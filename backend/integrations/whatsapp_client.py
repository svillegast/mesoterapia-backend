import os
import base64
import httpx
from typing import Optional


WHATSAPP_API_URL = "https://graph.facebook.com/v19.0"


class WhatsAppClient:
    """
    Envía mensajes y media por WhatsApp Business Cloud API (Meta).
    """

    def __init__(self):
        self._token = os.getenv("WHATSAPP_ACCESS_TOKEN", "")
        self._phone_id = os.getenv("WHATSAPP_PHONE_NUMBER_ID", "")

    async def send_analysis(self, phone: str, image_b64: str, text: str) -> bool:
        """
        Envía imagen del reporte + texto al cliente.
        Retorna True si ambos mensajes se enviaron correctamente.
        """
        media_id = await self._upload_image(image_b64)
        if not media_id:
            return False

        img_ok = await self._send_image(phone, media_id)
        txt_ok = await self._send_text(phone, text)
        return img_ok and txt_ok

    async def _upload_image(self, image_b64: str) -> Optional[str]:
        """Sube imagen a Meta y retorna el media_id."""
        img_bytes = base64.b64decode(image_b64)
        url = f"{WHATSAPP_API_URL}/{self._phone_id}/media"
        headers = {"Authorization": f"Bearer {self._token}"}

        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(
                url,
                headers=headers,
                files={"file": ("report.jpg", img_bytes, "image/jpeg")},
                data={"messaging_product": "whatsapp"},
            )

        if resp.status_code == 200:
            return resp.json().get("id")
        return None

    async def _send_image(self, phone: str, media_id: str) -> bool:
        """Envía imagen ya subida usando su media_id."""
        url = f"{WHATSAPP_API_URL}/{self._phone_id}/messages"
        headers = {
            "Authorization": f"Bearer {self._token}",
            "Content-Type": "application/json",
        }
        payload = {
            "messaging_product": "whatsapp",
            "to": phone,
            "type": "image",
            "image": {
                "id": media_id,
                "caption": "📊 Tu Análisis Facial Personalizado — Emprender Mesoterapia Sin Agujas",
            },
        }
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.post(url, headers=headers, json=payload)
        return resp.status_code == 200

    async def _send_text(self, phone: str, text: str) -> bool:
        """Envía mensaje de texto."""
        url = f"{WHATSAPP_API_URL}/{self._phone_id}/messages"
        headers = {
            "Authorization": f"Bearer {self._token}",
            "Content-Type": "application/json",
        }
        payload = {
            "messaging_product": "whatsapp",
            "to": phone,
            "type": "text",
            "text": {"body": text, "preview_url": False},
        }
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.post(url, headers=headers, json=payload)
        return resp.status_code == 200
