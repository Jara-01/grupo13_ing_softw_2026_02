import 'package:ing_software/models/peticion_model.dart';
import 'package:ing_software/services/database_helper.dart';

class PeticionesService {
  static String centroActual = 'Hospital Regional Concepción';

  Future<List<Peticion>> obtenerPeticiones() async {
    return await DatabaseHelper.instance.obtenerPeticiones();
  }

  Future<List<Peticion>> obtenerMisPeticiones() async {
    final todas = await DatabaseHelper.instance.obtenerPeticiones();
    return todas.where((p) => p.centroSolicitante == centroActual).toList();
  }

  Future<void> crearPeticion({
    required String tipoSangre,
    required int cantidad,
    String? centroPersonalizado,
  }) async {
    final String emisor = centroPersonalizado ?? centroActual;
    final todas = await DatabaseHelper.instance.obtenerPeticiones();

    final nuevaPeticion = Peticion(
      id: 'PET-${(todas.length + 1).toString().padLeft(3, '0')}',
      centroSolicitante: emisor,
      tipoSangre: tipoSangre,
      cantidad: cantidad,
      estado: 'pendiente',
    );

    await DatabaseHelper.instance.crearPeticion(nuevaPeticion);
  }

  Future<bool> cerrarPeticion(String id) async {
    try {
      await DatabaseHelper.instance.cerrarPeticion(id);
      return true;
    } catch (e) {
      return false;
    }
  }
}