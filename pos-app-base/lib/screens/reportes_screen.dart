import 'package:flutter/material.dart';
import '../models/venta.dart';
import '../services/database_service.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _db = DatabaseService.instance;
  List<Venta> _ventasHoy = [];
  List<Venta> _ventasSemana = [];
  List<Venta> _ventasMes = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final ahora = DateTime.now();
    final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicioSemana = inicioHoy.subtract(Duration(days: ahora.weekday - 1));
    final inicioMes = DateTime(ahora.year, ahora.month, 1);
    final finHoy = inicioHoy.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

    final hoy = await _db.listarVentas(desde: inicioHoy, hasta: finHoy);
    final semana = await _db.listarVentas(desde: inicioSemana, hasta: ahora);
    final mes = await _db.listarVentas(desde: inicioMes, hasta: ahora);

    if (mounted) {
      setState(() {
        _ventasHoy = hoy;
        _ventasSemana = semana;
        _ventasMes = mes;
      });
    }
  }

  double _totalDe(List<Venta> ventas) => ventas.fold(0.0, (s, v) => s + v.total);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TarjetaTotal(titulo: 'Hoy', cantidad: _ventasHoy.length, total: _totalDe(_ventasHoy)),
          const SizedBox(height: 12),
          _TarjetaTotal(titulo: 'Esta semana', cantidad: _ventasSemana.length, total: _totalDe(_ventasSemana)),
          const SizedBox(height: 12),
          _TarjetaTotal(titulo: 'Este mes', cantidad: _ventasMes.length, total: _totalDe(_ventasMes)),
          const SizedBox(height: 24),
          Text('Ventas de hoy', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_ventasHoy.isEmpty)
            const Text('Sin ventas registradas hoy todavía.')
          else
            ..._ventasHoy.map((v) => ListTile(
                  title: Text('\$${v.total.toStringAsFixed(2)}'),
                  subtitle: Text(v.clienteNombre ?? 'Sin cliente'),
                  trailing: Text('${v.fecha.hour.toString().padLeft(2, '0')}:${v.fecha.minute.toString().padLeft(2, '0')}'),
                )),
        ],
      ),
    );
  }
}

class _TarjetaTotal extends StatelessWidget {
  final String titulo;
  final int cantidad;
  final double total;

  const _TarjetaTotal({required this.titulo, required this.cantidad, required this.total});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                Text('$cantidad ventas', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            Text('\$${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
