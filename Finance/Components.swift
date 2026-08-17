import SwiftUI

struct MontoPrivado: View {
    var texto: String
    var fuente: Font? = nil
    @AppStorage("privacyMode") private var privacyMode = false

    var body: some View {
        Text(texto)
            .font(fuente)
            .fontWeight(.bold)
            .blur(radius: privacyMode ? 8 : 0)
            .animation(.easeInOut(duration: 0.25), value: privacyMode)
    }
}

struct DoughnutSlice: Identifiable {
    let id: String
    let nombre: String
    let valor: Double
    let color: Color
}

struct DoughnutChart: View {
    let slices: [DoughnutSlice]

    @State private var avanzado = false
    @State private var activas: Set<String> = []

    private var visibles: [DoughnutSlice] {
        let filtradas = slices.filter { activas.contains($0.id) }
        return filtradas.isEmpty ? slices : filtradas
    }

    private var total: Double {
        max(visibles.reduce(0) { $0 + $1.valor }, 0.0001)
    }

    private var cortes: [(slice: DoughnutSlice, inicio: Double, fin: Double)] {
        var acumulado: Double = 0
        return visibles.map { slice in
            let inicio = acumulado / total
            acumulado += slice.valor
            return (slice, inicio, acumulado / total)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let diametro = min(geo.size.width, geo.size.height)
                let ancho = diametro * 0.07
                let gap = 0.0035
                ZStack {
                    Circle()
                        .stroke(Color(red: 0.02, green: 0.02, blue: 0.02), style: StrokeStyle(lineWidth: ancho, lineCap: .round))
                    ForEach(cortes, id: \.slice.id) { corte in
                        Circle()
                            .trim(
                                from: avanzado ? min(corte.inicio + gap, 1) : 0,
                                to: avanzado ? max(corte.fin - gap, 0) : 0
                            )
                            .stroke(corte.slice.color, style: StrokeStyle(lineWidth: ancho, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    VStack(spacing: 4) {
                        Text("TOTAL GASTADO")
                            .font(Fuente(9, .semibold))
                            .kerning(0.8)
                            .foregroundColor(Colores.textoSec.opacity(0.7))
                        MontoPrivado(
                            texto: formatoMonto(total),
                            fuente: .system(size: 28, weight: .bold, design: .rounded)
                        )
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: total))
                        .animation(.easeOut(duration: 0.5), value: total)
                    }
                }
                .frame(width: diametro, height: diametro)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.timingCurve(0.0, 0.0, 0.58, 1.0, duration: 0.8), value: avanzado)
            }
            .frame(height: 132)

            VStack(spacing: 0) {
                ForEach(Array(slices.enumerated()), id: \.element.id) { indice, slice in
                    let encendida = activas.isEmpty || activas.contains(slice.id)
                    Button {
                        withAnimation(.easeOut(duration: 0.4)) {
                            if activas.contains(slice.id) {
                                activas.remove(slice.id)
                            } else {
                                activas.insert(slice.id)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(slice.color.opacity(encendida ? 1 : 0.15))
                                .frame(width: 10, height: 10)
                            Text(slice.nombre)
                                .font(Fuente(13))
                                .foregroundColor(.white.opacity(encendida ? 0.85 : 0.35))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                            MontoPrivado(texto: formatoMonto(slice.valor), fuente: Fuente(13, .semibold))
                                .foregroundColor(.white.opacity(encendida ? 1 : 0.35))
                                .monospacedDigit()
                            Text(pct(slice.valor))
                                .font(Fuente(12))
                                .foregroundColor(Colores.textoSec)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.05))
                                .opacity(encendida ? 0 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                    if indice < slices.count - 1 {
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 0.5)
                            .padding(.leading, 36)
                    }
                }
            }
        }
        .onAppear { avanzado = true }
    }

    private func pct(_ valor: Double) -> String {
        String(format: "%.0f%%", (valor / total) * 100)
    }
}

struct ToastWayne: View {
    var mensaje: String
    var tipo: TipoToast
    @Binding var visible: Bool

    enum TipoToast {
        case exito, warning, info
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icono)
                .font(Fuente(15))
            Text(mensaje)
                .font(Fuente(13, .medium))
                .lineLimit(2)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(red: 0.078, green: 0.078, blue: 0.098).opacity(0.92))
        .vidrio(saturacion: 1.8)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.6), radius: 32, y: 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .task(id: visible) {
            guard visible else { return }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation(.easeOut(duration: 0.3)) { visible = false }
        }
    }

    private var icono: String {
        switch tipo {
        case .exito: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}
