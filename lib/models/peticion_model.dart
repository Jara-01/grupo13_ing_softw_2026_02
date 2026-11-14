//niveles de urgencia permitidos en una peticion
const List<String> nivelesUrgencia = ['Baja', 'Media', 'Alta', 'Critica'];

// estados posibles de una peticion entre centros
enum EstadoPeticion {
  pendiente,
  cerrada;

  // texto para mostrar en pantalla
  String get etiqueta {
    switch (this) {
      case EstadoPeticion.pendiente:
        return 'Pendiente';
      case EstadoPeticion.cerrada:
        return 'Cerrada';
    }
  }
}

// modelo de una peticion de sangre entre centros
class Peticion {
  final String id;
  final String centroSolicitante;
  final String? centroDestino;
  final String tipoSangre;
  // bolsas solicitadas
  final int cantidad;

  EstadoPeticion estado;

  // datos del caso que origina la peticion
  final String? paciente;
  final String? urgencia;
  final DateTime? fecha;

  // registro del descuento hecho al inventario
  final int unidadesDescontadas;
  final int? stockAntes;
  final int? stockDespues;

  Peticion({
    required this.id,
    required this.centroSolicitante,
    required this.tipoSangre,
    required this.cantidad,
    this.estado = EstadoPeticion.pendiente,
    this.centroDestino,
    this.paciente,
    this.urgencia,
    this.fecha,
    this.unidadesDescontadas = 0,
    this.stockAntes,
    this.stockDespues,
  });

  // convierte la peticion a un mapa para guardarla en la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'centroSolicitante': centroSolicitante,
      'centroDestino': centroDestino,
      'tipoSangre': tipoSangre,
      'cantidad': cantidad,
      'estado': estado.name,
      'paciente': paciente,
      'urgencia': urgencia,
      'fecha': fecha?.toIso8601String(),
      'unidadesDescontadas': unidadesDescontadas,
      'stockAntes': stockAntes,
      'stockDespues': stockDespues,
    };
  }
}
