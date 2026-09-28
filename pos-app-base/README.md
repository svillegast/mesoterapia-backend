# POS App Base — molde reutilizable

App Android (Flutter) de ventas a medida, sin servidor (SQLite local),
armada con los 6 módulos indispensables para el primer cliente piloto
(una plastifería), pero pensada como **molde reutilizable** para el
siguiente cliente: para reconfigurar, solo se edita
`lib/config/negocio_config.dart` (nombre, colores, si vende al por mayor,
etiqueta de la unidad) — no hace falta tocar el resto del código.

## Los 6 módulos

1. **Registro de ventas** (`venta_screen.dart`) — productos o monto libre,
   calcula el vuelto automático.
2. **Clientes** (`clientes_screen.dart`) — ficha simple.
3. **Reportes básicos** (`reportes_screen.dart`) — totales de hoy/semana/mes.
4. **Respaldo de datos** (`respaldo_service.dart`) — exporta toda la base a
   un JSON y abre el menú nativo de "Compartir" para guardarlo en Google
   Drive. Mismo patrón ya probado en producción por CobranzasVentasPro.
5. **Pérdidas y Ganancias con análisis** (`gastos_screen.dart` +
   `analisis_service.dart`) — no solo muestra números: genera un resumen en
   español (ganancia neta, comparación vs. mes anterior, categoría de mayor
   gasto) para que sirva para decidir, no solo para ver una tabla.
6. **Unidades y precio por volumen** (dentro de `productos_screen.dart`) —
   vender por unidad o al por mayor desde cierta cantidad, con control de
   stock incluido en la misma pantalla.

## Configuración por cliente (`lib/config/negocio_config.dart`)

- `nombreNegocio`, `colorPrimario`, `colorAcento` — identidad del negocio.
- `etiquetaUnidad` — cómo se llama la unidad de venta ("unidad", "funda",
  "metro", etc.).
- `ventaSoloConsumidorFinal` — en `true`, oculta el precio de mayorista y
  usa un solo precio por producto (para negocios que no venden por
  volumen). En `false` (como la plastifería piloto), muestra precio de
  mayorista y cantidad mínima.

## Pendiente — sistema de licencias (fuera de este molde)

Quedó fuera de este build, para una sesión aparte dedicada a eso: atar la
app a un número de teléfono (no al equipo) usando verificación por
**WhatsApp** (no SMS — muchos usuarios locales solo tienen datos, y
confirmar por SMS a veces exige una recarga aparte que no llega). Esto
necesita integrarse con la WhatsApp Business API — ya hay una base de eso
en `backend/integrations/whatsapp_client.py` del proyecto de mesoterapia —
en vez de Firebase Phone Auth (que solo hace SMS).

## Sobre CobranzasVentasPro

Es una app distinta (React Native/Expo, en Google Drive, no en GitHub) —
no se pudo reutilizar código directamente por ser otra tecnología, pero sí
se replicó su patrón de respaldo (exportar JSON + compartir vía el menú
nativo, permitiendo guardar en Google Drive sin necesitar credenciales de
la API de Google) porque ya está probado en producción.

## Compilar

```bash
cd pos-app-base
flutter create --org com.emprender.milagro --project-name pos_app_base .
flutter pub get
flutter analyze   # 0 errores al momento de este commit
flutter test      # pasa
flutter build apk --release
```
