from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import os
from dotenv import load_dotenv

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

app = FastAPI(title="Mesoterapia Facial AI", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inicializar componentes una sola vez
face_detector = FaceDetector()
zone_segmenter = ZoneSegmenter()
wrinkle_analyzer = WrinkleAnalyzer()
sagging_analyzer = SaggingAnalyzer()
spot_analyzer = SpotAnalyzer()
pore_analyzer = PoreAnalyzer()
dark_circle_analyzer = DarkCircleAnalyzer()
luminosity_analyzer = LuminosityAnalyzer()
volume_analyzer = VolumeAnalyzer()
zone_scorer = ZoneScorer()
protocol_mapper = ProtocolMapper()
visual_report = VisualReportGenerator()
text_report = TextReportGenerator()
whatsapp_client = WhatsAppClient()


@app.get("/health")
def health_check():
    return {"status": "ok", "service": "Mesoterapia Facial AI"}


@app.post("/api/analyze")
async def analyze_face(photo: UploadFile = File(...)):
    """
    Recibe foto del rostro y retorna análisis completo con recomendaciones.
    """
    contents = await photo.read()

    # 1. Detectar rostro y extraer landmarks
    landmarks, image_rgb = face_detector.detect(contents)
    if landmarks is None:
        raise HTTPException(
            status_code=422,
            detail="No se detectó ningún rostro en la imagen. Por favor toma una foto frontal con buena iluminación."
        )

    # 2. Segmentar zonas del rostro
    zones = zone_segmenter.segment(image_rgb, landmarks)

    # 3. Analizar cada condición
    results = {}

    results["arrugas_frontales"]   = wrinkle_analyzer.analyze_forehead(zones["frente"])
    results["lineas_entrecejo"]    = wrinkle_analyzer.analyze_glabella(zones["entrecejo"], landmarks)
    results["patas_gallo"]         = wrinkle_analyzer.analyze_crow_feet(zones["ojo_izq"], zones["ojo_der"])
    results["arrugas_periorales"]  = wrinkle_analyzer.analyze_perioral(zones["boca"])
    results["surcos_nasogenianos"] = sagging_analyzer.analyze_nasolabial(landmarks)
    results["lineas_marioneta"]    = sagging_analyzer.analyze_marionette(landmarks)
    results["mejillas_caidas"]     = sagging_analyzer.analyze_cheek_sagging(landmarks)
    results["mandibula_indefinida"]= sagging_analyzer.analyze_jawline(landmarks)
    results["parpados_caidos"]     = sagging_analyzer.analyze_eyelid_ptosis(landmarks)
    results["doble_menton"]        = sagging_analyzer.analyze_double_chin(landmarks)
    results["manchas"]             = spot_analyzer.analyze(zones["mejilla_izq"], zones["mejilla_der"], zones["frente"])
    results["poros_dilatados"]     = pore_analyzer.analyze(zones["mejilla_izq"], zones["mejilla_der"])
    results["ojeras"]              = dark_circle_analyzer.analyze(zones["ojo_izq"], zones["ojo_der"])
    results["bolsas_ojos"]         = dark_circle_analyzer.analyze_bags(zones["ojo_izq"], zones["ojo_der"])
    results["perdida_volumen"]     = volume_analyzer.analyze(landmarks)
    results["piel_opaca"]          = luminosity_analyzer.analyze_luminosity(image_rgb, landmarks)
    results["tono_desigual"]       = luminosity_analyzer.analyze_tone_evenness(image_rgb, landmarks)
    results["textura_irregular"]   = wrinkle_analyzer.analyze_texture(image_rgb, landmarks)

    # 4. Calcular scores por zona
    scores = zone_scorer.calculate(results)

    # 5. Mapear a protocolos recomendados
    treatment_plan = protocol_mapper.map(results, scores)

    # 6. Generar reporte visual (imagen con overlay)
    report_image_b64 = visual_report.generate(image_rgb, landmarks, scores, treatment_plan)

    # 7. Generar texto personalizado para WhatsApp
    whatsapp_text = text_report.generate(scores, treatment_plan)

    return JSONResponse({
        "scores": scores,
        "conditions": results,
        "treatment_plan": treatment_plan,
        "report_image_base64": report_image_b64,
        "whatsapp_text": whatsapp_text,
    })


@app.post("/api/send-whatsapp")
async def send_whatsapp(
    phone: str = Form(...),
    report_image_b64: str = Form(...),
    whatsapp_text: str = Form(...),
):
    """
    Envía reporte de análisis facial al cliente por WhatsApp.
    """
    phone = phone.strip().replace(" ", "").replace("-", "")
    if not phone.startswith("593"):
        phone = "593" + phone.lstrip("0")

    ok = await whatsapp_client.send_analysis(phone, report_image_b64, whatsapp_text)
    if not ok:
        raise HTTPException(status_code=500, detail="Error al enviar por WhatsApp.")

    return {"success": True, "sent_to": phone}


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
