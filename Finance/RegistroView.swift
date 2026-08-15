import SwiftUI
import SwiftData

struct RegistroView: View {
    let userId: String
    @Environment(\.modelContext) private var context

    @State private var montoTexto = ""
    @State private var tipo = "ingreso"
    @State private var categoria = Categorias.ingreso[0]
    @State private var descripcion = ""
    @State private var fecha = Date()
    @State private var mensaje: String?
    @State private var exito = false
    @FocusState private var montoEnfocado: Bool
    @FocusState private var descripcionEnfocada: Bool

    private var descripcionesUsadas: [String] {
        (UserDefaults.standard.array(forKey: "finance_descs_\(userId)") as? [String]) ?? []
    }

    private var campoFondo: Color {
        montoEnfocado ? Color.black.opacity(0.5) : Colores.campoBg
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                EtiquetaTitulo(texto: "Add Transaction")
                    .padding(.bottom, 14)

                if let mensaje = mensaje {
                    AlertaWayne(mensaje: mensaje, exito: exito)
                }

                CristalCard(padding: 24, radius: 24) {
                    VStack(spacing: 0) {
                        TextField("0.00", text: $montoTexto)
                            .keyboardType(.decimalPad)
                            .focused($montoEnfocado)
                            .font(Fuente(32, .bold))
                            .kerning(-0.5)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .padding(.vertical, 20)
                            .background(campoFondo)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(montoEnfocado ? Colores.accent : Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: montoEnfocado ? Colores.accent.opacity(0.15) : .clear, radius: 3)
                            .padding(.bottom, 20)

                        HStack(spacing: 10) {
                            ChipTipo(texto: "INCOME", activo: tipo == "ingreso", estilo: .blanco) {
                                cambiarTipo("ingreso")
                            }
                            ChipTipo(texto: "EXPENSE", activo: tipo == "gasto", estilo: .rojo) {
                                cambiarTipo("gasto")
                            }
                        }
                        .padding(.bottom, 18)

                        VistaDropdown(titulo: "Category", opciones: Categorias.lista(para: tipo), seleccion: $categoria)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description (optional)")
                                .font(Fuente(11, .medium))
                                .foregroundColor(Colores.textoSec)

                            if !descripcionesUsadas.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(descripcionesUsadas, id: \.self) { desc in
                                            Button {
                                                descripcion = desc
                                            } label: {
                                                Text(desc)
                                                    .font(Fuente(12))
                                                    .foregroundColor(.white.opacity(0.6))
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 5)
                                                    .background(Colores.campoBg)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                                .padding(.bottom, 6)
                            }

                            TextField("Add a note", text: $descripcion)
                                .font(Fuente(16))
                                .focused($descripcionEnfocada)
                                .padding(.horizontal, 16)
                                .frame(height: 48)
                                .bordeCampo(enfocado: descripcionEnfocada)
                        }
                        .padding(.bottom, 18)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Date")
                                .font(Fuente(11, .medium))
                                .foregroundColor(Colores.textoSec)
                            DatePicker("", selection: $fecha, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .colorScheme(.dark)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .padding(.horizontal, 16)
                                .bordeCampo()
                                .tint(Colores.accent)
                        }
                        .padding(.bottom, 20)

                        BtnWayne(texto: "CONFIRM TRANSACTION") {
                            guardar()
                        }
                    }
                }
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            .padding(.bottom, DesignTokens.contenedorPaddingBottom)
        }
    }

    private func cambiarTipo(_ nuevo: String) {
        tipo = nuevo
        categoria = Categorias.lista(para: nuevo)[0]
    }

    private func guardar() {
        guard let monto = Double(montoTexto.replacingOccurrences(of: ",", with: ".")),
              monto > 0 else {
            exito = false
            mensaje = "The amount entered is not valid."
            return
        }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let mov = Movimiento(
            tipo: tipo,
            categoria: categoria,
            monto: monto,
            descripcion: descripcion.trimmingCharacters(in: .whitespaces),
            fecha: f.string(from: fecha),
            userId: userId
        )
        context.insert(mov)
        try? context.save()

        if !descripcion.trimmingCharacters(in: .whitespaces).isEmpty {
            guardarDescripcion()
        }

        exito = true
        mensaje = "Transaction saved successfully."
        montoTexto = ""
        descripcion = ""
    }

    private func guardarDescripcion() {
        var lista = descripcionesUsadas
        let valor = descripcion.trimmingCharacters(in: .whitespaces)
        if !lista.contains(valor) {
            lista.insert(valor, at: 0)
            if lista.count > 20 { lista.removeLast() }
            UserDefaults.standard.set(lista, forKey: "finance_descs_\(userId)")
        }
    }
}

enum EstiloChip {
    case blanco, rojo
}

struct ChipTipo: View {
    let texto: String
    let activo: Bool
    let estilo: EstiloChip
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            Text(texto)
                .font(Fuente(13, .semibold))
                .kerning(1)
                .foregroundColor(colorFrente)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(colorFondo)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(ScalePressStyle(presionado: .constant(false)))
    }

    private var colorFondo: Color {
        guard activo else { return Color.white.opacity(0.03) }
        switch estilo {
        case .blanco: return .white
        case .rojo: return Colores.rojo
        }
    }

    private var colorFrente: Color {
        if !activo { return Color.white.opacity(0.25) }
        switch estilo {
        case .blanco: return .black
        case .rojo: return .white
        }
    }
}
