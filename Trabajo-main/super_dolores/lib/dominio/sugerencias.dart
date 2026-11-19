import 'eventos.dart';

class Sugerencia {
  final Servicio servicio;
  final String razon;
  const Sugerencia(this.servicio, this.razon);
}

/// "Siguiente mejor acción": propone el servicio que la persona AÚN NO usa (descubrimiento),
/// ordenado según la hora del día; si ya usa todos, propone el menos usado.
/// Es un sistema de reglas simple y explicable (se puede reemplazar luego por aprendizaje automático).
Sugerencia sugerirServicio({required Map<Servicio, int> usosUltimos30Dias, required DateTime ahora}) {
  final h = ahora.hour;
  final orden = switch (h) {
    >= 6 && < 11 => [Servicio.transporte, Servicio.mensajeria, Servicio.comercio, Servicio.pagos],
    >= 11 && < 16 => [Servicio.comercio, Servicio.pagos, Servicio.mensajeria, Servicio.transporte],
    >= 16 && < 22 => [Servicio.mensajeria, Servicio.comercio, Servicio.transporte, Servicio.pagos],
    _ => [Servicio.mensajeria, Servicio.pagos, Servicio.comercio, Servicio.transporte],
  };
  for (final s in orden) {
    if ((usosUltimos30Dias[s] ?? 0) == 0) {
      return Sugerencia(s, 'Aún no pruebas ${s.nombre}. ¡Descúbrelo!');
    }
  }
  var menor = orden.first;
  for (final s in orden) {
    if ((usosUltimos30Dias[s] ?? 0) < (usosUltimos30Dias[menor] ?? 0)) menor = s;
  }
  return Sugerencia(menor, 'Vuelve a ${menor.nombre}: es el que menos usas.');
}