import 'package:flutter_test/flutter_test.dart';
import 'package:super_dolores/dominio/analitica.dart';
import 'package:super_dolores/dominio/eventos.dart';
import 'package:super_dolores/dominio/excepciones.dart';
import 'package:super_dolores/dominio/lealtad.dart';
import 'package:super_dolores/dominio/monedero.dart';
import 'package:super_dolores/dominio/notificaciones.dart';
import 'package:super_dolores/dominio/sugerencias.dart';

final lunes = DateTime(2026, 11, 9, 10);
DateTime dia(int n, [int h = 10]) => DateTime(2026, 11, 9 + n, h);

int _n = 0;
String id() => 'e${++_n}';

EventoApp compra(DateTime f, int total, {String u = 'u1'}) =>
    PedidoCreado(id(), u, f, pedidoId: 'p', totalCentavos: total);
EventoApp viaje(DateTime f, int monto, {String u = 'u1'}) =>
    ViajeFinalizado(id(), u, f, viajeId: 'v', montoCentavos: monto);
EventoApp mensaje(DateTime f, {String u = 'u1'}) => MensajeEnviado(id(), u, f, para: 'x');
EventoApp pago(DateTime f, {String u = 'u1'}) =>
    PagoRealizado(id(), u, f, montoCentavos: 100, concepto: 'x', origen: Servicio.pagos);

Lealtad nueva() {
  final m = Monedero()..abrirCuenta('u1');
  return Lealtad(m);
}

