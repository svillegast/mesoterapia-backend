import numpy as np
import cv2
from typing import Dict


class LuminosityAnalyzer:
    """
    Evalúa luminosidad global (piel opaca) y uniformidad del tono.
    """

    def analyze_luminosity(self, image: np.ndarray, landmarks) -> Dict:
        """
        Analiza si la piel tiene brillo/luminosidad o está opaca.

        No usa brillo absoluto (mean_l) porque eso confunde "piel opaca" con
        "foto tomada con poca luz" — dos fotos de la misma piel con distinta
        iluminación daban scores muy distintos. En su lugar mide qué tan lejos
        está el promedio del punto más brillante DENTRO de la misma foto
        (percentil 95). Una piel realmente opaca tiene poco contraste entre su
        punto más luminoso y el promedio, incluso bajo buena luz; una foto
        oscura pero uniforme (mala iluminación, piel sana) mantiene esa
        relación baja porque ambos valores bajan juntos.
        """
        if image is None or image.size == 0:
            return {"score": 0.0, "condition": "piel_opaca"}

        lab = cv2.cvtColor(image, cv2.COLOR_RGB2LAB)
        l_channel = lab[:, :, 0].astype(float)

        p95 = np.percentile(l_channel, 95)
        mean_l = np.mean(l_channel)
        if p95 < 1e-6:
            return {"score": 0.0, "condition": "piel_opaca"}

        relative_dullness = (p95 - mean_l) / p95
        # Recalibrado 2026-08-25 con fotos reales: la normalización CLAHE de
        # main.py empuja el P95 casi al máximo (~220-229/255), así que el
        # divisor original (0.35) saturaba el score en 100 para todas las
        # fotos probadas (rango real observado: 0.40-0.50). Divisor ajustado
        # para que ese rango caiga en zona media, no en el techo. Sigue
        # siendo una calibración inicial — afinar cuando haya casos reales
        # confirmados de piel opaca vs. sana para comparar.
        score = np.clip(relative_dullness / 0.75 * 100, 0, 100)
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
        # Recalibrado 2026-08-25: mismo problema que piel_opaca — con CLAHE
        # ya aplicado, la variación real entre regiones en fotos normales
        # midió 17-34, y el divisor original (15) saturaba el score en 100
        # siempre. Igual que arriba, calibración inicial a falta de casos
        # reales confirmados de tono desigual vs. uniforme.
        # Segunda pasada (2026-08-28): el divisor 40 daba un score demasiado
        # bajo (25) para un caso confirmado por el usuario como "mínimo
        # Moderado" — ajustado a 18.
        score = np.clip(variance / 18 * 100, 0, 100)
        return {"score": round(float(score), 1), "condition": "tono_desigual"}
