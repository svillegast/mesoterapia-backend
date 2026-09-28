class Gasto {
  final int? id;
  final DateTime fecha;
  final String categoria;
  final double monto;
  final String? descripcion;

  Gasto({this.id, required this.fecha, required this.categoria, required this.monto, this.descripcion});

  Map<String, dynamic> toMap() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'categoria': categoria,
        'monto': monto,
        'descripcion': descripcion,
      };

  factory Gasto.fromMap(Map<String, dynamic> map) => Gasto(
        id: map['id'] as int?,
        fecha: DateTime.parse(map['fecha'] as String),
        categoria: map['categoria'] as String,
        monto: (map['monto'] as num).toDouble(),
        descripcion: map['descripcion'] as String?,
      );
}
