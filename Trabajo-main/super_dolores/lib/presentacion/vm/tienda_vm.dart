import 'package:flutter/foundation.dart';

import '../../dominio/comercio.dart';
import '../../dominio/contexto.dart';
import '../../dominio/excepciones.dart';

class TiendaViewModel extends ChangeNotifier {
  final ContextoMiniApp _contexto;
  final VoidCallback? alCambiar;
  TiendaViewModel(this._contexto, {this.alCambiar});

  Tienda? tienda;
  final Map<String, int> carrito = {};
  String? error;
  Pedido? ultimoPedido;
  bool ocupado = false;
  String? _claveActual; // la misma clave mientras el pedido no cambie ni se confirme

  List<Tienda> get tiendas => _contexto.comercio.tiendas();

  void elegirTienda(Tienda t) {
    tienda = t;
    carrito.clear();
    _claveActual = null;
    ultimoPedido = null;
    notifyListeners();
  }

  void volver() {
    tienda = null;
    carrito.clear();
    _claveActual = null;
    notifyListeners();
  }

  int get total {
    final t = tienda;
    if (t == null) return 0;
    var s = 0;
    carrito.forEach((id, n) => s += (t.producto(id)?.precioCentavos ?? 0) * n);
    return s;
  }

  void cambiar(String productoId, int delta) {
    final nuevo = (carrito[productoId] ?? 0) + delta;
    if (nuevo <= 0) {
      carrito.remove(productoId);
    } else {
      carrito[productoId] = nuevo;
    }
    _claveActual = null; // un pedido distinto es una operación distinta
    notifyListeners();
  }

  Future<void> comprar() async {
    if (ocupado || tienda == null) return;
    ocupado = true;
    error = null;
    notifyListeners();
    _claveActual ??= 'pedido-${DateTime.now().microsecondsSinceEpoch}';
    try {
      ultimoPedido = _contexto.comercio.comprar(tienda!.id, Map.of(carrito), clave: _claveActual!);
      carrito.clear();
      _claveActual = null;
      alCambiar?.call();
    } catch (e) {
      error = mensajeSeguro(e);
    }
    ocupado = false;
    notifyListeners();
  }
}