import 'package:flutter/material.dart';

class ConsejosScreen extends StatelessWidget {
  const ConsejosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consejos de práctica')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Estos son consejos generales de bienestar, no una indicación médica '
                'personalizada. Ante cualquier condición de salud, o si algo se siente '
                'mal durante la práctica, consulta a tu médico y detente.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _Seccion(
            titulo: '¿Cuántas veces al día?',
            icono: Icons.repeat,
            items: [
              'Lo habitual en estas prácticas es 2 sesiones al día: una en la '
                  'mañana y otra en la noche.',
              'Si estás empezando, con 1 sesión diaria ya se nota el beneficio '
                  'de la constancia. Puedes sumar la segunda más adelante.',
              'Más no es necesariamente mejor: la clave es la regularidad, no '
                  'la cantidad.',
            ],
          ),
          const _Seccion(
            titulo: '¿Cuánto tiempo por sesión?',
            icono: Icons.hourglass_bottom,
            items: [
              'Primeras 1-2 semanas: 5 minutos por sesión, para acostumbrarte '
                  'a la respiración nasal y al ritmo.',
              'Después: puedes subir a 10-15 minutos si te sientes cómodo/a.',
              'La prueba BOLT te sirve de referencia informal: si tu tiempo '
                  'sube semana a semana, vas por buen camino.',
            ],
          ),
          const _Seccion(
            titulo: 'Orientación general por edad',
            icono: Icons.groups_outlined,
            items: [
              'Adultos en general: 5-15 minutos, 1-2 veces al día, todos los '
                  'días, es un rango razonable y sostenible.',
              'Adultos mayores: empezar con sesiones más cortas (3-5 min) y '
                  'sin forzar las retenciones; ir subiendo solo si se siente bien.',
              'Adolescentes: sesiones cortas (5 min) y siempre con la '
                  'supervisión o el visto bueno de un adulto/médico.',
              'Niños: esta app no está pensada para niños sin supervisión '
                  'directa de un adulto.',
              'Embarazo o alguna condición cardiovascular, respiratoria o '
                  'similar: consultar primero con un médico antes de practicar, '
                  'especialmente las retenciones de aire.',
            ],
          ),
          const _Seccion(
            titulo: '¿Todos los días, todo el año?',
            icono: Icons.calendar_month,
            items: [
              'Sí: como cualquier hábito de bienestar (igual que el ejercicio), '
                  'el beneficio viene de mantenerlo en el tiempo, no de una '
                  'sesión aislada.',
              'Si un día no puedes, no pasa nada: retomas al día siguiente. La '
                  'app cuenta tu racha, pero perder un día no borra el progreso '
                  'acumulado.',
              'No hay "temporada": puedes practicar todo el año, ajustando la '
                  'duración a cómo te sientas.',
            ],
          ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<String> items;

  const _Seccion({required this.titulo, required this.icono, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((texto) => Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(texto)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
