class Sesion {
  final int? id;
  final DateTime fecha;
  final String tecnicaId;
  final int duracionSegundos;

  Sesion({this.id, required this.fecha, required this.tecnicaId, required this.duracionSegundos});

  Map<String, dynamic> toMap() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'tecnica_id': tecnicaId,
        'duracion_segundos': duracionSegundos,
      };

  factory Sesion.fromMap(Map<String, dynamic> map) => Sesion(
        id: map['id'] as int?,
        fecha: DateTime.parse(map['fecha'] as String),
        tecnicaId: map['tecnica_id'] as String,
        duracionSegundos: map['duracion_segundos'] as int,
      );
}
