import 'package:flutter_test/flutter_test.dart';
import 'package:super_dolores/dominio/excepciones.dart';
import 'package:super_dolores/dominio/plataforma.dart';
import 'package:super_dolores/dominio/transporte.dart';

DateTime ahora = DateTime(2026, 11, 9, 10);
const jardin = Punto(21.1561, -100.9333);
const parroquia = Punto(21.1565, -100.9339);
const utng = Punto(21.1325, -100.9267);

const cuentas = [
  'ana', 'luis', 'marta', 'plataforma', 'dueno-tortilleria', 'dueno-cajeta', 'dueno-talavera', 'conductor1', 'conductor2',
];

Plataforma nueva({bool conSaldo = true}) {
  final p = Plataforma(reloj: () => ahora);
  if (conSaldo) p.cargarDatosDemo();
  return p;
}

int dineroTotal(Plataforma p) => cuentas.fold(0, (s, c) => s + p.monedero.saldo(c));

void main() {
  setUp(() => ahora = DateTime(2026, 11, 9, 10));

  group('Comercio', () {
    test('compra: cobra, reparte la comisión del 5% y descuenta inventario', () {
      final p = nueva();
      final pedido = p.comercio.comprar(usuarioId: 'ana', tiendaId: 'tortilleria', items: {'kilo': 2}, clave: 'p1');
      expect(pedido.totalCentavos, 5600);
      expect(pedido.comisionCentavos, 280);
      expect(p.monedero.saldo('ana'), 94400);
      expect(p.monedero.saldo('dueno-tortilleria'), 5320); // 5,600 - 280
      expect(p.monedero.saldo('plataforma'), 280); // el negocio de la plataforma
      expect(p.comercio.tiendas.first.producto('kilo')!.existencias, 48);
      expect(p.comercio.pedidosDe('ana').single.id, pedido.id);
    });
    test('INVARIANTE: la suma de todo el dinero del sistema no cambia con una compra', () {
      final p = nueva();
      final antes = dineroTotal(p);
      p.comercio.comprar(usuarioId: 'ana', tiendaId: 'cajeta', items: {'cajeta': 3, 'alegrias': 1}, clave: 'p1');
      expect(dineroTotal(p), antes);
    });
    test('IDEMPOTENCIA: un doble toque no compra dos veces', () {
      final p = nueva();
      final a = p.comercio.comprar(usuarioId: 'ana', tiendaId: 'tortilleria', items: {'kilo': 1}, clave: 'p1');
      final b = p.comercio.comprar(usuarioId: 'ana', tiendaId: 'tortilleria', items: {'kilo': 1}, clave: 'p1');
      expect(identical(a, b), isTrue);
      expect(p.monedero.saldo('ana'), 97200);
      expect(p.comercio.tiendas.first.producto('kilo')!.existencias, 49);
    });
    test('sin saldo: no hay pedido, ni cobro, ni cambio de inventario', () {
      final p = nueva();
      expect(
          () => p.comercio.comprar(usuarioId: 'ana', tiendaId: 'talavera', items: {'jarron': 1}, clave: 'p1') // \$1,250 > \$1,000
              ,
          throwsA(isA<SaldoInsuficienteException>()));
      expect(p.comercio.pedidosDe('ana'), isEmpty);
      expect(p.comercio.tiendas.last.producto('jarron')!.existencias, 4);
      expect(p.monedero.saldo('ana'), 100000);
    });
    test('validaciones del pedido', () {
      final p = nueva();
      PedidoInvalidoException? e;
      void intentar(Map<String, int> items, {String tienda = 'tortilleria'}) {
        try {
          p.comercio.comprar(usuarioId: 'ana', tiendaId: tienda, items: items, clave: 'k${items.hashCode}');
        } on PedidoInvalidoException catch (x) {
          e = x;
        }
      }

      intentar({});
      expect(e, isNotNull);
      e = null;
      intentar({'kilo': 0});
      expect(e, isNotNull);
      e = null;
      intentar({'kilo': 11});
      expect(e, isNotNull);
      e = null;
      intentar({'noexiste': 1});
      expect(e, isNotNull);
      e = null;
      intentar({'kilo': 1}, tienda: 'fantasma');
      expect(e, isNotNull);
    });
    test('existencias insuficientes', () {
      final p = nueva();
      expect(() => p.comercio.comprar(usuarioId: 'ana', tiendaId: 'talavera', items: {'taza': 10, 'jarron': 5}, clave: 'k'),
          throwsA(isA<ExistenciasInsuficientesException>()));
    });
    test('la compra genera puntos y avisos a comprador y vendedor', () {
      final p = nueva();
      p.comercio.comprar(usuarioId: 'ana', tiendaId: 'tortilleria', items: {'kilo': 2}, clave: 'p1');
      expect(p.lealtad.puntos('ana'), 5); // 5,600 centavos → \$56 → 5 puntos
      expect(p.notificador.de('ana').single.titulo, 'Pedido confirmado');
      expect(p.notificador.de('dueno-tortilleria').single.titulo, 'Te llegó dinero');
    });
  });

  group('Transporte', () {
    test('Haversine: un grado de longitud en el ecuador ≈ 111.195 km', () {
      expect(distanciaKm(const Punto(0, 0), const Punto(0, 1)), closeTo(111.195, 0.01));
    });
    test('distancia cero y simetría', () {
      expect(distanciaKm(jardin, jardin), 0);
      expect(distanciaKm(jardin, utng), closeTo(distanciaKm(utng, jardin), 1e-9));
      expect(distanciaKm(jardin, utng), closeTo(2.712, 0.01));
    });
    test('tarifa: base + km + minutos', () => expect(Tarifa.calcular(km: 5, minutos: 12), 8300));
    test('tarifa dinámica con tope de 2.0 y piso de 1.0', () {
      expect(Tarifa.calcular(km: 5, minutos: 12, multiplicador: 1.5), 12450);
      expect(Tarifa.calcular(km: 5, minutos: 12, multiplicador: 3), 16600);
      expect(Tarifa.calcular(km: 5, minutos: 12, multiplicador: 0.5), 8300);
    });
    test('viaje muy corto paga el mínimo', () => expect(Tarifa.calcular(km: 0.5, minutos: 2), Tarifa.minimoCentavos));
    test('minutos estimados a 25 km/h, redondeando hacia arriba', () {
      expect(Tarifa.minutosEstimados(5), 12);
      expect(Tarifa.minutosEstimados(10), 24);
      expect(Tarifa.minutosEstimados(2.5), 6);
    });
    test('estimar usa la distancia real', () {
      final p = nueva();
      expect(p.viajes.estimar(jardin, utng), 5720);
      expect(p.viajes.estimar(jardin, parroquia), Tarifa.minimoCentavos);
    });
    test('solicitar exige saldo para el estimado', () {
      final p = nueva(conSaldo: false);
      expect(() => p.viajes.solicitar('ana', jardin, utng), throwsA(isA<SaldoInsuficienteException>()));
    });
    test('viaje completo: cobra la tarifa REAL y paga al conductor menos 20%', () {
      final p = nueva();
      final antes = dineroTotal(p);
      final v = p.viajes.solicitar('ana', jardin, utng);
      expect(v.estado, EstadoViaje.solicitado);
      p.viajes.aceptar(v.id, 'conductor1');
      p.viajes.iniciar(v.id);
      final fin = p.viajes.finalizar(v.id, kmReal: 5, minutosReal: 12);
      expect(fin.estado, EstadoViaje.finalizado);
      expect(fin.cobradoCentavos, 8300);
      expect(p.monedero.saldo('ana'), 91700);
      expect(p.monedero.saldo('conductor1'), 6640);
      expect(p.monedero.saldo('plataforma'), 1660);
      expect(dineroTotal(p), antes); // el dinero solo cambió de manos
      expect(p.lealtad.puntos('ana'), 8);
      expect(p.notificador.de('ana').single.titulo, 'Viaje finalizado');
    });
    test('transiciones ilegales lanzan error y no cambian nada', () {
      final p = nueva();
      final v = p.viajes.solicitar('ana', jardin, utng);
      expect(() => p.viajes.iniciar(v.id), throwsA(isA<TransicionInvalidaException>()));
      expect(() => p.viajes.finalizar(v.id, kmReal: 1, minutosReal: 1), throwsA(isA<TransicionInvalidaException>()));
      p.viajes.aceptar(v.id, 'conductor1');
      p.viajes.iniciar(v.id);
      expect(() => p.viajes.cancelar(v.id), throwsA(isA<TransicionInvalidaException>()));
      p.viajes.finalizar(v.id, kmReal: 3, minutosReal: 8);
      expect(() => p.viajes.finalizar(v.id, kmReal: 3, minutosReal: 8), throwsA(isA<TransicionInvalidaException>()));
      expect(p.monedero.saldo('plataforma') > 0, isTrue);
    });
    test('cancelar antes de que acepten es gratis', () {
      final p = nueva();
      final v = p.viajes.solicitar('ana', jardin, utng);
      expect(p.viajes.cancelar(v.id).estado, EstadoViaje.cancelado);
      expect(p.monedero.saldo('ana'), 100000);
    });
    test('cancelar después de aceptar cobra \$15 al pasajero para el conductor', () {
      final p = nueva();
      final v = p.viajes.solicitar('ana', jardin, utng);
      p.viajes.aceptar(v.id, 'conductor1');
      p.viajes.cancelar(v.id);
      expect(p.monedero.saldo('ana'), 98500);
      expect(p.monedero.saldo('conductor1'), 1500);
    });
    test('la cancelación cobra solo lo que haya si el saldo es menor a \$15', () {
      final p = nueva(conSaldo: false);
      p.monedero.depositar('ana', 5000, clave: 'd');
      final v = p.viajes.solicitar('ana', jardin, parroquia); // estimado \$45
      p.viajes.aceptar(v.id, 'conductor1');
      p.monedero.transferir('ana', 'luis', 4000, 'x', clave: 't'); // quedan \$10
      p.viajes.cancelar(v.id);
      expect(p.monedero.saldo('ana'), 0);
      expect(p.monedero.saldo('conductor1'), 1000);
    });
  });

  group('Integración entre servicios (la gracia de una SuperApp)', () {
    test('un día de uso: chat + dinero + compra + viaje suman puntos y variedad', () {
      final p = nueva();
      p.mensajes.enviar('ana', 'luis', 'Hola');
      p.mensajes.enviarDinero('ana', 'luis', 5000, clave: 'a');
      p.comercio.comprar(usuarioId: 'ana', tiendaId: 'cajeta', items: {'cajeta': 1}, clave: 'b');
      final v = p.viajes.solicitar('ana', jardin, utng);
      p.viajes.aceptar(v.id, 'conductor1');
      p.viajes.iniciar(v.id);
      p.viajes.finalizar(v.id, kmReal: 5, minutosReal: 12);
      // pagos+mensajería (+50), comercio (+100 por 3 servicios), transporte (+200 por 4) y gasto: 9 + 8
      expect(p.lealtad.puntos('ana'), 50 + 100 + 200 + 9 + 8);
      expect(p.analitica.serviciosPorUsuario(DateTime(2026, 11, 9), DateTime(2026, 11, 9)), 4.0);
    });
  });
}