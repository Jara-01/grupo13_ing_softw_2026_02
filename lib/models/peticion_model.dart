// niveles de urgencia permitidos en una peticion
const List<String> nivelesUrgencia = ['Baja', 'Media', 'Alta', 'Critica'];

class Peticion {
  final String id;
  final String centroSolicitante;
  final String tipoSangre;
  final int cantidad;
  String estado;
  final String? paciente;
  final String? centroDestino;
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
    this.estado = 'pendiente',
    this.paciente,
    this.centroDestino,
    this.urgencia,
    this.fecha,
    this.unidadesDescontadas = 0,
    this.stockAntes,
    this.stockDespues,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'centroSolicitante': centroSolicitante,
      'tipoSangre': tipoSangre,
      'cantidad': cantidad,
      'estado': estado,
      'paciente': paciente,
      'centroDestino': centroDestino,
      'urgencia': urgencia,
      'fecha': fecha?.toIso8601String(),
      'unidadesDescontadas': unidadesDescontadas,
      'stockAntes': stockAntes,
      'stockDespues': stockDespues,
    };
  }

  factory Peticion.fromJson(Map<String, dynamic> json) {
    return Peticion(
      id: json['id'],
      centroSolicitante: json['centroSolicitante'],
      tipoSangre: json['tipoSangre'],
      cantidad: json['cantidad'],
      estado: json['estado'],
      paciente: json['paciente'],
      centroDestino: json['centroDestino'],
      urgencia: json['urgencia'],
      fecha: json['fecha'] == null ? null : DateTime.parse(json['fecha']),
      unidadesDescontadas: json['unidadesDescontadas'] ?? 0,
      stockAntes: json['stockAntes'],
      stockDespues: json['stockDespues'],
    );
  }
}
