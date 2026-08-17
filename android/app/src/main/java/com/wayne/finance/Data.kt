package com.wayne.finance

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

data class Usuario(
    val nombre: String,
    val passwordHash: String,
    val ultimoCheck: String,
    val fechaCreacion: String
)

data class Movimiento(
    val id: Long,
    val tipo: String,
    val categoria: String,
    val monto: Double,
    val descripcion: String,
    val fecha: String,
    val userId: String
) {
    val esIngreso: Boolean get() = tipo == "ingreso"
}

data class Presupuesto(
    val id: Long,
    val categoria: String,
    val limite: Double,
    val userId: String
)

data class Recurrente(
    val id: Long,
    val tipo: String,
    val categoria: String,
    val monto: Double,
    val descripcion: String,
    val dia: Int,
    val activo: Boolean,
    val userId: String
) {
    val esIngreso: Boolean get() = tipo == "ingreso"
}

data class Meta(
    val id: Long,
    val nombre: String,
    val objetivo: Double,
    val ahorrado: Double,
    val userId: String,
    val fechaCreacion: String
)

object Categorias {
    val ingreso = listOf("Salary", "Gifts", "Other")
    val gasto = listOf(
        "Housing", "Groceries", "Food", "Transportation", "Subscriptions",
        "Health", "Entertainment", "Clothing", "Education", "Utilities"
    )
    fun lista(para tipo: String): List<String> = if (tipo == "ingreso") ingreso else gasto
}

object Db {
    private const val NOMBRE = "finance.db"
    private const val VERSION = 1

    var helper: Helper? = null

    class Helper(context: Context) : SQLiteOpenHelper(context, NOMBRE, null, VERSION) {
        override fun onCreate(db: SQLiteDatabase) {
            db.execSQL(
                "CREATE TABLE usuarios (" +
                    "nombre TEXT PRIMARY KEY, " +
                    "passwordHash TEXT NOT NULL, " +
                    "ultimoCheck TEXT NOT NULL DEFAULT '', " +
                    "fechaCreacion TEXT NOT NULL)"
            )
            db.execSQL(
                "CREATE TABLE movimientos (" +
                    "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    "tipo TEXT NOT NULL, " +
                    "categoria TEXT NOT NULL, " +
                    "monto REAL NOT NULL, " +
                    "descripcion TEXT NOT NULL DEFAULT '', " +
                    "fecha TEXT NOT NULL, " +
                    "userId TEXT NOT NULL)"
            )
            db.execSQL(
                "CREATE TABLE presupuestos (" +
                    "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    "categoria TEXT NOT NULL, " +
                    "limite REAL NOT NULL, " +
                    "userId TEXT NOT NULL)"
            )
            db.execSQL(
                "CREATE TABLE recurrentes (" +
                    "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    "tipo TEXT NOT NULL, " +
                    "categoria TEXT NOT NULL, " +
                    "monto REAL NOT NULL, " +
                    "descripcion TEXT NOT NULL DEFAULT '', " +
                    "dia INTEGER NOT NULL, " +
                    "activo INTEGER NOT NULL DEFAULT 1, " +
                    "userId TEXT NOT NULL)"
            )
            db.execSQL(
                "CREATE TABLE metas (" +
                    "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    "nombre TEXT NOT NULL, " +
                    "objetivo REAL NOT NULL, " +
                    "ahorrado REAL NOT NULL DEFAULT 0, " +
                    "userId TEXT NOT NULL, " +
                    "fechaCreacion TEXT NOT NULL)"
            )
        }

