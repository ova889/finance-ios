package com.wayne.finance

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberSwipeToDismissBoxState
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import java.time.LocalDate

@Composable
fun HistorialScreen(estado: AppState) {
    val ctx = LocalContext.current
    var desde by remember { mutableStateOf(LocalDate.now()) }
    var hasta by remember { mutableStateOf(LocalDate.now()) }
    var fechasActivas by remember { mutableStateOf(false) }
    var tipoFiltro by remember { mutableStateOf("All") }
    var busqueda by remember { mutableStateOf("") }
    var movimientoAEditar by remember { mutableStateOf<Movimiento?>(null) }
    var pendienteEliminar by remember { mutableStateOf<Movimiento?>(null) }
    var cargado by remember { mutableStateOf(false) }
    var toast by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) { cargado = true }

    val filtrados = remember(estado.movimientos, fechasActivas, desde, hasta, tipoFiltro, busqueda) {
        val desdeStr = if (fechasActivas) desde.format(fmtFecha) else ""
        val hastaStr = if (fechasActivas) hasta.format(fmtFecha) else ""
        estado.delUsuario()
            .filter { m ->
                if (desdeStr.isNotEmpty() && m.fecha < desdeStr) return@filter false
                if (hastaStr.isNotEmpty() && m.fecha > hastaStr) return@filter false
                if (tipoFiltro == "Income" && !m.esIngreso) return@filter false
                if (tipoFiltro == "Expense" && m.esIngreso) return@filter false
                if (busqueda.isNotEmpty()) {
                    val texto = (m.descripcion + " " + m.categoria).lowercase()
                    if (!texto.contains(busqueda.lowercase())) return@filter false
                }
                true
            }
            .sortedWith(compareByDescending<Movimiento> { it.fecha }.thenByDescending { it.monto })
    }

    val agrupados = remember(filtrados) {
        val grupos = mutableListOf<Pair<String, List<Movimiento>>>()
        for (m in filtrados) {
            val idx = grupos.indexOfLast { it.first == m.fecha }
            if (idx >= 0) {
                grupos[idx] = grupos[idx].first to (grupos[idx].second + m)
            } else {
                grupos.add(m.fecha to listOf(m))
            }
        }
        grupos
    }

    val totalIngresos = filtrados.filter { it.esIngreso }.sumOf { it.monto }
    val totalGastos = filtrados.filter { !it.esIngreso }.sumOf { it.monto }

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
                EtiquetaTitulo(texto = "Transaction History", tamano = 17, modifier = Modifier.weight(1f))
                BtnGhost("CSV", { exportar(estado, filtrados, tipoMime = "text/csv") })
                Spacer(Modifier.width(6.dp))
                BtnGhost("PDF", { exportar(estado, filtrados, tipoMime = "application/pdf") })
            }

            CristalCard(padding = 16.dp) {
                Column {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        SelectorFecha(
                            titulo = "From",
                            fecha = desde,
                            onFecha = { desde = it; fechasActivas = true },
                            modifier = Modifier.weight(1f)
                        )
                        SelectorFecha(
                            titulo = "To",
                            fecha = hasta,
                            onFecha = { hasta = it; fechasActivas = true },
                            modifier = Modifier.weight(1f)
                        )
                    }
                    Spacer(Modifier.height(10.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                        VistaDropdown(
                            opciones = listOf("All", "Income", "Expense"),
                            seleccion = tipoFiltro,
                            onSeleccionar = { tipoFiltro = it },
                            compacto = true,
                            margenInferior = 0.dp,
                            modifier = Modifier.weight(1f)
                        )
                        BtnWayne(
                            texto = "Filter",
                            pequeno = true,
                            accion = {},
                            modifier = Modifier.width(110.dp)
                        )
                        BtnGhost("Clear", {
                            fechasActivas = false
                            tipoFiltro = "All"
                            busqueda = ""
                            desde = LocalDate.now()
                            hasta = LocalDate.now()
                        })
                    }
                }
            }

            Row(horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                TarjetaResumen("Income", formatoMonto(totalIngresos), Colores.verde, Prefs.privacidad(estado.ctx), Modifier.weight(1f))
                TarjetaResumen("Expenses", formatoMonto(totalGastos), Colores.rojo, Prefs.privacidad(estado.ctx), Modifier.weight(1f))
            }

            Row(
                Modifier
                    .fillMaxWidth()
                    .height(44.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(Color.Black.copy(alpha = 0.25f))
                    .padding(horizontal = 16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("\uD83D\uDD0D", fontSize = 14.sp, color = Color.White.copy(alpha = 0.3f))
                Spacer(Modifier.width(10.dp))
                BasicInputWayne(
                    placeholder = "Search transactions...",
                    texto = busqueda,
                    onTexto = { busqueda = it },
                    altura = 44.dp
                )
            }

            Column {
                if (filtrados.isEmpty()) {
                    CristalCard(padding = 24.dp) {
                        Text(
                            "No transactions found for these filters.",
                            fontSize = 13.sp,
                            color = Colores.textoSec,
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                } else {
                    agrupados.forEach { (fecha, items) ->
                        Text(
                            fechaLegible(fecha).uppercase(),
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold,
                            letterSpacing = 0.5.sp,
                            color = Color.White.copy(alpha = 0.2f),
                            modifier = Modifier.padding(top = 16.dp, bottom = 8.dp, start = 4.dp)
                        )
                        items.forEach { m ->
                            FilaMovimiento(
                                m = m,
                                onTap = { movimientoAEditar = m },
                                onEliminar = { pendienteEliminar = m },
                                privacidad = Prefs.privacidad(estado.ctx)
                            )
                        }
                    }
                }
            }
        }

        movimientoAEditar?.let { mov ->
            Box(
                Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.6f))
                    .clickable { movimientoAEditar = null }
                    .zIndex(5f)
            )
            EditarMovimiento(
                movimiento = mov,
                estado = estado,
                onCerrar = { movimientoAEditar = null },
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .zIndex(6f)
            )
        }

        pendienteEliminar?.let { m ->
            AlertDialog(
                onDismissRequest = { pendienteEliminar = null },
                title = { Text("Delete transaction?") },
                text = {
                    Text("This will permanently delete \"${m.descripcion}\" (${formatoMonto(m.monto)}). This action cannot be undone.")
                },
                confirmButton = {
                    TextButton(onClick = {
                        estado.eliminarMovimiento(m)
                        pendienteEliminar = null
                        toast = "Transaction deleted"
                    }) { Text("Delete", color = Colores.rojo) }
                },
                dismissButton = {
                    TextButton(onClick = { pendienteEliminar = null }) { Text("Cancel") }
                }
            )
        }

        toast?.let {
            ToastWayne(mensaje = it, tipo = TipoToast.EXITO) { toast = null }
        }
    }
}

