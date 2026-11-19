import 'package:flutter/foundation.dart';

import '../../dominio/eventos.dart';
import '../../dominio/lealtad.dart';
import '../../dominio/mini_app.dart';
import '../../dominio/plataforma.dart';
import '../../dominio/sugerencias.dart';
import '../../dominio/dinero.dart';

/// Pantalla de inicio: el "tablero" que da UTILIDAD diaria (saldo, mensajes, puntos, sugerencia)
/// y pone todos los servicios a un toque.
class InicioViewModel extends ChangeNotifier {
  final Plataforma plataforma;
  String usuarioId;
  InicioViewModel(this.plataforma, this.usuarioId);

  void cambiarUsuario(String id) {
    usuarioId = id;
    notificar();
  }

  void notificar() => notifyListeners();

  int get saldo => plataforma.monedero.saldo(usuarioId);
  int get puntos => plataforma.lealtad.puntos(usuarioId);
  int get racha => plataforma.lealtad.racha(usuarioId);
  NivelLealtad get nivel => plataforma.lealtad.nivel(usuarioId);
  int get noLeidos => plataforma.mensajes.noLeidos(usuarioId);
  List<MiniApp> get miniApps => plataforma.registro.activas;

  Sugerencia get sugerencia {
    final usos = <Servicio, int>{};
    final hoy = soloFecha(plataforma.reloj());
    final desde = masDias(hoy, -29);
    for (final r in plataforma.analitica.registros) {
      final d = soloFecha(r.fecha);
      if (r.usuarioId == usuarioId && !d.isBefore(desde) && !d.isAfter(hoy)) {
        usos[r.servicio] = (usos[r.servicio] ?? 0) + 1;
      }
    }
    return sugerirServicio(usosUltimos30Dias: usos, ahora: plataforma.reloj());
  }

  /// Canjea todos los puntos canjeables (múltiplos de 100).
  int canjearTodo() {
    final canjeables = puntos ~/ Lealtad.puntosPorCanje * Lealtad.puntosPorCanje;
    if (canjeables == 0) return 0;
    final c = plataforma.lealtad.canjear(usuarioId, canjeables);
    notificar();
    return c;
  }
}