        override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        }
    }

    @Synchronized
    private fun db(): SQLiteDatabase = helper!!.writableDatabase

    fun init(context: Context) {
        if (helper == null) helper = Helper(context.applicationContext)
    }

    fun usuarioPorNombre(nombre: String): Usuario? {
        val db = db()
        db.query("usuarios", null, "nombre = ?", arrayOf(nombre), null, null, null).use { c ->
            if (c.moveToFirst()) {
                return Usuario(
                    nombre = c.getString(0),
                    passwordHash = c.getString(1),
                    ultimoCheck = c.getString(2),
                    fechaCreacion = c.getString(3)
                )
            }
        }
        return null
    }

    fun insertarUsuario(nombre: String, passwordHash: String) {
        val v = ContentValues()
        v.put("nombre", nombre)
        v.put("passwordHash", passwordHash)
        v.put("ultimoCheck", "")
        v.put("fechaCreacion", hoyString())
        db().insertOrThrow("usuarios", null, v)
    }

    fun movimientos(userId: String): List<Movimiento> = rawMovimientos(
        "SELECT id, tipo, categoria, monto, descripcion, fecha, userId FROM movimientos WHERE userId = ?",
        arrayOf(userId)
    )

    fun todosLosMovimientos(): List<Movimiento> = rawMovimientos(
        "SELECT id, tipo, categoria, monto, descripcion, fecha, userId FROM movimientos",
        emptyArray()
    )

    private fun rawMovimientos(sql: String, args: Array<String>): List<Movimiento> {
        val lista = mutableListOf<Movimiento>()
        db().rawQuery(sql, args).use { c ->
            while (c.moveToNext()) {
                lista.add(
                    Movimiento(
                        id = c.getLong(0),
                        tipo = c.getString(1),
                        categoria = c.getString(2),
                        monto = c.getDouble(3),
                        descripcion = c.getString(4),
                        fecha = c.getString(5),
                        userId = c.getString(6)
                    )
                )
            }
        }
        return lista
    }

    fun insertarMovimiento(m: Movimiento) {
        val v = ContentValues()
        v.put("tipo", m.tipo)
        v.put("categoria", m.categoria)
        v.put("monto", m.monto)
        v.put("descripcion", m.descripcion)
        v.put("fecha", m.fecha)
        v.put("userId", m.userId)
        db().insert("movimientos", null, v)
    }

    fun actualizarMovimiento(m: Movimiento) {
        val v = ContentValues()
        v.put("tipo", m.tipo)
        v.put("categoria", m.categoria)
        v.put("monto", m.monto)
        v.put("descripcion", m.descripcion)
        v.put("fecha", m.fecha)
        db().update("movimientos", v, "id = ?", arrayOf(m.id.toString()))
    }

    fun eliminarMovimiento(id: Long) {
        db().delete("movimientos", "id = ?", arrayOf(id.toString()))
    }

    fun metas(userId: String): List<Meta> {
        val lista = mutableListOf<Meta>()
        db().query("metas", null, "userId = ?", arrayOf(userId), null, null, "fechaCreacion").use { c ->
            while (c.moveToNext()) {
                lista.add(
                    Meta(
                        id = c.getLong(0),
                        nombre = c.getString(1),
                        objetivo = c.getDouble(2),
                        ahorrado = c.getDouble(3),
                        userId = c.getString(4),
                        fechaCreacion = c.getString(5)
                    )
                )
            }
        }
        return lista
    }

    fun insertarMeta(nombre: String, objetivo: Double, userId: String) {
        val v = ContentValues()
        v.put("nombre", nombre)
        v.put("objetivo", objetivo)
        v.put("ahorrado", 0.0)
        v.put("userId", userId)
        v.put("fechaCreacion", hoyString())
        db().insert("metas", null, v)
    }

    fun eliminarMeta(id: Long) {
        db().delete("metas", "id = ?", arrayOf(id.toString()))
    }

    fun ajustarAhorro(id: Long, delta: Double) {
        val actual = db().quadruple("SELECT ahorrado FROM metas WHERE id = ?", arrayOf(id.toString())) ?: 0.0
        val nuevo = (actual + delta).coerceAtLeast(0.0)
        val v = ContentValues()
        v.put("ahorrado", nuevo)
        db().update("metas", v, "id = ?", arrayOf(id.toString()))
    }

    fun recurrentes(userId: String): List<Recurrente> {
        val lista = mutableListOf<Recurrente>()
        db().query("recurrentes", null, "userId = ?", arrayOf(userId), null, null, "dia, categoria").use { c ->
            while (c.moveToNext()) {
                lista.add(
                    Recurrente(
                        id = c.getLong(0),
                        tipo = c.getString(1),
                        categoria = c.getString(2),
                        monto = c.getDouble(3),
                        descripcion = c.getString(4),
                        dia = c.getInt(5),
                        activo = c.getInt(6) == 1,
                        userId = c.getString(7)
                    )
                )
            }
        }
        return lista
    }

    fun recurrentesActivosHoy(userId: String, diaHoy: Int): List<Recurrente> =
        recurrentes(userId).filter { it.activo && it.dia == diaHoy }

    fun insertarRecurrente(r: Recurrente) {
        val v = ContentValues()
        v.put("tipo", r.tipo)
        v.put("categoria", r.categoria)
        v.put("monto", r.monto)
        v.put("descripcion", r.descripcion)
        v.put("dia", r.dia)
        v.put("activo", 1)
        v.put("userId", r.userId)
        db().insert("recurrentes", null, v)
    }

    fun eliminarRecurrente(id: Long) {
        db().delete("recurrentes", "id = ?", arrayOf(id.toString()))
    }

    fun actualizarUltimoCheck(nombre: String, valor: String) {
        val v = ContentValues()
        v.put("ultimoCheck", valor)
        db().update("usuarios", v, "nombre = ?", arrayOf(nombre))
    }

    fun limpiarDatos(userId: String) {
        db().delete("movimientos", "userId = ?", arrayOf(userId))
        db().delete("presupuestos", "userId = ?", arrayOf(userId))
    }

    private fun SQLiteDatabase.quadruple(sql: String, args: Array<String>): Double? {
        rawQuery(sql, args).use { c ->
            if (c.moveToFirst()) return c.getDouble(0)
        }
        return null
    }
}