class ConditionScore {
  final String condition;
  final double score;
  final String severity;
  final String color;

  const ConditionScore({
    required this.condition,
    required this.score,
    required this.severity,
    required this.color,
  });

  factory ConditionScore.fromJson(Map<String, dynamic> j) => ConditionScore(
        condition: j['condition'] ?? '',
        score: (j['score'] ?? 0).toDouble(),
        severity: j['severity'] ?? 'Óptima',
        color: j['color'] ?? '#4CAF50',
      );
}

class ZoneScore {
  final String zone;
  final double score;
  final String severity;
  final String color;

  const ZoneScore({
    required this.zone,
    required this.score,
    required this.severity,
    required this.color,
  });

  factory ZoneScore.fromJson(String zone, Map<String, dynamic> j) => ZoneScore(
        zone: zone,
        score: (j['score'] ?? 0).toDouble(),
        severity: j['severity'] ?? 'Óptima',
        color: j['color'] ?? '#4CAF50',
      );
}

class Protocol {
  final String id;
  final String nombre;
  final double triggerScore;
  final String priority;
  final int precio;
  final int pack6;
  final int? pack10;
  final String sesiones;
  final int duracionMin;
  final List<String> activeConditions;
  final List<String> explanations;

  const Protocol({
    required this.id,
    required this.nombre,
    required this.triggerScore,
    required this.priority,
    required this.precio,
    required this.pack6,
    this.pack10,
    required this.sesiones,
    required this.duracionMin,
    required this.activeConditions,
    required this.explanations,
  });

  factory Protocol.fromJson(Map<String, dynamic> j) => Protocol(
        id: j['protocol_id'] ?? '',
        nombre: j['nombre'] ?? '',
        triggerScore: (j['trigger_score'] ?? 0).toDouble(),
        priority: j['priority'] ?? 'Recomendado',
        precio: j['precio'] ?? 0,
        pack6: j['pack6'] ?? 0,
        pack10: j['pack10'],
        sesiones: j['sesiones'] ?? '',
        duracionMin: j['duracion_min'] ?? 0,
        activeConditions: List<String>.from(j['active_conditions'] ?? []),
        explanations: List<String>.from(j['explanations'] ?? []),
      );
}

class ComboSuggestion {
  final String nombre;
  final int precioSuelto;
  final int precioCombo;
  final int ahorro;

  const ComboSuggestion({
    required this.nombre,
    required this.precioSuelto,
    required this.precioCombo,
    required this.ahorro,
  });

  factory ComboSuggestion.fromJson(Map<String, dynamic> j) => ComboSuggestion(
        nombre: j['nombre'] ?? '',
        precioSuelto: j['precio_suelto'] ?? 0,
        precioCombo: j['precio_combo'] ?? 0,
        ahorro: j['ahorro'] ?? 0,
      );
}

class FaceAnalysis {
  final double globalScore;
  final String globalSeverity;
  final Map<String, ZoneScore> zones;
  final List<Protocol> protocols;
  final ComboSuggestion? combo;
  final String reportImageBase64;
  final String whatsappText;
  final DateTime analyzedAt;

  const FaceAnalysis({
    required this.globalScore,
    required this.globalSeverity,
    required this.zones,
    required this.protocols,
    this.combo,
    required this.reportImageBase64,
    required this.whatsappText,
    required this.analyzedAt,
  });

  factory FaceAnalysis.fromJson(Map<String, dynamic> j) {
    final scoresData = j['scores'] as Map<String, dynamic>? ?? {};
    final zonesData = scoresData['zones'] as Map<String, dynamic>? ?? {};
    final treatmentPlan = j['treatment_plan'] as Map<String, dynamic>? ?? {};
    final protocols = (treatmentPlan['protocols'] as List? ?? [])
        .map((p) => Protocol.fromJson(p as Map<String, dynamic>))
        .toList();
    final comboData = treatmentPlan['combo_suggestion'] as Map<String, dynamic>?;

    return FaceAnalysis(
      globalScore: (scoresData['global'] ?? 0).toDouble(),
      globalSeverity: scoresData['global_severity'] ?? 'Leve',
      zones: zonesData.map(
        (k, v) => MapEntry(k, ZoneScore.fromJson(k, v as Map<String, dynamic>)),
      ),
      protocols: protocols,
      combo: (comboData != null && comboData.isNotEmpty)
          ? ComboSuggestion.fromJson(comboData)
          : null,
      reportImageBase64: j['report_image_base64'] ?? '',
      whatsappText: j['whatsapp_text'] ?? '',
      analyzedAt: DateTime.now(),
    );
  }
}
