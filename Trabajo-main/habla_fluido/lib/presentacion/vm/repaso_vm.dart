import 'package:flutter/foundation.dart';

import '../../dominio/repaso.dart';
import '../../dominio/voz.dart';
import 'aprendizaje_vm.dart';

/// Repaso con RECUPERACIÓN ACTIVA: ves la frase en español, intentas decirla en inglés
/// ANTES de ver la respuesta, y te autocalificas. Esfuerzo de recordar = memoria más fuerte.
class RepasoViewModel extends ChangeNotifier {
  final AprendizajeViewModel _aprendizaje;
  final Voz _voz;
  RepasoViewModel(this._aprendizaje, this._voz) {
    _cola = _aprendizaje.pendientes;
  }

  late List<TarjetaRepaso> _cola;
  bool respuestaVisible = false;

  bool get terminado => _cola.isEmpty;
  int get restantes => _cola.length;
  TarjetaRepaso? get actual => _cola.isEmpty ? null : _cola.first;

  Future<void> mostrarRespuesta() async {
    final t = actual;
    if (t == null) return;
    respuestaVisible = true;
    notifyListeners();
    try {
      await _voz.hablar(t.frase);
    } catch (_) {}
  }

  /// Botones típicos: "Otra vez" = 1, "Difícil" = 3, "Bien" = 4, "Fácil" = 5.
  Future<void> calificar(int calidad) async {
    final t = actual;
    if (t == null || !respuestaVisible) return;
    await _aprendizaje.calificarTarjeta(t.id, calidad);
    _cola = [..._cola]..removeAt(0);
    // Si fue "otra vez", vuelve al final de la cola de HOY para repetirla en esta sesión.
    if (calidad < 3) {
      final nueva = _aprendizaje.mazo.todas.where((x) => x.id == t.id);
      if (nueva.isNotEmpty) _cola.add(nueva.first);
    }
    respuestaVisible = false;
    notifyListeners();
  }
}