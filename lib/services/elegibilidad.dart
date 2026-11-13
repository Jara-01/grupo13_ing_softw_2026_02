// T03 · Regla para determinar si un donante está "apto vigente" (US01).
//
// La evaluación clínica la hace el personal fuera del sistema y se registra
// como estado (RF-09). Esta regla solo combina lo registrado para responder
// si hoy se puede aceptar una donación (RF-05):
//
//   apto vigente = (estado apto, o diferido cuya fecha ya llegó)
//                  y se cumplió el intervalo mínimo desde la última donación.

import '../models/donante.dart';

class ReglasElegibilidad {
  ReglasElegibilidad._();

  /// Días mínimos entre dos donaciones de un mismo donante.
  ///
  /// VALOR PROVISIONAL: lo debe confirmar el Product Owner. Se deja como
  /// parámetro para poder cambiarlo sin tocar la regla.
  static const int diasMinimosEntreDonaciones = 90;
}

class ResultadoElegibilidad {
  const ResultadoElegibilidad._(this.apto, this.motivo, this.habilitadoDesde);

  const ResultadoElegibilidad.apto() : this._(true, 'Apto para donar.', null);

  const ResultadoElegibilidad.noApto(String motivo, {DateTime? habilitadoDesde})
    : this._(false, motivo, habilitadoDesde);

  final bool apto;

  /// Mensaje para mostrar al personal (UC-02, extensión 4').
  final String motivo;

  /// Primer día en que podrá donar, si la inelegibilidad es temporal.
  final DateTime? habilitadoDesde;

  @override
  String toString() =>
      'ResultadoElegibilidad(apto: $apto, motivo: $motivo, desde: $habilitadoDesde)';
}

/// Evalúa si [donante] puede donar en la fecha [hoy].
///
/// [ultimaDonacion] es la fecha de su donación más reciente, o `null` si
/// nunca ha donado. Solo se comparan fechas: la hora no influye.
ResultadoElegibilidad evaluarElegibilidad({
  required Donante donante,
  required DateTime hoy,
  DateTime? ultimaDonacion,
  int diasMinimosEntreDonaciones =
      ReglasElegibilidad.diasMinimosEntreDonaciones,
}) {
  final dia = _soloFecha(hoy);

  switch (donante.estado) {
    case EstadoElegibilidad.sinEvaluar:
      return const ResultadoElegibilidad.noApto(
        'No tiene una evaluación de elegibilidad registrada.',
      );
    case EstadoElegibilidad.rechazado:
      return const ResultadoElegibilidad.noApto(
        'Rechazado permanentemente para donar.',
      );
    case EstadoElegibilidad.diferido:
      final desde = _soloFecha(donante.fechaDiferido!);
      if (dia.isBefore(desde)) {
        return ResultadoElegibilidad.noApto(
          'Diferido temporalmente. Podrá donar desde el '
          '${Donante.fechaComoTexto(desde)}.',
          habilitadoDesde: desde,
        );
      }
    case EstadoElegibilidad.apto:
      break;
  }

  if (ultimaDonacion != null) {
    final u = _soloFecha(ultimaDonacion);
    final desde = DateTime.utc(
      u.year,
      u.month,
      u.day + diasMinimosEntreDonaciones,
    );
    if (dia.isBefore(desde)) {
      return ResultadoElegibilidad.noApto(
        'Aún no cumple $diasMinimosEntreDonaciones días desde su última '
        'donación. Podrá donar desde el ${Donante.fechaComoTexto(desde)}.',
        habilitadoDesde: desde,
      );
    }
  }

  return const ResultadoElegibilidad.apto();
}

/// Fecha sin hora, en UTC, para que los cambios de horario no muevan el día.
DateTime _soloFecha(DateTime f) => DateTime.utc(f.year, f.month, f.day);
