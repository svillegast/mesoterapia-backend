import base64
import io
import numpy as np
from PIL import Image, ImageDraw
from typing import Dict

# Colores por severidad (R, G, B, A)
COLORS = {
    "Avanzada":  (244, 67,  54,  170),
    "Moderada":  (255, 152,  0,  150),
    "Leve":      (139, 195, 74,  130),
    "Óptima":    (76,  175, 80,   70),
}

ZONE_DRAW_INDICES = {
    "frente":      [10, 109, 67, 103, 54, 21, 162, 127, 234, 93, 132, 58, 172,
                    136, 150, 149, 176, 148, 152, 377, 400, 378, 379, 365, 397,
                    288, 361, 323, 454, 356, 389, 251, 284, 332, 297, 338],
    "ojos":        [33, 246, 161, 160, 159, 158, 157, 173, 133, 155, 154, 153,
                    145, 144, 163, 7,
                    362, 398, 384, 385, 386, 387, 388, 466, 263, 249, 390, 373,
                    374, 380, 381, 382],
    "mejillas":    [116, 117, 118, 119, 120, 121, 128, 245, 188, 174,
                    345, 346, 347, 348, 349, 350, 357, 465, 412, 399],
    "boca_surcos": [61, 84, 17, 314, 405, 321, 375, 291, 409, 270,
                    267, 0, 37, 39, 40, 185, 92, 322, 287, 410],
    "mandibula":   [172, 136, 150, 149, 176, 148, 152, 377, 400,
                    378, 379, 365, 397, 288, 361, 323],
}


class VisualReportGenerator:
    """
    Genera imagen del rostro con overlay de zonas coloreadas.
    Sin panel lateral — toda la info se muestra en la app Flutter.
    """

    def generate(self, image: np.ndarray, landmarks, scores: Dict, treatment_plan: Dict) -> str:
        pil_img = Image.fromarray(image).convert("RGBA")

        # Escalar a altura fija
        target_h = 700
        ratio = target_h / pil_img.height
        face_w = int(pil_img.width * ratio)
        pil_img = pil_img.resize((face_w, target_h), Image.LANCZOS)
        lm_scaled = [(int(lm.x * face_w), int(lm.y * target_h)) for lm in landmarks]

        # Overlay de zonas coloreadas
        overlay = Image.new("RGBA", pil_img.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)
        zone_scores = scores.get("zones", {})

        for zone_name, indices in ZONE_DRAW_INDICES.items():
            zone_data = zone_scores.get(zone_name, {})
            severity = zone_data.get("severity", "Óptima")
            color = COLORS.get(severity, COLORS["Óptima"])
            pts = [lm_scaled[i] for i in indices if i < len(lm_scaled)]
            if len(pts) >= 3:
                draw.polygon(pts, fill=color)

        face_out = Image.alpha_composite(pil_img, overlay).convert("RGB")

        buf = io.BytesIO()
        face_out.save(buf, format="JPEG", quality=88)
        return base64.b64encode(buf.getvalue()).decode()
