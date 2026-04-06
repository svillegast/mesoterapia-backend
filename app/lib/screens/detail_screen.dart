import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/face_analysis.dart';
import '../models/zone_config.dart';

const _condLabels = {
  'arrugas_frontales':    'Arrugas en la frente',
  'lineas_entrecejo':     'Líneas de entrecejo',
  'patas_gallo':          'Patas de gallo',
  'ojeras':               'Ojeras',
  'bolsas_ojos':          'Bolsas bajo los ojos',
  'parpados_caidos':      'Párpados caídos',
  'mejillas_caidas':      'Pérdida de firmeza en mejillas',
  'perdida_volumen':      'Pérdida de volumen facial',
  'poros_dilatados':      'Poros dilatados',
  'manchas':              'Manchas / pigmentación',
  'surcos_nasogenianos':  'Surcos nasolabiales',
  'lineas_marioneta':     'Líneas marioneta',
  'arrugas_periorales':   'Arrugas alrededor de labios',
  'mandibula_indefinida': 'Contorno mandibular difuso',
  'doble_menton':         'Papada / doble mentón',
  'piel_opaca':           'Piel sin luminosidad',
  'tono_desigual':        'Tono de piel desigual',
  'textura_irregular':    'Textura cutánea irregular',
};


// ── DetailScreen ──────────────────────────────────────────────────────────────
class DetailScreen extends StatelessWidget {
  final ConsumerZone zone;
  final double score;
  final FaceAnalysis analysis;
  final Protocol? protocol;

  const DetailScreen({
    super.key,
    required this.zone,
    required this.score,
    required this.analysis,
    required this.protocol,
  });

  @override
  Widget build(BuildContext context) {
    final color       = scoreColor(score);
    final zoneImgB64  = analysis.zoneImages[zone.imageZone] ?? '';
    final faceImgB64  = analysis.faceImageBase64;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // ── Fondo: cara difuminada ──────────────────────────────────────
        if (faceImgB64.isNotEmpty)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Image.memory(
                base64Decode(faceImgB64),
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.35),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),

        // ── Contenido ───────────────────────────────────────────────────
        SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Panel izquierdo: foto de zona ───────────────────────
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Botón volver
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              color: Colors.white.withOpacity(0.12),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.arrow_back_ios, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Volver', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                              ]),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Nombre de la zona
                      Text(
                        zone.label.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Análisis de zona',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // Foto recortada de la zona
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: zoneImgB64.isNotEmpty
                              ? Image.memory(
                                  base64Decode(zoneImgB64),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                              : Container(
                                  color: Colors.white.withOpacity(0.05),
                                  child: Icon(Icons.face, color: color.withOpacity(0.4), size: 60),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Score circle grande
                      Row(children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.12),
                            border: Border.all(color: color, width: 2.5),
                            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12)],
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('${score.round()}',
                                style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold, height: 1)),
                            Text('/100', style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
                          ]),
                        ),
                        const SizedBox(width: 14),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(severityLabel(score),
                              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${zone.label} · ${score.round()}/100',
                              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
                        ]),
                      ]),
                    ],
                  ),
                ),
              ),

              // ── Panel derecho: análisis + protocolo ─────────────────
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        color: Colors.white.withOpacity(0.07),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Qué significa el score
                              _SectionLabel('QUÉ SIGNIFICA ESTE SCORE'),
                              const SizedBox(height: 8),
                              _GlassPanel(
                                color: color,
                                child: Text(severityDesc(score),
                                    style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 13, height: 1.6)),
                              ),
                              const SizedBox(height: 18),

                              // Análisis realizados
                              _SectionLabel('ANÁLISIS REALIZADOS POR LA IA'),
                              const SizedBox(height: 8),
                              _GlassPanel(
                                color: const Color(0xFF7B61FF),
                                child: Column(
                                  children: zone.conditionKeys.map((c) {
                                    final s = analysis.conditionScores[c] ?? 0;
                                    final detected = s >= 30;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                      child: Row(children: [
                                        Icon(
                                          detected ? Icons.manage_search_rounded : Icons.check_circle_outline,
                                          color: detected ? scoreColor(s) : const Color(0xFF4CAF50),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(_condLabels[c] ?? c,
                                              style: TextStyle(
                                                color: detected ? Colors.white : const Color(0xFF9E9E9E),
                                                fontSize: 13,
                                              )),
                                        ),
                                        if (detected)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: scoreColor(s).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text('${s.round()}',
                                                style: TextStyle(color: scoreColor(s), fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                      ]),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Protocolo de mesoterapia virtual
                              if (protocol != null) ...[
                                _SectionLabel('PROTOCOLO DE MESOTERAPIA VIRTUAL'),
                                const SizedBox(height: 8),
                                _GlassPanel(
                                  color: color,
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      const Icon(Icons.spa_outlined, color: Color(0xFF7B61FF), size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(protocol!.nombre,
                                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                      ),
                                    ]),
                                    const SizedBox(height: 10),
                                    Wrap(spacing: 6, runSpacing: 6, children: [
                                      _Tag(Icons.repeat_outlined, '${protocol!.sesiones} ses.'),
                                      _Tag(Icons.access_time_outlined, '${protocol!.duracionMin} min'),
                                      _Tag(Icons.attach_money, '\$${protocol!.precio}/ses.'),
                                    ]),
                                    const SizedBox(height: 12),
                                    // Pack destacado
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7B61FF).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFF7B61FF).withOpacity(0.35)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Pack 6 sesiones',
                                              style: TextStyle(color: Color(0xFF7B61FF), fontSize: 13)),
                                          Text('\$${protocol!.pack6}',
                                              style: const TextStyle(
                                                  color: Color(0xFF7B61FF), fontSize: 24, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    if (protocol!.explanations.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(protocol!.explanations.first,
                                          style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 12, height: 1.6)),
                                    ],
                                  ]),
                                ),
                              ] else
                                _GlassPanel(
                                  color: const Color(0xFF4CAF50),
                                  child: const Row(children: [
                                    Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 18),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Esta zona está en buen estado. No requiere tratamiento actualmente.',
                                        style: TextStyle(color: Color(0xFF4CAF50), fontSize: 13),
                                      ),
                                    ),
                                  ]),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF9E9E9E),
      fontSize: 10,
      letterSpacing: 1.4,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final Color color;
  const _GlassPanel({required this.child, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.22)),
    ),
    child: child,
  );
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Tag(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: const Color(0xFF9E9E9E)),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
    ]),
  );
}
