import 'natural_product.dart';

class DiseaseQueryResult {
  final int? id;
  final String query;
  final String queryType;
  final String organAffected;
  final String diseaseExplanation;
  final List<NaturalProduct> products;
  final DateTime createdAt;

  DiseaseQueryResult({
    this.id,
    required this.query,
    required this.queryType,
    required this.organAffected,
    required this.diseaseExplanation,
    required this.products,
    required this.createdAt,
  });

  factory DiseaseQueryResult.fromGeminiJson(
    String query,
    String queryType,
    Map<String, dynamic> json,
  ) {
    final productsJson = (json['products'] as List?) ?? [];
    final products = productsJson
        .map((p) => NaturalProduct.fromGeminiJson(p as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.starRating.compareTo(a.starRating));

    return DiseaseQueryResult(
      query: query,
      queryType: queryType,
      organAffected: json['organ_affected']?.toString() ?? '',
      diseaseExplanation: json['disease_explanation']?.toString() ?? '',
      products: products,
      createdAt: DateTime.now(),
    );
  }
}
