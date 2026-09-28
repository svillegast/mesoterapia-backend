import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/natural_product.dart';
import '../widgets/star_rating.dart';

class ProductDetailScreen extends StatelessWidget {
  final NaturalProduct producto;

  const ProductDetailScreen({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(producto.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StarRating(rating: producto.starRating, size: 28),
          const SizedBox(height: 12),
          Text(producto.evidenceLevel, style: Theme.of(context).textTheme.titleSmall),
          const Divider(height: 32),
          Text(producto.effectSummary),
          const Divider(height: 32),
          Text('Estudios que respaldan esta evidencia',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...producto.studies.map((estudio) => Card(
                child: ListTile(
                  title: Text(estudio.title),
                  subtitle: Text(
                    '${estudio.studyType} · ${estudio.year ?? "año no especificado"}'
                    '${estudio.sampleSize != null ? " · n=${estudio.sampleSize}" : ""}',
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => launchUrl(
                    Uri.parse(estudio.url),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              )),
          const SizedBox(height: 24),
          const Card(
            color: Color(0xFFFFF3E0),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '⚠️ Esta información es de apoyo educativo/científico, generada '
                'automáticamente a partir de resúmenes de estudios, y no reemplaza '
                'el criterio clínico profesional. Verificar posibles interacciones '
                'con medicamentos antes de recomendar cualquier producto natural, y '
                'revisar el estudio original antes de citarlo formalmente.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
