import 'package:ajolotito/dominio/categoria.dart';
import 'package:ajolotito/dominio/mascota.dart';
import 'package:ajolotito/dominio/planificador.dart';
import 'package:ajolotito/dominio/politica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime d(int dia, int h, [int m = 0]) => DateTime(2026, 11, dia, h, m);
  const plani = Planificador();

  test('día normal: hambre 16:00, sorpresa 18:00, crítico 18:30 y sorpresas de los días siguientes', () {
    final ahora = d(12, 10);
    final plan = plani.planear(Mascota.nueva('Xólotl', ahora), ahora);
    expect(plan.map((p) => (p.id, p.cuando)).toList(), [
      (Ids.hambre, d(12, 16)),
      (Ids.sorpresa(0), d(12, 18)),
      (Ids.critico, d(12, 18, 30)),
      (Ids.sorpresa(1), d(13, 18)),
      (Ids.sorpresa(2), d(14, 18)),
    ]);
  });

  test('cada notificación lleva su payload y textos con el nombre', () {
    final ahora = d(12, 10);
    final plan = plani.planear(Mascota.nueva('Xólotl', ahora), ahora);
    final hambre = plan.firstWhere((p) => p.id == Ids.hambre);
    final juego = plan.firstWhere((p) => p.id == Ids.sorpresa(0));
    expect(hambre.payload, 'v1:alimentar');
    expect(juego.payload, 'v1:jugar');
    expect(hambre.titulo.isNotEmpty && hambre.cuerpo.isNotEmpty, isTrue);
  });

  group('horas de silencio', () {
    test('el aviso crítico de las 23:30 se pospone a las 8:00 del día siguiente', () {
      final ahora = d(12, 15);
      final plan = plani.planear(Mascota.nueva('X', ahora), ahora);
      expect(plan.firstWhere((p) => p.id == Ids.hambre).cuando, d(12, 21));
      expect(plan.firstWhere((p) => p.id == Ids.critico).cuando, d(13, 8));
    });

    test('si hambre y crítico caerían juntos al terminar el silencio, solo queda el crítico', () {
      final ahora = d(12, 17); // hambre 23:00, crítico 01:30 -> ambos 8:00
      final plan = plani.planear(Mascota.nueva('X', ahora), ahora);
      expect(plan.any((p) => p.id == Ids.hambre), isFalse);
      expect(plan.firstWhere((p) => p.id == Ids.critico).cuando, d(13, 8));
    });

    test('ninguna notificación cae en horas de silencio', () {
      for (var h = 0; h < 24; h++) {
        final ahora = d(12, h, 17);
        for (final p in plani.planear(Mascota.nueva('X', ahora), ahora)) {
          expect(plani.politica.enSilencio(p.cuando), isFalse, reason: 'ahora=$h:17 -> ${p.id} ${p.cuando}');
        }
      }
    });
  });

  group('no avisar de lo que ya pasó', () {
    test('si ya tiene hambre, solo se programa el crítico', () {
      final ahora = d(12, 10);
      final m = Mascota(nombre: 'X', saciedadBase: 30, desde: ahora);
      final plan = plani.planear(m, ahora);
      expect(plan.where((p) => p.esDeHambre).map((p) => p.id), [Ids.critico]);
      expect(plan.firstWhere((p) => p.id == Ids.critico).cuando, d(12, 11, 30));
    });
    test('si ya es famélico, no se programa nada de hambre', () {
      final ahora = d(12, 10);
      final m = Mascota(nombre: 'X', saciedadBase: 10, desde: ahora);
      expect(plani.planear(m, ahora).where((p) => p.esDeHambre), isEmpty);
    });
    test('pasadas las 18:00, la primera sorpresa es mañana', () {
      final ahora = d(12, 19);
      final m = Mascota.nueva('X', ahora);
      final s = plani.planear(m, ahora).where((p) => p.categoria == Categoria.sorpresa).toList();
      expect(s.map((p) => p.cuando), [d(13, 18), d(14, 18), d(15, 18)]);
    });
  });

  group('categorías apagadas por el usuario', () {
    test('sin hambre: solo sorpresas', () {
      const sinHambre = Planificador(politica: PoliticaNotificaciones(activas: {Categoria.sorpresa}));
      final ahora = d(12, 10);
      final plan = sinHambre.planear(Mascota.nueva('X', ahora), ahora);
      expect(plan.every((p) => p.categoria == Categoria.sorpresa), isTrue);
      expect(plan, hasLength(3));
    });
    test('sin sorpresas: solo hambre', () {
      const sinSorp = Planificador(politica: PoliticaNotificaciones(activas: {Categoria.hambre}));
      final ahora = d(12, 10);
      final plan = sinSorp.planear(Mascota.nueva('X', ahora), ahora);
      expect(plan.map((p) => p.id), [Ids.hambre, Ids.critico]);
    });
    test('todo apagado: lista vacía', () {
      const nada = Planificador(politica: PoliticaNotificaciones(activas: {}));
      final ahora = d(12, 10);
      expect(nada.planear(Mascota.nueva('X', ahora), ahora), isEmpty);
    });
  });

  test('tope diario: con máximo 2, se sacrifica la sorpresa (la menos importante)', () {
    const tope2 = Planificador(politica: PoliticaNotificaciones(maxPorDia: 2));
    final ahora = d(12, 10);
    final plan = tope2.planear(Mascota.nueva('X', ahora), ahora);
    final hoy = plan.where((p) => p.cuando.day == 12).map((p) => p.id).toList();
    expect(hoy, [Ids.hambre, Ids.critico]);
    expect(plan, hasLength(4));
  });

  test('los ids son únicos (así programar reemplaza en vez de duplicar)', () {
    final ahora = d(12, 10);
    final ids = plani.planear(Mascota.nueva('X', ahora), ahora).map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids.every(Ids.todos.contains), isTrue);
  });
}