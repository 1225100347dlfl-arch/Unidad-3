import 'package:flutter_test/flutter_test.dart';
import 'package:super_dolores/dominio/dinero.dart';
import 'package:super_dolores/dominio/eventos.dart';
import 'package:super_dolores/dominio/excepciones.dart';
import 'package:super_dolores/dominio/mensajeria.dart';
import 'package:super_dolores/dominio/monedero.dart';
import 'package:super_dolores/dominio/plataforma.dart';
import 'package:super_dolores/dominio/transporte.dart';

DateTime ahora = DateTime(2026, 11, 9, 10); // un lunes
const _jardin = Punto(21.1561, -100.9333);
const _parroquia = Punto(21.1565, -100.9339);

Plataforma nueva() => Plataforma(reloj: () => ahora)..cargarDatosDemo();

Monedero monederoConCuentas() {
  final m = Monedero(reloj: () => ahora)
    ..abrirCuenta('ana')
    ..abrirCuenta('luis');
  return m;
}

void main() {
  setUp(() => ahora = DateTime(2026, 11, 9, 10));

  group('dinero y fechas', () {
    test('formatearPesos', () {
      expect(formatearPesos(125000), r'$1,250.00');
      expect(formatearPesos(5), r'$0.05');
      expect(formatearPesos(0), r'$0.00');
      expect(formatearPesos(-5050), r'-$50.50');
      expect(formatearPesos(100000000), r'$1,000,000.00');
    });
    test('porcentaje redondea al más cercano', () {
      expect(porcentaje(9999, 5), 500);
      expect(porcentaje(5600, 5), 280);
    });
    test('lunesDe: toda la semana apunta al mismo lunes', () {
      final lunes = DateTime(2026, 11, 9);
      for (var d = 9; d <= 15; d++) {
        expect(lunesDe(DateTime(2026, 11, d, 23, 59)), lunes, reason: 'día $d');
      }
      expect(lunesDe(DateTime(2026, 11, 16)), DateTime(2026, 11, 16));
    });
    test('masDias cruza de mes', () => expect(masDias(DateTime(2026, 11, 28), 5), DateTime(2026, 12, 3)));
  });

  group('Monedero (libro de movimientos)', () {
    test('el saldo es la suma de los movimientos', () {
      final m = monederoConCuentas();
      m.depositar('ana', 10000, clave: 'a');
      m.pagar('ana', 2500, 'Café', clave: 'b');
      expect(m.saldo('ana'), 7500);
      expect(m.movimientos('ana').length, 2);
      expect(m.movimientos('ana').first.concepto, 'Café'); // el más reciente primero
    });
    test('no se puede pagar más de lo que hay', () {
      final m = monederoConCuentas()..depositar('ana', 1000, clave: 'a');
      expect(() => m.pagar('ana', 1001, 'x', clave: 'b'), throwsA(isA<SaldoInsuficienteException>()));
      expect(m.saldo('ana'), 1000);
    });
    test('montos inválidos y tope por operación', () {
      final m = monederoConCuentas();
      expect(() => m.depositar('ana', 0, clave: 'a'), throwsA(isA<MontoInvalidoException>()));
      expect(() => m.depositar('ana', -5, clave: 'b'), throwsA(isA<MontoInvalidoException>()));
      expect(() => m.depositar('ana', Monedero.maxPorOperacion + 1, clave: 'c'), throwsA(isA<LimiteExcedidoException>()));
      m.depositar('ana', Monedero.maxPorOperacion, clave: 'd'); // justo en el tope: sí
    });
    test('transferir mueve el dinero y la suma total NO cambia', () {
      final m = monederoConCuentas()..depositar('ana', 10000, clave: 'a');
      final antes = m.saldo('ana') + m.saldo('luis');
      m.transferir('ana', 'luis', 4000, 'Regalo', clave: 't1');
      expect(m.saldo('ana'), 6000);
      expect(m.saldo('luis'), 4000);
      expect(m.saldo('ana') + m.saldo('luis'), antes);
    });
    test('transferir es TODO o NADA: si falla, no queda rastro', () {
      final m = monederoConCuentas()..depositar('ana', 1000, clave: 'a');
      expect(() => m.transferir('ana', 'luis', 5000, 'x', clave: 't'), throwsA(isA<SaldoInsuficienteException>()));
      expect(m.movimientos('luis'), isEmpty);
      expect(m.movimientos('ana').length, 1);
    });
    test('no se puede transferir a uno mismo ni a una cuenta inexistente', () {
      final m = monederoConCuentas()..depositar('ana', 1000, clave: 'a');
      expect(() => m.transferir('ana', 'ana', 100, 'x', clave: 't'), throwsA(isA<DestinatarioInvalidoException>()));
      expect(() => m.transferir('ana', 'fantasma', 100, 'x', clave: 't'), throwsA(isA<CuentaNoExisteException>()));
    });
    test('IDEMPOTENCIA: repetir la misma clave no cobra dos veces', () {
      final m = monederoConCuentas()..depositar('ana', 10000, clave: 'a');
      final a = m.pagar('ana', 3000, 'Taxi', clave: 'k1');
      final b = m.pagar('ana', 3000, 'Taxi', clave: 'k1');
      expect(identical(a, b), isTrue);
      expect(m.saldo('ana'), 7000);
      m.transferir('ana', 'luis', 1000, 'x', clave: 'k2');
      m.transferir('ana', 'luis', 1000, 'x', clave: 'k2');
      expect(m.saldo('luis'), 1000);
    });
    test('límite diario de salidas y se renueva al día siguiente', () {
      final m = monederoConCuentas();
      for (var i = 0; i < 3; i++) {
        m.depositar('ana', 500000, clave: 'd$i');
      }
      m.pagar('ana', 500000, 'a', clave: 'p1');
      m.pagar('ana', 500000, 'b', clave: 'p2'); // 10,000 = justo el tope
      expect(() => m.pagar('ana', 100, 'c', clave: 'p3'), throwsA(isA<LimiteExcedidoException>()));
      expect(m.salidasDeHoy('ana'), 1000000);
      ahora = DateTime(2026, 11, 10, 9);
      m.pagar('ana', 100, 'c', clave: 'p3'); // otro día: sí
    });
    test('las cuentas de la plataforma no tienen tope diario', () {
      final m = Monedero(reloj: () => ahora)
        ..abrirCuenta('plataforma', sinLimites: true)
        ..abrirCuenta('dueno');
      for (var i = 0; i < 5; i++) {
        m.depositar('plataforma', 500000, clave: 'd$i');
      }
      for (var i = 0; i < 5; i++) {
        m.transferir('plataforma', 'dueno', 500000, 'x', clave: 't$i'); // 25,000 en un día
      }
      expect(m.saldo('dueno'), 2500000);
    });
    test('el reembolso devuelve dinero y valida el monto', () {
      final m = monederoConCuentas();
      m.reembolsar('ana', 1000, 'Canje', clave: 'r');
      expect(m.saldo('ana'), 1000);
      expect(() => m.reembolsar('ana', 0, 'x', clave: 'r2'), throwsA(isA<MontoInvalidoException>()));
    });
  });

  group('Bus de eventos', () {
    EventoApp pago(String id) => PagoRealizado(id, 'ana', ahora, montoCentavos: 100, concepto: 'x', origen: Servicio.pagos);

    test('cada suscriptor recibe solo el TIPO que pidió', () {
      final bus = BusEventos();
      final pagos = <String>[];
      final mensajes = <String>[];
      bus.suscribir<PagoRealizado>((e) => pagos.add(e.id));
      bus.suscribir<MensajeEnviado>((e) => mensajes.add(e.id));
      bus.publicar(pago('e1'));
      bus.publicar(MensajeEnviado('e2', 'ana', ahora, para: 'luis'));
      expect(pagos, ['e1']);
      expect(mensajes, ['e2']);
    });
    test('un suscriptor que falla no impide que los demás reciban el evento', () {
      final bus = BusEventos();
      var recibido = 0;
      bus.suscribir<PagoRealizado>((_) => throw StateError('boom'));
      bus.suscribir<PagoRealizado>((_) => recibido++);
      bus.publicar(pago('e1'));
      expect(recibido, 1);
      expect(bus.errores.length, 1);
    });
    test('Ids genera identificadores únicos y legibles', () {
      final ids = Ids();
      expect([ids.siguiente('ev'), ids.siguiente('ev'), ids.siguiente('msg')], ['ev-1', 'ev-2', 'msg-3']);
    });
    test('recibir dinero no cuenta como uso; enviar mensajes sí', () {
      expect(DineroRecibido('e', 'ana', ahora, de: 'luis', montoCentavos: 1).cuentaComoUso, isFalse);
      expect(MensajeEnviado('e', 'ana', ahora, para: 'luis').cuentaComoUso, isTrue);
    });
  });

  group('Mensajería', () {
    test('valida mensajes vacíos, enormes, a uno mismo y a "sistema"', () {
      final p = nueva();
      expect(() => p.mensajes.enviar('ana', 'luis', '   '), throwsA(isA<MensajeInvalidoException>()));
      expect(() => p.mensajes.enviar('ana', 'luis', 'x' * 1001), throwsA(isA<MensajeInvalidoException>()));
      p.mensajes.enviar('ana', 'luis', 'x' * 1000); // justo en el límite
      expect(() => p.mensajes.enviar('ana', 'ana', 'hola'), throwsA(isA<DestinatarioInvalidoException>()));
      expect(() => p.mensajes.enviar('ana', ServicioMensajes.sistema, 'hola'), throwsA(isA<DestinatarioInvalidoException>()));
    });
    test('conversación en orden, no leídos y marcarLeidos', () {
      final p = nueva();
      p.mensajes.enviar('ana', 'luis', 'Hola');
      p.mensajes.enviar('luis', 'ana', 'Qué tal');
      p.mensajes.enviar('ana', 'luis', 'Bien');
      expect(p.mensajes.conversacion('ana', 'luis').map((m) => m.texto), ['Hola', 'Qué tal', 'Bien']);
      expect(p.mensajes.noLeidos('luis'), 2);
      p.mensajes.marcarLeidos('luis', 'ana');
      expect(p.mensajes.noLeidos('luis'), 0);
      expect(p.mensajes.noLeidos('ana'), 1);
    });
    test('resumenes: el chat más reciente va primero y cuenta no leídos', () {
      final p = nueva();
      p.mensajes.enviar('luis', 'ana', 'uno');
      p.mensajes.enviar('marta', 'ana', 'dos');
      p.mensajes.enviar('luis', 'ana', 'tres');
      final r = p.mensajes.resumenes('ana');
      expect(r.map((x) => x.con), ['luis', 'marta']);
      expect(r.first.noLeidos, 2);
    });
    test('mensajes de la plataforma no cuentan como uso', () {
      final p = nueva();
      p.mensajes.enviarSistema('ana', 'Bienvenida');
      expect(p.analitica.registros, isEmpty);
      expect(p.mensajes.deSistema('ana').length, 1);
    });
    test('dinero en el chat: transfiere, deja mensaje, notifica y cuenta como 2 servicios', () {
      final p = nueva();
      final m = p.mensajes.enviarDinero('ana', 'luis', 5000, clave: 'c1');
      expect(m.tipo, TipoMensaje.dinero);
      expect(p.monedero.saldo('ana'), 95000);
      expect(p.monedero.saldo('luis'), 105000);
      expect(p.lealtad.puntos('ana'), 50); // pagos + mensajería en la misma semana → bono
      expect(p.lealtad.puntos('luis'), 0); // recibir es pasivo
      expect(p.notificador.de('luis').single.titulo, 'Te llegó dinero');
    });
    test('si falta saldo, no se envía ni el dinero ni el mensaje', () {
      final p = nueva();
      p.mensajes.enviarDinero('ana', 'luis', 50000, clave: 'c1'); // \$500 de \$1,000: sí hay
      expect(() => p.mensajes.enviarDinero('ana', 'luis', 60000, clave: 'c2'), throwsA(isA<SaldoInsuficienteException>()));
      expect(p.mensajes.conversacion('ana', 'luis').length, 1);
    });
  });

  group('Mini-apps, permisos y kill switch', () {
    test('no se puede registrar dos veces la misma mini-app', () {
      final p = nueva();
      expect(() => p.registro.registrar(Plataforma.miniChat), throwsArgumentError);
    });
    test('una mini-app de tercero (solo identidad) no toca dinero ni chats', () {
      final p = nueva();
      final ctx = p.contextoPara(Plataforma.miniHoroscopo, 'ana');
      expect(() => ctx.monedero, throwsA(isA<PermisoDenegadoException>()));
      expect(() => ctx.pagos, throwsA(isA<PermisoDenegadoException>()));
      expect(() => ctx.mensajes, throwsA(isA<PermisoDenegadoException>()));
      expect(() => ctx.comercio, throwsA(isA<PermisoDenegadoException>()));
      expect(() => ctx.viajes, throwsA(isA<PermisoDenegadoException>()));
    });
    test('el chat puede enviar dinero pero NO leer el saldo (menor privilegio)', () {
      final p = nueva();
      final ctx = p.contextoPara(Plataforma.miniChat, 'ana');
      expect(() => ctx.monedero, throwsA(isA<PermisoDenegadoException>()));
      ctx.pagos.enviarDinero('luis', 1000, clave: 'x');
      expect(p.monedero.saldo('luis'), 101000);
    });
    test('la API está ligada a UN usuario: no puede actuar como otra persona', () {
      final p = nueva();
      final ctx = p.contextoPara(Plataforma.miniMonedero, 'ana');
      expect(ctx.monedero.saldo(), p.monedero.saldo('ana'));
      ctx.pagos.pagar(1000, 'Algo', clave: 'k');
      expect(p.monedero.saldo('ana'), 99000);
      expect(p.monedero.saldo('luis'), 100000); // intacto
    });
    test('kill switch: apagar una mini-app la oculta y bloquea sus llamadas', () {
      final p = nueva();
      final ctx = p.contextoPara(Plataforma.miniChat, 'ana');
      p.registro.apagar('chat');
      expect(p.registro.activas.map((a) => a.id), isNot(contains('chat')));
      expect(() => ctx.mensajes, throwsA(isA<MiniAppNoDisponibleException>()));
      p.registro.encender('chat');
      expect(() => ctx.mensajes, returnsNormally);
    });
    test('una mini-app no puede operar sobre viajes de otra persona', () {
      final p = nueva();
      final ana = p.contextoPara(Plataforma.miniViajes, 'ana').viajes;
      final luis = p.contextoPara(Plataforma.miniViajes, 'luis').viajes;
      final v = ana.solicitar(_jardin, _parroquia);
      expect(() => luis.cancelar(v.id), throwsA(isA<PedidoInvalidoException>()));
    });
  });
}