import 'package:flutter/material.dart';

/// Configuración del negocio para esta compilación de la app.
/// Para armar la app de un cliente nuevo: copiar este archivo, cambiar estos
/// valores, y compilar — no se toca el resto del código.
class NegocioConfig {
  static const String nombreNegocio = 'Plastifería (piloto)';
  static const Color colorPrimario = Color(0xFF0F6B5C);
  static const Color colorAcento = Color(0xFFB5762A);

  /// Etiqueta de la unidad base al vender (ej. "unidad", "funda", "paquete").
  static const String etiquetaUnidad = 'unidad';

  /// A partir de esta cantidad se aplica el precio de mayorista.
  static const int cantidadMinimaMayoristaPorDefecto = 12;

  /// true = el negocio solo vende al consumidor final (un solo precio por
  /// producto, sin precio de mayorista). Poner en false para negocios que
  /// sí venden por volumen (ferretería, plastifería al por mayor, etc.).
  static const bool ventaSoloConsumidorFinal = false;
}
