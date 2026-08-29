import numpy as np
from typing import Dict


# Índices clave de landmarks MediaPipe para análisis geométrico
LM = {
    # Mandíbula
    "chin": 152,
    "jaw_l": 234,
    "jaw_r": 454,
    "jaw_mid_l": 172,
    "jaw_mid_r": 397,

    # Mejillas
    "cheek_l_high": 116,
    "cheek_r_high": 345,
    "cheek_l_low": 138,
    "cheek_r_low": 367,

    # Surcos nasogenianos
    "nasolabial_l": 92,
    "nasolabial_r": 322,
    "nose_tip": 4,
    "mouth_corner_l": 61,
    "mouth_corner_r": 291,

    # Líneas de marioneta
    "marionette_l": 172,
    "marionette_r": 397,
    "chin_l": 176,
    "chin_r": 400,

    # Párpados
    "upper_lid_l": 159,
    "lower_lid_l": 145,
    "upper_lid_r": 386,
    "lower_lid_r": 374,
    "eye_inner_l": 133,
    "eye_inner_r": 362,

    # Cuello / doble mentón
    "chin_bottom": 152,
    "throat": 199,
}


def _dist(lm_a, lm_b) -> float:
    return np.sqrt((lm_a.x - lm_b.x) ** 2 + (lm_a.y - lm_b.y) ** 2)


