import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject private var session: Session
    @Environment(\.modelContext) private var context

    @State private var enLogin = false

    var body: some View {
        Group {
            if let usuario = session.usuarioActual {
                MainView(userId: usuario)
                    .id(usuario)
            } else if enLogin {
                LoginView()
            } else {
                LandingView { enLogin = true }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.usuarioActual)
        .task {
            SeedService.crearUsuarioPredeterminado(en: context)
        }
    }
}
