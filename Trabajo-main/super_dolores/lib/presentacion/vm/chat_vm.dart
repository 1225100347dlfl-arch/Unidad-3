import 'package:flutter/foundation.dart';

import '../../dominio/contexto.dart';
import '../../dominio/excepciones.dart';
import '../../dominio/mensajeria.dart';

class ChatViewModel extends ChangeNotifier {
  final ContextoMiniApp _contexto;
  final VoidCallback? alCambiar;
  ChatViewModel(this._contexto, {this.alCambiar});

  String? con; // conversación abierta
  String? error;

  List<ResumenConversacion> get resumenes => _contexto.mensajes.resumenes();
  List<Mensaje> get mensajes => con == null ? [] : _contexto.mensajes.conversacion(con!);

  void abrir(String otro) {
    con = otro;
    _contexto.mensajes.marcarLeidos(otro);
    error = null;
    alCambiar?.call();
    notifyListeners();
  }

  void cerrar() {
    con = null;
    notifyListeners();
  }

  void enviar(String texto) {
    final destino = con;
    if (destino == null) return;
    try {
      _contexto.mensajes.enviar(destino, texto);
      error = null;
    } catch (e) {
      error = mensajeSeguro(e);
    }
    alCambiar?.call();
    notifyListeners();
  }

  void enviarDinero(int montoCentavos) {
    final destino = con;
    if (destino == null) return;
    try {
      _contexto.pagos.enviarDinero(destino, montoCentavos, clave: 'chat-${DateTime.now().microsecondsSinceEpoch}');
      error = null;
    } catch (e) {
      error = mensajeSeguro(e);
    }
    alCambiar?.call();
    notifyListeners();
  }
}