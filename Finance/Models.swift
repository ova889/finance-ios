import Foundation
import SwiftData

@Model
final class Usuario {
    var nombre: String
    var passwordHash: String
    var ultimoCheckRecurrentes: String
    var fechaCreacion: Date

    init(nombre: String, passwordHash: String) {
        self.nombre = nombre
        self.passwordHash = passwordHash
        self.ultimoCheckRecurrentes = ""
        self.fechaCreacion = Date()
    }
}

@Model
final class Movimiento {
    var tipo: String
    var categoria: String
    var monto: Double
    var descripcion: String
    var fecha: String
    var userId: String

    init(tipo: String, categoria: String, monto: Double, descripcion: String, fecha: String, userId: String) {
        self.tipo = tipo
        self.categoria = categoria
        self.monto = monto
        self.descripcion = descripcion
        self.fecha = fecha
        self.userId = userId
    }

    var esIngreso: Bool { tipo == "ingreso" }
}

@Model
final class Presupuesto {
    var categoria: String
    var limite: Double
    var userId: String

    init(categoria: String, limite: Double, userId: String) {
        self.categoria = categoria
        self.limite = limite
        self.userId = userId
    }
}

@Model
final class Recurrente {
    var tipo: String
    var categoria: String
    var monto: Double
    var descripcion: String
    var dia: Int
    var activo: Bool
    var userId: String

    init(tipo: String, categoria: String, monto: Double, descripcion: String, dia: Int, userId: String) {
        self.tipo = tipo
        self.categoria = categoria
        self.monto = monto
        self.descripcion = descripcion
        self.dia = dia
        self.activo = true
        self.userId = userId
    }

    var esIngreso: Bool { tipo == "ingreso" }
}

@Model
final class Meta {
    var nombre: String
    var objetivo: Double
    var ahorrado: Double
    var userId: String
    var fechaCreacion: Date

    init(nombre: String, objetivo: Double, userId: String) {
        self.nombre = nombre
        self.objetivo = objetivo
        self.ahorrado = 0
        self.userId = userId
        self.fechaCreacion = Date()
    }
}

enum Categorias {
    static let ingreso = ["Salary", "Gifts", "Other"]
    static let gasto = ["Housing", "Groceries", "Food", "Transportation", "Subscriptions", "Health", "Entertainment", "Clothing", "Education", "Utilities"]

    static func lista(para tipo: String) -> [String] {
        tipo == "ingreso" ? ingreso : gasto
    }
}
