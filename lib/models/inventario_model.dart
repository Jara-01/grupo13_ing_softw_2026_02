class InventarioItem {
  final String id;
  final String tipoSangre;
  final int unidadesDisponibles; // O volumen/cantidad de esta unidad específica
  final String centroOrigen;
  final DateTime fechaLlegada;
  final DateTime fechaVencimiento;
  final int volumenMl; // Ej: 450 ml

  InventarioItem({
    required this.id,
    required this.tipoSangre,
    required this.unidadesDisponibles,
    required this.centroOrigen,
    required this.fechaLlegada,
    required this.fechaVencimiento,
    required this.volumenMl,
  });


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo_sangre': tipoSangre,
      'unidades_disponibles': unidadesDisponibles,
      'centro_origen': centroOrigen,
      'fecha_llegada': fechaLlegada.toIso8601String(),
      'fecha_vencimiento': fechaVencimiento.toIso8601String(),
      'volumen_ml': volumenMl,
    };
  }

  factory InventarioItem.fromMap(Map<String, dynamic> map) {
    return InventarioItem(
      id: map['id'],
      tipoSangre: map['tipo_sangre'],
      unidadesDisponibles: map['unidades_disponibles'],
      centroOrigen: map['centro_origen'],
      fechaLlegada: DateTime.parse(map['fecha_llegada']),
      fechaVencimiento: DateTime.parse(map['fecha_vencimiento']),
      volumenMl: map['volumen_ml'],
    );
  }
}
