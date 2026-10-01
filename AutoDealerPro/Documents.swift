import SwiftUI
import UIKit
import PDFKit

enum DocumentType: String, Identifiable { case invoice = "Rechnung", contract = "Kaufvertrag"; var id: String { rawValue } }
struct DocumentEditor: View {
    @EnvironmentObject var store: DealerStore; @Environment(\.dismiss) private var dismiss
    let vehicle: Vehicle; let type: DocumentType
    @State private var number = ""; @State private var date = Date(); @State private var customerID: UUID?
    @State private var terms = ""; @State private var pdf: SharedFile?; @State private var message: String?
    var body: some View {
        NavigationStack {
            Form {
                Section { Label("Dokumententwurf", systemImage: "doc.text"); Text("Vor geschäftlicher Verwendung müssen Steuerangaben, Vertragsbedingungen und Vollständigkeit geprüft werden. Die App berechnet keine Umsatzsteuer.").font(.caption).foregroundStyle(.secondary) }
                Section("Dokumentdaten") { TextField("Dokumentnummer", text: $number); DatePicker("Datum", selection: $date, displayedComponents: .date); Picker("Käufer", selection: $customerID) { Text("Käufer wählen").tag(nil as UUID?); ForEach(store.snapshot.customers) { Text($0.name).tag(Optional($0.id)) } } }
                Section("Steuerangaben, Zahlung & Vereinbarungen") { TextEditor(text: $terms).frame(minHeight: 180).accessibilityLabel("Steuerangaben und Vereinbarungen") }
                Section { LabeledContent(vehicle.name, value: Money.display(vehicle.saleCents)); Button { do { let customer = store.snapshot.customers.first { $0.id == customerID }; pdf = SharedFile(url: try PDFBuilder.create(type: type, number: number, date: date, dealer: store.snapshot.dealer, customer: customer, vehicle: vehicle, terms: terms)) } catch { message = error.localizedDescription } } label: { Label("PDF-Entwurf erstellen", systemImage: "doc.badge.plus") } }
            }.navigationTitle(type.rawValue).navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Schließen") { dismiss() } }
                .onAppear { customerID = vehicle.customerID }
                .sheet(item: $pdf) { file in NavigationStack { PDFPreview(url: file.url).navigationTitle("PDF-Entwurf").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .cancellationAction) { Button("Schließen") { pdf = nil } }; ToolbarItem(placement: .primaryAction) { ShareLink(item: file.url) { Label("Teilen", systemImage: "square.and.arrow.up") } } } } }
                .alert("PDF konnte nicht erstellt werden", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) { Button("OK", role: .cancel) {} } message: { Text(message ?? "") }
        }
    }
}
@MainActor enum PDFBuilder {
    static func create(type: DocumentType, number: String, date: Date, dealer: Dealer, customer: Customer?, vehicle: Vehicle, terms: String) throws -> URL {
        let bounds = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
        let format = UIGraphicsPDFRendererFormat(); format.documentInfo = [kCGPDFContextTitle as String: "\(type.rawValue) – Entwurf", kCGPDFContextCreator as String: "AutoDealer Pro"]
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(type.rawValue)-Entwurf-\(UUID().uuidString).pdf")
        try renderer.writePDF(to: url) { context in
            var y: CGFloat = 55; var page = 0
            func newPage() {
                context.beginPage(); page += 1; y = 55
                let footer = "AutoDealer Pro · ENTWURF · Seite \(page)"
                (footer as NSString).draw(at: CGPoint(x: 45, y: 803), withAttributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.darkGray])
            }
            func line(_ text: String, size: CGFloat = 11, bold: Bool = false) {
                let font = bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
                // Break by characters as a fallback, including a single very long VIN/note token.
                for paragraph in text.components(separatedBy: "\n") {
                    if paragraph.isEmpty { y += 13; continue }
                    var row = ""
                    for character in paragraph {
                        let candidate = row + String(character)
                        if !row.isEmpty && (candidate as NSString).size(withAttributes: attrs).width > 505 {
                            if y + size + 8 > 775 { newPage() }
                            (row as NSString).draw(at: CGPoint(x: 45, y: y), withAttributes: attrs); y += size + 6; row = String(character)
                        } else { row = candidate }
                    }
                    if y + size + 8 > 775 { newPage() }
                    (row as NSString).draw(at: CGPoint(x: 45, y: y), withAttributes: attrs); y += size + 8
                }
            }
            newPage(); line(dealer.name, size: 19, bold: true); line(dealer.address); line("Steuernummer / USt-ID: \(dealer.taxID.isEmpty ? "Noch zu ergänzen" : dealer.taxID)"); y += 18
            line("\(type.rawValue) · ENTWURF", size: 25, bold: true)
            line("Nummer: \(number.isEmpty ? "Noch zu ergänzen" : number)")
            line("Datum: \(date.formatted(.dateTime.day().month().year().locale(Locale(identifier: "de_DE"))))"); y += 12
            line("Käufer", size: 13, bold: true); line(customer?.name ?? "Noch zu ergänzen"); line(customer?.address ?? ""); y += 16
            line(vehicle.name, size: 17, bold: true); line("FIN: \(vehicle.vin.isEmpty ? "Noch zu ergänzen" : vehicle.vin)")
            line("Erstzulassung: \(vehicle.year) · Kilometerstand: \(vehicle.mileage) km")
            line("\(vehicle.fuel) · \(vehicle.transmission) · \(vehicle.power) PS")
            line("Kaufpreis: \(Money.display(vehicle.saleCents))", size: 18, bold: true); y += 12
            if !vehicle.notes.isEmpty { line("Zustand und bekannte Schäden", size: 13, bold: true); line(vehicle.notes); y += 10 }
            line("Steuern, Zahlung und Vereinbarungen", size: 13, bold: true)
            line(terms.isEmpty ? "Noch zu ergänzen. Es wurde keine Steuerbehandlung festgelegt." : terms)
            if type == .contract { y += 45; line("Ort, Datum: __________________________________________"); y += 20; line("Verkäufer: ___________________________________________"); y += 20; line("Käufer: ______________________________________________") }
            y += 20; line("Entwurf. Angaben, Steuerbehandlung und rechtliche Vollständigkeit vor Verwendung prüfen.", size: 9)
        }
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: url.path)
        return url
    }
}
struct PDFPreview: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> PDFView { let view = PDFView(); view.autoScales = true; view.document = PDFDocument(url: url); return view }
    func updateUIView(_ uiView: PDFView, context: Context) {}
}
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
