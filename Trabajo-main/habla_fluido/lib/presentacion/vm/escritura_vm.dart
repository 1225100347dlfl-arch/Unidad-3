import 'package:flutter/foundation.dart';

import '../../dominio/excepciones.dart';
import '../../dominio/nivel.dart';
import '../../dominio/reglas.dart';
import '../../dominio/tutor.dart';
import 'aprendizaje_vm.dart';

class EscrituraViewModel extends ChangeNotifier {
  final TutorIA _tutor;
  final AprendizajeViewModel _aprendizaje;
  EscrituraViewModel(this._tutor, this._aprendizaje);

  RespuestaTutor? resultado;
  bool ocupado = false;
  String? error;

  static const _temas = {
    NivelCefr.a1: 'Write 3 sentences about your family.',
    NivelCefr.a2: 'Write about what you did last weekend.',
    NivelCefr.b1: 'Write a short paragraph about your plans for next year.',
    NivelCefr.b2: 'Write your opinion about studying online.',
    NivelCefr.c1: 'Write a short argument for or against remote work.',
  };
  String get tema => _temas[_aprendizaje.nivel]!;


  /// 1.0 sin errores; cada error corregido resta 0.2. Es una heurística sencilla, no una calificación oficial.
  static double puntajeDe(int errores) => (1 - 0.2 * errores).clamp(0.0, 1.0);

  Future<void> enviar(String texto) async {
    if (ocupado) return;
    final palabras = texto.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).length;
    if (palabras < Reglas.palabrasMinimasEscritura) {
      error = 'Escribe al menos ${Reglas.palabrasMinimasEscritura} palabras.';
      notifyListeners();
      return;
    }
    ocupado = true;
    error = null;
    notifyListeners();
    try {
      final r = await _tutor.corregir(nivel: _aprendizaje.nivel, texto: texto.trim());
      resultado = r;

      await _aprendizaje.registrarIntento(Habilidad.escritura, puntajeDe(r.correcciones.length));
    } catch (e) {
      error = mensajeSeguro(e);
    }
    ocupado = false;
    notifyListeners();
  }
}