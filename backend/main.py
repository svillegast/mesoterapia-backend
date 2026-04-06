from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import os
import base64
import numpy as np
import cv2
from dotenv import load_dotenv
from typing import Optional

from analysis.face_detector import FaceDetector
from analysis.zone_segmenter import ZoneSegmenter
from analysis.wrinkle_analyzer import WrinkleAnalyzer
from analysis.sagging_analyzer import SaggingAnalyzer
from analysis.spot_analyzer import SpotAnalyzer
from analysis.pore_analyzer import PoreAnalyzer
from analysis.dark_circle_analyzer import DarkCircleAnalyzer
from analysis.luminosity_analyzer import LuminosityAnalyzer
from analysis.volume_analyzer import VolumeAnalyzer
from scoring.zone_scorer import ZoneScorer
from protocols.protocol_mapper import ProtocolMapper
from reports.visual_report import VisualReportGenerator
from reports.text_report import TextReportGenerator
from integrations.whatsapp_client import WhatsAppClient

load_dotenv()


# ── Helpers ────────────────────────────────────────────────────────────────────

def _normalize_illumination(image_rgb: np.ndarray) -> np.ndarray:
    """
    Normalización CLAHE en canal L del espacio LAB.
    Reduce falsos positivos por iluminación desigual.
    """
    lab = cv2.cvtColor(image_rgb, cv2.COLOR_RGB2LAB)
    l, a, b = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    l_eq = clahe.apply(l)
    lab_eq = cv2.merge([l_eq, a, b])
    return cv2.cvtColor(lab_eq, cv2.COLOR_LAB2RGB)


def _age_factor(age: int) -> float:
    """
    Factor de corrección por edad.
    Piel joven sana puntúa más alto por textura natural —
    este factor reduce esos scores para evitar falsos positivos.
    """
    if age <= 22: return 0.55
    if age <= 28: return 0.65
    if age <= 35: return 0.78
    if age <= 45: return 0.90
    if age <= 55: return 1.00
    return 1.08


def _apply_age_correction(results: dict, factor: float) -> dict:
    """Aplica factor de edad a todos los scores de condición."""
    corrected = {}
    for key, data in results.items():
        if isinstance(data, dict) and "score" in data:
            new_score = round(min(100.0, data["score"] * factor), 1)
            corrected[key] = {**data, "score": new_score}
        else:
            corrected[key] = data
    return corrected


def _clean_face_b64(image_rgb: np.ndarray, target_h: int = 700) -> str:
    """Rostro limpio sin overlays, redimensionado y levemente mejorado."""
    from PIL import Image, ImageEnhance
    import io as _io
    pil = Image.fromarray(image_rgb)
    ratio = target_h / pil.height
    new_w = max(1, int(pil.width * ratio))
    pil = pil.resize((new_w, target_h), Image.LANCZOS)
    # Mejora leve: +10% brillo, +15% contraste, +10% nitidez
    pil = ImageEnhance.Brightness(pil).enhance(1.10)
    pil = ImageEnhance.Contrast(pil).enhance(1.15)
    pil = ImageEnhance.Sharpness(pil).enhance(1.10)
    buf = _io.BytesIO()
    pil.save(buf, format='JPEG', quality=92)
    return base64.b64encode(buf.getvalue()).decode()


def _zone_centers(landmarks) -> dict:
    """Centros anatómicos de zonas como coordenadas normalizadas (0-1)."""
    lm = list(landmarks)
    zone_idx = {
        "frente":      [10, 109, 67, 103, 54, 21, 162, 127],
        "ojos":        [33, 133, 362, 263, 159, 145, 374, 386],
        "mejillas":    [116, 345, 187, 411, 50, 280],
        "boca_surcos": [61, 291, 0, 17, 57, 287],
        "mandibula":   [172, 397, 152, 377, 148],
        "luminosidad": [234, 454, 10, 152],
    }
    out = {}
    for zone, indices in zone_idx.items():
        pts = [(lm[i].x, lm[i].y) for i in indices if i < len(lm)]
        if pts:
            out[zone] = {
                "x": round(sum(p[0] for p in pts) / len(pts), 4),
                "y": round(sum(p[1] for p in pts) / len(pts), 4),
            }
    return out


