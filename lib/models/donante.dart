// T01 · Modelo de datos del donante (US01).
//
// Refleja los datos mínimos de RF-08 (RUT, nombre, fecha de nacimiento,
// peso, tipo de sangre y teléfono) y el resultado de la evaluación de
// elegibilidad de RF-09 (apto, diferido con fecha o rechazado).

/// Los ocho tipos de sangre del dominio (ABO/Rh).
enum TipoSangre {
  aPos('A+'),
  aNeg('A-'),
  bPos('B+'),
  bNeg('B-'),
  abPos('AB+'),
  abNeg('AB-'),
  oPos('O+'),
  oNeg('O-');

  const TipoSangre(this.etiqueta);

  /// Texto que se guarda en la base de datos y se muestra en pantalla.
  final String etiqueta;

  static TipoSangre desdeEtiqueta(String etiqueta) {
    return TipoSangre.values.firstWhere(
      (t) => t.etiqueta == etiqueta,
      orElse: () => throw ArgumentError('Tipo de sangre inválido: $etiqueta'),
    );
  }
}

/// Resultado de la evaluación de elegibilidad, que el personal realiza fuera
/// del sistema y luego registra (RF-09).
enum EstadoElegibilidad {
  /// El donante fue registrado, pero aún no se ingresa su evaluación.
  sinEvaluar,

  /// Apto para donar.
  apto,

  /// Diferido temporalmente; puede volver a donar desde [Donante.fechaDiferido].
  diferido,

  /// Rechazado permanentemente.
  rechazado,
}

class Donante {
  /// RUT en formato normalizado `cuerpo-DV`, por ejemplo `12345678-5`.
  final String rut;
  final String nombre;
  final DateTime fechaNacimiento;
  final double pesoKg;
  final TipoSangre tipoSangre;
  final String telefono;
  final EstadoElegibilidad estado;

  /// Fecha desde la cual un donante diferido puede volver a donar.
  /// Solo tiene valor cuando [estado] es [EstadoElegibilidad.diferido].
  final DateTime? fechaDiferido;

  /// Versión del registro, para control de concurrencia optimista (US05).
  final int version;

  const Donante({
    required this.rut,
    required this.nombre,
    required this.fechaNacimiento,
    required this.pesoKg,
    required this.tipoSangre,
    required this.telefono,
    this.estado = EstadoElegibilidad.sinEvaluar,
    this.fechaDiferido,
    this.version = 1,
  });

  Donante copyWith({
    String? rut,
    String? nombre,
    DateTime? fechaNacimiento,
    double? pesoKg,
    TipoSangre? tipoSangre,
    String? telefono,
    EstadoElegibilidad? estado,
    DateTime? fechaDiferido,
    bool borrarFechaDiferido = false,
    int? version,
  }) {
    return Donante(
      rut: rut ?? this.rut,
      nombre: nombre ?? this.nombre,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      pesoKg: pesoKg ?? this.pesoKg,
      tipoSangre: tipoSangre ?? this.tipoSangre,
      telefono: telefono ?? this.telefono,
      estado: estado ?? this.estado,
      fechaDiferido: borrarFechaDiferido
          ? null
          : (fechaDiferido ?? this.fechaDiferido),
      version: version ?? this.version,
    );
  }

  /// Fila de la tabla `donante`. Las fechas se guardan como `YYYY-MM-DD`.
  Map<String, Object?> toMap() {
    return {
      'rut': rut,
      'nombre': nombre,
      'fecha_nacimiento': fechaComoTexto(fechaNacimiento),
      'peso_kg': pesoKg,
      'tipo_sangre': tipoSangre.etiqueta,
      'telefono': telefono,
      'estado_elegibilidad': estado.name,
      'fecha_diferido': fechaDiferido == null
          ? null
          : fechaComoTexto(fechaDiferido!),
      'version': version,
    };
  }

  factory Donante.fromMap(Map<String, Object?> fila) {
    final fechaDiferido = fila['fecha_diferido'] as String?;
    return Donante(
      rut: fila['rut'] as String,
      nombre: fila['nombre'] as String,
      fechaNacimiento: DateTime.parse(fila['fecha_nacimiento'] as String),
      pesoKg: (fila['peso_kg'] as num).toDouble(),
      tipoSangre: TipoSangre.desdeEtiqueta(fila['tipo_sangre'] as String),
      telefono: fila['telefono'] as String,
      estado: EstadoElegibilidad.values.byName(
        fila['estado_elegibilidad'] as String,
      ),
      fechaDiferido: fechaDiferido == null
          ? null
          : DateTime.parse(fechaDiferido),
      version: fila['version'] as int,
    );
  }

  /// Convierte una fecha a `YYYY-MM-DD`, ignorando la hora.
  static String fechaComoTexto(DateTime fecha) {
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year.toString().padLeft(4, '0')}-$m-$d';
  }

  @override
  String toString() =>
      'Donante($rut, $nombre, ${tipoSangre.etiqueta}, ${estado.name})';
}
