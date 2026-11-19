import 'nivel.dart';
import 'progreso.dart';
import 'reglas.dart';

class BloquePlan {
  final Habilidad habilidad;
  final int minutos;
  final bool esRefuerzo;
  const BloquePlan(this.habilidad, this.minutos, {this.esRefuerzo = false});
}

const _pesosBase = {
  Habilidad.escucha: 0.20,
  Habilidad.pronunciacion: 0.20,
  Habilidad.lectura: 0.20,
  Habilidad.escritura: 0.15,
  Habilidad.conversacion: 0.25,
};

/// Reparte la sesión entre las 5 habilidades y da un extra a la más débil.
/// Los minutos son enteros y SUMAN exactamente [minutosTotales] (método del mayor resto).

List<BloquePlan> generarPlan(Progreso progreso, {int minutosTotales = Reglas.minutosPorSesion}) {
  final debil = progreso.masDebil;
  final habilidades = Habilidad.values;
  final pesos = [

    for (final h in habilidades) _pesosBase[h]! + (h == debil ? Reglas.extraHabilidadDebil : 0),
  ];
  final suma = pesos.fold<double>(0, (a, b) => a + b);
  final crudos = [for (final w in pesos) w / suma * minutosTotales];
  final minutos = [for (final c in crudos) c.floor()];
  var resto = minutosTotales - minutos.fold<int>(0, (a, b) => a + b);

  // Los que tengan mayor parte decimal reciben el minuto sobrante (empates: el primero).
  final orden = List<int>.generate(habilidades.length, (i) => i)
    ..sort((a, b) {
      final fa = crudos[a] - minutos[a];
      final fb = crudos[b] - minutos[b];
      final c = fb.compareTo(fa);
      return c != 0 ? c : a.compareTo(b);
    });
  for (final i in orden) {
    if (resto <= 0) break;
    minutos[i]++;
    resto--;
  }
  return [
    for (var i = 0; i < habilidades.length; i++)
      BloquePlan(habilidades[i], minutos[i], esRefuerzo: habilidades[i] == debil),
  ];
}