void main() {
  group('Lealtad: puntos por gasto', () {
    test('1 punto por cada \$10 en compras y viajes', () {
      final l = nueva()
        ..alEvento(compra(lunes, 5600))
        ..alEvento(viaje(lunes, 8300));
      expect(l.puntos('u1'), 5 + 8);
    });
    test('un evento repetido NO premia dos veces (idempotencia por id)', () {
      final l = nueva();
      final e = compra(lunes, 10000);
      l.alEvento(e);
      l.alEvento(e);
      expect(l.puntos('u1'), 10);
    });
    test('mensajes y pagos entre personas no dan puntos por gasto', () {
      final l = nueva()
        ..alEvento(mensaje(lunes))
        ..alEvento(pago(lunes));
      expect(l.puntos('u1'), 0 + 50); // solo el bono de 2 servicios distintos
    });
    test('recibir dinero es pasivo: ni puntos ni racha', () {
      final l = nueva()..alEvento(DineroRecibido(id(), 'u1', lunes, de: 'x', montoCentavos: 999999));
      expect(l.puntos('u1'), 0);
      expect(l.racha('u1'), 0);
    });
  });

  group('Lealtad: niveles', () {
    test('Bronce → Plata en 500 y → Oro en 2000', () {
      final l = nueva()..alEvento(compra(lunes, 499000));
      expect(l.puntos('u1'), 499);
      expect(l.nivel('u1'), NivelLealtad.bronce);
      l.alEvento(compra(lunes, 1000));
      expect(l.puntos('u1'), 500);
      expect(l.nivel('u1'), NivelLealtad.plata);
      l.alEvento(compra(lunes, 1500000));
      expect(l.nivel('u1'), NivelLealtad.oro);
    });
    test('Plata gana 125% de puntos por gasto', () {
      final l = nueva()..alEvento(compra(lunes, 500000)); // 500 pts → Plata
      l.alEvento(compra(lunes, 10000)); // base 10 × 125% = 12
      expect(l.puntos('u1'), 512);
    });
  });

  group('Lealtad: bono semanal por variedad de servicios', () {
    test('2 → +50, 3 → +100, 4 → +200 (una vez por escalón y por semana)', () {
      final l = nueva()
        ..alEvento(mensaje(dia(0)))
        ..alEvento(compra(dia(1), 1000)) // 1 pt + 50
        ..alEvento(viaje(dia(2), 1000)) // 1 pt + 100
        ..alEvento(pago(dia(3))); // +200
      expect(l.puntos('u1'), 1 + 50 + 1 + 100 + 200);
    });
    test('repetir el mismo servicio no vuelve a dar bono', () {
      final l = nueva()
        ..alEvento(mensaje(dia(0)))
        ..alEvento(pago(dia(0)))
        ..alEvento(mensaje(dia(1)))
        ..alEvento(pago(dia(1)));
      expect(l.puntos('u1'), 50);
    });
    test('la semana siguiente el bono se puede ganar de nuevo', () {
      final l = nueva()
        ..alEvento(mensaje(dia(0)))
        ..alEvento(pago(dia(1))) // semana 1: +50
        ..alEvento(mensaje(dia(7)))
        ..alEvento(pago(dia(8))); // semana 2: +50
      expect(l.puntos('u1'), 100);
    });
    test('domingo y lunes siguiente son semanas distintas', () {
      final l = nueva()
        ..alEvento(mensaje(dia(6))) // domingo
        ..alEvento(pago(dia(7))); // lunes de la semana siguiente
      expect(l.puntos('u1'), 0);
    });
  });

  group('Lealtad: racha', () {
    test('7 días seguidos dan +70', () {
      final l = nueva();
      for (var d = 0; d < 7; d++) {
        l.alEvento(mensaje(dia(d)));
      }
      expect(l.racha('u1'), 7);
      expect(l.puntos('u1'), 70);
    });
    test('varios eventos el mismo día no inflan la racha', () {
      final l = nueva()
        ..alEvento(mensaje(dia(0, 8)))
        ..alEvento(mensaje(dia(0, 20)));
      expect(l.racha('u1'), 1);
    });
    test('saltarse un día reinicia la racha a 1', () {
      final l = nueva()
        ..alEvento(mensaje(dia(0)))
        ..alEvento(mensaje(dia(1)))
        ..alEvento(mensaje(dia(3)));
      expect(l.racha('u1'), 1);
    });
    test('un evento atrasado (día anterior) no rompe la racha', () {
      final l = nueva()
        ..alEvento(mensaje(dia(1)))
        ..alEvento(mensaje(dia(0)));
      expect(l.racha('u1'), 1);
    });
  });

  group('Lealtad: canje', () {
    test('100 puntos = \$10 de saldo', () {
      final m = Monedero()..abrirCuenta('u1');
      final l = Lealtad(m)..alEvento(compra(lunes, 300000)); // 300 pts
      final c = l.canjear('u1', 200);
      expect(c, 2000);
      expect(m.saldo('u1'), 2000);
      expect(l.puntos('u1'), 100);
    });
    test('solo múltiplos de 100 y sin pasarse de los puntos', () {
      final l = nueva()..alEvento(compra(lunes, 300000));
      expect(() => l.canjear('u1', 250), throwsA(isA<CanjeInvalidoException>()));
      expect(() => l.canjear('u1', 0), throwsA(isA<CanjeInvalidoException>()));
      expect(() => l.canjear('u1', 400), throwsA(isA<CanjeInvalidoException>()));
      expect(l.puntos('u1'), 300);
    });
  });

  group('Analítica de retención (datos hechos a mano, verificados con un cálculo independiente)', () {
    final a = Analitica();
    void r(String u, Servicio s, int d) => a.agregar(RegistroUso(u, s, DateTime(2026, 11, d, 12)));
    setUpAll(() {
      r('A', Servicio.mensajeria, 1);
      r('A', Servicio.comercio, 2);
      r('A', Servicio.mensajeria, 8);
      r('B', Servicio.pagos, 1);
      r('C', Servicio.transporte, 1);
      r('C', Servicio.transporte, 2);
      r('D', Servicio.mensajeria, 2);
      r('D', Servicio.pagos, 9);
      r('E', Servicio.comercio, 2);
    });
    DateTime nov(int d) => DateTime(2026, 11, d);

    test('DAU, WAU y MAU', () {
      expect(a.dau(nov(2)), 4);
      expect(a.wau(nov(2)), 5);
      expect(a.mau(nov(2)), 5);
      expect(a.dau(nov(8)), 1);
      expect(a.wau(nov(8)), 4); // B ya salió de la ventana de 7 días
      expect(a.mau(nov(8)), 5);
    });
    test('stickiness = DAU / MAU', () {
      expect(a.stickiness(nov(2)), closeTo(0.8, 1e-9));
      expect(a.stickiness(nov(8)), closeTo(0.2, 1e-9));
      expect(Analitica().stickiness(nov(1)), 0);
    });
    test('cohortes: quién llegó por primera vez cada día', () {
      expect(a.cohorte(nov(1)), {'A', 'B', 'C'});
      expect(a.cohorte(nov(2)), {'D', 'E'});
      expect(a.primerDia('D'), nov(2));
      expect(a.primerDia('nadie'), isNull);
    });
    test('retención D1 y D7 por cohorte', () {
      expect(a.retencion(nov(1), 1), closeTo(2 / 3, 1e-9)); // A y C volvieron el día 2
      expect(a.retencion(nov(1), 7), closeTo(1 / 3, 1e-9)); // solo A el día 8
      expect(a.retencion(nov(2), 7), closeTo(1 / 2, 1e-9)); // D el día 9
      expect(a.retencion(nov(2), 1), 0);
      expect(a.retencion(nov(20), 1), 0); // cohorte vacía: sin dividir entre cero
    });
    test('servicios por usuario y % multiservicio', () {
      expect(a.serviciosPorUsuario(nov(1), nov(9)), closeTo(1.4, 1e-9));
      expect(a.porcentajeMultiservicio(nov(1), nov(9)), closeTo(0.4, 1e-9));
      expect(a.porcentajeMultiservicio(nov(1), nov(9), minimo: 1), 1.0);
    });
    test('semana 2 según servicios usados en la semana 1 (correlación, no causa)', () {
      final c = a.retencionSemana2PorServicios(nov(1), nov(2));
      expect(c.nUno, 4);
      expect(c.unServicio, closeTo(0.25, 1e-9));
      expect(c.nMulti, 1);
      expect(c.multiservicio, 1.0);
    });
    test('el registro de eventos ignora lo pasivo', () {
      final bus = BusEventos();
      final b = Analitica()..conectar(bus);
      bus.publicar(DineroRecibido('e1', 'u', DateTime(2026, 11, 1), de: 'x', montoCentavos: 1));
      bus.publicar(MensajeEnviado('e2', 'u', DateTime(2026, 11, 1), para: 'x'));
      expect(b.registros.length, 1);
    });
  });

  group('Notificaciones éticas', () {
    Notificacion promo(DateTime f, {String u = 'u1'}) =>
        Notificacion(u, TipoNotificacion.promocional, 'Oferta', '...', f);
    Notificacion trans(DateTime f) => Notificacion('u1', TipoNotificacion.transaccional, 'Aviso', '...', f);

    test('tope de 2 promociones al día y se renueva al siguiente', () {
      final n = Notificador();
      expect(n.intentar(promo(dia(0, 9))), isTrue);
      expect(n.intentar(promo(dia(0, 12))), isTrue);
      expect(n.intentar(promo(dia(0, 15))), isFalse);
      expect(n.intentar(promo(dia(1, 9))), isTrue);
    });
    test('horario de silencio de 10 pm a 8 am para promociones', () {
      final n = Notificador();
      expect(n.intentar(promo(dia(0, 22))), isFalse);
      expect(n.intentar(promo(dia(0, 23))), isFalse);
      expect(n.intentar(promo(dia(0, 7))), isFalse);
      expect(n.intentar(promo(dia(0, 8))), isTrue);
      expect(n.intentar(promo(dia(0, 21))), isTrue);
    });
    test('las transaccionales (te llegó dinero) pasan siempre', () {
      final n = Notificador();
      for (var i = 0; i < 5; i++) {
        expect(n.intentar(trans(dia(0, 3))), isTrue);
      }
    });
    test('quien desactiva las promociones no recibe ninguna', () {
      final n = Notificador()..configurarPromociones('u1', activas: false);
      expect(n.intentar(promo(dia(0, 12))), isFalse);
      expect(n.intentar(trans(dia(0, 12))), isTrue);
      n.configurarPromociones('u1', activas: true);
      expect(n.intentar(promo(dia(0, 12))), isTrue);
    });
    test('el tope es POR persona', () {
      final n = Notificador();
      n.intentar(promo(dia(0, 9)));
      n.intentar(promo(dia(0, 10)));
      expect(n.intentar(promo(dia(0, 11), u: 'u2')), isTrue);
    });
  });

  group('Sugerencias', () {
    DateTime h(int hora) => DateTime(2026, 11, 9, hora);
    test('según la hora propone primero un servicio distinto que aún no usa', () {
      expect(sugerirServicio(usosUltimos30Dias: {}, ahora: h(9)).servicio, Servicio.transporte);
      expect(sugerirServicio(usosUltimos30Dias: {}, ahora: h(13)).servicio, Servicio.comercio);
      expect(sugerirServicio(usosUltimos30Dias: {}, ahora: h(19)).servicio, Servicio.mensajeria);
      expect(sugerirServicio(usosUltimos30Dias: {}, ahora: h(23)).servicio, Servicio.mensajeria);
      expect(sugerirServicio(usosUltimos30Dias: {}, ahora: h(3)).servicio, Servicio.mensajeria);
    });
    test('salta los que ya usa', () {
      final s = sugerirServicio(usosUltimos30Dias: {Servicio.transporte: 5}, ahora: h(9));
      expect(s.servicio, Servicio.mensajeria);
    });
    test('si usa todos, propone el menos usado', () {
      final s = sugerirServicio(
        usosUltimos30Dias: {Servicio.transporte: 5, Servicio.mensajeria: 3, Servicio.comercio: 1, Servicio.pagos: 2},
        ahora: h(9),
      );
      expect(s.servicio, Servicio.comercio);
    });
  });
}