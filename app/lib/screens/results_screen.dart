import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/face_analysis.dart';
import '../models/zone_config.dart';
import 'detail_screen.dart';

// ── Pantalla de resultados ────────────────────────────────────────────────────
class ResultsScreen extends StatefulWidget {
  final FaceAnalysis analysis;
  const ResultsScreen({super.key, required this.analysis});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  String? _activeKey;
  late AnimationController _lineAnim;
  late Animation<double> _lineFade;

  FaceAnalysis get a => widget.analysis;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _lineAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _lineFade = CurvedAnimation(parent: _lineAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _lineAnim.dispose();
    super.dispose();
  }

  void _tap(String key) async {
    if (_activeKey == key) {
      _lineAnim.reverse();
      setState(() => _activeKey = null);
      return;
    }
    setState(() => _activeKey = key);
    await _lineAnim.forward(from: 0);
    if (!mounted) return;

    final zone = kZones.firstWhere((z) => z.key == key);
    final score = computeZoneScore(a, zone);
    final protocol = _protocolFor(zone);

    // ignore: use_build_context_synchronously
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: DetailScreen(
            zone: zone,
            score: score,
            analysis: a,
            protocol: protocol,
          ),
        ),
      ),
    );
    if (mounted) {
      _lineAnim.reverse();
      setState(() => _activeKey = null);
    }
  }

  Protocol? _protocolFor(ConsumerZone zone) {
    Protocol? best;
    double bestScore = 0;
    for (final p in a.protocols) {
      final hasMatch = p.activeConditions.any((c) => zone.conditionKeys.contains(c));
      if (hasMatch && p.triggerScore > bestScore) {
        best = p;
        bestScore = p.triggerScore;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (ctx, constraints) {
        final W = constraints.maxWidth;
        final H = constraints.maxHeight;

        return Stack(children: [
          // ── Cara limpia (sin overlays) ─────────────────────────────────
          if (a.faceImageBase64.isNotEmpty)
            Positioned.fill(
              child: Image.memory(
                base64Decode(a.faceImageBase64),
                fit: BoxFit.cover,
              ),
            ),

          // ── Gradiente lateral para legibilidad ────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.45),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.45),
                  ],
                  stops: const [0, 0.20, 0.80, 1.0],
                ),
              ),
            ),
          ),

          // ── Líneas dinámicas (solo cuando hay círculo activo) ──────────
          AnimatedBuilder(
            animation: _lineFade,
            builder: (_, __) => CustomPaint(
              size: Size(W, H),
              painter: _LeaderPainter(
                W: W, H: H,
                activeKey: _activeKey,
                opacity: _lineFade.value,
                zoneScores: {
                  for (final z in kZones) z.key: computeZoneScore(a, z)
                },
              ),
            ),
          ),

          // ── Círculos flotantes glassmorphism ───────────────────────────
          ...kZones.map((z) {
            final pos = kCirclePos[z.key]!;
            final score = computeZoneScore(a, z);
            final isActive = _activeKey == z.key;
            return Positioned(
              left: W * pos.$1 - 36,
              top:  H * pos.$2 - 36,
              child: GestureDetector(
                onTap: () => _tap(z.key),
                child: _GlassCircle(
                  label: z.label,
                  score: score,
                  isActive: isActive,
                ),
              ),
            );
          }),

          // ── AppBar minimalista ─────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: _GlassBar(analysis: a, onWhatsApp: _shareWhatsApp, onBack: () => Navigator.pop(context)),
          ),
        ]);
      }),
    );
  }

  Future<void> _shareWhatsApp() async {
    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(a.whatsappText)}');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

// ── Círculo glassmorphism ─────────────────────────────────────────────────────
class _GlassCircle extends StatelessWidget {
  final String label;
  final double score;
  final bool isActive;
  const _GlassCircle({required this.label, required this.score, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(score);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 72, height: 72,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? color.withOpacity(0.22)
                  : Colors.white.withOpacity(0.08),
              border: Border.all(color: color, width: isActive ? 2.8 : 2.0),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(isActive ? 0.55 : 0.30),
                  blurRadius: isActive ? 16 : 8,
                  spreadRadius: isActive ? 2 : 0,
                ),
              ],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(
                '${score.round()}',
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1,
                  shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 8)],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Líneas dinámicas ──────────────────────────────────────────────────────────
class _LeaderPainter extends CustomPainter {
  final double W, H, opacity;
  final String? activeKey;
  final Map<String, double> zoneScores;

  _LeaderPainter({
    required this.W, required this.H, required this.opacity,
    required this.activeKey, required this.zoneScores,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (activeKey == null || opacity == 0) return;
    final pos    = kCirclePos[activeKey!];
    final target = kZoneTarget[activeKey!];
    if (pos == null || target == null) return;

    final score = zoneScores[activeKey!] ?? 0;
    final color = scoreColor(score);

    final from = Offset(W * pos.$1, H * pos.$2);
    final to   = Offset(W * target.$1, H * target.$2);

    // Línea principal
    canvas.drawLine(
      from, to,
      Paint()
        ..color = color.withOpacity(opacity * 0.85)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Halo en el punto de destino
    canvas.drawCircle(to, 9 * opacity,
        Paint()..color = color.withOpacity(opacity * 0.25));
    // Punto central
    canvas.drawCircle(to, 5 * opacity,
        Paint()..color = color.withOpacity(opacity));
  }

  @override
  bool shouldRepaint(covariant _LeaderPainter old) =>
      old.opacity != opacity || old.activeKey != activeKey;
}

// ── Barra superior glassmorphism ──────────────────────────────────────────────
class _GlassBar extends StatelessWidget {
  final FaceAnalysis analysis;
  final VoidCallback onWhatsApp;
  final VoidCallback onBack;
  const _GlassBar({required this.analysis, required this.onWhatsApp, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(analysis.globalScore);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          color: Colors.black.withOpacity(0.45),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
              onPressed: onBack,
            ),
            const Text('Análisis Facial IA',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            // Score global
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Text('Score ${analysis.globalScore.round()}/100 · ${analysis.globalSeverity}',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onWhatsApp,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat, color: Colors.white, size: 13),
                  SizedBox(width: 4),
                  Text('Compartir', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
