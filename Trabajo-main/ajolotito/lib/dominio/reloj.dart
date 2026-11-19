/// El reloj es una dependencia: así las pruebas controlan el tiempo.
abstract class Reloj {
  DateTime ahora();
}

class RelojSistema implements Reloj {
  const RelojSistema();
  @override
  DateTime ahora() => DateTime.now();
}

/// Reloj de pruebas: el tiempo solo avanza cuando tú lo dices.
class RelojFalso implements Reloj {
  RelojFalso(this._t);
  DateTime _t;
  @override
  DateTime ahora() => _t;
  void avanzar(Duration d) => _t = _t.add(d);
  void fijar(DateTime t) => _t = t;
}