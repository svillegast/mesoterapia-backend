import 'package:flutter/material.dart';
import '../config/negocio_config.dart';
import '../services/respaldo_service.dart';
import 'clientes_screen.dart';
import 'gastos_screen.dart';
import 'productos_screen.dart';
import 'reportes_screen.dart';
import 'venta_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(NegocioConfig.nombreNegocio)),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: [
          _AccesoModulo(
            icono: Icons.point_of_sale,
            titulo: 'Nueva venta',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VentaScreen()),
            ),
          ),
          _AccesoModulo(
            icono: Icons.inventory_2,
            titulo: 'Productos',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProductosScreen()),
            ),
          ),
          _AccesoModulo(
            icono: Icons.people,
            titulo: 'Clientes',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClientesScreen()),
            ),
          ),
          _AccesoModulo(
            icono: Icons.bar_chart,
            titulo: 'Reportes',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportesScreen()),
            ),
          ),
          _AccesoModulo(
            icono: Icons.trending_up,
            titulo: 'Pérdidas y\nGanancias',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GastosScreen()),
            ),
          ),
          _AccesoModulo(
            icono: Icons.backup,
            titulo: 'Respaldo',
            onTap: () async {
              await RespaldoService().crearYCompartirRespaldo();
            },
          ),
        ],
      ),
    );
  }
}

class _AccesoModulo extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final VoidCallback onTap;

  const _AccesoModulo({required this.icono, required this.titulo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
