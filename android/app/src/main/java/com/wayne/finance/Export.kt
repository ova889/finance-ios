package com.wayne.finance

import android.content.Context
import android.content.Intent
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.pdf.PdfDocument
import androidx.core.content.FileProvider
import java.io.File

object ExportService {

    data class Resultado(val file: File)

    private fun escribir(context: Context, nombre: String, bytes: ByteArray): Resultado? {
        val dir = File(context.cacheDir, "exports").apply { mkdirs() }
        return try {
            val f = File(dir, nombre)
            f.writeBytes(bytes)
            Resultado(f)
        } catch (e: Exception) {
            null
        }
    }

    fun generarCSV(context: Context, movimientos: List<Movimiento>): Resultado? {
        val lineas = mutableListOf<String>()
        lineas.add("Date,Type,Category,Description,Amount")
        for (m in movimientos) {
            val tipo = if (m.esIngreso) "Income" else "Expense"
            val desc = m.descripcion.replace(",", ";")
            lineas.add("${m.fecha},$tipo,${m.categoria},$desc,${"%.2f".format(m.monto)}")
        }
        val bytes = lineas.joinToString("\n").toByteArray(Charsets.UTF_8)
        return escribir(context, "finance_export.csv", bytes)
    }

    fun generarPDF(context: Context, movimientos: List<Movimiento>): Resultado? {
        val doc = PdfDocument()
        val pageInfo = PdfDocument.PageInfo.Builder(595, 842, 1).create()
        val page = doc.startPage(pageInfo)
        val canvas: Canvas = page.canvas

        val bgDark = Color.rgb(10, 10, 15)
        val card = Color.rgb(20, 20, 26)
        val fila = Color.rgb(26, 26, 34)
        val filaAlt = Color.rgb(18, 18, 26)
        val accent = Color.rgb(94, 92, 230)
        val verde = Color.rgb(48, 209, 88)
        val rojo = Color.rgb(255, 69, 58)
        val textoSec = Color.rgb(142, 142, 147)
        val blanco = Color.WHITE

        canvas.drawColor(bgDark)

        val titulo = Paint().apply { color = accent; textSize = 24f; isFakeBoldText = true }
        val sub = Paint().apply { color = textoSec; textSize = 9f }
        val header = Paint().apply { color = blanco; textSize = 8f; isFakeBoldText = true }
        val filaP = Paint().apply { color = blanco; textSize = 8f }
        val resumen = Paint().apply { color = textoSec; textSize = 10f; isFakeBoldText = true }

        val margen = 51f
        val contenidoAncho = 595f - margen * 2
        var y = 60f

        canvas.drawText("FINANCE", margen, y + 18f, titulo)
        y += 34f
        canvas.drawText("Transaction History", margen, y + 10f, sub)
        y += 30f

        val colFechas = 80f
        val colTipo = 62f
        val colCat = 94f
        val colDesc = 154f
        val colMonto = contenidoAncho - colFechas - colTipo - colCat - colDesc
        val anchos = floatArrayOf(colFechas, colTipo, colCat, colDesc, colMonto)

        fun dibujarHeader() {
            val rect = android.graphics.RectF(margen, y, margen + contenidoAncho, y + 30f)
            canvas.drawRoundRect(rect, 0f, 0f, Paint().apply { color = card })
            val titulos = listOf("Date", "Type", "Category", "Description", "Amount")
            var x = margen + 10f
            for ((i, t) in titulos.withIndex()) {
                canvas.drawText(t, x, y + 18f, header)
                x += anchos[i]
            }
            canvas.drawRect(rect.left, y + 29f, rect.right, y + 30f, Paint().apply { color = accent })
            y += 30f
        }

        dibujarHeader()

        val filaAltura = 26f
        for ((idx, m) in movimientos.withIndex()) {
            if (y + filaAltura > 842f - 80f) {
                canvas.drawColor(bgDark)
                y = margen
                dibujarHeader()
            }
            val rect = android.graphics.RectF(margen, y, margen + contenidoAncho, y + filaAltura)
            canvas.drawRoundRect(rect, 0f, 0f, Paint().apply { color = if (idx % 2 == 0) fila else filaAlt })
            val colorMonto = if (m.esIngreso) verde else rojo
            val tipo = if (m.esIngreso) "Income" else "Expense"
            val signo = if (m.esIngreso) "+" else "-"
            val montoP = Paint().apply { color = colorMonto; textSize = 8f; isFakeBoldText = true }
            val tipoP = Paint().apply { color = colorMonto; textSize = 8f }
            val filaBlanca = Paint().apply { color = blanco; textSize = 8f }

            var x = margen + 10f
            canvas.drawText(m.fecha, x, y + 16f, filaBlanca); x += colFechas
            canvas.drawText(tipo, x, y + 16f, tipoP); x += colTipo
            canvas.drawText(m.categoria, x, y + 16f, filaBlanca); x += colCat
            val desc = if (m.descripcion.isEmpty()) "-" else m.descripcion
            canvas.drawText(desc.take(40), x, y + 16f, filaBlanca); x += colDesc
            canvas.drawText("$signo${formatoMonto(m.monto)}", x, y + 16f, montoP)
            y += filaAltura
        }

        y += 18f
        val totalInc = movimientos.filter { it.esIngreso }.sumOf { it.monto }
        val totalExp = movimientos.filter { !it.esIngreso }.sumOf { it.monto }
        val balance = totalInc - totalExp
        canvas.drawText(
            "Total Income: +${formatoMonto(totalInc)}  |  Total Expenses: -${formatoMonto(totalExp)}  |  Balance: ${formatoMonto(balance)}",
            margen, y, resumen
        )

        doc.finishPage(page)
        val bytes = doc.openDocument().use { it.readBytes() }
        doc.close()
        return escribir(context, "wayne_finance_history.pdf", bytes)
    }

    fun compartir(context: Context, resultado: Resultado, tipoMime: String) {
        val uri = FileProvider.getUriForFile(context, "com.wayne.finance.files", resultado.file)
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = tipoMime
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        context.startActivity(Intent.createChooser(intent, "Export"))
    }
}