import 'package:flutter/material.dart';
import '../models/disease_query_result.dart';
import '../widgets/star_rating.dart';
import 'product_detail_screen.dart';

class ResultsScreen extends StatelessWidget {
  final DiseaseQueryResult resultado;

  const ResultsScreen({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(resultado.query)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (resultado.organAffected.isNotEmpty) ...[
            Text('Órgano afectado: ${resultado.organAffected}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
          ],
          if (resultado.diseaseExplanation.isNotEmpty) ...[
            Text(resultado.diseaseExplanation),
            const SizedBox(height: 24),
          ],
          if (resultado.products.isEmpty)
            const Text(
              'No se encontraron productos naturales con evidencia científica '
              'suficiente para esta búsqueda en las fuentes consultadas.',
            )
          else
            Text('Productos naturales encontrados (${resultado.products.length})',
                style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...resultado.products.map((producto) => Card(
                child: ListTile(
                  title: Text(producto.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      StarRating(rating: producto.starRating),
                      const SizedBox(height: 4),
                      Text(producto.evidenceLevel,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(producto: producto),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
