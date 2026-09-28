import 'package:flutter/material.dart';

class DescargoScreen extends StatelessWidget {
  final VoidCallback onAceptar;

  const DescargoScreen({super.key, required this.onAceptar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Antes de empezar')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                children: const [
                  Icon(Icons.info_outline, size: 40),
                  SizedBox(height: 16),
                  Text(
                    'Esta aplicación es una herramienta personal de bienestar, no un '
                    'dispositivo médico ni un tratamiento.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Las técnicas de respiración guiada (respiración nasal cadenciada y '
                    'tarareo) son prácticas de bienestar general. No diagnostican, curan ni '
                    'previenen ninguna enfermedad, y no reemplazan la consulta con un '
                    'profesional de la salud.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'La prueba BOLT es un autoregistro informativo de tu tolerancia a '
                    'retener la respiración, no un diagnóstico clínico.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Si tienes alguna condición cardiovascular, respiratoria o de otro tipo, '
                    'consulta a tu médico antes de usar esta app. Detén la práctica si '
                    'sientes mareo, molestia o cualquier síntoma inusual.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAceptar,
              child: const Text('Entiendo y acepto'),
            ),
          ],
        ),
      ),
    );
  }
}
