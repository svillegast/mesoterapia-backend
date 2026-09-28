import 'package:flutter/material.dart';
import '../services/progreso_service.dart';

class ProgresoScreen extends StatefulWidget {
  const ProgresoScreen({super.key});

  @override
  State<ProgresoScreen> createState() => _ProgresoScreenState();
}

class _ProgresoScreenState extends State<ProgresoScreen> {
  final _servicio = ProgresoService();
  ResultadoProgreso? _resultado;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final r = await _servicio.calcular();
    if (mounted) setState(() => _resultado = r);
  }

  @override
  Widget build(BuildContext context) {
    final r = _resultado;
    return Scaffold(
      appBar: AppBar(title: const Text('Progreso')),
      body: r == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TarjetaMetrica(
                          icono: Icons.local_fire_department,
                          titulo: 'Racha',
                          valor: '${r.rachaDias} día${r.rachaDias == 1 ? '' : 's'}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TarjetaMetrica(
                          icono: Icons.timer_outlined,
                          titulo: 'Total practicado',
                          valor: '${r.totalMinutos} min',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _TarjetaMetrica(
                    icono: Icons.spa_outlined,
                    titulo: 'Sesiones completadas',
                    valor: '${r.totalSesiones}',
                  ),
                  const SizedBox(height: 24),
                  Text('Nivel actual', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.nivelActual.nombre,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(value: r.progresoNivel),
                          const SizedBox(height: 8),
                          if (r.siguienteNivel != null)
                            Text(
                              'Siguiente: ${r.siguienteNivel!.nombre} '
                              '(${r.siguienteNivel!.minutosMinimos} min acumulados)',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          else
                            const Text('¡Nivel máximo alcanzado!'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Niveles', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...niveles.map((n) {
                    final alcanzado = r.totalMinutos >= n.minutosMinimos;
                    return ListTile(
                      leading: Icon(
                        alcanzado ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: alcanzado ? Colors.green : null,
                      ),
                      title: Text(n.nombre),
                      subtitle: Text('${n.minutosMinimos} min acumulados'),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _TarjetaMetrica extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _TarjetaMetrica({required this.icono, required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(titulo, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(valor, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
