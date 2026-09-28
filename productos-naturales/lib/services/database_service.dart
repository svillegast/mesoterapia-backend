import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/disease_query_result.dart';
import '../models/natural_product.dart';
import '../models/study.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'productos_naturales.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE consultas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            query TEXT NOT NULL,
            query_type TEXT NOT NULL,
            organ_affected TEXT,
            disease_explanation TEXT,
            created_at TEXT NOT NULL,
            UNIQUE(query, query_type)
          )
        ''');
        await db.execute('''
          CREATE TABLE productos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            consulta_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            effect_summary TEXT,
            star_rating REAL NOT NULL,
            evidence_level TEXT,
            FOREIGN KEY(consulta_id) REFERENCES consultas(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE estudios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            producto_id INTEGER NOT NULL,
            source TEXT,
            external_id TEXT,
            title TEXT,
            year INTEGER,
            study_type TEXT,
            sample_size INTEGER,
            url TEXT,
            FOREIGN KEY(producto_id) REFERENCES productos(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  Future<DiseaseQueryResult?> buscarEnCache(String query, String queryType) async {
    final db = await database;
    final normalizada = query.trim().toLowerCase();

    final consultas = await db.query(
      'consultas',
      where: 'LOWER(query) = ? AND query_type = ?',
      whereArgs: [normalizada, queryType],
    );

    if (consultas.isEmpty) return null;

    final consulta = consultas.first;
    final consultaId = consulta['id'] as int;

    final productosRows = await db.query(
      'productos',
      where: 'consulta_id = ?',
      whereArgs: [consultaId],
      orderBy: 'star_rating DESC',
    );

    final productos = <NaturalProduct>[];
    for (final p in productosRows) {
      final productoId = p['id'] as int;
      final estudiosRows = await db.query(
        'estudios',
        where: 'producto_id = ?',
        whereArgs: [productoId],
      );

      final estudios = estudiosRows
          .map((e) => Study(
                source: e['source'] as String? ?? '',
                externalId: e['external_id'] as String? ?? '',
                title: e['title'] as String? ?? '',
                year: e['year'] as int?,
                studyType: e['study_type'] as String? ?? 'other',
                sampleSize: e['sample_size'] as int?,
                url: e['url'] as String? ?? '',
              ))
          .toList();

      productos.add(NaturalProduct(
        id: productoId,
        name: p['name'] as String? ?? '',
        effectSummary: p['effect_summary'] as String? ?? '',
        starRating: (p['star_rating'] as num).toDouble(),
        evidenceLevel: p['evidence_level'] as String? ?? '',
        studies: estudios,
      ));
    }

    return DiseaseQueryResult(
      id: consultaId,
      query: consulta['query'] as String,
      queryType: consulta['query_type'] as String,
      organAffected: consulta['organ_affected'] as String? ?? '',
      diseaseExplanation: consulta['disease_explanation'] as String? ?? '',
      products: productos,
      createdAt: DateTime.tryParse(consulta['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Future<void> guardar(DiseaseQueryResult resultado) async {
    final db = await database;

    await db.insert(
      'consultas',
      {
        'query': resultado.query,
        'query_type': resultado.queryType,
        'organ_affected': resultado.organAffected,
        'disease_explanation': resultado.diseaseExplanation,
        'created_at': resultado.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final consultaRows = await db.query(
      'consultas',
      where: 'LOWER(query) = ? AND query_type = ?',
      whereArgs: [resultado.query.trim().toLowerCase(), resultado.queryType],
    );
    final consultaId = consultaRows.first['id'] as int;

    await db.delete('productos', where: 'consulta_id = ?', whereArgs: [consultaId]);

    for (final producto in resultado.products) {
      final productoId = await db.insert('productos', {
        'consulta_id': consultaId,
        'name': producto.name,
        'effect_summary': producto.effectSummary,
        'star_rating': producto.starRating,
        'evidence_level': producto.evidenceLevel,
      });

      for (final estudio in producto.studies) {
        await db.insert('estudios', {
          'producto_id': productoId,
          ...estudio.toMap(),
        });
      }
    }
  }
}
