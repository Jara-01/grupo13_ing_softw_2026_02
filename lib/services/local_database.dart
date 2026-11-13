import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/inventario_model.dart';
import '../models/peticion_model.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final directory = await getApplicationSupportDirectory();
    final dbPath = join(directory.path, 'banco_sangre.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE inventario (
      id TEXT PRIMARY KEY,
      tipo_sangre TEXT NOT NULL,
      unidades_disponibles INTEGER NOT NULL,
      centro_origen TEXT NOT NULL,
      fecha_llegada TEXT NOT NULL,
      fecha_vencimiento TEXT NOT NULL,
      volumen_ml INTEGER NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE peticiones (
      id TEXT PRIMARY KEY,
      centro_solicitante TEXT NOT NULL,
      tipo_sangre TEXT NOT NULL,
      cantidad INTEGER NOT NULL,
      estado TEXT NOT NULL
    )
    ''');
  }

  // INVENTARIO
  Future<int> insertInventario(InventarioItem item) async {
    final db = await database;
    return db.insert(
      'inventario',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<InventarioItem>> getInventario() async {
    final db = await database;
    final maps = await db.query('inventario', orderBy: 'id ASC');

    return List.generate(maps.length, (i) => InventarioItem.fromMap(maps[i]));
  }

  Future<int> deleteInventario(String id) async {
    final db = await database;
    return db.delete('inventario', where: 'id = ?', whereArgs: [id]);
  }

  // PETICIONES
  Future<int> insertPeticion(Peticion peticion) async {
    final db = await database;
    return db.insert(
      'peticiones',
      peticion.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Peticion>> getPeticiones() async {
    final db = await database;
    final maps = await db.query('peticiones', orderBy: 'id ASC');

    return List.generate(maps.length, (i) => Peticion.fromMap(maps[i]));
  }

  Future<int> updatePeticion(Peticion peticion) async {
    final db = await database;
    return db.update(
      'peticiones',
      peticion.toMap(),
      where: 'id = ?',
      whereArgs: [peticion.id],
    );
  }
}
