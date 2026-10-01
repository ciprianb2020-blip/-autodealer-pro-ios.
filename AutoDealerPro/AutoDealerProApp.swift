import SwiftUI

@main struct AutoDealerProApp: App {
    @StateObject private var store = DealerStore()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store).tint(.dealerBlue)
                .environment(\.locale, Locale(identifier: "de_DE"))
                .alert("Hinweis", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) { Button("OK", role: .cancel) { store.error = nil } } message: { Text(store.error ?? "") }
        }
    }
}
extension Color { static let dealerBlue = Color(red: 0.14, green: 0.29, blue: 0.87) }
struct RootView: View {
    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Übersicht", systemImage: "square.grid.2x2") }
            InventoryView().tabItem { Label("Fahrzeuge", systemImage: "car.side") }
            CustomersView().tabItem { Label("Kunden", systemImage: "person.2") }
            SettingsView().tabItem { Label("Firma", systemImage: "building.2") }
        }
    }
}
struct LocalNotice: View {
    var body: some View { Label("Auf diesem iPhone gespeichert · Keine Cloud-Synchronisierung", systemImage: "iphone").font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
}
