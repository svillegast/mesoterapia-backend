import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:productos_naturales_app/main.dart';

void main() {
  testWidgets('Muestra la pantalla de búsqueda al iniciar', (tester) async {
    await tester.pumpWidget(const ProductosNaturalesApp());

    expect(find.text('Buscar evidencia'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
