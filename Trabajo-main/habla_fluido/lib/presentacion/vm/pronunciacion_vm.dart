import 'package:flutter/foundation.dart';

import '../../dominio/comparador.dart';
import '../../dominio/excepciones.dart';
import '../../dominio/frase.dart';
import '../../dominio/nivel.dart';
import '../../dominio/voz.dart';
import 'aprendizaje_vm.dart';

/// Pronunciación por SHADOWING: escuchas el modelo, lo repites de inmediato y la app
/// compara lo que reconoció con la frase. Mide INTELIGIBILIDAD (¿te entienden?),
/// no acento nativo: ese es un objetivo realista y suficiente para comunicarse.
class PronunciacionViewModel extends ChangeNotifier {
  final Voz _voz;
  final AprendizajeViewModel _aprendizaje;

  PronunciacionViewModel(this._voz, this._aprendizaje);

  int indice = 0;
  ResultadoComparacion? resultado;
  String? escuchado;
  bool ocupado = false;
  String? error;

  List<Frase> get frases => frasesDeNivel(_aprendizaje.nivel);
  Frase get actual => frases[indice % frases.length];

  Future<void> escucharModelo({bool lento = false}) async {
    if (ocupado) return;
    ocupado = true;
    error = null;
    notifyListeners();
    try {
      await _voz.hablar(actual.ingles, velocidad: lento ? 0.6 : 1.0);
    } catch (e) {
      error = mensajeSeguro(e);
    }
    ocupado = false;
    notifyListeners();
  }

  Future<void> grabar() async {
    if (ocupado) return;
    ocupado = true;
    error = null;
    notifyListeners();
    try {
      final dicho = await _voz.escuchar();
      if (dicho == null || dicho.trim().isEmpty) {
        error = 'No te escuché. Acércate al micrófono e inténtalo de nuevo.';
      } else {
        escuchado = dicho;
        resultado = comparar(actual.ingles, dicho);

        await _aprendizaje.registrarIntento(Habilidad.pronunciacion, resultado!.puntaje, frase: actual);
      }
    } catch (e) {
      error = mensajeSeguro(e);
    }
    ocupado = false;
    notifyListeners();
  }

  void siguiente() {
    indice++;
    resultado = null;
    escuchado = null;
    error = null;
    notifyListeners();
  }
}