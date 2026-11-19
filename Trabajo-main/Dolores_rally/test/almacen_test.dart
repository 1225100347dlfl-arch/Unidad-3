import 'package:dolores_rally/datos/almacen_prefs.dart';
import 'package:dolores_rally/dominio/almacen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AlmacenMemoria (contrato)', () {
    test('empieza vacío', () async {
      final a = AlmacenMemoria();
      expect(await a.cargarCapturados(), isEmpty);
      expect(await a.cargarMejorPuntaje(), 0);
    });

    test('guarda y recupera ids y puntaje', () async {
      final a = AlmacenMemoria();
      await a.guardarCapturados({'hidalgo', 'leona'});
      await a.guardarMejorPuntaje(350);
      expect(await a.cargarCapturados(), {'hidalgo', 'leona'});
      expect(await a.cargarMejorPuntaje(), 350);
    });

    test('devuelve una copia: modificarla no altera lo guardado', () async {
      final a = AlmacenMemoria();
      await a.guardarCapturados({'hidalgo'});
      (await a.cargarCapturados()).add('intruso');
      expect(await a.cargarCapturados(), {'hidalgo'});
    });
  });

  group('AlmacenPrefs (shared_preferences simulado)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('empieza vacío', () async {
      final a = AlmacenPrefs();
      expect(await a.cargarCapturados(), isEmpty);
      expect(await a.cargarMejorPuntaje(), 0);
    });

    test('lo guardado sobrevive a una instancia nueva (como cerrar la app)', () async {
      await AlmacenPrefs().guardarCapturados({'allende', 'josefa'});
      await AlmacenPrefs().guardarMejorPuntaje(225);
      final otra = AlmacenPrefs();
      expect(await otra.cargarCapturados(), {'allende', 'josefa'});
      expect(await otra.cargarMejorPuntaje(), 225);
    });
  });
}
