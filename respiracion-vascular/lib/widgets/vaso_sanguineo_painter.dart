import 'dart:math';
import 'package:flutter/material.dart';

/// Dibuja un vaso sanguíneo cuyo diámetro varía según [dilatacion] (0 = muy
/// contraído, 1 = totalmente dilatado), con partículas fluyendo dentro que
/// representan el flujo sanguíneo / moléculas de óxido nítrico.
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
    final anchoMax = size.height * 0.6;
    final anchoMin = size.height * 0.22;
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

    final paintPared = Paint()
      ..color = colorPared.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rectVaso, paintPared);

    final paintBorde = Paint()
      ..color = colorPared
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rectVaso, paintBorde);

    const numParticulas = 8;
    final velocidad = 0.3 + dilatacion * 0.9;
    final paintParticula = Paint()..color = colorBase;

    for (var i = 0; i < numParticulas; i++) {
      final offsetBase = (i / numParticulas + faseFlujo * velocidad) % 1.0;
      final x = offsetBase * size.width;
      final jitter = sin((offsetBase * 2 * pi) + i) * (anchoVaso * 0.18);
      final y = centroY + jitter;
      final radio = 3.0 + dilatacion * 2.5;
      canvas.drawCircle(Offset(x, y), radio, paintParticula);
    }
  }

  @override
  bool shouldRepaint(covariant VasoSanguineoPainter oldDelegate) {
    return oldDelegate.dilatacion != dilatacion ||
        oldDelegate.faseFlujo != faseFlujo ||
        oldDelegate.colorBase != colorBase;
  }
}
