import SwiftUI
import SwiftData

struct RecurrentesView: View {
    let userId: String
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var recurrentes: [Recurrente]

    @State private var tipo = "gasto"
    @State private var categoria = Categorias.gasto[0]
    @State private var montoTexto = ""
    @State private var descripcion = ""
    @State private var dia = 1

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
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                Spacer()
                Text("Recurring")
                    .font(.system(size: 20, weight: .bold))
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
                            .font(.system(size: 13))
                            .foregroundColor(Colores.textoSec)
                            .padding(.top, 30)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(delUsuario, id: \.id) { r in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(r.descripcion.isEmpty ? r.categoria : r.descripcion)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.white)
                                        HStack(spacing: 4) {
                                            Text("\(r.categoria) · Day \(r.dia) ·")
                                                .font(.system(size: 11))
                                                .foregroundColor(Colores.textoSec)
                                            Text(formatoConSigno(r.monto, esIngreso: r.esIngreso))
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(r.esIngreso ? Colores.verde : Colores.rojo)
                                        }
                                    }
                                    Spacer()
                                    Button {
                                        eliminar(r)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 14))
                                            .foregroundColor(Colores.rojo)
                                            .frame(width: 30, height: 30)
                                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Colores.rojo.opacity(0.15), lineWidth: 1))
                                    }
                                }
                                .padding(14)
                                .background(Colores.cardBg.opacity(0.55))
                                .background(.ultraThinMaterial)
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
        }
        .background(Fondo.gradiente.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var campoMonto: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Amount")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Colores.textoSec)
            TextField("0.00", text: $montoTexto)
                .keyboardType(.decimalPad)
                .font(.system(size: 14))
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(Colores.campoBg)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var campoDia: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Day")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Colores.textoSec)
            Stepper(value: $dia, in: 1...31) {
                Text("\(dia)")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .frame(height: 40)
            .background(Colores.campoBg)
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var campoTipo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Type")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Colores.textoSec)
            Menu {
                Button("Expense") { tipo = "gasto"; categoria = Categorias.gasto[0] }
                Button("Income") { tipo = "ingreso"; categoria = Categorias.ingreso[0] }
            } label: {
                HStack {
                    Text(tipo == "gasto" ? "Expense" : "Income")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(Colores.campoBg)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var campoCategoria: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Category")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Colores.textoSec)
            Menu {
                ForEach(Categorias.lista(para: tipo), id: \.self) { cat in
                    Button(cat) { categoria = cat }
                }
            } label: {
                HStack {
                    Text(categoria)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(Colores.campoBg)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var campoDescripcion: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Description")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Colores.textoSec)
            TextField("Netflix", text: $descripcion)
                .font(.system(size: 14))
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(Colores.campoBg)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
