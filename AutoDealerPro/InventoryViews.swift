import SwiftUI
import PhotosUI
import UIKit

struct DashboardView: View {
    @EnvironmentObject var store: DealerStore
    @State private var adding = false
    private var stock: [Vehicle] { store.snapshot.vehicles.filter { $0.status != .sold } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack { Image(systemName: "car.side.fill").font(.title).foregroundStyle(Color.dealerBlue); VStack(alignment: .leading) { Text("AUTODEALER PRO").font(.caption.weight(.bold)).tracking(2).foregroundStyle(.secondary); Text(store.snapshot.dealer.name).font(.title2.bold()) } }
                    LocalNotice()
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        Metric(title: "Im Bestand", value: String(stock.count), icon: "car.side")
                        Metric(title: "Gebundenes Kapital", value: Money.display(stock.reduce(0) { $0 + $1.investment }), icon: "eurosign.circle")
                        Metric(title: "Erwartete Marge", value: Money.display(stock.reduce(0) { $0 + $1.margin }), icon: "chart.line.uptrend.xyaxis", accent: true)
                        Metric(title: "Verkauft", value: String(store.snapshot.vehicles.filter { $0.status == .sold }.count), icon: "checkmark.seal")
                    }
                    Text("Vor Steuern und Gemeinkosten. Alle Zeiträume.").font(.caption).foregroundStyle(.secondary)
                    Text("Verkaufsprozess").font(.title3.bold())
                    VStack(spacing: 0) {
                        ForEach(VehicleStatus.allCases) { status in
                            HStack { StatusBadge(status: status); Spacer(); Text(String(store.snapshot.vehicles.filter { $0.status == status }.count)).monospacedDigit().bold() }.padding()
                            if status != .sold { Divider().padding(.horizontal) }
                        }
                    }.background(.background, in: RoundedRectangle(cornerRadius: 16))
                    if stock.isEmpty {
                        ContentUnavailableView { Label("Ihr erster Ankauf", systemImage: "car.side") } description: { Text("Erfassen Sie ein Fahrzeug und behalten Sie die Marge im Blick.") } actions: { Button("Fahrzeug hinzufügen") { adding = true }.buttonStyle(.borderedProminent) }
                    } else {
                        Text("Fahrzeuge im Bestand").font(.title3.bold())
                        ForEach(stock.prefix(5)) { v in NavigationLink { VehicleDetail(id: v.id) } label: { VehicleRow(vehicle: v) }.buttonStyle(.plain) }
                    }
                }.padding()
            }.background(Color(uiColor: .systemGroupedBackground)).navigationTitle("Übersicht")
                .toolbar { Button("Fahrzeug hinzufügen", systemImage: "plus") { adding = true } }
                .sheet(isPresented: $adding) { VehicleEditor(vehicle: Vehicle()) }
        }
    }
}
struct Metric: View {
    let title: String; let value: String; let icon: String; var accent = false
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { Image(systemName: icon); Spacer() }.foregroundStyle(accent ? .white.opacity(0.8) : .secondary)
            Text(value).font(.title2.bold()).minimumScaleFactor(0.65).lineLimit(1)
            Text(title).font(.caption).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(16).foregroundStyle(accent ? Color.white : Color.primary)
            .background(accent ? Color.dealerBlue : Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
struct StatusBadge: View {
    let status: VehicleStatus
    private var color: Color { switch status { case .purchased: return .secondary; case .preparation: return .orange; case .listed: return .dealerBlue; case .reserved: return .purple; case .sold: return .green } }
    var body: some View { Text(status.rawValue).font(.caption.weight(.semibold)).padding(.horizontal, 9).padding(.vertical, 5).foregroundStyle(color).background(color.opacity(0.11), in: Capsule()) }
}
struct VehicleRow: View {
    @EnvironmentObject var store: DealerStore
    let vehicle: Vehicle
    var body: some View {
        HStack(spacing: 13) {
            Group { if let id = vehicle.photoIDs.first, let photo = store.photo(id) { Image(uiImage: photo).resizable().scaledToFill() } else { Image(systemName: "car.side").font(.title2).foregroundStyle(Color.dealerBlue).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.dealerBlue.opacity(0.08)) } }.frame(width: 68, height: 60).clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 5) { Text(vehicle.name).font(.headline); Text("\(String(vehicle.year)) · \(vehicle.mileage.formatted()) km").font(.caption).foregroundStyle(.secondary); StatusBadge(status: vehicle.status) }
            Spacer(minLength: 3)
            VStack(alignment: .trailing, spacing: 6) { Text(Money.display(vehicle.saleCents)).font(.subheadline.bold()); Text(Money.display(vehicle.margin)).font(.caption).foregroundStyle(vehicle.margin >= 0 ? .green : .red) }
        }.padding(.vertical, 7).accessibilityElement(children: .combine)
    }
}
struct InventoryView: View {
    @EnvironmentObject var store: DealerStore
    @State private var query = ""; @State private var status: VehicleStatus?; @State private var adding = false
    private var filtered: [Vehicle] { store.snapshot.vehicles.filter { (status == nil || $0.status == status) && (query.isEmpty || ($0.name + " " + $0.vin).localizedCaseInsensitiveContains(query)) } }
    var body: some View {
        NavigationStack {
            List {
                Section { Picker("Status", selection: $status) { Text("Alle Fahrzeuge").tag(nil as VehicleStatus?); ForEach(VehicleStatus.allCases) { Text($0.rawValue).tag(Optional($0)) } } }
                Section { ForEach(filtered) { v in NavigationLink { VehicleDetail(id: v.id) } label: { VehicleRow(vehicle: v) } } } footer: { LocalNotice() }
            }.overlay { if filtered.isEmpty { ContentUnavailableView("Keine Fahrzeuge", systemImage: "car.side", description: Text(query.isEmpty ? "Fügen Sie ein Fahrzeug über + hinzu oder ändern Sie den Filter." : "Keine Treffer für diese Suche.")) } }
                .navigationTitle("Fahrzeugbestand").searchable(text: $query, prompt: "Marke, Modell oder FIN")
                .toolbar { Button("Hinzufügen", systemImage: "plus") { adding = true } }
                .sheet(isPresented: $adding) { VehicleEditor(vehicle: Vehicle()) }
        }
    }
}
struct VehicleDetail: View {
    @EnvironmentObject var store: DealerStore
    @Environment(\.dismiss) private var dismiss
    let id: UUID
    @State private var editing = false; @State private var deleting = false; @State private var camera = false
    @State private var picks: [PhotosPickerItem] = []; @State private var uploading = false; @State private var document: DocumentType?
    private var vehicle: Vehicle? { store.snapshot.vehicles.first { $0.id == id } }
    var body: some View {
        Group {
            if let v = vehicle {
                List {
                    Section {
                        HStack { StatusBadge(status: v.status); Spacer(); Text(Money.display(v.saleCents)).font(.title2.bold()) }
                        LabeledContent("Erstzulassung", value: String(v.year)); LabeledContent("Kilometerstand", value: "\(v.mileage.formatted()) km")
                        LabeledContent("Antrieb", value: "\(v.fuel) · \(v.transmission)"); LabeledContent("Leistung", value: "\(v.power) PS")
                        LabeledContent("FIN", value: v.vin.isEmpty ? "Nicht angegeben" : v.vin)
                        LabeledContent("Einkauf", value: v.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                        if let c = store.snapshot.customers.first(where: { $0.id == v.customerID }) { LabeledContent("Käufer", value: c.name) }
                    }
                    Section("Kalkulation") {
                        LabeledContent("Einkaufspreis", value: Money.display(v.purchaseCents))
                        ForEach(v.expenses) { LabeledContent($0.label, value: Money.display($0.cents)) }
                        LabeledContent("Gesamtinvestition", value: Money.display(v.investment))
                        LabeledContent(v.status == .sold ? "Rohertrag" : "Erwartete Marge") { Text(Money.display(v.margin)).bold().foregroundStyle(v.margin >= 0 ? .green : .red) }
                        Text("Vor Steuern und Gemeinkosten.").font(.caption).foregroundStyle(.secondary)
                    }
                    Section("Fahrzeugfotos") {
                        if !v.photoIDs.isEmpty { ScrollView(.horizontal) { HStack { ForEach(v.photoIDs, id: \.self) { photoID in if let image = store.photo(photoID) { Image(uiImage: image).resizable().scaledToFill().frame(width: 220, height: 165).clipped().clipShape(RoundedRectangle(cornerRadius: 10)).accessibilityLabel("Fahrzeugfoto").contextMenu { ShareLink(item: store.photoURL(photoID)) { Label("Teilen", systemImage: "square.and.arrow.up") } } } } }.padding(.vertical, 5) } }
                        PhotosPicker(selection: $picks, maxSelectionCount: 10, matching: .images) { Label("Fotos auswählen", systemImage: "photo.on.rectangle") }.disabled(uploading)
                        if UIImagePickerController.isSourceTypeAvailable(.camera) { Button { camera = true } label: { Label("Foto aufnehmen", systemImage: "camera") }.disabled(uploading) }
                        if uploading { ProgressView("Fotos werden gespeichert…") }
                    }
                    Section("Ausstattung") { Text(v.equipment.isEmpty ? "Noch nicht erfasst" : v.equipment).textSelection(.enabled) }
                    Section("Zustand & Hinweise") { Text(v.notes.isEmpty ? "Noch nicht erfasst" : v.notes).textSelection(.enabled) }
                    Section("Verkauf vorbereiten") {
                        NavigationLink { AdvertisementView(vehicle: v) } label: { Label("Anzeigentext", systemImage: "text.bubble") }
                        Button { document = .invoice } label: { Label("Rechnung als PDF", systemImage: "doc.text") }
                        Button { document = .contract } label: { Label("Kaufvertrag als PDF", systemImage: "signature") }
                    }
                    Section { Button("Fahrzeug löschen", role: .destructive) { deleting = true } } footer: { LocalNotice() }
                }.navigationTitle(v.name).navigationBarTitleDisplayMode(.inline)
                    .toolbar { Button("Bearbeiten") { editing = true } }
                    .sheet(isPresented: $editing) { VehicleEditor(vehicle: v) }
                    .sheet(item: $document) { kind in DocumentEditor(vehicle: v, type: kind) }
                    .sheet(isPresented: $camera) { CameraPicker { image in do { try store.addPhoto(image, to: id) } catch { store.error = error.localizedDescription } } }
                    .confirmationDialog("Fahrzeug und Fotos auf diesem iPhone löschen?", isPresented: $deleting, titleVisibility: .visible) { Button("Fahrzeug löschen", role: .destructive) { do { try store.removeVehicle(id); dismiss() } catch { store.error = error.localizedDescription } } }
                    .onChange(of: picks) { _, items in
                        Task { @MainActor in
                            uploading = true; defer { uploading = false; picks = [] }
                            for item in items { do {
                                guard let bytes = try await item.loadTransferable(type: Data.self), bytes.count <= 30 * 1024 * 1024, let image = UIImage(data: bytes) else { throw DealerError.invalid("Foto nicht lesbar oder größer als 30 MB.") }
                                try store.addPhoto(image, to: id)
                            } catch { store.error = error.localizedDescription; break } }
                        }
                    }
            } else { ContentUnavailableView("Fahrzeug nicht vorhanden", systemImage: "car.side") }
        }
    }
}
struct VehicleEditor: View {
    @EnvironmentObject var store: DealerStore; @Environment(\.dismiss) private var dismiss
    @State var vehicle: Vehicle
    @State private var purchase = ""; @State private var sale = ""; @State private var message: String?
    @State private var expenseLabel = ""; @State private var expenseAmount = ""
    private func save() { do { guard expenseLabel.isEmpty && expenseAmount.isEmpty else { throw DealerError.invalid("Bitte die eingegebenen Kosten erst hinzufügen oder beide Kostenfelder leeren.") }; vehicle.purchaseCents = try Money.parse(purchase); vehicle.saleCents = try Money.parse(sale); try vehicle.validate(customers: store.snapshot.customers); try store.save(vehicle); dismiss() } catch { message = error.localizedDescription } }
    var body: some View {
        NavigationStack {
            Form {
                Section("Fahrzeug") {
                    TextField("Marke & Modell *", text: $vehicle.name)
                    TextField("FIN / Fahrgestellnummer", text: $vehicle.vin).textInputAutocapitalization(.characters).autocorrectionDisabled()
                    LabeledContent("Erstzulassung") { TextField("Jahr", value: $vehicle.year, format: .number.grouping(.never)).keyboardType(.numberPad).multilineTextAlignment(.trailing) }
                    LabeledContent("Kilometer") { TextField("Kilometer", value: $vehicle.mileage, format: .number.grouping(.never)).keyboardType(.numberPad).multilineTextAlignment(.trailing) }
                    LabeledContent("Leistung (PS)") { TextField("PS", value: $vehicle.power, format: .number.grouping(.never)).keyboardType(.numberPad).multilineTextAlignment(.trailing) }
                    Picker("Kraftstoff", selection: $vehicle.fuel) { ForEach(["Diesel", "Benzin", "Hybrid", "Elektro", "LPG", "Sonstige"], id: \.self) { Text($0) } }
                    Picker("Getriebe", selection: $vehicle.transmission) { ForEach(["Automatik", "Schaltgetriebe"], id: \.self) { Text($0) } }
                    Picker("Status", selection: $vehicle.status) { ForEach(VehicleStatus.allCases) { Text($0.rawValue).tag($0) } }
                }
                Section { LabeledContent("Einkauf (€)") { TextField("0,00", text: $purchase).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }; LabeledContent(vehicle.status == .sold ? "Verkauf (€)" : "Angebot (€)") { TextField("0,00", text: $sale).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }; DatePicker("Einkaufsdatum", selection: $vehicle.purchaseDate, displayedComponents: .date) } header: { Text("Kalkulation") } footer: { Text("Beträge ohne Tausenderpunkte eingeben, z. B. 12500,50.") }
                Section("Zusätzliche Kosten") {
                    ForEach(vehicle.expenses) { e in LabeledContent(e.label, value: Money.display(e.cents)) }.onDelete { vehicle.expenses.remove(atOffsets: $0) }
                    TextField("Bezeichnung, z. B. Aufbereitung", text: $expenseLabel)
                    TextField("Betrag (€)", text: $expenseAmount).keyboardType(.decimalPad)
                    Button("Kosten hinzufügen") { do { guard !expenseLabel.trimmingCharacters(in: .whitespaces).isEmpty else { throw DealerError.invalid("Kostenbezeichnung fehlt.") }; vehicle.expenses.append(Expense(label: expenseLabel, cents: try Money.parse(expenseAmount))); expenseLabel = ""; expenseAmount = "" } catch { message = error.localizedDescription } }
                }
                Section("Käufer") {
                    Picker("Kunde", selection: $vehicle.customerID) { Text("Noch nicht zugeordnet").tag(nil as UUID?); ForEach(store.snapshot.customers) { Text($0.name).tag(Optional($0.id)) } }
                    if vehicle.status == .sold { DatePicker("Verkaufsdatum", selection: Binding(get: { vehicle.saleDate ?? Date() }, set: { vehicle.saleDate = $0 }), displayedComponents: .date) }
                    if store.snapshot.customers.isEmpty { Text("Kunden zuerst unter „Kunden“ anlegen.").font(.caption).foregroundStyle(.secondary) }
                }
                Section("Ausstattung") { TextEditor(text: $vehicle.equipment).frame(minHeight: 100).accessibilityLabel("Ausstattung") }
                Section("Bekannte Schäden & Hinweise") { TextEditor(text: $vehicle.notes).frame(minHeight: 100).accessibilityLabel("Zustand und Hinweise") }
            }.navigationTitle("Fahrzeug bearbeiten").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Speichern", action: save).bold() } }
                .onAppear { purchase = Money.input(vehicle.purchaseCents); sale = Money.input(vehicle.saleCents); if vehicle.status == .sold && vehicle.saleDate == nil { vehicle.saleDate = Date() } }
                .onChange(of: vehicle.status) { _, status in if status == .sold && vehicle.saleDate == nil { vehicle.saleDate = Date() } }
                .alert("Bitte prüfen", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) { Button("OK", role: .cancel) {} } message: { Text(message ?? "") }
        }.interactiveDismissDisabled()
    }
}
struct AdvertisementView: View {
    @EnvironmentObject var store: DealerStore; let vehicle: Vehicle
    @State private var text = ""; @State private var copied = false
    var body: some View { VStack(alignment: .leading, spacing: 16) { Text("Textvorlage für mobile.de und Kleinanzeigen. Angaben vor Veröffentlichung prüfen.").font(.subheadline).foregroundStyle(.secondary); TextEditor(text: $text).accessibilityLabel("Anzeigentext"); HStack { Button { UIPasteboard.general.string = text; copied = true } label: { Label(copied ? "Kopiert" : "Kopieren", systemImage: copied ? "checkmark" : "doc.on.doc") }.buttonStyle(.bordered); ShareLink(item: text) { Label("Teilen", systemImage: "square.and.arrow.up") }.buttonStyle(.borderedProminent) } }.padding().navigationTitle("Anzeigentext").navigationBarTitleDisplayMode(.inline).onAppear { text = vehicle.advertisement(dealer: store.snapshot.dealer) } }
}
struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss; var onImage: (UIImage) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIImagePickerController { let picker = UIImagePickerController(); picker.sourceType = .camera; picker.delegate = context.coordinator; return picker }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker; init(_ parent: CameraPicker) { self.parent = parent }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) { if let image = info[.originalImage] as? UIImage { parent.onImage(image) }; parent.dismiss() }
    }
}
