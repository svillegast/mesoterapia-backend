import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/face_analysis.dart';

const _zoneLabels = {
  'frente':      'Frente',
  'ojos':        'Contorno de ojos',
  'mejillas':    'Mejillas',
  'boca_surcos': 'Surcos / boca',
  'mandibula':   'Mandíbula',
  'luminosidad': 'Luminosidad',
};

class ResultsScreen extends StatelessWidget {
  final FaceAnalysis analysis;
  const ResultsScreen({super.key, required this.analysis});

  Color _hexColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final imgBytes = base64Decode(analysis.reportImageBase64);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Análisis Facial'),
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen reporte
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(imgBytes, fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),

            // Score global
            _SectionTitle('SCORE GLOBAL'),
            const SizedBox(height: 8),
            LinearPercentIndicator(
              lineHeight: 14,
              percent: (analysis.globalScore / 100).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF2A2A2A),
              progressColor: _scoreColor(analysis.globalScore),
              barRadius: const Radius.circular(8),
              center: Text(
                '${analysis.globalScore.toStringAsFixed(0)}/100',
                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Severidad: ${analysis.globalSeverity}',
              style: TextStyle(color: _scoreColor(analysis.globalScore), fontSize: 13),
            ),

            const SizedBox(height: 20),

            // Scores por zona
            _SectionTitle('ZONAS ANALIZADAS'),
            const SizedBox(height: 8),
            ...analysis.zones.entries.map((e) {
              final label = _zoneLabels[e.key] ?? e.key;
              final score = e.value.score;
              final color = _hexColor(e.value.color);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        Text('${score.toStringAsFixed(0)}/100',
                            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearPercentIndicator(
                      lineHeight: 8,
                      percent: (score / 100).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFF2A2A2A),
                      progressColor: color,
                      barRadius: const Radius.circular(6),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // Protocolos recomendados
            if (analysis.protocols.isNotEmpty) ...[
              _SectionTitle('TRATAMIENTOS RECOMENDADOS'),
              const SizedBox(height: 8),
              ...analysis.protocols.map((p) => _ProtocolCard(protocol: p)),
            ],

            // Pack combinado
            if (analysis.combo != null) ...[
              const SizedBox(height: 12),
              _ComboCard(combo: analysis.combo!),
            ],

            const SizedBox(height: 24),

            // WhatsApp disponible próximamente
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E4A2E)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.whatsapp, color: Color(0xFF25D366), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Envío por WhatsApp disponible próximamente',
                      style: TextStyle(color: Color(0xFF66BB6A), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 70) return const Color(0xFFF44336);
    if (score >= 50) return const Color(0xFFFF9800);
    if (score >= 30) return const Color(0xFF8BC34A);
    return const Color(0xFF4CAF50);
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF9E9E9E),
          letterSpacing: 1.2,
        ),
      );
}

class _ProtocolCard extends StatelessWidget {
  final Protocol protocol;
  const _ProtocolCard({required this.protocol});

  @override
  Widget build(BuildContext context) {
    final isPriority = protocol.priority == 'PRIORITARIO';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPriority ? const Color(0xFFF44336) : const Color(0xFF333333),
          width: isPriority ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(protocol.nombre,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              if (isPriority)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('PRIORITARIO',
                      style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${protocol.sesiones} sesiones · ${protocol.duracionMin} min · \$${protocol.precio}/sesión',
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Pack 6 sesiones: \$${protocol.pack6}',
            style: const TextStyle(color: Color(0xFF8BC34A), fontSize: 13, fontWeight: FontWeight.w600),
          ),
          if (protocol.explanations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              protocol.explanations.first,
              style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _ComboCard extends StatelessWidget {
  final ComboSuggestion combo;
  const _ComboCard({required this.combo});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF4A148C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 18),
                SizedBox(width: 6),
                Text('PACK COMBINADO SUGERIDO',
                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            Text(combo.nombre, style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('\$${combo.precioCombo}',
                    style: const TextStyle(
                        color: Color(0xFF8BC34A), fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('(ahorro \$${combo.ahorro})',
                    style: const TextStyle(color: Colors.amber, fontSize: 13)),
              ],
            ),
          ],
        ),
      );
}
