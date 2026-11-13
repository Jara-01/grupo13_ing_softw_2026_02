// T02 · Validación del RUT chileno (NRF-02).
//
// Acepta el RUT con o sin puntos y guion ("12.345.678-5", "12345678-5" o
// "123456785") y valida el dígito verificador con el algoritmo módulo 11.

class Rut {
  Rut._();

  static final RegExp _formato = RegExp(r'^\d{7,8}[0-9K]$');

  /// Quita puntos, guiones y espacios, y pasa la K a mayúscula.
  static String limpiar(String entrada) =>
      entrada.replaceAll(RegExp(r'[.\s-]'), '').toUpperCase();

  /// `true` si el RUT tiene formato válido y su dígito verificador es correcto.
  static bool esValido(String entrada) {
    final rut = limpiar(entrada);
    if (!_formato.hasMatch(rut)) return false;
    final cuerpo = rut.substring(0, rut.length - 1);
    final dv = rut.substring(rut.length - 1);
    return calcularDv(cuerpo) == dv;
  }

  /// Formato con el que se guarda en la base de datos: `12345678-5`.
  /// Lanza [FormatException] si el RUT no es válido.
  static String normalizar(String entrada) {
    if (!esValido(entrada)) {
      throw FormatException('RUT inválido', entrada);
    }
    final rut = limpiar(entrada);
    return '${rut.substring(0, rut.length - 1)}-${rut.substring(rut.length - 1)}';
  }

  /// Dígito verificador (0-9 o K) para el cuerpo numérico de un RUT.
  static String calcularDv(String cuerpo) {
    var suma = 0;
    var multiplicador = 2;
    for (var i = cuerpo.length - 1; i >= 0; i--) {
      suma += int.parse(cuerpo[i]) * multiplicador;
      multiplicador = multiplicador == 7 ? 2 : multiplicador + 1;
    }
    final resultado = 11 - (suma % 11);
    if (resultado == 11) return '0';
    if (resultado == 10) return 'K';
    return '$resultado';
  }
}