private fun exportar(estado: AppState, filtrados: List<Movimiento>, tipoMime: String) {
    val res = if (tipoMime.contains("csv")) {
        ExportService.generarCSV(estado.ctx, filtrados)
    } else {
        ExportService.generarPDF(estado.ctx, filtrados)
    }
    res?.let { ExportService.compartir(estado.ctx, it, tipoMime) }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FilaMovimiento(
    m: Movimiento,
    onTap: () -> Unit,
    onEliminar: () -> Unit,
    privacidad: Boolean
) {
    val estado = rememberSwipeToDismissBoxState(
        confirmValueChange = { valor ->
            if (valor == SwipeToDismissBoxValue.EndToStart) {
                onEliminar()
            }
            false
        }
    )

    SwipeToDismissBox(
        state = estado,
        enableDismissFromStartToEnd = false,
        backgroundContent = {
            Row(
                Modifier
                    .fillMaxSize()
                    .padding(top = 10.dp, end = 10.dp, bottom = 10.dp),
                horizontalArrangement = Arrangement.End,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    Modifier
                        .width(72.dp)
                        .fillMaxSize()
                        .clip(RoundedCornerShape(18.dp))
                        .background(Colores.rojo),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        IconoBasura(Modifier.size(18.dp), color = Color.White.copy(alpha = 0.85f), grosor = 1.5f)
                        Text("Delete", fontSize = 9.5.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 0.3.sp, color = Color.White)
                    }
                }
            }
        }
    ) {
        Row(
            Modifier
                .padding(vertical = 2.dp)
                .fillMaxWidth()
                .clip(RoundedCornerShape(24.dp))
                .background(
                    Brush.linearGradient(
                        listOf(Color(0xFF08080C), Color(0xFF060608))
                    )
                )
                .clickable { onTap() }
                .padding(14.dp)
        ) {
            Column(Modifier.weight(1f)) {
                Text(
                    if (m.descripcion.isEmpty()) m.categoria else m.descripcion,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Medium,
                    color = Color.White,
                    maxLines = 1
                )
                Spacer(Modifier.height(2.dp))
                Text(m.categoria, fontSize = 11.sp, color = Colores.textoSec)
            }
            MontoPrivado(
                formatoConSigno(m.monto, m.esIngreso),
                privacidad = privacidad,
                fuente = 18,
                peso = FontWeight.Bold,
                color = if (m.esIngreso) Colores.verde else Colores.rojo
            )
        }
    }
}

