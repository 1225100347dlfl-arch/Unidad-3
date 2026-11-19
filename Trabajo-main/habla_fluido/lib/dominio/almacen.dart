/// Dónde se guarda el avance (JSON). En el teléfono: shared_preferences.
abstract class AlmacenAvance {
  Future<Map<String, Object?>?> cargar();
  Future<void> guardar(Map<String, Object?> datos);
}