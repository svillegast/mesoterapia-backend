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
        # Recalibrado 2026-08-29: la escala original (0.01=piel lisa,
        # 0.08=arrugas profundas) no se parece nada a los valores reales —
        # en 2 casos confirmados con arrugas/patas de gallo visibles, el
        # crudo salio 0.0021-0.0024, muy por debajo del piso asumido de
        # 0.005. Esta funcion se usa en frente, entrecejo, patas de gallo y
        # periorales — el ajuste mejora las 4 a la vez.
        score = np.clip(raw / 0.005 * 100, 0, 100)
        return float(score)

    def _canny_line_density(self, region: np.ndarray) -> float:
        """
        Densidad de bordes finos (líneas de arrugas) via Canny.

        Antes usaba umbrales fijos (30/80), muy sensibles al contraste/
        exposición de la foto: luz dura genera más "bordes" falsos y una foto
        borrosa u oscura oculta arrugas reales. Ahora los umbrales se calculan
        a partir de la mediana de intensidad de la propia región (Canny
        automático), para que el detector se adapte a la exposición de cada
        foto en vez de asumir siempre el mismo nivel de contraste.
        """
        if region is None or region.size == 0:
            return 0.0
        gray = cv2.cvtColor(region, cv2.COLOR_RGB2GRAY) if region.ndim == 3 else region
        if gray.shape[0] < 10 or gray.shape[1] < 10:
            return 0.0
        density = self._canny_raw_density(region)
        # Recalibrado 2026-08-28: mayor peso relativo de Canny en el score
        # combinado (ver analyze_forehead) — se sube la sensibilidad para
        # que un caso real de arrugas visibles no quede subestimado.
        score = np.clip(density / 0.10 * 100, 0, 100)
        return float(score)

    def _canny_raw_density(self, region: np.ndarray) -> float:
        """Densidad de bordes Canny sin escalar (0.0-1.0 aprox), para que
        cada condición aplique su propio divisor calibrado por separado."""
        if region is None or region.size == 0:
            return 0.0
        gray = cv2.cvtColor(region, cv2.COLOR_RGB2GRAY) if region.ndim == 3 else region
        if gray.shape[0] < 10 or gray.shape[1] < 10:
            return 0.0
        median = float(np.median(gray))
        low = int(max(0, 0.66 * median))
        high = int(min(255, 1.33 * median))
        edges = cv2.Canny(gray, low, high)
        return float(np.sum(edges > 0) / edges.size)

    def analyze_forehead(self, zone: np.ndarray) -> Dict:
        """Arrugas horizontales en la frente."""
        # AVISO 2026-08-29: NI Gabor NI Canny distinguen bien esta zona —
        # comparando un caso real de 59 años con arrugas confirmadas contra
        # uno de 19 años sin arrugas, AMBAS señales salieron invertidas
        # (más "arruga" detectada en la piel joven). No se puede calibrar
        # esto con un divisor, el método completo necesita rediseño
        # (probablemente un filtro direccional específico para líneas
        # horizontales, no densidad de bordes genérica). Mientras tanto se
        # amortigua fuertemente el resultado para no generar falsos
        # positivos en piel joven, aceptando que también subestima casos
        # reales hasta que se resuelva bien.
        gabor_s = self._gabor_wrinkle_score(zone)
        canny_s = self._canny_line_density(zone)
        score = (gabor_s * 0.3 + canny_s * 0.7) * 0.35
        return {"score": round(score, 1), "condition": "arrugas_frontales"}

    def analyze_glabella(self, zone: np.ndarray, landmarks) -> Dict:
        """Líneas del entrecejo usando landmarks de profundidad Z."""
        # AVISO 2026-08-29: igual que arrugas_frontales — ni Gabor ni la
        # profundidad Z distinguieron bien entre el caso de 59 años (arrugas
        # confirmadas) y el de 19 años (sin arrugas); la Z incluso salió
        # invertida (mayor "profundidad" en la piel joven). Amortiguado
        # fuertemente hasta rediseñar con más casos reales.
        gabor_s = self._gabor_wrinkle_score(zone)

        # Usar coordenada Z de landmarks del entrecejo (9, 107, 66)
        z_vals = [landmarks[i].z for i in [9, 107, 66, 105, 63, 70]]
        z_range = max(z_vals) - min(z_vals)
        depth_score = np.clip(abs(z_range) / 0.05 * 100, 0, 100)

        score = (gabor_s * 0.2 + float(depth_score) * 0.8) * 0.35
        return {"score": round(score, 1), "condition": "lineas_entrecejo"}

    def analyze_crow_feet(self, zone_l: np.ndarray, zone_r: np.ndarray) -> Dict:
        """Patas de gallo en zona lateral de los ojos."""
        # CORREGIDO 2026-08-29: Gabor daba resultado invertido (mayor en
        # piel joven sin arrugas que en caso real con patas de gallo
        # confirmadas) — no es de fiar aqui. Canny SI dio la direccion
        # correcta en ambos casos de referencia, se usa en su lugar.
        d_l = self._canny_raw_density(zone_l)
        d_r = self._canny_raw_density(zone_r)
        score = np.clip((d_l + d_r) / 2 / 0.30 * 100, 0, 100)
        return {"score": round(float(score), 1), "condition": "patas_gallo"}

    def analyze_perioral(self, zone: np.ndarray) -> Dict:
        """Arrugas periorales (código de barras alrededor de labios)."""
        # CORREGIDO 2026-08-29: mismo cambio que patas de gallo — Gabor no
        # es confiable, se usa Canny en su lugar.
        density = self._canny_raw_density(zone)
        score = np.clip(density / 0.18 * 100, 0, 100)
        return {"score": round(float(score), 1), "condition": "arrugas_periorales"}

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
        # Recalibrado 2026-08-28: divisor original (25) daba score demasiado
        # bajo (35) para un caso real que el usuario confirmó que debía ser
        # "un poco más" — ajustado a 17.
        score = np.clip(roughness / 17 * 100, 0, 100)
        return {"score": round(float(score), 1), "condition": "textura_irregular"}
