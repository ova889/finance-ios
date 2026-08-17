package com.wayne.finance

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.CornerSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@Composable
fun DashboardScreen(estado: AppState) {
    var mesSeleccionado by remember { mutableStateOf(mesActual()) }
    var metaNombre by remember { mutableStateOf("") }
    var metaObjetivo by remember { mutableStateOf("") }
    var metaAEliminar by remember { mutableStateOf<Meta?>(null) }
    var mostrarRecurrentes by remember { mutableStateOf(false) }
    var cargado by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) { cargado = true }

    val meses = remember { mesesDisponibles() }

    Box(Modifier.fillMaxSize()) {
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 10.dp)
                .padding(top = 6.dp, bottom = 100.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                EtiquetaTitulo(texto = "Dashboard", tamano = 20, modifier = Modifier.weight(1f))
                VistaDropdown(
                    opciones = meses,
                    seleccion = mesSeleccionado,
                    onSeleccionar = { mesSeleccionado = it },
                    compacto = true,
                    ancho = 120,
                    margenInferior = 0.dp
                )
            }

            if (cargado) {
                filaResumen(estado)
                tarjetaCategorias(estado)
                tarjetaRecientes(estado)
            }
            tarjetaMetas(
                estado = estado,
                metaNombre = metaNombre,
                onMetaNombre = { metaNombre = it },
                metaObjetivo = metaObjetivo,
                onMetaObjetivo = { metaObjetivo = it },
                onGuardar = {
                    val nombre = metaNombre.trim()
                    val objetivo = metaObjetivo.replace(",", ".").toDoubleOrNull()
                    if (nombre.isNotEmpty() && objetivo != null && objetivo > 0) {
                        estado.crearMeta(nombre, objetivo)
                        metaNombre = ""
                        metaObjetivo = ""
                    }
                },
                onEliminar = { metaAEliminar = it }
            )
            tarjetaTendencias(estado)
            tarjetaRecurrentes { mostrarRecurrentes = true }
        }

        if (mostrarRecurrentes) {
            RecurrentesScreen(
                estado = estado,
                onCerrar = { mostrarRecurrentes = false }
            )
        }

        metaAEliminar?.let { meta ->
            AlertDialog(
                onDismissRequest = { metaAEliminar = null },
                title = { Text("Delete goal \"${meta.nombre}\"?") },
                text = { Text("This goal and its savings will be removed. This action cannot be undone.") },
                confirmButton = {
                    TextButton(onClick = {
                        estado.eliminarMeta(meta.id)
                        metaAEliminar = null
                    }) { Text("Delete", color = Colores.rojo) }
                },
                dismissButton = {
                    TextButton(onClick = { metaAEliminar = null }) { Text("Cancel") }
                }
            )
        }
    }
}

@Composable
private fun filaResumen(estado: AppState) {
    val privacidad = Prefs.privacidad(estado.ctx)
    Row(horizontalArrangement = Arrangement.spacedBy(5.dp)) {
        TarjetaResumen("Income", formatoMonto(estado.ingresos()), Colores.verde, privacidad, Modifier.weight(1f))
        TarjetaResumen("Expenses", formatoMonto(estado.gastos()), Colores.rojo, privacidad, Modifier.weight(1f))
        TarjetaResumen("Balance", formatoMonto(estado.saldo()), Color.White, privacidad, Modifier.weight(1f))
    }
}

