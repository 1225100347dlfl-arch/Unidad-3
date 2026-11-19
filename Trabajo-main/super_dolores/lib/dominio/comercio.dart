import 'dinero.dart';
import 'eventos.dart';
import 'excepciones.dart';
import 'monedero.dart';

class ProductoTienda {
  final String id;
  final String nombre;
  final int precioCentavos;
  int existencias;
  ProductoTienda(this.id, this.nombre, this.precioCentavos, this.existencias);
}

class Tienda {
  final String id;
  final String nombre;
  final String emoji;
  final String duenoId; // cuenta que recibe el dinero
  final List<ProductoTienda> productos;
  Tienda(this.id, this.nombre, this.emoji, this.duenoId, this.productos);

  ProductoTienda? producto(String id) {
    for (final p in productos) {
      if (p.id == id) return p;
    }
    return null;
  }
}

class LineaPedido {
  final String productoId;
  final String nombre;
  final int cantidad;
  final int precioCentavos;
  const LineaPedido(this.productoId, this.nombre, this.cantidad, this.precioCentavos);
  int get importe => cantidad * precioCentavos;
}

class Pedido {
  final String id;
  final String usuarioId;
  final String tiendaId;
  final List<LineaPedido> lineas;
  final int totalCentavos;
  final int comisionCentavos;
  final DateTime fecha;
  const Pedido(this.id, this.usuarioId, this.tiendaId, this.lineas, this.totalCentavos, this.comisionCentavos, this.fecha);
}

/// Marketplace de negocios locales. La plataforma cobra una comisión: es su modelo de negocio.
class ServicioComercio {
  static const int comisionPct = 5;
  static const String cuentaPlataforma = 'plataforma';
  static const int maxPorProducto = 10;

  final Monedero _monedero;
  final BusEventos _bus;
  final Ids _ids;
  final DateTime Function() _reloj;
  final List<Tienda> tiendas;
  final Map<String, Pedido> _porClave = {};
  final List<Pedido> _pedidos = [];

  ServicioComercio(this._monedero, this._bus, this._ids, this._reloj, this.tiendas);

  List<Pedido> pedidosDe(String usuario) => _pedidos.where((p) => p.usuarioId == usuario).toList().reversed.toList();

  /// [items]: productoId → cantidad. Idempotente con [clave] (un doble toque no compra dos veces).
  Pedido comprar({
    required String usuarioId,
    required String tiendaId,
    required Map<String, int> items,
    required String clave,
  }) {
    final previo = _porClave['$usuarioId|$clave'];
    if (previo != null) return previo;

    final tienda = tiendas.where((t) => t.id == tiendaId).firstOrNull;
    if (tienda == null) throw const PedidoInvalidoException('La tienda no existe.');
    if (items.isEmpty) throw const PedidoInvalidoException('Tu pedido está vacío.');

    // 1) Validar TODO antes de mover dinero.
    final lineas = <LineaPedido>[];
    for (final e in items.entries) {
      final p = tienda.producto(e.key);
      if (p == null) throw const PedidoInvalidoException('Un producto ya no está disponible.');
      if (e.value <= 0 || e.value > maxPorProducto) {
        throw PedidoInvalidoException('Cantidad inválida para ${p.nombre} (1 a $maxPorProducto).');
      }
      if (p.existencias < e.value) throw ExistenciasInsuficientesException(p.nombre);
      lineas.add(LineaPedido(p.id, p.nombre, e.value, p.precioCentavos));
    }
    final total = lineas.fold<int>(0, (s, l) => s + l.importe);
    final comision = porcentaje(total, comisionPct);

    // 2) Cobrar: el comprador paga a la plataforma (custodia) y ella libera al negocio menos su comisión.
    _monedero.transferir(usuarioId, cuentaPlataforma, total, 'Pedido en ${tienda.nombre}', clave: clave);
    _monedero.transferir(cuentaPlataforma, tienda.duenoId, total - comision, 'Venta (menos comisión)',
        clave: 'liberar:$usuarioId:$clave');

    // 3) Solo con el pago confirmado se descuenta el inventario y se crea el pedido.
    for (final l in lineas) {
      tienda.producto(l.productoId)!.existencias -= l.cantidad;
    }
    final ahora = _reloj();
    final pedido = Pedido(_ids.siguiente('ped'), usuarioId, tiendaId, lineas, total, comision, ahora);
    _pedidos.add(pedido);
    _porClave['$usuarioId|$clave'] = pedido;

    _bus.publicar(PagoRealizado(_ids.siguiente('ev'), usuarioId, ahora,
        montoCentavos: total, concepto: 'Pedido en ${tienda.nombre}', origen: Servicio.comercio));
    _bus.publicar(PedidoCreado(_ids.siguiente('ev'), usuarioId, ahora, pedidoId: pedido.id, totalCentavos: total));
    _bus.publicar(DineroRecibido(_ids.siguiente('ev'), tienda.duenoId, ahora, de: usuarioId, montoCentavos: total - comision));
    return pedido;
  }
}