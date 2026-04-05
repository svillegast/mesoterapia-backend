from typing import Dict, List
from protocols.protocol_data import PROTOCOLS

# Mínimo score para recomendar un protocolo
RECOMMEND_THRESHOLD = 30

# Explicaciones personalizadas por condición (mencionan productos reales)
CONDITION_EXPLANATIONS = {
    "arrugas_frontales": (
        "Se detectaron líneas horizontales en tu frente. Nuestro *Hidrafiller* (ácido hialurónico) "
        "+ *Vitamina C Skin* penetra sin agujas para rellenar y suavizar estas líneas, "
        "estimulando colágeno nuevo. Resultados visibles desde la 2da sesión."
    ),
    "lineas_entrecejo": (
        "Las líneas del entrecejo se forman por tensión muscular repetida. "
        "Nuestro *Hidrafiller* + *Vitamina C Skin* con radiofrecuencia suave (RF 04) "
        "suaviza estas marcas de expresión desde dentro."
    ),
    "patas_gallo": (
        "La zona del contorno de ojos es la más delicada del rostro. "
        "Las líneas laterales detectadas se tratan con nuestro cabezal de precisión C-DEL "
        "y *Booster Peptides* + *DMAE* que reafirman sin agredir."
    ),
    "ojeras": (
        "Tu análisis revela oscurecimiento bajo los ojos, señal de microcirculación lenta. "
        "Nuestro protocolo 'Mirada Despierta' con *DMAE* reactiva la circulación "
        "y aclara la zona gradualmente."
    ),
    "bolsas_ojos": (
        "Se detectan bolsas infraorbitales. Nuestro *Booster Peptides* + *Hidrafiller* "
        "con cabezal C-DEL y EMS Shallow drena y descongestionan esta zona sensible."
    ),
    "parpados_caidos": (
        "Tu análisis muestra descenso del párpado superior. Nuestro 'Vector de Elevación' "
        "con *DMAE* + EMS 03 'despierta' el músculo elevador, abriendo la mirada "
        "de forma natural y sin cirugía."
    ),
    "mejillas_caidas": (
        "Se detectó pérdida de firmeza en las mejillas. Nuestro *Firm Skin* + *DMAE* + "
        "*Booster Peptides* a RF 06 + EMS Deep trabajan músculo y piel "
        "para redefinir el óvalo facial."
    ),
    "perdida_volumen": (
        "Tu rostro muestra pérdida de volumen en las mejillas. La combinación de "
        "*Hidrafiller* (relleno hialurónico) + *Firm Skin* (estructura) "
        "restaura la plenitud natural sin inyecciones."
    ),
    "poros_dilatados": (
        "Se detectan poros visibles en zona nariz-mejillas. Nuestra *Vitamina C Skin* "
        "+ *Hidrafiller* refina la textura y minimiza el tamaño del poro progresivamente."
    ),
    "manchas": (
        "Tu análisis identifica zonas de pigmentación irregular. Nuestro "
        "*Clar Biopeptido* (despigmentante profesional) + *Vitamina C Skin* inhibe "
        "la melanina excesiva y unifica el tono. Incluye protección solar SPF 50+."
    ),
    "surcos_nasogenianos": (
        "Los surcos nariz-boca son de los más visibles. Nuestro *Firm Skin* + *DMAE* + "
        "*Booster Peptides* a RF 06 rellena y tensa esta zona de forma progresiva "
        "desde la primera sesión."
    ),
    "lineas_marioneta": (
        "Se detectan líneas descendentes desde la comisura labial que dan aspecto de cansancio. "
        "Nuestro *DMAE* (tensor inmediato) + *Booster Peptides* con EMS Deep "
        "eleva las comisuras y rejuvenece la expresión."
    ),
    "arrugas_periorales": (
        "Las líneas finas alrededor de los labios responden muy bien a nuestro *Hidrafiller* "
        "que hidrata y rellena desde dentro, combinado con *Vitamina C Skin* "
        "para renovar la superficie."
    ),
    "mandibula_indefinida": (
        "Tu análisis muestra pérdida de definición mandibular. El *Firm Skin* + *DMAE* "
        "a RF 06 + EMS Deep redefine el contorno y estimula colágeno nuevo."
    ),
    "doble_menton": (
        "Se detecta acumulación submentoniana. Combinamos *Firm Skin* + *DMAE* (lifting) "
        "con *Silicio Orgánico* + *Firm Skin* (protocolo cervical) para trabajar "
        "flacidez y contorno en la misma zona."
    ),
    "piel_opaca": (
        "Tu piel muestra falta de luminosidad. Nuestro *Clar Biopeptido* + *Vitamina C Skin* "
        "devuelven el brillo y la vitalidad desde la primera sesión, "
        "con RF suave (03) que no agrede la piel."
    ),
    "tono_desigual": (
        "Se detecta irregularidad en el tono. El *Clar Biopeptido* unifica gradualmente "
        "mientras la *Vitamina C Skin* ilumina, revelando una piel más homogénea y radiante."
    ),
    "textura_irregular": (
        "La textura de tu piel muestra irregularidades. Nuestro *Hidrafiller* + *Vitamina C Skin* "
        "con RF 04 renueva la superficie cutánea dejando la piel más suave y uniforme."
    ),
}

