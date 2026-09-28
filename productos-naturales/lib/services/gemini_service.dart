import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';
import '../models/disease_query_result.dart';
import 'europepmc_service.dart';

class GeminiService {
  static const _model = 'gemini-2.0-flash';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  Future<DiseaseQueryResult> analizar({
    required String query,
    required String queryType,
    required List<EuropePmcArticle> articulos,
  }) async {
    final uri = Uri.parse('$_baseUrl?key=${Secrets.geminiApiKey}');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': _construirPrompt(query, queryType, articulos)}
            ]
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.2,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini respondió ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final candidates = body['candidates'] as List?;
    final text = candidates == null || candidates.isEmpty
        ? null
        : (candidates[0]['content']?['parts']?[0]?['text'] as String?);

    if (text == null) {
      throw Exception('Gemini no devolvió contenido analizable: ${response.body}');
    }

    final json = jsonDecode(text) as Map<String, dynamic>;
    return DiseaseQueryResult.fromGeminiJson(query, queryType, json);
  }

  String _construirPrompt(
    String query,
    String queryType,
    List<EuropePmcArticle> articulos,
  ) {
    final estudiosTexto = articulos.take(30).map((a) {
      final resumen = (a.abstractText ?? 'sin resumen disponible').replaceAll('\n', ' ');
      return '- ID: ${a.source}:${a.id} | Año: ${a.year ?? "?"} | Título: ${a.title}\n'
          '  Resumen: $resumen';
    }).join('\n\n');

    final tipoTexto = queryType == 'organ' ? 'el órgano' : 'la enfermedad';

    return '''
Eres un asesor científico experto en fitoterapia y medicina basada en evidencia. Un profesional de salud te consulta sobre "$query" ($tipoTexto). A continuación tienes resúmenes reales de estudios científicos encontrados en PubMed/Europe PMC sobre este tema.

ESTUDIOS ENCONTRADOS:
$estudiosTexto

TAREA: Analiza SOLO la evidencia presente en estos resúmenes (no inventes estudios ni datos que no estén aquí). Responde en JSON con esta estructura exacta:

{
  "organ_affected": "órgano principal afectado por esta enfermedad, en español",
  "disease_explanation": "explicación breve en español de qué le hace esta enfermedad a ese órgano",
  "products": [
    {
      "name": "nombre del producto natural o compuesto, en español",
      "effect_summary": "explicación en español de cómo ayudaría, según los estudios",
      "star_rating": numero del 1 al 5 (puede ser decimal, ej 3.5),
      "evidence_level": "descripción breve del nivel de evidencia en español",
      "studies": [
        {
          "source": "PMC o MED según corresponda",
          "external_id": "el ID tal como aparece arriba",
          "title": "título original del estudio",
          "year": año como número,
          "study_type": "meta_analysis|systematic_review|rct|cohort|animal|in_vitro|other",
          "sample_size": número de participantes si se menciona, o null,
          "url": "https://europepmc.org/article/{source}/{external_id}"
        }
      ]
    }
  ]
}

Reglas para la calificación de estrellas (star_rating):
- 5 estrellas: múltiples meta-análisis o revisiones sistemáticas con resultados consistentes.
- 4 estrellas: al menos un ensayo clínico aleatorizado (RCT) con buen tamaño de muestra, o varios RCTs pequeños consistentes.
- 3 estrellas: uno o pocos RCTs pequeños, o estudios de cohorte/observacionales consistentes.
- 2 estrellas: solo estudios en animales o in vitro, sin evidencia humana todavía.
- 1 estrella: evidencia muy preliminar, contradictoria, o de un solo estudio pequeño.

Ordena "products" de mayor a menor star_rating. Cada estudio citado en "studies" debe ser uno de los que aparecen arriba (mismo source y external_id) — no inventes IDs nuevos. Si un producto no tiene ningún estudio real en la lista de arriba, no lo incluyas. Si no encuentras ningún producto natural con evidencia relevante, devuelve "products": [].
''';
  }
}
