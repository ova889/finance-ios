import SwiftUI
import SwiftData

struct ConfiguracionView: View {
    let userId: String
    @Environment(\.modelContext) private var context

    @AppStorage("privacyMode") private var privacyMode = false
    @State private var alerta: AlertaConfirmacion?
    @State private var textoPendientes = "No pending operations"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                EtiquetaTitulo(texto: "Settings")
                    .padding(.bottom, 4)

                filaPrivacidad
                filaPendientes
                filaLimpiar

                VStack(spacing: 4) {
                    Text("Finance v2.0")
                        .font(.system(size: 12))
                        .foregroundColor(Colores.textoSec)
                    Text("100% Native · Offline-ready")
                        .font(.system(size: 11))
                        .foregroundColor(Colores.textoSec.opacity(0.6))
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)
            .padding(.bottom, 100)
        }
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
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    Text("Blurs all amounts on screen")
                        .font(.system(size: 11))
                        .foregroundColor(Colores.textoSec)
                }
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        privacyMode.toggle()
                    }
                } label: {
                    Image(systemName: privacyMode ? "eye.slash" : "eye")
                        .font(.system(size: 16))
                        .foregroundColor(privacyMode ? .white : .white.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(privacyMode ? 0.1 : 0.03))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private var filaPendientes: some View {
        CristalCard(padding: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pending Operations")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    Text(textoPendientes)
                        .font(.system(size: 11))
                        .foregroundColor(Colores.textoSec)
                }
                Spacer()
                Button {
                    sincronizar()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Sync Now")
                            .font(.system(size: 11, weight: .semibold))
                            .kerning(1.5)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 40)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    Text("Deletes all transactions and budgets")
                        .font(.system(size: 11))
                        .foregroundColor(Colores.textoSec)
                }
                Spacer()
                Button {
                    confirmarLimpiar()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                        Text("Clear")
                            .font(.system(size: 11, weight: .semibold))
                            .kerning(1.5)
                    }
                    .foregroundColor(Colores.rojo)
                    .padding(.horizontal, 14)
                    .frame(height: 40)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Colores.rojo.opacity(0.3), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
