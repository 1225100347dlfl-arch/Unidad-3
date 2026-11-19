import 'package:flutter/foundation.dart';

import '../../dominio/almacen.dart';
import '../../dominio/frase.dart';
import '../../dominio/nivel.dart';
import '../../dominio/plan_diario.dart';
import '../../dominio/progreso.dart';
import '../../dominio/repaso.dart';

/// Núcleo del aprendizaje: progreso por habilidad, repaso espaciado y persistencia.
/// Los demás ViewModels le reportan sus resultados.
class AprendizajeViewModel extends ChangeNotifier {
  final AlmacenAvance _almacen;
  final DateTime Function() _reloj;

  Progreso progreso = Progreso();
  MazoRepaso mazo = MazoRepaso();


  AprendizajeViewModel(this._almacen, {DateTime Function()? reloj}) : _reloj = reloj ?? DateTime.now;

  DateTime get hoy => _reloj();
  NivelCefr get nivel => progreso.nivel;
  List<BloquePlan> get plan => generarPlan(progreso);
  List<TarjetaRepaso> get pendientes => mazo.pendientes(hoy);
  bool get puedeSubirDeNivel => progreso.puedeSubirDeNivel;

  Future<void> cargar() async {
    final datos = await _almacen.cargar();
    if (datos != null) {
      progreso = Progreso.desdeJson(datos['progreso']);
      final lista = datos['tarjetas'];
      mazo = MazoRepaso([
        if (lista is List) ...lista.map(TarjetaRepaso.desdeJson).whereType<TarjetaRepaso>(),
      ]);
    }
    notifyListeners();
  }

  /// Un intento terminado. Si viene con [frase], también entra al repaso espaciado.
  Future<void> registrarIntento(Habilidad h, double puntaje, {Frase? frase}) async {
    progreso.registrar(h, puntaje, hoy);
    if (frase != null) {
      mazo.registrar(id: frase.id, frase: frase.ingles, traduccion: frase.espanol, puntaje: puntaje, hoy: hoy);
    }
    await _guardar();
    notifyListeners();
  }

  Future<void> calificarTarjeta(String id, int calidad) async {
    mazo.calificar(id, calidad, hoy);
    await _guardar();
    notifyListeners();
  }

  Future<void> subirDeNivel() async {
    if (progreso.subirDeNivel()) {
      await _guardar();
      notifyListeners();
    }
  }

  Future<void> _guardar() async {
    try {
      await _almacen.guardar({
        'progreso': progreso.aJson(),
        'tarjetas': [for (final t in mazo.todas) t.aJson()],
      });
    } catch (_) {
      // Guardar es "mejor esfuerzo": un fallo de disco no debe interrumpir la práctica.
    }
  }
}