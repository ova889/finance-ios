package com.wayne.finance

import android.content.Context
import android.content.SharedPreferences
import java.security.MessageDigest

object PasswordHasher {
    fun hash(password: String, sal: String): String {
        val datos = (sal + password + sal).toByteArray(Charsets.UTF_8)
        val digest = MessageDigest.getInstance("SHA-256").digest(datos)
        return digest.joinToString("") { "%02x".format(it) }
    }
}

object Prefs {
    const val CLAVE_SESION = "session_usuario"
    const val CLAVE_PRIVACIDAD = "privacyMode"

    private fun p(ctx: Context): SharedPreferences =
        ctx.getSharedPreferences("wayne_finance", Context.MODE_PRIVATE)

    fun sesion(ctx: Context): String? = p(ctx).getString(CLAVE_SESION, null)

    fun guardarSesion(ctx: Context, nombre: String?) {
        p(ctx).edit().putString(CLAVE_SESION, nombre).apply()
    }

    fun privacidad(ctx: Context): Boolean = p(ctx).getBoolean(CLAVE_PRIVACIDAD, false)

    fun setPrivacidad(ctx: Context, valor: Boolean) {
        p(ctx).edit().putBoolean(CLAVE_PRIVACIDAD, valor).apply()
    }

    fun descripciones(ctx: Context, userId: String): List<String> =
        p(ctx).getStringSet("finance_descs_$userId", emptySet()).orEmpty().toList()

    fun guardarDescripcion(ctx: Context, userId: String, valor: String) {
        val lista = descripciones(ctx, userId).toMutableList()
        if (!lista.contains(valor)) {
            lista.add(0, valor)
            if (lista.size > 20) lista.removeAt(lista.size - 1)
            p(ctx).edit().putStringSet("finance_descs_$userId", lista.toSet()).apply()
        }
    }

    fun ultimoCheckRecurrentes(ctx: Context, userId: String): String =
        p(ctx).getString("ultimo_check_$userId", "") ?: ""

    fun setUltimoCheckRecurrentes(ctx: Context, userId: String, valor: String) {
        p(ctx).edit().putString("ultimo_check_$userId", valor).apply()
    }
}

object Session {
    fun iniciarSesion(context: Context, nombre: String, password: String): String? {
        val limpio = nombre.trim()
        val usuario = Db.usuarioPorNombre(limpio) ?: return null
        val hash = PasswordHasher.hash(password, "wayne_batcueva")
        if (usuario.passwordHash != hash) return null
        Prefs.guardarSesion(context, usuario.nombre)
        return usuario.nombre
    }

    fun registrar(context: Context, nombre: String, password: String, confirmacion: String): String? {
        val limpio = nombre.trim()
        if (limpio.isEmpty() || password.isEmpty()) return null
        if (password != confirmacion) return null
        if (password.length < 3) return null
        if (Db.usuarioPorNombre(limpio) != null) return null
        Db.insertarUsuario(limpio, PasswordHasher.hash(password, "wayne_batcueva"))
        Prefs.guardarSesion(context, limpio)
        return limpio
    }

    fun cerrarSesion(context: Context) {
        Prefs.guardarSesion(context, null)
    }
}

object SeedService {
    fun asegurarUsuario() {
        val nombre = "ova"
        if (Db.usuarioPorNombre(nombre) == null) {
            Db.insertarUsuario(nombre, PasswordHasher.hash("889", "wayne_batcueva"))
        }
    }
}

object RecurringService {
    fun checkRecurrentes(context: Context, userId: String): List<String> {
        val hoy = hoyString()
        if (Prefs.ultimoCheckRecurrentes(context, userId) == hoy) return emptyList()
        val diaHoy = hoyLocal().dayOfMonth
        val items = Db.recurrentesActivosHoy(userId, diaHoy)
        val creados = mutableListOf<String>()
        for (r in items) {
            Db.insertarMovimiento(
                Movimiento(
                    id = 0,
                    tipo = r.tipo,
                    categoria = r.categoria,
                    monto = r.monto,
                    descripcion = if (r.descripcion.isEmpty()) r.categoria else r.descripcion,
                    fecha = hoy,
                    userId = userId
                )
            )
            creados.add("Auto-created ${r.categoria} (${formatoConSigno(r.monto, r.esIngreso)})")
        }
        Prefs.setUltimoCheckRecurrentes(context, userId, hoy)
        return creados
    }
}