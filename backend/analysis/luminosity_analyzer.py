import numpy as np
import cv2
from typing import Dict


class LuminosityAnalyzer:
    """
    Evalúa luminosidad global (piel opaca) y uniformidad del tono.
    """

    def analyze_luminosity(self, image: np.ndarray, landmarks) -> Dict:
        """Analiza si la piel tiene brillo/luminosidad o está opaca."""
        if image is None or image.size == 0:
            return {"score": 0.0, "condition": "piel_opaca"}

        lab = cv2.cvtColor(image, cv2.COLOR_RGB2LAB)
        l_channel = lab[:, :, 0].astype(float)

        mean_l = np.mean(l_channel)
        # Luminancia alta = piel brillante. Baja = opaca.
        # Escala LAB: 0 (negro) - 255 (blanco)
        # Piel sana: ~140-180 en LAB L
        score = np.clip((180 - mean_l) / 80 * 100, 0, 100)
        return {"score": round(float(score), 1), "condition": "piel_opaca"}

    def analyze_tone_evenness(self, image: np.ndarray, landmarks) -> Dict:
        """Analiza uniformidad del tono: variación de color entre zonas."""
        if image is None or image.size == 0:
            return {"score": 0.0, "condition": "tono_desigual"}

        lab = cv2.cvtColor(image, cv2.COLOR_RGB2LAB)
        l_channel = lab[:, :, 0].astype(float)
        a_channel = lab[:, :, 1].astype(float)

        # Dividir imagen en 6 regiones y medir varianza de color entre ellas
        h, w = l_channel.shape
        regions = []
        for i in range(2):
            for j in range(3):
                r = l_channel[i * h // 2:(i + 1) * h // 2, j * w // 3:(j + 1) * w // 3]
                if r.size > 0:
                    regions.append(np.mean(r))

        if len(regions) < 2:
            return {"score": 0.0, "condition": "tono_desigual"}

        variance = np.std(regions)
        score = np.clip(variance / 15 * 100, 0, 100)
        return {"score": round(float(score), 1), "condition": "tono_desigual"}
