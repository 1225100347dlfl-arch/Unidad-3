import 'dart:convert';
import 'dart:math' as math;

enum Humor { feliz, hambriento, famelico }

class YaEstaLlena implements Exception {
  const YaEstaLlena(this.nombre);
  final String nombre;
  @override
  String toString() => '$nombre ya no puede comer más';
}

/// Un ajolote cuya saciedad BAJA con el tiempo. No guardamos "cuánta hambre
/// tiene ahora": guardamos un punto de partida (saciedadBase en `desde`) y
/// CALCULAMOS el valor para cualquier instante.
class Mascota {
  const Mascota({
    required this.nombre,
    required this.saciedadBase,
    required this.desde,
    this.puntosPorHora = 10,
  }) : assert(puntosPorHora > 0);

  factory Mascota.nueva(String nombre, DateTime ahora, {double puntosPorHora = 10}) =>
      Mascota(nombre: nombre, saciedadBase: maxSaciedad, desde: ahora, puntosPorHora: puntosPorHora);

  static const double maxSaciedad = 100;
  static const double umbralHambre = 40;
  static const double umbralCritico = 15;
  static const double limiteParaComer = 90;
  static const double porcion = 35;

  final String nombre;
  final double saciedadBase;
  final DateTime desde;
  final double puntosPorHora;

  double saciedadEn(DateTime t) {
    if (!t.isAfter(desde)) return saciedadBase;
    final horas = t.difference(desde).inMicroseconds / Duration.microsecondsPerHour;
    return math.max(0.0, saciedadBase - horas * puntosPorHora);
  }

  Humor humorEn(DateTime t) {
    final s = saciedadEn(t);
    if (s <= umbralCritico) return Humor.famelico;
    if (s <= umbralHambre) return Humor.hambriento;
    return Humor.feliz;
  }

  /// Instante en que la saciedad baja hasta [umbral]. Si ya estaba por debajo
  /// al empezar, devuelve `desde`.
  DateTime momentoEnQueBajaA(double umbral) {
    if (saciedadBase <= umbral) return desde;
    final horas = (saciedadBase - umbral) / puntosPorHora;
    return desde.add(Duration(microseconds: (horas * Duration.microsecondsPerHour).round()));
  }

  Mascota alimentar(DateTime t) {
    final actual = saciedadEn(t);
    if (actual >= limiteParaComer) throw YaEstaLlena(nombre);
    return Mascota(
      nombre: nombre,
      saciedadBase: math.min(maxSaciedad, actual + porcion),
      desde: t,
      puntosPorHora: puntosPorHora,
    );
  }

  /// Cambia el ritmo SIN saltos: la saciedad de este instante es el nuevo punto de partida.
  Mascota conRitmo(DateTime t, double nuevoRitmo) =>
      Mascota(nombre: nombre, saciedadBase: saciedadEn(t), desde: t, puntosPorHora: nuevoRitmo);

  Map<String, Object> toJson() => {
        'nombre': nombre,
        'saciedadBase': saciedadBase,
        'desde': desde.toIso8601String(),
        'puntosPorHora': puntosPorHora,
      };

  String aTexto() => jsonEncode(toJson());

  /// Lo guardado en disco NO es de fiar: valida todo y devuelve null si algo no cuadra.
  static Mascota? desdeTexto(String? texto) {
    if (texto == null) return null;
    try {
      final j = jsonDecode(texto);
      if (j is! Map<String, dynamic>) return null;
      final n = j['nombre'];
      final s = j['saciedadBase'];
      final d = j['desde'];
      final r = j['puntosPorHora'];
      if (n is! String || n.isEmpty || s is! num || d is! String || r is! num) return null;
      final fecha = DateTime.tryParse(d);
      if (fecha == null || s < 0 || s > maxSaciedad || r <= 0) return null;
      return Mascota(nombre: n, saciedadBase: s.toDouble(), desde: fecha, puntosPorHora: r.toDouble());
    } on FormatException {
      return null;
    }
  }
}