class Cliente {
  final int? id;
  final String nombre;
  final String? telefono;
  final String? direccion;
  final String? notas;

  Cliente({this.id, required this.nombre, this.telefono, this.direccion, this.notas});

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'telefono': telefono,
        'direccion': direccion,
        'notas': notas,
      };

  factory Cliente.fromMap(Map<String, dynamic> map) => Cliente(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        telefono: map['telefono'] as String?,
        direccion: map['direccion'] as String?,
        notas: map['notas'] as String?,
      );
}
