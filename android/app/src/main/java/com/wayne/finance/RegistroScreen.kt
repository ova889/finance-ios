package com.wayne.finance

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.time.LocalDate

@Composable
fun RegistroScreen(estado: AppState) {
    var montoTexto by remember { mutableStateOf("") }
    var tipo by remember { mutableStateOf("ingreso") }
    var categoria by remember { mutableStateOf(Categorias.ingreso[0]) }
    var descripcion by remember { mutableStateOf("") }
    var fecha by remember { mutableStateOf(LocalDate.now()) }
    var mensaje by remember { mutableStateOf<String?>(null) }
    var exito by remember { mutableStateOf(false) }
    var cargado by remember { mutableStateOf(false) }
    var montoEnfocado by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) { cargado = true }

    val descripcionesUsadas = remember(estado.userId) { Prefs.descripciones(estado.ctx, estado.userId) }

    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 10.dp)
            .padding(top = 6.dp, bottom = 100.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        EtiquetaTitulo(texto = "Add Transaction", tamano = 17)

        mensaje?.let {
            AlertaWayne(mensaje = it, exito = exito)
        }

        CristalCard(padding = 24.dp, radius = 24.dp) {
            Column {
                androidx.compose.foundation.text.BasicTextField(
                    value = montoTexto,
                    onValueChange = { montoTexto = it },
                    singleLine = true,
                    textStyle = TextStyle(
                        color = Color.White,
                        fontSize = 32.sp,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center
                    ),
                    keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 20.dp)
                        .clip(RoundedCornerShape(18.dp))
                        .background(if (montoEnfocado) Color.Black.copy(alpha = 0.5f) else Color.Black.copy(alpha = 0.25f))
                        .padding(horizontal = 16.dp, vertical = 12.dp)
                        .then(
                            Modifier.borderMonto(montoEnfocado)
                        )
                        .focusableMonto { montoEnfocado = it },
                    decorationBox = { inner ->
                        Box(contentAlignment = Alignment.Center) {
                            if (montoTexto.isEmpty()) {
                                Text(
                                    "0.00",
                                    fontSize = 32.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White.copy(alpha = 0.2f)
                                )
                            }
                            inner()
                        }
                    }
                )

                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    ChipTipo("INCOME", tipo == "ingreso", estiloRojo = false, mod = Modifier.weight(1f)) {
                        tipo = "ingreso"
                        categoria = Categorias.lista("ingreso")[0]
                    }
                    ChipTipo("EXPENSE", tipo == "gasto", estiloRojo = true, mod = Modifier.weight(1f)) {
                        tipo = "gasto"
                        categoria = Categorias.lista("gasto")[0]
                    }
                }
                Spacer(Modifier.height(18.dp))

                VistaDropdown(
                    titulo = "Category",
                    opciones = Categorias.lista(tipo),
                    seleccion = categoria,
                    onSeleccionar = { categoria = it },
                    compacto = true
                )

                Column {
                    Text(
                        "Description (optional)",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium,
                        color = Colores.textoSec
                    )
                    if (descripcionesUsadas.isNotEmpty()) {
                        Row(
                            Modifier
                                .fillMaxWidth()
                                .horizontalScroll(rememberScrollState())
                                .padding(vertical = 6.dp),
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            descripcionesUsadas.take(15).forEach { desc ->
                                Text(
                                    desc,
                                    fontSize = 12.sp,
                                    color = Color.White.copy(alpha = 0.6f),
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(20.dp))
                                        .background(Colores.campoBg)
                                        .clickable { descripcion = desc }
                                        .padding(horizontal = 10.dp, vertical = 5.dp)
                                )
                            }
                        }
                    }
                    CampoWayne(
                        titulo = "",
                        placeholder = "Add a note",
                        texto = descripcion,
                        onTexto = { descripcion = it },
                        altura = 36.dp
                    )
                }

                SelectorFecha(
                    titulo = "Date",
                    fecha = fecha,
                    onFecha = { fecha = it }
                )

                Spacer(Modifier.height(10.dp))
                BtnWayne(texto = "CONFIRM TRANSACTION") {
                    val monto = montoTexto.replace(",", ".").toDoubleOrNull()
                    if (monto == null || monto <= 0) {
                        exito = false
                        mensaje = "The amount entered is not valid."
                    } else {
                        estado.guardarMovimiento(
                            tipo = tipo,
                            categoria = categoria,
                            monto = monto,
                            descripcion = descripcion.trim(),
                            fecha = fecha.format(fmtFecha)
                        )
                        val desc = descripcion.trim()
                        if (desc.isNotEmpty()) {
                            Prefs.guardarDescripcion(estado.ctx, estado.userId, desc)
                        }
                        exito = true
                        mensaje = "Transaction saved successfully."
                        montoTexto = ""
                        descripcion = ""
                    }
                }
            }
        }
    }
}

private fun Modifier.borderMonto(enfocado: Boolean): Modifier = this.then(
    Modifier.border(
        1.dp,
        if (enfocado) Colores.accent else Color.White.copy(alpha = 0.1f),
        RoundedCornerShape(18.dp)
    )
)

private fun Modifier.focusableMonto(onCambio: (Boolean) -> Unit): Modifier = this.then(
    Modifier.onFocusChanged { onCambio(it.isFocused) }
)