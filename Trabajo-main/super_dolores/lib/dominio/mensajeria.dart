import 'dinero.dart';
import 'eventos.dart';
import 'excepciones.dart';
import 'monedero.dart';

enum TipoMensaje { texto, dinero, sistema }

class Mensaje {
  final String id;
  final String de; // 'sistema' para avisos de la plataforma
  final String para;
  final String texto;
  final DateTime fecha;
  final TipoMensaje tipo;
  bool leido;
  Mensaje(this.id, this.de, this.para, this.texto, this.fecha, this.tipo, {this.leido = false});
}

class ResumenConversacion {
  final String con;
  final Mensaje ultimo;
  final int noLeidos;
  const ResumenConversacion(this.con, this.ultimo, this.noLeidos);
}

class ServicioMensajes {
  static const int maxCaracteres = 1000;
  static const String sistema = 'sistema';

  final Monedero _monedero;
  final BusEventos _bus;
  final Ids _ids;
  final DateTime Function() _reloj;
  final List<Mensaje> _mensajes = [];

  ServicioMensajes(this._monedero, this._bus, this._ids, this._reloj);

  Mensaje _agregar(String de, String para, String texto, TipoMensaje tipo) {
    final m = Mensaje(_ids.siguiente('msg'), de, para, texto, _reloj(), tipo);
    _mensajes.add(m);
    return m;
  }

  String _validar(String texto) {
    final t = texto.trim();
    if (t.isEmpty) throw const MensajeInvalidoException('Escribe un mensaje.');
    if (t.length > maxCaracteres) {
      throw const MensajeInvalidoException('El mensaje es demasiado largo (máximo $maxCaracteres caracteres).');
    }
    return t;
  }

  Mensaje enviar(String de, String para, String texto) {
    if (de == para || para == sistema) throw const DestinatarioInvalidoException();
    final m = _agregar(de, para, _validar(texto), TipoMensaje.texto);
    _bus.publicar(MensajeEnviado(_ids.siguiente('ev'), de, _reloj(), para: para));
    return m;
  }

  /// Aviso automático de la plataforma (recibos, confirmaciones). No cuenta como uso del usuario.
  Mensaje enviarSistema(String para, String texto) => _agregar(sistema, para, texto, TipoMensaje.sistema);

  /// Dinero dentro del chat: la idea estrella de las superapps (mensajería + pagos).
  Mensaje enviarDinero(String de, String para, int montoCentavos, {required String clave}) {
    _monedero.transferir(de, para, montoCentavos, 'Envío por chat', clave: clave);
    final ahora = _reloj();
    _bus.publicar(PagoRealizado(_ids.siguiente('ev'), de, ahora,
        montoCentavos: montoCentavos, concepto: 'Envío por chat', origen: Servicio.pagos));
    _bus.publicar(DineroRecibido(_ids.siguiente('ev'), para, ahora, de: de, montoCentavos: montoCentavos));
    final m = _agregar(de, para, '💸 ${formatearPesos(montoCentavos)}', TipoMensaje.dinero);
    _bus.publicar(MensajeEnviado(_ids.siguiente('ev'), de, ahora, para: para));
    return m;
  }

  List<Mensaje> conversacion(String a, String b) => _mensajes
      .where((m) => (m.de == a && m.para == b) || (m.de == b && m.para == a))
      .toList();

  /// Mensajes de la plataforma dirigidos al usuario.
  List<Mensaje> deSistema(String usuario) =>
      _mensajes.where((m) => m.de == sistema && m.para == usuario).toList();

  int noLeidos(String usuario) => _mensajes.where((m) => m.para == usuario && !m.leido).length;

  void marcarLeidos(String usuario, String con) {
    for (final m in _mensajes) {
      if (m.para == usuario && m.de == con) m.leido = true;
    }
  }

  /// Lista de chats: el más reciente primero.
  List<ResumenConversacion> resumenes(String usuario) {
    final por = <String, List<Mensaje>>{};
    for (final m in _mensajes) {
      if (m.de == usuario) (por[m.para] ??= []).add(m);
      if (m.para == usuario) (por[m.de] ??= []).add(m);
    }
    final res = [
      for (final e in por.entries)
        ResumenConversacion(e.key, e.value.last, e.value.where((m) => m.para == usuario && !m.leido).length),
    ];
    res.sort((a, b) => _num(b.ultimo.id).compareTo(_num(a.ultimo.id)));
    return res;
  }

  int _num(String id) => int.parse(id.split('-').last);
}