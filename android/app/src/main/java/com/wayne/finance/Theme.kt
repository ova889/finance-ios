package com.wayne.finance

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

object Colores {
    val verde = Color(0xFF30D158)
    val rojo = Color(0xFFFF453A)
    val accent = Color(0xFF5E5CE6)
    val textoSec = Color(0xFF8E8E93)
    val cardBg = Color(0xFF08080C)
    val campoBg = Color(0xFF16161A)
    val borde = Color.White.copy(alpha = 0.10f)
    val bordeCard = Color.White.copy(alpha = 0.04f)
    val blancoSuave = Color.White.copy(alpha = 0.28f)
}

@Composable
fun FondoGradiente(modifier: Modifier = Modifier) {
    BoxWithConstraints(modifier.fillMaxSize()) {
        val w = maxWidth.value
        val h = maxHeight.value
        val brush = remember(w, h) {
            Brush.radialGradient(
                colors = listOf(Color(0xFF0F0F10), Color(0xFF000000)),
                center = Offset(w * 0.5f, -h * 0.1f),
                radius = maxOf(w, h) * 1.15f
            )
        }
        Box(Modifier.fillMaxSize().background(brush))
    }
}

object Fondo {
    val gradientePantalla = Brush.verticalGradient(
        colors = listOf(Color(0xFF0F0F10), Color(0xFF000000))
    )
}

@Composable
fun CristalCard(
    modifier: Modifier = Modifier,
    padding: Dp = 16.dp,
    radius: Dp = 24.dp,
    paddingHorizontal: Dp? = null,
    content: @Composable () -> Unit
) {
    val forma = RoundedCornerShape(radius)
    Box(
        modifier = modifier
            .fillMaxWidth()
            .shadow(
                elevation = 32.dp,
                shape = forma,
                clip = false,
                spotColor = Color.Black.copy(alpha = 0.4f),
                ambientColor = Color.Black.copy(alpha = 0.4f)
            )
            .clip(forma)
    ) {
        Box(Modifier.matchParentSize().background(Colores.cardBg.copy(alpha = 0.55f)))
        Box(Modifier.matchParentSize().background(Color.Black.copy(alpha = 0.55f)))
        Box(
            Modifier
                .matchParentSize()
                .background(
                    Brush.linearGradient(
                        listOf(Color.White.copy(alpha = 0.06f), Color.Transparent),
                        start = Offset(0f, 0f),
                        end = Offset(Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY)
                    )
                )
        )
        Box(
            Modifier
                .fillMaxWidth()
                .height(1.dp)
                .align(Alignment.TopCenter)
                .background(
                    Brush.verticalGradient(
                        listOf(Color.White.copy(alpha = 0.12f), Color.White.copy(alpha = 0.04f))
                    )
                )
        )
        Box(
            Modifier
                .fillMaxWidth()
                .height(1.dp)
                .align(Alignment.BottomCenter)
                .background(
                    Brush.verticalGradient(
                        listOf(Color.White.copy(alpha = 0.04f), Color.Transparent)
                    )
                )
        )
        Box(
            Modifier
                .matchParentSize()
                .border(1.dp, Colores.bordeCard, forma)
        )
        Column(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = paddingHorizontal ?: padding, vertical = padding)
        ) {
            content()
        }
    }
}

@Composable
fun CampoWayne(
    titulo: String,
    placeholder: String = "",
    texto: String,
    onTexto: (String) -> Unit,
    isSecure: Boolean = false,
    tipoTeclado: KeyboardType = KeyboardType.Text,
    altura: Dp = 48.dp,
    margenInferior: Dp = 18.dp,
    enfocadoExterno: Boolean? = null,
    onEnfocados: (Boolean) -> Unit = {}
) {
    var interno by remember { mutableStateOf(false) }
    val enfocado = enfocadoExterno ?: interno
    Column(Modifier.padding(bottom = margenInferior)) {
        androidx.compose.material3.Text(
            titulo,
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium,
            color = Colores.textoSec
        )
        Spacer(Modifier.height(6.dp))
        Box {
            BasicTextField(
                value = texto,
                onValueChange = onTexto,
                singleLine = true,
                textStyle = TextStyle(color = Color.White, fontSize = 16.sp),
                keyboardOptions = KeyboardOptions(keyboardType = tipoTeclado),
                visualTransformation = if (isSecure) PasswordVisualTransformation() else VisualTransformation.None,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(altura)
                    .clip(RoundedCornerShape(14.dp))
                    .background(if (enfocado) Color.Black.copy(alpha = 0.5f) else Color.Black.copy(alpha = 0.25f))
                    .border(1.dp, if (enfocado) Colores.accent else Color.White.copy(alpha = 0.1f), RoundedCornerShape(14.dp))
                    .padding(horizontal = 16.dp)
                    .onFocusChanged { estado ->
                        interno = estado.isFocused
                        onEnfocados(estado.isFocused)
                    },
                decorationBox = { inner ->
                    Box(contentAlignment = Alignment.CenterStart) {
                        if (texto.isEmpty()) {
                            androidx.compose.material3.Text(
                                placeholder,
                                fontSize = 16.sp,
                                color = Color.White.copy(alpha = 0.25f)
                            )
                        }
                        inner()
                    }
                }
            )
        }
    }
}

