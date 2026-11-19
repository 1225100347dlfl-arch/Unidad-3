import 'package:ajolotito/dominio/mascota.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 11, 12, 10, 0);

  group('saciedad', () {
    test('empieza en 100 y baja 10 puntos por hora', () {
      final m = Mascota.nueva('Xólotl', t0);
      expect(m.saciedadEn(t0), 100);
      expect(m.saciedadEn(t0.add(const Duration(hours: 3))), 70);
    });
    test('nunca baja de 0', () {
      final m = Mascota.nueva('Xólotl', t0);
      expect(m.saciedadEn(t0.add(const Duration(days: 5))), 0);
    });
    test('antes del punto de partida devuelve la base (sin valores raros)', () {
      final m = Mascota.nueva('Xólotl', t0);
      expect(m.saciedadEn(t0.subtract(const Duration(hours: 2))), 100);
    });
  });

  group('humor (pruebas de frontera)', () {
    final m = Mascota.nueva('Xólotl', t0);
    Humor aLas(double h) => m.humorEn(t0.add(Duration(minutes: (h * 60).round())));

    test('feliz mientras la saciedad sea mayor a 40', () => expect(aLas(5.9), Humor.feliz));
    test('hambriento justo en 40', () => expect(aLas(6), Humor.hambriento));
    test('hambriento hasta pasar 15', () => expect(aLas(8), Humor.hambriento));
    test('famélico justo en 15', () => expect(aLas(8.5), Humor.famelico));
  });

  group('predicción: ¿cuándo tendrá hambre?', () {
    test('llega a 40 a las 6 horas y a 15 a las 8.5 horas', () {
      final m = Mascota.nueva('Xólotl', t0);
      expect(m.momentoEnQueBajaA(40), t0.add(const Duration(hours: 6)));
      expect(m.momentoEnQueBajaA(15), t0.add(const Duration(hours: 8, minutes: 30)));
    });
    test('si ya estaba por debajo, devuelve el punto de partida', () {
      final m = Mascota(nombre: 'X', saciedadBase: 30, desde: t0);
      expect(m.momentoEnQueBajaA(40), t0);
    });
    test('la predicción coincide con el cálculo de saciedad', () {
      final m = Mascota(nombre: 'X', saciedadBase: 77, desde: t0, puntosPorHora: 7);
      final cuando = m.momentoEnQueBajaA(40);
      expect(m.saciedadEn(cuando), closeTo(40, 0.001));
    });
  });

  group('alimentar', () {
    test('suma una porción (35) a lo que tenga en ese momento', () {
      final m = Mascota.nueva('X', t0);
      final seis = t0.add(const Duration(hours: 6)); // saciedad 40
      final n = m.alimentar(seis);
      expect(n.saciedadEn(seis), 75);
      expect(n.desde, seis);
    });
    test('no pasa de 100', () {
      final m = Mascota.nueva('X', t0);
      final n = m.alimentar(t0.add(const Duration(hours: 3))); // 70 + 35
      expect(n.saciedadEn(t0.add(const Duration(hours: 3))), 100);
    });
    test('con 90 o más ya no quiere comer', () {
      final m = Mascota.nueva('X', t0);
      expect(() => m.alimentar(t0), throwsA(isA<YaEstaLlena>()));
    });
  });

  test('cambiar el ritmo no produce saltos en la saciedad', () {
    final m = Mascota.nueva('X', t0);
    final t = t0.add(const Duration(hours: 2)); // 80
    final r = m.conRitmo(t, 600);
    expect(r.saciedadEn(t), 80);
    expect(r.saciedadEn(t.add(const Duration(minutes: 1))), closeTo(70, 0.001));
  });

  group('guardar y leer (JSON)', () {
    test('ida y vuelta conserva todo', () {
      final m = Mascota(nombre: 'Xólotl', saciedadBase: 63.5, desde: t0, puntosPorHora: 12);
      final r = Mascota.desdeTexto(m.aTexto())!;
      expect(r.nombre, 'Xólotl');
      expect(r.saciedadBase, 63.5);
      expect(r.desde, t0);
      expect(r.puntosPorHora, 12);
    });
    test('datos dañados o raros devuelven null, no truenan', () {
      expect(Mascota.desdeTexto(null), isNull);
      expect(Mascota.desdeTexto('esto no es json'), isNull);
      expect(Mascota.desdeTexto('[1,2,3]'), isNull);
      expect(Mascota.desdeTexto('{"nombre":"X"}'), isNull);
      expect(Mascota.desdeTexto('{"nombre":"X","saciedadBase":500,"desde":"2026-01-01T00:00:00","puntosPorHora":10}'), isNull);
      expect(Mascota.desdeTexto('{"nombre":"X","saciedadBase":50,"desde":"ayer","puntosPorHora":10}'), isNull);
      expect(Mascota.desdeTexto('{"nombre":"X","saciedadBase":50,"desde":"2026-01-01T00:00:00","puntosPorHora":0}'), isNull);
    });
  });
}