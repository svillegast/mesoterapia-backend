import 'package:flutter/material.dart';
import 'config/negocio_config.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PosApp());
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: NegocioConfig.nombreNegocio,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: NegocioConfig.colorPrimario,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
