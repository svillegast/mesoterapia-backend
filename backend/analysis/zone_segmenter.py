import numpy as np
import cv2
from typing import Dict

# Índices de landmarks MediaPipe Face Mesh por zona
# Referencia: https://github.com/google/mediapipe/wiki/MediaPipe-Face-Mesh
ZONE_LANDMARKS = {
    # Frente: banda superior entre cejas y línea del cabello
    "frente": [10, 338, 297, 332, 284, 251, 389, 356, 454, 323, 361, 288,
               397, 365, 379, 378, 400, 377, 152, 148, 176, 149, 150, 136,
               172, 58, 132, 93, 234, 127, 162, 21, 54, 103, 67, 109],

    # Entrecejo (glabela)
    "entrecejo": [9, 107, 66, 105, 63, 70, 46, 53, 52, 65, 55, 285, 295,
                  282, 283, 276, 353, 336, 296, 334],

    # Ojo izquierdo completo (párpado + contorno lateral)
    "ojo_izq": [33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158,
                159, 160, 161, 246, 130, 25, 110, 24, 23, 22, 26, 112, 243],

    # Ojo derecho completo
    "ojo_der": [362, 382, 381, 380, 374, 373, 390, 249, 263, 466, 388, 387,
                386, 385, 384, 398, 359, 255, 339, 254, 253, 252, 256, 341, 463],

    # Mejilla izquierda
    "mejilla_izq": [116, 117, 118, 119, 120, 121, 128, 245, 188, 174, 196,
                    197, 198, 209, 210, 211, 212, 202, 214, 215, 138, 135,
                    169, 170, 140, 171, 175],

    # Mejilla derecha
    "mejilla_der": [345, 346, 347, 348, 349, 350, 357, 465, 412, 399, 419,
                    420, 421, 429, 430, 431, 432, 422, 434, 435, 367, 364,
                    394, 395, 369, 396, 400],

    # Zona de la boca y labios
    "boca": [61, 84, 17, 314, 405, 321, 375, 291, 409, 270, 269, 267, 0,
             37, 39, 40, 185, 61, 76, 77, 90, 180, 85, 16, 315, 404,
             320, 307, 306, 408, 304, 303, 302, 11, 72, 38],

    # Mandíbula y contorno inferior
    "mandibula": [172, 136, 150, 149, 176, 148, 152, 377, 400, 378, 379,
                  365, 397, 288, 361, 323, 454, 356, 389, 251, 284, 332,
                  297, 338, 10, 109, 67, 103, 54, 21, 162, 127, 234, 93,
                  132, 58],

    # Cuello (estimado bajo la mandíbula)
    "cuello": [152, 377, 378, 379, 365, 397, 288, 172, 136, 150, 149, 176, 148],
}


class ZoneSegmenter:
    """
    Recorta cada zona del rostro usando los landmarks como máscara.
    """

    def segment(self, image: np.ndarray, landmarks) -> Dict[str, np.ndarray]:
        """
        Retorna un dict con cada zona recortada como imagen numpy.
        """
        h, w = image.shape[:2]
        pts_all = np.array([[int(lm.x * w), int(lm.y * h)] for lm in landmarks])

        zones = {}
        for zone_name, indices in ZONE_LANDMARKS.items():
            pts = pts_all[indices]
            # CORREGIDO 2026-08-28: los landmarks de "ojo_izq"/"ojo_der" son
            # el contorno del párpado (estándar de MediaPipe) — con el
            # margen normal de 10%, el recorte apenas toca el borde del ojo
            # y NO llega al área real de ojeras/bolsas, que está más abajo,
            # hacia el pómulo. Detectado por el usuario probando la app real
            # (la "zona de análisis" mostraba mayormente el ojo, no la piel
            # de debajo). Se agrega margen extra hacia abajo solo para estas
            # 2 zonas.
            extra_bottom = 0.60 if zone_name in ("ojo_izq", "ojo_der") else 0.0
            zones[zone_name] = self._crop_zone(image, pts, extra_bottom_pad=extra_bottom)

        return zones

    def _crop_zone(self, image: np.ndarray, pts: np.ndarray, extra_bottom_pad: float = 0.0) -> np.ndarray:
        """
        Recorta la región convexa del rostro definida por los puntos.
        extra_bottom_pad: margen adicional hacia abajo, como fracción de la
        altura del recorte (ej. 0.60 = 60% más de altura hacia abajo).
        """
        x, y, bw, bh = cv2.boundingRect(pts)
        # Agregar margen del 10%
        pad_x = max(int(bw * 0.10), 5)
        pad_y = max(int(bh * 0.10), 5)
        pad_bottom_extra = int(bh * extra_bottom_pad)
        h, w = image.shape[:2]
        x1 = max(0, x - pad_x)
        y1 = max(0, y - pad_y)
        x2 = min(w, x + bw + pad_x)
        y2 = min(h, y + bh + pad_y + pad_bottom_extra)
        return image[y1:y2, x1:x2].copy()
