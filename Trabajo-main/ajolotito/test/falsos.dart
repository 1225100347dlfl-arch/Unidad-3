import 'package:ajolotito/dominio/categoria.dart';
import 'package:ajolotito/dominio/planificador.dart';
import 'package:ajolotito/dominio/puerto.dart';

/// Doble de pruebas del plugin: programar con el mismo id REEMPLAZA.
class PuertoFalso implements PuertoNotificaciones {
  bool activas = true; // ¿hay permiso?
  bool usuarioAcepta = true; // qué responde el usuario al diálogo
  int vecesPidioPermiso = 0;
  int ajustesAbiertos = 0;
  String? lanzamiento;
  void Function(String?)? _alTocar;

  final Map<int, PlanNotificacion> programadas = {};
  final List<String> mostradas = [];

  @override
  Future<void> inicializar() async {}

  @override
  Future<bool> notificacionesActivas() async => activas;

  @override
  Future<bool> pedirPermiso() async {
    vecesPidioPermiso++;
    activas = usuarioAcepta;
    return usuarioAcepta;
  }

  @override
  Future<void> programar(PlanNotificacion plan) async => programadas[plan.id] = plan;

  @override
  Future<void> mostrarAhora({
    required int id,
    required String titulo,
    required String cuerpo,
    required Categoria categoria,
    required String payload,
  }) async =>
      mostradas.add(titulo);

  @override
  Future<void> cancelar(int id) async => programadas.remove(id);

  @override
  Future<String?> payloadDeLanzamiento() async => lanzamiento;

  @override
  void escucharToques(void Function(String? payload) alTocar) => _alTocar = alTocar;

  void simularToque(String? payload) => _alTocar?.call(payload);

  @override
  Future<void> abrirAjustes() async => ajustesAbiertos++;
}