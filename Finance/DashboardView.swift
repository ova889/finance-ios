import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    let userId: String
    @Environment(\.modelContext) private var context

    @Query private var movimientos: [Movimiento]
    @Query private var presupuestos: [Presupuesto]

    @State private var mostrarRecurrentes = false
    @State private var toast: String?
    @State private var toastTipo: ToastWayne.TipoToast = .exito
    @State private var mesSeleccionado = mesActual()
    @State private var nuevaCategoria = Categorias.gasto[0]
    @State private var nuevoLimite = ""
    @State private var cargado = false
    @State private var presupuestoAEliminar: Presupuesto?

    init(userId: String) {
        self.userId = userId
        _movimientos = Query(filter: #Predicate<Movimiento> { $0.userId == userId })
        _presupuestos = Query(filter: #Predicate<Presupuesto> { $0.userId == userId })
    }

    private var delUsuario: [Movimiento] {
        movimientos.filter { $0.userId == userId }
    }

    private var ingresos: Double {
        delUsuario.filter { $0.esIngreso }.reduce(0) { $0 + $1.monto }
    }

    private var gastos: Double {
        delUsuario.filter { !$0.esIngreso }.reduce(0) { $0 + $1.monto }
    }

    private var saldo: Double { ingresos - gastos }

    private var gastosPorCategoria: [(categoria: String, total: Double)] {
        var map: [String: Double] = [:]
        for m in delUsuario where !m.esIngreso {
            map[m.categoria, default: 0] += m.monto
        }
        return map.sorted { $0.value > $1.value }.map { (categoria: $0.key, total: $0.value) }
    }

    private var ultimos: [Movimiento] {
        Array(delUsuario.sorted { a, b in
            if a.fecha != b.fecha { return a.fecha > b.fecha }
            return a.monto > b.monto
        }.prefix(6))
    }

    private var resumenMes: (inc: Double, exp: Double, bal: Double) {
        let delMes = delUsuario.filter { $0.fecha.hasPrefix(mesSeleccionado) }
        let inc = delMes.filter { $0.esIngreso }.reduce(0) { $0 + $1.monto }
        let exp = delMes.filter { !$0.esIngreso }.reduce(0) { $0 + $1.monto }
        return (inc, exp, inc - exp)
    }

    private var tendencias: [(mes: String, ingresos: Double, gastos: Double)] {
        var map: [String: (inc: Double, exp: Double)] = [:]
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        let ahora = Date()
        let hace6 = Calendar.current.date(byAdding: .month, value: -5, to: ahora) ?? ahora
        for m in delUsuario {
            guard let fecha = fechaDesdeString(m.fecha), fecha >= hace6 else { continue }
            let clave = f.string(from: fecha)
            var item = map[clave, default: (0, 0)]
            if m.esIngreso { item.inc += m.monto } else { item.exp += m.monto }
            map[clave] = item
        }
        return map.sorted { $0.key < $1.key }.map { (mes: $0.key, ingresos: $0.value.inc, gastos: $0.value.exp) }
    }

    private func fechaDesdeString(_ texto: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: texto)
    }

    private var mesesDisponibles: [String] {
        var lista: [String] = []
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        for i in 0..<24 {
            if let fecha = Calendar.current.date(byAdding: .month, value: -i, to: Date()) {
                lista.append(f.string(from: fecha))
            }
        }
        return lista
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                cabecera
                    .opacity(cargado ? 1 : 0)
                    .offset(x: cargado ? 0 : -8)
                    .animation(.easeOut(duration: 0.35).delay(0.25), value: cargado)

                filaResumen
                    .offset(y: cargado ? 0 : 36)
                    .opacity(cargado ? 1 : 0)
                    .scaleEffect(cargado ? 1 : 0.95)
                    .animation(.spring(response: 0.65, dampingFraction: 0.8).delay(0.15), value: cargado)

                tarjetaCategorias
                    .entrada(retraso: 0.22, cargado: cargado)
                tarjetaRecientes
                    .entrada(retraso: 0.29, cargado: cargado)
                tarjetaPresupuestos
                    .entrada(retraso: 0.36, cargado: cargado)
                tarjetaRecurrentes
                    .entrada(retraso: 0.43, cargado: cargado)
                tarjetaTendencias
                    .entrada(retraso: 0.5, cargado: cargado)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
            .padding(.bottom, DesignTokens.contenedorPaddingBottom)
        }
        .onAppear {
            cargado = true
            comprobarRecurrentes()
        }
        .fullScreenCover(isPresented: $mostrarRecurrentes) {
            RecurrentesView(userId: userId)
        }
        .overlay(alignment: .bottom) {
            if let toast = toast {
                ToastWayne(mensaje: toast, tipo: toastTipo, visible: Binding(
                    get: { self.toast != nil },
                    set: { if !$0 { self.toast = nil } }
                ))
                .padding(.bottom, 90)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .alert("Delete budget for \(presupuestoAEliminar?.categoria ?? "")?", isPresented: Binding(get: { presupuestoAEliminar != nil }, set: { if !$0 { presupuestoAEliminar = nil } })) {
            Button("Delete", role: .destructive) {
                if let p = presupuestoAEliminar {
                    eliminarPresupuesto(p)
                }
                presupuestoAEliminar = nil
            }
            Button("Cancel", role: .cancel) { presupuestoAEliminar = nil }
        } message: {
            Text("This budget and its tracking will be removed. This action cannot be undone.")
        }
    }

    private var cabecera: some View {
        HStack(alignment: .center) {
            EtiquetaTitulo(texto: "Dashboard")

            Spacer()

            VistaDropdown(
                opciones: mesesDisponibles,
                seleccion: $mesSeleccionado,
                compacto: true,
                ancho: 130,
                alinearDerecha: true,
                margenInferior: 0
            )

            let resumen = resumenMes
            HStack(spacing: 8) {
                Text("+\(formatoMonto(resumen.inc))")
                    .font(Fuente(10, .semibold))
                    .foregroundColor(Colores.verde)
                Text("-\(formatoMonto(resumen.exp))")
                    .font(Fuente(10, .semibold))
                    .foregroundColor(Colores.rojo)
                Text(formatoMonto(resumen.bal))
                    .font(Fuente(10, .semibold))
                    .foregroundColor(resumen.bal >= 0 ? Colores.verde : Colores.rojo)
            }
        }
    }

    private var filaResumen: some View {
        HStack(spacing: 5) {
            TarjetaResumen(etiqueta: "Income", monto: formatoMonto(ingresos), color: Colores.verde)
            TarjetaResumen(etiqueta: "Expenses", monto: formatoMonto(gastos), color: Colores.rojo)
            TarjetaResumen(etiqueta: "Balance", monto: formatoMonto(saldo), color: .white)
        }
    }

    private var tarjetaCategorias: some View {
        CristalCard(padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HTitle(texto: "Expenses by Category")
                if gastosPorCategoria.isEmpty {
                    Text("No expenses recorded yet.")
                        .font(Fuente(13))
                        .foregroundColor(Colores.textoSec)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 60)
                } else {
                    DoughnutChart(slices: slicesDoughnut)
                }
            }
        }
    }

    private var slicesDoughnut: [DoughnutSlice] {
        let colores: [Color] = [
            .white.opacity(0.85), .white.opacity(0.65), .white.opacity(0.45),
            .white.opacity(0.30), .white.opacity(0.20), .white.opacity(0.15),
            Colores.verde.opacity(0.5), Colores.rojo.opacity(0.4), Colores.verde.opacity(0.3)
        ]
        return gastosPorCategoria.enumerated().map { idx, item in
            DoughnutSlice(nombre: item.categoria, valor: item.total, color: colores[idx % colores.count])
        }
    }

    private var tarjetaRecientes: some View {
        CristalCard(padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HTitle(texto: "Recent Transactions")
                if ultimos.isEmpty {
                    Text("No transactions yet. Go to \"Add\" to get started.")
                        .font(Fuente(13))
                        .foregroundColor(Colores.textoSec)
                } else {
                    VStack(spacing: 0) {
                        ForEach(ultimos, id: \.id) { m in
                            HStack(spacing: 8) {
                                Text(m.fecha)
                                    .font(Fuente(13))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(m.categoria)
                                    .font(Fuente(13))
                                    .foregroundColor(.white)
                                Spacer()
                                MontoPrivado(texto: formatoConSigno(m.monto, esIngreso: m.esIngreso))
                                    .font(Fuente(14, .semibold))
                                    .foregroundColor(m.esIngreso ? Colores.verde : Colores.rojo)
                            }
                            .padding(.vertical, 8)
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(Color.white.opacity(0.02)).frame(height: 1)
                            }
                        }
                    }
                }
            }
        }
    }

    private var tarjetaPresupuestos: some View {
        CristalCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HTitle(texto: "Category Budgets")

                let budgets = presupuestos.filter { $0.userId == userId }

                if budgets.isEmpty {
                    Text("No budgets set yet.")
                        .font(Fuente(12))
                        .foregroundColor(Colores.textoSec)
                }

                ForEach(budgets, id: \.categoria) { p in
                    let gastado = gastosPorCategoria.first(where: { $0.categoria == p.categoria })?.total ?? 0
                    let excedido = gastado > p.limite
                    let porcentaje = p.limite > 0 ? min(100, (gastado / p.limite) * 100) : 0

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            HStack(spacing: 6) {
                                Text(p.categoria)
                                    .font(Fuente(12))
                                    .foregroundColor(.white)
                                Button {
                                    presupuestoAEliminar = p
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(Fuente(10))
                                        .foregroundColor(Colores.rojo.opacity(0.4))
                                }
                            }
                            Spacer()
                            Text("\(formatoMonto(gastado)) / \(formatoMonto(p.limite))")
                                .font(Fuente(12))
                                .foregroundColor(excedido ? Colores.rojo : Colores.textoSec)
                                .fontWeight(excedido ? .semibold : .regular)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.04))
                                Capsule()
                                    .fill(excedido ? Colores.rojo : Color.white.opacity(0.5))
                                    .frame(width: max(geo.size.width * porcentaje / 100, 2))
                            }
                        }
                        .frame(height: 4)
                        if excedido {
                            Text("Exceeded this budget.")
                                .font(Fuente(11))
                                .foregroundColor(Colores.rojo)
                        }
                    }
                    .padding(.bottom, 4)
                }

                HStack(alignment: .bottom, spacing: 8) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Category")
                            .font(Fuente(11, .medium))
                            .foregroundColor(Colores.textoSec)
                        VistaDropdown(
                            opciones: Categorias.gasto,
                            seleccion: $nuevaCategoria,
                            margenInferior: 0
                        )
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Limit ($)")
                            .font(Fuente(11, .medium))
                            .foregroundColor(Colores.textoSec)
                        TextField("200.00", text: $nuevoLimite)
                            .keyboardType(.decimalPad)
                            .font(Fuente(13))
                            .padding(.horizontal, 12)
                            .frame(height: 40)
                            .background(Colores.campoBg)
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .frame(maxWidth: .infinity)

                    Button {
                        guardarPresupuesto()
                    } label: {
                        Text("Set Budget")
                            .font(Fuente(11, .semibold))
                            .kerning(1.5)
                            .textCase(.uppercase)
                            .foregroundColor(.white)
                            .frame(height: 40)
                            .frame(maxWidth: .infinity)
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(ScalePressStyle(presionado: .constant(false)))
                }
                .padding(.top, 8)
            }
        }
    }

    private var tarjetaTendencias: some View {
        CristalCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HTitle(texto: "Monthly Trends")
                if tendencias.isEmpty {
                    Text("No data yet.")
                        .font(Fuente(12))
                        .foregroundColor(Colores.textoSec)
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                } else {
                    Chart(tendencias, id: \.mes) { t in
                        BarMark(
                            x: .value("Month", t.mes),
                            y: .value("Income", t.ingresos)
                        )
                        .foregroundStyle(by: .value("Serie", "Income"))
                        .cornerRadius(4)

                        BarMark(
                            x: .value("Month", t.mes),
                            y: .value("Expenses", t.gastos)
                        )
                        .foregroundStyle(by: .value("Serie", "Expenses"))
                        .cornerRadius(4)
                    }
                    .chartForegroundStyleScale([
                        "Income": Colores.verde.opacity(0.2),
                        "Expenses": Colores.rojo.opacity(0.15)
                    ])
                    .chartLegend(position: .top, alignment: .leading, spacing: 12)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .font(Fuente(9))
                                .foregroundStyle(Color.white.opacity(0.2))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine().foregroundStyle(Color.white.opacity(0.03))
                            AxisValueLabel {
                                if let monto = value.as(Double.self) {
                                    Text("$\(Int(monto))")
                                        .font(Fuente(9))
                                        .foregroundStyle(Color.white.opacity(0.2))
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                }
            }
        }
    }

    private var tarjetaRecurrentes: some View {
        CristalCard(padding: 16) {
            Button {
                mostrarRecurrentes = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HTitle(texto: "Recurring")
                    Text("Manage auto-transactions →")
                        .font(Fuente(12))
                        .foregroundColor(Colores.textoSec)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func guardarPresupuesto() {
        guard let limite = Double(nuevoLimite.replacingOccurrences(of: ",", with: ".")),
              limite > 0 else { return }
        if let existente = presupuestos.first(where: { $0.categoria == nuevaCategoria && $0.userId == userId }) {
            existente.limite = limite
        } else {
            let nuevo = Presupuesto(categoria: nuevaCategoria, limite: limite, userId: userId)
            context.insert(nuevo)
        }
        try? context.save()
        nuevoLimite = ""
    }

    private func eliminarPresupuesto(_ p: Presupuesto) {
        context.delete(p)
        try? context.save()
    }

    private func comprobarRecurrentes() {
        guard let usuario = session_usuario() else { return }
        let creados = RecurringService.checkRecurrentes(para: usuario, context: context)
        if !creados.isEmpty {
            toastTipo = .exito
            toast = creados.joined(separator: " · ")
        }
    }

    private func session_usuario() -> Usuario? {
        let descriptor = FetchDescriptor<Usuario>(predicate: #Predicate { $0.nombre == userId })
        return try? context.fetch(descriptor).first
    }
}

struct TarjetaResumen: View {
    let etiqueta: String
    let monto: String
    let color: Color

    var body: some View {
        CristalCard(padding: 10, radius: 14, paddingHorizontal: 6) {
            VStack(spacing: 4) {
                Text(etiqueta)
                    .font(Fuente(8, .medium))
                    .kerning(0.5)
                    .textCase(.uppercase)
                    .foregroundColor(Color.white.opacity(0.28))
                MontoPrivado(texto: monto)
                    .font(Fuente(15, .bold))
                    .kerning(-0.5)
                    .monospacedDigit()
                    .foregroundColor(color)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct EntradaTarjeta: ViewModifier {
    var retraso: Double
    var cargado: Bool

    func body(content: Content) -> some View {
        content
            .offset(y: cargado ? 0 : 18)
            .opacity(cargado ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(retraso), value: cargado)
    }
}

extension View {
    func entrada(retraso: Double, cargado: Bool) -> some View {
        modifier(EntradaTarjeta(retraso: retraso, cargado: cargado))
    }
}
