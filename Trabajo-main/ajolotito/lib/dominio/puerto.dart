import 'categoria.dart';
import 'planificador.dart';

/// La "puerta" hacia el sistema de notificaciones. El plugin real vive en lib/infra/puerto_real.dart.
abstract class PuertoNotificaciones {
  Future<void> inicializar();

  /// ¿Puede la app mostrar notificaciones AHORA? (permiso + ajustes del sistema)
  Future<bool> notificacionesActivas();

  /// Muestra el diálogo del sistema. Devuelve si el usuario aceptó.
  Future<bool> pedirPermiso();

  Future<void> programar(PlanNotificacion plan);

  Future<void> mostrarAhora({
    required int id,
    required String titulo,
    required String cuerpo,
    required Categoria categoria,
    required String payload,
  });

  Future<void> cancelar(int id);

  /// Payload de la notificación que ABRIÓ la app desde cerrada (o null).
  Future<String?> payloadDeLanzamiento();

  /// Se llama cuando el usuario toca una notificación con la app ya viva.
  void escucharToques(void Function(String? payload) alTocar);

  Future<void> abrirAjustes();
}