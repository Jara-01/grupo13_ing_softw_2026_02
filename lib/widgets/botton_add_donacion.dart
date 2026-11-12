import 'package:flutter/material.dart';
import 'package:ing_software/models/inventario_model.dart';
import 'package:ing_software/models/lista_donaciones.dart';

class ButtonAddDonacion extends StatefulWidget {
  const ButtonAddDonacion({super.key});

  @override
  State<ButtonAddDonacion> createState() => _ButtonAddDonacionState();
}

class _ButtonAddDonacionState extends State<ButtonAddDonacion> {
  String donacionTipo = "O+";
  int? donacionVolumen;
  String? donacionCentro;
  DateTime? donacionFecha;
  
  Future<void> _inputFecha() async {
    final DateTime? fechaUsuario = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year), 
      lastDate: DateTime(2050),
    );

    setState(() {
      donacionFecha = fechaUsuario;
    });
  }

  void limpiarDonacion() {
    donacionTipo = 'O+';
    donacionVolumen = null;
    donacionCentro = null;
    donacionFecha = null;
  }

  Future<void> _inputDonacion() async {
  showDialog(
    barrierDismissible: false,
    context:  context,
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          constraints: BoxConstraints(minWidth: 400),
          contentPadding: EdgeInsets.all(10.0),
          title: const Text("Agregar donación"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Tipo de Sangre", style: const TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                    value: donacionTipo,
                    items: ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (nuevoValor) {
                      if (nuevoValor != null) {
                        setState(() {
                          donacionTipo = nuevoValor;
                        });
                      }
                    },
                  ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Volumen:", style: const TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'ml',
                        ),
                        onChanged: (volUsuario) {
                          if (int.tryParse(volUsuario) != null) {
                            setState(() {
                              donacionVolumen = int.parse(volUsuario);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Centro de Origen:", style: const TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(
                      width: 250,
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Centro',
                        ),
                        onChanged: (centroUsuario) {
                          setState(() {
                            donacionCentro = centroUsuario;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Fecha de Extracción:", style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: _inputFecha,
                      child: Text("Cambiar fecha"),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Al cancelar todas las opciones vuelven a su valor predeterminado
            TextButton(
              onPressed: () {
                limpiarDonacion();
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            // Al aceptar primero se comprueba si las entradas son válidas, luego se añade un elemento a la lista de donaciones
            TextButton(
              onPressed: () {
                if(donacionVolumen == null || donacionVolumen !< 250) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Donación rechazada: Volumen inválido")),
                  );
                }
                else if (donacionFecha == null || donacionFecha!.isAfter(DateTime.now())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Donación rechazada: Fecha inválida")),
                  );
                }
                else if (donacionCentro == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Donación rechazada: Centro inválido")),
                  );
                } else {
                  inventarioMock.add(InventarioItem(
                    id: "B-XX", // TODO: añadir un sistema de id's para las donaciones
                    tipoSangre: donacionTipo,
                    unidadesDisponibles: 1,
                    centroOrigen: donacionCentro ?? '',
                    fechaLlegada: donacionFecha ?? DateTime.now(),
                    fechaVencimiento: donacionFecha!.add(Duration(days: 42)),
                    volumenMl: donacionVolumen ?? 0,
                  ));
                }
                Navigator.of(context).pop();
                limpiarDonacion();
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      });
    }
  );
}
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _inputDonacion();
      },
      child: const Text('Agregar donación'),
    );
  }
}