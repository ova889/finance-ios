import Foundation
import SwiftData
import CryptoKit
import SwiftUI

enum AuthError: LocalizedError {
    case usuarioExiste
    case credencialesInvalidas
    case camposVacios
    case contrasenaCorta
    case contrasenasNoCoinciden

    var errorDescription: String? {
        switch self {
        case .usuarioExiste:
            return "That user ID already exists."
        case .credencialesInvalidas:
            return "Invalid username or password."
        case .camposVacios:
            return "Please fill in all fields."
        case .contrasenaCorta:
            return "Access code must be at least 3 characters."
        case .contrasenasNoCoinciden:
            return "Access codes do not match."
        }
    }
}

enum PasswordHasher {
    static func hash(_ password: String, sal: String) -> String {
        let data = Data((sal + password + sal).utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

@MainActor
final class Session: ObservableObject {
    @Published var usuarioActual: String? {
        didSet { UserDefaults.standard.set(usuarioActual, forKey: "session_usuario") }
    }

    init() {
        usuarioActual = UserDefaults.standard.string(forKey: "session_usuario")
    }

    var estaLogueado: Bool {
        usuarioActual != nil
    }

    func cerrarSesion() {
        usuarioActual = nil
    }

    func usuario(nombre: String, en context: ModelContext) -> Usuario? {
        let descriptor = FetchDescriptor<Usuario>(predicate: #Predicate { $0.nombre == nombre })
        return try? context.fetch(descriptor).first
    }

    @discardableResult
    func iniciarSesion(usuario nombre: String, password: String, context: ModelContext) -> Bool {
        let nombreLimpio = nombre.trimmingCharacters(in: .whitespaces)
        guard let usuario = usuario(nombre: nombreLimpio, en: context) else { return false }
        let hash = PasswordHasher.hash(password, sal: "wayne_batcueva")
        guard usuario.passwordHash == hash else { return false }
        usuarioActual = usuario.nombre
        return true
    }

    @discardableResult
    func registrar(usuario nombre: String, password: String, confirmacion: String, context: ModelContext) throws -> Bool {
        let nombreLimpio = nombre.trimmingCharacters(in: .whitespaces)
        guard !nombreLimpio.isEmpty, !password.isEmpty else { throw AuthError.camposVacios }
        guard password == confirmacion else { throw AuthError.contrasenasNoCoinciden }
        guard password.count >= 3 else { throw AuthError.contrasenaCorta }
        guard usuario(nombre: nombreLimpio, en: context) == nil else { throw AuthError.usuarioExiste }

        let nuevo = Usuario(nombre: nombreLimpio, passwordHash: PasswordHasher.hash(password, sal: "wayne_batcueva"))
        context.insert(nuevo)
        try context.save()
        usuarioActual = nuevo.nombre
        return true
    }
}

enum SeedService {
    static func crearUsuarioPredeterminado(en context: ModelContext) {
        let descriptor = FetchDescriptor<Usuario>(predicate: #Predicate { $0.nombre == "ova" })
        if (try? context.fetch(descriptor).first) == nil {
            let nuevo = Usuario(nombre: "ova", passwordHash: PasswordHasher.hash("889", sal: "wayne_batcueva"))
            context.insert(nuevo)
            try? context.save()
        }
    }
}
