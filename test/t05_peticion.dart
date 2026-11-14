// T04 · Verificación del modelo y persistencia de peticiones.
// Ejecutar con: flutter test test/t04_peticiones_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ing_software/models/peticion_model.dart';
import 'package:ing_software/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('Peticion', () {
    test('usa pendiente como estado inicial', () {
      final peticion = Peticion(
        id: 'PET-001',
        centroSolicitante: 'Hospital Regional Concepción',
        tipoSangre: 'O+',
        cantidad: 2,
      );

      expect(peticion.estado, 'pendiente');
    });

    test('convierte los campos a JSON y reconstruye la petición', () {
      final original = Peticion(
        id: 'PET-002',
        centroSolicitante: 'Hospital Las Higueras',
        tipoSangre: 'AB-',
        cantidad: 3,
        estado: 'cerrada',
      );

      final reconstruida = Peticion.fromJson(original.toJson());

      expect(reconstruida.id, original.id);
      expect(reconstruida.centroSolicitante, original.centroSolicitante);
      expect(reconstruida.tipoSangre, original.tipoSangre);
      expect(reconstruida.cantidad, original.cantidad);
      expect(reconstruida.estado, original.estado);
    });
  });

  group('Peticiones · persistencia SQLite', () {
    late Database db;

    setUp(() async {
      db = await DatabaseHelper.abrirParaPruebas();
    });

    tearDown(() async => db.close());

    test('guarda y recupera una petición sin perder datos', () async {
      final original = Peticion(
        id: 'PET-001',
        centroSolicitante: 'Hospital Regional Concepción',
        tipoSangre: 'O+',
        cantidad: 2,
      );

      await db.insert('peticiones', original.toJson());
      final filas = await db.query('peticiones');
      final recuperada = Peticion.fromJson(filas.single);

      expect(recuperada.id, original.id);
      expect(recuperada.centroSolicitante, original.centroSolicitante);
      expect(recuperada.tipoSangre, original.tipoSangre);
      expect(recuperada.cantidad, original.cantidad);
      expect(recuperada.estado, 'pendiente');
    });

    test('permite cerrar una petición existente', () async {
      final peticion = Peticion(
        id: 'PET-001',
        centroSolicitante: 'Hospital Regional Concepción',
        tipoSangre: 'A-',
        cantidad: 1,
      );
      await db.insert('peticiones', peticion.toJson());

      final filasActualizadas = await db.update(
        'peticiones',
        {'estado': 'cerrada'},
        where: 'id = ?',
        whereArgs: [peticion.id],
      );
      final fila = (await db.query(
        'peticiones',
        where: 'id = ?',
        whereArgs: [peticion.id],
      )).single;

      expect(filasActualizadas, 1);
      expect(Peticion.fromJson(fila).estado, 'cerrada');
    });

    test('rechaza una petición sin campos obligatorios', () async {
      await expectLater(
        db.insert('peticiones', {'id': 'PET-001'}),
        throwsA(isA<DatabaseException>()),
      );
      expect(await db.query('peticiones'), isEmpty);
    });
  });
}
