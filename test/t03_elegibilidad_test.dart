// T03 · Verificación de la regla de elegibilidad vigente.
// Escenarios E4 a E6 de US01 y casos límite. Ejecutar con:
//   flutter test test/t03_elegibilidad_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ing_software/models/donante.dart';
import 'package:ing_software/services/database_helper.dart';
import 'package:ing_software/services/donantes_service.dart';
import 'package:ing_software/services/elegibilidad.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/datos_prueba.dart';

void main() {
  final hoy = DateTime(2026, 11, 12);
  final apto = donanteDePrueba().copyWith(estado: EstadoElegibilidad.apto);

  group('evaluarElegibilidad (regla pura)', () {
    test('apto y sin donaciones previas: puede donar', () {
      final r = evaluarElegibilidad(donante: apto, hoy: hoy);
      expect(r.apto, isTrue);
      expect(r.habilitadoDesde, isNull);
    });

    test('sin evaluación registrada: no puede donar', () {
      final r = evaluarElegibilidad(donante: donanteDePrueba(), hoy: hoy);
      expect(r.apto, isFalse);
    });

    test('E4: diferido con fecha futura no puede donar e informa la fecha', () {
      final diferido = donanteDePrueba().copyWith(
        estado: EstadoElegibilidad.diferido,
        fechaDiferido: DateTime(2026, 12, 1),
      );
      final r = evaluarElegibilidad(donante: diferido, hoy: hoy);
      expect(r.apto, isFalse);
      expect(r.habilitadoDesde, DateTime.utc(2026, 12, 1));
      expect(r.motivo, contains('2026-12-01'));
    });

    test('E4 límite: diferido puede donar justo el día de su fecha', () {
      final diferido = donanteDePrueba().copyWith(
        estado: EstadoElegibilidad.diferido,
        fechaDiferido: hoy,
      );
      expect(evaluarElegibilidad(donante: diferido, hoy: hoy).apto, isTrue);
    });

    test('E5: rechazado permanentemente nunca puede donar', () {
      final rechazado = donanteDePrueba().copyWith(
        estado: EstadoElegibilidad.rechazado,
      );
      final r = evaluarElegibilidad(donante: rechazado, hoy: hoy);
      expect(r.apto, isFalse);
      expect(r.habilitadoDesde, isNull);
    });

    test('E6: apto con donación reciente no puede donar todavía', () {
      final r = evaluarElegibilidad(
        donante: apto,
        hoy: hoy,
        ultimaDonacion: DateTime(2026, 10, 1),
        diasMinimosEntreDonaciones: 90,
      );
      expect(r.apto, isFalse);
      expect(r.habilitadoDesde, DateTime.utc(2026, 12, 30));
    });

    test('E6 límite: puede donar justo al cumplir el intervalo', () {
      final ultima = DateTime(2026, 8, 14); // + 90 días = 2026-11-12
      expect(
        evaluarElegibilidad(
          donante: apto,
          hoy: hoy,
          ultimaDonacion: ultima,
          diasMinimosEntreDonaciones: 90,
        ).apto,
        isTrue,
      );
      expect(
        evaluarElegibilidad(
          donante: apto,
          hoy: hoy.subtract(const Duration(days: 1)),
          ultimaDonacion: ultima,
          diasMinimosEntreDonaciones: 90,
        ).apto,
        isFalse,
      );
    });

    test('diferido vencido pero con donación reciente: manda el intervalo', () {
      final diferido = donanteDePrueba().copyWith(
        estado: EstadoElegibilidad.diferido,
        fechaDiferido: DateTime(2026, 11, 1),
      );
      final r = evaluarElegibilidad(
        donante: diferido,
        hoy: hoy,
        ultimaDonacion: DateTime(2026, 10, 1),
        diasMinimosEntreDonaciones: 90,
      );
      expect(r.apto, isFalse);
      expect(r.habilitadoDesde, DateTime.utc(2026, 12, 30));
    });

    test('la hora del día no cambia el resultado', () {
      final r = evaluarElegibilidad(
        donante: apto,
        hoy: DateTime(2026, 11, 12, 23, 59),
        ultimaDonacion: DateTime(2026, 8, 14, 0, 1),
        diasMinimosEntreDonaciones: 90,
      );
      expect(r.apto, isTrue);
    });
  });

  group('DonantesService · registrar y consultar elegibilidad', () {
    late Database db;
    late DonantesService servicio;

    setUp(() async {
      db = await DatabaseHelper.abrirParaPruebas();
      servicio = DonantesService(db);
      await servicio.registrarDonante(donanteDePrueba(), hoy: hoy);
    });

    tearDown(() async => db.close());

    test('registra apto y aumenta la versión del registro', () async {
      final d = await servicio.registrarElegibilidad(
        '12.345.678-5',
        EstadoElegibilidad.apto,
        hoy: hoy,
      );
      expect(d.estado, EstadoElegibilidad.apto);
      expect(d.fechaDiferido, isNull);
      expect(d.version, 2);
      expect(
        (await servicio.consultarElegibilidad('12345678-5', hoy: hoy)).apto,
        isTrue,
      );
    });

    test('registra diferido con fecha y la consulta lo informa', () async {
      await servicio.registrarElegibilidad(
        '12345678-5',
        EstadoElegibilidad.diferido,
        fechaDiferido: DateTime(2026, 12, 1),
        hoy: hoy,
      );
      final r = await servicio.consultarElegibilidad('12345678-5', hoy: hoy);
      expect(r.apto, isFalse);
      expect(r.habilitadoDesde, DateTime.utc(2026, 12, 1));
    });

    test('diferido sin fecha o con fecha pasada se rechaza', () async {
      await expectLater(
        servicio.registrarElegibilidad(
          '12345678-5',
          EstadoElegibilidad.diferido,
          hoy: hoy,
        ),
        throwsA(isA<DatosDonanteInvalidosException>()),
      );
      await expectLater(
        servicio.registrarElegibilidad(
          '12345678-5',
          EstadoElegibilidad.diferido,
          fechaDiferido: DateTime(2026, 11, 1),
          hoy: hoy,
        ),
        throwsA(isA<DatosDonanteInvalidosException>()),
      );
    });

    test('pasar de diferido a rechazado borra la fecha', () async {
      await servicio.registrarElegibilidad(
        '12345678-5',
        EstadoElegibilidad.diferido,
        fechaDiferido: DateTime(2026, 12, 1),
        hoy: hoy,
      );
      final d = await servicio.registrarElegibilidad(
        '12345678-5',
        EstadoElegibilidad.rechazado,
        fechaDiferido: DateTime(2027, 1, 1),
        hoy: hoy,
      );
      expect(d.estado, EstadoElegibilidad.rechazado);
      expect(d.fechaDiferido, isNull);
    });

    test('no se puede volver a "sin evaluar"', () async {
      await expectLater(
        servicio.registrarElegibilidad(
          '12345678-5',
          EstadoElegibilidad.sinEvaluar,
          hoy: hoy,
        ),
        throwsA(isA<DatosDonanteInvalidosException>()),
      );
    });

    test('donante no registrado lanza DonanteNoEncontradoException', () async {
      await expectLater(
        servicio.registrarElegibilidad(
          '7654321-6',
          EstadoElegibilidad.apto,
          hoy: hoy,
        ),
        throwsA(isA<DonanteNoEncontradoException>()),
      );
      await expectLater(
        servicio.consultarElegibilidad('7654321-6', hoy: hoy),
        throwsA(isA<DonanteNoEncontradoException>()),
      );
    });
  });
}
