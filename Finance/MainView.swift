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
    @State private var latido = false
    @Namespace private var navEspacio
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
            DropdownHost()
        }
        .preferredColorScheme(.dark)
        .onAppear { latido = true }
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

            MontoPrivado(texto: formatoMonto(balance), fuente: Fuente(12, .bold))
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
                .scaleEffect(latido ? 1.3 : 1)
                .shadow(color: Colores.verde.opacity(latido ? 0.6 : 0.25), radius: latido ? 8 : 3)
                .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: latido)

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

    @ViewBuilder
    private func capaActiva() -> some View {
        LinearGradient(
            colors: [Color.white.opacity(0.28), Color.white.opacity(0.10)],
            startPoint: .top, endPoint: .bottom
        )
        .clipShape(Capsule())
        .matchedGeometryEffect(id: "pill-activo", in: navEspacio)
        .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0.5))
    }

    private func iconoNavegacion(_ item: TabPrincipal) -> some View {
        let activo = tab == item
        let color = activo ? Color.white : Color.white.opacity(0.55)
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
        HStack(spacing: 22) {
            ForEach(TabPrincipal.allCases, id: \.self) { item in
                let activo = tab == item
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        tab = item
                    }
                } label: {
                    iconoNavegacion(item)
                        .frame(width: 22, height: 22)
                        .frame(width: 46, height: 38)
                        .scaleEffect(activo ? 1 : 0.94)
                        .overlay(activo ? AnyView(capaActiva()) : AnyView(EmptyView()))
                        .contentShape(Capsule())
                }
                .buttonStyle(PressLiquido())
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 64)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                startPoint: .top, endPoint: .bottom
            )
            .blendMode(.plusLighter)
        )
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.28), lineWidth: 1))
        .overlay(Capsule().inset(by: 0.5).stroke(Color.black.opacity(0.15), lineWidth: 0.5))
        .overlay(alignment: .top) {
            Capsule()
                .fill(LinearGradient(
                    colors: [Color.white.opacity(0.22), .clear],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(height: 32)
                .padding(.horizontal, 1)
                .blendMode(.overlay)
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.4), radius: 24, y: 14)
        .shadow(color: .black.opacity(0.25), radius: 6, y: 4)
        .padding(.bottom, 24)
    }

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
