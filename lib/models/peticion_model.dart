// Niveles de urgencia permitidos en una petición.
const List<String> nivelesUrgencia = ['Baja', 'Media', 'Alta', 'Critica'];

// Estados posibles de una petición entre centros.
enum EstadoPeticion {
  pendiente,
  cerrada;

  String get etiqueta {
    switch (this) {
      case EstadoPeticion.pendiente:
        return 'Pendiente';
      case EstadoPeticion.cerrada:
        return 'Cerrada';
    }
  }
}

class Peticion {
  final String id;
  final String centroSolicitante;
  final String? centroDestino;
  final String tipoSangre;
  final int cantidad;
  EstadoPeticion estado;
  final String? paciente;
  final String? urgencia;
  final DateTime? fecha;
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

  /// Mapa completo para serializar una petición fuera del esquema SQLite actual.
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

  /// Conserva el formato de las cinco columnas de la tabla `peticiones`.
  /// DatabaseHelper usa este método al insertar en el esquema existente.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'centroSolicitante': centroSolicitante,
      'tipoSangre': tipoSangre,
      'cantidad': cantidad,
      'estado': estado.name,
    };
  }

  factory Peticion.fromJson(Map<String, dynamic> json) {
    final estadoTexto = json['estado'] as String? ?? EstadoPeticion.pendiente.name;
    final fechaTexto = json['fecha'] as String?;

    return Peticion(
      id: json['id'] as String,
      centroSolicitante: json['centroSolicitante'] as String,
      tipoSangre: json['tipoSangre'] as String,
      cantidad: (json['cantidad'] as num).toInt(),
      estado: EstadoPeticion.values.firstWhere(
        (estado) => estado.name == estadoTexto,
        orElse: () => EstadoPeticion.pendiente,
      ),
      centroDestino: json['centroDestino'] as String?,
      paciente: json['paciente'] as String?,
      urgencia: json['urgencia'] as String?,
      fecha: fechaTexto == null ? null : DateTime.tryParse(fechaTexto),
      unidadesDescontadas: (json['unidadesDescontadas'] as num?)?.toInt() ?? 0,
      stockAntes: (json['stockAntes'] as num?)?.toInt(),
      stockDespues: (json['stockDespues'] as num?)?.toInt(),
    );
  }
}
