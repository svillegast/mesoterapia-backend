# Productos Naturales — Evidencia Científica

App Android (Flutter) independiente, sin servidor propio: busca en PubMed/Europe PMC
qué productos naturales tienen respaldo científico para una enfermedad o un órgano
afectado, usa Gemini para estructurar y calificar la evidencia (1-5 estrellas), y
guarda todo en una base SQLite local en el teléfono para no repetir la misma
investigación dos veces.

## ⚠️ Paso pendiente antes de compilar

Este código se escribió en una sesión sin el SDK de Flutter instalado, así que
**faltan las carpetas de plataforma** (`android/`, `ios/`) que normalmente genera
`flutter create`. Para completarlo, en una máquina con Flutter instalado:

```bash
cd productos-naturales
flutter create --org com.emprender.milagro --project-name productos_naturales_app .
```

Esto genera `android/`, `ios/`, etc. **sin tocar** el código ya escrito en `lib/`
(flutter create respeta los archivos existentes en `lib/` y `pubspec.yaml` si ya
existen, pero por seguridad revisa el diff después de correrlo).

## Configurar la API key de Gemini

```bash
cp lib/config/secrets.example.dart lib/config/secrets.dart
# Editar lib/config/secrets.dart y poner la API key real de Gemini (aistudio.google.com/apikey)
```

`lib/config/secrets.dart` está en `.gitignore` — nunca se sube al repositorio.

## Correr la app

```bash
flutter pub get
flutter run
```

## Cómo funciona

1. El usuario busca por **enfermedad** (ej. "diabetes tipo 2") o por **órgano**
   (ej. "hígado").
2. La app revisa primero su base SQLite local (`productos_naturales.db` en el
   propio teléfono) — si ya investigó eso antes, muestra el resultado guardado al
   instante, sin usar internet ni gastar cuota de Gemini.
3. Si no lo tiene guardado, busca estudios reales en **Europe PMC** (API pública
   gratuita que indexa PubMed + más), envía esos resúmenes a **Gemini** (capa
   gratuita) para que extraiga qué le hace la enfermedad al órgano, qué productos
   naturales tienen evidencia, y los califique de 1 a 5 estrellas según el tipo de
   estudio (meta-análisis > ensayo clínico > cohorte > animal/in vitro).
4. Guarda el resultado estructurado (enfermedad, órgano, productos, estudios
   citados) en SQLite para la próxima vez.

## Fuentes usadas (y por qué)

Solo fuentes 100% gratuitas y legales, vía API pública:

- **Europe PMC** — indexa PubMed + PMC + preprints, con buena cobertura de
  investigación internacional (incluida la china, rusa, india y alemana) **cuando
  se publica en revistas indexadas en inglés**, que es donde de verdad está la
  investigación seria y revisada por pares sobre medicina tradicional/fitoterapia.
- Bases nativas como CNKI (China) o eLibrary.ru (Rusia) son de pago y en su
  idioma original — no son viables para esta app; ver
  `Subvenciones/DPrize-2026/...` y el resto de investigaciones guardadas en
  Drive para más contexto de esta decisión.

## Nota de responsabilidad

Los resultados son generados automáticamente a partir de resúmenes científicos y
sirven como apoyo educativo/de investigación — no reemplazan el criterio clínico
profesional. La app lo recuerda en la pantalla de detalle de cada producto.
