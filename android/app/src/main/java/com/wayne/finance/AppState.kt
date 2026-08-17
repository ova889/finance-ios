package com.wayne.finance

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

class AppState(val ctx: Context, val userId: String) {
    var movimientos by mutableStateOf(listOf<Movimiento>())
        private set
    var metas by mutableStateOf(listOf<Meta>())
        private set
    var recurrentes by mutableStateOf(listOf<Recurrente>())
        private set
    var privacidad by mutableStateOf(Prefs.privacidad(ctx))
        private set

    fun togglePrivacidad() {
        privacidad = !privacidad
        Prefs.setPrivacidad(ctx, privacidad)
    }

    fun recargar() {
        movimientos = Db.movimientos(userId)
        metas = Db.metas(userId)
        recurrentes = Db.recurrentes(userId)
    }

    fun delUsuario(): List<Movimiento> = movimientos.filter { it.userId == userId }

    fun ingresos(): Double = delUsuario().filter { it.esIngreso }.sumOf { it.monto }

    fun gastos(): Double = delUsuario().filter { !it.esIngreso }.sumOf { it.monto }

    fun saldo(): Double = ingresos() - gastos()

    fun gastosPorCategoria(): List<Pair<String, Double>> {
        val map = mutableMapOf<String, Double>()
        for (m in delUsuario()) {
            if (!m.esIngreso) map[m.categoria] = (map[m.categoria] ?: 0.0) + m.monto
        }
        return map.entries.sortedByDescending { it.value }.map { it.key to it.value }
    }

    fun ultimos(n: Int): List<Movimiento> = delUsuario()
        .sortedWith(compareByDescending<Movimiento> { it.fecha }.thenByDescending { it.monto })
        .take(n)

    fun tendencias(): List<Triple<String, Double, Double>> {
        val map = mutableMapOf<String, Pair<Double, Double>>()
        val ahora = hoyLocal()
        val hace6 = ahora.minusMonths(5)
        for (m in delUsuario()) {
            val fecha = fechaDesdeString(m.fecha) ?: continue
            if (fecha.isBefore(hace6)) continue
            val clave = fecha.format(fmtMes)
            val actual = map[clave] ?: (0.0 to 0.0)
            map[clave] = if (m.esIngreso) (actual.first + m.monto) to actual.second
            else actual.first to (actual.second + m.monto)
        }
        return map.entries.sortedBy { it.key }.map { Triple(it.key, it.value.first, it.value.second) }
    }

    fun guardarMovimiento(tipo: String, categoria: String, monto: Double, descripcion: String, fecha: String) {
        Db.insertarMovimiento(Movimiento(0, tipo, categoria, monto, descripcion, fecha, userId))
        recargar()
    }

    fun actualizarMovimiento(m: Movimiento) {
        Db.actualizarMovimiento(m)
        recargar()
    }

    fun eliminarMovimiento(m: Movimiento) {
        Db.eliminarMovimiento(m.id)
        recargar()
    }

    fun crearMeta(nombre: String, objetivo: Double) {
        Db.insertarMeta(nombre, objetivo, userId)
        recargar()
    }

    fun eliminarMeta(id: Long) {
        Db.eliminarMeta(id)
        recargar()
    }

    fun ajustarAhorro(id: Long, delta: Double) {
        Db.ajustarAhorro(id, delta)
        recargar()
    }

    fun crearRecurrente(tipo: String, categoria: String, monto: Double, descripcion: String, dia: Int) {
        Db.insertarRecurrente(Recurrente(0, tipo, categoria, monto, descripcion, dia, true, userId))
        recargar()
    }

    fun eliminarRecurrente(id: Long) {
        Db.eliminarRecurrente(id)
        recargar()
    }
}