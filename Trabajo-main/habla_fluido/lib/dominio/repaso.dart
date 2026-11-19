/// Repetición espaciada (algoritmo SM-2, simplificado). Cada vez que recuerdas bien
/// una frase, la siguiente revisión se aleja más en el tiempo; si fallas, vuelve pronto.
class TarjetaRepaso {
  final String id;
  final String frase;
  final String traduccion;
  final double facilidad;
  final int intervaloDias;
  final int repeticiones;
  final DateTime proxima;

  const TarjetaRepaso({
    required this.id,
    required this.frase,
    required this.traduccion,
    required this.proxima,
    this.facilidad = 2.5,
    this.intervaloDias = 0,
    this.repeticiones = 0,
  });

  bool estaVencida(DateTime hoy) => !_soloFecha(proxima).isAfter(_soloFecha(hoy));

  /// [calidad]: 0 (no la recordé) a 5 (perfecta).
  TarjetaRepaso calificar(int calidad, DateTime hoy) {
    if (calidad < 0 || calidad > 5) throw ArgumentError('La calidad va de 0 a 5');
    final d = _soloFecha(hoy);
    var reps = repeticiones;
    var intervalo = intervaloDias;
    if (calidad < 3) {
      reps = 0;
      intervalo = 1;
    } else {
      reps += 1;
      intervalo = reps == 1 ? 1 : (reps == 2 ? 6 : (intervaloDias * facilidad).round());
    }
    final q = 5 - calidad;

    final nuevaFacilidad = (facilidad + (0.1 - q * (0.08 + q * 0.02))).clamp(1.3, 10.0).toDouble();
    return TarjetaRepaso(
      id: id,
      frase: frase,
      traduccion: traduccion,
      facilidad: nuevaFacilidad,
      intervaloDias: intervalo,
      repeticiones: reps,
      proxima: DateTime(d.year, d.month, d.day + intervalo),
    );
  }

  Map<String, Object?> aJson() => {
        'id': id,
        'frase': frase,
        'traduccion': traduccion,
        'facilidad': facilidad,
        'intervaloDias': intervaloDias,
        'repeticiones': repeticiones,
        'proxima': proxima.toIso8601String(),
      };

  static TarjetaRepaso? desdeJson(Object? o) {
    if (o is! Map) return null;
    try {
      return TarjetaRepaso(
        id: o['id'] as String,
        frase: o['frase'] as String,
        traduccion: o['traduccion'] as String,
        facilidad: (o['facilidad'] as num).toDouble(),
        intervaloDias: o['intervaloDias'] as int,
        repeticiones: o['repeticiones'] as int,
        proxima: DateTime.parse(o['proxima'] as String),
      );
    } catch (_) {
      return null; // dato dañado: se descarta en lugar de tronar
    }
  }
}

DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

/// Convierte el puntaje de un intento (0 a 1) en la calidad 0..5 de SM-2.
int calidadDesdePuntaje(double p) {
  if (p >= 0.95) return 5;
  if (p >= 0.85) return 4;
  if (p >= 0.70) return 3;
  if (p >= 0.50) return 2;
  if (p >= 0.30) return 1;
  return 0;
}

class MazoRepaso {
  final Map<String, TarjetaRepaso> _tarjetas = {};

  MazoRepaso([Iterable<TarjetaRepaso> iniciales = const []]) {
    for (final t in iniciales) {
      _tarjetas[t.id] = t;
    }
  }

  List<TarjetaRepaso> get todas => _tarjetas.values.toList();

  List<TarjetaRepaso> pendientes(DateTime hoy) =>
      _tarjetas.values.where((t) => t.estaVencida(hoy)).toList()
        ..sort((a, b) => a.proxima.compareTo(b.proxima));

  /// Califica una tarjeta que el estudiante repasó (0 a 5). Si no existe, no hace nada.
  void calificar(String id, int calidad, DateTime hoy) {
    final t = _tarjetas[id];
    if (t != null) _tarjetas[id] = t.calificar(calidad, hoy);
  }
  /// Registra un intento: crea la tarjeta si no existía y la reprograma.
  void registrar({required String id, required String frase, required String traduccion,
      required double puntaje, required DateTime hoy}) {

    final base = _tarjetas[id] ?? TarjetaRepaso(id: id, frase: frase, traduccion: traduccion, proxima: hoy);
    _tarjetas[id] = base.calificar(calidadDesdePuntaje(puntaje), hoy);
  }
}