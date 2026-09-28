import '../models/sesion.dart';
import 'database_service.dart';

class Nivel {
  final String nombre;
  final int minutosMinimos;
  const Nivel(this.nombre, this.minutosMinimos);
}

const List<Nivel> niveles = [
  Nivel('Activación Endotelial', 0),
  Nivel('Flexibilidad Vascular', 60),
  Nivel('Máxima Oxigenación Tisular', 300),
  Nivel('Resistencia Hipóxica (Master)', 900),
];

class ResultadoProgreso {
  final int totalSesiones;
  final int totalMinutos;
  final int rachaDias;
  final Nivel nivelActual;
  final Nivel? siguienteNivel;
  final double progresoNivel;

  ResultadoProgreso({
    required this.totalSesiones,
    required this.totalMinutos,
    required this.rachaDias,
    required this.nivelActual,
    this.siguienteNivel,
    required this.progresoNivel,
  });
}

class ProgresoService {
  final _db = DatabaseService.instance;

  Future<ResultadoProgreso> calcular() async {
    final sesiones = await _db.listarSesiones();
    final totalSegundos = sesiones.fold(0, (s, e) => s + e.duracionSegundos);
    final totalMinutos = totalSegundos ~/ 60;

    final nivelActual = _nivelPara(totalMinutos);
    final indiceActual = niveles.indexOf(nivelActual);
    final siguienteNivel = indiceActual < niveles.length - 1 ? niveles[indiceActual + 1] : null;

    double progresoNivel = 1.0;
    if (siguienteNivel != null) {
      final rango = siguienteNivel.minutosMinimos - nivelActual.minutosMinimos;
      final avance = totalMinutos - nivelActual.minutosMinimos;
      progresoNivel = rango > 0 ? (avance / rango).clamp(0.0, 1.0) : 1.0;
    }

    return ResultadoProgreso(
      totalSesiones: sesiones.length,
      totalMinutos: totalMinutos,
      rachaDias: _calcularRacha(sesiones),
      nivelActual: nivelActual,
      siguienteNivel: siguienteNivel,
      progresoNivel: progresoNivel,
    );
  }

  Nivel _nivelPara(int totalMinutos) {
    var actual = niveles.first;
    for (final n in niveles) {
      if (totalMinutos >= n.minutosMinimos) actual = n;
    }
    return actual;
  }

  int _calcularRacha(List<Sesion> sesiones) {
    if (sesiones.isEmpty) return 0;

    final diasConSesion = sesiones.map((s) => DateTime(s.fecha.year, s.fecha.month, s.fecha.day)).toSet();

    var hoy = DateTime.now();
    var cursor = DateTime(hoy.year, hoy.month, hoy.day);

    if (!diasConSesion.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!diasConSesion.contains(cursor)) return 0;
    }

    var racha = 0;
    while (diasConSesion.contains(cursor)) {
      racha++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return racha;
  }
}
