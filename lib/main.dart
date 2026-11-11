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
  bool? testPopup;
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
      print(horaDonacion);
    });
  }

  Future<void> _inputDonacion() async {
  switch (await showDialog(
    context:  context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: const Text("test"),
        children: [
          SimpleDialogOption(
            onPressed: () { Navigator.pop(context, true); },
            child: const Text('True'),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Text("Fecha y hora:"),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _inputFecha,
                      child: Text("Fecha"),
                    ),
                    OutlinedButton(
                      onPressed: _inputHora,
                      child: Text("Hora"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }
  )) {
    case true:
      testPopup = true;
      print("true");
    break;
    case false:
      testPopup = false;
      print("false");
    break;
    case null:
      print("null");
    break;
  }
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