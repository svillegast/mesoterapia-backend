import 'dart:math';
import 'package:flutter/material.dart';

/// Dibuja un vaso sanguíneo cuyo diámetro varía según [dilatacion] (0 = muy
/// contraído, 1 = totalmente dilatado), con un brillo/glow, pared con
/// gradiente y partículas fluyendo dentro que representan el flujo
/// sanguíneo / moléculas de óxido nítrico, con estela y variación de tamaño.
class VasoSanguineoPainter extends CustomPainter {
  final double dilatacion;
  final double faseFlujo;
  final Color colorBase;

  VasoSanguineoPainter({
    required this.dilatacion,
    required this.faseFlujo,
    required this.colorBase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final anchoMax = size.height * 0.62;
    final anchoMin = size.height * 0.24;
    final anchoVaso = anchoMin + (anchoMax - anchoMin) * dilatacion;

    final centroY = size.height / 2;
    final rectVaso = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, centroY - anchoVaso / 2, size.width, anchoVaso),
      Radius.circular(anchoVaso / 2),
    );

    final colorPared = Color.lerp(
      const Color(0xFF6B7B8C),
      colorBase,
      dilatacion,
    )!;

    // Resplandor exterior (glow) que crece con la dilatación.
    final paintGlow = Paint()
      ..color = colorBase.withValues(alpha: 0.18 + dilatacion * 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + dilatacion * 14)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rectVaso, paintGlow);

    // Pared del vaso con gradiente vertical (efecto de volumen/tubo).
    final paintPared = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colorPared.withValues(alpha: 0.45),
          colorPared.withValues(alpha: 0.20),
          colorPared.withValues(alpha: 0.45),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rectVaso.outerRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rectVaso, paintPared);

    final paintBorde = Paint()
      ..color = colorPared
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rectVaso, paintBorde);

    // Línea central brillante que sugiere el flujo laminar.
    final paintLineaCentral = Paint()
      ..color = Colors.white.withValues(alpha: 0.10 + dilatacion * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = anchoVaso * 0.06;
    canvas.drawLine(
      Offset(0, centroY),
      Offset(size.width, centroY),
      paintLineaCentral,
    );

    const numParticulas = 10;
    final velocidad = 0.3 + dilatacion * 0.9;

    for (var i = 0; i < numParticulas; i++) {
      final offsetBase = (i / numParticulas + faseFlujo * velocidad) % 1.0;
      final x = offsetBase * size.width;
      final jitter = sin((offsetBase * 2 * pi) + i) * (anchoVaso * 0.16);
      final y = centroY + jitter;

      // Radio con leve pulso individual para que no se vean idénticas.
      final pulso = 0.5 + 0.5 * sin((faseFlujo * 2 * pi) + i * 1.7);
      final radio = (3.0 + dilatacion * 2.8) * (0.85 + pulso * 0.3);

      // Estela detrás de cada partícula (da sensación de movimiento).
      final xEstela = ((offsetBase - 0.04) % 1.0) * size.width;
      if (xEstela < x) {
        final paintEstela = Paint()
          ..color = colorBase.withValues(alpha: 0.18)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(xEstela, y), radio * 0.7, paintEstela);
      }

      // Glow suave detrás de la partícula.
      final paintParticulaGlow = Paint()
        ..color = colorBase.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), radio * 1.6, paintParticulaGlow);

      // Núcleo de la partícula con un pequeño brillo blanco (efecto 3D).
      final paintParticula = Paint()..color = colorBase;
      canvas.drawCircle(Offset(x, y), radio, paintParticula);
      final paintBrillo = Paint()..color = Colors.white.withValues(alpha: 0.55);
      canvas.drawCircle(Offset(x - radio * 0.3, y - radio * 0.3), radio * 0.35, paintBrillo);
    }
  }

  @override
  bool shouldRepaint(covariant VasoSanguineoPainter oldDelegate) {
    return oldDelegate.dilatacion != dilatacion ||
        oldDelegate.faseFlujo != faseFlujo ||
        oldDelegate.colorBase != colorBase;
  }
}
