import 'dart:math' as math;

import 'dinero.dart';
import 'eventos.dart';
import 'excepciones.dart';
import 'monedero.dart';

class Punto {
  final double lat;
  final double lon;
  const Punto(this.lat, this.lon);
}

/// Distancia en línea recta sobre la esfera terrestre (fórmula de Haversine).
double distanciaKm(Punto a, Punto b) {
  const r = 6371.0088;
  double rad(double g) => g * math.pi / 180;
  final dLat = rad(b.lat - a.lat);
  final dLon = rad(b.lon - a.lon);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.lat)) * math.cos(rad(b.lat)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}

class Tarifa {
  static const int baseCentavos = 2500;
  static const int porKmCentavos = 800;
  static const int porMinutoCentavos = 150;
  static const int minimoCentavos = 4500;
  static const double maxMultiplicador = 2.0; // tope a la "tarifa dinámica"
  static const int cancelacionCentavos = 1500;
  static const double velocidadUrbanaKmh = 25;

  static int minutosEstimados(double km) => (km / velocidadUrbanaKmh * 60).ceil();

  /// base + km + minutos, por el multiplicador (entre 1.0 y el tope), con un mínimo.
  static int calcular({required double km, required int minutos, double multiplicador = 1.0}) {
    final m = multiplicador.clamp(1.0, maxMultiplicador).toDouble();
    final crudo = baseCentavos + (km * porKmCentavos).round() + minutos * porMinutoCentavos;
    final total = (crudo * m).round();
    return total < minimoCentavos ? minimoCentavos : total;
  }
}

enum EstadoViaje { solicitado, aceptado, enCurso, finalizado, cancelado }

/// Máquina de estados: solo estas transiciones son legales. Lo demás es un error.
const _transiciones = <EstadoViaje, Set<EstadoViaje>>{
  EstadoViaje.solicitado: {EstadoViaje.aceptado, EstadoViaje.cancelado},
  EstadoViaje.aceptado: {EstadoViaje.enCurso, EstadoViaje.cancelado},
  EstadoViaje.enCurso: {EstadoViaje.finalizado},
  EstadoViaje.finalizado: {},
  EstadoViaje.cancelado: {},
};

class Viaje {
  final String id;
  final String usuarioId;
  final Punto origen;
  final Punto destino;
  final int estimadoCentavos;
  final EstadoViaje estado;
  final String? conductorId;
  final int? cobradoCentavos;

  const Viaje(this.id, this.usuarioId, this.origen, this.destino, this.estimadoCentavos, this.estado,
      {this.conductorId, this.cobradoCentavos});

  Viaje _a(EstadoViaje nuevo, {String? conductorId, int? cobrado}) {
    if (!_transiciones[estado]!.contains(nuevo)) throw const TransicionInvalidaException();
    return Viaje(id, usuarioId, origen, destino, estimadoCentavos, nuevo,
        conductorId: conductorId ?? this.conductorId, cobradoCentavos: cobrado ?? cobradoCentavos);
  }
}

class ServicioViajes {
  static const int comisionPct = 20;
  static const String cuentaPlataforma = 'plataforma';

  final Monedero _monedero;
  final BusEventos _bus;
  final Ids _ids;
  final DateTime Function() _reloj;
  final Map<String, Viaje> _viajes = {};

  ServicioViajes(this._monedero, this._bus, this._ids, this._reloj);

  Viaje? porId(String id) => _viajes[id];

  List<Viaje> deUsuario(String u) => _viajes.values.where((v) => v.usuarioId == u).toList().reversed.toList();

  int estimar(Punto origen, Punto destino, {double multiplicador = 1.0}) {
    final km = distanciaKm(origen, destino);
    return Tarifa.calcular(km: km, minutos: Tarifa.minutosEstimados(km), multiplicador: multiplicador);
  }

  Viaje solicitar(String usuarioId, Punto origen, Punto destino) {
    final est = estimar(origen, destino);
    if (_monedero.saldo(usuarioId) < est) throw const SaldoInsuficienteException();
    final v = Viaje(_ids.siguiente('via'), usuarioId, origen, destino, est, EstadoViaje.solicitado);
    return _viajes[v.id] = v;
  }

  Viaje aceptar(String id, String conductorId) => _guardar(_viajes[id]!._a(EstadoViaje.aceptado, conductorId: conductorId));

  Viaje iniciar(String id) => _guardar(_viajes[id]!._a(EstadoViaje.enCurso));

  /// Cobra la tarifa REAL (distancia y tiempo medidos) y paga al conductor menos la comisión.
  Viaje finalizar(String id, {required double kmReal, required int minutosReal, double multiplicador = 1.0}) {
    final v = _viajes[id]!;
    final cobrar = Tarifa.calcular(km: kmReal, minutos: minutosReal, multiplicador: multiplicador);
    final listo = v._a(EstadoViaje.finalizado, cobrado: cobrar); // valida la transición primero
    _monedero.transferir(v.usuarioId, cuentaPlataforma, cobrar, 'Viaje ${v.id}', clave: 'viaje:${v.id}');
    final comision = porcentaje(cobrar, comisionPct);
    _monedero.transferir(cuentaPlataforma, v.conductorId!, cobrar - comision, 'Pago de viaje ${v.id}',
        clave: 'liberar-viaje:${v.id}');
    final ahora = _reloj();
    _bus.publicar(PagoRealizado(_ids.siguiente('ev'), v.usuarioId, ahora,
        montoCentavos: cobrar, concepto: 'Viaje ${v.id}', origen: Servicio.transporte));
    _bus.publicar(ViajeFinalizado(_ids.siguiente('ev'), v.usuarioId, ahora, viajeId: v.id, montoCentavos: cobrar));
    return _guardar(listo);
  }

  /// Cancelar es gratis antes de que acepte un conductor; después, cuesta la tarifa de cancelación
  /// (o lo que haya de saldo si es menos).
  Viaje cancelar(String id) {
    final v = _viajes[id]!;
    final listo = v._a(EstadoViaje.cancelado);
    if (v.estado == EstadoViaje.aceptado) {
      final saldo = _monedero.saldo(v.usuarioId);
      final cargo = saldo < Tarifa.cancelacionCentavos ? saldo : Tarifa.cancelacionCentavos;
      if (cargo > 0) {
        _monedero.transferir(v.usuarioId, v.conductorId!, cargo, 'Cancelación ${v.id}', clave: 'cancela:${v.id}');
      }
    }
    return _guardar(listo);
  }

  Viaje _guardar(Viaje v) => _viajes[v.id] = v;
}