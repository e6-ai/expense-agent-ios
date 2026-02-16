import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showCamera = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ReceiptListView(showCamera: $showCamera)
                .tabItem {
                    Label("Receipts", systemImage: "list.bullet")
                }
                .tag(0)

            ReportView()
                .tabItem {
                    Label("Reports", systemImage: "chart.pie.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .tint(.orange)
        .onAppear {
            // Auto-show camera on first launch if API key is set
            if !APIKeyManager.shared.apiKey.isEmpty {
                showCamera = true
            }
        }
    }
}
