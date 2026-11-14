import 'package:ing_software/models/inventario_model.dart';
import 'package:ing_software/models/lista_donaciones.dart';
import 'package:ing_software/models/peticion_model.dart';

class PeticionesService {
  static String centroActual = 'Hospital Regional Concepción';

  // historial de peticiones (vacio al iniciar)
  static final List<Peticion> _peticionesDB = [];

  List<Peticion> obtenerPeticiones() {
    return _peticionesDB;
  }

  List<Peticion> obtenerMisPeticiones() {
    return _peticionesDB.where((p) => p.centroSolicitante == centroActual).toList();
  }

  void crearPeticion({
    required String tipoSangre,
    required int cantidad,
    String? centroPersonalizado,
  }) {
    final String emisor = centroPersonalizado ?? centroActual;

    final nuevaPeticion = Peticion(
      id: 'PET-${(_peticionesDB.length + 1).toString().padLeft(3, '0')}',
      centroSolicitante: emisor,
      tipoSangre: tipoSangre,
      cantidad: cantidad,
      estado: EstadoPeticion.pendiente,
    );
    _peticionesDB.add(nuevaPeticion);
  }

  bool cerrarPeticion(String id) {
    try {
      final peticion = _peticionesDB.firstWhere((p) => p.id == id);
      peticion.estado = EstadoPeticion.cerrada;
      return true;
    } catch (e) {
      return false;
    }
  }

  // stock total (en bolsas) disponible de un tipo de sangre
  int stockDe(String tipoSangre) {
    return inventarioMock
        .where((i) => i.tipoSangre == tipoSangre)
        .fold(0, (suma, i) => suma + i.unidadesDisponibles);
  }

  // stock por tipo para los tipos que siguen en el inventario
  Map<String, int> stockPorTipo() {
    final mapa = <String, int>{};
    for (final i in inventarioMock) {
      mapa[i.tipoSangre] = (mapa[i.tipoSangre] ?? 0) + i.unidadesDisponibles;
    }
    return mapa;
  }

  // Crea la peticion y descuenta primero las bolsas mas proximas a vencer.
  // La operacion falla completa si no hay stock suficiente: nunca hay descuentos parciales.
  Peticion crearPeticionConDescuento({
    required String paciente,
    required String centroDestino,
    required String tipoSangre,
    required int cantidad,
    required String urgencia,
  }) {
    if (cantidad <= 0) {
      throw ArgumentError.value(cantidad, 'cantidad', 'Debe ser mayor que cero.');
    }

    final bolsas = inventarioMock.where((i) => i.tipoSangre == tipoSangre).toList()
      ..sort((a, b) => a.fechaVencimiento.compareTo(b.fechaVencimiento));

    final stockAntes = bolsas.fold<int>(0, (s, b) => s + b.unidadesDisponibles);
    if (cantidad > stockAntes) {
      throw StateError(
        'Stock insuficiente para $tipoSangre: solicitado $cantidad, disponible $stockAntes.',
      );
    }

    // La validacion se hace antes de modificar el inventario.
    int restante = cantidad;
    for (final bolsa in bolsas) {
      if (restante == 0) break;
      if (bolsa.unidadesDisponibles <= restante) {
        restante -= bolsa.unidadesDisponibles;
        inventarioMock.remove(bolsa);
      } else {
        bolsa.unidadesDisponibles -= restante;
        restante = 0;
      }
    }

    final nueva = Peticion(
      id: 'PET-${(_peticionesDB.length + 1).toString().padLeft(3, '0')}',
      centroSolicitante: centroActual,
      tipoSangre: tipoSangre,
      cantidad: cantidad,
      estado: EstadoPeticion.pendiente,
      paciente: paciente,
      centroDestino: centroDestino,
      urgencia: urgencia,
      fecha: DateTime.now(),
      unidadesDescontadas: cantidad,
      stockAntes: stockAntes,
      stockDespues: stockAntes - cantidad,
    );
    _peticionesDB.add(nueva);
    return nueva;
  }
}
