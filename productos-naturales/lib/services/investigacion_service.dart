import '../models/disease_query_result.dart';
import 'database_service.dart';
import 'europepmc_service.dart';
import 'gemini_service.dart';

class InvestigacionService {
  final _europePmc = EuropePmcService();
  final _gemini = GeminiService();
  final _db = DatabaseService.instance;

  Future<DiseaseQueryResult> buscar({
    required String query,
    required String queryType,
    bool forzarActualizacion = false,
  }) async {
    if (!forzarActualizacion) {
      final enCache = await _db.buscarEnCache(query, queryType);
      if (enCache != null) return enCache;
    }

    final terminoBusqueda = queryType == 'organ'
        ? '"$query" AND (herbal OR "natural product" OR phytotherapy OR nutraceutical) AND disease'
        : '"$query" AND (herbal OR "natural product" OR phytotherapy OR nutraceutical OR supplement)';

    final articulos = await _europePmc.search(terminoBusqueda, pageSize: 30);

    if (articulos.isEmpty) {
      final vacio = DiseaseQueryResult(
        query: query,
        queryType: queryType,
        organAffected: '',
        diseaseExplanation:
            'No se encontraron estudios científicos sobre "$query" en las fuentes '
            'consultadas (PubMed/Europe PMC). Intenta con otro término (ej. el nombre '
            'en inglés de la enfermedad).',
        products: [],
        createdAt: DateTime.now(),
      );
      await _db.guardar(vacio);
      return vacio;
    }

    final resultado = await _gemini.analizar(
      query: query,
      queryType: queryType,
      articulos: articulos,
    );

    await _db.guardar(resultado);
    return resultado;
  }
}