@Composable
fun TarjetaResumen(etiqueta: String, monto: String, color: Color, privacidad: Boolean, modifier: Modifier) {
    CristalCard(modifier = modifier, padding = 10.dp, radius = 14.dp, paddingHorizontal = 6.dp) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                etiqueta.uppercase(),
                fontSize = 8.sp,
                fontWeight = FontWeight.Medium,
                letterSpacing = 0.5.sp,
                color = Color.White.copy(alpha = 0.28f)
            )
            Spacer(Modifier.height(4.dp))
            MontoPrivado(
                monto,
                privacidad = privacidad,
                fuente = 15,
                peso = FontWeight.Bold,
                color = color,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

private fun colorDona(idx: Int): Color = listOf(
    Color.White,
    Color(0xFFD1D1D1),
    Color(0xFFA3A3A3),
    Color(0xFF8C8C8C),
    Color(0xFF6B6B6B),
    Color(0xFF4D4D4D),
    Color(0xFF383838),
    Color(0xFF292929),
    Color(0xFF1F1F1F),
    Color(0xFF171717),
    Color(0xFF121212),
    Color(0xFF0D0D0D)
)[idx % 12]

@Composable
private fun tarjetaCategorias(estado: AppState) {
    val categorias = estado.gastosPorCategoria()
    CristalCard(padding = 16.dp) {
        Column {
            HTitle("Expenses by Category")
            if (categorias.isEmpty()) {
                Text(
                    "No expenses recorded yet.",
                    fontSize = 13.sp,
                    color = Colores.textoSec,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 60.dp)
                )
                Box(Modifier.size(1.dp))
            } else {
                DonaGrafica(categorias)
            }
        }
    }
}

@Composable
private fun DonaGrafica(categorias: List<Pair<String, Double>>) {
    var activas by remember { mutableStateOf(setOf<String>()) }
    var avanzado by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { avanzado = true }

    val visibles = if (activas.isEmpty()) categorias else categorias.filter { it.first in activas }
    val total = maxOf(visibles.sumOf { it.second }, 0.0001)
    val factor by animateFloatAsState(if (avanzado) 1f else 0f, tween(800), label = "dona")

    Column {
        Box(Modifier.fillMaxWidth().height(132.dp), contentAlignment = Alignment.Center) {
            Canvas(Modifier.fillMaxSize()) {
                val diametro = minOf(size.width, size.height)
                val ancho = minOf(diametro * 0.03f, 8f)
                val gap = 0.0035f
                var acumulado = 0f
                drawCircle(
                    color = Color(0xFF050505),
                    radius = diametro / 2 - ancho / 2,
                    style = Stroke(width = ancho, cap = StrokeCap.Round)
                )
                for ((nombre, valor) in visibles) {
                    val inicio = acumulado / total.toFloat()
                    acumulado += valor.toFloat()
                    val fin = acumulado / total.toFloat()
                    val idx = categorias.indexOfFirst { it.first == nombre }
                    drawArc(
                        color = colorDona(idx),
                        startAngle = -90f + 360f * (inicio + gap) * factor,
                        sweepAngle = 360f * maxOf(fin - inicio - gap * 2, 0f) * factor,
                        useCenter = false,
                        style = Stroke(width = ancho, cap = StrokeCap.Round)
                    )
                }
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    "TOTAL GASTADO",
                    fontSize = 8.sp,
                    fontWeight = FontWeight.Medium,
                    letterSpacing = 1.sp,
                    color = Colores.textoSec.copy(alpha = 0.6f)
                )
                Spacer(Modifier.height(4.dp))
                MontoPrivado(
                    formatoMonto(total),
                    privacidad = Prefs.privacidad(estadoCtx()),
                    fuente = 23,
                    peso = FontWeight.Light
                )
            }
        }
        Spacer(Modifier.height(12.dp))
        Column {
            categorias.forEachIndexed { idx, (nombre, valor) ->
                val encendida = activas.isEmpty() || nombre in activas
                Row(
                    Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(if (encendida) Color.Transparent else Color.White.copy(alpha = 0.05f))
                        .clickable {
                            activas = if (activas.contains(nombre)) activas - nombre else activas + nombre
                        }
                        .padding(horizontal = 12.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        Modifier
                            .size(10.dp)
                            .clip(CircleShape)
                            .background(colorDona(idx).copy(alpha = if (encendida) 1f else 0.15f))
                    )
                    Spacer(Modifier.width(10.dp))
                    Text(
                        nombre,
                        fontSize = 13.sp,
                        color = Color.White.copy(alpha = if (encendida) 0.85f else 0.35f),
                        modifier = Modifier.weight(1f)
                    )
                    MontoPrivado(
                        formatoMonto(valor),
                        privacidad = Prefs.privacidad(estadoCtx()),
                        fuente = 13,
                        peso = FontWeight.SemiBold,
                        color = Color.White.copy(alpha = if (encendida) 1f else 0.35f)
                    )
                    Spacer(Modifier.width(12.dp))
                    Text(
                        "${((valor / total) * 100).toInt()}%",
                        fontSize = 12.sp,
                        color = Colores.textoSec
                    )
                }
                if (idx < categorias.size - 1) {
                    Box(
                        Modifier
                            .height(0.5.dp)
                            .fillMaxWidth()
                            .padding(start = 36.dp)
                            .background(Color.White.copy(alpha = 0.06f))
                    )
                }
            }
        }
    }
}

