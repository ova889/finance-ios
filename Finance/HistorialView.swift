import SwiftUI
import SwiftData

struct HistorialView: View {
    let userId: String
    @Environment(\.modelContext) private var context

    @Query private var movimientos: [Movimiento]

    @State private var fechasActivas = false
    @State private var desde = Date()
    @State private var hasta = Date()
    @State private var tipoFiltro = "All"
    @State private var busqueda = ""
    @State private var movimientoAEditar: Movimiento?
    @State private var archivoCompartir: ExportService.Resultado?
    @State private var cargado = false

    init(userId: String) {
        self.userId = userId
        _movimientos = Query(filter: #Predicate<Movimiento> { $0.userId == userId })
    }

    private var delUsuario: [Movimiento] {
        movimientos.filter { $0.userId == userId }
    }

    private var filtrados: [Movimiento] {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let desdeStr = fechasActivas ? f.string(from: desde) : ""
        let hastaStr = fechasActivas ? f.string(from: hasta) : ""

        return delUsuario
            .filter { m in
                if !desdeStr.isEmpty && m.fecha < desdeStr { return false }
                if !hastaStr.isEmpty && m.fecha > hastaStr { return false }
                if tipoFiltro == "Income" && !m.esIngreso { return false }
                if tipoFiltro == "Expense" && m.esIngreso { return false }
                if !busqueda.isEmpty {
                    let texto = (m.descripcion + " " + m.categoria).lowercased()
                    if !texto.contains(busqueda.lowercased()) { return false }
                }
                return true
            }
            .sorted { a, b in
                if a.fecha != b.fecha { return a.fecha > b.fecha }
                return a.monto > b.monto
            }
    }

    private var agrupados: [(fecha: String, items: [Movimiento])] {
        var grupos: [(fecha: String, items: [Movimiento])] = []
        for m in filtrados {
            if let idx = grupos.lastIndex(where: { $0.fecha == m.fecha }) {
                grupos[idx].items.append(m)
            } else {
                grupos.append((fecha: m.fecha, items: [m]))
            }
        }
        return grupos
    }

    private var totalIngresos: Double {
        filtrados.filter { $0.esIngreso }.reduce(0) { $0 + $1.monto }
    }

    private var totalGastos: Double {
        filtrados.filter { !$0.esIngreso }.reduce(0) { $0 + $1.monto }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                cabecera
                    .opacity(cargado ? 1 : 0)
                    .offset(y: cargado ? 0 : 8)
                    .animation(.easeOut(duration: 0.25).delay(0.05), value: cargado)
                filtros
                    .entrada(retraso: 0.12, cargado: cargado)
                resumenFiltros
                    .entrada(retraso: 0.19, cargado: cargado)
                buscador
                    .entrada(retraso: 0.26, cargado: cargado)
                lista
                    .entrada(retraso: 0.33, cargado: cargado)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
            .padding(.bottom, DesignTokens.contenedorPaddingBottom)
        }
        .sheet(item: $movimientoAEditar) { mov in
            EditarMovimientoSheet(movimiento: mov)
        }
        .sheet(item: $archivoCompartir) { resultado in
            ShareSheet(items: [resultado.url])
                .presentationDetents([.medium])
        }
        .alert("Delete transaction?", isPresented: Binding(get: { pendienteEliminar != nil }, set: { if !$0 { pendienteEliminar = nil } })) {
            Button("Delete", role: .destructive) {
                if let m = pendienteEliminar {
                    eliminar(m)
                }
                pendienteEliminar = nil
            }
            Button("Cancel", role: .cancel) { pendienteEliminar = nil }
        } message: {
            if let m = pendienteEliminar {
                Text("This will permanently delete \"\(m.descripcion)\" (\(String(format: "$%.2f", m.monto))). This action cannot be undone.")
            }
        }
        .onAppear { cargado = true }
    }

    private var cabecera: some View {
        HStack(alignment: .center) {
            EtiquetaTitulo(texto: "Transaction History")
            Spacer()
            HStack(spacing: 6) {
                BtnGhost(texto: "CSV") { exportarCSV() }
                BtnGhost(texto: "PDF") { exportarPDF() }
            }
        }
    }

