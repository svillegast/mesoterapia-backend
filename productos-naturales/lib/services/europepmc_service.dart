import 'dart:convert';
import 'package:http/http.dart' as http;

class EuropePmcArticle {
  final String id;
  final String source;
  final String title;
  final String? abstractText;
  final int? year;

  EuropePmcArticle({
    required this.id,
    required this.source,
    required this.title,
    this.abstractText,
    this.year,
  });
}

class EuropePmcService {
  static const _baseUrl =
      'https://www.ebi.ac.uk/europepmc/webservices/rest/search';

  Future<List<EuropePmcArticle>> search(String query, {int pageSize = 30}) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'query': query,
      'format': 'json',
      'resultType': 'core',
      'pageSize': '$pageSize',
      'sort': 'CITED desc',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Europe PMC respondió ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['resultList']?['result'] as List?) ?? [];

    return results
        .map((r) {
          final map = r as Map<String, dynamic>;
          return EuropePmcArticle(
            id: map['id']?.toString() ?? '',
            source: map['source']?.toString() ?? 'MED',
            title: map['title']?.toString() ?? '',
            abstractText: map['abstractText']?.toString(),
            year: int.tryParse('${map['pubYear'] ?? ''}'),
          );
        })
        .where((a) => a.id.isNotEmpty && a.title.isNotEmpty)
        .toList();
  }
}
