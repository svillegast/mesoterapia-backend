import numpy as np
import cv2
from typing import Dict


class DarkCircleAnalyzer:
    """
    Detecta ojeras (oscurecimiento infraorbital) y bolsas bajo los ojos.
    """

    def analyze(self, zone_l: np.ndarray, zone_r: np.ndarray) -> Dict:
        score_l = self._dark_circle_score(zone_l)
        score_r = self._dark_circle_score(zone_r)
        score = (score_l + score_r) / 2
        return {"score": round(float(score), 1), "condition": "ojeras"}

    def analyze_bags(self, zone_l: np.ndarray, zone_r: np.ndarray) -> Dict:
        score_l = self._bag_score(zone_l)
        score_r = self._bag_score(zone_r)
        score = (score_l + score_r) / 2
        return {"score": round(float(score), 1), "condition": "bolsas_ojos"}

    def _dark_circle_score(self, region: np.ndarray) -> float:
        """
        Compara luminancia del tercio inferior del ojo (bajo-ojo) vs tercio superior.
        Diferencia mayor = ojera más oscura.
        """
        if region is None or region.size == 0 or region.shape[0] < 15:
            return 0.0

        lab = cv2.cvtColor(region, cv2.COLOR_RGB2LAB)
        l_channel = lab[:, :, 0].astype(float)
        h = l_channel.shape[0]

        upper_mean = np.mean(l_channel[:h // 2, :])
        lower_mean = np.mean(l_channel[h // 2:, :])

        diff = upper_mean - lower_mean  # positivo = zona inferior más oscura
        score = np.clip(diff / 30 * 100, 0, 100)
        return float(score)

    def _bag_score(self, region: np.ndarray) -> float:
        """
        Bolsas: detecta gradiente de sombra/luz en la zona inferior del ojo.
        Una bolsa crea una sombra horizontal característica.
        """
        if region is None or region.size == 0 or region.shape[0] < 20:
            return 0.0

        gray = cv2.cvtColor(region, cv2.COLOR_RGB2GRAY) if region.ndim == 3 else region
        h = gray.shape[0]
        lower = gray[h // 2:, :]

        # Gradiente vertical en la zona inferior
        sobelx = cv2.Sobel(lower.astype(float), cv2.CV_64F, 0, 1, ksize=3)
        gradient_mean = np.mean(np.abs(sobelx))

        score = np.clip(gradient_mean / 8 * 100, 0, 100)
        return float(score)
