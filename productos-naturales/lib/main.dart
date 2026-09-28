import 'package:flutter/material.dart';
import 'screens/search_screen.dart';

void main() {
  runApp(const ProductosNaturalesApp());
}

class ProductosNaturalesApp extends StatelessWidget {
  const ProductosNaturalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Productos Naturales',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D32),
        useMaterial3: true,
      ),
      home: const SearchScreen(),
    );
  }
}
