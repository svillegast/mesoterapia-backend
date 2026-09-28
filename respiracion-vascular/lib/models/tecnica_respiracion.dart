class TecnicaRespiracion {
  final String id;
  final String nombre;
  final String descripcion;
  final int inhalarMs;
  final int retenerMs;
  final int exhalarMs;
  final bool conTarareo;

  const TecnicaRespiracion({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.inhalarMs,
    this.retenerMs = 0,
    required this.exhalarMs,
    this.conTarareo = false,
  });

  int get duracionCicloMs => inhalarMs + retenerMs + exhalarMs;
}

const List<TecnicaRespiracion> tecnicasDisponibles = [
  TecnicaRespiracion(
    id: 'cadenciada',
    nombre: 'Respiración Cadenciada',
    descripcion:
        'Coherencia cardíaca: inhala y exhala al mismo ritmo (5.5 segundos cada uno) para sincronizar tu corazón y tu respiración.',
    inhalarMs: 5500,
    exhalarMs: 5500,
  ),
  TecnicaRespiracion(
    id: 'tarareo',
    nombre: 'Tarareo (Humming)',
    descripcion:
        'Inhala por la nariz y exhala emitiendo un sonido grave (zumbido) — se ha visto que multiplica varias veces la liberación de óxido nítrico en las cavidades nasales frente a una exhalación silenciosa.',
    inhalarMs: 4000,
    exhalarMs: 7000,
    conTarareo: true,
  ),
];
