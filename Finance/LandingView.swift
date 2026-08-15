import SwiftUI

struct LandingView: View {
    var alIniciar: () -> Void

    @State private var cargado = false
    @State private var flotando = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(red: 0.031, green: 0.031, blue: 0.047),
                    .black,
                    Color(red: 0.02, green: 0.02, blue: 0.031)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                gradient: Gradient(colors: [
                    Colores.accent.opacity(0.06),
                    Colores.accent.opacity(0.02),
                    .clear
                ]),
                center: .init(x: 0.5, y: 0.0),
                startRadius: 0,
                endRadius: 350
            )
            .frame(width: 700, height: 700)
            .offset(y: -180)
            .allowsHitTesting(false)

            CuadriculaFondo()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    logoWrap
                        .opacity(cargado ? 1 : 0)
                        .scaleEffect(cargado ? 1 : 0.85)
                        .rotationEffect(.degrees(cargado ? 0 : -6))
                        .animation(.easeOut(duration: 0.8).delay(0.05), value: cargado)
                        .animation(flotando ? .easeInOut(duration: 5).repeatForever(autoreverses: true) : .default, value: flotando)

                    Text("FINANCE")
                        .font(FuenteInter(40, .heavy))
                        .kerning(-1)
                        .lineSpacing(0)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.white, Color.white.opacity(0.5)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(.top, 22)
                        .opacity(cargado ? 1 : 0)
                        .offset(y: cargado ? 0 : 20)
                        .animation(.easeOut(duration: 0.7).delay(0.2), value: cargado)

                    subTitulo
                        .padding(.top, 10)
                        .opacity(cargado ? 1 : 0)
                        .offset(y: cargado ? 0 : 20)
                        .animation(.easeOut(duration: 0.7).delay(0.3), value: cargado)

                    metricas
                        .padding(.top, 34)
                        .opacity(cargado ? 1 : 0)
                        .offset(y: cargado ? 0 : 20)
                        .animation(.easeOut(duration: 0.7).delay(0.4), value: cargado)

                    tarjetasCaracteristicas
                        .padding(.top, 14)
                        .opacity(cargado ? 1 : 0)
                        .offset(y: cargado ? 0 : 20)
                        .animation(.easeOut(duration: 0.7).delay(0.5), value: cargado)

                    botonLanzar
                        .padding(.top, 26)
                        .opacity(cargado ? 1 : 0)
                        .offset(y: cargado ? 0 : 20)
                        .animation(.easeOut(duration: 0.7).delay(0.6), value: cargado)

                    Text("PWA · Finance v2.0")
                        .font(FuenteInter(10))
                        .kerning(2)
                        .foregroundColor(.white.opacity(0.06))
                        .padding(.top, 40)
                        .padding(.bottom, 24)
                        .opacity(cargado ? 1 : 0)
                        .animation(.easeOut(duration: 0.7).delay(0.7), value: cargado)
                }
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            cargado = true
            flotando = true
        }
    }

    private var logoWrap: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.03))
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
            IconoW()
                .frame(width: 28, height: 28)
                .opacity(0.7)
        }
        .frame(width: 60, height: 60)
        .offset(y: flotando ? -5 : 0)
    }

    private var subTitulo: some View {
        Text("$ Track every dollar.\nOffline by default. Privacy first.")
            .font(FuenteInter(14))
            .multilineTextAlignment(.center)
            .foregroundColor(.white.opacity(0.3))
    }

    private var metricas: some View {
        HStack(spacing: 0) {
            metrica(valor: "+$0", color: Colores.verde, etiqueta: "Income")
            Divider()
                .overlay(Color.white.opacity(0.03))
                .frame(height: 36)
            metrica(valor: "-$0", color: Colores.rojo, etiqueta: "Expenses")
            Divider()
                .overlay(Color.white.opacity(0.03))
                .frame(height: 36)
            metrica(valor: "$0", color: .white, etiqueta: "Balance")
        }
        .padding(6)
        .background(Color.white.opacity(0.02))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func metrica(valor: String, color: Color, etiqueta: String) -> some View {
        VStack(spacing: 4) {
            Text(valor)
                .font(FuenteMono(19, .semibold))
                .kerning(-0.5)
                .foregroundColor(color)
            Text(etiqueta)
                .font(FuenteInter(10, .semibold))
                .kerning(1)
                .textCase(.uppercase)
                .foregroundColor(.white.opacity(0.15))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private var tarjetasCaracteristicas: some View {
        VStack(spacing: 6) {
            tarjetaCaracteristica(
                icono: "square.grid.2x2",
                titulo: "Dashboard",
                desc: "Balance · Charts · Budgets"
            )
            tarjetaCaracteristica(
                icono: "clock",
                titulo: "History",
                desc: "Search · Filter · Export"
            )
            tarjetaCaracteristica(
                icono: "shield",
                titulo: "Offline",
                desc: "Works without internet"
            )
        }
    }

    private func tarjetaCaracteristica(icono: String, titulo: String, desc: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icono)
                .font(FuenteInter(17))
                .foregroundColor(.white.opacity(0.2))
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(titulo)
                    .font(FuenteInter(11, .semibold))
                    .kerning(1)
                    .textCase(.uppercase)
                    .foregroundColor(.white.opacity(0.3))
                Text(desc)
                    .font(FuenteInter(11))
                    .foregroundColor(.white.opacity(0.15))
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.white.opacity(0.02))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var botonLanzar: some View {
        Button(action: alIniciar) {
            HStack(spacing: 10) {
                Text("Launch App")
                    .font(FuenteInter(16, .semibold))
                Image(systemName: "arrow.right")
                    .font(FuenteInter(13, .bold))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 36)
            .padding(.vertical, 16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .white.opacity(0.04), radius: 32, y: 4)
        }
        .buttonStyle(ScalePressStyle(presionado: .constant(false)))
    }
}

struct CuadriculaFondo: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { contexto, size in
                var path = Path()
                let paso: CGFloat = 48
                var x: CGFloat = 0
                while x <= size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += paso
                }
                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += paso
                }
                contexto.stroke(path, with: .color(.white.opacity(0.015)), lineWidth: 1)
            }
        }
    }
}
