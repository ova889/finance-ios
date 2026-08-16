import SwiftUI
import SwiftData

struct RecurrentesView: View {
    let userId: String
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var recurrentes: [Recurrente]

    @State private var tipo = "gasto"
    @State private var tipoDisplay = "Expense"
    @State private var categoria = Categorias.gasto[0]
    @State private var montoTexto = ""
    @State private var descripcion = ""
    @State private var dia = 1
    @FocusState private var montoEnfocado: Bool
    @FocusState private var descripcionEnfocada: Bool

    init(userId: String) {
        self.userId = userId
        _recurrentes = Query(filter: #Predicate<Recurrente> { $0.userId == userId })
    }

    private var delUsuario: [Recurrente] {
        recurrentes.filter { $0.userId == userId }.sorted { ($0.dia, $0.categoria) < ($1.dia, $1.categoria) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(Fuente(15, .semibold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                Spacer()
                Text("Recurring")
                    .font(Fuente(20, .bold))
                    .kerning(-0.5)
                    .foregroundColor(.white)
                Spacer()
                Color.clear.frame(width: 34, height: 34)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 6)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    CristalCard(padding: 16) {
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                campoMonto
                                campoDia
                            }
                            HStack(spacing: 8) {
                                campoTipo
                                campoCategoria
                            }
                            campoDescripcion

                            BtnWayne(texto: "Add Recurring", pequeno: true) {
                                guardar()
                            }
                        }
                    }

                    if delUsuario.isEmpty {
                        Text("No recurring transactions set.")
                            .font(Fuente(13))
                            .foregroundColor(Colores.textoSec)
                            .padding(.top, 40)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(delUsuario, id: \.id) { r in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(r.descripcion.isEmpty ? r.categoria : r.descripcion)
                                            .font(Fuente(15, .medium))
                                            .foregroundColor(.white)
                                        HStack(spacing: 4) {
                                            Text("\(r.categoria) · Day \(r.dia) ·")
                                                .font(Fuente(11))
                                                .foregroundColor(Colores.textoSec)
                                            MontoPrivado(texto: formatoConSigno(r.monto, esIngreso: r.esIngreso), fuente: Fuente(11, .semibold))
                                                .foregroundColor(r.esIngreso ? Colores.verde : Colores.rojo)
                                        }
                                    }
                                    Spacer()
                                    Button {
                                        pendienteEliminar = r
                                    } label: {
                                        IconoBasura()
                                            .stroke(.white.opacity(0.28), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                            .frame(width: 16, height: 16)
                                            .frame(width: 30, height: 30)
                                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.03), lineWidth: 1))
                                    }
                                }
                                .padding(14)
                                .background(Colores.cardBg.opacity(0.55))
                                .vidrio()
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.04), lineWidth: 1))
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        .scrollDismissesKeyboard(.interactively)
        }
        .background(Fondo.gradiente.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .alert("Delete recurring?", isPresented: Binding(get: { pendienteEliminar != nil }, set: { if !$0 { pendienteEliminar = nil } })) {
            Button("Delete", role: .destructive) {
                if let r = pendienteEliminar {
                    eliminar(r)
                }
                pendienteEliminar = nil
            }
            Button("Cancel", role: .cancel) { pendienteEliminar = nil }
        } message: {
            if let r = pendienteEliminar {
                Text("This will permanently delete the recurring \"\(r.descripcion.isEmpty ? r.categoria : r.descripcion)\". This action cannot be undone.")
            }
        }
    }

    @State private var pendienteEliminar: Recurrente?

    private var campoMonto: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Amount")
                .font(Fuente(11, .medium))
                .foregroundColor(Colores.textoSec)
            TextField("0.00", text: $montoTexto)
                .keyboardType(.decimalPad)
                .focused($montoEnfocado)
                .font(Fuente(16))
                .padding(.horizontal, 16)
                .frame(height: DesignTokens.campoAltura)
                .bordeCampo(enfocado: montoEnfocado)
        }
    }

    private var campoDia: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Day")
                .font(Fuente(11, .medium))
                .foregroundColor(Colores.textoSec)
            Stepper(value: $dia, in: 1...31) {
                Text("\(dia)")
                    .font(Fuente(14))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .frame(height: DesignTokens.campoAltura)
            .bordeCampo()
        }
    }

    private var campoTipo: some View {
        VistaDropdown(
            titulo: "Type",
            opciones: ["Expense", "Income"],
            seleccion: $tipoDisplay,
            margenInferior: 0
        )
        .onChange(of: tipoDisplay) { _, nuevo in
            tipo = nuevo == "Income" ? "ingreso" : "gasto"
            categoria = nuevo == "Income" ? Categorias.ingreso[0] : Categorias.gasto[0]
        }
    }

    private var campoCategoria: some View {
        VistaDropdown(
            titulo: "Category",
            opciones: Categorias.lista(para: tipo),
            seleccion: $categoria,
            margenInferior: 0
        )
    }

    private var campoDescripcion: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Description")
                .font(Fuente(11, .medium))
                .foregroundColor(Colores.textoSec)
            TextField("Netflix", text: $descripcion)
                .font(Fuente(16))
                .focused($descripcionEnfocada)
                .padding(.horizontal, 16)
                .frame(height: DesignTokens.campoAltura)
                .bordeCampo(enfocado: descripcionEnfocada)
                .bordeCampo(enfocado: descripcionEnfocada)
        }
    }

    private func guardar() {
        guard let monto = Double(montoTexto.replacingOccurrences(of: ",", with: ".")),
              monto > 0, (1...31).contains(dia) else { return }
        let nuevo = Recurrente(
            tipo: tipo,
            categoria: categoria,
            monto: monto,
            descripcion: descripcion.trimmingCharacters(in: .whitespaces),
            dia: dia,
            userId: userId
        )
        context.insert(nuevo)
        try? context.save()
        montoTexto = ""
        descripcion = ""
    }

    private func eliminar(_ r: Recurrente) {
        context.delete(r)
        try? context.save()
    }
}
