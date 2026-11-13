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
      version: versionEsquema,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Versión del esquema. Al agregar una tabla nueva: subir este número,
  /// crearla en [_createDB] (bases nuevas) y en [_upgradeDB] (bases que ya
  /// existen en el computador de cada integrante).
  ///
  /// Historial:
  /// - 1: donaciones y peticiones.
  /// - 2: donante (US01, T01).
  static const int versionEsquema = 3;

  /// Abre una base de datos solo para pruebas, con el esquema completo.
  /// Por defecto es en memoria; con [ruta] se puede usar un archivo
  /// temporal (por ejemplo, para probar la migración desde la versión 1).
  static Future<Database> abrirParaPruebas([String ruta = ':memory:']) {
    sqfliteFfiInit();
    return databaseFactoryFfi.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: versionEsquema,
        singleInstance: false,
        onCreate: instance._createDB,
        onUpgrade: instance._upgradeDB,
      ),
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await crearTablaDonante(db);
    }
  }

  /// T01 · Tabla del donante (US01, RF-08 y RF-09).
  static Future<void> crearTablaDonante(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS donante (
        rut                 TEXT    PRIMARY KEY,
        nombre              TEXT    NOT NULL CHECK (length(trim(nombre)) > 0),
        fecha_nacimiento    TEXT    NOT NULL,
        peso_kg             REAL    NOT NULL CHECK (peso_kg > 0),
        tipo_sangre         TEXT    NOT NULL
          CHECK (tipo_sangre IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
        telefono            TEXT    NOT NULL,
        estado_elegibilidad TEXT    NOT NULL DEFAULT 'sinEvaluar'
          CHECK (estado_elegibilidad IN ('sinEvaluar','apto','diferido','rechazado')),
        fecha_diferido      TEXT,
        version             INTEGER NOT NULL DEFAULT 1,
        -- Un donante diferido siempre tiene fecha, y solo él la tiene.
        CHECK ((estado_elegibilidad = 'diferido') = (fecha_diferido IS NOT NULL))
      )
    ''');
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE donaciones (
        id TEXT PRIMARY KEY,
        rut TEXT NOT NULL,
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

    await crearTablaDonante(db);
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