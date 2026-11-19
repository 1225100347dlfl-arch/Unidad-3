import 'reglas.dart';

enum EstadoPalabra { correcta, parecida, sustituida, omitida, sobrante }

class ResultadoPalabra {
  final String? esperada;
  final String? dicha;
  final EstadoPalabra estado;
  const ResultadoPalabra(this.esperada, this.dicha, this.estado);
}

class ResultadoComparacion {
  final List<ResultadoPalabra> palabras;
  final int totalEsperadas;
  const ResultadoComparacion(this.palabras, this.totalEsperadas);

  int _cuenta(EstadoPalabra e) => palabras.where((p) => p.estado == e).length;

  /// 0 a 1. Correcta suma 1, parecida suma 0.5 y cada palabra sobrante resta 0.25.
  double get puntaje {
    if (totalEsperadas == 0) return 0;
    final bruto = _cuenta(EstadoPalabra.correcta) +
        0.5 * _cuenta(EstadoPalabra.parecida) -
        0.25 * _cuenta(EstadoPalabra.sobrante);
    return (bruto / totalEsperadas).clamp(0.0, 1.0);
  }

  bool get aprobado => puntaje >= Reglas.umbralAprobado;

  /// Las palabras que conviene volver a practicar.
  List<String> get porPracticar => [
        for (final p in palabras)
          if (p.esperada != null &&
              (p.estado == EstadoPalabra.sustituida ||
                  p.estado == EstadoPalabra.omitida ||
                  p.estado == EstadoPalabra.parecida))
            p.esperada!,
      ];
}

/// Minúsculas, sin puntuación (conserva apóstrofos: don't) y separado en palabras.
List<String> normalizar(String texto) => texto
    .toLowerCase()
    .replaceAll('’', "'")
    .replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ')
    .split(RegExp(r'\s+'))
    .where((s) => s.isNotEmpty)
    .toList();

int distanciaLevenshtein(String a, String b) {
  var previa = List<int>.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    final actual = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final costo = a[i - 1] == b[j - 1] ? 0 : 1;

      actual[j] = [previa[j] + 1, actual[j - 1] + 1, previa[j - 1] + costo].reduce((x, y) => x < y ? x : y);
    }
    previa = actual;
  }
  return previa[b.length];
}

/// 1.0 = idénticas, 0.0 = totalmente distintas.
double similitud(String a, String b) {
  final largo = a.length > b.length ? a.length : b.length;
  return largo == 0 ? 1.0 : 1 - distanciaLevenshtein(a, b) / largo;
}

double _costoSustitucion(String a, String b) =>
    a == b ? 0 : (similitud(a, b) >= Reglas.umbralParecida ? 0.5 : 1);

/// Alinea palabra por palabra lo ESPERADO contra lo DICHO (programación dinámica,
/// la misma idea de "diff" que usa Git) y clasifica cada palabra.
ResultadoComparacion comparar(String esperado, String dicho) {
  final e = normalizar(esperado);
  final d = normalizar(dicho);
  final n = e.length;
  final m = d.length;

  final t = List.generate(n + 1, (_) => List<double>.filled(m + 1, 0));
  for (var i = 0; i <= n; i++) {
    t[i][0] = i.toDouble();
  }
  for (var j = 0; j <= m; j++) {
    t[0][j] = j.toDouble();
  }
  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      final diag = t[i - 1][j - 1] + _costoSustitucion(e[i - 1], d[j - 1]);
      final arriba = t[i - 1][j] + 1;
      final izq = t[i][j - 1] + 1;
      t[i][j] = [diag, arriba, izq].reduce((x, y) => x < y ? x : y);
    }
  }

  // Camino de regreso: se prefiere la diagonal en los empates.
  final res = <ResultadoPalabra>[];
  var i = n;
  var j = m;
  while (i > 0 || j > 0) {

    if (i > 0 && j > 0 && t[i][j] == t[i - 1][j - 1] + _costoSustitucion(e[i - 1], d[j - 1])) {
      final a = e[i - 1];
      final b = d[j - 1];
      final estado = a == b
          ? EstadoPalabra.correcta

          : (similitud(a, b) >= Reglas.umbralParecida ? EstadoPalabra.parecida : EstadoPalabra.sustituida);
      res.add(ResultadoPalabra(a, b, estado));
      i--;
      j--;
    } else if (i > 0 && t[i][j] == t[i - 1][j] + 1) {
      res.add(ResultadoPalabra(e[i - 1], null, EstadoPalabra.omitida));
      i--;
    } else {
      res.add(ResultadoPalabra(null, d[j - 1], EstadoPalabra.sobrante));
      j--;
    }
  }
  return ResultadoComparacion(res.reversed.toList(), n);
}