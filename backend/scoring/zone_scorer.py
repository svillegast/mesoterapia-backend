from typing import Dict

# Pesos por zona (suman 1.0)
ZONE_WEIGHTS = {
    "ojos":      0.22,
    "boca_surcos": 0.18,
    "mejillas":  0.18,
    "frente":    0.12,
    "mandibula": 0.12,
    "luminosidad": 0.10,
    "cuello":    0.08,
}

# Mapa condición → zona
CONDITION_ZONE = {
    "arrugas_frontales":    "frente",
    "lineas_entrecejo":     "frente",
    "patas_gallo":          "ojos",
    "ojeras":               "ojos",
    "bolsas_ojos":          "ojos",
    "parpados_caidos":      "ojos",
    "mejillas_caidas":      "mejillas",
    "perdida_volumen":      "mejillas",
    "poros_dilatados":      "mejillas",
    "manchas":              "mejillas",
    "surcos_nasogenianos":  "boca_surcos",
    "lineas_marioneta":     "boca_surcos",
    "arrugas_periorales":   "boca_surcos",
    "mandibula_indefinida": "mandibula",
    "doble_menton":         "mandibula",
    "piel_opaca":           "luminosidad",
    "tono_desigual":        "luminosidad",
    "textura_irregular":    "luminosidad",
}

SEVERITY_LABELS = {
    (0, 30):  "Óptima",
    (30, 50): "Leve",
    (50, 70): "Moderada",
    (70, 100): "Avanzada",
}

SEVERITY_COLORS = {
    "Óptima":   "#4CAF50",
    "Leve":     "#8BC34A",
    "Moderada": "#FF9800",
    "Avanzada": "#F44336",
}


def _label(score: float) -> str:
    for (lo, hi), label in SEVERITY_LABELS.items():
        if lo <= score < hi:
            return label
    return "Avanzada"


class ZoneScorer:
    """
    Calcula scores ponderados por zona y score global.
    """

    def calculate(self, results: Dict) -> Dict:
        zone_scores: Dict[str, list] = {z: [] for z in ZONE_WEIGHTS}

        for condition_key, data in results.items():
            zone = CONDITION_ZONE.get(condition_key)
            if zone and isinstance(data, dict):
                zone_scores[zone].append(data.get("score", 0))

        zones_out = {}
        for zone, scores in zone_scores.items():
            if scores:
                avg = sum(scores) / len(scores)
            else:
                avg = 0.0
            zones_out[zone] = {
                "score": round(avg, 1),
                "severity": _label(avg),
                "color": SEVERITY_COLORS[_label(avg)],
                "weight": ZONE_WEIGHTS[zone],
            }

        global_score = sum(
            zones_out[z]["score"] * ZONE_WEIGHTS[z] for z in ZONE_WEIGHTS
        )

        # Scores individuales enriquecidos
        conditions_out = {}
        for cond, data in results.items():
            if isinstance(data, dict):
                s = data.get("score", 0)
                conditions_out[cond] = {
                    "score": s,
                    "severity": _label(s),
                    "color": SEVERITY_COLORS[_label(s)],
                }

        return {
            "global": round(global_score, 1),
            "global_severity": _label(global_score),
            "zones": zones_out,
            "conditions": conditions_out,
        }
