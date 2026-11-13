// T02 · Verificación de registro y consulta de donantes.
// Escenarios E1 a E3 de US01. Ejecutar con:
//   flutter test test/t02_registro_donantes_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ing_software/models/donante.dart';
import 'package:ing_software/services/database_helper.dart';
import 'package:ing_software/services/donantes_service.dart';
import 'package:ing_software/utils/rut.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/datos_prueba.dart';

void main() {
  group('Rut', () {
    test('acepta RUT válidos con y sin puntos o guion', () {
      expect(Rut.esValido('12.345.678-5'), isTrue);
      expect(Rut.esValido('12345678-5'), isTrue);
      expect(Rut.esValido('123456785'), isTrue);
      expect(Rut.esValido('7.654.321-6'), isTrue);
      expect(Rut.esValido('10.000.013-k'), isTrue); // DV K, en minúscula
      expect(Rut.esValido('10.000.004-0'), isTrue); // DV 0
    });

    test('rechaza dígito verificador incorrecto o formato inválido', () {
      expect(Rut.esValido('12.345.678-9'), isFalse);
      expect(Rut.esValido('12345678'), isFalse);
      expect(Rut.esValido('abc'), isFalse);
      expect(Rut.esValido(''), isFalse);
    });

    test('normaliza a cuerpo-DV', () {
      expect(Rut.normalizar('12.345.678-5'), '12345678-5');
      expect(Rut.normalizar('10000013k'), '10000013-K');
    });
  });

  group('DonantesService', () {
    late Database db;
    late DonantesService servicio;
    final hoy = DateTime(2026, 11, 12);

    setUp(() async {
      db = await DatabaseHelper.abrirParaPruebas();
      servicio = DonantesService(db);
    });

    tearDown(() async => db.close());

    test(
      'E1: registra un donante válido y se puede consultar por RUT',
      () async {
        final guardado = await servicio.registrarDonante(
          donanteDePrueba(rut: '12.345.678-5'),
          hoy: hoy,
        );
        expect(guardado.rut, '12345678-5');
        expect(guardado.estado, EstadoElegibilidad.sinEvaluar);

        final consultado = await servicio.obtenerPorRut('12345678-5');
        expect(consultado, isNotNull);
        expect(consultado!.nombre, 'Ana Rojas');
        expect(consultado.tipoSangre, TipoSangre.oNeg);
      },
    );

    test('E2: no permite registrar dos veces el mismo RUT', () async {
      await servicio.registrarDonante(
        donanteDePrueba(rut: '12345678-5'),
        hoy: hoy,
      );
      // El mismo RUT escrito de otra forma también se detecta.
      await expectLater(
        servicio.registrarDonante(
          donanteDePrueba(rut: '12.345.678-5'),
          hoy: hoy,
        ),
        throwsA(isA<DonanteDuplicadoException>()),
      );
      expect(await servicio.listarDonantes(), hasLength(1));
    });

    test('E3: rechaza un RUT con dígito verificador inválido', () async {
      await expectLater(
        servicio.registrarDonante(
          donanteDePrueba(rut: '12.345.678-9'),
          hoy: hoy,
        ),
        throwsA(isA<RutInvalidoException>()),
      );
      expect(await servicio.listarDonantes(), isEmpty);
    });

    test('marca los campos obligatorios vacíos o inválidos', () async {
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

    test('consultar un RUT no registrado devuelve null', () async {
      expect(await servicio.obtenerPorRut('7.654.321-6'), isNull);
    });

    test('consultar con un RUT inválido lanza RutInvalidoException', () async {
      await expectLater(
        servicio.obtenerPorRut('1-1'),
        throwsA(isA<RutInvalidoException>()),
      );
    });

    test('lista los donantes ordenados por nombre', () async {
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
}
