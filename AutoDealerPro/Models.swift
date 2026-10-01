import Foundation

enum VehicleStatus: String, CaseIterable, Codable, Identifiable {
    case purchased = "Angekauft", preparation = "Aufbereitung", listed = "Inseriert", reserved = "Reserviert", sold = "Verkauft"
    var id: String { rawValue }
}
struct Expense: Identifiable, Codable, Equatable {
    var id = UUID(); var label = ""; var cents = 0
}
struct Vehicle: Identifiable, Codable, Equatable {
    var id = UUID(); var name = ""; var vin = ""; var year = Calendar.current.component(.year, from: Date())
    var mileage = 0; var power = 0; var fuel = "Diesel"; var transmission = "Automatik"
    var status: VehicleStatus = .purchased; var purchaseCents = 0; var saleCents = 0
    var purchaseDate = Date(); var saleDate: Date?; var customerID: UUID?
    var equipment = ""; var notes = ""; var expenses: [Expense] = []; var photoIDs: [UUID] = []
    var investment: Int { purchaseCents + expenses.reduce(0) { $0 + $1.cents } }
    var margin: Int { saleCents - investment }
}
struct Customer: Identifiable, Codable, Equatable {
    var id = UUID(); var name = ""; var email = ""; var phone = ""; var address = ""; var notes = ""
}
struct Dealer: Codable, Equatable {
    var name = "Mein Autohaus"; var address = ""; var taxID = ""
}
struct Snapshot: Codable {
    var schemaVersion = 1; var dealer = Dealer(); var vehicles: [Vehicle] = []; var customers: [Customer] = []
}
struct Backup: Codable { var snapshot: Snapshot; var photos: [String: Data] }
enum DealerError: LocalizedError {
    case invalid(String)
    var errorDescription: String? { switch self { case .invalid(let text): return text } }
}
enum Money {
    static func display(_ cents: Int) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.locale = Locale(identifier: "de_DE"); f.currencyCode = "EUR"
        return f.string(from: NSNumber(value: Double(cents) / 100)) ?? "0,00 €"
    }
    static func input(_ cents: Int) -> String { String(format: "%.2f", Double(cents) / 100).replacingOccurrences(of: ".", with: ",") }
    static func parse(_ text: String) throws -> Int {
        let value = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard value.range(of: #"^\d{1,9}(\.\d{1,2})?$"#, options: .regularExpression) != nil else { throw DealerError.invalid("Betrag ohne Tausenderpunkte eingeben, z. B. 12500,50.") }
        let parts = value.split(separator: ".")
        guard let whole = Int(parts[0]) else { throw DealerError.invalid("Ungültiger Betrag.") }
        let decimals = parts.count > 1 ? String(parts[1]).padding(toLength: 2, withPad: "0", startingAt: 0) : "00"
        return whole * 100 + (Int(decimals) ?? 0)
    }
}
extension Vehicle {
    func validate(customers: [Customer]) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw DealerError.invalid("Marke und Modell fehlen.") }
        guard (1886...Calendar.current.component(.year, from: Date()) + 1).contains(year), (0...10_000_000).contains(mileage), (0...10_000).contains(power) else { throw DealerError.invalid("Bitte Jahr, Kilometerstand und Leistung prüfen.") }
        guard (0...99_999_999_999).contains(purchaseCents), (0...99_999_999_999).contains(saleCents), expenses.count <= 1000, photoIDs.count <= 100 else { throw DealerError.invalid("Ungültige Fahrzeugdaten.") }
        guard expenses.allSatisfy({ !$0.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (0...99_999_999_999).contains($0.cents) }) else { throw DealerError.invalid("Kosten benötigen eine Bezeichnung und einen gültigen Betrag.") }
        if let customerID, !customers.contains(where: { $0.id == customerID }) { throw DealerError.invalid("Der zugeordnete Kunde fehlt.") }
        if status == .sold && (customerID == nil || saleDate == nil) { throw DealerError.invalid("Für den Verkauf bitte Käufer und Verkaufsdatum angeben.") }
        if let saleDate, status == .sold && saleDate < Calendar.current.startOfDay(for: purchaseDate) { throw DealerError.invalid("Der Verkauf liegt vor dem Einkauf.") }
    }
    func advertisement(dealer: Dealer) -> String {
        """
        \(name)

        Erstzulassung: \(year)
        Kilometerstand: \(mileage.formatted(.number.locale(Locale(identifier: "de_DE")))) km
        \(fuel) · \(transmission) · \(power) PS

        Ausstattung:
        \(equipment.isEmpty ? "Auf Anfrage" : equipment)

        \(notes)

        Preis: \(Money.display(saleCents))
        \(dealer.name)
        \(dealer.address)
        Besichtigung nach Vereinbarung.
        """
    }
}
