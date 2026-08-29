import numpy as np
import cv2
from typing import Dict


class SpotAnalyzer:
    """
    Detecta manchas e hiperpigmentación usando segmentación de color HSV.
    """

    def analyze(self, zone_l: np.ndarray, zone_r: np.ndarray, zone_forehead: np.ndarray) -> Dict:
        score_l = self._detect_spots(zone_l)
        score_r = self._detect_spots(zone_r)
        score_f = self._detect_spots(zone_forehead)
        score = max(score_l, score_r, score_f)
        return {"score": round(float(score), 1), "condition": "manchas"}

    def _detect_spots(self, region: np.ndarray) -> float:
        if region is None or region.size == 0 or region.shape[0] < 10 or region.shape[1] < 10:
            return 0.0

        # Convertir a LAB para mejor separación de luminancia
        lab = cv2.cvtColor(region, cv2.COLOR_RGB2LAB)
        l_channel = lab[:, :, 0].astype(float)

        # Manchas = píxeles con luminancia significativamente más baja que la media.
        # Antes usaba 1.5 desviaciones estándar: con una distribución normal eso
        # marca ~6-7% de CUALQUIER imagen como "mancha" sin importar si hay
        # manchas reales, y sombras por luz direccional (una sola fuente de luz)
        # se contaban igual que una mancha real. Se sube el umbral estadístico y
        # se exige además una caída absoluta mínima en luminancia, para que una
        # sombra suave por mala iluminación no cruce el umbral.
        mean_l = np.mean(l_channel)
        std_l = np.std(l_channel)
        # Recalibrado 2026-08-28 (segunda pasada): el umbral de 2.5 dejó de
        # detectar CUALQUIER mancha en un caso real con pecas moderadas
        # confirmadas por el usuario (0 píxeles detectados) — demasiado
        # estricto. Bajado a un punto intermedio entre el original (1.5,
        # detectaba de más) y el de esta mañana (2.5, no detectaba nada).
        threshold = mean_l - 2.1 * std_l
        min_absolute_drop = 13  # unidades LAB L — ajustar con más fotos de referencia

        dark_mask = l_channel < np.minimum(threshold, mean_l - min_absolute_drop)
        spot_ratio = np.sum(dark_mask) / dark_mask.size

        # Eliminar ruido: solo contar clusters suficientemente grandes
        mask_uint8 = (dark_mask * 255).astype(np.uint8)
        num_labels, _, stats, _ = cv2.connectedComponentsWithStats(mask_uint8, connectivity=8)

        min_area = max(20, dark_mask.size * 0.002)
        significant = sum(1 for i in range(1, num_labels) if stats[i, cv2.CC_STAT_AREA] >= min_area)

        score = np.clip(spot_ratio * 400 + significant * 5, 0, 100)
        return float(score)
