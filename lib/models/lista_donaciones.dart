import 'package:ing_software/models/inventario_model.dart';

class ListaDonacionesConfig {
  static const String estadoDisponible = 'Disponible';
}

/// Inventario de ejemplo usado por la pantalla de gestión de peticiones.
/// Se mantiene mutable porque el servicio descuenta unidades al crear peticiones.
final List<InventarioItem> inventarioMock = [
  InventarioItem(
    id: 'BOLSA-001',
    tipoSangre: 'O+',
    unidadesDisponibles: 3,
    centroOrigen: 'Hospital Regional',
    fechaLlegada: DateTime(2026, 11, 1),
    fechaVencimiento: DateTime(2026, 12, 1),
    volumenMl: 450,
  ),
  InventarioItem(
    id: 'BOLSA-002',
    tipoSangre: 'O+',
    unidadesDisponibles: 2,
    centroOrigen: 'Hospital Regional',
    fechaLlegada: DateTime(2026, 11, 3),
    fechaVencimiento: DateTime(2026, 12, 5),
    volumenMl: 450,
  ),
  InventarioItem(
    id: 'BOLSA-003',
    tipoSangre: 'A+',
    unidadesDisponibles: 2,
    centroOrigen: 'Hospital Regional',
    fechaLlegada: DateTime(2026, 11, 4),
    fechaVencimiento: DateTime(2026, 12, 8),
    volumenMl: 450,
  ),
];