@Composable
private fun estadoCtx(): android.content.Context = androidx.compose.ui.platform.LocalContext.current

@Composable
private fun tarjetaRecientes(estado: AppState) {
    val ultimos = estado.ultimos(6)
    CristalCard(padding = 16.dp) {
        Column {
            HTitle("Recent Transactions")
            if (ultimos.isEmpty()) {
                Text(
                    "No transactions yet. Go to \"Add\" to get started.",
                    fontSize = 13.sp,
                    color = Colores.textoSec
                )
            } else {
                val privacidad = Prefs.privacidad(estado.ctx)
                ultimos.forEach { m ->
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp)
                            .padding(bottom = if (m == ultimos.last()) 0.dp else 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(m.fecha, fontSize = 14.sp, color = Color.White)
                        Spacer(Modifier.weight(1f))
                        Text(m.categoria, fontSize = 14.sp, color = Color.White)
                        Spacer(Modifier.weight(1f))
                        MontoPrivado(
                            formatoConSigno(m.monto, m.esIngreso),
                            privacidad = privacidad,
                            fuente = 14,
                            peso = FontWeight.SemiBold,
                            color = if (m.esIngreso) Colores.verde else Colores.rojo
                        )
                    }
                    if (m != ultimos.last()) {
                        Box(
                            Modifier
                                .height(1.dp)
                                .fillMaxWidth()
                                .background(Color.White.copy(alpha = 0.02f))
                        )
                    }
                }
                Box(Modifier.size(1.dp))
            }
        }
    }
}

