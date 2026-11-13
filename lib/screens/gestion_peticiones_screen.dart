import 'package:flutter/material.dart';
import 'package:ing_software/models/peticion_model.dart';
import 'package:ing_software/services/peticiones_service.dart';

// colores de cada nivel de urgencia
Color _colorUrgencia(String? urgencia) {
  switch (urgencia) {
    case 'Baja':
      return Colors.green;
    case 'Media':
      return Colors.amber.shade700;
    case 'Alta':
      return Colors.deepOrange;
    case 'Critica':
      return Colors.red.shade800;
    default:
      // sin urgencia (peticiones antiguas o sin dato)
      return Colors.grey;
  }
}

// codigo de la pantalla principal
class GestionPeticionesScreen extends StatefulWidget {
  const GestionPeticionesScreen({super.key});

  @override
  State<GestionPeticionesScreen> createState() => _GestionPeticionesScreenState();
}

class _GestionPeticionesScreenState extends State<GestionPeticionesScreen> {
  // servicio que guarda las peticiones y descuenta el inventario
  final PeticionesService _servicio = PeticionesService();

  // centros de destino (se usa los mismos nombres que usa el mock de inventario)
  final List<String> _centros = [
    'Hospital Regional',
    'Centro de Sangre',
    'Clínica Las Encinas',
  ];

