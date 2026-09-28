class ItemVenta {
  final int? productoId;
  final String nombreProducto;
  final int cantidad;
  final double precioUnitarioAplicado;

  ItemVenta({
    this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitarioAplicado,
  });

  double get subtotal => cantidad * precioUnitarioAplicado;

  Map<String, dynamic> toMap(int ventaId) => {
        'venta_id': ventaId,
        'producto_id': productoId,
        'nombre_producto': nombreProducto,
        'cantidad': cantidad,
        'precio_unitario_aplicado': precioUnitarioAplicado,
      };

  factory ItemVenta.fromMap(Map<String, dynamic> map) => ItemVenta(
        productoId: map['producto_id'] as int?,
        nombreProducto: map['nombre_producto'] as String,
        cantidad: map['cantidad'] as int,
        precioUnitarioAplicado: (map['precio_unitario_aplicado'] as num).toDouble(),
      );
}

class Venta {
  final int? id;
  final DateTime fecha;
  final int? clienteId;
  final String? clienteNombre;
  final List<ItemVenta> items;
  final double montoLibre;
  final double montoPagado;

  Venta({
    this.id,
    required this.fecha,
    this.clienteId,
    this.clienteNombre,
    this.items = const [],
    this.montoLibre = 0,
    required this.montoPagado,
  });

  double get total {
    if (items.isNotEmpty) {
      return items.fold(0.0, (sum, i) => sum + i.subtotal);
    }
    return montoLibre;
  }

  double get vuelto => (montoPagado - total).clamp(0, double.infinity);

  Map<String, dynamic> toMap() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'cliente_id': clienteId,
        'cliente_nombre': clienteNombre,
        'monto_libre': montoLibre,
        'monto_pagado': montoPagado,
        'total': total,
      };

  factory Venta.fromMap(Map<String, dynamic> map, List<ItemVenta> items) => Venta(
        id: map['id'] as int?,
        fecha: DateTime.parse(map['fecha'] as String),
        clienteId: map['cliente_id'] as int?,
        clienteNombre: map['cliente_nombre'] as String?,
        items: items,
        montoLibre: (map['monto_libre'] as num?)?.toDouble() ?? 0,
        montoPagado: (map['monto_pagado'] as num).toDouble(),
      );
}
