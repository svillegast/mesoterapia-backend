import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../services/database_service.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _db = DatabaseService.instance;
  List<Cliente> _clientes = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await _db.listarClientes();
    if (mounted) setState(() => _clientes = lista);
  }

  Future<void> _abrirFormulario({Cliente? existente}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioCliente(existente: existente),
    );
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
      body: _clientes.isEmpty
          ? const Center(child: Text('Todavía no hay clientes registrados.'))
          : ListView.builder(
              itemCount: _clientes.length,
              itemBuilder: (_, i) {
                final c = _clientes[i];
                return ListTile(
                  title: Text(c.nombre),
                  subtitle: Text([
                    if (c.telefono != null && c.telefono!.isNotEmpty) c.telefono!,
                    if (c.direccion != null && c.direccion!.isNotEmpty) c.direccion!,
                  ].join(' · ')),
                  onTap: () => _abrirFormulario(existente: c),
                );
              },
            ),
    );
  }
}

class _FormularioCliente extends StatefulWidget {
  final Cliente? existente;
  const _FormularioCliente({this.existente});

  @override
  State<_FormularioCliente> createState() => _FormularioClienteState();
}

class _FormularioClienteState extends State<_FormularioCliente> {
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final c = widget.existente;
    if (c != null) {
      _nombreCtrl.text = c.nombre;
      _telefonoCtrl.text = c.telefono ?? '';
      _direccionCtrl.text = c.direccion ?? '';
      _notasCtrl.text = c.notas ?? '';
    }
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) return;
    final cliente = Cliente(
      id: widget.existente?.id,
      nombre: _nombreCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim().isEmpty ? null : _direccionCtrl.text.trim(),
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
    );
    await DatabaseService.instance.guardarCliente(cliente);
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
          Text(widget.existente == null ? 'Nuevo cliente' : 'Editar cliente',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _telefonoCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Teléfono (opcional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _direccionCtrl,
            decoration: const InputDecoration(labelText: 'Dirección (opcional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notasCtrl,
            decoration: const InputDecoration(labelText: 'Notas (opcional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _guardar, child: const Text('Guardar')),
        ],
      ),
    );
  }
}
