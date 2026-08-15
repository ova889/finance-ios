import SwiftUI

struct MontoPrivado: View {
    var texto: String
    @AppStorage("privacyMode") private var privacyMode = false

    var body: some View {
        Text(privacyMode ? "••••••" : texto)
            .fontWeight(privacyMode ? .regular : .bold)
            .animation(.easeInOut(duration: 0.2), value: privacyMode)
    }
}

struct DoughnutSlice: Identifiable {
    let id = UUID()
    let nombre: String
    let valor: Double
    let color: Color
}

struct DoughnutChart: View {
    let slices: [DoughnutSlice]

    private var total: Double {
        max(slices.reduce(0) { $0 + $1.valor }, 0.0001)
    }

    private var cortes: [(slice: DoughnutSlice, inicio: Double, fin: Double)] {
        var acumulado: Double = 0
        return slices.map { slice in
            let inicio = acumulado / total
            acumulado += slice.valor
            return (slice, inicio, acumulado / total)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let ancho = min(geo.size.width, geo.size.height) * 0.16
                ZStack {
                    ForEach(cortes, id: \.slice.id) { corte in
                        Circle()
                            .trim(from: corte.inicio, to: corte.fin)
                            .stroke(corte.slice.color, style: StrokeStyle(lineWidth: ancho, lineCap: .butt))
                            .rotationEffect(.degrees(-90))
                            .padding(2)
                    }
                }
                .frame(width: min(geo.size.width, geo.size.height),
                       height: min(geo.size.width, geo.size.height))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 190)

            VStack(spacing: 6) {
                ForEach(slices) { slice in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(slice.color)
                            .frame(width: 5, height: 5)
                        Text(slice.nombre)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.45))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(formatoMonto(slice.valor))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
            }
        }
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
                .font(.system(size: 15))
            Text(mensaje)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(2)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(red: 0.078, green: 0.078, blue: 0.098).opacity(0.92))
        .background(.ultraThinMaterial)
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
