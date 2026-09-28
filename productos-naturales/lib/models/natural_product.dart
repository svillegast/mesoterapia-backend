import 'study.dart';

class NaturalProduct {
  final int? id;
  final String name;
  final String effectSummary;
  final double starRating;
  final String evidenceLevel;
  final List<Study> studies;

  NaturalProduct({
    this.id,
    required this.name,
    required this.effectSummary,
    required this.starRating,
    required this.evidenceLevel,
    required this.studies,
  });

  factory NaturalProduct.fromGeminiJson(Map<String, dynamic> json) {
    final studiesJson = (json['studies'] as List?) ?? [];
    final rating = json['star_rating'];
    final ratingDouble =
        rating is num ? rating.toDouble() : double.tryParse('$rating') ?? 0.0;
    return NaturalProduct(
      name: json['name']?.toString() ?? '',
      effectSummary: json['effect_summary']?.toString() ?? '',
      starRating: ratingDouble.clamp(0.0, 5.0).toDouble(),
      evidenceLevel: json['evidence_level']?.toString() ?? '',
      studies: studiesJson
          .map((s) => Study.fromGeminiJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
