import 'categoria.dart';

/// Las reglas de buena educación de la app, en un solo lugar y con pruebas.
class PoliticaNotificaciones {
  const PoliticaNotificaciones({
    this.silencioDesde = 22,
    this.silencioHasta = 8,
    this.maxPorDia = 3,
    this.margenEntreAvisos = const Duration(minutes: 30),
    this.activas = const {Categoria.hambre, Categoria.sorpresa},
  });

  final int silencioDesde; // hora (0-23) en que empieza el silencio
  final int silencioHasta; // hora en que termina
  final int maxPorDia;
  final Duration margenEntreAvisos;
  final Set<Categoria> activas;

  bool habilitada(Categoria c) => activas.contains(c);

  bool enSilencio(DateTime t) {
    if (silencioDesde == silencioHasta) return false;
    final h = t.hour;
    return silencioDesde > silencioHasta
        ? (h >= silencioDesde || h < silencioHasta) // cruza la medianoche
        : (h >= silencioDesde && h < silencioHasta);
  }

  /// Si [t] cae en horas de silencio, lo pasa al final del silencio.
  DateTime ajustar(DateTime t) {
    if (!enSilencio(t)) return t;
    final finHoy = DateTime(t.year, t.month, t.day, silencioHasta);
    return t.isBefore(finHoy) ? finHoy : DateTime(t.year, t.month, t.day + 1, silencioHasta);
  }
}