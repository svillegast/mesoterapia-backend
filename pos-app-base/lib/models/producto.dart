class Producto {
  final int? id;
  final String nombre;
  final double precioUnidad;
  final double? precioMayorista;
  final int? cantidadMinimaMayorista;
  final int stock;

  Producto({
    this.id,
    required this.nombre,
    required this.precioUnidad,
    this.precioMayorista,
    this.cantidadMinimaMayorista,
    this.stock = 0,
  });

  double precioParaCantidad(int cantidad) {
    if (precioMayorista != null &&
        cantidadMinimaMayorista != null &&
        cantidad >= cantidadMinimaMayorista!) {
      return precioMayorista!;
    }
    return precioUnidad;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'precio_unidad': precioUnidad,
        'precio_mayorista': precioMayorista,
        'cantidad_minima_mayorista': cantidadMinimaMayorista,
        'stock': stock,
      };

  factory Producto.fromMap(Map<String, dynamic> map) => Producto(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        precioUnidad: (map['precio_unidad'] as num).toDouble(),
        precioMayorista: (map['precio_mayorista'] as num?)?.toDouble(),
        cantidadMinimaMayorista: map['cantidad_minima_mayorista'] as int?,
        stock: map['stock'] as int? ?? 0,
      );

  Producto copyWith({int? id, int? stock}) => Producto(
        id: id ?? this.id,
        nombre: nombre,
        precioUnidad: precioUnidad,
        precioMayorista: precioMayorista,
        cantidadMinimaMayorista: cantidadMinimaMayorista,
        stock: stock ?? this.stock,
      );
}
