package com.wayne.finance

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import kotlin.math.roundToInt
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

enum class TabPrincipal(val indice: Int) {
    DASHBOARD(0), HISTORIAL(1), REGISTRO(2), CONFIGURACION(3)
}

@Composable
fun MainScreen(userId: String, onSalir: () -> Unit) {
    val ctx = LocalContext.current
    val estado = remember(userId) { AppState(ctx, userId) }
    var tab by remember { mutableStateOf(TabPrincipal.DASHBOARD) }
    var splash by remember { mutableStateOf(true) }
    var tapBrand by remember { mutableIntStateOf(0) }
    var toast by remember { mutableStateOf<String?>(null) }
    var toastTipo by remember { mutableStateOf(TipoToast.EXITO) }
    val scope = rememberCoroutineScope()

    LaunchedEffect(estado) {
        estado.recargar()
        val creados = RecurringService.checkRecurrentes(ctx, userId)
        if (creados.isNotEmpty()) {
            estado.recargar()
            toastTipo = TipoToast.EXITO
            toast = creados.joinToString(" \u00B7 ")
        }
        delay(1050)
        splash = false
    }

    val alfaSplash by animateFloatAsState(if (splash) 1f else 0f, tween(500), label = "splash")
    val escalaContenido by animateFloatAsState(if (splash) 1.04f else 1f, tween(450), label = "contenido")
    val pulsoLatido by animateFloatAsState(
        if (!splash) 1.3f else 1f,
        infiniteRepeatable(tween(1100), RepeatMode.Reverse),
        label = "lat"
    )

    Box(
        Modifier
            .fillMaxSize()
            .background(Fondo.gradientePantalla)
    ) {
        Column(
            Modifier
                .fillMaxSize()
                .scale(escalaContenido)
                .imePadding()
        ) {
            topBar(
                balance = estado.saldo(),
                latido = pulsoLatido,
                privacidad = Prefs.privacidad(ctx),
                onTitulo = {
                    tapBrand += 1
                    if (tapBrand >= 2) {
                        tapBrand = 0
                        onSalir()
                    } else {
                        scope.launch {
                            delay(300)
                            tapBrand = 0
                        }
                    }
                },
                onSalir = onSalir
            )

            Box(
                Modifier
                    .fillMaxSize()
                    .weight(1f)
            ) {
                when (tab) {
                    TabPrincipal.DASHBOARD -> DashboardScreen(estado)
                    TabPrincipal.HISTORIAL -> HistorialScreen(estado)
                    TabPrincipal.REGISTRO -> RegistroScreen(estado)
                    TabPrincipal.CONFIGURACION -> ConfiguracionScreen(estado, onSalir)
                }
            }
        }

        barraNavegacion(
            tab = tab,
            onTab = { tab = it },
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 24.dp)
        )

        toast?.let {
            Box(
                Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 110.dp)
                    .zIndex(1f)
            ) {
                ToastWayne(mensaje = it, tipo = toastTipo) { toast = null }
            }
        }

        if (splash) {
            Box(
                Modifier
                    .fillMaxSize()
                    .background(Color.Black)
                    .alpha(alfaSplash)
                    .zIndex(2f),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    IconoW(Modifier.size(46.dp))
                    Spacer(Modifier.height(16.dp))
                    androidx.compose.material3.Text(
                        "FINANCE",
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 7.sp,
                        color = Color.White
                    )
                    Spacer(Modifier.height(10.dp))
                    Box(
                        Modifier
                            .height(2.dp)
                            .width(40.dp)
                            .background(Colores.accent)
                    )
                    Box(Modifier.size(1.dp))
                }
            }
        }
    }
}

