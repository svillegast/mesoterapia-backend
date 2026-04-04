import numpy as np
import cv2
from typing import Dict


class PoreAnalyzer:
    """
    Detecta poros dilatados mediante análisis de textura de alta frecuencia.
    """

    def analyze(self, zone_l: np.ndarray, zone_r: np.ndarray) -> Dict:
        score_l = self._pore_score(zone_l)
        score_r = self._pore_score(zone_r)
        score = (score_l + score_r) / 2
        return {"score": round(float(score), 1), "condition": "poros_dilatados"}

    def _pore_score(self, region: np.ndarray) -> float:
        if region is None or region.size == 0 or region.shape[0] < 15 or region.shape[1] < 15:
            return 0.0

        gray = cv2.cvtColor(region, cv2.COLOR_RGB2GRAY) if region.ndim == 3 else region

        # Suavizar para eliminar ruido, luego restar para obtener detalles finos
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        detail = cv2.subtract(gray, blurred)

        # Los poros aparecen como puntos oscuros de tamaño pequeño
        _, thresh = cv2.threshold(detail, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)

        # Analizar componentes conectados pequeños (= poros)
        num_labels, _, stats, _ = cv2.connectedComponentsWithStats(thresh, connectivity=8)
        min_a, max_a = 3, 80
        pore_count = sum(
            1 for i in range(1, num_labels)
            if min_a <= stats[i, cv2.CC_STAT_AREA] <= max_a
        )

        # Densidad de poros por 10,000 px²
        density = pore_count / (region.shape[0] * region.shape[1]) * 10000
        score = np.clip(density / 8 * 100, 0, 100)
        return float(score)
