import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/descargo_screen.dart';
import 'screens/home_screen.dart';
import 'services/notificaciones_service.dart';

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
    _reprogramarRecordatorios();
  }

  Future<void> _verificar() async {
    final prefs = await SharedPreferences.getInstance();
    final aceptado = prefs.getBool(_claveDescargoAceptado) ?? false;
    if (mounted) setState(() => _descargoAceptado = aceptado);
  }

  /// Vuelve a programar los recordatorios activos cada vez que se abre la
  /// app, como respaldo por si el sistema no los conservó tras un reinicio.
  Future<void> _reprogramarRecordatorios() async {
    await NotificacionesService.instance.init();
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool('recordatorio_manana_activo') ?? false) {
      final minutos = prefs.getInt('recordatorio_manana_minutos') ?? 7 * 60;
      await NotificacionesService.instance.programarRecordatorioDiario(
        id: idRecordatorioManana,
        hora: TimeOfDay(hour: minutos ~/ 60, minute: minutos % 60),
        titulo: 'Momento de respirar',
        cuerpo: 'Tu sesión de respiración de la mañana te espera 🌬️',
      );
    }

    if (prefs.getBool('recordatorio_noche_activo') ?? false) {
      final minutos = prefs.getInt('recordatorio_noche_minutos') ?? 20 * 60;
      await NotificacionesService.instance.programarRecordatorioDiario(
        id: idRecordatorioNoche,
        hora: TimeOfDay(hour: minutos ~/ 60, minute: minutos % 60),
        titulo: 'Momento de respirar',
        cuerpo: 'Cierra el día con tu sesión de respiración 🌙',
      );
    }
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
