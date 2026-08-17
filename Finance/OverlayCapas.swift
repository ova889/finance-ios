import SwiftUI

@MainActor
final class OverlayCapas: ObservableObject {
    struct Pedido: Identifiable {
        let id: UUID
        let opciones: [String]
        let seleccion: String
        let onSeleccionar: (String) -> Void
        let origen: CGRect
        let ancho: CGFloat
        let alinearDerecha: Bool
    }

    @Published var pedido: Pedido?

    func presentar(_ pedido: Pedido) {
        self.pedido = pedido
    }

    func cerrar(siEs id: UUID) {
        if pedido?.id == id { pedido = nil }
    }

    func cerrar() {
        pedido = nil
    }
}

struct DropdownHost: View {
    @EnvironmentObject private var capas: OverlayCapas

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let pedido = capas.pedido {
                GeometryReader { geo in
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { capas.cerrar() }
                    PanelDropdown(pedido: pedido, altoPantalla: geo.size.height, anchoPantalla: geo.size.width)
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .zIndex(1000)
        .animation(.easeOut(duration: 0.15), value: capas.pedido?.id)
    }
}

    private struct PanelDropdown: View {
        let pedido: OverlayCapas.Pedido
        let altoPantalla: CGFloat
        let anchoPantalla: CGFloat

        @EnvironmentObject private var capas: OverlayCapas

        private var anchoPanel: CGFloat { max(pedido.ancho, 200) }
        private var altoFila: CGFloat { 36 }
        private var altoMaximo: CGFloat { 240 }

        var body: some View {
            let altoFilas = CGFloat(pedido.opciones.count) * altoFila + 12
            let altoPanel = min(altoFilas, altoMaximo)
            let sube = pedido.origen.maxY + altoPanel + 12 > altoPantalla - 40
            let yBase = sube ? pedido.origen.minY - altoPanel - 6 : pedido.origen.maxY + 6
            let yClamped = max(min(yBase, altoPantalla - altoPanel - 10), 10)
            let xCentro = pedido.alinearDerecha ? pedido.origen.maxX - anchoPanel / 2 : pedido.origen.minX + anchoPanel / 2
            let xClamped = max(min(xCentro, anchoPantalla - anchoPanel / 2 - 10), anchoPanel / 2 + 10)
            VStack(spacing: 0) {
                if altoFilas > altoPanel {
                    ScrollView(showsIndicators: false) {
                        opciones
                    }
                } else {
                    opciones
                }
            }
            .frame(width: anchoPanel)
            .frame(minHeight: 0, maxHeight: altoFilas > altoPanel ? altoPanel : .infinity)
            .padding(6)
            .background(Color.black.opacity(0.85))
            .vidrio(saturacion: 1.8)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .shadow(color: .black.opacity(0.6), radius: 40, y: 12)
            .position(x: xClamped, y: yClamped + altoPanel / 2)
            .transition(.opacity.combined(with: .offset(y: sube ? -4 : 4)))
        }

    @ViewBuilder
    private var opciones: some View {
        ForEach(pedido.opciones, id: \.self) { op in
            Button {
                pedido.onSeleccionar(op)
                capas.cerrar()
            } label: {
                HStack(spacing: 10) {
                    Text(op)
                        .font(Fuente(13, op == pedido.seleccion ? .semibold : .regular))
                        .foregroundColor(op == pedido.seleccion ? .white : .white.opacity(0.7))
                    Spacer()
                    if op == pedido.seleccion {
                        Image(systemName: "checkmark")
                            .font(Fuente(11, .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(height: 36)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressStyle(escala: 0.97))
        }
    }
}