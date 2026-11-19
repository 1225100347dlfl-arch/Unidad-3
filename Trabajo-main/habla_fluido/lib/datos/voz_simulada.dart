import 'dart:collection';

import '../dominio/voz.dart';

/// Voz de mentiras para pruebas: guarda lo que "dijo" y devuelve lo que tú le programes.
class VozSimulada implements Voz {
  final Queue<String?> _porEscuchar;
  final List<String> dichos = [];
  final List<double> velocidades = [];
  int escuchas = 0;


  VozSimulada([Iterable<String?> respuestas = const []]) : _porEscuchar = Queue.of(respuestas);

  void programar(String? respuesta) => _porEscuchar.add(respuesta);

  @override
  Future<void> hablar(String texto, {double velocidad = 1.0}) async {
    dichos.add(texto);
    velocidades.add(velocidad);
  }

  @override
  Future<String?> escuchar({Duration limite = const Duration(seconds: 8)}) async {
    escuchas++;
    return _porEscuchar.isEmpty ? null : _porEscuchar.removeFirst();
  }

  @override
  Future<void> detener() async {}
}