import SwiftUI
import SwiftData
import LocalAuthentication

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
    @State private var splash = true
    @State private var pulso = false
    @State private var dragOffset = CGSize.zero
    @State private var bloqueada = false
    @State private var autenticando = false
    @Environment(\.scenePhase) private var scenePhase
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
            .scaleEffect(splash ? 1.04 : 1)
            .blur(radius: splash ? 6 : 0)
            .animation(.easeOut(duration: 0.45), value: splash)

            barraNavegacion
            DropdownHost()

            if splash {
                pantallaBienvenida
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            if bloqueada {
                pantallaBloqueo
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(2000)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            latido = true
            pulso = true
            if splash {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_050_000_000)
                    withAnimation(.easeOut(duration: 0.5)) {
                        splash = false
                    }
                    if hayAutenticacion() {
                        bloqueada = true
                        autenticar()
                    }
                }
            }
        }
        .onChange(of: scenePhase) { _, nueva in
            switch nueva {
            case .background:
                if !bloqueada && hayAutenticacion() {
                    bloqueada = true
                }
            case .active:
                if bloqueada {
                    autenticar()
                }
            default:
                break
            }
        }
    }

    private var pantallaBloqueo: some View {
        ZStack {
            Fondo.gradiente
            VStack(spacing: 14) {
                IconoW()
                    .foregroundStyle(Color.white)
                    .frame(width: 38, height: 38)
                Text("FINANCE")
                    .font(Fuente(18, .bold))
                    .kerning(6)
                    .foregroundColor(.white)
                Text("Locked")
                    .font(Fuente(12))
                    .foregroundColor(.white.opacity(0.4))
                Button {
                    autenticar()
                } label: {
                    Image(systemName: "faceid")
                        .font(Fuente(28))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 64, height: 64)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(PressStyle(escala: 0.92))
                .padding(.top, 8)
            }
        }
        .background(Color.black)
    }

    private func hayAutenticacion() -> Bool {
        let contexto = LAContext()
        var error: NSError?
        let conBiometria = contexto.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if conBiometria { return true }
        return contexto.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    @MainActor
    private func autenticar() {
        guard !autenticando else { return }
        let contexto = LAContext()
        var error: NSError?
        let biometrica = contexto.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        guard biometrica || contexto.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            withAnimation(.easeOut(duration: 0.3)) {
                bloqueada = false
            }
            return
        }
        autenticando = true
        contexto.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Unlock Wayne Finance"
        ) { exito, err in
            let fallback = !exito && (err as? LAError).map {
                $0.code == .biometryNotAvailable || $0.code == .biometryNotEnrolled || $0.code == .biometryLockout
            } ?? false
            DispatchQueue.main.async {
                autenticarFallback(si: fallback, exito: exito)
            }
        }
    }

    @MainActor
    private func autenticarFallback(si esNecesario: Bool, exito: Bool) {
        guard esNecesario else {
            autenticando = false
            withAnimation(.easeOut(duration: 0.35)) {
                bloqueada = !exito
            }
            return
        }
        let contexto = LAContext()
        contexto.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Unlock Wayne Finance"
        ) { exito2, _ in
            DispatchQueue.main.async {
                autenticando = false
                withAnimation(.easeOut(duration: 0.35)) {
                    bloqueada = !exito2
                }
            }
        }
    }

    private var pantallaBienvenida: some View {
        ZStack {
            Fondo.gradiente
            VStack(spacing: 16) {
                IconoW()
                    .foregroundStyle(Color.white)
                    .frame(width: 46, height: 46)
                    .shadow(color: Color.white.opacity(0.3), radius: 20)
                Text("FINANCE")
                    .font(Fuente(24, .bold))
                    .kerning(7)
                    .foregroundColor(.white)
                Rectangle()
                    .fill(Colores.accent)
                    .frame(width: 40, height: 2)
                    .shadow(color: Colores.accent.opacity(0.5), radius: 8)
            }
            .scaleEffect(pulso ? 1.06 : 0.96)
            .opacity(pulso ? 1 : 0.35)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulso)
        }
        .background(Color.black)
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Button {
                activarPanico()
            } label: {
                HStack(spacing: 6) {
                    IconoW()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(Color.white.opacity(0.5))
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
        HStack(spacing: 24) {
            ForEach(TabPrincipal.allCases, id: \.self) { item in
                let activo = tab == item
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        tab = item
                    }
                } label: {
                    iconoNavegacion(item)
                        .frame(width: 22, height: 22)
                        .frame(width: 38, height: 38)
                        .scaleEffect(activo ? 1 : 0.92)
                        .overlay(
                            Group {
                                if activo {
                                    Capsule()
                                        .fill(Color.white.opacity(0.08))
                                        .matchedGeometryEffect(id: "pill-activo", in: navEspacio)
                                }
                            }
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(barraCristal)
        .clipShape(Capsule())
        .compositingGroup()
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
        .padding(.horizontal, 12)
        .offset(y: dragOffset.height)
        .gesture(
            DragGesture()
                .onChanged { valor in
                    let dy = valor.translation.height
                    dragOffset = CGSize(width: 0, height: dy < 0 ? dy * 0.25 : dy * 0.45)
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        dragOffset = .zero
                    }
                }
        )
        .padding(.bottom, 24)
    }

    private var barraCristal: some View {
        ZStack {
            Capsule()
                .fill(.ultraThinMaterial)
            Capsule()
                .fill(Color.black.opacity(0.6))
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.07), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(height: 22)
                .padding(.horizontal, 1)
                .blendMode(.overlay)
                .allowsHitTesting(false)
        }
        .environment(\.colorScheme, .dark)
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
