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

struct WayIcono: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.03))
                .frame(width: 44, height: 44)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
            BatSymbol()
                .fill(Color.white.opacity(0.6))
                .frame(width: 26, height: 15.6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

    var body: some View {
        ZStack {
            Fondo.gradiente.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 70)

                    VStack(spacing: 20) {
                        WayIcono()

                        Text("FINANCE")
                            .font(.system(size: 22, weight: .bold))
                            .kerning(3)
                            .foregroundColor(.white)

                        Rectangle()
                            .fill(Colores.accent)
                            .frame(width: 32, height: 1.5)
                            .shadow(color: Colores.accent.opacity(0.3), radius: 6)
                    }

                    Spacer(minLength: 32)

                    if let error = error {
                        AlertaWayne(mensaje: error, exito: false)
                    }
                    if let exito = exito {
                        AlertaWayne(mensaje: exito, exito: true)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        CampoWayne(titulo: "User ID", placeholder: "USER ID", texto: $usuario)
                        CampoWayne(titulo: "Access Code", placeholder: "ACCESS CODE", texto: $password, isSecure: true)
                        if modoRegistro {
                            CampoWayne(titulo: "Confirm Access Code", placeholder: "CONFIRM ACCESS CODE", texto: $confirmacion, isSecure: true)
                        }
                    }

                    BtnWayne(texto: modoRegistro ? "CREATE ACCOUNT" : "AUTHORIZE") {
                        accionPrincipal()
                    }
                    .padding(.top, 4)

                    Button(action: { withAnimation(.easeInOut(duration: 0.25)) {
                        modoRegistro.toggle()
                        error = nil
                        exito = nil
                    } }) {
                        Text(modoRegistro ? "← Back to login" : "Create your own account")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Colores.textoSec)
                            .padding(.top, 18)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .frame(maxWidth: 400)
                .frame(maxWidth: .infinity)
            }
        }
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
