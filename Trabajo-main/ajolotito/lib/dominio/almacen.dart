/// Persistencia mínima (clave-valor). En la app real usa SharedPreferences.
abstract class Almacen {
  Future<String?> leerTexto(String clave);
  Future<void> guardarTexto(String clave, String valor);
  Future<bool?> leerBool(String clave);
  Future<void> guardarBool(String clave, bool valor);
}

class AlmacenMemoria implements Almacen {
  final Map<String, Object> _datos = {};

  @override
  Future<String?> leerTexto(String clave) async => _datos[clave] as String?;
  @override
  Future<void> guardarTexto(String clave, String valor) async => _datos[clave] = valor;
  @override
  Future<bool?> leerBool(String clave) async => _datos[clave] as bool?;
  @override
  Future<void> guardarBool(String clave, bool valor) async => _datos[clave] = valor;
}