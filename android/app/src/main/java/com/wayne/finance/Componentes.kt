package com.wayne.finance

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.time.LocalDate
import java.time.ZoneOffset

@Composable
fun VistaDropdown(
    opciones: List<String>,
    seleccion: String,
    onSeleccionar: (String) -> Unit,
    titulo: String = "",
    compacto: Boolean = false,
    ancho: Int = 220,
    margenInferior: androidx.compose.ui.unit.Dp = 18.dp,
    alinearDerecha: Boolean = false,
    modifier: Modifier = Modifier
) {
    var abierto by remember { mutableStateOf(false) }
    val altura = if (compacto) 32.dp else 48.dp

    Column(modifier = modifier.padding(bottom = margenInferior)) {
        if (titulo.isNotEmpty()) {
            Text(
                titulo,
                fontSize = 11.sp,
                fontWeight = FontWeight.Medium,
                color = Colores.textoSec
            )
            Spacer(Modifier.height(6.dp))
        }
        Box {
            Box(
                modifier = Modifier
                    .then(if (ancho > 0) Modifier.width(ancho.dp) else Modifier.fillMaxWidth())
                    .height(altura)
                    .background(Color.Black.copy(alpha = if (abierto) 0.5f else 0.25f))
                    .clickable { abierto = true }
                    .padding(horizontal = if (compacto) 8.dp else 16.dp),
                contentAlignment = Alignment.CenterStart
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        seleccion,
                        fontSize = if (compacto) 13.sp else 16.sp,
                        color = Color.White,
                        modifier = Modifier.weight(1f)
                    )
                    Text(
                        if (abierto) "\u25B2" else "\u25BC",
                        fontSize = 9.sp,
                        color = Color.White.copy(alpha = 0.5f)
                    )
                }
            }
            DropdownMenu(
                expanded = abierto,
                onDismissRequest = { abierto = false },
                modifier = Modifier
                    .width(ancho.dp)
                    .background(Color.Black.copy(alpha = 0.85f)),
                containerColor = Color.Black.copy(alpha = 0.85f)
            ) {
                for (op in opciones) {
                    DropdownMenuItem(
                        text = {
                            Text(
                                op,
                                fontSize = 13.sp,
                                fontWeight = if (op == seleccion) FontWeight.SemiBold else FontWeight.Normal,
                                color = if (op == seleccion) Color.White else Color.White.copy(alpha = 0.7f)
                            )
                        },
                        trailingIcon = {
                            if (op == seleccion) {
                                Text("\u2713", fontSize = 11.sp, color = Color.White.copy(alpha = 0.7f))
                            }
                        },
                        onClick = {
                            onSeleccionar(op)
                            abierto = false
                        }
                    )
                }
            }
        }
    }
}

enum class TipoToast { EXITO, WARNING, INFO }

@Composable
fun ToastWayne(mensaje: String, tipo: TipoToast, onOcultar: () -> Unit) {
    var visible by remember { mutableStateOf(true) }
    LaunchedEffect(Unit) {
        kotlinx.coroutines.delay(3000)
        visible = false
        onOcultar()
    }
    if (visible) {
        Box(
            modifier = Modifier
                .background(
                    Color(0xFF141419).copy(alpha = 0.92f),
                    RoundedCornerShape(14.dp)
                )
                .padding(horizontal = 20.dp, vertical = 12.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    when (tipo) {
                        TipoToast.EXITO -> "\u2713"
                        TipoToast.WARNING -> "!"
                        TipoToast.INFO -> "i"
                    },
                    fontSize = 15.sp,
                    color = Color.White,
                    modifier = Modifier.padding(end = 10.dp)
                )
                Text(
                    mensaje,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                    color = Color.White,
                    maxLines = 2
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SelectorFecha(
    titulo: String,
    fecha: LocalDate,
    onFecha: (LocalDate) -> Unit,
    modifier: Modifier = Modifier
) {
    var abierto by remember { mutableStateOf(false) }

    Column(modifier) {
        Text(titulo, fontSize = 11.sp, fontWeight = FontWeight.Medium, color = Colores.textoSec)
        Spacer(Modifier.height(6.dp))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(36.dp)
                .background(Color.Black.copy(alpha = 0.25f))
                .clickable { abierto = true }
                .padding(horizontal = 12.dp),
            contentAlignment = Alignment.CenterStart
        ) {
            Text(
                fecha.format(fmtFecha),
                fontSize = 14.sp,
                color = Color.White
            )
        }
    }

    if (abierto) {
        val estado = rememberDatePickerState(
            initialSelectedDateMillis = fecha.atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli()
        )
        DatePickerDialog(
            onDismissRequest = { abierto = false },
            confirmButton = {
                TextButton(onClick = {
                    estado.selectedDateMillis?.let { ms ->
                        onFecha(
                            java.time.Instant.ofEpochMilli(ms)
                                .atZone(ZoneOffset.UTC)
                                .toLocalDate()
                        )
                    }
                    abierto = false
                }) { Text("OK") }
            },
            dismissButton = {
                TextButton(onClick = { abierto = false }) { Text("Cancel") }
            }
        ) {
            DatePicker(state = estado, showModeToggle = false)
        }
    }
}

@Composable
fun Interruptor(texto: String, subtitulo: String, activo: Boolean, onCambiar: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onCambiar() }
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f)) {
            Text(texto, fontSize = 15.sp, fontWeight = FontWeight.Medium, color = Color.White)
            Text(subtitulo, fontSize = 11.sp, color = Colores.textoSec)
        }
        Box(
            modifier = Modifier
                .size(width = 44.dp, height = 24.dp)
                .background(
                    if (activo) Color.White.copy(alpha = 0.25f) else Color.White.copy(alpha = 0.08f),
                    RoundedCornerShape(12.dp)
                )
                .padding(2.dp),
            contentAlignment = if (activo) Alignment.CenterEnd else Alignment.CenterStart
        ) {
            Box(
                Modifier
                    .size(20.dp)
                    .background(if (activo) Color.White else Color.White.copy(alpha = 0.4f))
            )
        }
    }
}