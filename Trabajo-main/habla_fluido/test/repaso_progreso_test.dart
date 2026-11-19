import 'package:flutter_test/flutter_test.dart';
import 'package:habla_fluido/dominio/nivel.dart';
import 'package:habla_fluido/dominio/plan_diario.dart';
import 'package:habla_fluido/dominio/progreso.dart';
import 'package:habla_fluido/dominio/repaso.dart';
import 'package:habla_fluido/dominio/reglas.dart';

final d1 = DateTime(2026, 11, 5, 14, 30);

void main() {
  group('SM-2', () {
    test('secuencia 4, 5, 5, 2', () {
      var t = TarjetaRepaso(id: 'a', frase: 'x', traduccion: 'y', proxima: d1);
      t = t.calificar(4, d1);
      expect((t.repeticiones, t.intervaloDias), (1, 1));
      expect(t.facilidad, closeTo(2.5, 1e-9));
      t = t.calificar(5, d1);
      expect((t.repeticiones, t.intervaloDias), (2, 6));
      expect(t.facilidad, closeTo(2.6, 1e-9));
      t = t.calificar(5, d1);
      expect((t.repeticiones, t.intervaloDias), (3, 16)); // 6 × 2.6 = 15.6 → 16
      expect(t.facilidad, closeTo(2.7, 1e-9));
      t = t.calificar(2, d1); // fallo: vuelve a empezar
      expect((t.repeticiones, t.intervaloDias), (0, 1));
      expect(t.facilidad, closeTo(2.38, 1e-9));
    });
    test('la facilidad nunca baja de 1.3', () {
      var t = TarjetaRepaso(id: 'a', frase: 'x', traduccion: 'y', proxima: d1);
      for (var i = 0; i < 30; i++) {
        t = t.calificar(0, d1);
      }
      expect(t.facilidad, 1.3);
    });
    test('la próxima fecha se cuenta en días completos', () {
      final t = TarjetaRepaso(id: 'a', frase: 'x', traduccion: 'y', proxima: d1).calificar(5, d1);
      expect(t.proxima, DateTime(2026, 11, 6));
    });
    test('vencida si la fecha llegó (sin importar la hora)', () {

      final t = TarjetaRepaso(id: 'a', frase: 'x', traduccion: 'y', proxima: DateTime(2026, 11, 6));
      expect(t.estaVencida(DateTime(2026, 11, 5, 23, 59)), isFalse);
      expect(t.estaVencida(DateTime(2026, 11, 6, 0, 1)), isTrue);
    });
    test('calidad fuera de rango lanza', () {

      expect(() => TarjetaRepaso(id: 'a', frase: 'x', traduccion: 'y', proxima: d1).calificar(6, d1),
          throwsArgumentError);
    });
    test('calidadDesdePuntaje', () {
      expect([1.0, 0.9, 0.75, 0.6, 0.4, 0.1].map(calidadDesdePuntaje), [5, 4, 3, 2, 1, 0]);
    });
    test('JSON de ida y vuelta y dato dañado', () {

      final t = TarjetaRepaso(id: 'a', frase: 'x', traduccion: 'y', proxima: d1).calificar(5, d1);
      final r = TarjetaRepaso.desdeJson(t.aJson())!;
      expect((r.id, r.intervaloDias, r.facilidad), ('a', 1, t.facilidad));
      expect(TarjetaRepaso.desdeJson({'id': 3}), isNull);
      expect(TarjetaRepaso.desdeJson('basura'), isNull);
    });
    test('mazo: registra, programa y lista pendientes', () {
      final m = MazoRepaso();
      m.registrar(id: 'a', frase: 'x', traduccion: 'y', puntaje: 0.2, hoy: d1);
      m.registrar(id: 'b', frase: 'x2', traduccion: 'y2', puntaje: 1.0, hoy: d1);
      expect(m.todas.length, 2);
      expect(m.pendientes(d1), isEmpty); // ambas quedan para mañana
      expect(m.pendientes(DateTime(2026, 11, 6)).length, 2);
      m.calificar('a', 5, DateTime(2026, 11, 6));
      expect(m.pendientes(DateTime(2026, 11, 6)).length, 1);
    });
  });

  group('Progreso', () {
    test('EMA: el primer intento fija el valor; luego pesa 30%', () {
      final p = Progreso();
      p.registrar(Habilidad.escucha, 1.0, d1);
      expect(p.dominioDe(Habilidad.escucha), 1.0);
      p.registrar(Habilidad.escucha, 0.0, d1);
      expect(p.dominioDe(Habilidad.escucha), closeTo(0.7, 1e-9));
      expect(p.de(Habilidad.escucha)!.intentos, 2);
    });

    test('habilidad sin datos vale 0.5', () => expect(Progreso().dominioDe(Habilidad.lectura), Reglas.dominioSinEvaluar));
    test('puntaje fuera de rango se recorta', () {
      final p = Progreso()..registrar(Habilidad.lectura, 7, d1);
      expect(p.dominioDe(Habilidad.lectura), 1.0);
    });
    test('racha: mismo día, día siguiente y día perdido', () {
      final p = Progreso();
      p.registrar(Habilidad.escucha, 1, DateTime(2026, 11, 5, 8));
      expect(p.racha, 1);
      p.registrar(Habilidad.escucha, 1, DateTime(2026, 11, 5, 21));
      expect(p.racha, 1);
      p.registrar(Habilidad.escucha, 1, DateTime(2026, 11, 6));
      expect(p.racha, 2);
      p.registrar(Habilidad.escucha, 1, DateTime(2026, 11, 9));
      expect(p.racha, 1);
    });
    test('la habilidad más débil', () {
      final p = Progreso();

      for (final h in [Habilidad.escucha, Habilidad.pronunciacion, Habilidad.lectura, Habilidad.conversacion]) {
        p.registrar(h, 0.9, d1);
      }
      expect(p.masDebil, Habilidad.escritura); // sin evaluar = 0.5 < 0.9
    });
    test('subir de nivel exige dominio e intentos en TODAS las habilidades y reinicia', () {
      final p = Progreso();
      for (final h in Habilidad.values) {
        for (var i = 0; i < Reglas.intentosParaSubir; i++) {
          p.registrar(h, 1.0, d1);
        }
      }
      expect(p.puedeSubirDeNivel, isTrue);
      expect(p.subirDeNivel(), isTrue);
      expect(p.nivel, NivelCefr.a2);
      expect(p.de(Habilidad.escucha), isNull);
      expect(p.puedeSubirDeNivel, isFalse);
    });
    test('con una habilidad floja no sube', () {
      final p = Progreso();
      for (final h in Habilidad.values) {
        for (var i = 0; i < 5; i++) {
          p.registrar(h, h == Habilidad.escritura ? 0.4 : 1.0, d1);
        }
      }
      expect(p.puedeSubirDeNivel, isFalse);
      expect(p.subirDeNivel(), isFalse);
    });
    test('JSON de ida y vuelta', () {
      final p = Progreso(nivel: NivelCefr.b1)..registrar(Habilidad.lectura, 0.6, d1);
      final r = Progreso.desdeJson(p.aJson());
      expect(r.nivel, NivelCefr.b1);
      expect(r.dominioDe(Habilidad.lectura), closeTo(0.6, 1e-9));
      expect(r.racha, 1);
      expect(Progreso.desdeJson('basura').nivel, NivelCefr.a1);
    });
  });

  group('plan diario', () {
    Progreso con(Habilidad debil) {
      final p = Progreso();
      for (final h in Habilidad.values) {
        p.registrar(h, h == debil ? 0.3 : 0.9, d1);
      }
      return p;
    }

    test('suma exactamente los minutos pedidos', () {
      for (final total in [5, 10, 17, 20, 33]) {
        final plan = generarPlan(con(Habilidad.lectura), minutosTotales: total);
        expect(plan.fold<int>(0, (a, b) => a + b.minutos), total, reason: '$total min');
      }
    });
    test('reparto concreto con escritura débil (20 min)', () {
      final plan = generarPlan(con(Habilidad.escritura));
      expect(plan.map((b) => b.minutos).toList(), [4, 4, 3, 5, 4]);
      expect(plan.where((b) => b.esRefuerzo).single.habilidad, Habilidad.escritura);
    });
    test('la habilidad débil recibe más tiempo que con su peso base', () {
      final plan = generarPlan(con(Habilidad.pronunciacion));
      final pron = plan.firstWhere((b) => b.habilidad == Habilidad.pronunciacion).minutos;
      expect(pron, 6);
    });
    test('toda habilidad recibe al menos 1 minuto en una sesión de 10', () {
      final plan = generarPlan(con(Habilidad.lectura), minutosTotales: 10);
      expect(plan.every((b) => b.minutos >= 1), isTrue);
    });
  });
}