import UIKit
import CoreGraphics
import UniformTypeIdentifiers

enum ExportService {
    struct Resultado: Identifiable {
        let id = UUID()
        let url: URL
        let nombre: String
    }

    static func generarCSV(movimientos: [Movimiento]) -> Resultado? {
        var lineas = ["Date,Type,Category,Description,Amount"]
        for m in movimientos {
            let tipo = m.esIngreso ? "Income" : "Expense"
            let desc = m.descripcion.replacingOccurrences(of: ",", with: ";")
            lineas.append("\(m.fecha),\(tipo),\(m.categoria),\(desc),\(String(format: "%.2f", m.monto))")
        }
        guard let datos = lineas.joined(separator: "\n").data(using: .utf8) else { return nil }
        return escribir(nombre: "finance_export.csv", datos: datos)
    }

    static func generarPDF(movimientos: [Movimiento]) -> Resultado? {
        let pageW: CGFloat = 595
        let pageH: CGFloat = 842
        let margen: CGFloat = 51
        let contenidoAncho = pageW - margen * 2

        let bgDark = UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1)
        let card = UIColor(red: 0.078, green: 0.078, blue: 0.102, alpha: 1)
        let fila = UIColor(red: 0.102, green: 0.102, blue: 0.133, alpha: 1)
        let filaAlt = UIColor(red: 0.071, green: 0.071, blue: 0.102, alpha: 1)
        let accent = UIColor(red: 0.369, green: 0.361, blue: 0.902, alpha: 1)
        let verde = UIColor(red: 0.188, green: 0.82, blue: 0.345, alpha: 1)
        let rojo = UIColor(red: 1.0, green: 0.271, blue: 0.227, alpha: 1)
        let textoSec = UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1)
        let blanco = UIColor.white

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH))
        let datos = renderer.pdfData { ctx in
            ctx.beginPage()
            ctx.cgContext.setFillColor(bgDark.cgColor)
            ctx.cgContext.fill(CGRect(x: 0, y: 0, width: pageW, height: pageH))

            var y: CGFloat = 60

            func dibujarTexto(_ texto: String, en frame: CGRect, color: UIColor, fuente: UIFont) {
                let attrs: [NSAttributedString.Key: Any] = [.font: fuente, .foregroundColor: color]
                (texto as NSString).draw(in: frame, withAttributes: attrs)
            }

            dibujarTexto("FINANCE", en: CGRect(x: margen, y: y, width: contenidoAncho, height: 30),
                         color: accent, fuente: .systemFont(ofSize: 24, weight: .bold))
            y += 34
            let fecha = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
            dibujarTexto("Transaction History · \(fecha)", en: CGRect(x: margen, y: y, width: contenidoAncho, height: 14),
                         color: textoSec, fuente: .systemFont(ofSize: 9))
            y += 30

            let colFechas: CGFloat = 80
            let colTipo: CGFloat = 62
            let colCat: CGFloat = 94
            let colDesc: CGFloat = 154
            let colMonto = contenidoAncho - colFechas - colTipo - colCat - colDesc

            func dibujarHeader() {
                ctx.cgContext.setFillColor(card.cgColor)
                ctx.cgContext.fill(CGRect(x: margen, y: y, width: contenidoAncho, height: 30))
                let headerTitles = ["Date", "Type", "Category", "Description", "Amount"]
                var x = margen + 10
                for (i, titulo) in headerTitles.enumerated() {
                    let ancho: CGFloat = [colFechas, colTipo, colCat, colDesc, colMonto][i]
                    dibujarTexto(titulo, en: CGRect(x: x, y: y + 8, width: ancho, height: 14),
                                 color: blanco, fuente: .systemFont(ofSize: 8, weight: .bold))
                    x += ancho
                }
                ctx.cgContext.setFillColor(accent.cgColor)
                ctx.cgContext.fill(CGRect(x: margen, y: y + 29, width: contenidoAncho, height: 1))
                y += 30
            }

            dibujarHeader()

            let filaAltura: CGFloat = 26
            for (idx, m) in movimientos.enumerated() {
                if y + filaAltura > pageH - 80 {
                    y = margen
                    ctx.cgContext.setFillColor(bgDark.cgColor)
                    ctx.cgContext.fill(CGRect(x: 0, y: 0, width: pageW, height: pageH))
                    dibujarHeader()
                }
                ctx.cgContext.setFillColor((idx % 2 == 0 ? fila : filaAlt).cgColor)
                ctx.cgContext.fill(CGRect(x: margen, y: y, width: contenidoAncho, height: filaAltura))
                let colorMonto = m.esIngreso ? verde : rojo
                let tipo = m.esIngreso ? "Income" : "Expense"
                let signo = m.esIngreso ? "+" : "-"
                var x = margen + 10
                dibujarTexto(m.fecha, en: CGRect(x: x, y: y + 7, width: colFechas, height: 12),
                             color: blanco, fuente: .systemFont(ofSize: 8))
                x += colFechas
                dibujarTexto(tipo, en: CGRect(x: x, y: y + 7, width: colTipo, height: 12),
                             color: colorMonto, fuente: .systemFont(ofSize: 8))
                x += colTipo
                dibujarTexto(m.categoria, en: CGRect(x: x, y: y + 7, width: colCat, height: 12),
                             color: blanco, fuente: .systemFont(ofSize: 8))
                x += colCat
                let desc = m.descripcion.isEmpty ? "-" : m.descripcion
                dibujarTexto(String(desc.prefix(40)), en: CGRect(x: x, y: y + 7, width: colDesc, height: 12),
                             color: blanco, fuente: .systemFont(ofSize: 8))
                x += colDesc
                dibujarTexto("\(signo)\(formatoMonto(m.monto))", en: CGRect(x: x, y: y + 7, width: colMonto, height: 12),
                             color: colorMonto, fuente: .systemFont(ofSize: 8, weight: .medium))
                y += filaAltura
            }

            y += 18
            let totalInc = movimientos.filter { $0.esIngreso }.reduce(0) { $0 + $1.monto }
            let totalExp = movimientos.filter { !$0.esIngreso }.reduce(0) { $0 + $1.monto }
            let balance = totalInc - totalExp
            let resumen = "Total Income: +\(formatoMonto(totalInc))  |  Total Expenses: -\(formatoMonto(totalExp))  |  Balance: \(formatoMonto(balance))"
            dibujarTexto(resumen, en: CGRect(x: margen, y: y, width: contenidoAncho, height: 14),
                         color: textoSec, fuente: .systemFont(ofSize: 10, weight: .medium))
        }

        return escribir(nombre: "wayne_finance_history.pdf", datos: datos)
    }

    private static func escribir(nombre: String, datos: Data) -> Resultado? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(nombre)
        do {
            try datos.write(to: url)
            return Resultado(url: url, nombre: nombre)
        } catch {
            return nil
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
