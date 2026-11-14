import 'package:flutter/material.dart';
import 'package:ing_software/models/tipos_helper.dart';

class DetalleBolsasScreen extends StatelessWidget {
  final String tipoSangre;
  final ListaRegistros todasLasBolsas;

  const DetalleBolsasScreen({
    super.key,
    required this.tipoSangre,
    required this.todasLasBolsas,
  });

  @override
  Widget build(BuildContext context) {
    ListaRegistros bolsasFiltradas = todasLasBolsas
        .where((b) => b['tipoSangre'] == tipoSangre)
        .toList();

    bolsasFiltradas.sort((a, b) => a['fechaVencimiento'].compareTo(b['fechaVencimiento']));

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de Bolsas: $tipoSangre'),
      ),
      body: bolsasFiltradas.isEmpty
          ? const Center(
        child: Text(
          'No hay bolsas disponibles para este tipo de sangre.',
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: bolsasFiltradas.length,
        itemBuilder: (context, index) {
          final bolsa = bolsasFiltradas[index];
          final fechaVenc = DateTime.parse(bolsa['fechaVencimiento']);
          final diasRestantes = fechaVenc.difference(DateTime.now()).inDays;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: diasRestantes < 5 ? Colors.red.shade100 : Colors.green.shade100,
                child: Text(
                  bolsa['tipoSangre'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: diasRestantes < 5 ? Colors.red.shade800 : Colors.green.shade800,
                  ),
                ),
              ),
              title: Text('ID Bolsa: ${bolsa['id']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Centro Origen: ${bolsa['centroOrigen']}'),
                  Text('Volumen: ${bolsa['volumenMl']} ml'),
                  Text('Vence en: $diasRestantes días (${bolsa['fechaVencimiento'].toString().substring(0, 10)})'),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}