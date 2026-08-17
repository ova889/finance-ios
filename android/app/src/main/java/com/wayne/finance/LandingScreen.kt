package com.wayne.finance

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
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
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.drawscope.rotate

@Composable
fun LandingScreen(onLanzar: () -> Unit) {
    var cargado by remember { mutableStateOf(false) }
    var flotando by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        cargado = true
        flotando = true
    }

    val infinita = rememberInfiniteTransition(label = "flotar")
    val flotar by infinita.animateFloat(
        initialValue = 0f,
        targetValue = -5f,
        animationSpec = infiniteRepeatable(tween(2500), RepeatMode.Reverse),
        label = "y"
    )
    val escalaLogo by animateFloatAsState(if (cargado) 1f else 0.85f, tween(700), label = "logo")
    val rotLogo by animateFloatAsState(if (cargado) 0f else -6f, tween(700), label = "rot")
    val alfaTitulo by animateFloatAsState(if (cargado) 1f else 0f, tween(700), label = "at")
    val dyTitulo by animateFloatAsState(if (cargado) 0f else 20f, tween(700), label = "dt")

    Box(
        Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(Color(0xFF08080C), Color(0xFF000000), Color(0xFF050508))
                )
            )
    ) {
        Canvas(Modifier.fillMaxSize()) {
            val paso = 48f * density
            val p = androidx.compose.ui.graphics.Path()
            var x = 0f
            while (x <= size.width) {
                p.moveTo(x, 0f)
                p.lineTo(x, size.height)
                x += paso
            }
            var y = 0f
            while (y <= size.height) {
                p.moveTo(0f, y)
                p.lineTo(size.width, y)
                y += paso
            }
            drawPath(p, Color.White.copy(alpha = 0.015f), style = Stroke(width = 1f, cap = androidx.compose.ui.graphics.StrokeCap.Round))
        }

        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(60.dp))

            Box(
                Modifier
                    .offset(y = flotar.dp)
                    .scale(escalaLogo)
                    .rotate(rotLogo)
                    .size(60.dp)
                    .clip(RoundedCornerShape(20.dp))
                    .background(Color.White.copy(alpha = 0.03f)),
                contentAlignment = Alignment.Center
            ) {
                IconoW(Modifier.size(28.dp), opacidad = 0.7f)
            }

            Spacer(Modifier.height(22.dp))

            Box(Modifier.offset(y = dyTitulo.dp)) {
                androidx.compose.material3.Text(
                    "FINANCE",
                    fontSize = 40.sp,
                    fontWeight = FontWeight.Black,
                    letterSpacing = (-1).sp,
                    color = Color.White,
                    modifier = Modifier.alpha(alfaTitulo)
                )
            }

            Spacer(Modifier.height(10.dp))
            androidx.compose.material3.Text(
                "\$ Track every dollar.\nOffline by default. Privacy first.",
                fontSize = 14.sp,
                textAlign = TextAlign.Center,
                color = Color.White.copy(alpha = 0.3f),
                modifier = Modifier
                    .offset(y = dyTitulo.dp)
                    .alpha(alfaTitulo)
            )

            Spacer(Modifier.height(34.dp))
            metricaLanding(cargado)
            Spacer(Modifier.height(14.dp))
            tarjetasCaracteristicas(cargado)
            Spacer(Modifier.height(26.dp))
            botonLanzar(onLanzar, cargado)
            Spacer(Modifier.height(40.dp))
            androidx.compose.material3.Text(
                "PWA · Finance v2.0",
                fontSize = 10.sp,
                letterSpacing = 2.sp,
                color = Color.White.copy(alpha = 0.06f),
                modifier = Modifier.alpha(alfaTitulo)
            )
            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
private fun metricaLanding(cargado: Boolean) {
    val alfa by animateFloatAsState(if (cargado) 1f else 0f, tween(700), label = "m")
    val dy by animateFloatAsState(if (cargado) 0f else 20f, tween(700), label = "md")
    Row(
        Modifier
            .alpha(alfa)
            .offset(y = dy.dp)
            .clip(RoundedCornerShape(20.dp))
            .background(Color.White.copy(alpha = 0.02f))
            .padding(6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        metrica(valor = "+$0", color = Colores.verde, etiqueta = "Income")
        Box(Modifier.height(36.dp).width(1.dp).background(Color.White.copy(alpha = 0.03f)))
        metrica(valor = "-$0", color = Colores.rojo, etiqueta = "Expenses")
        Box(Modifier.height(36.dp).width(1.dp).background(Color.White.copy(alpha = 0.03f)))
        metrica(valor = "$0", color = Color.White, etiqueta = "Balance")
    }
}

@Composable
private fun metrica(valor: String, color: Color, etiqueta: String) {
    Column(
        Modifier
            .width(90.dp)
            .padding(vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        androidx.compose.material3.Text(valor, fontSize = 19.sp, fontWeight = FontWeight.SemiBold, color = color, letterSpacing = (-0.5).sp)
        Spacer(Modifier.height(4.dp))
        androidx.compose.material3.Text(etiqueta.uppercase(), fontSize = 10.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.sp, color = Color.White.copy(alpha = 0.15f))
    }
}

@Composable
private fun tarjetasCaracteristicas(cargado: Boolean) {
    val alfa by animateFloatAsState(if (cargado) 1f else 0f, tween(700), label = "t")
    Column(
        Modifier
            .alpha(alfa)
            .fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        tarjetaCaracteristica("Dashboard", "Balance · Charts · Budgets")
        tarjetaCaracteristica("History", "Search · Filter · Export")
        tarjetaCaracteristica("Offline", "Works without internet")
    }
}

@Composable
private fun tarjetaCaracteristica(titulo: String, desc: String) {
    Row(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(Color.White.copy(alpha = 0.02f))
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f)) {
            androidx.compose.material3.Text(titulo.uppercase(), fontSize = 11.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.sp, color = Color.White.copy(alpha = 0.3f))
            Spacer(Modifier.height(3.dp))
            androidx.compose.material3.Text(desc, fontSize = 11.sp, color = Color.White.copy(alpha = 0.15f))
        }
    }
}

@Composable
private fun botonLanzar(onLanzar: () -> Unit, cargado: Boolean) {
    val alfa by animateFloatAsState(if (cargado) 1f else 0f, tween(700), label = "b")
    Box(
        Modifier
            .alpha(alfa)
            .clip(RoundedCornerShape(14.dp))
            .background(Color.White)
            .clickable { onLanzar() }
            .padding(horizontal = 36.dp, vertical = 16.dp)
    ) {
        androidx.compose.material3.Text(
            "Launch App",
            fontSize = 16.sp,
            fontWeight = FontWeight.SemiBold,
            color = Color.Black
        )
    }
}