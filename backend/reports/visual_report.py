import base64
import io
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from typing import Dict

# Colores por severidad (R, G, B, A)
COLORS = {
    "Avanzada":  (244, 67,  54,  180),   # rojo
    "Moderada":  (255, 152,  0,  160),   # naranja
    "Leve":      (139, 195, 74,  140),   # verde claro
    "Óptima":    (76,  175, 80,   80),   # verde
}

# Índices MediaPipe aproximados por zona para trazar polígono overlay
# (subset reducido para dibujo, no todos los 468 landmarks)
ZONE_DRAW_INDICES = {
    "frente":        [10, 109, 67, 103, 54, 21, 162, 127, 234, 93, 132, 58, 172,
                      136, 150, 149, 176, 148, 152, 377, 400, 378, 379, 365, 397,
                      288, 361, 323, 454, 356, 389, 251, 284, 332, 297, 338],
    "ojos":          [33, 246, 161, 160, 159, 158, 157, 173, 133, 155, 154, 153,
                      145, 144, 163, 7,
                      362, 398, 384, 385, 386, 387, 388, 466, 263, 249, 390, 373,
                      374, 380, 381, 382],
    "mejillas":      [116, 117, 118, 119, 120, 121, 128, 245, 188, 174,
                      345, 346, 347, 348, 349, 350, 357, 465, 412, 399],
    "boca_surcos":   [61, 84, 17, 314, 405, 321, 375, 291, 409, 270,
                      267, 0, 37, 39, 40, 185, 92, 322, 287, 410],
    "mandibula":     [172, 136, 150, 149, 176, 148, 152, 377, 400,
                      378, 379, 365, 397, 288, 361, 323],
    "luminosidad":   [],  # Zona global, no se dibuja polígono
}


def _landmarks_to_px(landmarks, w: int, h: int) -> np.ndarray:
    return np.array([[int(lm.x * w), int(lm.y * h)] for lm in landmarks])


