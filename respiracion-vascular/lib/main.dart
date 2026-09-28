import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/descargo_screen.dart';
import 'screens/home_screen.dart';

const _claveDescargoAceptado = 'descargo_aceptado';

void main() {
  runApp(const RespiracionVascularApp());
}

class RespiracionVascularApp extends StatelessWidget {
  const RespiracionVascularApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Respiración Vascular',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC0392B)),
      ),
      home: const _Arranque(),
    );
  }
}

class _Arranque extends StatefulWidget {
  const _Arranque();

  @override
  State<_Arranque> createState() => _ArranqueState();
}

class _ArranqueState extends State<_Arranque> {
  bool? _descargoAceptado;

  @override
  void initState() {
    super.initState();
    _verificar();
  }

  Future<void> _verificar() async {
    final prefs = await SharedPreferences.getInstance();
    final aceptado = prefs.getBool(_claveDescargoAceptado) ?? false;
    if (mounted) setState(() => _descargoAceptado = aceptado);
  }

  Future<void> _aceptar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveDescargoAceptado, true);
    if (mounted) setState(() => _descargoAceptado = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_descargoAceptado == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_descargoAceptado == false) {
      return DescargoScreen(onAceptar: _aceptar);
    }
    return const HomeScreen();
  }
}
