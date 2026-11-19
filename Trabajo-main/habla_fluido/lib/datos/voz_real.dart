import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../dominio/excepciones.dart';
import '../dominio/voz.dart';

/// Voz real: texto→voz con flutter_tts y voz→texto con speech_to_text.
/// El reconocimiento lo hace el servicio de voz del sistema (Google/Apple):
/// el audio puede salir del teléfono. Avisa al estudiante en tu aviso de privacidad.
class VozReal implements Voz {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  bool _sttListo = false;

  @override
  Future<void> hablar(String texto, {double velocidad = 1.0}) async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate((0.5 * velocidad).clamp(0.1, 1.0)); // 0.5 ≈ velocidad normal
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(texto);
  }

  @override
  Future<String?> escuchar({Duration limite = const Duration(seconds: 8)}) async {
    if (!_sttListo) _sttListo = await _stt.initialize();
    if (!_sttListo) throw const MicrofonoNoDisponibleException();

    final resultado = Completer<String?>();
    await _stt.listen(
      onResult: (r) {
        if (r.finalResult && !resultado.isCompleted) resultado.complete(r.recognizedWords);
      },
      localeId: 'en_US',
      listenFor: limite,
      pauseFor: const Duration(seconds: 3),
    );
    return resultado.future.timeout(limite + const Duration(seconds: 3), onTimeout: () {
      _stt.stop();
      return null;
    });
  }

  @override
  Future<void> detener() async {
    await _tts.stop();
    await _stt.stop();
  }
}