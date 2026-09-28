import '../models/gasto.dart';
import '../models/venta.dart';
import 'database_service.dart';

class ResultadoAnalisis {
  final double ventasMes;
  final double gastosMes;
  final double gananciaNeta;
  final double margenPorcentaje;
  final double? cambioVsMesAnterior;
  final String? categoriaGastoMayor;
  final double? categoriaGastoMayorPorcentaje;
  final String resumen;

  ResultadoAnalisis({
    required this.ventasMes,
    required this.gastosMes,
    required this.gananciaNeta,
    required this.margenPorcentaje,
    this.cambioVsMesAnterior,
    this.categoriaGastoMayor,
    this.categoriaGastoMayorPorcentaje,
    required this.resumen,
  });
}

class AnalisisService {
  final _db = DatabaseService.instance;

  Future<ResultadoAnalisis> analizarMes(DateTime mes) async {
    final inicioMes = DateTime(mes.year, mes.month, 1);
    final finMes = DateTime(mes.year, mes.month + 1, 0, 23, 59, 59);

    final ventas = await _db.listarVentas(desde: inicioMes, hasta: finMes);
    final gastos = await _db.listarGastos(desde: inicioMes, hasta: finMes);

    final ventasMes = ventas.fold(0.0, (sum, v) => sum + v.total);
    final gastosMes = gastos.fold(0.0, (sum, g) => sum + g.monto);
    final gananciaNeta = ventasMes - gastosMes;
    final margen = ventasMes > 0 ? (gananciaNeta / ventasMes) * 100 : 0.0;

    final inicioMesAnterior = DateTime(mes.year, mes.month - 1, 1);
    final finMesAnterior = DateTime(mes.year, mes.month, 0, 23, 59, 59);
    final ventasMesAnterior = await _db.listarVentas(desde: inicioMesAnterior, hasta: finMesAnterior);
    final gastosMesAnterior = await _db.listarGastos(desde: inicioMesAnterior, hasta: finMesAnterior);
    final gananciaMesAnterior =
        ventasMesAnterior.fold(0.0, (s, v) => s + v.total) - gastosMesAnterior.fold(0.0, (s, g) => s + g.monto);

    double? cambioVsMesAnterior;
    if (gananciaMesAnterior != 0) {
      cambioVsMesAnterior = ((gananciaNeta - gananciaMesAnterior) / gananciaMesAnterior.abs()) * 100;
    }

    final porCategoria = _agruparPorCategoria(gastos);
    String? categoriaMayor;
    double? categoriaMayorPct;
    if (porCategoria.isNotEmpty && gastosMes > 0) {
      final entry = porCategoria.entries.reduce((a, b) => a.value > b.value ? a : b);
      categoriaMayor = entry.key;
      categoriaMayorPct = (entry.value / gastosMes) * 100;
    }

    final resumen = _construirResumen(
      gananciaNeta: gananciaNeta,
      margen: margen,
      cambioVsMesAnterior: cambioVsMesAnterior,
      categoriaMayor: categoriaMayor,
      categoriaMayorPct: categoriaMayorPct,
    );

    return ResultadoAnalisis(
      ventasMes: ventasMes,
      gastosMes: gastosMes,
      gananciaNeta: gananciaNeta,
      margenPorcentaje: margen,
      cambioVsMesAnterior: cambioVsMesAnterior,
      categoriaGastoMayor: categoriaMayor,
      categoriaGastoMayorPorcentaje: categoriaMayorPct,
      resumen: resumen,
    );
  }

  Map<String, double> _agruparPorCategoria(List<Gasto> gastos) {
    final mapa = <String, double>{};
    for (final g in gastos) {
      mapa[g.categoria] = (mapa[g.categoria] ?? 0) + g.monto;
    }
    return mapa;
  }

  String _construirResumen({
    required double gananciaNeta,
    required double margen,
    double? cambioVsMesAnterior,
    String? categoriaMayor,
    double? categoriaMayorPct,
  }) {
    final partes = <String>[];

    if (gananciaNeta >= 0) {
      partes.add(
        'Este mes ganaste \$${gananciaNeta.toStringAsFixed(0)} (${margen.toStringAsFixed(0)}% de margen).',
      );
    } else {
      partes.add(
        'Este mes perdiste \$${gananciaNeta.abs().toStringAsFixed(0)} — tus gastos superaron a tus ventas.',
      );
    }

    if (cambioVsMesAnterior != null) {
      final signo = cambioVsMesAnterior >= 0 ? 'más' : 'menos';
      partes.add('Es ${cambioVsMesAnterior.abs().toStringAsFixed(0)}% $signo que el mes pasado.');
    }

    if (categoriaMayor != null && categoriaMayorPct != null) {
      partes.add(
        'Tu mayor gasto fue en "$categoriaMayor" (${categoriaMayorPct.toStringAsFixed(0)}% de lo que gastaste).',
      );
    }

    return partes.join(' ');
  }
}