class VisualReportGenerator:
    """
    Genera imagen del reporte con:
    - Foto del rostro con overlay de zonas coloreadas
    - Panel derecho con scores y recomendaciones
    """

    PANEL_W = 420
    FONT_SIZE_TITLE = 22
    FONT_SIZE_BODY = 17
    FONT_SIZE_SMALL = 14

    def generate(self, image: np.ndarray, landmarks, scores: Dict, treatment_plan: Dict) -> str:
        """Retorna imagen del reporte en base64 (JPEG)."""
        pil_img = Image.fromarray(image).convert("RGBA")

        # Escalar la foto a altura fija para consistencia
        target_h = 700
        ratio = target_h / pil_img.height
        face_w = int(pil_img.width * ratio)
        pil_img = pil_img.resize((face_w, target_h), Image.LANCZOS)
        lm_scaled = [(int(lm.x * face_w), int(lm.y * target_h)) for lm in landmarks]

        # Dibujar overlay de zonas
        overlay = Image.new("RGBA", pil_img.size, (0, 0, 0, 0))
        draw_overlay = ImageDraw.Draw(overlay)
        zone_scores = scores.get("zones", {})

        for zone_name, indices in ZONE_DRAW_INDICES.items():
            if not indices:
                continue
            zone_data = zone_scores.get(zone_name, {})
            severity = zone_data.get("severity", "Óptima")
            color = COLORS.get(severity, COLORS["Óptima"])

            pts = [lm_scaled[i] for i in indices if i < len(lm_scaled)]
            if len(pts) >= 3:
                draw_overlay.polygon(pts, fill=color)

        face_composite = Image.alpha_composite(pil_img, overlay).convert("RGB")

        # Crear panel lateral
        panel = self._build_panel(scores, treatment_plan, target_h)

        # Unir foto + panel
        total_w = face_w + self.PANEL_W
        report = Image.new("RGB", (total_w, target_h), (18, 18, 18))
        report.paste(face_composite, (0, 0))
        report.paste(panel, (face_w, 0))

        # Serializar a base64
        buf = io.BytesIO()
        report.save(buf, format="JPEG", quality=88)
        return base64.b64encode(buf.getvalue()).decode()

    def _build_panel(self, scores: Dict, treatment_plan: Dict, height: int) -> Image.Image:
        panel = Image.new("RGB", (self.PANEL_W, height), (18, 18, 18))
        draw = ImageDraw.Draw(panel)

        try:
            font_title = ImageFont.truetype("arial.ttf", self.FONT_SIZE_TITLE)
            font_body  = ImageFont.truetype("arial.ttf", self.FONT_SIZE_BODY)
            font_small = ImageFont.truetype("arial.ttf", self.FONT_SIZE_SMALL)
        except Exception:
            font_title = font_body = font_small = ImageFont.load_default()

        y = 14
        pad = 12

        # --- Encabezado ---
        draw.text((pad, y), "ANÁLISIS FACIAL IA", font=font_title, fill=(255, 255, 255))
        y += 26
        draw.text((pad, y), "Emprender · Mesoterapia Sin Agujas", font=font_small, fill=(160, 160, 160))
        y += 24
        draw.line([(pad, y), (self.PANEL_W - pad, y)], fill=(60, 60, 60), width=1)
        y += 10

        # --- Score global ---
        global_score = scores.get("global", 0)
        severity = scores.get("global_severity", "Leve")
        sev_color = {
            "Avanzada": (244, 67, 54),
            "Moderada": (255, 152, 0),
            "Leve":     (139, 195, 74),
            "Óptima":   (76, 175, 80),
        }.get(severity, (160, 160, 160))

        draw.text((pad, y), f"SCORE GLOBAL: {global_score:.0f}/100", font=font_body, fill=(255, 255, 255))
        y += 22
        bar_w = self.PANEL_W - pad * 2
        bar_fill = int(bar_w * global_score / 100)
        draw.rectangle([pad, y, pad + bar_w, y + 10], fill=(50, 50, 50))
        draw.rectangle([pad, y, pad + bar_fill, y + 10], fill=sev_color)
        y += 18

        draw.text((pad, y), f"Severidad global: {severity}", font=font_small, fill=sev_color)
        y += 22
        draw.line([(pad, y), (self.PANEL_W - pad, y)], fill=(60, 60, 60), width=1)
        y += 10

        # --- Scores por zona ---
        draw.text((pad, y), "ZONAS ANALIZADAS:", font=font_body, fill=(200, 200, 200))
        y += 22

        zone_labels = {
            "frente":      "Frente",
            "ojos":        "Contorno ojos",
            "mejillas":    "Mejillas",
            "boca_surcos": "Surcos / boca",
            "mandibula":   "Mandíbula",
            "luminosidad": "Luminosidad",
        }

        zone_scores = scores.get("zones", {})
        for zone_key, zone_label in zone_labels.items():
            zd = zone_scores.get(zone_key, {})
            zs = zd.get("score", 0)
            zv = zd.get("severity", "Óptima")
            dot_color = {
                "Avanzada": (244, 67, 54),
                "Moderada": (255, 152, 0),
                "Leve":     (139, 195, 74),
                "Óptima":   (76, 175, 80),
            }.get(zv, (100, 100, 100))

            draw.ellipse([pad, y + 3, pad + 8, y + 11], fill=dot_color)
            draw.text((pad + 14, y), f"{zone_label:<16} {zs:>5.0f}/100", font=font_small, fill=(220, 220, 220))
            y += 18

            if y > height - 160:
                break

        y += 6
        draw.line([(pad, y), (self.PANEL_W - pad, y)], fill=(60, 60, 60), width=1)
        y += 10

        # --- Protocolos recomendados ---
        protocols = treatment_plan.get("protocols", [])
        if protocols:
            draw.text((pad, y), "TRATAMIENTOS:", font=font_body, fill=(200, 200, 200))
            y += 22
            for i, proto in enumerate(protocols[:3], 1):
                pname = proto.get("nombre", "")
                pprice = proto.get("precio", 0)
                ppack = proto.get("pack6", 0)
                prio = proto.get("priority", "")
                prio_color = (244, 67, 54) if prio == "PRIORITARIO" else (255, 152, 0)

                draw.text((pad, y), f"{i}. {pname[:30]}", font=font_small, fill=(255, 255, 255))
                y += 16
                draw.text((pad + 10, y), f"${pprice}/sesión · Pack 6: ${ppack}", font=font_small, fill=(140, 200, 140))
                y += 14
                draw.text((pad + 10, y), prio, font=font_small, fill=prio_color)
                y += 18
                if y > height - 80:
                    break

        # --- Combo sugerido ---
        combo = treatment_plan.get("combo_suggestion", {})
        if combo:
            y += 4
            draw.line([(pad, y), (self.PANEL_W - pad, y)], fill=(60, 60, 60), width=1)
            y += 8
            draw.text((pad, y), "PACK COMBINADO:", font=font_small, fill=(255, 215, 0))
            y += 16
            draw.text((pad, y), f"${combo.get('precio_combo', 0)} (ahorro ${combo.get('ahorro', 0)})", font=font_small, fill=(140, 200, 140))
            y += 18

        # --- Footer ---
        footer_y = height - 46
        draw.line([(pad, footer_y), (self.PANEL_W - pad, footer_y)], fill=(60, 60, 60), width=1)
        draw.text((pad, footer_y + 6), "Isidoro Acurio Fiallos y Bolívar Leal", font=font_small, fill=(120, 120, 120))
        draw.text((pad, footer_y + 20), "Mercado La Colón · Milagro, Ecuador", font=font_small, fill=(120, 120, 120))

        return panel
