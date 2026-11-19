import 'package:ajolotito/dominio/payload.dart';
import 'package:ajolotito/dominio/politica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const p = PoliticaNotificaciones(); // silencio de 22:00 a 08:00
  DateTime a(int h, [int m = 0, int dia = 12]) => DateTime(2026, 11, dia, h, m);

  group('horas de silencio (cruzan la medianoche)', () {
    test('de 22 a 7:59 hay silencio', () {
      for (final h in [22, 23, 0, 3, 7]) {
        expect(p.enSilencio(a(h)), isTrue, reason: 'hora $h');
      }
    });
    test('de 8 a 21:59 no', () {
      for (final h in [8, 12, 18, 21]) {
        expect(p.enSilencio(a(h)), isFalse, reason: 'hora $h');
      }
    });
    test('justo a las 22:00 empieza y justo a las 8:00 termina', () {
      expect(p.enSilencio(a(22)), isTrue);
      expect(p.enSilencio(a(7, 59)), isTrue);
      expect(p.enSilencio(a(8)), isFalse);
    });
    test('si desde == hasta, no hay silencio', () {
      const sin = PoliticaNotificaciones(silencioDesde: 8, silencioHasta: 8);
      expect(sin.enSilencio(a(3)), isFalse);
    });
    test('también funciona un silencio dentro del mismo día (13 a 15)', () {
      const siesta = PoliticaNotificaciones(silencioDesde: 13, silencioHasta: 15);
      expect(siesta.enSilencio(a(14)), isTrue);
      expect(siesta.enSilencio(a(15)), isFalse);
    });
  });

  group('ajustar: mover al final del silencio', () {
    test('de día no cambia nada', () => expect(p.ajustar(a(12)), a(12)));
    test('a las 23:00 pasa a las 8:00 del día siguiente',
        () => expect(p.ajustar(a(23)), DateTime(2026, 11, 13, 8)));
    test('a las 03:00 pasa a las 8:00 del MISMO día',
        () => expect(p.ajustar(a(3)), a(8)));
    test('fin de mes: el 30 a las 23:00 pasa al 1 del mes siguiente',
        () => expect(p.ajustar(DateTime(2026, 11, 30, 23)), DateTime(2026, 12, 1, 8)));
  });

  group('payload', () {
    test('ida y vuelta', () {
      for (final d in Destino.values) {
        expect(PayloadNotif.decodificar(PayloadNotif(d).codificar()).destino, d);
      }
    });
    test('formato versionado', () => expect(const PayloadNotif(Destino.alimentar).codificar(), 'v1:alimentar'));
    test('basura, versión desconocida o vacío caen en inicio (nunca truena)', () {
      for (final raro in [null, '', 'hola', 'v2:alimentar', 'v1:', 'v1:borrarTodo', 'v1:alimentar:extra']) {
        expect(PayloadNotif.decodificar(raro).destino, Destino.inicio, reason: '$raro');
      }
    });
  });
}