import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sesion.dart';
import '../models/tecnica_respiracion.dart';
import '../services/database_service.dart';
import '../widgets/vaso_sanguineo_painter.dart';

class RespiracionScreen extends StatefulWidget {
  const RespiracionScreen({super.key});

  @override
  State<RespiracionScreen> createState() => _RespiracionScreenState();
}

class _RespiracionScreenState extends State<RespiracionScreen> {
  TecnicaRespiracion _tecnica = tecnicasDisponibles.first;
  int _minutosSeleccionados = 5;
  bool _enSesion = false;

  void _iniciarSesion() {
    setState(() => _enSesion = true);
  }

  void _terminarSesion() {
    setState(() => _enSesion = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_enSesion) {
      return _SesionActivaView(
        tecnica: _tecnica,
        duracionTotalSegundos: _minutosSeleccionados * 60,
        onTerminar: _terminarSesion,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva sesión')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Técnica', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...tecnicasDisponibles.map((t) => Card(
                color: t.id == _tecnica.id ? Theme.of(context).colorScheme.primaryContainer : null,
                child: ListTile(
                  title: Text(t.nombre),
                  subtitle: Text(t.descripcion),
                  onTap: () => setState(() => _tecnica = t),
                ),
              )),
          const SizedBox(height: 16),
          Text('Duración', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [5, 10, 15].map((m) {
              return ChoiceChip(
                label: Text('$m min'),
                selected: _minutosSeleccionados == m,
                onSelected: (_) => setState(() => _minutosSeleccionados = m),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _iniciarSesion,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Comenzar'),
          ),
        ],
      ),
    );
  }
}

class _SesionActivaView extends StatefulWidget {
  final TecnicaRespiracion tecnica;
  final int duracionTotalSegundos;
  final VoidCallback onTerminar;

  const _SesionActivaView({
    required this.tecnica,
    required this.duracionTotalSegundos,
    required this.onTerminar,
  });

  @override
  State<_SesionActivaView> createState() => _SesionActivaViewState();
}

class _SesionActivaViewState extends State<_SesionActivaView> with TickerProviderStateMixin {
  late final AnimationController _faseController;
  late final Animation<double> _dilatacion;
  late final AnimationController _flujoController;

  Timer? _cronometro;
  int _segundosRestantes = 0;
  bool _completada = false;

  @override
  void initState() {
    super.initState();
    _segundosRestantes = widget.duracionTotalSegundos;

    final t = widget.tecnica;
    final totalMs = t.duracionCicloMs;
    final pesoInhalar = t.inhalarMs / totalMs * 100;
    final pesoRetener = t.retenerMs / totalMs * 100;
    final pesoExhalar = t.exhalarMs / totalMs * 100;

    final secuencia = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: pesoInhalar,
      ),
      if (t.retenerMs > 0)
        TweenSequenceItem(tween: ConstantTween(1.0), weight: pesoRetener),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: pesoExhalar,
      ),
    ]);

    _faseController = AnimationController(vsync: this, duration: Duration(milliseconds: totalMs))..repeat();
    _dilatacion = secuencia.animate(_faseController);

    _flujoController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

    _cronometro = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    setState(() => _segundosRestantes--);
    if (_segundosRestantes <= 0) {
      _finalizar();
    }
  }

  Future<void> _finalizar() async {
    if (_completada) return;
    _completada = true;
    _cronometro?.cancel();
    _faseController.stop();
    _flujoController.stop();

    await DatabaseService.instance.guardarSesion(Sesion(
      fecha: DateTime.now(),
      tecnicaId: widget.tecnica.id,
      duracionSegundos: widget.duracionTotalSegundos,
    ));

    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Sesión completada'),
          content: Text(
            'Practicaste ${widget.tecnica.nombre} durante ${widget.duracionTotalSegundos ~/ 60} minutos. '
            'Tu circulación y niveles de óxido nítrico se benefician con la constancia.',
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Listo')),
          ],
        ),
      );
      widget.onTerminar();
    }
  }

  String _faseTexto(double valor) {
    final t = widget.tecnica;
    final ms = valor * t.duracionCicloMs;
    if (ms < t.inhalarMs) return 'Inhala por la nariz';
    if (ms < t.inhalarMs + t.retenerMs) return 'Mantén';
    return t.conTarareo ? 'Exhala tarareando' : 'Exhala';
  }

  @override
  void dispose() {
    _cronometro?.cancel();
    _faseController.dispose();
    _flujoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutos = (_segundosRestantes ~/ 60).toString().padLeft(2, '0');
    final segundos = (_segundosRestantes % 60).toString().padLeft(2, '0');
    final colorBase = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tecnica.nombre),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _cronometro?.cancel();
            widget.onTerminar();
          },
        ),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_faseController, _flujoController]),
        builder: (context, _) {
          final dilatacion = _dilatacion.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('$minutos:$segundos',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Center(
                  child: Transform.scale(
                    scale: 0.7 + dilatacion * 0.5,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            colorBase.withValues(alpha: 0.55 + dilatacion * 0.25),
                            colorBase.withValues(alpha: 0.22 + dilatacion * 0.18),
                            colorBase.withValues(alpha: 0.05),
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorBase.withValues(alpha: 0.35 + dilatacion * 0.25),
                            blurRadius: 30 + dilatacion * 30,
                            spreadRadius: 4 + dilatacion * 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.25 + dilatacion * 0.25),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _faseTexto(_faseController.value),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Container(
                height: 100,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CustomPaint(
                  painter: VasoSanguineoPainter(
                    dilatacion: dilatacion,
                    faseFlujo: _flujoController.value,
                    colorBase: colorBase,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
