// T01 · Verificación del modelo y esquema del donante.
// Ejecutar con: flutter test test/t01_esquema_donante_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ing_software/models/donante.dart';
import 'package:ing_software/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/datos_prueba.dart';

void main() {
  late Database db;

  setUp(() async {
    db = await DatabaseHelper.abrirParaPruebas();
  });

  tearDown(() async => db.close());

  test(
    'esqueleto: guarda un donante y lo lee de vuelta sin perder datos',
    () async {
      final original = donanteDePrueba();
      await db.insert('donante', original.toMap());

      final filas = await db.query('donante');
      expect(filas, hasLength(1));

      final leido = Donante.fromMap(filas.single);
      expect(leido.rut, original.rut);
      expect(leido.nombre, original.nombre);
      expect(leido.fechaNacimiento, original.fechaNacimiento);
      expect(leido.pesoKg, original.pesoKg);
      expect(leido.tipoSangre, TipoSangre.oNeg);
      expect(leido.telefono, original.telefono);
      expect(leido.estado, EstadoElegibilidad.sinEvaluar);
      expect(leido.fechaDiferido, isNull);
      expect(leido.version, 1);
    },
  );

  test('el mismo RUT no puede quedar registrado dos veces (RF-08)', () async {
    await db.insert('donante', donanteDePrueba().toMap());
    expect(
      () => db.insert('donante', donanteDePrueba().toMap()),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('rechaza un tipo de sangre fuera de los ocho válidos', () async {
    final fila = donanteDePrueba().toMap()..['tipo_sangre'] = 'Z+';
    expect(() => db.insert('donante', fila), throwsA(isA<DatabaseException>()));
  });

  test('un donante diferido debe tener fecha de habilitación', () async {
    final fila = donanteDePrueba().toMap()
      ..['estado_elegibilidad'] = 'diferido'
      ..['fecha_diferido'] = null;
    expect(() => db.insert('donante', fila), throwsA(isA<DatabaseException>()));
  });

  test('un donante apto no puede tener fecha de diferido', () async {
    final fila = donanteDePrueba().toMap()
      ..['estado_elegibilidad'] = 'apto'
      ..['fecha_diferido'] = '2026-12-01';
    expect(() => db.insert('donante', fila), throwsA(isA<DatabaseException>()));
  });

  test('los ocho tipos de sangre se convierten ida y vuelta', () {
    for (final tipo in TipoSangre.values) {
      expect(TipoSangre.desdeEtiqueta(tipo.etiqueta), tipo);
    }
    expect(() => TipoSangre.desdeEtiqueta('C+'), throwsArgumentError);
  });

  test('la base única incluye donante, donaciones y peticiones', () async {
    final tablas = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: "type = 'table'",
    );
    final nombres = tablas.map((t) => t['name']).toSet();
    expect(nombres, containsAll(['donante', 'donaciones', 'peticiones']));
  });

  test('una base existente en versión 1 se migra y agrega donante', () async {
    final dir = await Directory.systemTemp.createTemp('bd_migracion_');
    final ruta = '${dir.path}${Platform.pathSeparator}banco_sangre.db';
    try {
      // Simula la base que ya tiene cada integrante (versión 1).
      final v1 = await databaseFactoryFfi.openDatabase(
        ruta,
        options: OpenDatabaseOptions(
          version: 1,
          singleInstance: false,
          onCreate: (db, _) => db.execute(
            'CREATE TABLE peticiones (id TEXT PRIMARY KEY, estado TEXT)',
          ),
        ),
      );
      await v1.insert('peticiones', {'id': 'PET-001', 'estado': 'pendiente'});
      await v1.close();

      final v2 = await DatabaseHelper.abrirParaPruebas(ruta);
      expect(await v2.getVersion(), DatabaseHelper.versionEsquema);
      await v2.insert('donante', donanteDePrueba().toMap());
      expect(await v2.query('donante'), hasLength(1));
      // La migración no borra los datos que ya existían.
      expect(await v2.query('peticiones'), hasLength(1));
      await v2.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