@Composable
private fun topBar(
    balance: Double,
    latido: Float,
    privacidad: Boolean,
    onTitulo: () -> Unit,
    onSalir: () -> Unit
) {
    Row(
        Modifier
            .fillMaxWidth()
            .background(Color.Black.copy(alpha = 0.55f))
            .statusBarsPadding()
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(
            Modifier.clickable { onTitulo() },
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            IconoW(Modifier.size(16.dp), opacidad = 0.5f)
            androidx.compose.material3.Text(
                "FINANCE",
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 1.5.sp,
                color = Color.White.copy(alpha = 0.45f)
            )
        }

        Spacer(Modifier.weight(1f))

        MontoPrivado(
            texto = formatoMonto(balance),
            privacidad = privacidad,
            fuente = 12,
            peso = FontWeight.Bold,
            modifier = Modifier.padding(end = 8.dp)
        )

        Box(
            Modifier
                .width(1.dp)
                .height(14.dp)
                .background(Color.White.copy(alpha = 0.06f))
        )

        Spacer(Modifier.width(8.dp))

        Box(
            Modifier
                .size(6.dp)
                .scale(latido)
                .clip(CircleShape)
                .background(Colores.verde)
        )

        Spacer(Modifier.width(10.dp))

        Box(
            Modifier
                .clip(RoundedCornerShape(8.dp))
                .clickable { onSalir() }
                .padding(horizontal = 10.dp, vertical = 5.dp)
        ) {
            androidx.compose.material3.Text(
                "Sign Out",
                fontSize = 10.sp,
                fontWeight = FontWeight.Medium,
                letterSpacing = 0.3.sp,
                color = Colores.rojo
            )
        }
    }
}

@Composable
private fun barraNavegacion(
    tab: TabPrincipal,
    onTab: (TabPrincipal) -> Unit,
    modifier: Modifier = Modifier
) {
    val dyTotal = remember { mutableStateOf(0f) }
    val offsetY = remember { Animatable(0f) }
    val scope = rememberCoroutineScope()

    val barraBase = Modifier
        .fillMaxWidth()
        .height(52.dp)
        .shadow(24.dp, CircleShape, clip = false, spotColor = Color.Black.copy(alpha = 0.35f), ambientColor = Color.Black.copy(alpha = 0.35f))
        .clip(CircleShape)
        .background(Color.Black.copy(alpha = 0.6f))

    BoxWithConstraints(
        modifier = modifier
            .padding(horizontal = 12.dp)
            .then(barraBase)
            .offset { IntOffset(0, offsetY.value.roundToInt()) }
            .pointerInput(Unit) {
                detectDragGestures(
                    onDrag = { cambio, cantidad ->
                        cambio.consume()
                        dyTotal.value += cantidad.y
                        scope.launch {
                            offsetY.snapTo(
                                if (dyTotal.value < 0) dyTotal.value * 0.25f else dyTotal.value * 0.45f
                            )
                        }
                    },
                    onDragEnd = { volver(scope, offsetY, dyTotal) },
                    onDragCancel = { volver(scope, offsetY, dyTotal) }
                )
            }
    ) {
        val anchoItem = maxWidth / 4f
        val barraX by animateDpAsState(
            anchoItem * tab.indice,
            spring(dampingRatio = 0.66f, stiffness = Spring.StiffnessLow),
            label = "pill"
        )

        Box(
            Modifier
                .offset(x = barraX)
                .size(width = anchoItem, height = 52.dp)
                .clip(CircleShape)
                .background(
                    Brush.verticalGradient(
                        listOf(Color.White.copy(alpha = 0.28f), Color.White.copy(alpha = 0.10f))
                    )
                )
        )

        Row(Modifier.fillMaxSize()) {
            TabPrincipal.entries.forEach { item ->
                val activo = tab == item
                val iconColor = if (activo) Color.White else Color.White.copy(alpha = 0.55f)
                Box(
                    Modifier
                        .weight(1f)
                        .fillMaxSize()
                        .clickable { onTab(item) },
                    contentAlignment = Alignment.Center
                ) {
                    val tam = 22.dp
                    when (item) {
                        TabPrincipal.DASHBOARD -> IconoGrid(Modifier.size(tam), iconColor)
                        TabPrincipal.HISTORIAL -> IconoReloj(Modifier.size(tam), iconColor)
                        TabPrincipal.REGISTRO -> IconoMas(Modifier.size(tam), iconColor)
                        TabPrincipal.CONFIGURACION -> IconoEngranaje(Modifier.size(tam), iconColor)
                    }
                }
            }
        }
    }
}

private fun volver(
    scope: kotlinx.coroutines.CoroutineScope,
    offsetY: Animatable<Float, androidx.compose.animation.core.AnimationVector1D>,
    dyTotal: androidx.compose.runtime.MutableState<Float>
) {
    dyTotal.value = 0f
    scope.launch {
        offsetY.animateTo(0f, spring(dampingRatio = 0.6f, stiffness = Spring.StiffnessMediumLow))
    }
}