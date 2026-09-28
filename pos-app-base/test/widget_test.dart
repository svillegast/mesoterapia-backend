import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app_base/main.dart';

void main() {
  testWidgets('Muestra la pantalla de inicio con los accesos a módulos', (tester) async {
    await tester.pumpWidget(const PosApp());

    expect(find.text('Nueva venta'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });
}
