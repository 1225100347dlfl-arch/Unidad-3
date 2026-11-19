import 'package:shared_preferences/shared_preferences.dart';

import '../dominio/almacen.dart';

class AlmacenPrefs implements Almacen {
  AlmacenPrefs(this._p);
  final SharedPreferences _p;

  @override
  Future<String?> leerTexto(String clave) async => _p.getString(clave);
  @override
  Future<void> guardarTexto(String clave, String valor) => _p.setString(clave, valor);
  @override
  Future<bool?> leerBool(String clave) async => _p.getBool(clave);
  @override
  Future<void> guardarBool(String clave, bool valor) => _p.setBool(clave, valor);
}