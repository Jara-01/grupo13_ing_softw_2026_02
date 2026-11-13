// T02 · Servicio para registrar y consultar donantes (US01, UC-01).
//
// Como la base de datos es SQLite local, los "endpoints" de la planificación
// son métodos de este servicio. Las pantallas (Flutter) lo usan directamente.

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/donante.dart';
import '../utils/rut.dart';

/// El RUT no tiene formato válido o su dígito verificador no corresponde.
class RutInvalidoException implements Exception {
  RutInvalidoException(this.rut);
  final String rut;

  @override
  String toString() => 'El RUT "$rut" no es válido.';
}

/// Ya existe un donante con ese RUT (RF-08, NRF-02).
class DonanteDuplicadoException implements Exception {
  DonanteDuplicadoException(this.rut);
  final String rut;

  @override
  String toString() => 'El donante con RUT $rut ya está registrado.';
}

/// Faltan datos obligatorios o son inválidos (UC-01, extensión 4').
class DatosDonanteInvalidosException implements Exception {
  DatosDonanteInvalidosException(this.errores);

  /// Un mensaje por campo con error, para marcarlo en el formulario.
  final Map<String, String> errores;

  @override
  String toString() => 'Datos del donante inválidos: $errores';
}

class DonantesService {
  DonantesService(this._db);

  final Database _db;

  static const String _tabla = 'donante';

  /// Registra un donante nuevo (UC-01, pasos 1 a 5).
  ///
  /// Devuelve el donante tal como quedó guardado (con el RUT normalizado).
  /// Lanza [RutInvalidoException], [DatosDonanteInvalidosException] o
  /// [DonanteDuplicadoException].
  Future<Donante> registrarDonante(Donante donante, {DateTime? hoy}) async {
    final rut = _rutNormalizado(donante.rut);

    final errores = validarDatos(donante, hoy: hoy ?? DateTime.now());
    if (errores.isNotEmpty) throw DatosDonanteInvalidosException(errores);

    final nuevo = donante.copyWith(
      rut: rut,
      nombre: donante.nombre.trim(),
      telefono: donante.telefono.trim(),
      estado: EstadoElegibilidad.sinEvaluar,
      borrarFechaDiferido: true,
      version: 1,
    );

    try {
      await _db.insert(
        _tabla,
        nuevo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw DonanteDuplicadoException(rut);
      rethrow;
    }
    return nuevo;
  }

  /// Busca un donante por RUT. Devuelve `null` si no está registrado.
  Future<Donante?> obtenerPorRut(String rut) async {
    final filas = await _db.query(
      _tabla,
      where: 'rut = ?',
      whereArgs: [_rutNormalizado(rut)],
      limit: 1,
    );
    return filas.isEmpty ? null : Donante.fromMap(filas.first);
  }

  /// Lista todos los donantes, ordenados por nombre.
  Future<List<Donante>> listarDonantes() async {
    final filas = await _db.query(_tabla, orderBy: 'nombre COLLATE NOCASE');
    return filas.map(Donante.fromMap).toList();
  }

  /// Valida los datos mínimos de RF-08. Devuelve un mapa campo → mensaje,
  /// vacío si todo está correcto.
  ///
  /// No aplica criterios clínicos (edad o peso mínimos): esa evaluación la
  /// hace el personal fuera del sistema y se registra como elegibilidad.
  static Map<String, String> validarDatos(Donante d, {required DateTime hoy}) {
    final errores = <String, String>{};
    if (d.nombre.trim().isEmpty) {
      errores['nombre'] = 'El nombre es obligatorio.';
    }
    final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);
    if (d.fechaNacimiento.isAfter(soloHoy)) {
      errores['fechaNacimiento'] =
          'La fecha de nacimiento no puede ser futura.';
    }
    if (d.pesoKg <= 0) {
      errores['pesoKg'] = 'El peso debe ser mayor que 0.';
    }
    if (d.telefono.trim().isEmpty) {
      errores['telefono'] = 'El teléfono es obligatorio.';
    }
    return errores;
  }

  String _rutNormalizado(String rut) {
    if (!Rut.esValido(rut)) throw RutInvalidoException(rut);
    return Rut.normalizar(rut);
  }
}
