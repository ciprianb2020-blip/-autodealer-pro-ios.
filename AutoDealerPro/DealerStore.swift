import Foundation
import Combine
import UIKit

@MainActor final class DealerStore: ObservableObject {
    @Published private(set) var snapshot = Snapshot()
    @Published var error: String?
    @Published private(set) var loadFailed = false
    private let root: URL
    private var dataURL: URL { root.appendingPathComponent("dealer.json") }
    private var photosURL: URL { root.appendingPathComponent("Photos", isDirectory: true) }
    init() {
        root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("AutoDealerPro", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: photosURL, withIntermediateDirectories: true, attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
            if FileManager.default.fileExists(atPath: dataURL.path) {
                let decoded = try JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: dataURL)); try Self.validate(decoded); snapshot = decoded
            }
        } catch { self.error = "Gespeicherte Daten konnten nicht geladen werden: \(error.localizedDescription). Vorhandene Dateien werden nicht überschrieben."; loadFailed = true }
    }
    private static func validate(_ s: Snapshot) throws {
        guard s.schemaVersion == 1, s.vehicles.count <= 10000, s.customers.count <= 50000,
              Set(s.vehicles.map(\.id)).count == s.vehicles.count, Set(s.customers.map(\.id)).count == s.customers.count,
              s.customers.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { throw DealerError.invalid("Datei ist ungültig oder hat eine nicht unterstützte Version.") }
        for vehicle in s.vehicles { try vehicle.validate(customers: s.customers) }
    }
    private func commit(_ next: Snapshot) throws {
        guard !loadFailed else { throw DealerError.invalid("Speicherfehler zuerst beheben oder eine Sicherung wiederherstellen.") }
        try Self.validate(next)
        try JSONEncoder().encode(next).write(to: dataURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        snapshot = next
    }
    func save(_ v: Vehicle) throws {
        var next = snapshot
        if let i = next.vehicles.firstIndex(where: { $0.id == v.id }) { next.vehicles[i] = v } else { next.vehicles.insert(v, at: 0) }
        try commit(next)
    }
    func save(_ c: Customer) throws {
        var next = snapshot
        if let i = next.customers.firstIndex(where: { $0.id == c.id }) { next.customers[i] = c } else { next.customers.append(c) }
        try commit(next)
    }
    func save(_ d: Dealer) throws {
        guard !d.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw DealerError.invalid("Firmenname fehlt.") }
        var next = snapshot; next.dealer = d; try commit(next)
    }
    func removeVehicle(_ id: UUID) throws {
        let ids = snapshot.vehicles.first(where: { $0.id == id })?.photoIDs ?? []
        var next = snapshot; next.vehicles.removeAll { $0.id == id }; try commit(next)
        for photoID in ids { try? FileManager.default.removeItem(at: photoURL(photoID)) }
    }
    func removeCustomer(_ id: UUID) throws {
        guard !snapshot.vehicles.contains(where: { $0.customerID == id }) else { throw DealerError.invalid("Dieser Kunde ist einem Fahrzeug zugeordnet.") }
        var next = snapshot; next.customers.removeAll { $0.id == id }; try commit(next)
    }
    func photoURL(_ id: UUID) -> URL { photosURL.appendingPathComponent(id.uuidString).appendingPathExtension("jpg") }
    func photo(_ id: UUID) -> UIImage? { UIImage(contentsOfFile: photoURL(id).path) }
    func addPhoto(_ image: UIImage, to vehicleID: UUID) throws {
        guard var v = snapshot.vehicles.first(where: { $0.id == vehicleID }) else { throw DealerError.invalid("Fahrzeug fehlt.") }
        guard v.photoIDs.count < 100 else { throw DealerError.invalid("Maximal 100 Fotos pro Fahrzeug.") }
        let longest = max(image.size.width, image.size.height); let scale = min(1, 2000 / max(1, longest))
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let normalized = UIGraphicsImageRenderer(size: size, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        guard let bytes = normalized.jpegData(compressionQuality: 0.82) else { throw DealerError.invalid("Foto konnte nicht gelesen werden.") }
        let id = UUID(); try bytes.write(to: photoURL(id), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]); v.photoIDs.append(id)
        do { try save(v) } catch { try? FileManager.default.removeItem(at: photoURL(id)); throw error }
    }
    func removePhoto(_ id: UUID, from vehicleID: UUID) throws {
        guard var v = snapshot.vehicles.first(where: { $0.id == vehicleID }) else { return }
        v.photoIDs.removeAll { $0 == id }; try save(v); try? FileManager.default.removeItem(at: photoURL(id))
    }
    func backup() throws -> URL {
        var photos: [String: Data] = [:]; var totalBytes = 0
        for v in snapshot.vehicles { for id in v.photoIDs {
            let bytes = try Data(contentsOf: photoURL(id)); totalBytes += bytes.count
            guard totalBytes <= 70 * 1024 * 1024 else { throw DealerError.invalid("Fotosicherung zu groß für dieses Exportformat (maximal 70 MB Fotodaten).") }
            photos[id.uuidString] = bytes
        } }
        let backup = Backup(snapshot: snapshot, photos: photos)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AutoDealerPro-\(UUID().uuidString).json")
        let encoded = try JSONEncoder().encode(backup)
        guard encoded.count <= 100 * 1024 * 1024 else { throw DealerError.invalid("Sicherung überschreitet die Importgrenze von 100 MB.") }
        try encoded.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]); return url
    }
    func importBackup(_ url: URL) throws {
        let granted = url.startAccessingSecurityScopedResource(); defer { if granted { url.stopAccessingSecurityScopedResource() } }
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size <= 100 * 1024 * 1024 else { throw DealerError.invalid("Sicherung darf maximal 100 MB groß sein.") }
        let backup = try JSONDecoder().decode(Backup.self, from: Data(contentsOf: url)); try Self.validate(backup.snapshot)
        // Import into an empty local workspace only: never overwrite an existing dealer.
        guard snapshot.vehicles.isEmpty && snapshot.customers.isEmpty && !loadFailed else { throw DealerError.invalid("Import nur in einen leeren, fehlerfrei geladenen Arbeitsbereich möglich. Vorhandene Daten zuerst sichern und anschließend lokal löschen.") }
        for v in backup.snapshot.vehicles { for id in v.photoIDs {
            guard let bytes = backup.photos[id.uuidString], bytes.count <= 8 * 1024 * 1024, UIImage(data: bytes) != nil else { throw DealerError.invalid("Ein Foto in der Sicherung fehlt oder ist ungültig.") }
        } }
        for v in backup.snapshot.vehicles { for id in v.photoIDs { try backup.photos[id.uuidString]!.write(to: photoURL(id), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]) } }
        try commit(backup.snapshot)
    }
    func deleteLocalData() throws {
        // Deliberate destructive recovery is available even if the original store cannot decode.
        try JSONEncoder().encode(Snapshot()).write(to: dataURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        snapshot = Snapshot(); loadFailed = false
        for url in try FileManager.default.contentsOfDirectory(at: photosURL, includingPropertiesForKeys: nil) { try FileManager.default.removeItem(at: url) }
    }
}