  // abre el formulario para pedir los datos de peticion
  Future<void> _abrirFormulario() async {
    final stock = _servicio.stockPorTipo();
    // sin stock no tiene sentido abrir el formulario
    if (stock.isEmpty) {
      _mostrarMensaje('No hay unidades disponibles en el inventario :(');
      return;
    }
    final datos = await showModalBottomSheet<_DatosFormulario>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FormularioPeticion(stockPorTipo: stock, centros: _centros),
    );
    // datos es null si el usuario cancela o cierra el formulario
    if (datos != null) _confirmarPeticion(datos);
  }

  // registra la peticion y descuenta el inventario
  void _confirmarPeticion(_DatosFormulario d) {
    // late final porque se asigna dentro del setState
    late final Peticion creada;
    setState(() {
      creada = _servicio.crearPeticionConDescuento(
        paciente: d.paciente,
        centroDestino: d.centro,
        tipoSangre: d.tipoSangre,
        cantidad: d.cantidad,
        urgencia: d.urgencia,
      );
    });
    // si el stock quedo en 0, el tipo ya no aparece en el inventario
    _mostrarMensaje(creada.stockDespues == 0
        ? 'Peticion enviada. Se agotó ${creada.tipoSangre}'
        : 'Peticion enviada. Stock restante de ${creada.tipoSangre}: ${creada.stockDespues}');
  }

  void _mostrarMensaje(String texto) {
    // se oculta el mensaje anterior para que no se acumulen
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  void _abrirHistorial() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _HistorialScreen(servicio: _servicio)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // el stock se recalcula en cada build para reflejar los descuentos
    final stock = _servicio.stockPorTipo();
    final tipos = stock.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de peticiones'),
        actions: [
          // icono de historial
          IconButton(
            tooltip: 'Historial de cambios',
            icon: const Icon(Icons.history),
            onPressed: _abrirHistorial,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _abrirFormulario,
                    icon: const Icon(Icons.add),
                    label: const Text('agregar peticion'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _abrirHistorial,
                  icon: const Icon(Icons.history),
                  label: const Text('Historial'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Inventario actual (${tipos.length} tipos)',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: tipos.isEmpty
                ? const Center(child: Text('El inventario está vacío'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: tipos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final tipo = tipos[i];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: const Icon(Icons.bloodtype, color: Colors.red),
                          title: Text('Sangre $tipo'),
                          trailing: Chip(label: Text('Stock: ${stock[tipo]}')),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// formulario
// datos que devuelve el formulario al confirmarse
class _DatosFormulario {
  final String paciente;
  final String centro;
  final String tipoSangre;
  final int cantidad;
  final String urgencia;

  _DatosFormulario({
    required this.paciente,
    required this.centro,
    required this.tipoSangre,
    required this.cantidad,
    required this.urgencia,
  });
}

class _FormularioPeticion extends StatefulWidget {
  final Map<String, int> stockPorTipo;
  final List<String> centros;

  const _FormularioPeticion({required this.stockPorTipo, required this.centros});

  @override
  State<_FormularioPeticion> createState() => _FormularioPeticionState();
}

class _FormularioPeticionState extends State<_FormularioPeticion> {
  final _formKey = GlobalKey<FormState>();
  final _pacienteCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();

  String? _centro;
  String? _tipoSangre;
  // la urgencia media viene seleccionada por defecto
  String _urgencia = 'Media';

  @override
  void dispose() {
    // se liberan los controladores para evitar fugas de memoria
    _pacienteCtrl.dispose();
    _cantidadCtrl.dispose();
    super.dispose();
  }

  void _enviar() {
    // solo se envia si todos los campos son validos
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_DatosFormulario(
      paciente: _pacienteCtrl.text.trim(),
      centro: _centro!,
      tipoSangre: _tipoSangre!,
      cantidad: int.parse(_cantidadCtrl.text.trim()),
      urgencia: _urgencia,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tipos = widget.stockPorTipo.keys.toList()..sort();

    return Padding(
      // el padding inferior evita que el teclado tape los campos
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nueva petición', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // nombre del paciente
              TextFormField(
                controller: _pacienteCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre del paciente',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresa el nombre del paciente'
                    : null,
              ),
              const SizedBox(height: 12),

              // centro de destino
              DropdownButtonFormField<String>(
                value: _centro,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Centro de destino',
                  border: OutlineInputBorder(),
                ),
                items: widget.centros
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _centro = v),
                validator: (v) => v == null ? 'Selecciona un centro' : null,
              ),
              const SizedBox(height: 12),

              // insumo (tipo de sangre) con su stock disponible
              DropdownButtonFormField<String>(
                value: _tipoSangre,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Insumo necesario (tipo de sangre)',
                  border: OutlineInputBorder(),
                ),
                items: tipos
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text('Sangre $t  (stock: ${widget.stockPorTipo[t]})'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _tipoSangre = v),
                validator: (v) => v == null ? 'Selecciona un insumo' : null,
              ),
              const SizedBox(height: 12),

              // cantidad requerida
              TextFormField(
                controller: _cantidadCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cantidad requerida (bolsas)',
                  border: const OutlineInputBorder(),
                  // el stock disponible se muestra solo al elegir un tipo
                  helperText: _tipoSangre == null
                      ? null
                      : 'Disponible: ${widget.stockPorTipo[_tipoSangre]}.',
                  helperMaxLines: 2,
                ),
                validator: (v) {
                  // debe ser un entero mayor a 0
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Ingrese una cantidad mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // nivel de urgencia
              DropdownButtonFormField<String>(
                value: _urgencia,
                decoration: const InputDecoration(
                  labelText: 'Nivel de urgencia',
                  border: OutlineInputBorder(),
                ),
                items: nivelesUrgencia
                    .map((u) => DropdownMenuItem(
                          value: u,
                          child: Row(
                            children: [
                              Icon(Icons.circle, size: 12, color: _colorUrgencia(u)),
                              const SizedBox(width: 8),
                              Text(u),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _urgencia = v ?? _urgencia),
              ),
              const SizedBox(height: 20),

              FilledButton(
                onPressed: _enviar,
                child: const Text('confirmar y enviar peticion'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//historial de cambios
class _HistorialScreen extends StatelessWidget {
  final PeticionesService servicio;
  const _HistorialScreen({required this.servicio});

  // da formato dd/mm/aaaa hh:mm a la fecha
  String _fecha(DateTime? f) {
    if (f == null) return 'Sin fecha';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(f.day)}/${dos(f.month)}/${f.year} ${dos(f.hour)}:${dos(f.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final stock = servicio.stockPorTipo();
    final tipos = stock.keys.toList()..sort();
    // estaran primero las peticiones recientes
    final peticiones = servicio.obtenerPeticiones().reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de cambios')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // estado actualizado del inventario
          Text('Estado actual del inventario', style: tema.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (tipos.isEmpty)
            const Text('El inventario está vacío')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tipos.map((t) => Chip(label: Text('$t: ${stock[t]}'))).toList(),
            ),
          const Divider(height: 32),

          // registro de peticiones
          Text('Peticiones (${peticiones.length})', style: tema.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...peticiones.map((p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('${p.id} - ${p.paciente ?? 'Sin paciente'}',
                                style: tema.textTheme.titleSmall),
                          ),
                          if (p.urgencia != null)
                            Chip(
                              label: Text(p.urgencia!,
                                  style: const TextStyle(color: Colors.white)),
                              backgroundColor: _colorUrgencia(p.urgencia),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      Text(_fecha(p.fecha), style: tema.textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Text('Origen: ${p.centroSolicitante}'),
                      Text('Destino: ${p.centroDestino ?? '-'}'),
                      // estado de la peticion (pendiente o cerrada)
                      Text('Estado: ${p.estado.etiqueta}'),
                      Text('Sangre ${p.tipoSangre}  |  Solicitado: ${p.cantidad}'
                          '${p.stockAntes == null ? '' : '  |  Descontado: ${p.unidadesDescontadas}'}'),
                      // el detalle de stock solo existe si hubo descuento
                      if (p.stockAntes != null)
                        Text('Stock antes: ${p.stockAntes} -> stock despues: ${p.stockDespues}'),
                      // stock en 0 significa que el tipo salio del inventario
                      if (p.stockDespues == 0 && p.stockAntes != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Tipo retirado del inventario',
                              style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
