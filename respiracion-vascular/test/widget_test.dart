import 'package:flutter_test/flutter_test.dart';

import 'package:respiracion_vascular/main.dart';

void main() {
  testWidgets('La app arranca y muestra el descargo o la pantalla principal', (tester) async {
    await tester.pumpWidget(const RespiracionVascularApp());
    await tester.pump();

    expect(find.byType(RespiracionVascularApp), findsOneWidget);
  });
}
