import 'package:flutter/material.dart';
import 'package:ing_software/services/database_helper.dart';

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

    if (fechaUsuario != null) {
      setState(() {
        donacionFecha = fechaUsuario;
      });
    }
  }

  Future<void> _inputDonacion() async {
    setState(() {
      donacionTipo = "O+";
      donacionVolumen = null;
      donacionCentro = null;
      donacionFecha = DateTime.now();
    });

    final BuildContext pantallaContext = context;

    if (!mounted) return;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            constraints: const BoxConstraints(minWidth: 400),
            contentPadding: const EdgeInsets.all(10.0),
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
                      const Text("Tipo de Sangre", style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: donacionTipo,
                        items: ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (nuevoValor) {
                          if (nuevoValor != null) {
                            setStateDialog(() {
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
                      const Text("Volumen:", style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'ml',
                          ),
                          onChanged: (volUsuario) {
                            if (int.tryParse(volUsuario) != null) {
                              setStateDialog(() {
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
                      const Text("Centro de Origen:", style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(
                        width: 250,
                        child: TextField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Centro',
                          ),
                          onChanged: (centroUsuario) {
                            setStateDialog(() {
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
                      const Text("Fecha de Extracción:", style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () async {
                          await _inputFecha();
                          setStateDialog(() {});
                        },
                        child: Text(donacionFecha == null
                            ? "Cambiar fecha"
                            : "${donacionFecha!.toLocal()}".split(' ')[0]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final db = await DatabaseHelper.instance.database;

                    final fechaLlegadaObj = donacionFecha ?? DateTime.now();
                    final fechaVencimientoObj = fechaLlegadaObj.add(const Duration(days: 42));

                    await db.insert(
                      'donaciones',
                      {
                        'id': 'B-${DateTime.now().millisecondsSinceEpoch}',
                        'tipoSangre': donacionTipo,
                        'centroOrigen': donacionCentro ?? 'Hospital Regional',
                        'fechaLlegada': fechaLlegadaObj.toIso8601String(),
                        'fechaVencimiento': fechaVencimientoObj.toIso8601String(),
                        'volumenMl': donacionVolumen ?? 450,
                        'estado': 'Disponible',
                      },
                    );

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }

                    if (pantallaContext.mounted) {
                      (pantallaContext as Element).markNeedsBuild();
                    }
                  } catch (e) {
                    print("Error al registrar donación: $e");
                  }
                },
                child: const Text("Aceptar"),
              ),
            ],
          );
        });
      },
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