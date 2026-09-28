import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/prueba_bolt.dart';
import '../models/sesion.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'respiracion_vascular.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sesiones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fecha TEXT NOT NULL,
            tecnica_id TEXT NOT NULL,
            duracion_segundos INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE pruebas_bolt (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fecha TEXT NOT NULL,
            segundos INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> guardarSesion(Sesion s) async {
    final db = await database;
    return db.insert('sesiones', s.toMap()..remove('id'));
  }

  Future<List<Sesion>> listarSesiones() async {
    final db = await database;
    final rows = await db.query('sesiones', orderBy: 'fecha DESC');
    return rows.map((r) => Sesion.fromMap(r)).toList();
  }

  Future<int> guardarPruebaBolt(PruebaBolt p) async {
    final db = await database;
    return db.insert('pruebas_bolt', p.toMap()..remove('id'));
  }

  Future<List<PruebaBolt>> listarPruebasBolt() async {
    final db = await database;
    final rows = await db.query('pruebas_bolt', orderBy: 'fecha DESC');
    return rows.map((r) => PruebaBolt.fromMap(r)).toList();
  }
}
