/// Contrato de voz. La app solo conoce esto; el motor real (flutter_tts + speech_to_text)
/// y el simulado de las pruebas son intercambiables.
abstract class Voz {
  /// Pronuncia [texto] en inglés. [velocidad] 1.0 = normal, 0.6 = lenta.
  Future<void> hablar(String texto, {double velocidad = 1.0});

  /// Escucha al estudiante y devuelve lo que entendió (o null si no oyó nada).
  Future<String?> escuchar({Duration limite = const Duration(seconds: 8)});

  Future<void> detener();
}