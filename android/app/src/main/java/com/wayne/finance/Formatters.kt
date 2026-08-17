package com.wayne.finance

import java.time.LocalDate
import java.time.format.DateTimeFormatter

val fmtFecha: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
val fmtMes: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM")

fun hoyString(): String = LocalDate.now().format(fmtFecha)

fun hoyLocal(): LocalDate = LocalDate.now()

fun mesActual(): String = LocalDate.now().format(fmtMes)

fun formatoMonto(monto: Double): String = String.format("$%.2f", monto)

fun formatoConSigno(monto: Double, esIngreso: Boolean): String {
    val signo = if (esIngreso) "+" else "-"
    return signo + formatoMonto(kotlin.math.abs(monto))
}

fun fechaLegible(fecha: String): String {
    val hoy = hoyString()
    if (fecha == hoy) return "Today"
    val ayer = LocalDate.now().minusDays(1)
    if (fecha == ayer.format(fmtFecha)) return "Yesterday"
    return fecha
}

fun fechaDesdeString(texto: String): LocalDate? = try {
    LocalDate.parse(texto, fmtFecha)
} catch (e: Exception) {
    null
}

fun mesesDisponibles(): List<String> {
    val lista = mutableListOf<String>()
    val ahora = LocalDate.now()
    for (i in 0 until 24) {
        lista.add(ahora.minusMonths(i.toLong()).format(fmtMes))
    }
    return lista
}

fun stringDesdeDate(date: LocalDate): String = date.format(fmtFecha)