@Composable
private fun tarjetaMetas(
    estado: AppState,
    metaNombre: String,
    onMetaNombre: (String) -> Unit,
    metaObjetivo: String,
    onMetaObjetivo: (String) -> Unit,
    onGuardar: () -> Unit,
    onEliminar: (Meta) -> Unit
) {
    val metas = estado.metas
    CristalCard(padding = 16.dp) {
        Column {
            Row(verticalAlignment = Alignment.CenterVertically) {
                HTitle("Goals & Savings")
                Spacer(Modifier.weight(1f))
                Row(
                    Modifier
                        .clip(CircleShape)
                        .background(Color.White.copy(alpha = 0.06f))
                        .padding(horizontal = 10.dp, vertical = 5.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(Modifier.size(5.dp).clip(CircleShape).background(Colores.verde))
                    Spacer(Modifier.width(4.dp))
                    MontoPrivado(
                        formatoMonto(metas.sumOf { it.ahorrado }),
                        privacidad = Prefs.privacidad(estado.ctx),
                        fuente = 11,
                        peso = FontWeight.SemiBold
                    )
                }
            }

            if (metas.isEmpty()) {
                Text(
                    "Crea tu primera meta: algo que quieras comprar o lograr.",
                    fontSize = 12.sp,
                    color = Colores.textoSec
                )
                Spacer(Modifier.height(8.dp))
            }

            metas.forEach { meta ->
                filaMeta(estado, meta, onEliminar)
            }

            Box(Modifier.height(1.dp).fillMaxWidth().background(Color.White.copy(alpha = 0.06f)))
            Spacer(Modifier.height(12.dp))

            Row(verticalAlignment = Alignment.Bottom) {
                Column(Modifier.weight(1f)) {
                    Text("Goal", fontSize = 11.sp, fontWeight = FontWeight.Medium, color = Colores.textoSec)
                    Spacer(Modifier.height(6.dp))
                    BasicInputWayne(
                        placeholder = "PS5 \u00B7 viaje \u00B7 etc",
                        texto = metaNombre,
                        onTexto = onMetaNombre,
                        altura = 44.dp
                    )
                }
                Spacer(Modifier.width(8.dp))
                Column {
                    Text("Target (\$)", fontSize = 11.sp, fontWeight = FontWeight.Medium, color = Colores.textoSec)
                    Spacer(Modifier.height(6.dp))
                    BasicInputWayne(
                        placeholder = "800.00",
                        texto = metaObjetivo,
                        onTexto = onMetaObjetivo,
                        altura = 44.dp,
                        ancho = 110.dp,
                        teclado = KeyboardType.Decimal
                    )
                }
                Spacer(Modifier.width(8.dp))
                Box(
                    Modifier
                        .size(44.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(Colores.verde)
                        .clickable { onGuardar() },
                    contentAlignment = Alignment.Center
                ) {
                    Text("+", fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = Color.Black)
                }
            }
        }
    }
}

@Composable
fun BasicInputWayne(
    placeholder: String,
    texto: String,
    onTexto: (String) -> Unit,
    altura: androidx.compose.ui.unit.Dp = 44.dp,
    ancho: androidx.compose.ui.unit.Dp? = null,
    teclado: KeyboardType = KeyboardType.Text
) {
    androidx.compose.foundation.text.BasicTextField(
        value = texto,
        onValueChange = onTexto,
        singleLine = true,
        textStyle = androidx.compose.ui.text.TextStyle(color = Color.White, fontSize = 14.sp),
        keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = teclado),
        modifier = Modifier
            .then(if (ancho != null) Modifier.width(ancho) else Modifier.fillMaxWidth())
            .height(altura)
            .clip(RoundedCornerShape(14.dp))
            .background(Color.Black.copy(alpha = 0.25f))
            .padding(horizontal = 14.dp),
        decorationBox = { inner ->
            Box(contentAlignment = Alignment.CenterStart) {
                if (texto.isEmpty()) {
                    Text(placeholder, fontSize = 14.sp, color = Color.White.copy(alpha = 0.2f))
                }
                inner()
            }
        }
    )
}

@Composable
private fun filaMeta(estado: AppState, meta: Meta, onEliminar: (Meta) -> Unit) {
    val pct = if (meta.objetivo > 0) minOf(meta.ahorrado / meta.objetivo, 1.0) else 0.0
    Column(Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(meta.nombre, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = Color.White)
                Row(verticalAlignment = Alignment.CenterVertically) {
                    MontoPrivado(
                        formatoMonto(meta.ahorrado),
                        privacidad = Prefs.privacidad(estado.ctx),
                        fuente = 11,
                        peso = FontWeight.SemiBold,
                        color = Colores.verde
                    )
                    Text(" de ", fontSize = 11.sp, color = Colores.textoSec)
                    MontoPrivado(
                        formatoMonto(meta.objetivo),
                        privacidad = Prefs.privacidad(estado.ctx),
                        fuente = 11,
                        color = Color.White.copy(alpha = 0.5f)
                    )
                    Text(
                        " \u00B7 ${(pct * 100).toInt()}%",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium,
                        color = if (pct >= 1) Colores.verde else Color.White.copy(alpha = 0.35f)
                    )
                }
            }
            BotonIcono(
                mod = Modifier.size(30.dp),
                accion = { estado.ajustarAhorro(meta.id, 10.0) }
            ) {
                Text("+", fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = Color.White)
            }
            Spacer(Modifier.width(8.dp))
            BotonIcono(
                mod = Modifier.size(30.dp),
                accion = { if (meta.ahorrado >= 10) estado.ajustarAhorro(meta.id, -10.0) }
            ) {
                Text("\u2212", fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = Color.White.copy(alpha = 0.7f))
            }
            Spacer(Modifier.width(8.dp))
            Box(
                Modifier
                    .size(28.dp)
                    .clickable { onEliminar(meta) },
                contentAlignment = Alignment.Center
            ) {
                Text("\u2715", fontSize = 10.sp, color = Colores.rojo.copy(alpha = 0.5f))
            }
        }
        Spacer(Modifier.height(6.dp))
        Box(Modifier.fillMaxWidth().height(4.dp).clip(CircleShape).background(Color.White.copy(alpha = 0.05f))) {
            Box(
                Modifier
                    .fillMaxWidth(pct.toFloat())
                    .height(4.dp)
                    .clip(CircleShape)
                    .background(Brush.horizontalGradient(listOf(Colores.verde, Colores.verde.copy(alpha = 0.6f))))
            ) { Box(Modifier.size(1.dp)) }
        }
    }
}

