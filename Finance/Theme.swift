import SwiftUI
import UIKit

enum Fondo {
    static let negro = Color(red: 0.0, green: 0.0, blue: 0.0)
    static let gradiente = EllipticalGradient(
        gradient: Gradient(colors: [Color(red: 0.059, green: 0.059, blue: 0.063), Color.black]),
        center: .init(x: 0.5, y: -0.1),
        startRadiusFraction: 0.0,
        endRadiusFraction: 1.15
    )
}

func Fuente(_ size: CGFloat, _ peso: Font.Weight = .regular) -> Font {
    Font.system(size: size, weight: peso)
}

func FuenteInter(_ size: CGFloat, _ peso: Font.Weight = .regular) -> Font {
    Font.custom("Inter", size: size).weight(peso)
}

func FuenteMono(_ size: CGFloat, _ peso: Font.Weight = .regular) -> Font {
    Font.custom("JetBrains Mono", size: size).weight(peso)
}

enum Colores {
    static let verde = DesignTokens.colorGreen
    static let rojo = DesignTokens.colorRed
    static let accent = DesignTokens.colorAccent
    static let textoSec = DesignTokens.colorTextosec
    static let cardBg = Color(red: 0.031, green: 0.031, blue: 0.047)
    static let campoBg = Color(red: 0.0, green: 0.0, blue: 0.0).opacity(0.25)
    static let borde = Color.white.opacity(0.10)
    static let bordeCard = Color.white.opacity(0.04)
    static let blancoSuave = Color.white.opacity(0.28)
}

struct BordeCampo: ViewModifier {
    var enfocado: Bool

    func body(content: Content) -> some View {
        content
            .background(enfocado ? Color.black.opacity(0.5) : Colores.campoBg)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(enfocado ? Colores.accent : Color.white.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: enfocado ? Colores.accent.opacity(0.15) : .clear, radius: 3)
    }
}

struct Vidrio: ViewModifier {
    var saturacion: Double = 2.0
    var contraste: Double = 1.1

    func body(content: Content) -> some View {
        content.background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .saturation(saturacion)
                .contrast(contraste)
        }
    }
}

extension View {
    func vidrio(saturacion: Double = 2.0, contraste: Double = 1.1) -> some View {
        modifier(Vidrio(saturacion: saturacion, contraste: contraste))
    }

    func bordeCampo(enfocado: Bool = false) -> some View {
        modifier(BordeCampo(enfocado: enfocado))
    }
}

struct CristalCard<Contenido: View>: View {
    var padding: CGFloat = 16
    var radius: CGFloat = 24
    var paddingHorizontal: CGFloat? = nil
    @ViewBuilder var contenido: () -> Contenido

    var body: some View {
        contenido()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, paddingHorizontal ?? padding)
            .padding(.vertical, padding)
            .background(Colores.cardBg.opacity(0.55))
            .overlay(Color.black.opacity(0.55))
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

    @FocusState private var enfocado: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo)
                .font(Fuente(11, .medium))
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
            .focused($enfocado)
            .font(Fuente(16))
            .padding(.horizontal, 16)
            .frame(height: 48)
            .bordeCampo(enfocado: enfocado)
            .padding(.bottom, 18)
        }
    }
}

struct VistaDropdown: View {
    var titulo: String = ""
    var opciones: [String]
    @Binding var seleccion: String
    var compacto: Bool = false
    var ancho: CGFloat? = nil
    var alinearDerecha: Bool = false
    var margenInferior: CGFloat = 18

    @State private var abierto = false

    private var altura: CGFloat { compacto ? 32 : DesignTokens.campoAltura }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !titulo.isEmpty {
                Text(titulo)
                    .font(Fuente(11, .medium))
                    .foregroundColor(Colores.textoSec)
            }
            Button {
                abierto.toggle()
            } label: {
                HStack(spacing: 8) {
                    Text(seleccion)
                        .font(Fuente(compacto ? 11 : 16))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(Fuente(9, .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .rotationEffect(.degrees(abierto ? 180 : 0))
                }
                .padding(.horizontal, compacto ? 8 : 16)
                .frame(height: altura)
                .frame(maxWidth: ancho ?? .infinity)
                .bordeCampo(enfocado: abierto)
            }
            .buttonStyle(PressStyle(escala: 0.98))
            .overlay(alignment: alinearDerecha ? .topTrailing : .topLeading) {
                if abierto {
                    ZStack(alignment: alinearDerecha ? .topTrailing : .topLeading) {
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .onTapGesture { abierto = false }
                        panel
                            .padding(.top, altura + 6)
                            .transition(.opacity.combined(with: .offset(y: -8)))
                    }
                }
            }
            .padding(.bottom, margenInferior)
        }
        .animation(.easeOut(duration: 0.15), value: abierto)
    }

    private var panel: some View {
        VStack(spacing: 0) {
            ForEach(opciones, id: \.self) { op in
                Button {
                    seleccion = op
                    abierto = false
                } label: {
                    HStack(spacing: 10) {
                        Text(op)
                            .font(Fuente(13, op == seleccion ? .semibold : .regular))
                            .foregroundColor(op == seleccion ? .white : .white.opacity(0.7))
                        Spacer()
                        if op == seleccion {
                            Image(systemName: "checkmark")
                                .font(Fuente(11, .semibold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressStyle(escala: 0.97))
            }
        }
        .frame(width: max(ancho ?? 220, 200))
        .padding(6)
        .background(Color.black.opacity(0.85))
        .vidrio(saturacion: 1.8)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.6), radius: 40, y: 12)
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
                .font(Fuente(pequeno ? 11 : 13, .semibold))
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
                .font(Fuente(13, .medium))
                .foregroundColor(.white)
                .frame(height: DesignTokens.btnGhostAltura)
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

struct PressStyle: ButtonStyle {
    var escala: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? escala : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct PressLiquido: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(
                configuration.isPressed
                    ? .easeOut(duration: 0.1)
                    : .spring(response: 0.3, dampingFraction: 0.55),
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { _, pulsado in
                if pulsado {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}

struct AlertaWayne: View {
    var mensaje: String
    var exito: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: exito ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .font(Fuente(14))
            Text(mensaje)
                .font(Fuente(13))
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
    var tamano: CGFloat = 17

    var body: some View {
        Text(texto)
            .font(Fuente(tamano, .bold))
            .kerning(-0.5)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HTitle: View {
    var texto: String

    var body: some View {
        Text(texto)
            .font(Fuente(13, .semibold))
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
