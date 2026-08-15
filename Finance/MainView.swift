import SwiftUI
import SwiftData

enum TabPrincipal: String, CaseIterable {
    case dashboard = "Dashboard"
    case historial = "History"
    case registro = "Add"
    case configuracion = "Settings"
}

struct MainView: View {
    let userId: String
    @EnvironmentObject private var session: Session

    @State private var tab: TabPrincipal = .dashboard
    @State private var tapBrand = 0
    @State private var timerPanico: Task<Void, Never>?
    @Query private var movimientos: [Movimiento]

    init(userId: String) {
        self.userId = userId
        _movimientos = Query(filter: #Predicate<Movimiento> { $0.userId == userId })
    }

    private var balance: Double {
        let ingresos = movimientos.filter { $0.esIngreso }.reduce(0) { $0 + $1.monto }
        let gastos = movimientos.filter { !$0.esIngreso }.reduce(0) { $0 + $1.monto }
        return ingresos - gastos
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Fondo.gradiente.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Group {
                    switch tab {
                    case .dashboard:
                        DashboardView(userId: userId)
                    case .historial:
                        HistorialView(userId: userId)
                    case .registro:
                        RegistroView(userId: userId)
                    case .configuracion:
                        ConfiguracionView(userId: userId)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            barraNavegacion
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Button {
                activarPanico()
            } label: {
                HStack(spacing: 6) {
                    IconoW()
                        .frame(width: 16, height: 16)
                        .opacity(0.5)
                    Text("FINANCE")
                        .font(Fuente(12, .semibold))
                        .kerning(1.5)
                        .foregroundColor(.white.opacity(0.45))
                }
            }

            Spacer()

            Text(formatoMonto(balance))
                .font(Fuente(12, .bold))
                .kerning(-0.3)
                .foregroundColor(.white)
                .monospacedDigit()
                .padding(.trailing, 8)
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 1, height: 14)
                }

            Circle()
                .fill(Colores.verde)
                .frame(width: 6, height: 6)
                .shadow(color: Colores.verde.opacity(0.4), radius: 6)

            Button(action: { session.cerrarSesion() }) {
                Text("Sign Out")
                    .font(Fuente(10, .medium))
                    .kerning(0.3)
                    .foregroundColor(Colores.rojo)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Colores.rojo.opacity(0.15), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color.black.opacity(0.55))
        .vidrio(saturacion: 1.8)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.03)).frame(height: 1).allowsHitTesting(false)
        }
    }

    private func iconoNavegacion(_ item: TabPrincipal) -> some View {
        let activo = tab == item
        let color = activo ? Color.white : Color.white.opacity(0.25)
        switch item {
        case .dashboard:
            return AnyView(IconoGrid().stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)))
        case .historial:
            return AnyView(IconoReloj().stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)))
        case .registro:
            return AnyView(IconoMas().stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)))
        case .configuracion:
            return AnyView(IconoEngranaje().stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)))
        }
    }

    private var barraNavegacion: some View {
        HStack(spacing: 6) {
            ForEach(TabPrincipal.allCases, id: \.self) { item in
                Button {
                    tab = item
                } label: {
                    iconoNavegacion(item)
                        .frame(width: DesignTokens.navIconoTamano, height: DesignTokens.navIconoTamano)
                        .frame(width: DesignTokens.navItemTamano, height: DesignTokens.navItemTamano)
                        .background(tab == item ? Color.white.opacity(0.08) : .clear)
                        .clipShape(Circle())
                }
                .buttonStyle(PressStyle(escala: 0.9))
            }
        }
        .padding(.horizontal, 16)
        .frame(width: 280, height: DesignTokens.navPillAltura)
        .background(DesignTokens.navPillFondo)
        .vidrio()
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
        .overlay(alignment: .top) {
            Capsule().fill(Color.white.opacity(0.06)).frame(height: 12).frame(maxWidth: .infinity).padding(.horizontal, 1).allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.35), radius: 32, y: 8)
        .scaleEffect(pillPresionado ? 0.97 : 1)
        .animation(.easeOut(duration: 0.1), value: pillPresionado)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pillPresionado = true }
                .onEnded { _ in pillPresionado = false }
        )
        .padding(.bottom, 24)
    }

    @State private var pillPresionado = false

    private func activarPanico() {
        tapBrand += 1
        if tapBrand >= 2 {
            tapBrand = 0
            session.cerrarSesion()
            return
        }
        timerPanico?.cancel()
        timerPanico = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            tapBrand = 0
        }
    }
}
