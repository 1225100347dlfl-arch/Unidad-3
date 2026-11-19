import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../dominio/analitica.dart';
import '../../dominio/dinero.dart';
import '../../dominio/eventos.dart';

/// Genera uso SINTÉTICO (inventado, con semilla fija) para practicar el cálculo de métricas.
///  Estos números NO son reales: sirven para aprender a leer un tablero de retención.
Analitica simularUso({required DateTime inicio, int usuarios = 200, int dias = 30, int semilla = 42}) {
  final rnd = Random(semilla);
  final a = Analitica();
  for (var u = 0; u < usuarios; u++) {
    final llegada = rnd.nextInt(dias - 14); // llega algún día de las primeras semanas
    final motivacion = rnd.nextDouble(); // 0 = poco interesado, 1 = muy interesado
    final servicios = Servicio.values;
    final cuantos = 1 + (motivacion * 3.2).floor().clamp(0, 3).toInt(); // los motivados prueban más servicios
    final favoritos = ([...servicios]..shuffle(rnd)).take(cuantos).toList();
    for (var d = llegada; d < dias; d++) {
      final prob = d == llegada ? 1.0 : (0.15 + 0.7 * motivacion) * pow(0.97, d - llegada);
      if (rnd.nextDouble() < prob) {
        a.agregar(RegistroUso('u$u', favoritos[rnd.nextInt(favoritos.length)], masDias(inicio, d)));
      }
    }
  }
  return a;
}

class MetricasViewModel extends ChangeNotifier {
  final DateTime inicio;
  late final Analitica analitica = simularUso(inicio: inicio);
  MetricasViewModel(this.inicio);

  DateTime get ultimoDia => masDias(inicio, 29);
  int get dau => analitica.dau(ultimoDia);
  int get wau => analitica.wau(ultimoDia);
  int get mau => analitica.mau(ultimoDia);
  double get stickiness => analitica.stickiness(ultimoDia);
  double get serviciosPorUsuario => analitica.serviciosPorUsuario(inicio, ultimoDia);
  double get multiservicio => analitica.porcentajeMultiservicio(inicio, ultimoDia);

  /// Retención D1 y D7 promedio de las cohortes diarias con datos.
  double retencionPromedio(int n) {
    final tasas = <double>[];
    for (var d = 0; d < 30 - n; d++) {
      final dia = masDias(inicio, d);
      if (analitica.cohorte(dia).isNotEmpty) tasas.add(analitica.retencion(dia, n));
    }
    return tasas.isEmpty ? 0 : tasas.reduce((a, b) => a + b) / tasas.length;
  }

  ({double unServicio, double multiservicio, int nUno, int nMulti}) get comparacion =>
      analitica.retencionSemana2PorServicios(inicio, masDias(inicio, 14));
}