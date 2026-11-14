import 'package:flutter_test/flutter_test.dart';
import 'package:ing_software/models/donante.dart';
import 'package:ing_software/services/database_helper.dart';
import 'package:ing_software/services/donantes_service.dart';
import 'package:ing_software/services/elegibilidad.dart';
import 'package:ing_software/utils/rut.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/datos_prueba.dart';

void main() {
  final hoy = DateTime(2026, 11, 12);

  group('Rut validation', () {
    test('accepts valid RUTs with and without formatting', () {
      expect(Rut.esValido('12.345.678-5'), isTrue);
      expect(Rut.esValido('12345678-5'), isTrue);
      expect(Rut.esValido('123456785'), isTrue);
      expect(Rut.esValido('7.654.321-6'), isTrue);
      expect(Rut.esValido('10.000.013-k'), isTrue);
      expect(Rut.esValido('10.000.004-0'), isTrue);
    });

    test('rejects invalid RUT format or DV', () {
      expect(Rut.esValido('12.345.678-9'), isFalse);
      expect(Rut.esValido('12345678'), isFalse);
      expect(Rut.esValido('abc'), isFalse);
      expect(Rut.esValido(''), isFalse);
    });

    test('normalizes formatted RUT to body-DV format', () {
      expect(Rut.normalizar('12.345.678-5'), '12345678-5');
      expect(Rut.normalizar('10000013k'), '10000013-K');
    });
  });

  group('DonantesService · registro', () {
    late Database db;
    late DonantesService servicio;

    setUp(() async {
      db = await DatabaseHelper.abrirParaPruebas();
      servicio = DonantesService(db);
    });

    tearDown(() async => db.close());

    test('registers a valid donor and retrieves by RUT', () async {
      final guardado = await servicio.registrarDonante(
        donanteDePrueba(rut: '12.345.678-5'),
        hoy: hoy,
      );

      expect(guardado.rut, '12345678-5');
      expect(guardado.estado, EstadoElegibilidad.sinEvaluar);
      expect(guardado.version, 1);

      final consultado = await servicio.obtenerPorRut('12345678-5');
      expect(consultado, isNotNull);
      expect(consultado!.nombre, 'Ana Rojas');
      expect(consultado.tipoSangre, TipoSangre.oNeg);
    });

    test('rejects duplicate RUTs regardless of formatting', () async {
      await servicio.registrarDonante(
        donanteDePrueba(rut: '12345678-5'),
        hoy: hoy,
      );

      await expectLater(
        servicio.registrarDonante(
          donanteDePrueba(rut: '12.345.678-5'),
          hoy: hoy,
        ),
        throwsA(isA<DonanteDuplicadoException>()),
      );

      expect(await servicio.listarDonantes(), hasLength(1));
    });

    test('rejects an invalid RUT', () async {
      await expectLater(
        servicio.registrarDonante(
          donanteDePrueba(rut: '12.345.678-9'),
          hoy: hoy,
        ),
        throwsA(isA<RutInvalidoException>()),
      );

      expect(await servicio.listarDonantes(), isEmpty);
    });

    test('validates required donor fields', () async {
      final invalido = donanteDePrueba().copyWith(
        nombre: '   ',
        telefono: '',
        pesoKg: 0,
        fechaNacimiento: DateTime(2030, 1, 1),
      );

      try {
        await servicio.registrarDonante(invalido, hoy: hoy);
        fail('Debió lanzar DatosDonanteInvalidosException');
      } on DatosDonanteInvalidosException catch (e) {
        expect(
          e.errores.keys,
          containsAll(['nombre', 'telefono', 'pesoKg', 'fechaNacimiento']),
        );
      }

      expect(await servicio.listarDonantes(), isEmpty);
    });

    test('returns null when querying a non-registered RUT', () async {
      expect(await servicio.obtenerPorRut('7.654.321-6'), isNull);
    });

    test('throws for an invalid RUT lookup', () async {
      await expectLater(
        servicio.obtenerPorRut('1-1'),
        throwsA(isA<RutInvalidoException>()),
      );
    });

    test('lists donors sorted by name', () async {
      await servicio.registrarDonante(
        donanteDePrueba(rut: '12345678-5').copyWith(nombre: 'Pedro Soto'),
        hoy: hoy,
      );
      await servicio.registrarDonante(
        donanteDePrueba(rut: '7654321-6').copyWith(nombre: 'ana López'),
        hoy: hoy,
      );

      final nombres = (await servicio.listarDonantes())
      .map((d) => d.nombre)
      .toList();

      expect(nombres, ['ana López', 'Pedro Soto']);
    });
  });

  group('DonantesService · elegibilidad', () {
    late Database db;
    late DonantesService servicio;

    setUp(() async {
      db = await DatabaseHelper.abrirParaPruebas();
      servicio = DonantesService(db);
      await servicio.registrarDonante(donanteDePrueba(), hoy: hoy);
    });

    tearDown(() async => db.close());

    group('evaluarElegibilidad (regla pura)', () {
      final apto = donanteDePrueba().copyWith(estado: EstadoElegibilidad.apto);

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
        expect(
          evaluarElegibilidad(donante: diferido, hoy: hoy).apto,
          isTrue,
        );
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
        final ultima = DateTime(2026, 8, 14);

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

    test('no se puede volver a sin evaluar', () async {
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
