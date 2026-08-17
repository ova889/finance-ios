package com.wayne.finance

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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun RecurrentesScreen(estado: AppState, onCerrar: () -> Unit) {
    var tipo by remember { mutableStateOf("gasto") }
    var categoria by remember { mutableStateOf(Categorias.lista("gasto")[0]) }
    var montoTexto by remember { mutableStateOf("") }
    var descripcion by remember { mutableStateOf("") }
    var dia by remember { mutableIntStateOf(1) }
    var mensaje by remember { mutableStateOf<String?>(null) }
    var exito by remember { mutableStateOf(false) }
    var recurrenteAEliminar by remember { mutableStateOf<Recurrente?>(null) }
    var cargado by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) { cargado = true }

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
                Box(
                    Modifier
                        .size(30.dp)
                        .clip(CircleShape)
                        .clickable { onCerrar() },
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        "\u27A4",
                        modifier = Modifier.rotate(180f),
                        fontSize = 14.sp,
                        color = Colores.textoSec
                    )
                }
                EtiquetaTitulo(texto = "Recurring", tamano = 20, modifier = Modifier.padding(start = 8.dp))
                Spacer(Modifier.weight(1f))
                Text(
                    "${estado.recurrentes.size} scheduled",
                    fontSize = 12.sp,
                    color = Colores.textoSec
                )
            }

            if (mensaje != null) {
                AlertaWayne(mensaje = mensaje!!, exito = exito)
            }

            CristalCard(padding = 16.dp) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        ChipTipo("INCOME", tipo == "ingreso", estiloRojo = false, Modifier.weight(1f)) {
                            tipo = "ingreso"
                            categoria = Categorias.lista("ingreso")[0]
                        }
                        ChipTipo("EXPENSE", tipo == "gasto", estiloRojo = true, Modifier.weight(1f)) {
                            tipo = "gasto"
                            categoria = Categorias.lista("gasto")[0]
                        }
                    }

                    VistaDropdown(
                        titulo = "Category",
                        opciones = Categorias.lista(tipo),
                        seleccion = categoria,
                        onSeleccionar = { categoria = it },
                        compacto = true,
                        margenInferior = 10.dp
                    )

                    Column {
                        Text(
                            "Description",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium,
                            color = Colores.textoSec
                        )
                        Spacer(Modifier.height(6.dp))
                        CampoWayne(
                            titulo = "",
                            placeholder = "e.g. Netflix",
                            texto = descripcion,
                            onTexto = { descripcion = it },
                            altura = 36.dp
                        )
                    }

                    Column {
                        Text(
                            "Amount",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium,
                            color = Colores.textoSec
                        )
                        Spacer(Modifier.height(6.dp))
                        CampoWayne(
                            titulo = "",
                            placeholder = "0.00",
                            texto = montoTexto,
                            onTexto = { montoTexto = it },
                            altura = 36.dp,
                            tipoTeclado = KeyboardType.Decimal
                        )
                    }

                    Column {
                        Text(
                            "Day of the month",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium,
                            color = Colores.textoSec
                        )
                        Spacer(Modifier.height(6.dp))
                        Row(
                            Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            BotonIcono(
                                mod = Modifier.size(32.dp),
                                accion = { dia = maxOf(1, dia - 1) }
                            ) {
                                Text("−", fontSize = 16.sp, color = Color.White)
                            }
                            Text(
                                dia.toString(),
                                fontSize = 18.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = Color.White,
                                modifier = Modifier.width(64.dp).padding(vertical = 10.dp),
                            )
                            BotonIcono(
                                mod = Modifier.size(32.dp),
                                accion = { dia = minOf(31, dia + 1) }
                            ) {
                                Text("+", fontSize = 16.sp, color = Color.White)
                            }
                        }
                        Text(
                            "The transaction will be created automatically every month on day $dia",
                            fontSize = 10.sp,
                            color = Colores.textoSec,
                            modifier = Modifier.align(Alignment.CenterHorizontally)
                        )
                    }

                    BtnWayne(texto = "SAVE RECURRING") {
                        val monto = montoTexto.replace(",", ".").toDoubleOrNull()
                        if (monto == null || monto <= 0) {
                            exito = false
                            mensaje = "The amount entered is not valid."
                        } else {
                            estado.crearRecurrente(
                                tipo = tipo,
                                categoria = categoria,
                                monto = monto,
                                descripcion = descripcion.trim(),
                                dia = dia
                            )
                            exito = true
                            mensaje = "Recurring transaction saved."
                            montoTexto = ""
                            descripcion = ""
                        }
                    }
                }
            }

            if (cargado && estado.recurrentes.isNotEmpty()) {
                Text(
                    "SCHEDULED",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.SemiBold,
                    letterSpacing = 2.sp,
                    color = Colores.textoSec
                )
                Column {
                    estado.recurrentes
                        .sortedWith(compareBy<Recurrente> { it.dia }.thenBy { it.categoria })
                        .forEach { r ->
                            Row(
                                Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 6.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    Modifier
                                        .size(34.dp)
                                        .clip(RoundedCornerShape(12.dp))
                                        .background(
                                            if (r.tipo == "ingreso") Color.White.copy(alpha = 0.06f)
                                            else Colores.rojo.copy(alpha = 0.12f)
                                        ),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        r.dia.toString(),
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = if (r.tipo == "ingreso") Color.White else Colores.rojo
                                    )
                                }
                                Column(Modifier.weight(1f).padding(horizontal = 10.dp)) {
                                    Text(
                                        if (r.descripcion.isNotEmpty()) r.descripcion else r.categoria,
                                        fontSize = 14.sp,
                                        fontWeight = FontWeight.Medium,
                                        color = Color.White
                                    )
                                    Text(
                                        r.categoria + " \u00B7 " +
                                            (if (r.tipo == "ingreso") "Income" else "Expense") +
                                            " \u00B7 Every month on day " + r.dia,
                                        fontSize = 11.sp,
                                        color = Colores.textoSec
                                    )
                                }
                                Text(
                                    formatoConSigno(r.monto, r.tipo == "ingreso"),
                                    fontSize = 15.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = if (r.tipo == "ingreso") Colores.verde else Colores.rojo
                                )
                                Box(
                                    Modifier
                                        .padding(start = 8.dp)
                                        .size(30.dp)
                                        .clip(CircleShape)
                                        .clickable { recurrenteAEliminar = r },
                                    contentAlignment = Alignment.Center
                                ) {
                                    IconoBasura(Modifier.size(13.dp), Color.White.copy(alpha = 0.5f))
                                }
                            }
                        }
                }
            }
        }

        recurrenteAEliminar?.let { r ->
            AlertDialog(
                onDismissRequest = { recurrenteAEliminar = null },
                title = { Text("Delete recurring transaction?") },
                text = {
                    Text(
                        "\"${if (r.descripcion.isNotEmpty()) r.descripcion else r.categoria}\" " +
                            "(${formatoMonto(r.monto)} every month on day ${r.dia}) will be removed."
                    )
                },
                confirmButton = {
                    TextButton(onClick = {
                        estado.eliminarRecurrente(r.id)
                        recurrenteAEliminar = null
                    }) { Text("Delete", color = Colores.rojo) }
                },
                dismissButton = {
                    TextButton(onClick = { recurrenteAEliminar = null }) { Text("Cancel") }
                }
            )
        }
    }
}