    private var filtros: some View {
        CristalCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("From")
                            .font(Fuente(11, .medium))
                            .foregroundColor(Colores.textoSec)
                        DatePicker("From", selection: $desde, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .frame(height: 36.0)
                            .padding(.horizontal, 12)
                            .bordeCampo()
                            .tint(Colores.accent)
                            .onChange(of: desde) { _, _ in fechasActivas = true }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("To")
                            .font(Fuente(11, .medium))
                            .foregroundColor(Colores.textoSec)
                        DatePicker("To", selection: $hasta, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .frame(height: 36.0)
                            .padding(.horizontal, 12)
                            .bordeCampo()
                            .tint(Colores.accent)
                            .onChange(of: hasta) { _, _ in fechasActivas = true }
                    }
                }

                HStack(spacing: 8) {
                    VistaDropdown(
                        opciones: ["All", "Income", "Expense"],
                        seleccion: $tipoFiltro,
                        margenInferior: 0
                    )
                    .frame(maxWidth: .infinity)

                    BtnWayne(texto: "Filter", pequeno: true) {}
                        .frame(maxWidth: .infinity)

                    BtnGhost(texto: "Clear") {
                        limpiarFiltros()
                    }
                }
            }
        }
    }

    private var resumenFiltros: some View {
        HStack(spacing: 5) {
            CristalCard(padding: 10, radius: 14, paddingHorizontal: 6) {
                VStack(spacing: 4) {
                    Text("Income")
                        .font(Fuente(8, .medium))
                        .textCase(.uppercase)
                        .kerning(0.5)
                        .foregroundColor(Color.white.opacity(0.28))
                    MontoPrivado(texto: formatoMonto(totalIngresos))
                        .font(Fuente(15, .bold))
                        .kerning(-0.5)
                        .monospacedDigit()
                        .foregroundColor(Colores.verde)
                        .frame(maxWidth: .infinity)
                }
            }
            CristalCard(padding: 10, radius: 14, paddingHorizontal: 6) {
                VStack(spacing: 4) {
                    Text("Expenses")
                        .font(Fuente(8, .medium))
                        .textCase(.uppercase)
                        .kerning(0.5)
                        .foregroundColor(Color.white.opacity(0.28))
                    MontoPrivado(texto: formatoMonto(totalGastos))
                        .font(Fuente(15, .bold))
                        .kerning(-0.5)
                        .monospacedDigit()
                        .foregroundColor(Colores.rojo)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var buscador: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(Fuente(14))
                .foregroundColor(.white.opacity(0.3))
            TextField("Search transactions...", text: $busqueda)
                .font(Fuente(14))
                .foregroundColor(.white)
                .focused($busquedaEnfocada)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .bordeCampo(enfocado: busquedaEnfocada)
    }

    @FocusState private var busquedaEnfocada: Bool

    private var lista: some View {
        VStack(spacing: 0) {
            if filtrados.isEmpty {
                CristalCard(padding: 24) {
                    Text("No transactions found for these filters.")
                        .font(Fuente(13))
                        .foregroundColor(Colores.textoSec)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                ForEach(agrupados, id: \.fecha) { grupo in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(fechaLegible(grupo.fecha))
                            .font(Fuente(12, .semibold))
                            .kerning(0.5)
                            .textCase(.uppercase)
                            .foregroundColor(Color.white.opacity(0.2))
                            .padding(.top, 16)
                            .padding(.horizontal, 4)
                            .offset(x: cargado ? 0 : -8)
                            .opacity(cargado ? 1 : 0)
                            .animation(.easeOut(duration: 0.35).delay(0.35), value: cargado)

                        ForEach(grupo.items, id: \.id) { m in
                            filaMovimiento(m)
                        }
                    }
                }
            }
        }
    }

    private func filaMovimiento(_ m: Movimiento) -> some View {
        let contenido = HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(m.descripcion.isEmpty ? m.categoria : m.descripcion)
                    .font(Fuente(15, .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(m.categoria)
                    .font(Fuente(11))
                    .foregroundColor(Colores.textoSec)
            }
            Spacer()
            MontoPrivado(texto: formatoConSigno(m.monto, esIngreso: m.esIngreso))
                .font(Fuente(18, .bold))
                .kerning(-0.5)
                .monospacedDigit()
                .foregroundColor(m.esIngreso ? Colores.verde : Colores.rojo)
        }
        .padding(14)
        .background(
            ZStack {
                Colores.cardBg.opacity(0.55)
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.06), .clear, .clear]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .vidrio()
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.04), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture {
            movimientoAEditar = m
        }

        return SwipeEliminar {
            pendienteEliminar = m
        } contenido: {
            contenido
        }
        .padding(.vertical, 2)
    }

    @State private var pendienteEliminar: Movimiento?

    private func eliminar(_ m: Movimiento) {
        context.delete(m)
        try? context.save()
    }

    private func limpiarFiltros() {
        fechasActivas = false
        tipoFiltro = "All"
        busqueda = ""
        desde = Date()
        hasta = Date()
    }

    private func exportarCSV() {
        if let resultado = ExportService.generarCSV(movimientos: filtrados) {
            archivoCompartir = resultado
        }
    }

    private func exportarPDF() {
        if let resultado = ExportService.generarPDF(movimientos: filtrados) {
            archivoCompartir = resultado
        }
    }
}

struct SwipeEliminar<Contenido: View>: View {
    let onEliminar: () -> Void
    @ViewBuilder var contenido: Contenido

    @State private var offset: CGFloat = 0
    @State private var arrastrando = false
    private let anchoBotones: CGFloat = 90

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(action: onEliminar) {
                VStack(spacing: 3) {
                    IconoBasura()
                        .stroke(.white.opacity(0.85), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                        .frame(width: 22, height: 22)
                    Text("Delete")
                        .font(Fuente(10, .semibold))
                        .kerning(0.3)
                }
                .foregroundColor(.white)
                .frame(width: anchoBotones)
                .frame(maxHeight: .infinity)
                .background(Colores.rojo)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }

            contenido
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { valor in
                            if !arrastrando {
                                arrastrando = true
                            }
                            let dx = valor.translation.width
                            let rebote = dx < -anchoBotones ? -anchoBotones - (dx + anchoBotones) * 0.3 : max(-anchoBotones, dx)
                            offset = rebote
                        }
                        .onEnded { valor in
                            arrastrando = false
                            let debeAbrir = valor.translation.width < -60
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                offset = debeAbrir ? -anchoBotones : 0
                            }
                        }
                )
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct EditarMovimientoSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var movimiento: Movimiento
    @State private var categoria: String
    @State private var montoTexto: String
    @State private var descripcion: String
    @State private var fecha: Date
    @FocusState private var montoEnfocado: Bool
    @FocusState private var descripcionEnfocada: Bool

    init(movimiento: Movimiento) {
        self.movimiento = movimiento
        _categoria = State(initialValue: movimiento.categoria)
        _montoTexto = State(initialValue: String(format: "%.2f", movimiento.monto))
        _descripcion = State(initialValue: movimiento.descripcion)
        _fecha = State(initialValue: Self.fechaDeString(movimiento.fecha) ?? Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { dismiss() }
                    .font(Fuente(14))
                    .foregroundColor(Colores.textoSec)
                Spacer()
                Text("Edit Transaction")
                    .font(Fuente(16, .semibold))
                    .kerning(-0.3)
                Spacer()
                Color.clear.frame(width: 50, height: 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VistaDropdown(
                        titulo: "Category",
                        opciones: Categorias.lista(para: movimiento.tipo),
                        seleccion: $categoria
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Amount ($)")
                            .font(Fuente(11, .medium))
                            .foregroundColor(Colores.textoSec)
                        TextField("0.00", text: $montoTexto)
                            .keyboardType(.decimalPad)
                            .font(Fuente(16))
                            .focused($montoEnfocado)
                            .padding(.horizontal, 16)
                            .frame(height: 48)
                            .bordeCampo(enfocado: montoEnfocado)
                    }
                    .padding(.bottom, 18)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description (optional)")
                            .font(Fuente(11, .medium))
                            .foregroundColor(Colores.textoSec)
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
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .padding(.horizontal, 16)
                            .bordeCampo()
                            .tint(Colores.accent)
                    }
                    .padding(.bottom, 20)

                    BtnWayne(texto: "Save Changes") {
                        guardar()
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .padding(.horizontal, 20)
            .padding(.top, 6)
        }
        .presentationDetents([.large])
        .presentationBackground(Color(red: 0.06, green: 0.06, blue: 0.07))
        .preferredColorScheme(.dark)
        .overlay { DropdownHost() }
    }

    private func guardar() {
        guard let monto = Double(montoTexto.replacingOccurrences(of: ",", with: ".")),
              monto > 0 else { return }
        montoEnfocado = true
        movimiento.categoria = categoria
        movimiento.monto = monto
        movimiento.descripcion = descripcion.trimmingCharacters(in: .whitespaces)
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        movimiento.fecha = f.string(from: fecha)
        try? context.save()
        dismiss()
    }

    private static func fechaDeString(_ texto: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: texto)
    }
}
