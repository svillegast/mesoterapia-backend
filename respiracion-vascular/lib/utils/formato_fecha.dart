const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

String formatearFechaHora(DateTime fecha) {
  final dia = fecha.day;
  final mes = _meses[fecha.month - 1];
  final hora = fecha.hour.toString().padLeft(2, '0');
  final minuto = fecha.minute.toString().padLeft(2, '0');
  return '$dia $mes ${fecha.year}, $hora:$minuto';
}

String formatearFecha(DateTime fecha) {
  final dia = fecha.day;
  final mes = _meses[fecha.month - 1];
  return '$dia $mes ${fecha.year}';
}
