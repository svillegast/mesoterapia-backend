import mediapipe as mp
import numpy as np
import cv2
from typing import Optional, Tuple


class FaceDetector:
    """
    Detecta el rostro y extrae los 468 landmarks 3D con MediaPipe Face Mesh.
    """

    def __init__(self):
        self._face_mesh = mp.solutions.face_mesh.FaceMesh(
            static_image_mode=True,
            max_num_faces=1,
            refine_landmarks=True,
            min_detection_confidence=0.5,
        )

    def detect(self, image_bytes: bytes) -> Tuple[Optional[list], Optional[np.ndarray]]:
        """
        Recibe bytes de imagen y retorna (landmarks_list, image_rgb).
        landmarks_list: lista de 468 objetos con .x, .y, .z (normalizados 0-1).
        Retorna (None, None) si no se detecta rostro.
        """
        arr = np.frombuffer(image_bytes, np.uint8)
        bgr = cv2.imdecode(arr, cv2.IMREAD_COLOR)
        if bgr is None:
            return None, None

        # Redimensionar si la imagen es demasiado grande (optimización)
        h, w = bgr.shape[:2]
        if max(h, w) > 1920:
            scale = 1920 / max(h, w)
            bgr = cv2.resize(bgr, (int(w * scale), int(h * scale)))

        rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
        result = self._face_mesh.process(rgb)

        if not result.multi_face_landmarks:
            return None, None

        landmarks = result.multi_face_landmarks[0].landmark
        return landmarks, rgb

    def landmark_px(self, lm, image: np.ndarray) -> Tuple[int, int]:
        """Convierte landmark normalizado a píxeles."""
        h, w = image.shape[:2]
        return int(lm.x * w), int(lm.y * h)

    def landmarks_to_px(self, landmarks, image: np.ndarray) -> np.ndarray:
        """Retorna array (468, 2) de coordenadas en píxeles."""
        h, w = image.shape[:2]
        return np.array([[int(lm.x * w), int(lm.y * h)] for lm in landmarks])
