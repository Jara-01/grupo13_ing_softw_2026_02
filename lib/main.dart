import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: ButtonAddDonacion(),
        ),
      ),
    );
  }
}

class ButtonAddDonacion extends StatefulWidget {
  const ButtonAddDonacion({super.key});

  @override
  State<ButtonAddDonacion> createState() => _ButtonAddDonacionState();
}

class _ButtonAddDonacionState extends State<ButtonAddDonacion> {
  DateTime? fechaDonacion;
  TimeOfDay? horaDonacion;
  
  Future<void> _inputFecha() async {
    final DateTime? fechaUsuario = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year), 
      lastDate: DateTime(2050),
    );

    setState(() {
      fechaDonacion = fechaUsuario;
      print(fechaDonacion);
    });
  }
  Future<void> _inputHora() async {
    final TimeOfDay? horaUsuario = await showTimePicker(
      context: context,
      initialTime: horaDonacion ?? TimeOfDay.now(),
    );

    setState(() {
      horaDonacion = horaUsuario;
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
        content: SizedBox(
          height: 200.0,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: .center,
                crossAxisAlignment: .start,
                spacing: 15.0,
                children: [
                  OutlinedButton(
                    onPressed: _inputFecha,
                    child: Text("Cambiar fecha"),
                  ),
                  OutlinedButton(
                    onPressed: _inputHora,
                    child: Text("Cambiar hora"),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              fechaDonacion = null;
              horaDonacion = null;
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
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Ink(
            decoration: const ShapeDecoration(
              color: Colors.lightBlue,
              shape: CircleBorder(),
            ),
            child: IconButton(
              icon: const Icon(Icons.add),
              color: Colors.white,
              onPressed: () {
                _inputDonacion();
              },
            ),
          ),
        ),
      ),
    );
  }
}