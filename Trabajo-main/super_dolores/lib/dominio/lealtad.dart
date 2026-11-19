import 'dinero.dart';
import 'eventos.dart';
import 'excepciones.dart';
import 'monedero.dart';

enum NivelLealtad {
  bronce('Bronce', 0, 100),
  plata('Plata', 500, 125),
  oro('Oro', 2000, 150);

  final String nombre;
  final int puntosMinimos;
  final int porcentajePuntos; // multiplicador de puntos por gasto
  const NivelLealtad(this.nombre, this.puntosMinimos, this.porcentajePuntos);
}

/// Motor de RETENCIÓN. Reglas (todas con nombre y a la vista):
///  1. Gasto: 1 punto por cada $10 en comercio o viajes, por el multiplicador del nivel.
///  2. Bono semanal por usar servicios DISTINTOS: 2 → +50, 3 → +100, 4 → +200 (una vez por semana cada escalón).
///  3. Racha: cada 7 días seguidos usando la app → +70.
///  4. Canje: 100 puntos = $10 de saldo (equivale a ~1% de devolución sobre el gasto base).
class Lealtad {
  static const int centavosPorPunto = 1000;
  static const Map<int, int> bonoSemanal = {2: 50, 3: 100, 4: 200};
  static const int bonoRacha = 70;
  static const int diasPorBonoRacha = 7;
  static const int puntosPorCanje = 100;
  static const int centavosPorCanje = 1000;

  final Monedero _monedero;
  final Map<String, int> _puntos = {};
  final Set<String> _procesados = {};
  final Map<String, Map<DateTime, Set<Servicio>>> _semanas = {};
  final Map<String, DateTime> _ultimoDia = {};
  final Map<String, int> _racha = {};
  int _canjes = 0;

  Lealtad(this._monedero);

  /// Conecta el motor al bus: así comercio, viajes y mensajes NO saben que existe la lealtad.
  void conectar(BusEventos bus) {
    bus.suscribir<EventoApp>(alEvento);
  }

  int puntos(String u) => _puntos[u] ?? 0;
  int racha(String u) => _racha[u] ?? 0;

  NivelLealtad nivel(String u) {
    final p = puntos(u);
    return NivelLealtad.values.lastWhere((n) => p >= n.puntosMinimos);
  }

  void _dar(String u, int n) => _puntos[u] = puntos(u) + n;

  void alEvento(EventoApp e) {
    if (!e.cuentaComoUso) return;
    if (!_procesados.add(e.id)) return; // idempotencia: el mismo evento no premia dos veces

    final u = e.usuarioId;

    // 1) Puntos por gasto (solo cuando se completó la compra o el viaje).
    final gasto = switch (e) {
      PedidoCreado(:final totalCentavos) => totalCentavos,
      ViajeFinalizado(:final montoCentavos) => montoCentavos,
      _ => 0,
    };
    if (gasto > 0) {
      final base = gasto ~/ centavosPorPunto;
      _dar(u, base * nivel(u).porcentajePuntos ~/ 100);
    }

    // 2) Bono semanal por variedad de servicios.
    final semana = lunesDe(e.fecha);
    final usados = ((_semanas[u] ??= {})[semana] ??= {});
    final antes = usados.length;
    usados.add(e.servicio);
    final despues = usados.length;
    if (despues > antes) {
      final bono = bonoSemanal[despues];
      if (bono != null) _dar(u, bono);
    }

    // 3) Racha de días consecutivos.
    final dia = soloFecha(e.fecha);
    final ultimo = _ultimoDia[u];
    if (ultimo == null) {
      _racha[u] = 1;
    } else if (dia == masDias(ultimo, 1)) {
      _racha[u] = racha(u) + 1;
      if (racha(u) % diasPorBonoRacha == 0) _dar(u, bonoRacha);
    } else if (dia.isAfter(ultimo)) {
      _racha[u] = 1;
    }
    if (ultimo == null || dia.isAfter(ultimo)) _ultimoDia[u] = dia;
  }

  /// Canjea [puntosACanjear] (múltiplo de 100) por saldo en el monedero.
  int canjear(String u, int puntosACanjear) {
    if (puntosACanjear <= 0 || puntosACanjear % puntosPorCanje != 0) {
      throw const CanjeInvalidoException('Canjea múltiplos de 100 puntos.');
    }
    if (puntosACanjear > puntos(u)) throw const CanjeInvalidoException('No tienes suficientes puntos.');
    final centavos = puntosACanjear ~/ puntosPorCanje * centavosPorCanje;
    _monedero.reembolsar(u, centavos, 'Canje de puntos', clave: 'canje:$u:${++_canjes}');
    _puntos[u] = puntos(u) - puntosACanjear;
    return centavos;
  }
}