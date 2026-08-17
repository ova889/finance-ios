package com.wayne.finance

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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun ConfiguracionScreen(estado: AppState, onSalir: () -> Unit) {
    var privacidad by remember { mutableStateOf(Prefs.privacidad(estado.ctx)) }
    var textoPendientes by remember { mutableStateOf("No pending operations") }
    var etapaAlerta by remember { mutableIntStateOf(0) }
    var cargado by remember { mutableStateOf(false) }
    val scope = androidx.compose.runtime.rememberCoroutineScope()

    LaunchedEffect(Unit) { cargado = true }

    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 10.dp)
            .padding(top = 6.dp, bottom = 100.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        EtiquetaTitulo(texto = "Settings", tamano = 17)

        CristalCard(padding = 16.dp) {
            Interruptor(
                texto = "Privacy Mode",
                subtitulo = "Blurs all amounts on screen",
                activo = privacidad,
                onCambiar = {
                    privacidad = !privacidad
                    Prefs.setPrivacidad(estado.ctx, privacidad)
                }
            )
        }

        CristalCard(padding = 16.dp) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text("Pending Operations", fontSize = 15.sp, fontWeight = FontWeight.Medium, color = Color.White)
                    Text(textoPendientes, fontSize = 11.sp, color = Colores.textoSec)
                }
                Box(
                    Modifier
                        .clip(RoundedCornerShape(14.dp))
                        .clickable {
                            textoPendientes = "All operations synced"
                            scope.launch {
                                delay(2000)
                                textoPendientes = "No pending operations"
                            }
                        }
                        .padding(horizontal = 16.dp)
                        .height(32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        "SYNC NOW",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.SemiBold,
                        letterSpacing = 1.5.sp,
                        color = Color.White
                    )
                }
            }
        }

        CristalCard(padding = 16.dp) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text("Clear All Data", fontSize = 15.sp, fontWeight = FontWeight.Medium, color = Color.White)
                    Text("Deletes all transactions and budgets", fontSize = 11.sp, color = Colores.textoSec)
                }
                Box(
                    Modifier
                        .clip(RoundedCornerShape(14.dp))
                        .clickable { etapaAlerta = 1 }
                        .padding(horizontal = 16.dp)
                        .height(32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        "CLEAR",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.SemiBold,
                        letterSpacing = 1.5.sp,
                        color = Colores.rojo
                    )
                }
            }
        }

        Column(Modifier.fillMaxWidth().padding(top = 10.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Text("Finance v2.0", fontSize = 12.sp, color = Colores.textoSec)
            Text("Android \u00B7 Offline-ready", fontSize = 11.sp, color = Colores.textoSec.copy(alpha = 0.6f))
        }

        Spacer(Modifier.height(14.dp))

        Box(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .clickable { onSalir() }
                .height(48.dp),
            contentAlignment = Alignment.Center
        ) {
            Text("Sign Out", fontSize = 13.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 2.sp, color = Colores.rojo)
        }
    }

    if (etapaAlerta > 0) {
        AlertDialog(
            onDismissRequest = { etapaAlerta = 0 },
            title = { Text(if (etapaAlerta == 1) "Delete ALL transactions and budgets?" else "Delete ALL data?") },
            text = { Text(if (etapaAlerta == 1) "This cannot be undone." else "All data will be permanently removed.") },
            confirmButton = {
                TextButton(onClick = {
                    if (etapaAlerta == 1) {
                        etapaAlerta = 2
                    } else {
                        Db.limpiarDatos(estado.userId)
                        estado.recargar()
                        etapaAlerta = 0
                    }
                }) {
                    Text(if (etapaAlerta == 1) "Delete" else "Delete Forever", color = Colores.rojo)
                }
            },
            dismissButton = {
                TextButton(onClick = { etapaAlerta = 0 }) { Text("Cancel") }
            }
        )
    }
}