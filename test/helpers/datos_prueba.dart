// Datos de prueba compartidos por los tests de US01.

import 'package:ing_software/models/donante.dart';

Donante donanteDePrueba({String rut = '12345678-5'}) => Donante(
  rut: rut,
  nombre: 'Ana Rojas',
  fechaNacimiento: DateTime(1995, 4, 20),
  pesoKg: 62.5,
  tipoSangre: TipoSangre.oNeg,
  telefono: '+56911112222',
);
