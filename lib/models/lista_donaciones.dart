import 'package:flutter/material.dart';
import 'package:ing_software/models/inventario_model.dart';

List<InventarioItem> inventarioMock = [
    InventarioItem(id: 'B001', tipoSangre: 'O-', unidadesDisponibles: 1, centroOrigen: 'Hospital Regional', fechaLlegada: DateTime.now().subtract(const Duration(days: 5)), fechaVencimiento: DateTime.now().add(const Duration(days: 10)), volumenMl: 450),
    InventarioItem(id: 'B002', tipoSangre: 'O-', unidadesDisponibles: 1, centroOrigen: 'Centro de Sangre', fechaLlegada: DateTime.now().subtract(const Duration(days: 2)), fechaVencimiento: DateTime.now().add(const Duration(days: 3)), volumenMl: 400),
    InventarioItem(id: 'B003', tipoSangre: 'O+', unidadesDisponibles: 1, centroOrigen: 'Clínica Las Encinas', fechaLlegada: DateTime.now().subtract(const Duration(days: 10)), fechaVencimiento: DateTime.now().add(const Duration(days: 25)), volumenMl: 450),
    InventarioItem(id: 'B004', tipoSangre: 'O+', unidadesDisponibles: 1, centroOrigen: 'Hospital Regional', fechaLlegada: DateTime.now().subtract(const Duration(days: 1)), fechaVencimiento: DateTime.now().add(const Duration(days: 30)), volumenMl: 500),
    InventarioItem(id: 'B005', tipoSangre: 'A+', unidadesDisponibles: 1, centroOrigen: 'Hospital Regional', fechaLlegada: DateTime.now().subtract(const Duration(days: 4)), fechaVencimiento: DateTime.now().add(const Duration(days: 8)), volumenMl: 450),
    InventarioItem(id: 'B006', tipoSangre: 'AB+', unidadesDisponibles: 1, centroOrigen: 'Centro de Sangre', fechaLlegada: DateTime.now().subtract(const Duration(days: 8)), fechaVencimiento: DateTime.now().add(const Duration(days: 2)), volumenMl: 350),
  ];