class SaggingAnalyzer:
    """
    Detecta flacidez, caídas y pérdida de definición usando geometría de landmarks.
    """

    def analyze_nasolabial(self, landmarks) -> Dict:
        """Profundidad de surcos nasogenianos por Z-depth relativo."""
        nose = landmarks[LM["nose_tip"]]
        nl_l = landmarks[LM["nasolabial_l"]]
        nl_r = landmarks[LM["nasolabial_r"]]

        # Diferencia Z entre punta nariz y surco (surco más profundo = mayor Z relativo)
        z_depth_l = abs(nl_l.z - nose.z)
        z_depth_r = abs(nl_r.z - nose.z)
        z_avg = (z_depth_l + z_depth_r) / 2

        # Recalibrado 2026-08-28 con 7 fotos reales: divisor original (0.04)
        # saturaba en 100 siempre — rango real observado 0.04-0.27.
        score = np.clip(z_avg / 0.30 * 100, 0, 100)
        return {"score": round(float(score), 1), "condition": "surcos_nasogenianos"}

    def analyze_marionette(self, landmarks) -> Dict:
        """Líneas de marioneta: descenso de comisura labial."""
        corner_l = landmarks[LM["mouth_corner_l"]]
        corner_r = landmarks[LM["mouth_corner_r"]]
        mar_l = landmarks[LM["marionette_l"]]
        mar_r = landmarks[LM["marionette_r"]]

        # Ángulo de descenso de comisura (positivo = comisura más baja)
        drop_l = mar_l.y - corner_l.y
        drop_r = mar_r.y - corner_r.y
        avg_drop = (drop_l + drop_r) / 2

        # Recalibrado 2026-08-28: divisor original (0.03) saturaba en 100 casi
        # siempre — rango real observado -0.01 a 0.09.
        score = np.clip(avg_drop / 0.10 * 100, 0, 100)
        return {"score": round(float(score), 1), "condition": "lineas_marioneta"}

    def analyze_cheek_sagging(self, landmarks) -> Dict:
        """Flacidez de mejillas: pendiente del contorno entre pómulo y mandíbula."""
        ch_l_h = landmarks[LM["cheek_l_high"]]
        ch_l_low = landmarks[LM["cheek_l_low"]]
        ch_r_h = landmarks[LM["cheek_r_high"]]
        ch_r_low = landmarks[LM["cheek_r_low"]]

        # A mayor diferencia vertical (pómulo vs mejilla baja), más caída
        slope_l = ch_l_low.y - ch_l_h.y
        slope_r = ch_r_low.y - ch_r_h.y
        avg_slope = (slope_l + slope_r) / 2

        # Recalibrado 2026-08-28: divisor original (0.12) saturaba en 100 casi
        # siempre — rango real observado 0.09-0.25.
        score = np.clip(avg_slope / 0.35 * 100, 0, 100)
        return {"score": round(float(score), 1), "condition": "mejillas_caidas"}

    def analyze_jawline(self, landmarks) -> Dict:
        """Definición mandibular: ángulo y rectitud del jawline."""
        jaw_l = landmarks[LM["jaw_l"]]
        jaw_r = landmarks[LM["jaw_r"]]
        chin = landmarks[LM["chin"]]

        # Curvatura del jawline: si chin está muy arriba respecto a jaw_l/jaw_r = mandíbula difusa
        mid_y = (jaw_l.y + jaw_r.y) / 2
        deviation = abs(chin.y - mid_y)

        # Ancho mandibular vs ancho facial
        jaw_width = _dist(jaw_l, jaw_r)
        face_width = jaw_width  # normalizado por sí mismo

        # AVISO 2026-08-28: en 7 fotos reales, `deviation` salió siempre entre
        # 0.13-0.51 — muy por encima del 0.05 que la fórmula asume como
        # "mandíbula bien definida". El mentón normalmente está bien por
        # debajo de la línea jaw_l/jaw_r, así que un valor alto de por sí no
        # necesariamente indica mala definición — el diseño de esta métrica
        # parece no medir lo que se pretendía, no es solo un tema de
        # divisor. NO se recalibra a ciegas sin un caso de referencia real
        # (alguien con mandíbula claramente definida vs. difusa para
        # comparar) — hoy siempre da 0, lo cual no perjudica al cliente,
        # pero tampoco es un dato confiable. Revisar con más cuidado antes
        # de usar este condition en producción.
        score = np.clip((0.05 - deviation) / 0.05 * 100, 0, 100)
        return {"score": round(float(score), 1), "condition": "mandibula_indefinida"}

    def analyze_eyelid_ptosis(self, landmarks) -> Dict:
        """Párpados caídos: apertura ocular reducida respecto a baseline."""
        # Apertura vertical del ojo (distancia párpado superior a inferior)
        lid_open_l = abs(landmarks[LM["upper_lid_l"]].y - landmarks[LM["lower_lid_l"]].y)
        lid_open_r = abs(landmarks[LM["upper_lid_r"]].y - landmarks[LM["lower_lid_r"]].y)
        avg_open = (lid_open_l + lid_open_r) / 2

        # Ancho del ojo como referencia de normalización
        eye_width_l = _dist(landmarks[LM["eye_inner_l"]], landmarks[33])
        eye_width_r = _dist(landmarks[LM["eye_inner_r"]], landmarks[263])
        avg_width = (eye_width_l + eye_width_r) / 2

        ratio = avg_open / (avg_width + 1e-6)

        # Recalibrado 2026-08-28: el "ideal" original (0.35-0.40) no coincidió
        # con ninguna de las 7 fotos reales (rango observado 0.15-0.31),
        # saturando en 100 casi siempre. Nota: algunas de estas fotos podían
        # tener lentes, lo que afecta la precisión de los landmarks de ojos —
        # confirmar este ajuste con fotos sin lentes cuando se pueda.
        # Segunda pasada (mismo día): el divisor 0.25 seguia dando un score
        # demasiado bajo para un caso real confirmado por el usuario como
        # "moderado a mas critico" — ajustado a 0.21.
        score = np.clip((0.35 - ratio) / 0.21 * 100, 0, 100)
        return {"score": round(float(score), 1), "condition": "parpados_caidos"}

    def analyze_double_chin(self, landmarks) -> Dict:
        """Doble mentón: posición del mentón vs cuello."""
        chin = landmarks[LM["chin_bottom"]]
        throat = landmarks[LM["throat"]]

        # Si el mentón tiene Z-depth parecido al cuello → doble mentón
        z_diff = abs(chin.z - throat.z)
        y_diff = abs(throat.y - chin.y)

        ratio = z_diff / (y_diff + 1e-6)
        # Recalibrado 2026-08-28: divisor original (0.5) saturaba en 100 casi
        # siempre — rango real observado 0.47-2.78.
        score = np.clip(ratio / 3.5 * 100, 0, 100)
        return {"score": round(float(score), 1), "condition": "doble_menton"}
