import SwiftUI
import SwiftData

@main
struct FinanceApp: App {
    let container: ModelContainer
    @StateObject private var session = Session()

    init() {
        do {
            container = try ModelContainer(for: Usuario.self, Movimiento.self, Presupuesto.self, Recurrente.self)
        } catch {
            fatalError("No se pudo crear el contenedor de datos: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
