enum Servicio {
  mensajeria('Mensajes', '💬'),
  pagos('Monedero', '💰'),
  comercio('Tienda', '🛒'),
  transporte('Viajes', '🚕');

  final String nombre;
  final String emoji;
  const Servicio(this.nombre, this.emoji);
}

/// Hechos que ocurren en la plataforma. Los servicios NO se llaman entre sí:
/// publican eventos y los demás (lealtad, notificaciones, analítica) reaccionan.
sealed class EventoApp {
  final String id;
  final String usuarioId;
  final DateTime fecha;
  const EventoApp(this.id, this.usuarioId, this.fecha);

  Servicio get servicio;

  /// ¿Cuenta como "uso activo" del usuario? Recibir dinero es pasivo y NO cuenta.
  bool get cuentaComoUso => true;
}

class PagoRealizado extends EventoApp {
  final int montoCentavos;
  final String concepto;
  final Servicio origen;
  const PagoRealizado(super.id, super.usuarioId, super.fecha,
      {required this.montoCentavos, required this.concepto, required this.origen});
  @override
  Servicio get servicio => origen;
}

class PedidoCreado extends EventoApp {
  final String pedidoId;
  final int totalCentavos;
  const PedidoCreado(super.id, super.usuarioId, super.fecha,
      {required this.pedidoId, required this.totalCentavos});
  @override
  Servicio get servicio => Servicio.comercio;
}

class ViajeFinalizado extends EventoApp {
  final String viajeId;
  final int montoCentavos;
  const ViajeFinalizado(super.id, super.usuarioId, super.fecha,
      {required this.viajeId, required this.montoCentavos});
  @override
  Servicio get servicio => Servicio.transporte;
}

class MensajeEnviado extends EventoApp {
  final String para;
  const MensajeEnviado(super.id, super.usuarioId, super.fecha, {required this.para});
  @override
  Servicio get servicio => Servicio.mensajeria;
}

class DineroRecibido extends EventoApp {
  final String de;
  final int montoCentavos;
  const DineroRecibido(super.id, super.usuarioId, super.fecha, {required this.de, required this.montoCentavos});
  @override
  Servicio get servicio => Servicio.pagos;
  @override
  bool get cuentaComoUso => false;
}

class Ids {
  int _n = 0;
  String siguiente(String prefijo) => '$prefijo-${++_n}';
}

/// Bus de eventos: publicar/suscribir con tipos. Un suscriptor que falla NO derrumba a los demás.
class BusEventos {
  final List<void Function(EventoApp)> _suscriptores = [];
  final List<Object> errores = [];

  void suscribir<T extends EventoApp>(void Function(T) manejador) {
    _suscriptores.add((e) {
      if (e is T) manejador(e);
    });
  }

  void publicar(EventoApp e) {
    for (final s in List.of(_suscriptores)) {
      try {
        s(e);
      } catch (err) {
        errores.add(err); // se registra y se sigue: aislamiento de fallos
      }
    }
  }
}