@Composable
private fun EditarMovimiento(
    movimiento: Movimiento,
    estado: AppState,
    onCerrar: () -> Unit,
    modifier: Modifier = Modifier
) {
    var categoria by remember { mutableStateOf(movimiento.categoria) }
    var montoTexto by remember { mutableStateOf("%.2f".format(movimiento.monto)) }
    var descripcion by remember { mutableStateOf(movimiento.descripcion) }
    var fecha by remember { mutableStateOf(fechaDesdeString(movimiento.fecha) ?: LocalDate.now()) }

    Column(
        modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp))
            .background(Color(0xFF0F0F12))
            .padding(horizontal = 20.dp)
            .padding(top = 14.dp, bottom = 30.dp)
            .verticalScroll(rememberScrollState())
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                "Cancel",
                fontSize = 14.sp,
                color = Colores.textoSec,
                modifier = Modifier.clickable { onCerrar() }
            )
            Spacer(Modifier.weight(1f))
            Text(
                "Edit Transaction",
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color.White
            )
            Spacer(Modifier.weight(1f))
            Spacer(Modifier.width(50.dp))
        }
        Spacer(Modifier.height(14.dp))

        VistaDropdown(
            titulo = "Category",
            opciones = Categorias.lista(movimiento.tipo),
            seleccion = categoria,
            onSeleccionar = { categoria = it },
            compacto = true
        )

        CampoWayne(
            titulo = "Amount (\$)",
            placeholder = "0.00",
            texto = montoTexto,
            onTexto = { montoTexto = it },
            tipoTeclado = KeyboardType.Decimal,
            altura = 36.dp
        )

        CampoWayne(
            titulo = "Description (optional)",
            placeholder = "Add a note",
            texto = descripcion,
            onTexto = { descripcion = it },
            altura = 36.dp
        )

        SelectorFecha(
            titulo = "Date",
            fecha = fecha,
            onFecha = { fecha = it }
        )

        Spacer(Modifier.height(10.dp))
        BtnWayne(texto = "Save Changes") {
            val monto = montoTexto.replace(",", ".").toDoubleOrNull()
            if (monto != null && monto > 0) {
                estado.actualizarMovimiento(
                    movimiento.copy(
                        categoria = categoria,
                        monto = monto,
                        descripcion = descripcion.trim(),
                        fecha = fecha.format(fmtFecha)
                    )
                )
                onCerrar()
            }
        }
        Spacer(Modifier.height(20.dp))
    }
}