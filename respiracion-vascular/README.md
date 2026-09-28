# Respiración Vascular

App personal de respiración guiada enfocada en bienestar vascular (óxido
nítrico, respiración nasal, coherencia cardíaca). Uso personal, sin fines
de publicación en tiendas por ahora — no hace afirmaciones médicas ni
diagnósticas.

## Fase 1 (implementada)

- **Respirar**: dos categorías de técnicas.
  - *Calmante*: Respiración Cadenciada (5.5s/5.5s) y Tarareo/Humming
    (4s/7s), en sesión continua con duración seleccionable (5/10/15
    min) y animación de un vaso sanguíneo que se dilata y contrae según
    el ritmo, con partículas de flujo.
  - *Abdominal intensa*: Kapalabhati y Agnisar Kriya, técnicas por
    rondas (bombeos abdominales rápidos + descanso, 1-5 rondas
    configurables) asociadas en la tradición del yoga a estimular los
    órganos abdominales (páncreas, hígado, estómago). Antes de poder
    empezar, la app muestra las contraindicaciones de cada técnica
    (embarazo, hipertensión no controlada, hernia, cirugía abdominal
    reciente, problemas cardíacos, etc.) y exige marcar una casilla de
    "las leí y no tengo ninguna" — no son afirmaciones médicas, son
    prácticas de bienestar con evidencia preliminar/tradicional, no
    clínica sólida.
- **Prueba BOLT**: cronómetro para el autoregistro de tolerancia a retener
  la respiración, con historial.
- **Progreso**: racha de días consecutivos, minutos totales practicados,
  sesiones completadas, y niveles (Activación Endotelial → Flexibilidad
  Vascular → Máxima Oxigenación Tisular → Resistencia Hipóxica).
- **Consejos de práctica**: frecuencia recomendada, duración progresiva,
  orientación general por edad y notas de constancia — como guía general
  de bienestar, no prescripción médica.
- **Descargo de responsabilidad**: se muestra una sola vez en el primer
  uso (guardado con `shared_preferences`), dejando claro que no es un
  dispositivo médico.
- **Recordatorios (alarma)**: dos recordatorios diarios configurables
  (mañana/noche), con hora elegible por el usuario. Usa
  `flutter_local_notifications` en modo alarma exacta (sonido,
  vibración, categoría `alarm`, se puede mostrar con pantalla
  bloqueada) — no una notificación silenciosa. Se reprograma
  automáticamente cada vez que se abre la app, como respaldo por si el
  sistema no conserva la alarma tras un reinicio.

Todo funciona 100% local (SQLite vía `sqflite`), sin servidor ni cuenta.

## Arquitectura

- `lib/models/` — `TecnicaRespiracion`, `Sesion`, `PruebaBolt`.
- `lib/services/` — `DatabaseService` (SQLite), `ProgresoService`
  (cálculo de racha y niveles).
- `lib/widgets/vaso_sanguineo_painter.dart` — `CustomPainter` de la
  animación del vaso sanguíneo.
- `lib/screens/` — pantallas de cada módulo.
- `lib/services/notificaciones_service.dart` — programación de las
  alarmas diarias con `flutter_local_notifications` + `timezone`.
- `lib/utils/formato_fecha.dart` — formateo de fechas en español sin
  depender del paquete `intl` (se evitó por el riesgo de necesitar
  `initializeDateFormatting` antes de usarse, que no se puede probar en
  este entorno sin SDK de Android).

## Fase 2 (pendiente, no implementada)

- **Medición real de HRV/SpO2 vía ESP32 + MAX30102**: en vez de estimar
  el pulso con la cámara del teléfono (PPG por cámara, impreciso), el
  usuario ya tiene un proyecto propio con ESP32 + sensor MAX30102. La
  idea es que el ESP32 lea el sensor y transmita los datos al teléfono
  por Bluetooth Low Energy (BLE), y la app los reciba con el paquete
  `flutter_blue_plus` (o similar) para mostrar HRV/SpO2 reales durante
  la sesión de respiración, en vez de un estimado por cámara.
  - Requiere: firmware del ESP32 exponiendo un servicio BLE (GATT) con
    las lecturas del MAX30102, y en la app un servicio `BleService` que
    escanee, se conecte y reciba las lecturas.
  - Se deja pendiente hasta tener el firmware del ESP32 listo y probado
    por separado.
- Posible gráfico histórico de duración de BOLT en el tiempo.
- Nota sobre el permiso de "Alarmas y recordatorios" (Android 12+): la
  app lo solicita al activar un recordatorio, pero como no se puede
  probar en este entorno (sin SDK de Android), conviene verificar en un
  teléfono real que el diálogo del sistema aparece y que, si el usuario
  lo niega, la alarma exacta cae de forma segura a una notificación
  normal en vez de fallar silenciosamente.

## Validación

- `flutter analyze`: sin issues.
- `flutter test`: pasa.
- No se pudo compilar un APK real ni probar la app corriendo, porque el
  entorno de desarrollo no tiene acceso al SDK de Android (red
  bloqueada hacia `dl.google.com`). Para probarla de verdad hay que
  correr `flutter run` en un equipo con Android Studio/SDK instalado.
