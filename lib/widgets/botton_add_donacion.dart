import 'package:flutter/material.dart';

class ButtonAddDonacion extends StatefulWidget {
  const ButtonAddDonacion({super.key});

  @override
  State<ButtonAddDonacion> createState() => _ButtonAddDonacionState();
}

class _ButtonAddDonacionState extends State<ButtonAddDonacion> {
  DateTime? fechaDonacion;
  
  Future<void> _inputFecha() async {
    final DateTime? fechaUsuario = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year), 
      lastDate: DateTime(DateTime.now().year),
    );

    setState(() {
      fechaDonacion = fechaUsuario;
    });
  }

  Future<void> _inputDonacion() async {
  showDialog(
    barrierDismissible: false,
    context:  context,
    builder: (BuildContext context) {
      return AlertDialog(
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
                  Text("testest"), // TODO: Volver esto en un widget de input
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Volumen:", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("testest"), // TODO: Volver esto en un widget de input
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Centro de Origen:", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("testest"), // TODO: Volver esto en un widget de input
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
              fechaDonacion = null;
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