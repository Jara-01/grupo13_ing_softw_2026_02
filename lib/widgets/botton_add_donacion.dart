import 'package:flutter/material.dart';

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
            TextButton(
              onPressed: () {
                donacionFecha = null;
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                // TODO: Guardar los datos ingresados a una instancia de donación.
                Navigator.of(context).pop();
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