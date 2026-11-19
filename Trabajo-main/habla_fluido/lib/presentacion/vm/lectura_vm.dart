import 'package:flutter/foundation.dart';

import '../../dominio/lectura.dart';
import '../../dominio/nivel.dart';
import 'aprendizaje_vm.dart';

class LecturaViewModel extends ChangeNotifier {
  final AprendizajeViewModel _aprendizaje;
  LecturaViewModel(this._aprendizaje);

  int indiceTexto = 0;
  final Map<int, int> respuestas = {}; // pregunta -> opción elegida
  bool _registrado = false;
  List<TextoLectura> get textos => lecturasDeNivel(_aprendizaje.nivel);
  TextoLectura get actual => textos[indiceTexto % textos.length];
  bool get terminado => respuestas.length == actual.preguntas.length;

  int get correctas {
    var n = 0;
    respuestas.forEach((p, o) {
      if (actual.preguntas[p].correcta == o) n++;
    });
    return n;
  }

  double get puntaje => actual.preguntas.isEmpty ? 0 : correctas / actual.preguntas.length;

  /// Solo se puede responder una vez por pregunta (se aprende más del primer intento).
  Future<void> responder(int pregunta, int opcion) async {
    if (pregunta < 0 || pregunta >= actual.preguntas.length) return;
    if (opcion < 0 || opcion >= actual.preguntas[pregunta].opciones.length) return;
    if (respuestas.containsKey(pregunta)) return;
    respuestas[pregunta] = opcion;
    if (terminado && !_registrado) {
      _registrado = true;
      await _aprendizaje.registrarIntento(Habilidad.lectura, puntaje);
    }
    notifyListeners();
  }

  void siguienteTexto() {
    indiceTexto++;
    respuestas.clear();
    _registrado = false;
    notifyListeners();
  }
}