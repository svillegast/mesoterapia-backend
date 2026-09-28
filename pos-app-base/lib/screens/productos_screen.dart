import 'package:flutter/material.dart';
import '../config/negocio_config.dart';
import '../models/producto.dart';
import '../services/database_service.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final _db = DatabaseService.instance;
  List<Producto> _productos = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await _db.listarProductos();
    if (mounted) setState(() => _productos = lista);
  }

  Future<void> _abrirFormulario({Producto? existente}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioProducto(existente: existente),
    );
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
      body: _productos.isEmpty
          ? const Center(child: Text('Todavía no hay productos registrados.'))
          : ListView.builder(
              itemCount: _productos.length,
              itemBuilder: (_, i) {
                final p = _productos[i];
                return ListTile(
                  title: Text(p.nombre),
                  subtitle: Text(
                    'Stock: ${p.stock} · \$${p.precioUnidad.toStringAsFixed(2)} c/u'
                    '${p.precioMayorista != null ? " · \$${p.precioMayorista!.toStringAsFixed(2)} desde ${p.cantidadMinimaMayorista}" : ""}',
                  ),
                  onTap: () => _abrirFormulario(existente: p),
                );
              },
            ),
    );
  }
}

class _FormularioProducto extends StatefulWidget {
  final Producto? existente;
  const _FormularioProducto({this.existente});

  @override
  State<_FormularioProducto> createState() => _FormularioProductoState();
}

class _FormularioProductoState extends State<_FormularioProducto> {
  final _nombreCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _precioMayoristaCtrl = TextEditingController();
  final _cantidadMinimaCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    final p = widget.existente;
    if (p != null) {
      _nombreCtrl.text = p.nombre;
      _precioCtrl.text = p.precioUnidad.toString();
      _precioMayoristaCtrl.text = p.precioMayorista?.toString() ?? '';
      _cantidadMinimaCtrl.text = p.cantidadMinimaMayorista?.toString() ??
          NegocioConfig.cantidadMinimaMayoristaPorDefecto.toString();
      _stockCtrl.text = p.stock.toString();
    } else {
      _cantidadMinimaCtrl.text = NegocioConfig.cantidadMinimaMayoristaPorDefecto.toString();
    }
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty || _precioCtrl.text.trim().isEmpty) return;
    final producto = Producto(
      id: widget.existente?.id,
      nombre: _nombreCtrl.text.trim(),
      precioUnidad: double.tryParse(_precioCtrl.text) ?? 0,
      precioMayorista: NegocioConfig.ventaSoloConsumidorFinal ? null : double.tryParse(_precioMayoristaCtrl.text),
      cantidadMinimaMayorista:
          NegocioConfig.ventaSoloConsumidorFinal ? null : int.tryParse(_cantidadMinimaCtrl.text),
      stock: int.tryParse(_stockCtrl.text) ?? 0,
    );
    await DatabaseService.instance.guardarProducto(producto);
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
          Text(widget.existente == null ? 'Nuevo producto' : 'Editar producto',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _precioCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Precio por ${NegocioConfig.etiquetaUnidad}',
              border: OutlineInputBorder(),
            ),
          ),
          if (!NegocioConfig.ventaSoloConsumidorFinal) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _precioMayoristaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Precio al por mayor (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cantidadMinimaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Desde cuántos', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _stockCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Stock actual', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _guardar, child: const Text('Guardar')),
        ],
      ),
    );
  }
}
