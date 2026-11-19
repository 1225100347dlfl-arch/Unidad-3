import 'package:ajolotito/dominio/almacen.dart';
import 'package:ajolotito/dominio/categoria.dart';
import 'package:ajolotito/dominio/payload.dart';
import 'package:ajolotito/dominio/planificador.dart';
import 'package:ajolotito/dominio/reloj.dart';
import 'package:ajolotito/dominio/servicio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'falsos.dart';

void main() {
  DateTime d(int dia, int h, [int m = 0]) => DateTime(2026, 11, dia, h, m);

  late PuertoFalso puerto;
  late RelojFalso reloj;
  late AlmacenMemoria almacen;
  late ServicioAjolote servicio;

  setUp(() {
    puerto = PuertoFalso();
    reloj = RelojFalso(d(12, 10));
    almacen = AlmacenMemoria();
    servicio = ServicioAjolote(puerto: puerto, almacen: almacen, reloj: reloj);
  });

  test('la primera vez crea al ajolote y lo guarda; la segunda lo recupera', () async {
    final a = await servicio.cargar();
    reloj.avanzar(const Duration(hours: 3));
    final b = await servicio.cargar();
    expect(b.nombre, a.nombre);
    expect(b.desde, a.desde, reason: 'no se reinicia al reabrir la app');
  });

  group('sincronizar', () {
    test('en segundo plano programa hambre, crítico y 3 sorpresas', () async {
      await servicio.alPasarAFondo();
      expect(puerto.programadas.keys.toSet(), {Ids.hambre, Ids.critico, 100, 101, 102});
      expect(puerto.programadas[Ids.hambre]!.cuando, d(12, 16));
    });

    test('sin permiso no se programa NADA y se limpia lo anterior', () async {
      await servicio.alPasarAFondo();
      expect(puerto.programadas, isNotEmpty);
      puerto.activas = false;
      await servicio.alPasarAFondo();
      expect(puerto.programadas, isEmpty);
      expect(servicio.programadas, isEmpty);
    });

    test('es idempotente: sincronizar dos veces deja lo mismo (sin duplicados)', () async {
      await servicio.alPasarAFondo();
      final antes = Map.of(puerto.programadas);
      await servicio.alPasarAFondo();
      expect(puerto.programadas.keys, antes.keys);
    });
  });

  group('alimentar reemplaza el aviso viejo (nada de notificaciones obsoletas)', () {
    test('tras comer a las 15:00, el hambre se reprograma a las 19:30 y el crítico a las 8:00', () async {
      await servicio.alPasarAFondo(); // hambre programada 16:00
      reloj.fijar(d(12, 15)); // saciedad 50
      await servicio.alVolverAlFrente();
      await servicio.alimentar(); // 50 + 35 = 85
      await servicio.alPasarAFondo();
      expect(puerto.programadas[Ids.hambre]!.cuando, d(12, 19, 30));
      expect(puerto.programadas[Ids.critico]!.cuando, d(13, 8)); // 22:00 cae en silencio
    });
  });

  group('primer plano / segundo plano', () {
    test('mirando la app NO se programa hambre, pero sí las sorpresas', () async {
      await servicio.alVolverAlFrente();
      expect(puerto.programadas.containsKey(Ids.hambre), isFalse);
      expect(puerto.programadas.containsKey(Ids.critico), isFalse);
      expect(puerto.programadas.keys.toSet(), {100, 101, 102});
    });

    test('al salir de la app vuelve a programar el hambre', () async {
      await servicio.alVolverAlFrente();
      await servicio.alPasarAFondo();
      expect(puerto.programadas.containsKey(Ids.hambre), isTrue);
    });
  });

  group('preferencias del usuario', () {
    test('apagar "hambre" quita 1 y 2, y se recuerda', () async {
      await servicio.alPasarAFondo();
      await servicio.cambiarCategoria(Categoria.hambre, false);
      expect(puerto.programadas.keys.toSet(), {100, 101, 102});
      expect((await servicio.categorias())[Categoria.hambre], isFalse);
    });

    test('apagar "sorpresas" deja solo hambre', () async {
      await servicio.alPasarAFondo();
      await servicio.cambiarCategoria(Categoria.sorpresa, false);
      expect(puerto.programadas.keys.toSet(), {Ids.hambre, Ids.critico});
    });
  });

  group('modo clase (tiempo acelerado)', () {
    test('con ritmo 600, hambre a los 6 min y crítico a los 8.5 min; ambos se conservan', () async {
      await servicio.cambiarRitmo(ServicioAjolote.ritmoClase);
      await servicio.alPasarAFondo();
      expect(puerto.programadas[Ids.hambre]!.cuando, d(12, 10, 6));
      expect(puerto.programadas[Ids.critico]!.cuando, DateTime(2026, 11, 12, 10, 8, 30));
    });
  });

  group('toques en notificaciones', () {
    test('arranque desde cerrada: el payload decide la pantalla', () async {
      puerto.lanzamiento = 'v1:alimentarYa';
      expect(await servicio.destinoDeLanzamiento(), Destino.alimentarYa);
    });
    test('sin notificación de arranque, abre en inicio', () async {
      expect(await servicio.destinoDeLanzamiento(), Destino.inicio);
    });
    test('payload corrupto, abre en inicio', () async {
      puerto.lanzamiento = '¿¿??';
      expect(await servicio.destinoDeLanzamiento(), Destino.inicio);
    });
  });

  test('probarAhora muestra una notificación inmediata', () async {
    await servicio.probarAhora();
    expect(puerto.mostradas, hasLength(1));
  });
}