# Combinaciones permitidas en misma sesión
ALLOWED_COMBOS = [
    {"P1", "P5"},
    {"P2", "P4"},
    {"P1", "P3"},
    {"P3", "P4"},
]


class ProtocolMapper:
    """
    Mapea condiciones detectadas a protocolos de tratamiento priorizados.
    """

    def map(self, results: Dict, scores: Dict, min_score: int = RECOMMEND_THRESHOLD) -> Dict:
        conditions = scores.get("conditions", {})
        triggered: Dict[str, float] = {}  # protocol_id → max score trigger

        for condition, data in conditions.items():
            score = data.get("score", 0)
            if score < min_score:
                continue
            for pid, proto in PROTOCOLS.items():
                if condition in proto.get("indicaciones", []):
                    triggered[pid] = max(triggered.get(pid, 0), score)

        # Ordenar por score descendente
        ordered: List[Dict] = []
        for pid, trigger_score in sorted(triggered.items(), key=lambda x: -x[1]):
            proto = PROTOCOLS[pid]
            # Recopilar condiciones activas para este protocolo
            active_conditions = [
                c for c in proto.get("indicaciones", [])
                if conditions.get(c, {}).get("score", 0) >= min_score
            ]
            explanations = [
                CONDITION_EXPLANATIONS[c]
                for c in active_conditions
                if c in CONDITION_EXPLANATIONS
            ]
            ordered.append({
                "protocol_id": pid,
                "nombre": proto["nombre"],
                "trigger_score": round(trigger_score, 1),
                "priority": _priority_label(trigger_score),
                "precio": proto["precio"],
                "pack6": proto["pack6"],
                "pack10": proto.get("pack10"),
                "sesiones": proto["sesiones"],
                "duracion_min": proto["duracion_min"],
                "active_conditions": active_conditions,
                "explanations": explanations,
            })

        # Sugerir pack combinado si aplica
        combo = self._suggest_combo(triggered)

        return {
            "protocols": ordered,
            "combo_suggestion": combo,
            "total_conditions_detected": sum(
                1 for d in conditions.values() if d.get("score", 0) >= RECOMMEND_THRESHOLD
            ),
        }

    def _suggest_combo(self, triggered: Dict) -> Dict:
        """Sugiere el mejor pack combinado si hay 2+ protocolos."""
        if len(triggered) < 2:
            return {}

        triggered_set = set(triggered.keys())
        for combo in ALLOWED_COMBOS:
            if combo.issubset(triggered_set):
                ids = list(combo)
                total_suelto = sum(PROTOCOLS[p]["pack6"] for p in ids)
                descuento = round(total_suelto * 0.08)
                total_combo = total_suelto - descuento
                names = " + ".join(PROTOCOLS[p]["nombre"] for p in ids)
                return {
                    "protocols": ids,
                    "nombre": names,
                    "precio_suelto": total_suelto,
                    "descuento": descuento,
                    "precio_combo": total_combo,
                    "ahorro": descuento,
                }
        return {}


def _priority_label(score: float) -> str:
    if score >= 70:
        return "PRIORITARIO"
    if score >= 50:
        return "Necesario"
    return "Recomendado"
