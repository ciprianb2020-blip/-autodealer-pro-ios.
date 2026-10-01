import SwiftUI
import UniformTypeIdentifiers

struct CustomersView: View {
    @EnvironmentObject var store: DealerStore
    @State private var query = ""; @State private var editing: Customer?
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.snapshot.customers.filter { query.isEmpty || ($0.name + " " + $0.email + " " + $0.phone).localizedCaseInsensitiveContains(query) }) { c in
                    Button { editing = c } label: {
                        HStack { Image(systemName: "person.crop.circle.fill").font(.largeTitle).foregroundStyle(Color.dealerBlue.opacity(0.7)); VStack(alignment: .leading, spacing: 5) { Text(c.name).font(.headline).foregroundStyle(.primary); if !c.email.isEmpty { Text(c.email).font(.caption).foregroundStyle(.secondary) }; if !c.phone.isEmpty { Text(c.phone).font(.caption).foregroundStyle(.secondary) } } }
                    }
                }
            }.overlay { if store.snapshot.customers.isEmpty { ContentUnavailableView("Ihre Kunden", systemImage: "person.2", description: Text("Speichern Sie Käufer und Kontakte über +.")) } }
                .navigationTitle("Kunden").searchable(text: $query, prompt: "Name, E-Mail oder Telefon")
                .toolbar { Button("Kunde hinzufügen", systemImage: "plus") { editing = Customer() } }
                .sheet(item: $editing) { CustomerEditor(customer: $0) }
        }
    }
}
struct CustomerEditor: View {
    @EnvironmentObject var store: DealerStore; @Environment(\.dismiss) private var dismiss
    @State var customer: Customer; @State private var message: String?; @State private var deleting = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Kontakt") { TextField("Name *", text: $customer.name); TextField("E-Mail", text: $customer.email).keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled(); TextField("Telefon", text: $customer.phone).keyboardType(.phonePad) }
                Section("Adresse") { TextEditor(text: $customer.address).frame(minHeight: 90).accessibilityLabel("Adresse") }
                Section("Notizen") { TextEditor(text: $customer.notes).frame(minHeight: 100).accessibilityLabel("Kundennotizen") }
                if store.snapshot.customers.contains(where: { $0.id == customer.id }) { Section { Button("Kunde löschen", role: .destructive) { deleting = true } } }
            }.navigationTitle("Kundendaten").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Speichern") { do { try store.save(customer); dismiss() } catch { message = error.localizedDescription } }.bold() } }
                .alert("Bitte prüfen", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) { Button("OK", role: .cancel) {} } message: { Text(message ?? "") }
                .confirmationDialog("Diesen Kunden auf dem iPhone löschen?", isPresented: $deleting, titleVisibility: .visible) { Button("Kunde löschen", role: .destructive) { do { try store.removeCustomer(customer.id); dismiss() } catch { message = error.localizedDescription } } }
        }.interactiveDismissDisabled()
    }
}
struct SharedFile: Identifiable { let id = UUID(); let url: URL }
struct SettingsView: View {
    @EnvironmentObject var store: DealerStore
    @State private var editing = false; @State private var deleting = false; @State private var importing = false
    @State private var export: SharedFile?; @State private var message: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Ihr Unternehmen") { Text(store.snapshot.dealer.name).font(.headline); if !store.snapshot.dealer.address.isEmpty { Text(store.snapshot.dealer.address) }; if !store.snapshot.dealer.taxID.isEmpty { LabeledContent("Steuernummer / USt-ID", value: store.snapshot.dealer.taxID) }; Button("Firmendaten bearbeiten") { editing = true } }
                Section { Label("Lokale iPhone-Version", systemImage: "iphone"); Text("Fahrzeuge, Kunden und Fotos werden in dieser Version nur auf diesem Gerät gespeichert. Die Daten werden nicht automatisch mit der Web-App oder anderen Mitarbeitern abgeglichen.").font(.subheadline).foregroundStyle(.secondary); Link(destination: URL(string: "https://autodealer-pro.sara-naomi.chatgpt.site")!) { Label("Private Web-App öffnen", systemImage: "safari") }; Text("Die Web-App ist derzeit nur für ihren Eigentümer zugänglich. Cloud-Anmeldung und Abonnements sind in der iPhone-Version noch nicht aktiviert.").font(.caption).foregroundStyle(.secondary) } header: { Text("Verbindung") }
                Section {
                    Button { do { export = SharedFile(url: try store.backup()) } catch { message = error.localizedDescription } } label: { Label("Sicherung exportieren", systemImage: "square.and.arrow.up") }
                    Button { importing = true } label: { Label("Sicherung importieren", systemImage: "square.and.arrow.down") }
                    Text("Die Sicherung enthält Kunden, Fahrzeugdaten und Fotos. Bewahren Sie sie geschützt auf. Ein Import ist nur in einen leeren Arbeitsbereich möglich. Nur Sicherungen dieser iPhone-App werden unterstützt.").font(.caption).foregroundStyle(.secondary)
                } header: { Text("Datensicherung") }
                Section { NavigationLink("Datenschutz auf diesem Gerät") { PrivacyView() }; Text("Version 0.1 · Entwicklungsversion").font(.caption).foregroundStyle(.secondary) } header: { Text("Über AutoDealer Pro") }
                Section { Button("Alle lokalen Daten löschen", role: .destructive) { deleting = true } } footer: { Text("Löscht Fahrzeuge, Fotos, Kunden und Firmendaten ausschließlich in dieser App. Exportierte Sicherungen und Daten der Web-App bleiben erhalten.") }
            }.navigationTitle("Firma & Daten")
                .sheet(isPresented: $editing) { DealerEditor(dealer: store.snapshot.dealer) }
                .sheet(item: $export) { file in ShareSheet(items: [file.url]) }
                .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in do { try store.importBackup(result.get()); message = "Sicherung erfolgreich importiert." } catch { message = error.localizedDescription } }
                .confirmationDialog("Alle Daten auf diesem iPhone unwiderruflich löschen? Vorher eine Sicherung exportieren.", isPresented: $deleting, titleVisibility: .visible) { Button("Alle lokalen Daten löschen", role: .destructive) { do { try store.deleteLocalData() } catch { message = error.localizedDescription } } }
                .alert("Hinweis", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) { Button("OK", role: .cancel) {} } message: { Text(message ?? "") }
        }
    }
}
struct DealerEditor: View {
    @EnvironmentObject var store: DealerStore; @Environment(\.dismiss) private var dismiss
    @State var dealer: Dealer; @State private var message: String?
    var body: some View { NavigationStack { Form { TextField("Firmenname *", text: $dealer.name); Section("Adresse") { TextEditor(text: $dealer.address).frame(minHeight: 100).accessibilityLabel("Firmenadresse") }; TextField("Steuernummer / USt-ID", text: $dealer.taxID) }.navigationTitle("Firmendaten").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Speichern") { do { try store.save(dealer); dismiss() } catch { message = error.localizedDescription } } } }.alert("Bitte prüfen", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) { Button("OK", role: .cancel) {} } message: { Text(message ?? "") }.interactiveDismissDisabled() } }
}
struct PrivacyView: View {
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 20) { Text("Ihre Daten auf diesem Gerät").font(.title2.bold()); Text("Diese Entwicklungsversion speichert Ihre eingegebenen Firmendaten, Fahrzeuge, Kunden und Fotos lokal im geschützten App-Verzeichnis. Sie enthält keine Analyse- oder Werbedienste und überträgt diese Daten nicht an einen App-Server."); Text("Fotos und Kamera").font(.headline); Text("Sie wählen Fotos einzeln über die iOS-Fotoauswahl aus. Die Kamera wird nur geöffnet, wenn Sie „Foto aufnehmen“ wählen. Fotos werden für die Fahrzeugakte verkleinert und als JPEG gespeichert."); Text("Export und Sicherungen").font(.headline); Text("Beim Teilen eines PDFs, Anzeigentextes oder einer Sicherung bestimmen Sie den Empfänger. Andere Apps und Speicheranbieter verarbeiten die geteilten Dateien nach ihren eigenen Regeln. Gerätesicherungen können abhängig von Ihren iOS-Einstellungen App-Daten enthalten."); Text("Löschen").font(.headline); Text("Unter „Firma“ können Sie alle lokalen App-Daten löschen. Bereits geteilte Dateien und Sicherungen werden dabei nicht gelöscht. Die Web-App hat einen eigenen Datenbestand."); Text("Noch kein öffentlicher SaaS-Dienst").font(.headline); Text("Diese Informationen beschreiben nur die lokale Entwicklungsversion. Vor der SaaS-Veröffentlichung müssen Betreiber, Kontakt, Serververarbeitung, Aufbewahrung und Betroffenenrechte in einer vollständigen Datenschutzerklärung ergänzt werden.") }.padding() }.navigationTitle("Datenschutz").navigationBarTitleDisplayMode(.inline) }
}
