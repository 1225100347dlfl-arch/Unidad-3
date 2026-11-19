enum Destino { inicio, alimentar, alimentarYa, jugar }

/// Lo que viaja DENTRO de la notificación. Tiene versión ("v1") y se
/// decodifica con desconfianza: si algo raro llega, la app abre en el inicio.
class PayloadNotif {
  const PayloadNotif(this.destino);
  final Destino destino;

  String codificar() => 'v1:${destino.name}';

  static PayloadNotif decodificar(String? crudo) {
    const defecto = PayloadNotif(Destino.inicio);
    if (crudo == null) return defecto;
    final partes = crudo.split(':');
    if (partes.length != 2 || partes[0] != 'v1') return defecto;
    for (final d in Destino.values) {
      if (d.name == partes[1]) return PayloadNotif(d);
    }
    return defecto;
  }
}