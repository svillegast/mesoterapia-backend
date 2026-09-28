class Study {
  final String source;
  final String externalId;
  final String title;
  final int? year;
  final String studyType;
  final int? sampleSize;
  final String url;

  Study({
    required this.source,
    required this.externalId,
    required this.title,
    this.year,
    required this.studyType,
    this.sampleSize,
    required this.url,
  });

  Map<String, dynamic> toMap() => {
        'source': source,
        'external_id': externalId,
        'title': title,
        'year': year,
        'study_type': studyType,
        'sample_size': sampleSize,
        'url': url,
      };

  factory Study.fromGeminiJson(Map<String, dynamic> json) {
    final source = json['source']?.toString() ?? 'MED';
    final externalId = json['external_id']?.toString() ?? '';
    return Study(
      source: source,
      externalId: externalId,
      title: json['title']?.toString() ?? '',
      year: int.tryParse('${json['year'] ?? ''}'),
      studyType: json['study_type']?.toString() ?? 'other',
      sampleSize: int.tryParse('${json['sample_size'] ?? ''}'),
      url: json['url']?.toString() ??
          'https://europepmc.org/article/$source/$externalId',
    );
  }
}
