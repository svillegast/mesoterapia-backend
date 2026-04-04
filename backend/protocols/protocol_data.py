# Protocolos reales de mesoterapia sin agujas - Emprender Milagro

PROTOCOLS = {
    "P1": {
        "id": "P1",
        "nombre": "Facial Anti-Edad & Revitalizante",
        "cabezal": "C-FAC",
        "preparacion": "Aloe Activator (equilibrar pH + conductividad)",
        "coctel": ["Hidrafiller (base hialurónica)", "Vitamina C Skin (luminosidad)"],
        "config": {"RF": 4, "Speed": 5, "Dose": 3, "EMS": "02 Shallow"},
        "finalizacion": "Aloe Vera Gelly",
        "duracion_min": 45,
        "sesiones": "6-10",
        "precio": 35,
        "pack6": 175,
        "pack10": None,
        "indicaciones": [
            "arrugas_frontales", "lineas_entrecejo", "arrugas_periorales",
            "poros_dilatados", "textura_irregular", "piel_opaca", "tono_desigual",
            "perdida_volumen",
        ],
    },
    "P2": {
        "id": "P2",
        "nombre": "Lifting & Tensado Facial",
        "cabezal": "C-FAC",
        "preparacion": "Aloe First (sensibiliza y prepara la dermis)",
        "coctel": [
            "Firm Skin (estructura)",
            "DMAE (efecto tensor)",
            "Booster Peptides (relajación de líneas)",
        ],
        "config": {"RF": 6, "Speed": 4, "Dose": 4, "EMS": "04 Deep"},
        "finalizacion": "Aloe Vera Gelly (capa fina)",
        "duracion_min": 55,
        "sesiones": "8-12",
        "precio": 40,
        "pack6": 200,
        "pack10": None,
        "indicaciones": [
            "mejillas_caidas", "surcos_nasogenianos", "lineas_marioneta",
            "mandibula_indefinida", "doble_menton", "perdida_volumen",
        ],
    },
    "P3": {
        "id": "P3",
        "nombre": "Despigmentación / Manchas",
        "cabezal": "C-FAC",
        "preparacion": "Aloe Activator",
        "coctel": [
            "Clar Biopeptido (despigmentante)",
            "Vitamina C Skin (iluminación)",
        ],
        "config": {"RF": 3, "Speed": 3, "Dose": 3, "EMS": "00 OFF"},
        "finalizacion": "Aloe Vera Gelly + Protección Solar SPF 50+",
        "duracion_min": 45,
        "sesiones": "8-12",
        "precio": 35,
        "pack6": 175,
        "pack10": 280,
        "indicaciones": ["manchas", "piel_opaca", "tono_desigual"],
        "nota": "SPF 50+ obligatorio entre sesiones",
    },
    "P4": {
        "id": "P4",
        "nombre": "Cuello, Escote y Manos",
        "cabezal": "C-FAC",
        "preparacion": "Aloe First",
        "coctel": [
            "Silicio Orgánico / Silanol (reestructuración profunda)",
            "Firm Skin (reafirmación)",
            "DMAE (tensor)",
        ],
        "config": {"RF": 5, "Speed": 5, "Dose": 3, "EMS": "03 Shallow"},
        "finalizacion": "Masaje con Aloe Vera Gelly",
        "duracion_min": 45,
        "sesiones": "6-10",
        "precio": 45,
        "pack6": 225,
        "pack10": 360,
        "indicaciones": ["doble_menton"],
        "zonas_extra": ["cuello", "escote", "manos"],
    },
    "P5": {
        "id": "P5",
        "nombre": "Ojeras y Contorno de Ojos",
        "cabezal": "C-DEL",
        "preparacion": "Aloe Vera Gelly (zona periocular muy sensible)",
        "coctel": [
            "Hidrafiller (estructura al hueso orbital)",
            "Booster Peptides (péptidos tensores + reafirmación)",
            "DMAE (tono muscular párpado superior)",
        ],
        "config": {"RF": "02-03", "Speed": None, "Dose": 1, "EMS": "03 Shallow"},
        "tecnica": (
            "VECTOR DE ELEVACIÓN: "
            "Inicio en cola interna de ceja → deslizar siguiendo arco superciliar → "
            "terminar en sien. Al llegar a cola de ceja: mantener presión ARRIBA "
            "5 segundos con EMS activo. Repetir 8-10 veces por ojo. "
            "⚠️ NUNCA sobre párpado móvil."
        ),
        "finalizacion": "Aloe Vera Gelly",
        "duracion_min": 35,
        "sesiones": "8-12",
        "precio": 25,
        "pack6": 130,
        "pack10": None,
        "indicaciones": [
            "patas_gallo", "ojeras", "bolsas_ojos", "parpados_caidos",
        ],
    },
}

# Precios adicionales
EXTRA_SERVICES = {
    "facial_express": {"nombre": "Facial Express (30 min)", "precio": 25, "pack6": 130},
    "anti_caida":     {"nombre": "Anti-Caída / Alopecia", "precio": 40, "pack6": 200, "pack10": 320},
    "hidratacion_capilar": {"nombre": "Hidratación Capilar Profunda", "precio": 25, "pack6": 130},
}

SALON_INFO = {
    "nombre": "Emprender - Mesoterapia Sin Agujas",
    "direccion": "Isidoro Acurio Fiallos y Bolívar Leal Chichande",
    "referencia": "Entrando por Mercado La Colón",
    "ciudad": "Milagro, Guayas, Ecuador",
}