@Composable
fun BtnWayne(
    texto: String,
    pequeno: Boolean = false,
    modifier: Modifier = Modifier,
    colorTexto: Color = Color.White,
    colorBorde: Color = Color.White.copy(alpha = 0.2f),
    accion: () -> Unit
) {
    val interaccion = remember { MutableInteractionSource() }
    val presionado by interaccion.collectIsPressedAsState()
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(14.dp))
            .background(if (presionado) Color.White else Color.Transparent)
            .border(1.dp, colorBorde, RoundedCornerShape(14.dp))
            .height(if (pequeno) 40.dp else 48.dp)
            .clickable(interactionSource = interaccion, indication = null) { accion() },
        contentAlignment = Alignment.Center
    ) {
        androidx.compose.material3.Text(
            texto,
            fontSize = if (pequeno) 11.sp else 13.sp,
            fontWeight = FontWeight.SemiBold,
            letterSpacing = if (pequeno) 1.5.sp else 2.sp,
            color = if (presionado) Color.Black else colorTexto
        )
    }
}

@Composable
fun BtnGhost(texto: String, accion: () -> Unit, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(Color.White.copy(alpha = 0.04f))
            .border(1.dp, Color.White.copy(alpha = 0.15f), RoundedCornerShape(12.dp))
            .height(48.dp)
            .clickable { accion() }
            .padding(horizontal = 18.dp),
        contentAlignment = Alignment.Center
    ) {
        androidx.compose.material3.Text(
            texto,
            fontSize = 13.sp,
            fontWeight = FontWeight.Medium,
            color = Color.White
        )
    }
}

@Composable
fun AlertaWayne(mensaje: String, exito: Boolean, modifier: Modifier = Modifier) {
    val color = if (exito) Colores.verde else Colores.rojo
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .background(color.copy(alpha = 0.03f))
            .border(1.dp, color.copy(alpha = 0.12f), RoundedCornerShape(10.dp))
            .padding(horizontal = 14.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        androidx.compose.material3.Text(
            if (exito) "\u2713" else "\u2717",
            fontSize = 14.sp,
            color = color
        )
        androidx.compose.material3.Text(
            mensaje,
            fontSize = 13.sp,
            color = color
        )
    }
}

@Composable
fun EtiquetaTitulo(texto: String, tamano: Int = 17, modifier: Modifier = Modifier) {
    androidx.compose.material3.Text(
        texto,
        fontSize = tamano.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = (-0.5).sp,
        color = Color.White,
        modifier = modifier.fillMaxWidth()
    )
}

@Composable
fun HTitle(texto: String) {
    androidx.compose.material3.Text(
        texto.uppercase(),
        fontSize = 13.sp,
        fontWeight = FontWeight.SemiBold,
        letterSpacing = 0.3.sp,
        color = Color.White.copy(alpha = 0.28f),
        modifier = Modifier.fillMaxWidth()
    )
}

@Composable
fun MontoPrivado(
    texto: String,
    privacidad: Boolean,
    fuente: Int = 15,
    peso: FontWeight = FontWeight.Bold,
    color: Color = Color.White,
    tnum: Boolean = false,
    modifier: Modifier = Modifier
) {
    androidx.compose.material3.Text(
        texto,
        fontSize = fuente.sp,
        fontWeight = peso,
        color = color,
        fontFeatureSettings = if (tnum) "tnum" else "",
        modifier = modifier.blur(if (privacidad) 8.dp else 0.dp)
    )
}

@Composable
fun ChipTipo(
    texto: String,
    activo: Boolean,
    estiloRojo: Boolean,
    mod: Modifier = Modifier,
    accion: () -> Unit
) {
    val fondo = when {
        !activo -> Color.White.copy(alpha = 0.03f)
        estiloRojo -> Colores.rojo
        else -> Color.White
    }
    val frente = when {
        !activo -> Color.White.copy(alpha = 0.25f)
        estiloRojo -> Color.White
        else -> Color.Black
    }
    Box(
        modifier = mod
            .clip(RoundedCornerShape(14.dp))
            .background(fondo)
            .border(1.dp, Color.White.copy(alpha = 0.06f), RoundedCornerShape(14.dp))
            .height(36.dp)
            .clickable { accion() },
        contentAlignment = Alignment.Center
    ) {
        androidx.compose.material3.Text(
            texto,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            letterSpacing = 1.sp,
            color = frente
        )
    }
}

@Composable
fun BotonIcono(
    mod: Modifier = Modifier,
    accion: () -> Unit,
    content: @Composable () -> Unit
) {
    Box(
        modifier = mod
            .clip(CircleShape)
            .background(Color.White.copy(alpha = 0.06f))
            .clickable { accion() },
        contentAlignment = Alignment.Center
    ) {
        content()
    }
}

data class OpcionDropdown(val texto: String, val marcada: Boolean)