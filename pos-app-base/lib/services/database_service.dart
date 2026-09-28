import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/cliente.dart';
import '../models/gasto.dart';
import '../models/producto.dart';
import '../models/venta.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'pos_app.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE productos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            precio_unidad REAL NOT NULL,
            precio_mayorista REAL,
            cantidad_minima_mayorista INTEGER,
            stock INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE clientes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            telefono TEXT,
            direccion TEXT,
            notas TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE ventas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fecha TEXT NOT NULL,
            cliente_id INTEGER,
            cliente_nombre TEXT,
            monto_libre REAL NOT NULL DEFAULT 0,
            monto_pagado REAL NOT NULL,
            total REAL NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE venta_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            venta_id INTEGER NOT NULL,
            producto_id INTEGER,
            nombre_producto TEXT NOT NULL,
            cantidad INTEGER NOT NULL,
            precio_unitario_aplicado REAL NOT NULL,
            FOREIGN KEY(venta_id) REFERENCES ventas(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE gastos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fecha TEXT NOT NULL,
            categoria TEXT NOT NULL,
            monto REAL NOT NULL,
            descripcion TEXT
          )
        ''');
      },
    );
  }

  // Productos
  Future<int> guardarProducto(Producto p) async {
    final db = await database;
    if (p.id == null) {
      return db.insert('productos', p.toMap()..remove('id'));
    }
    await db.update('productos', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
    return p.id!;
  }

  Future<List<Producto>> listarProductos() async {
    final db = await database;
    final rows = await db.query('productos', orderBy: 'nombre ASC');
    return rows.map((r) => Producto.fromMap(r)).toList();
  }

  Future<void> ajustarStock(int productoId, int delta) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE productos SET stock = stock + ? WHERE id = ?',
      [delta, productoId],
    );
  }

  // Clientes
  Future<int> guardarCliente(Cliente c) async {
    final db = await database;
    if (c.id == null) {
      return db.insert('clientes', c.toMap()..remove('id'));
    }
    await db.update('clientes', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
    return c.id!;
  }

  Future<List<Cliente>> listarClientes() async {
    final db = await database;
    final rows = await db.query('clientes', orderBy: 'nombre ASC');
    return rows.map((r) => Cliente.fromMap(r)).toList();
  }

  // Ventas
  Future<int> guardarVenta(Venta v) async {
    final db = await database;
    return db.transaction((txn) async {
      final ventaId = await txn.insert('ventas', v.toMap()..remove('id'));
      for (final item in v.items) {
        await txn.insert('venta_items', item.toMap(ventaId));
        if (item.productoId != null) {
          await txn.rawUpdate(
            'UPDATE productos SET stock = stock - ? WHERE id = ?',
            [item.cantidad, item.productoId],
          );
        }
      }
      return ventaId;
    });
  }

  Future<List<Venta>> listarVentas({DateTime? desde, DateTime? hasta}) async {
    final db = await database;
    String? where;
    List<Object?>? args;
    if (desde != null && hasta != null) {
      where = 'fecha >= ? AND fecha <= ?';
      args = [desde.toIso8601String(), hasta.toIso8601String()];
    }
    final rows = await db.query('ventas', where: where, whereArgs: args, orderBy: 'fecha DESC');
    final ventas = <Venta>[];
    for (final r in rows) {
      final itemRows = await db.query('venta_items', where: 'venta_id = ?', whereArgs: [r['id']]);
      final items = itemRows.map((i) => ItemVenta.fromMap(i)).toList();
      ventas.add(Venta.fromMap(r, items));
    }
    return ventas;
  }

  // Gastos
  Future<int> guardarGasto(Gasto g) async {
    final db = await database;
    return db.insert('gastos', g.toMap()..remove('id'));
  }

  Future<List<Gasto>> listarGastos({DateTime? desde, DateTime? hasta}) async {
    final db = await database;
    String? where;
    List<Object?>? args;
    if (desde != null && hasta != null) {
      where = 'fecha >= ? AND fecha <= ?';
      args = [desde.toIso8601String(), hasta.toIso8601String()];
    }
    final rows = await db.query('gastos', where: where, whereArgs: args, orderBy: 'fecha DESC');
    return rows.map((r) => Gasto.fromMap(r)).toList();
  }

  /// Exporta toda la base a un mapa plano, listo para JSON — mismo formato
  /// (tablas + fecha_respaldo) que ya usa CobranzasVentasPro, para mantener
  /// consistencia entre apps del mismo negocio.
  Future<Map<String, dynamic>> exportarTodo() async {
    final db = await database;
    return {
      'version': '1.0',
      'fecha_respaldo': DateTime.now().toIso8601String(),
      'tablas': {
        'productos': await db.query('productos'),
        'clientes': await db.query('clientes'),
        'ventas': await db.query('ventas'),
        'venta_items': await db.query('venta_items'),
        'gastos': await db.query('gastos'),
      },
    };
  }
}
