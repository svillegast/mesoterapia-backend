enum CategoriaTecnica { calma, abdominalIntensa }

class TecnicaRespiracion {
  final String id;
  final String nombre;
  final String descripcion;
  final CategoriaTecnica categoria;
  final List<String> contraindicaciones;

  // Usados por las técnicas de ciclo continuo (categoria == calma):
  // un solo ciclo inhalar/retener/exhalar que se repite por X minutos.
  final int inhalarMs;
  final int retenerMs;
  final int exhalarMs;
  final bool conTarareo;

  // Usados por las técnicas por rondas (categoria == abdominalIntensa):
  // series de bombeos abdominales rápidos seguidas de un descanso.
  final int pumpsPorRonda;
  final int duracionPumpMs;
  final int descansoRondaSegundos;

  const TecnicaRespiracion({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.categoria = CategoriaTecnica.calma,
    this.contraindicaciones = const [],
    this.inhalarMs = 0,
    this.retenerMs = 0,
    this.exhalarMs = 0,
    this.conTarareo = false,
    this.pumpsPorRonda = 0,
    this.duracionPumpMs = 0,
    this.descansoRondaSegundos = 0,
  });

  bool get esPorRondas => categoria == CategoriaTecnica.abdominalIntensa;

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
  TecnicaRespiracion(
    id: 'kapalabhati',
    nombre: 'Kapalabhati (respiración de fuego)',
    descripcion:
        'Exhalaciones cortas y forzadas por la nariz, empujando el abdomen hacia adentro con fuerza; la inhalación entre cada una es pasiva y suave. En la tradición del yoga se asocia con "masajear" y estimular los órganos abdominales (páncreas, hígado, estómago). Es más intensa que las técnicas de respiración calmada.',
    categoria: CategoriaTecnica.abdominalIntensa,
    pumpsPorRonda: 30,
    duracionPumpMs: 600,
    descansoRondaSegundos: 20,
    contraindicaciones: [
      'Embarazo',
      'Hipertensión arterial no controlada',
      'Hernia (incluida hernia hiatal)',
      'Cirugía abdominal reciente',
      'Problemas cardíacos',
      'Glaucoma o problemas de retina',
      'Mareos frecuentes, vértigo o epilepsia',
    ],
  ),
  TecnicaRespiracion(
    id: 'agnisar',
    nombre: 'Agnisar Kriya (fuego digestivo)',
    descripcion:
        'Se exhala todo el aire y, reteniendo la respiración (sin aire dentro), se bombea el abdomen hacia adentro y hacia afuera varias veces seguidas. Es más intensa que Kapalabhati y se enfoca aún más en el área del estómago y el páncreas. Requiere más práctica y control.',
    categoria: CategoriaTecnica.abdominalIntensa,
    pumpsPorRonda: 15,
    duracionPumpMs: 500,
    descansoRondaSegundos: 25,
    contraindicaciones: [
      'Embarazo',
      'Hipertensión arterial no controlada',
      'Hernia (incluida hernia hiatal)',
      'Cirugía abdominal reciente',
      'Problemas cardíacos',
      'Úlceras gástricas o duodenales activas',
      'Cualquier condición que no permita retener la respiración con seguridad',
    ],
  ),
];
