import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import '../services/database_service.dart';

class VentaScreen extends StatefulWidget {
  const VentaScreen({super.key});

  @override
  State<VentaScreen> createState() => _VentaScreenState();
}

class _VentaScreenState extends State<VentaScreen> {
  final _db = DatabaseService.instance;
  final _montoLibreCtrl = TextEditingController();
  final _montoPagadoCtrl = TextEditingController();

  List<Producto> _productos = [];
  Cliente? _clienteSeleccionado;
  final List<ItemVenta> _items = [];

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    _montoPagadoCtrl.addListener(() => setState(() {}));
    _montoLibreCtrl.addListener(() => setState(() {}));
  }

  Future<void> _cargarProductos() async {
    final lista = await _db.listarProductos();
    if (mounted) setState(() => _productos = lista);
  }

  double get _total {
    if (_items.isNotEmpty) {
      return _items.fold(0.0, (s, i) => s + i.subtotal);
    }
    return double.tryParse(_montoLibreCtrl.text) ?? 0;
  }

  double get _vuelto {
    final pagado = double.tryParse(_montoPagadoCtrl.text) ?? 0;
    return (pagado - _total).clamp(0, double.infinity);
  }

  Future<void> _agregarProducto(Producto p) async {
    final cantidad = await showDialog<int>(
      context: context,
      builder: (_) => _DialogoCantidad(producto: p),
    );
    if (cantidad == null || cantidad <= 0) return;
    setState(() {
      _items.add(ItemVenta(
        productoId: p.id,
        nombreProducto: p.nombre,
        cantidad: cantidad,
        precioUnitarioAplicado: p.precioParaCantidad(cantidad),
      ));
    });
  }

  Future<void> _guardarVenta() async {
    final pagado = double.tryParse(_montoPagadoCtrl.text) ?? 0;
    if (_total <= 0) {
      _mostrarError('Agrega productos o un monto para la venta.');
      return;
    }
    if (pagado < _total) {
      _mostrarError('El monto pagado es menor al total.');
      return;
    }

    final venta = Venta(
      fecha: DateTime.now(),
      clienteId: _clienteSeleccionado?.id,
      clienteNombre: _clienteSeleccionado?.nombre,
      items: _items,
      montoLibre: _items.isEmpty ? (double.tryParse(_montoLibreCtrl.text) ?? 0) : 0,
      montoPagado: pagado,
    );
    await _db.guardarVenta(venta);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Venta guardada. Vuelto: \$${_vuelto.toStringAsFixed(2)}')),
      );
      Navigator.of(context).pop();
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva venta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_productos.isNotEmpty) ...[
            Text('Productos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _productos
                  .map((p) => ActionChip(
                        label: Text(p.nombre),
                        onPressed: () => _agregarProducto(p),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (_items.isNotEmpty) ...[
            Card(
              child: Column(
                children: _items
                    .map((i) => ListTile(
                          title: Text(i.nombreProducto),
                          subtitle: Text('${i.cantidad} × \$${i.precioUnitarioAplicado.toStringAsFixed(2)}'),
                          trailing: Text('\$${i.subtotal.toStringAsFixed(2)}'),
                        ))
                    .toList(),
              ),
            ),
          ] else ...[
            TextField(
              controller: _montoLibreCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto de la venta', border: OutlineInputBorder()),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _montoPagadoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Con cuánto paga el cliente', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [const Text('Total'), Text('\$${_total.toStringAsFixed(2)}')],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Vuelto', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('\$${_vuelto.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _guardarVenta, child: const Text('Guardar venta')),
        ],
      ),
    );
  }
}

class _DialogoCantidad extends StatefulWidget {
  final Producto producto;
  const _DialogoCantidad({required this.producto});

  @override
  State<_DialogoCantidad> createState() => _DialogoCantidadState();
}

class _DialogoCantidadState extends State<_DialogoCantidad> {
  int _cantidad = 1;

  @override
  Widget build(BuildContext context) {
    final precio = widget.producto.precioParaCantidad(_cantidad);
    return AlertDialog(
      title: Text(widget.producto.nombre),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => setState(() => _cantidad = (_cantidad - 1).clamp(1, 9999)),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$_cantidad', style: const TextStyle(fontSize: 22)),
          IconButton(
            onPressed: () => setState(() => _cantidad++),
            icon: const Icon(Icons.add_circle_outline),
          ),
          const SizedBox(width: 12),
          Text('\$${precio.toStringAsFixed(2)} c/u'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, _cantidad), child: const Text('Agregar')),
      ],
    );
  }
}
