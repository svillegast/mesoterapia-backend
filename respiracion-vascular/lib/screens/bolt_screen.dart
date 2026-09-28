import 'dart:async';
import 'package:flutter/material.dart';
import '../models/prueba_bolt.dart';
import '../services/database_service.dart';
import '../utils/formato_fecha.dart';

class BoltScreen extends StatefulWidget {
  const BoltScreen({super.key});

  @override
  State<BoltScreen> createState() => _BoltScreenState();
}

class _BoltScreenState extends State<BoltScreen> {
  final _db = DatabaseService.instance;
  List<PruebaBolt> _historial = [];

  bool _corriendo = false;
  int _segundos = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await _db.listarPruebasBolt();
    if (mounted) setState(() => _historial = lista);
  }

  void _iniciar() {
    setState(() {
      _corriendo = true;
      _segundos = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _segundos++);
    });
  }

  Future<void> _detener() async {
    _timer?.cancel();
    setState(() => _corriendo = false);
    if (_segundos > 0) {
      await _db.guardarPruebaBolt(PruebaBolt(fecha: DateTime.now(), segundos: _segundos));
      await _cargar();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba BOLT')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Respira normal, exhala normal, y al terminar de exhalar presiona '
                '"Iniciar" y aguanta sin respirar hasta sentir la primera necesidad '
                'real de inhalar (no el límite máximo). Presiona "Detener" en ese momento.',
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('$_segundos s', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _corriendo ? _detener : _iniciar,
              icon: Icon(_corriendo ? Icons.stop : Icons.play_arrow),
              label: Text(_corriendo ? 'Detener' : 'Iniciar'),
              style: _corriendo ? FilledButton.styleFrom(backgroundColor: Colors.red) : null,
            ),
          ),
          const SizedBox(height: 32),
          Text('Historial', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_historial.isEmpty)
            const Text('Todavía no tienes pruebas registradas.')
          else
            ..._historial.take(20).map((p) => ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: Text('${p.segundos} s'),
                  subtitle: Text(formatearFechaHora(p.fecha)),
                )),
        ],
      ),
    );
  }
}
