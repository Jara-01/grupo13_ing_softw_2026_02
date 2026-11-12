// lib/main.dart
import 'package:flutter/material.dart';
import 'package:ing_software/screens/inventario_screen.dart';
import 'package:ing_software/widgets/botton_add_donacion.dart';

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