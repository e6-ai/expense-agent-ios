import SwiftUI
import SwiftData

@main
struct ExpenseAgentApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Receipt.self)
    }
}
