import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notificaciones_service.dart';

class RecordatoriosScreen extends StatefulWidget {
  const RecordatoriosScreen({super.key});

  @override
  State<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen> {
  bool _cargando = true;

  bool _mananaActivo = false;
  TimeOfDay _mananaHora = const TimeOfDay(hour: 7, minute: 0);

  bool _nocheActivo = false;
  TimeOfDay _nocheHora = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _mananaActivo = prefs.getBool('recordatorio_manana_activo') ?? false;
      _mananaHora = _minutosATime(prefs.getInt('recordatorio_manana_minutos') ?? 7 * 60);
      _nocheActivo = prefs.getBool('recordatorio_noche_activo') ?? false;
      _nocheHora = _minutosATime(prefs.getInt('recordatorio_noche_minutos') ?? 20 * 60);
      _cargando = false;
    });
  }

  TimeOfDay _minutosATime(int minutos) => TimeOfDay(hour: minutos ~/ 60, minute: minutos % 60);
  int _timeAMinutos(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _actualizarManana({bool? activo, TimeOfDay? hora}) async {
    final prefs = await SharedPreferences.getInstance();
    final nuevoActivo = activo ?? _mananaActivo;
    final nuevaHora = hora ?? _mananaHora;

    setState(() {
      _mananaActivo = nuevoActivo;
      _mananaHora = nuevaHora;
    });

    await prefs.setBool('recordatorio_manana_activo', nuevoActivo);
    await prefs.setInt('recordatorio_manana_minutos', _timeAMinutos(nuevaHora));

    if (nuevoActivo) {
      await NotificacionesService.instance.solicitarPermisos();
      await NotificacionesService.instance.programarRecordatorioDiario(
        id: idRecordatorioManana,
        hora: nuevaHora,
        titulo: 'Momento de respirar',
        cuerpo: 'Tu sesión de respiración de la mañana te espera 🌬️',
      );
    } else {
      await NotificacionesService.instance.cancelar(idRecordatorioManana);
    }
  }

  Future<void> _actualizarNoche({bool? activo, TimeOfDay? hora}) async {
    final prefs = await SharedPreferences.getInstance();
    final nuevoActivo = activo ?? _nocheActivo;
    final nuevaHora = hora ?? _nocheHora;

    setState(() {
      _nocheActivo = nuevoActivo;
      _nocheHora = nuevaHora;
    });

    await prefs.setBool('recordatorio_noche_activo', nuevoActivo);
    await prefs.setInt('recordatorio_noche_minutos', _timeAMinutos(nuevaHora));

    if (nuevoActivo) {
      await NotificacionesService.instance.solicitarPermisos();
      await NotificacionesService.instance.programarRecordatorioDiario(
        id: idRecordatorioNoche,
        hora: nuevaHora,
        titulo: 'Momento de respirar',
        cuerpo: 'Cierra el día con tu sesión de respiración 🌙',
      );
    } else {
      await NotificacionesService.instance.cancelar(idRecordatorioNoche);
    }
  }

  Future<void> _elegirHora(TimeOfDay actual, ValueChanged<TimeOfDay> onElegido) async {
    final elegido = await showTimePicker(context: context, initialTime: actual);
    if (elegido != null) onElegido(elegido);
  }

  String _formatearHora(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final periodo = t.period == DayPeriod.am ? 'a. m.' : 'p. m.';
    return '$h:$m $periodo';
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Recordatorios')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Activa uno o los dos recordatorios diarios. Te avisaremos a la hora '
                'elegida (con algunos minutos de tolerancia según el sistema del '
                'teléfono, para ahorrar batería).',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Recordatorio de mañana'),
                  subtitle: Text(_formatearHora(_mananaHora)),
                  value: _mananaActivo,
                  onChanged: (v) => _actualizarManana(activo: v),
                ),
                if (_mananaActivo)
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Cambiar hora'),
                    onTap: () => _elegirHora(_mananaHora, (h) => _actualizarManana(hora: h)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Recordatorio de noche'),
                  subtitle: Text(_formatearHora(_nocheHora)),
                  value: _nocheActivo,
                  onChanged: (v) => _actualizarNoche(activo: v),
                ),
                if (_nocheActivo)
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Cambiar hora'),
                    onTap: () => _elegirHora(_nocheHora, (h) => _actualizarNoche(hora: h)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
