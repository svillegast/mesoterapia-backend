import numpy as np
from typing import Dict


class VolumeAnalyzer:
    """
    Evalúa pérdida de volumen en mejillas usando curvatura 3D del Face Mesh.
    """

    # Landmarks de las mejillas en MediaPipe
    CHEEK_L = [116, 117, 118, 119, 120, 121, 128, 245]
    CHEEK_R = [345, 346, 347, 348, 349, 350, 357, 465]
    NOSE_TIP = 4

    def analyze(self, landmarks) -> Dict:
        """
        Compara la profundidad Z de las mejillas relativa a la nariz.
        Mejillas con volumen: Z similar a la nariz.
        Mejillas hundidas: Z más negativo (más profundo).
        """
        nose_z = landmarks[self.NOSE_TIP].z

        z_l = np.mean([landmarks[i].z for i in self.CHEEK_L])
        z_r = np.mean([landmarks[i].z for i in self.CHEEK_R])
        avg_cheek_z = (z_l + z_r) / 2

        # Diferencia: pómulo hundido → mayor diferencia con la nariz
        z_diff = nose_z - avg_cheek_z  # positivo = mejilla más hundida

        score = np.clip(z_diff / 0.06 * 100, 0, 100)
        return {"score": round(float(score), 1), "condition": "perdida_volumen"}
