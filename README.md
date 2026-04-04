# Mesoterapia Facial AI

App Android de análisis facial con IA para Emprender · Mesoterapia Sin Agujas · Milagro, Ecuador.

## Estructura

```
mesoterapia-facial-ai/
├── backend/   → API Python (FastAPI + MediaPipe + OpenCV)
└── app/       → App Android (Flutter)
```

## SETUP RÁPIDO

### 1. Backend (servidor Contabo o local)

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env
# Editar .env con tus credenciales
uvicorn main:app --host 0.0.0.0 --port 8000
```

### 2. Configurar la IP del servidor en Flutter

Editar `app/lib/services/api_service.dart`:
```dart
static const String _baseUrl = 'http://TU_IP_SERVIDOR:8000';
```

### 3. App Flutter

```bash
cd app
flutter pub get
flutter run
```

## Credenciales necesarias (.env)

1. **WhatsApp Business API:** Crear app en Meta for Developers → WhatsApp → Cloud API
   - `WHATSAPP_ACCESS_TOKEN`
   - `WHATSAPP_PHONE_NUMBER_ID`

2. **Firebase** (opcional, para historial):
   - Crear proyecto en Firebase Console
   - Descargar `firebase-credentials.json`

## Endpoints del backend

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/health` | Estado del servicio |
| POST | `/api/analyze` | Analiza foto del rostro |
| POST | `/api/send-whatsapp` | Envía resultado al cliente |
