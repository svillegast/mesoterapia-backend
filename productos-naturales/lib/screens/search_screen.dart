import 'package:flutter/material.dart';
import '../services/investigacion_service.dart';
import 'results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _tipoBusqueda = 'disease';
  bool _cargando = false;
  final _servicio = InvestigacionService();

  Future<void> _buscar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    setState(() => _cargando = true);
    try {
      final resultado =
          await _servicio.buscar(query: texto, queryType: _tipoBusqueda);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResultsScreen(resultado: resultado)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al investigar: $e')),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos Naturales — Evidencia Científica')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'disease', label: Text('Por enfermedad')),
                ButtonSegment(value: 'organ', label: Text('Por órgano')),
              ],
              selected: {_tipoBusqueda},
              onSelectionChanged: (s) => setState(() => _tipoBusqueda = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: _tipoBusqueda == 'disease'
                    ? 'Nombre de la enfermedad (ej: diabetes tipo 2)'
                    : 'Órgano afectado (ej: hígado)',
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _buscar(),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _cargando ? null : _buscar,
              icon: _cargando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(_cargando ? 'Investigando...' : 'Buscar evidencia'),
            ),
            const SizedBox(height: 24),
            Text(
              'Los resultados guardados quedan disponibles al instante la próxima '
              'vez que busques lo mismo, sin volver a consultar internet.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
