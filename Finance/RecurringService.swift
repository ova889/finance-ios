import Foundation
import SwiftData

enum RecurringService {
    @MainActor
    static func checkRecurrentes(para usuario: Usuario, context: ModelContext) -> [String] {
        let hoy = hoyString()
        guard usuario.ultimoCheckRecurrentes != hoy else { return [] }

        let hoyDia = Calendar.current.component(.day, from: Date())
        let descriptor = FetchDescriptor<Recurrente>(
            predicate: #Predicate { $0.userId == usuario.nombre && $0.activo == true && $0.dia == hoyDia }
        )
        guard let items = try? context.fetch(descriptor) else {
            usuario.ultimoCheckRecurrentes = hoy
            try? context.save()
            return []
        }

        var creados: [String] = []
        for r in items {
            let mov = Movimiento(
                tipo: r.tipo,
                categoria: r.categoria,
                monto: r.monto,
                descripcion: r.descripcion.isEmpty ? r.categoria : r.descripcion,
                fecha: hoy,
                userId: usuario.nombre
            )
            context.insert(mov)
            creados.append("Auto-created \(r.categoria) (\(formatoConSigno(r.monto, esIngreso: r.esIngreso)))")
        }

        usuario.ultimoCheckRecurrentes = hoy
        try? context.save()
        return creados
    }
}