@Composable
private fun tarjetaTendencias(estado: AppState) {
    val tendencias = estado.tendencias()
    CristalCard(padding = 16.dp) {
        HTitle("Monthly Trends")
        if (tendencias.isEmpty()) {
            Text("No data yet.", fontSize = 12.sp, color = Colores.textoSec, modifier = Modifier.fillMaxWidth())
            Spacer(Modifier.height(160.dp))
        } else {
            GraficaTendencias(tendencias)
        }
    }
}

@Composable
private fun GraficaTendencias(datos: List<Triple<String, Double, Double>>) {
    val maximo = maxOf(datos.maxOfOrNull { it.second } ?: 0.0, datos.maxOfOrNull { it.third } ?: 0.0)
    Column {
        Canvas(Modifier.fillMaxWidth().height(200.dp)) {
            val filas = datos.size
            val anchoBarra = size.width / (filas * 3f)
            val nivelMax = maxOf(maximo, 1.0).toFloat()
            for (i in 0..3) {
                val y = size.height * (i / 3f)
                drawLine(
                    Color.White.copy(alpha = 0.03f),
                    start = androidx.compose.ui.geometry.Offset(0f, y),
                    end = androidx.compose.ui.geometry.Offset(size.width, y),
                    strokeWidth = 1f
                )
            }
            datos.forEachIndexed { idx, t ->
                val x = idx * anchoBarra * 3f + anchoBarra / 2f
                val altoInc = (t.second.toFloat() / nivelMax) * size.height * 0.9f
                val altoExp = (t.third.toFloat() / nivelMax) * size.height * 0.9f
                drawRoundRect(
                    color = Colores.verde.copy(alpha = 0.2f),
                    topLeft = androidx.compose.ui.geometry.Offset(x, size.height - altoInc),
                    size = androidx.compose.ui.geometry.Size(anchoBarra, altoInc),
                    cornerRadius = androidx.compose.ui.geometry.CornerRadius(4f, 4f)
                )
                drawRoundRect(
                    color = Colores.rojo.copy(alpha = 0.15f),
                    topLeft = androidx.compose.ui.geometry.Offset(x + anchoBarra, size.height - altoExp),
                    size = androidx.compose.ui.geometry.Size(anchoBarra, altoExp),
                    cornerRadius = androidx.compose.ui.geometry.CornerRadius(4f, 4f)
                )
            }
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(8.dp).clip(CircleShape).background(Colores.verde.copy(alpha = 0.6f)))
            Spacer(Modifier.width(6.dp))
            Text("Income", fontSize = 11.sp, color = Color.White.copy(alpha = 0.5f))
            Spacer(Modifier.width(16.dp))
            Box(Modifier.size(8.dp).clip(CircleShape).background(Colores.rojo.copy(alpha = 0.6f)))
            Spacer(Modifier.width(6.dp))
            Text("Expenses", fontSize = 11.sp, color = Color.White.copy(alpha = 0.5f))
        }
        Spacer(Modifier.height(8.dp))
        Row {
            datos.forEach { t ->
                val etiqueta = try {
                    LocalDate.parse(t.first + "-01").format(DateTimeFormatter.ofPattern("MM/yy"))
                } catch (e: Exception) {
                    t.first
                }
                Text(
                    etiqueta,
                    fontSize = 9.sp,
                    color = Color.White.copy(alpha = 0.2f),
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun tarjetaRecurrentes(onAbrir: () -> Unit) {
    CristalCard(padding = 16.dp) {
        Column(Modifier.fillMaxWidth().clickable { onAbrir() }) {
            HTitle("Recurring")
            Text("Manage auto-transactions \u2192", fontSize = 12.sp, color = Colores.textoSec)
        }
    }
}