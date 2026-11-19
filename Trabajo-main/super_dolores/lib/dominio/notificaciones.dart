import 'dinero.dart';
import 'eventos.dart';

enum TipoNotificacion { transaccional, promocional }

class Notificacion {
  final String usuarioId;
  final TipoNotificacion tipo;
  final String titulo;
  final String cuerpo;
  final DateTime fecha;
  const Notificacion(this.usuarioId, this.tipo, this.titulo, this.cuerpo, this.fecha);
}

/// Retención ÉTICA: las notificaciones útiles (te llegó dinero) siempre pasan; las promocionales
/// tienen tope diario, horario de silencio y respeto total a la preferencia de la persona.
/// Spamear sube las métricas a corto plazo y destruye la confianza (y las desinstalaciones) a largo plazo.
class Notificador {
  static const int maxPromocionalesPorDia = 2;
  static const int silencioDesde = 22; // 10 pm
  static const int silencioHasta = 8; // 8 am

  final List<Notificacion> enviadas = [];
  final Set<String> _sinPromociones = {};

  void configurarPromociones(String usuarioId, {required bool activas}) {
    if (activas) {
      _sinPromociones.remove(usuarioId);
    } else {
      _sinPromociones.add(usuarioId);
    }
  }

  static bool enHorarioDeSilencio(DateTime t) => t.hour >= silencioDesde || t.hour < silencioHasta;

  /// Devuelve true si la notificación se envió.
  bool intentar(Notificacion n) {
    if (n.tipo == TipoNotificacion.promocional) {
      if (_sinPromociones.contains(n.usuarioId)) return false;
      if (enHorarioDeSilencio(n.fecha)) return false;
      final hoy = soloFecha(n.fecha);
      final yaEnviadas = enviadas
          .where((x) =>
              x.usuarioId == n.usuarioId &&
              x.tipo == TipoNotificacion.promocional &&
              soloFecha(x.fecha) == hoy)
          .length;
      if (yaEnviadas >= maxPromocionalesPorDia) return false;
    }
    enviadas.add(n);
    return true;
  }

  List<Notificacion> de(String usuarioId) =>
      enviadas.where((n) => n.usuarioId == usuarioId).toList().reversed.toList();

  /// Convierte hechos de la plataforma en avisos útiles.
  void conectar(BusEventos bus) {
    bus.suscribir<DineroRecibido>((e) => intentar(Notificacion(
        e.usuarioId, TipoNotificacion.transaccional, 'Te llegó dinero',
        '${e.de} te envió ${formatearPesos(e.montoCentavos)}', e.fecha)));
    bus.suscribir<ViajeFinalizado>((e) => intentar(Notificacion(
        e.usuarioId, TipoNotificacion.transaccional, 'Viaje finalizado',
        'Total: ${formatearPesos(e.montoCentavos)}', e.fecha)));
    bus.suscribir<PedidoCreado>((e) => intentar(Notificacion(
        e.usuarioId, TipoNotificacion.transaccional, 'Pedido confirmado',
        'Pedido ${e.pedidoId} por ${formatearPesos(e.totalCentavos)}', e.fecha)));
  }
}