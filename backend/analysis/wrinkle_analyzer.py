import numpy as np
import cv2
from skimage.filters import gabor
from skimage.color import rgb2gray
from typing import Dict


class WrinkleAnalyzer:
    """
    Detecta arrugas y textura irregular usando Gabor filters + Canny edge detection.
    Retorna score 0-100 (0=sin arrugas, 100=arrugas severas).
    """

    def _gabor_wrinkle_score(self, region: np.ndarray) -> float:
        """Score de arrugas via energía Gabor en múltiples orientaciones."""
        if region is None or region.size == 0:
            return 0.0
        gray = rgb2gray(region) if region.ndim == 3 else region
        if gray.shape[0] < 10 or gray.shape[1] < 10:
            return 0.0

        energies = []
        for theta in [0, np.pi / 4, np.pi / 2, 3 * np.pi / 4]:
            filt_real, _ = gabor(gray, frequency=0.3, theta=theta)
            energies.append(np.mean(np.abs(filt_real)))

        raw = np.max(energies)
        # Normalizar empíricamente: ~0.01 = piel lisa, ~0.08 = arrugas profundas
        score = np.clip((raw - 0.005) / 0.07 * 100, 0, 100)
        return float(score)

    def _canny_line_density(self, region: np.ndarray, low=30, high=80) -> float:
        """Densidad de bordes finos (líneas de arrugas) via Canny."""
        if region is None or region.size == 0:
            return 0.0
        gray = cv2.cvtColor(region, cv2.COLOR_RGB2GRAY) if region.ndim == 3 else region
        if gray.shape[0] < 10 or gray.shape[1] < 10:
            return 0.0
        edges = cv2.Canny(gray, low, high)
        density = np.sum(edges > 0) / edges.size
        score = np.clip(density / 0.15 * 100, 0, 100)
        return float(score)

    def analyze_forehead(self, zone: np.ndarray) -> Dict:
        """Arrugas horizontales en la frente."""
        gabor_s = self._gabor_wrinkle_score(zone)
        canny_s = self._canny_line_density(zone)
        score = gabor_s * 0.6 + canny_s * 0.4
        return {"score": round(score, 1), "condition": "arrugas_frontales"}

    def analyze_glabella(self, zone: np.ndarray, landmarks) -> Dict:
        """Líneas del entrecejo usando landmarks de profundidad Z."""
        gabor_s = self._gabor_wrinkle_score(zone)

        # Usar coordenada Z de landmarks del entrecejo (9, 107, 66)
        z_vals = [landmarks[i].z for i in [9, 107, 66, 105, 63, 70]]
        z_range = max(z_vals) - min(z_vals)
        depth_score = np.clip(abs(z_range) / 0.05 * 100, 0, 100)

        score = gabor_s * 0.5 + float(depth_score) * 0.5
        return {"score": round(score, 1), "condition": "lineas_entrecejo"}

    def analyze_crow_feet(self, zone_l: np.ndarray, zone_r: np.ndarray) -> Dict:
        """Patas de gallo en zona lateral de los ojos."""
        score_l = self._gabor_wrinkle_score(zone_l)
        score_r = self._gabor_wrinkle_score(zone_r)
        score = (score_l + score_r) / 2
        return {"score": round(score, 1), "condition": "patas_gallo"}

    def analyze_perioral(self, zone: np.ndarray) -> Dict:
        """Arrugas periorales (código de barras alrededor de labios)."""
        score = self._gabor_wrinkle_score(zone)
        return {"score": round(score, 1), "condition": "arrugas_periorales"}

    def analyze_texture(self, image: np.ndarray, landmarks) -> Dict:
        """Textura global irregular usando varianza local."""
        if image is None or image.size == 0:
            return {"score": 0.0, "condition": "textura_irregular"}
        gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
        # Varianza local en ventana 5x5
        mean = cv2.blur(gray.astype(float), (5, 5))
        sq_mean = cv2.blur((gray.astype(float) ** 2), (5, 5))
        variance = sq_mean - mean ** 2
        roughness = np.mean(np.sqrt(np.clip(variance, 0, None)))
        score = np.clip(roughness / 25 * 100, 0, 100)
        return {"score": round(float(score), 1), "condition": "textura_irregular"}
