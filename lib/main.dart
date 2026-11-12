// lib/main.dart
import 'package:flutter/material.dart';
import 'package:ing_software/screens/inventario_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          crossAxisAlignment: .center,
          spacing: 10.0,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InventarioScreen()),
                );
              },
              child: const Text('Inventario y compatibilidad'),
            ),
            ButtonAddDonacion(),
          ],
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
    return ElevatedButton(
      onPressed: () {
        _inputDonacion();
      },
      child: const Text('Agregar donación.'),
    );
  }
}