import 'nivel.dart';
import 'reglas.dart';

class DominioHabilidad {
  final double dominio; // 0..1, promedio móvil
  final int intentos;
  const DominioHabilidad(this.dominio, this.intentos);
}

/// Seguimiento del avance: dominio por habilidad (EMA), nivel MCER y racha de días.
class Progreso {
  final Map<Habilidad, DominioHabilidad> _habilidades;
  NivelCefr nivel;
  int racha;
  DateTime? ultimoDia;

  Progreso({
    Map<Habilidad, DominioHabilidad>? habilidades,
    this.nivel = NivelCefr.a1,
    this.racha = 0,
    this.ultimoDia,
  }) : _habilidades = {...?habilidades};

  DominioHabilidad? de(Habilidad h) => _habilidades[h];

  /// Dominio actual; las habilidades sin datos valen [Reglas.dominioSinEvaluar].
  double dominioDe(Habilidad h) => _habilidades[h]?.dominio ?? Reglas.dominioSinEvaluar;

  /// EMA: nuevo = viejo*(1-a) + intento*a. Pesa más lo reciente sin olvidar lo anterior.
  void registrar(Habilidad h, double puntaje, DateTime hoy) {
    final p = puntaje.clamp(0.0, 1.0).toDouble();
    final actual = _habilidades[h];
    if (actual == null) {
      _habilidades[h] = DominioHabilidad(p, 1);
    } else {
      final a = Reglas.pesoUltimoIntento;

      _habilidades[h] = DominioHabilidad(actual.dominio * (1 - a) + p * a, actual.intentos + 1);
    }
    _actualizarRacha(hoy);
  }

  void _actualizarRacha(DateTime hoy) {
    final h = DateTime.utc(hoy.year, hoy.month, hoy.day);
    final u = ultimoDia;
    if (u == null) {
      racha = 1;
    } else {
      final dias = h.difference(DateTime.utc(u.year, u.month, u.day)).inDays;
      if (dias == 1) {
        racha += 1;
      } else if (dias > 1) {
        racha = 1;
      }
    }
    ultimoDia = h;
  }

  Habilidad get masDebil {
    var peor = Habilidad.values.first;
    for (final h in Habilidad.values) {
      if (dominioDe(h) < dominioDe(peor)) peor = h;
    }
    return peor;
  }

  bool get puedeSubirDeNivel =>
      nivel.siguiente != null &&
      Habilidad.values.every((h) {
        final d = _habilidades[h];

        return d != null && d.intentos >= Reglas.intentosParaSubir && d.dominio >= Reglas.dominioParaSubir;
      });

  /// Sube de nivel y REINICIA las habilidades: el nuevo nivel se evalúa desde cero.
  bool subirDeNivel() {
    if (!puedeSubirDeNivel) return false;
    nivel = nivel.siguiente!;
    _habilidades.clear();
    return true;
  }

  Map<String, Object?> aJson() => {
        'nivel': nivel.name,
        'racha': racha,
        'ultimoDia': ultimoDia?.toIso8601String(),
        'habilidades': {
          for (final e in _habilidades.entries)
            e.key.name: {'dominio': e.value.dominio, 'intentos': e.value.intentos},
        },
      };

  static Progreso desdeJson(Object? o) {
    if (o is! Map) return Progreso();
    try {
      final hs = <Habilidad, DominioHabilidad>{};
      final mapa = o['habilidades'] as Map;
      for (final h in Habilidad.values) {
        final v = mapa[h.name];

        if (v is Map) hs[h] = DominioHabilidad((v['dominio'] as num).toDouble(), v['intentos'] as int);
      }
      return Progreso(
        habilidades: hs,

        nivel: NivelCefr.values.firstWhere((n) => n.name == o['nivel'], orElse: () => NivelCefr.a1),
        racha: o['racha'] as int,
        ultimoDia: o['ultimoDia'] == null ? null : DateTime.parse(o['ultimoDia'] as String),
      );
    } catch (_) {
      return Progreso();
    }
  }
}