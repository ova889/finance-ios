package com.wayne.finance

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        Db.init(applicationContext)
        SeedService.asegurarUsuario()
        setContent {
            AppRaiz()
        }
    }
}

@Composable
fun AppRaiz() {
    val ctx = LocalContext.current
    var usuario by remember { mutableStateOf(Prefs.sesion(ctx)) }
    var enLogin by remember { mutableStateOf(false) }

    Box(Modifier.fillMaxSize().background(Color.Black)) {
        val actual = usuario
        if (actual != null) {
            MainScreen(
                userId = actual,
                onSalir = {
                    Session.cerrarSesion(ctx)
                    usuario = Prefs.sesion(ctx)
                    enLogin = false
                }
            )
        } else if (enLogin) {
            LoginScreen(
                onVolver = { enLogin = false },
                onLogin = { nombre ->
                    usuario = nombre
                    enLogin = false
                }
            )
        } else {
            LandingScreen(onLanzar = { enLogin = true })
        }
    }
}