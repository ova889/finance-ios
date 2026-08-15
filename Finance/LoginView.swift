import SwiftUI
import SwiftData

struct BatSymbol: Shape {
    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 100
        let scaleY = rect.height / 60
        var path = Path()
        path.move(to: CGPoint(x: 50, y: 15))
        path.addCurve(to: CGPoint(x: 40, y: 2), control1: CGPoint(x: 47, y: 12), control2: CGPoint(x: 42, y: 4))
        path.addCurve(to: CGPoint(x: 34, y: 14), control1: CGPoint(x: 38, y: 5), control2: CGPoint(x: 37, y: 13))
        path.addCurve(to: CGPoint(x: 2, y: 30), control1: CGPoint(x: 25, y: 12), control2: CGPoint(x: 12, y: 18))
        path.addCurve(to: CGPoint(x: 28, y: 32), control1: CGPoint(x: 12, y: 33), control2: CGPoint(x: 22, y: 28))
        path.addCurve(to: CGPoint(x: 50, y: 58), control1: CGPoint(x: 32, y: 38), control2: CGPoint(x: 30, y: 52))
        path.addCurve(to: CGPoint(x: 72, y: 32), control1: CGPoint(x: 70, y: 52), control2: CGPoint(x: 68, y: 38))
        path.addCurve(to: CGPoint(x: 98, y: 30), control1: CGPoint(x: 78, y: 28), control2: CGPoint(x: 88, y: 33))
        path.addCurve(to: CGPoint(x: 66, y: 14), control1: CGPoint(x: 88, y: 18), control2: CGPoint(x: 75, y: 12))
        path.addCurve(to: CGPoint(x: 60, y: 2), control1: CGPoint(x: 63, y: 13), control2: CGPoint(x: 62, y: 5))
        path.addCurve(to: CGPoint(x: 50, y: 15), control1: CGPoint(x: 58, y: 4), control2: CGPoint(x: 53, y: 12))
        path.closeSubpath()
        return path.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
    }
}

struct LoginView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var session: Session

    @State private var modoRegistro = false
    @State private var usuario = ""
    @State private var password = ""
    @State private var confirmacion = ""
    @State private var error: String?
    @State private var exito: String?
    @State private var animada = false

    var body: some View {
        ZStack {
            Fondo.gradiente.ignoresSafeArea()

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 30)

                        CristalCard(padding: 18) {
                            VStack(spacing: 0) {
                                VStack(spacing: 8) {
                                    BatSymbol()
                                        .fill(Color.white.opacity(0.7))
                                        .frame(width: 44, height: 26.4)
                                        .shadow(color: .white.opacity(0.05), radius: 20)
                                        .padding(.bottom, 6)

                                    Text("FINANCE")
                                        .font(Fuente(20, .bold))
                                        .kerning(3)
                                        .foregroundColor(.white)

                                    Rectangle()
                                        .fill(Colores.accent)
                                        .frame(width: 32, height: 1.5)
                                        .shadow(color: Colores.accent.opacity(0.3), radius: 6)
                                }
                                .padding(.top, 10)

                                if let error = error {
                                    AlertaWayne(mensaje: error, exito: false)
                                        .padding(.top, 22)
                                }
                                if let exito = exito {
                                    AlertaWayne(mensaje: exito, exito: true)
                                        .padding(.top, 22)
                                }

                                VStack(alignment: .leading, spacing: 0) {
                                    CampoWayne(titulo: "User ID", placeholder: "USER ID", texto: $usuario)
                                        .padding(.top, 24)
                                    CampoWayne(titulo: "Access Code", placeholder: "ACCESS CODE", texto: $password, isSecure: true)
                                    if modoRegistro {
                                        CampoWayne(titulo: "Confirm Access Code", placeholder: "CONFIRM ACCESS CODE", texto: $confirmacion, isSecure: true)
                                    }
                                }

                                BtnWayne(texto: modoRegistro ? "CREATE ACCOUNT" : "AUTHORIZE") {
                                    accionPrincipal()
                                }
                                .padding(.top, 2)

                                Button(action: { withAnimation(.easeInOut(duration: 0.25)) {
                                    modoRegistro.toggle()
                                    error = nil
                                    exito = nil
                                } }) {
                                    Text(modoRegistro ? "← Back to login" : "Create your own account")
                                        .font(Fuente(12, .medium))
                                        .foregroundColor(Colores.textoSec)
                                        .padding(.top, 18)
                                }
                            }
                        }
                        .frame(maxWidth: 400)
                        .padding(.horizontal, 24)
                        .opacity(animada ? 1 : 0)
                        .offset(y: animada ? 0 : 12)
                        .animation(.easeOut(duration: 0.6), value: animada)

                        Spacer(minLength: 30)
                    }
                    .frame(minHeight: geo.size.height)
                    .frame(maxWidth: 400)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .onAppear { animada = true }
    }

    private func accionPrincipal() {
        if modoRegistro {
            do {
                try session.registrar(usuario: usuario, password: password, confirmacion: confirmacion, context: context)
            } catch {
                self.error = error.localizedDescription
            }
        } else {
            if session.iniciarSesion(usuario: usuario, password: password, context: context) {
                error = nil
            } else {
                error = "Invalid username or password."
            }
        }
    }
}
