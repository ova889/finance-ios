import SwiftUI

enum AppConfig {
    static let appURL = "https://ova889.pythonanywhere.com"
}

@main
struct FinanceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