def _make_zone_b64(crops: list) -> str:
    """Combina recortes de zonas horizontalmente y retorna como base64 JPEG."""
    valid = [c for c in crops if c is not None and isinstance(c, np.ndarray) and c.size > 0]
    if not valid:
        return ""
    if len(valid) == 1:
        combined = valid[0]
    else:
        target_h = max(c.shape[0] for c in valid)
        resized = []
        for c in valid:
            h, w = c.shape[:2]
            if h == 0:
                continue
            new_w = max(1, int(w * target_h / h))
            resized.append(cv2.resize(c, (new_w, target_h)))
        combined = np.hstack(resized) if len(resized) > 1 else resized[0]
    h, w = combined.shape[:2]
    if w > 480:
        new_h = max(1, int(h * 480 / w))
        combined = cv2.resize(combined, (480, new_h))
    bgr = cv2.cvtColor(combined, cv2.COLOR_RGB2BGR)
    _, buf = cv2.imencode('.jpg', bgr, [cv2.IMWRITE_JPEG_QUALITY, 82])
    return base64.b64encode(buf.tobytes()).decode()


# ── App ────────────────────────────────────────────────────────────────────────

app = FastAPI(title="Mesoterapia Facial AI", version="1.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

face_detector      = FaceDetector()
zone_segmenter     = ZoneSegmenter()
wrinkle_analyzer   = WrinkleAnalyzer()
sagging_analyzer   = SaggingAnalyzer()
spot_analyzer      = SpotAnalyzer()
pore_analyzer      = PoreAnalyzer()
dark_circle_analyzer = DarkCircleAnalyzer()
luminosity_analyzer  = LuminosityAnalyzer()
volume_analyzer      = VolumeAnalyzer()
zone_scorer          = ZoneScorer()
protocol_mapper      = ProtocolMapper()
visual_report        = VisualReportGenerator()
text_report          = TextReportGenerator()
whatsapp_client      = WhatsAppClient()


@app.get("/health")
def health_check():
    return {"status": "ok", "service": "Mesoterapia Facial AI", "version": "1.1.0"}


@app.post("/api/analyze")
async def analyze_face(
    photo: UploadFile = File(...),
    age: Optional[int] = Form(default=40),
):
    """
    Recibe foto del rostro y edad, retorna análisis completo con recomendaciones.
    age: edad de la cliente (default 40 si no se envía)
    """
    contents = await photo.read()

    # 1. Detectar rostro y extraer landmarks
    landmarks, image_rgb = face_detector.detect(contents)
    if landmarks is None:
        raise HTTPException(
            status_code=422,
            detail="No se detectó ningún rostro en la imagen. Por favor toma una foto frontal con buena iluminación."
        )

    # 2. Guardar cara limpia ANTES de normalización (para mostrar en app)
    face_clean_b64 = _clean_face_b64(image_rgb)
    face_centers   = _zone_centers(landmarks)

    # Normalización de iluminación (reduce falsos positivos por luz)
    image_rgb = _normalize_illumination(image_rgb)

    # 3. Segmentar zonas del rostro
    zones = zone_segmenter.segment(image_rgb, landmarks)

    # Generar imágenes recortadas por zona
    zone_images = {
        "frente":      _make_zone_b64([zones.get("frente")]),
        "ojos":        _make_zone_b64([zones.get("ojo_izq"), zones.get("ojo_der")]),
        "mejillas":    _make_zone_b64([zones.get("mejilla_izq"), zones.get("mejilla_der")]),
        "boca_surcos": _make_zone_b64([zones.get("boca")]),
        "mandibula":   _make_zone_b64([zones.get("mandibula")]),
        "cuello":      _make_zone_b64([zones.get("cuello")]),
    }

    # 4. Analizar cada condición
    results = {}
    results["arrugas_frontales"]    = wrinkle_analyzer.analyze_forehead(zones["frente"])
    results["lineas_entrecejo"]     = wrinkle_analyzer.analyze_glabella(zones["entrecejo"], landmarks)
    results["patas_gallo"]          = wrinkle_analyzer.analyze_crow_feet(zones["ojo_izq"], zones["ojo_der"])
    results["arrugas_periorales"]   = wrinkle_analyzer.analyze_perioral(zones["boca"])
    results["surcos_nasogenianos"]  = sagging_analyzer.analyze_nasolabial(landmarks)
    results["lineas_marioneta"]     = sagging_analyzer.analyze_marionette(landmarks)
    results["mejillas_caidas"]      = sagging_analyzer.analyze_cheek_sagging(landmarks)
    results["mandibula_indefinida"] = sagging_analyzer.analyze_jawline(landmarks)
    results["parpados_caidos"]      = sagging_analyzer.analyze_eyelid_ptosis(landmarks)
    results["doble_menton"]         = sagging_analyzer.analyze_double_chin(landmarks)
    results["manchas"]              = spot_analyzer.analyze(zones["mejilla_izq"], zones["mejilla_der"], zones["frente"])
    results["poros_dilatados"]      = pore_analyzer.analyze(zones["mejilla_izq"], zones["mejilla_der"])
    results["ojeras"]               = dark_circle_analyzer.analyze(zones["ojo_izq"], zones["ojo_der"])
    results["bolsas_ojos"]          = dark_circle_analyzer.analyze_bags(zones["ojo_izq"], zones["ojo_der"])
    results["perdida_volumen"]      = volume_analyzer.analyze(landmarks)
    results["piel_opaca"]           = luminosity_analyzer.analyze_luminosity(image_rgb, landmarks)
    results["tono_desigual"]        = luminosity_analyzer.analyze_tone_evenness(image_rgb, landmarks)
    results["textura_irregular"]    = wrinkle_analyzer.analyze_texture(image_rgb, landmarks)

    # 5. Corrección por edad
    age_safe = max(16, min(90, age or 40))
    factor = _age_factor(age_safe)
    results = _apply_age_correction(results, factor)

    # 6. Calcular scores por zona (umbral mínimo de confianza = 38)
    scores = zone_scorer.calculate(results)

    # 7. Mapear a protocolos (threshold elevado para reducir falsos positivos)
    treatment_plan = protocol_mapper.map(results, scores, min_score=38)

    # 8. Generar imagen del rostro con overlay de zonas
    report_image_b64 = visual_report.generate(image_rgb, landmarks, scores, treatment_plan)

    # 9. Generar texto para WhatsApp
    whatsapp_text = text_report.generate(scores, treatment_plan)

    return JSONResponse({
        "scores": scores,
        "conditions": results,
        "treatment_plan": treatment_plan,
        "face_image_base64": face_clean_b64,      # cara limpia para app
        "report_image_base64": report_image_b64,  # con overlay para compartir
        "zone_images": zone_images,
        "zone_centers": face_centers,             # coordenadas anatómicas
        "whatsapp_text": whatsapp_text,
        "age_applied": age_safe,
        "age_factor": round(factor, 2),
    })


@app.post("/api/send-whatsapp")
async def send_whatsapp(
    phone: str = Form(...),
    report_image_b64: str = Form(...),
    whatsapp_text: str = Form(...),
):
    phone = phone.strip().replace(" ", "").replace("-", "")
    if not phone.startswith("593"):
        phone = "593" + phone.lstrip("0")
    ok = await whatsapp_client.send_analysis(phone, report_image_b64, whatsapp_text)
    if not ok:
        raise HTTPException(status_code=500, detail="Error al enviar por WhatsApp.")
    return {"success": True, "sent_to": phone}


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
