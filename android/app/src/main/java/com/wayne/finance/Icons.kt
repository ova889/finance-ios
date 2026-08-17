package com.wayne.finance

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp

private fun Path.line(x1: Float, y1: Float, x2: Float, y2: Float) {
    moveTo(x1, y1)
    lineTo(x2, y2)
}

@Composable
fun IconoW(mod: Modifier = Modifier, color: Color = Color.White, opacidad: Float = 1f) {
    Canvas(modifier = mod) {
        val s = size.minDimension / 24f
        val path = Path()
        path.line(8 * s, 4 * s, 18 * s, 4 * s)
        path.line(8 * s, 4 * s, 8 * s, 20 * s)
        path.line(8 * s, 12 * s, 15 * s, 12 * s)
        drawPath(path, color.copy(alpha = opacidad), style = Stroke(width = 1.8f * s, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

@Composable
fun IconoGrid(mod: Modifier = Modifier, color: Color = Color.White, grosor: Float = 1.5f) {
    Canvas(modifier = mod) {
        val s = size.minDimension / 24f
        val path = Path()
        for ((x, y) in listOf(3f to 3f, 14f to 3f, 3f to 14f, 14f to 14f)) {
            path.addRoundRect(
                Rect(Offset(x * s, y * s), Size(7 * s, 7 * s)),
                cornerRadius = androidx.compose.ui.geometry.CornerRadius(1 * s, 1 * s)
            )
        }
        drawPath(path, color, style = Stroke(width = grosor * s, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

@Composable
fun IconoReloj(mod: Modifier = Modifier, color: Color = Color.White, grosor: Float = 1.5f) {
    Canvas(modifier = mod) {
        val s = size.minDimension / 24f
        val path = Path()
        path.addOval(Rect(Offset(2 * s, 2 * s), Size(20 * s, 20 * s)))
        path.line(12 * s, 6 * s, 12 * s, 12 * s)
        path.line(12 * s, 12 * s, 16 * s, 14 * s)
        drawPath(path, color, style = Stroke(width = grosor * s, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

@Composable
fun IconoMas(mod: Modifier = Modifier, color: Color = Color.White, grosor: Float = 2.5f) {
    Canvas(modifier = mod) {
        val s = size.minDimension / 24f
        val path = Path()
        path.line(12 * s, 5 * s, 12 * s, 19 * s)
        path.line(5 * s, 12 * s, 19 * s, 12 * s)
        drawPath(path, color, style = Stroke(width = grosor * s, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

@Composable
fun IconoEngranaje(mod: Modifier = Modifier, color: Color = Color.White, grosor: Float = 1.5f) {
    Canvas(modifier = mod) {
        val s = size.minDimension / 24f
        val path = Path()
        val c = Offset(12 * s, 12 * s)
        path.addOval(Rect(Offset(4.5f * s, 4.5f * s), Size(15 * s, 15 * s)))
        path.addOval(Rect(Offset(8.5f * s, 8.5f * s), Size(7 * s, 7 * s)))
        for (k in 0 until 8) {
            val a = Math.toRadians(45.0 * k)
            val r1 = 7.4f * s
            val r2 = 9.4f * s
            path.line(
                c.x + (r1 * Math.cos(a)).toFloat(),
                c.y + (r1 * Math.sin(a)).toFloat(),
                c.x + (r2 * Math.cos(a)).toFloat(),
                c.y + (r2 * Math.sin(a)).toFloat()
            )
        }
        drawPath(path, color, style = Stroke(width = grosor * s, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

@Composable
fun IconoBasura(mod: Modifier = Modifier, color: Color = Color.White, grosor: Float = 1.5f) {
    Canvas(modifier = mod) {
        val s = size.minDimension / 24f
        val path = Path()
        path.line(3 * s, 6 * s, 21 * s, 6 * s)
        path.line(19 * s, 6 * s, 19 * s, 20 * s)
        path.line(19 * s, 20 * s, 17 * s, 20 * s)
        path.line(17 * s, 20 * s, 17 * s, 22 * s)
        path.line(17 * s, 22 * s, 7 * s, 22 * s)
        path.line(7 * s, 22 * s, 7 * s, 20 * s)
        path.line(7 * s, 20 * s, 5 * s, 20 * s)
        path.line(5 * s, 20 * s, 5 * s, 6 * s)
        path.line(8 * s, 6 * s, 8 * s, 4 * s)
        path.line(8 * s, 4 * s, 10 * s, 4 * s)
        path.line(10 * s, 4 * s, 10 * s, 2 * s)
        path.line(10 * s, 2 * s, 14 * s, 2 * s)
        path.line(14 * s, 2 * s, 14 * s, 4 * s)
        path.line(14 * s, 4 * s, 16 * s, 4 * s)
        path.line(16 * s, 4 * s, 16 * s, 6 * s)
        path.line(10 * s, 11 * s, 10 * s, 17 * s)
        path.line(14 * s, 11 * s, 14 * s, 17 * s)
        drawPath(path, color, style = Stroke(width = grosor * s, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

@Composable
fun BatSymbol(mod: Modifier = Modifier, color: Color = Color.White.copy(alpha = 0.7f)) {
    Canvas(modifier = mod) {
        val sx = size.width / 100f
        val sy = size.height / 60f
        val path = Path()
        path.moveTo(50f * sx, 15f * sy)
        path.cubicTo(47f * sx, 12f * sy, 42f * sx, 4f * sy, 40f * sx, 2f * sy)
        path.cubicTo(38f * sx, 5f * sy, 37f * sx, 13f * sy, 34f * sx, 14f * sy)
        path.cubicTo(25f * sx, 12f * sy, 12f * sx, 18f * sy, 2f * sx, 30f * sy)
        path.cubicTo(12f * sx, 33f * sy, 22f * sx, 28f * sy, 28f * sx, 32f * sy)
        path.cubicTo(32f * sx, 38f * sy, 30f * sx, 52f * sy, 50f * sx, 58f * sy)
        path.cubicTo(70f * sx, 52f * sy, 68f * sx, 38f * sy, 72f * sx, 32f * sy)
        path.cubicTo(78f * sx, 28f * sy, 88f * sx, 33f * sy, 98f * sx, 30f * sy)
        path.cubicTo(88f * sx, 18f * sy, 75f * sx, 12f * sy, 66f * sx, 14f * sy)
        path.cubicTo(63f * sx, 13f * sy, 62f * sx, 5f * sy, 60f * sx, 2f * sy)
        path.cubicTo(58f * sx, 4f * sy, 53f * sx, 12f * sy, 50f * sx, 15f * sy)
        path.close()
        drawPath(path, color)
    }
}