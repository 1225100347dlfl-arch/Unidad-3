import 'package:flutter/foundation.dart';

import '../../dominio/contexto.dart';
import '../../dominio/excepciones.dart';
import '../../dominio/monedero.dart';

class MonederoViewModel extends ChangeNotifier {
  final ContextoMiniApp _contexto;
  final VoidCallback? alCambiar;
  MonederoViewModel(this._contexto, {this.alCambiar});

  String? error;
  String? exito;
  bool ocupado = false;
  int _n = 0;

  int get saldo => _contexto.monedero.saldo();
  List<Movimiento> get movimientos => _contexto.monedero.movimientos();

  /// Una clave NUEVA por intento de usuario; si hay un reintento automático, se reusa la misma.
  String _clave() => 'mon-${_contexto.usuarioId}-${DateTime.now().microsecondsSinceEpoch}-${_n++}';

  Future<void> enviarDinero(String para, int montoCentavos) async {
    if (ocupado) return;
    ocupado = true;
    error = null;
    exito = null;
    notifyListeners();
    try {
      _contexto.pagos.enviarDinero(para, montoCentavos, clave: _clave());
      exito = 'Dinero enviado.';
      alCambiar?.call();
    } catch (e) {
      error = mensajeSeguro(e);
    }
    ocupado = false;
    notifyListeners();
  }
}