import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:ing_software/models/peticion_model.dart';
import 'package:ing_software/models/tipos_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('banco_sangre.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE donaciones (
        id TEXT PRIMARY KEY,
        tipoSangre TEXT NOT NULL,
        centroOrigen TEXT NOT NULL,
        fechaLlegada TEXT NOT NULL,
        fechaVencimiento TEXT NOT NULL,
        volumenMl INTEGER NOT NULL,
        estado TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE peticiones (
        id TEXT PRIMARY KEY,
        centroSolicitante TEXT NOT NULL,
        tipoSangre TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        estado TEXT NOT NULL
      )
    ''');
  }

  Future<ListaRegistros> obtenerDonacionesDisponibles() async {
    final db = await instance.database;
    final resultado = await db.query(
      'donaciones',
      where: "estado = ?",
      whereArgs: ['Disponible'],
      orderBy: 'fechaVencimiento ASC',
    );
    return resultado;
  }

  Future<List<Peticion>> obtenerPeticiones() async {
    final db = await instance.database;
    final result = await db.query('peticiones');
    return result.map((json) => Peticion.fromJson(json)).toList();
  }

  Future<int> crearPeticion(Peticion peticion) async {
    final db = await instance.database;
    return await db.insert('peticiones', peticion.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> cerrarPeticion(String id) async {
    final db = await instance.database;
    return await db.update(
      'peticiones',
      {'estado': 'cerrada'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}