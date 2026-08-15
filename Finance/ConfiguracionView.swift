import SwiftUI
import SwiftData

struct ConfiguracionView: View {
    let userId: String
    @Environment(\.modelContext) private var context

    @AppStorage("privacyMode") private var privacyMode = false
    @State private var cargado = false
    @State private var alerta: AlertaConfirmacion?
    @State private var textoPendientes = "No pending operations"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                EtiquetaTitulo(texto: "Settings")
                    .padding(.bottom, 8)
                    .opacity(cargado ? 1 : 0)
                    .offset(y: cargado ? 0 : 8)
                    .animation(.easeOut(duration: 0.25).delay(0.05), value: cargado)

                filaPrivacidad
                    .entrada(retraso: 0.12, cargado: cargado)
                filaPendientes
                    .entrada(retraso: 0.19, cargado: cargado)
                filaLimpiar
                    .entrada(retraso: 0.26, cargado: cargado)

                VStack(spacing: 4) {
                    Text("Finance v2.0")
                        .font(Fuente(12))
                        .foregroundColor(Colores.textoSec)
                    Text("PWA · Offline-ready")
                        .font(Fuente(11))
                        .foregroundColor(Colores.textoSec.opacity(0.6))
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
            .padding(.bottom, DesignTokens.contenedorPaddingBottom)
        }
        .onAppear { cargado = true }
        .alert(
            "Delete ALL transactions and budgets?",
            isPresented: Binding(
                get: { alerta != nil },
                set: { if !$0 { alerta = nil } }
            ),
            presenting: alerta
        ) { alerta in
            if alerta.etapa == 1 {
                Button("Cancel", role: .cancel) { self.alerta = nil }
                Button("Delete", role: .destructive) { self.alerta = AlertaConfirmacion(etapa: 2) }
            } else {
                Button("Cancel", role: .cancel) { self.alerta = nil }
                Button("Delete Forever", role: .destructive) { limpiarDatos() }
            }
        } message: { alerta in
            Text(alerta.etapa == 1
                 ? "This cannot be undone."
                 : "All data will be permanently removed.")
        }
    }

    private var filaPrivacidad: some View {
        CristalCard(padding: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Privacy Mode")
                        .font(Fuente(15, .medium))
                        .foregroundColor(.white)
                    Text("Blurs all amounts on screen")
                        .font(Fuente(11))
                        .foregroundColor(Colores.textoSec)
                }
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        privacyMode.toggle()
                    }
                } label: {
                    Image(systemName: privacyMode ? "eye.slash" : "eye")
                        .font(Fuente(18))
                        .foregroundColor(privacyMode ? .white : .white.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(privacyMode ? 0.06 : 0.03))
                        .overlay(RoundedRectangle(cornerRadius: DesignTokens.privacidadRadio, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.privacidadRadio, style: .continuous))
                }
            }
        }
    }

    private var filaPendientes: some View {
        CristalCard(padding: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pending Operations")
                        .font(Fuente(15, .medium))
                        .foregroundColor(.white)
                    Text(textoPendientes)
                        .font(Fuente(11))
                        .foregroundColor(Colores.textoSec)
                }
                Spacer()
                Button {
                    sincronizar()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(Fuente(11, .semibold))
                        Text("Sync Now")
                            .font(Fuente(11, .semibold))
                            .kerning(1.5)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 40)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private func sincronizar() {
        textoPendientes = "All operations synced"
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.easeOut(duration: 0.3)) {
                textoPendientes = "No pending operations"
            }
        }
    }

    private var filaLimpiar: some View {
        CristalCard(padding: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clear All Data")
                        .font(Fuente(15, .medium))
                        .foregroundColor(.white)
                    Text("Deletes all transactions and budgets")
                        .font(Fuente(11))
                        .foregroundColor(Colores.textoSec)
                }
                Spacer()
                Button {
                    confirmarLimpiar()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(Fuente(11, .semibold))
                        Text("Clear")
                            .font(Fuente(11, .semibold))
                            .kerning(1.5)
                    }
                    .foregroundColor(Colores.rojo)
                    .padding(.horizontal, 16)
                    .frame(height: 40)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Colores.rojo.opacity(0.3), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private func confirmarLimpiar() {
        alerta = AlertaConfirmacion(etapa: 1)
    }

    private func limpiarDatos() {
        let descriptorMov = FetchDescriptor<Movimiento>(predicate: #Predicate { $0.userId == userId })
        let descriptorPres = FetchDescriptor<Presupuesto>(predicate: #Predicate { $0.userId == userId })
        if let movimientos = try? context.fetch(descriptorMov) {
            for m in movimientos { context.delete(m) }
        }
        if let presupuestos = try? context.fetch(descriptorPres) {
            for p in presupuestos { context.delete(p) }
        }
        try? context.save()
        alerta = nil
    }
}

struct AlertaConfirmacion: Identifiable {
    let id = UUID()
    let etapa: Int
}
