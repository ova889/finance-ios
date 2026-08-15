import SwiftUI
import UIKit

enum Fondo {
    static let negro = Color(red: 0.0, green: 0.0, blue: 0.0)
    static let gradiente = RadialGradient(
        gradient: Gradient(colors: [Color(red: 0.059, green: 0.059, blue: 0.063), Color.black]),
        center: .init(x: 0.5, y: 0.0),
        startRadius: 0,
        endRadius: 900
    )
}

enum Colores {
    static let verde = Color(red: 0.188, green: 0.82, blue: 0.345)
    static let rojo = Color(red: 1.0, green: 0.271, blue: 0.227)
    static let accent = Color(red: 0.369, green: 0.361, blue: 0.902)
    static let textoSec = Color(red: 0.557, green: 0.557, blue: 0.576)
    static let cardBg = Color(red: 0.031, green: 0.031, blue: 0.047)
    static let campoBg = Color(red: 0.0, green: 0.0, blue: 0.0).opacity(0.25)
    static let borde = Color.white.opacity(0.10)
    static let bordeCard = Color.white.opacity(0.04)
    static let blancoSuave = Color.white.opacity(0.28)
}

struct CristalCard<Contenido: View>: View {
    var padding: CGFloat = 16
    var radius: CGFloat = 24
    @ViewBuilder var contenido: () -> Contenido

    var body: some View {
        contenido()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(Colores.cardBg.opacity(0.55))
            .overlay(alignment: .topLeading) {
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.06), .clear]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .allowsHitTesting(false)
            }
            .overlay(alignment: .top) {
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 1)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.04), Color.white.opacity(0.0)]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 1)
                .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 32, x: 0, y: 8)
    }
}

struct CampoWayne: View {
    var titulo: String
    var placeholder: String = ""
    @Binding var texto: String
    var isSecure: Bool = false
    var tipoTeclado: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Colores.textoSec)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $texto)
                } else {
                    TextField(placeholder, text: $texto)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(tipoTeclado)
            .font(.system(size: 16))
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(Colores.campoBg)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.bottom, 18)
        }
    }
}

struct SelectorWayne: View {
    var titulo: String
    var opciones: [String]
    @Binding var seleccion: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Colores.textoSec)
            Menu {
                ForEach(opciones, id: \.self) { op in
                    Button(op) { seleccion = op }
                }
            } label: {
                HStack {
                    Text(seleccion)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(Colores.campoBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.bottom, 18)
        }
    }
}

struct BtnWayne: View {
    var texto: String
    var pequeno: Bool = false
    var colorTexto: Color = .white
    var colorBorde: Color = .white.opacity(0.2)
    var accion: () -> Void

    @State private var presionado = false

    var body: some View {
        Button(action: accion) {
            Text(texto)
                .font(.system(size: pequeno ? 11 : 13, weight: .semibold))
                .textCase(.uppercase)
                .kerning(pequeno ? 1.5 : 2)
                .frame(maxWidth: .infinity)
                .frame(height: pequeno ? 40 : 48)
                .foregroundColor(presionado ? .black : colorTexto)
                .background(presionado ? Color.white : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(colorBorde, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(ScalePressStyle(presionado: $presionado))
    }
}

struct BtnGhost: View {
    var texto: String
    var accion: () -> Void

    var body: some View {
        Button(action: accion) {
            Text(texto)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .frame(height: 44)
                .padding(.horizontal, 18)
                .background(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(ScalePressStyle(presionado: .constant(false)))
    }
}

struct ScalePressStyle: ButtonStyle {
    @Binding var presionado: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(configuration.isPressed ? .easeOut(duration: 0.08) : .easeIn(duration: 0.15), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, nuevo in
                presionado = nuevo
            }
    }
}

struct AlertaWayne: View {
    var mensaje: String
    var exito: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: exito ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .font(.system(size: 14))
            Text(mensaje)
                .font(.system(size: 13))
        }
        .foregroundColor(exito ? Colores.verde : Colores.rojo)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background((exito ? Colores.verde : Colores.rojo).opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke((exito ? Colores.verde : Colores.rojo).opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.bottom, 14)
    }
}

struct EtiquetaTitulo: View {
    var texto: String

    var body: some View {
        Text(texto)
            .font(.system(size: 20, weight: .bold))
            .kerning(-0.5)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HTitle: View {
    var texto: String

    var body: some View {
        Text(texto)
            .font(.system(size: 13, weight: .semibold))
            .kerning(0.3)
            .textCase(.uppercase)
            .foregroundColor(Color.white.opacity(0.28))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

func formatoMonto(_ monto: Double) -> String {
    String(format: "$%.2f", monto)
}

func formatoConSigno(_ monto: Double, esIngreso: Bool) -> String {
    let signo = esIngreso ? "+" : "-"
    return signo + formatoMonto(abs(monto))
}

func hoyString() -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: Date())
}

func fechaLegible(_ fecha: String) -> String {
    let hoy = hoyString()
    if fecha == hoy { return "Today" }
    var comps = DateComponents()
    comps.day = -1
    let ayer = Calendar.current.date(byAdding: comps, to: Date()) ?? Date()
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    if fecha == f.string(from: ayer) { return "Yesterday" }
    return fecha
}

func mesActual() -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM"
    return f.string(from: Date())
}
