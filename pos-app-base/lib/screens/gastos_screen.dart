import 'package:flutter/material.dart';
import '../models/gasto.dart';
import '../services/analisis_service.dart';
import '../services/database_service.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  final _db = DatabaseService.instance;
  final _analisis = AnalisisService();
  ResultadoAnalisis? _resultado;
  List<Gasto> _gastosMes = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final resultado = await _analisis.analizarMes(DateTime.now());
    final inicioMes = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final gastos = await _db.listarGastos(desde: inicioMes, hasta: DateTime.now());
    if (mounted) {
      setState(() {
        _resultado = resultado;
        _gastosMes = gastos;
      });
    }
  }

  Future<void> _agregarGasto() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FormularioGasto(),
    );
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final r = _resultado;
    return Scaffold(
      appBar: AppBar(title: const Text('Pérdidas y Ganancias')),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarGasto,
        child: const Icon(Icons.add),
      ),
      body: r == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: r.gananciaNeta >= 0
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Este mes', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text(
                          '\$${r.gananciaNeta.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        Text('Ventas \$${r.ventasMes.toStringAsFixed(2)} · Gastos \$${r.gastosMes.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline),
                        const SizedBox(width: 12),
                        Expanded(child: Text(r.resumen)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Gastos del mes', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_gastosMes.isEmpty)
                  const Text('Todavía no has registrado gastos este mes.')
                else
                  ..._gastosMes.map((g) => ListTile(
                        title: Text(g.categoria),
                        subtitle: Text(g.descripcion ?? ''),
                        trailing: Text('\$${g.monto.toStringAsFixed(2)}'),
                      )),
              ],
            ),
    );
  }
}

class _FormularioGasto extends StatefulWidget {
  const _FormularioGasto();

  @override
  State<_FormularioGasto> createState() => _FormularioGastoState();
}

class _FormularioGastoState extends State<_FormularioGasto> {
  final _categoriaCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  static const _categoriasComunes = ['Renta', 'Sueldos', 'Servicios', 'Insumos', 'Transporte', 'Otro'];

  Future<void> _guardar() async {
    if (_categoriaCtrl.text.trim().isEmpty || _montoCtrl.text.trim().isEmpty) return;
    final gasto = Gasto(
      fecha: DateTime.now(),
      categoria: _categoriaCtrl.text.trim(),
      monto: double.tryParse(_montoCtrl.text) ?? 0,
      descripcion: _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
    );
    await DatabaseService.instance.guardarGasto(gasto);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nuevo gasto', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _categoriasComunes
                .map((c) => ActionChip(label: Text(c), onPressed: () => setState(() => _categoriaCtrl.text = c)))
                .toList(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _categoriaCtrl,
            decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _montoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Monto', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descripcionCtrl,
            decoration: const InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _guardar, child: const Text('Guardar')),
        ],
      ),
    );
  }
}
