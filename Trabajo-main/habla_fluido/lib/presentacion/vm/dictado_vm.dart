import 'package:flutter/foundation.dart';

import '../../dominio/comparador.dart';
import '../../dominio/excepciones.dart';
import '../../dominio/frase.dart';
import '../../dominio/nivel.dart';
import '../../dominio/voz.dart';
import 'aprendizaje_vm.dart';

/// Entrenamiento del OÍDO con dictado: escuchas, escribes lo que entendiste y se compara.
class DictadoViewModel extends ChangeNotifier {
  final Voz _voz;
  final AprendizajeViewModel _aprendizaje;

  DictadoViewModel(this._voz, this._aprendizaje);

  int indice = 0;
  int reproducciones = 0;
  ResultadoComparacion? resultado;
  bool ocupado = false;
  String? error;

  List<Frase> get frases => frasesDeNivel(_aprendizaje.nivel);
  Frase get actual => frases[indice % frases.length];

  Future<void> reproducir({bool lento = false}) async {
    if (ocupado) return;
    ocupado = true;
    error = null;
    notifyListeners();
    try {
      reproducciones++;
      await _voz.hablar(actual.ingles, velocidad: lento ? 0.6 : 1.0);
    } catch (e) {
      error = mensajeSeguro(e);
    }
    ocupado = false;
    notifyListeners();
  }

  Future<void> enviar(String escrito) async {
    if (reproducciones == 0) {
      error = 'Primero escucha la frase.';
      notifyListeners();
      return;
    }
    if (escrito.trim().isEmpty) {
      error = 'Escribe lo que entendiste.';
      notifyListeners();
      return;
    }
    error = null;
    resultado = comparar(actual.ingles, escrito);
    await _aprendizaje.registrarIntento(Habilidad.escucha, resultado!.puntaje, frase: actual);
    notifyListeners();
  }

  void siguiente() {
    indice++;
    reproducciones = 0;
    resultado = null;
    error = null;
    notifyListeners();
  }
}