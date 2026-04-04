from typing import Dict
from protocols.protocol_data import SALON_INFO


class TextReportGenerator:
    """
    Genera el texto del mensaje WhatsApp personalizado para el cliente.
    """

    def generate(self, scores: Dict, treatment_plan: Dict) -> str:
        global_score = scores.get("global", 0)
        global_sev = scores.get("global_severity", "Leve")
        zone_scores = scores.get("zones", {})
        protocols = treatment_plan.get("protocols", [])
        combo = treatment_plan.get("combo_suggestion", {})

        # Zona con mayor score
        top_zones = sorted(
            [(k, v.get("score", 0)) for k, v in zone_scores.items()],
            key=lambda x: -x[1]
        )

        zone_name_map = {
            "frente":      "frente",
            "ojos":        "contorno de ojos",
            "mejillas":    "mejillas",
            "boca_surcos": "surcos y zona de la boca",
            "mandibula":   "mandíbula",
            "luminosidad": "luminosidad de la piel",
        }

        top1 = zone_name_map.get(top_zones[0][0], "rostro") if top_zones else "rostro"
        top2 = zone_name_map.get(top_zones[1][0], "") if len(top_zones) > 1 else ""

        lines = [
            f"Hola 👋 Aquí tienes tu *Análisis Facial Personalizado*.",
            "",
            f"*RESULTADO GLOBAL: {global_score:.0f}/100 — {global_sev}*",
            "",
        ]

        # Zona principal detectada
        if top_zones and top_zones[0][1] >= 30:
            s1 = top_zones[0][1]
            lines.append(f"Tu análisis muestra mayor atención en *{top1}* ({s1:.0f}/100)")
            if top2 and len(top_zones) > 1 and top_zones[1][1] >= 30:
                s2 = top_zones[1][1]
                lines.append(f"y en *{top2}* ({s2:.0f}/100).")
            lines.append("")

        # Explicaciones de las condiciones prioritarias
        if protocols:
            lines.append("*¿POR QUÉ ESTAS ZONAS?*")
            top_proto = protocols[0]
            for expl in top_proto.get("explanations", [])[:2]:
                lines.append(f"→ {expl}")
            lines.append("")

        # Plan sugerido
        if protocols:
            lines.append("*PLAN DE TRATAMIENTO SUGERIDO:*")
            for proto in protocols[:3]:
                prio = "⭐ " if proto.get("priority") == "PRIORITARIO" else "✅ "
                lines.append(
                    f"{prio}*{proto['nombre']}*\n"
                    f"   {proto['sesiones']} sesiones · ${proto['precio']}/sesión · Pack 6: *${proto['pack6']}*"
                )
            lines.append("")

        # Pack combinado
        if combo:
            lines.append(
                f"💡 *Pack combinado:* {combo.get('nombre', '')}\n"
                f"   ${combo.get('precio_combo')} (ahorro *${combo.get('ahorro')}* vs sesiones sueltas)"
            )
            lines.append("")

        lines += [
            "*Sin agujas · Sin dolor · Sin tiempo de recuperación*",
            "Resultados visibles desde la sesión 3.",
            "",
            "¿Te gustaría agendar tu primera sesión? Responde este mensaje 😊",
            "",
            f"📍 {SALON_INFO['direccion']}",
            f"   ({SALON_INFO['referencia']})",
            f"   {SALON_INFO['ciudad']}",
        ]

        return "\n".join(lines)
