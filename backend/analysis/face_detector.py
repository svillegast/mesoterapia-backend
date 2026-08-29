import os
import mediapipe as mp
from mediapipe.tasks.python import BaseOptions
from mediapipe.tasks.python.vision import FaceLandmarker, FaceLandmarkerOptions, RunningMode
import numpy as np
import cv2
from typing import Optional, Tuple

_MODEL_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "models", "face_landmarker.task")


class FaceDetector:
    """
    Detecta el rostro y extrae los 468 landmarks 3D con MediaPipe Face Landmarker
    (Tasks API). La API antigua (mp.solutions.face_mesh) fue retirada de
    mediapipe a partir de la version 0.10.30 en adelante — la version fijada
    en requirements.txt (0.10.14) ya no esta disponible para instalar en
    PyPI, asi que cualquier reinstalacion de dependencias con esa version
    fallaria. Esta migracion usa la API soportada actualmente.
    """

    def __init__(self):
        options = FaceLandmarkerOptions(
            base_options=BaseOptions(model_asset_path=_MODEL_PATH),
            running_mode=RunningMode.IMAGE,
            num_faces=1,
            min_face_detection_confidence=0.5,
        )
        self._landmarker = FaceLandmarker.create_from_options(options)

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
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
        result = self._landmarker.detect(mp_image)

        if not result.face_landmarks:
            return None, None

        landmarks = result.face_landmarks[0]
        return landmarks, rgb

    def landmark_px(self, lm, image: np.ndarray) -> Tuple[int, int]:
        """Convierte landmark normalizado a píxeles."""
        h, w = image.shape[:2]
        return int(lm.x * w), int(lm.y * h)

    def landmarks_to_px(self, landmarks, image: np.ndarray) -> np.ndarray:
        """Retorna array (468, 2) de coordenadas en píxeles."""
        h, w = image.shape[:2]
        return np.array([[int(lm.x * w), int(lm.y * h)] for lm in landmarks])
