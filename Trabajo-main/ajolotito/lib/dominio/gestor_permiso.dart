import 'almacen.dart';
import 'puerto.dart';

enum EstadoPermiso { sinPreguntar, concedido, denegado }

enum ResultadoPermiso { yaConcedido, concedido, denegado, hayQueIrAAjustes }

/// Pide el permiso UNA vez, en el momento oportuno; si dijo que no, no insiste.
class GestorPermiso {
  GestorPermiso({required this.puerto, required this.almacen});

  final PuertoNotificaciones puerto;
  final Almacen almacen;

  static const _kPregunto = 'preguntamos_permiso';

  Future<EstadoPermiso> estado() async {
    if (await puerto.notificacionesActivas()) return EstadoPermiso.concedido;
    final pregunto = await almacen.leerBool(_kPregunto) ?? false;
    return pregunto ? EstadoPermiso.denegado : EstadoPermiso.sinPreguntar;
  }

  Future<ResultadoPermiso> solicitar() async {
    switch (await estado()) {
      case EstadoPermiso.concedido:
        return ResultadoPermiso.yaConcedido;
      case EstadoPermiso.denegado:
        return ResultadoPermiso.hayQueIrAAjustes; // NO volvemos a preguntar
      case EstadoPermiso.sinPreguntar:
        final ok = await puerto.pedirPermiso();
        await almacen.guardarBool(_kPregunto, true);
        return ok ? ResultadoPermiso.concedido : ResultadoPermiso.denegado;
    }
  }

  Future<void> abrirAjustes() => puerto.abrirAjustes();
}