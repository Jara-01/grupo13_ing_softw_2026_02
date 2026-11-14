import 'package:flutter/material.dart';
import 'package:ing_software/screens/detalle_bolsas_screen.dart';
import 'package:ing_software/services/database_helper.dart';
import 'package:ing_software/models/tipos_helper.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  String _tipoSeleccionado = 'O-';
  
  List<String> _obtenerCompatibles(String tipo) {
    switch (tipo) {
      case 'O-':
        return ['O-'];
      case 'O+':
        return ['O-', 'O+'];
      case 'A-':
        return ['O-', 'A-'];
      case 'A+':
        return ['O-', 'O+', 'A-', 'A+'];
      case 'B-':
        return ['O-', 'B-'];
      case 'B+':
        return ['O-', 'O+', 'B-', 'B+'];
      case 'AB-':
        return ['O-', 'A-', 'B-', 'AB-'];
      case 'AB+':
        return ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'];
      default:
        return [];
    }
  }

  int _obtenerStockDe(String tipoSangre, ListaRegistros donaciones) {
    return donaciones.where((i) => i['tipoSangre'] == tipoSangre).length;
  }

  Color _obtenerColorStock(int unidades) {
    if (unidades >= 2) return Colors.green.shade300;
    if (unidades == 1) return Colors.amber.shade300;
    return Colors.red.shade300;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario y Compatibilidad'),
      ),
      body: FutureBuilder<ListaRegistros>(
        future: DatabaseHelper.instance.obtenerDonacionesDisponibles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar inventario: ${snapshot.error}'));
          }

          final donacionesDisponibles = snapshot.data ?? [];
          final tiposUnicos = donacionesDisponibles.map((e) => e['tipoSangre'].toString()).toSet().toList();

          if (tiposUnicos.isEmpty) {
            tiposUnicos.addAll(['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+']);
          }

          final compatibles = _obtenerCompatibles(_tipoSeleccionado);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stock Actual de Inventario',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: tiposUnicos.length,
                    itemBuilder: (context, index) {
                      final tipo = tiposUnicos[index];
                      final totalUnidades = _obtenerStockDe(tipo, donacionesDisponibles);
                      final colorCard = _obtenerColorStock(totalUnidades);

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalleBolsasScreen(
                                tipoSangre: tipo,
                                todasLasBolsas: donacionesDisponibles,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 3,
                          child: Container(
                            width: 140,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: colorCard, width: 4)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(tipo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                Text('$totalUnidades bolsas', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                const Text('Ver detalle ➔', style: TextStyle(fontSize: 10, color: Colors.blue)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 40),
                const Text(
                  'Consulta de Tabla de Compatibilidad',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Tipo de sangre del paciente: '),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _tipoSeleccionado,
                      items: ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (nuevoValor) {
                        if (nuevoValor != null) {
                          setState(() {
                            _tipoSeleccionado = nuevoValor;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Tipos compatibles para $_tipoSeleccionado:',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: compatibles.map((t) {
                    final stock = _obtenerStockDe(t, donacionesDisponibles);
                    final colorChip = _obtenerColorStock(stock);
                    return Chip(
                      label: Text('$t ($stock disp.)'),
                      backgroundColor: colorChip,
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}