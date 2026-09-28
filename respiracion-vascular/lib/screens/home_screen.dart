import 'package:flutter/material.dart';
import 'bolt_screen.dart';
import 'consejos_screen.dart';
import 'progreso_screen.dart';
import 'respiracion_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Respiración Vascular')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TarjetaModulo(
            icono: Icons.air,
            titulo: 'Respirar',
            subtitulo: 'Sesión guiada de respiración cadenciada o tarareo',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RespiracionScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _TarjetaModulo(
            icono: Icons.timer_outlined,
            titulo: 'Prueba BOLT',
            subtitulo: 'Mide tu tolerancia al CO2 en segundos',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BoltScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _TarjetaModulo(
            icono: Icons.trending_up,
            titulo: 'Progreso',
            subtitulo: 'Racha, minutos totales y nivel alcanzado',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProgresoScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _TarjetaModulo(
            icono: Icons.tips_and_updates_outlined,
            titulo: 'Consejos de práctica',
            subtitulo: 'Frecuencia, duración y orientación por edad',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConsejosScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaModulo extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _TarjetaModulo({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icono, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
