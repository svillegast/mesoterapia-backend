class PruebaBolt {
  final int? id;
  final DateTime fecha;
  final int segundos;

  PruebaBolt({this.id, required this.fecha, required this.segundos});

  Map<String, dynamic> toMap() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'segundos': segundos,
      };

  factory PruebaBolt.fromMap(Map<String, dynamic> map) => PruebaBolt(
        id: map['id'] as int?,
        fecha: DateTime.parse(map['fecha'] as String),
        segundos: map['segundos'] as int,
      );
}
