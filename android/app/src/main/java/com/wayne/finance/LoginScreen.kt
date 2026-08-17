package com.wayne.finance

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun LoginScreen(onVolver: () -> Unit, onLogin: (String) -> Unit) {
    val ctx = LocalContext.current
    var modoRegistro by remember { mutableStateOf(false) }
    var usuario by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmacion by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }
    var exito by remember { mutableStateOf<String?>(null) }

    Box(
        Modifier
            .fillMaxSize()
            .background(Fondo.gradientePantalla)
    ) {
        Column(
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp)
                .padding(top = 60.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            CristalCard(padding = 18.dp) {
                Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        BatSymbol(Modifier.size(width = 44.dp, height = 26.4.dp))
                        Spacer(Modifier.height(10.dp))
                        androidx.compose.material3.Text(
                            "FINANCE",
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 3.sp,
                            color = Color.White
                        )
                        Spacer(Modifier.height(8.dp))
                        Box(
                            Modifier
                                .size(width = 32.dp, height = 1.5.dp)
                                .background(Colores.accent)
                        )
                    }

                    error?.let {
                        Spacer(Modifier.height(22.dp))
                        AlertaWayne(mensaje = it, exito = false)
                    }
                    exito?.let {
                        Spacer(Modifier.height(22.dp))
                        AlertaWayne(mensaje = it, exito = true)
                    }

                    Spacer(Modifier.height(24.dp))
                    CampoWayne(
                        titulo = "User ID",
                        placeholder = "USER ID",
                        texto = usuario,
                        onTexto = { usuario = it },
                        tipoTeclado = KeyboardType.Ascii
                    )
                    CampoWayne(
                        titulo = "Access Code",
                        placeholder = "ACCESS CODE",
                        texto = password,
                        onTexto = { password = it },
                        isSecure = true,
                        tipoTeclado = KeyboardType.Ascii
                    )
                    if (modoRegistro) {
                        CampoWayne(
                            titulo = "Confirm Access Code",
                            placeholder = "CONFIRM ACCESS CODE",
                            texto = confirmacion,
                            onTexto = { confirmacion = it },
                            isSecure = true,
                            tipoTeclado = KeyboardType.Ascii
                        )
                    }

                    BtnWayne(texto = if (modoRegistro) "CREATE ACCOUNT" else "AUTHORIZE") {
                        val res = if (modoRegistro) {
                            Session.registrar(ctx, usuario, password, confirmacion)
                        } else {
                            Session.iniciarSesion(ctx, usuario, password)
                        }
                        if (res != null) {
                            error = null
                            exito = null
                            onLogin(res)
                        } else {
                            error = when {
                                usuario.isBlank() || password.isBlank() -> "Please fill in all fields."
                                modoRegistro && password != confirmacion -> "Access codes do not match."
                                modoRegistro && password.length < 3 -> "Access code must be at least 3 characters."
                                modoRegistro && Db.usuarioPorNombre(usuario.trim()) != null -> "That user ID already exists."
                                else -> "Invalid username or password."
                            }
                        }
                    }
                    Spacer(Modifier.height(20.dp))
                    Box(
                        Modifier
                            .fillMaxWidth()
                            .padding(top = 18.dp)
                            .padding(bottom = 10.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        androidx.compose.material3.Text(
                            if (modoRegistro) "\u2190 Back to login" else "Create your own account",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Medium,
                            color = Colores.textoSec,
                            modifier = Modifier
                                .background(Color.Transparent)
                                .clickable {
                                    modoRegistro = !modoRegistro
                                    error = null
                                    exito = null
                                }
                        )
                    }
                }
            }
            Spacer(Modifier.height(30.dp))
        }
    }
}