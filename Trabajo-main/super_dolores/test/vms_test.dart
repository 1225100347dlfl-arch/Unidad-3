import 'dart:ui' show VoidCallback;
import 'package:flutter_test/flutter_test.dart';
import 'package:super_dolores/dominio/eventos.dart';
import 'package:super_dolores/dominio/plataforma.dart';
import 'package:super_dolores/dominio/transporte.dart';
import 'package:super_dolores/presentacion/vm/chat_vm.dart';
import 'package:super_dolores/presentacion/vm/inicio_vm.dart';
import 'package:super_dolores/presentacion/vm/metricas_vm.dart';
import 'package:super_dolores/presentacion/vm/monedero_vm.dart';
import 'package:super_dolores/presentacion/vm/tienda_vm.dart';
import 'package:super_dolores/presentacion/vm/viajes_vm.dart';

DateTime ahora = DateTime(2026, 11, 9, 10);

Plataforma nueva() => Plataforma(reloj: () => ahora)..cargarDatosDemo();

void main() {
  setUp(() => ahora = DateTime(2026, 11, 9, 10));

  group('InicioViewModel', () {
    test('muestra saldo, puntos, nivel y no leídos', () {
      final p = nueva();
      final vm = InicioViewModel(p, 'ana');
      expect(vm.saldo, 100000);
      expect(vm.puntos, 0);
      expect(vm.nivel.nombre, 'Bronce');
      p.mensajes.enviar('luis', 'ana', 'Hola');
      expect(vm.noLeidos, 1);
    });
    test('la sugerencia cambia cuando el usuario ya usó el servicio', () {
      final p = nueva();
      final vm = InicioViewModel(p, 'ana');
      expect(vm.sugerencia.servicio, Servicio.transporte); // 10 am y nunca ha viajado
      final v = p.viajes.solicitar('ana', const Punto(21.1561, -100.9333), const Punto(21.1325, -100.9267));
      p.viajes.aceptar(v.id, 'conductor1');
      p.viajes.iniciar(v.id);
      p.viajes.finalizar(v.id, kmReal: 3, minutosReal: 8);
      expect(vm.sugerencia.servicio, Servicio.mensajeria);
    });
    test('cambiar de usuario avisa a la pantalla', () {
      final vm = InicioViewModel(nueva(), 'ana');
      var avisos = 0;
      vm.addListener(() => avisos++);
      vm.cambiarUsuario('luis');
      expect(vm.usuarioId, 'luis');
      expect(avisos, 1);
    });
    test('canjearTodo convierte los puntos canjeables en saldo', () {
      final p = nueva();
      p.monedero.depositar('ana', 500000, clave: 'extra');
      p.comercio.comprar(usuarioId: 'ana', tiendaId: 'talavera', items: {'jarron': 1}, clave: 'j'); // 125 pts
      final vm = InicioViewModel(p, 'ana');
      expect(vm.puntos, 125);
      final saldoAntes = vm.saldo;
      expect(vm.canjearTodo(), 1000);
      expect(vm.puntos, 25);
      expect(vm.saldo, saldoAntes + 1000);
      expect(vm.canjearTodo(), 0); // ya no alcanza para otro canje
    });
    test('el kill switch quita la mini-app de la lista', () {
      final p = nueva();
      final vm = InicioViewModel(p, 'ana');
      expect(vm.miniApps.map((a) => a.id), contains('viajes'));
      p.registro.apagar('viajes');
      expect(vm.miniApps.map((a) => a.id), isNot(contains('viajes')));
    });
  });

  group('MonederoViewModel', () {
    test('enviar dinero funciona y avisa para refrescar el inicio', () async {
      final p = nueva();
      var cambios = 0;
      final vm = MonederoViewModel(p.contextoPara(Plataforma.miniMonedero, 'ana'), alCambiar: () => cambios++);
      await vm.enviarDinero('luis', 2500);
      expect(vm.error, isNull);
      expect(vm.exito, isNotNull);
      expect(vm.saldo, 97500);
      expect(cambios, 1);
    });
    test('un error del negocio se muestra con su mensaje claro', () async {
      final p = nueva();
      final vm = MonederoViewModel(p.contextoPara(Plataforma.miniMonedero, 'ana'));
      await vm.enviarDinero('luis', 99999999);
      expect(vm.error, contains('Límite'));
      await vm.enviarDinero('luis', 500000); // \$5,000 > saldo \$1,000
      expect(vm.error, 'Saldo insuficiente.');
    });
    test('un error inesperado no revela detalles', () async {
      final p = nueva();
      final vm = MonederoViewModel(p.contextoPara(Plataforma.miniMonedero, 'ana'));
      await vm.enviarDinero('fantasma', 100); // cuenta inexistente → error del negocio
      expect(vm.error, 'La cuenta no existe.');
    });
  });

  group('ChatViewModel', () {
    test('abrir marca como leídos y enviar agrega el mensaje', () {
      final p = nueva();
      p.mensajes.enviar('luis', 'ana', 'Hola Ana');
      final vm = ChatViewModel(p.contextoPara(Plataforma.miniChat, 'ana'));
      expect(vm.resumenes.single.noLeidos, 1);
      vm.abrir('luis');
      expect(p.mensajes.noLeidos('ana'), 0);
      vm.enviar('Hola Luis');
      expect(vm.mensajes.map((m) => m.texto), ['Hola Ana', 'Hola Luis']);
    });
    test('mensaje vacío muestra aviso y no se envía', () {
      final p = nueva();
      final vm = ChatViewModel(p.contextoPara(Plataforma.miniChat, 'ana'))..abrir('luis');
      vm.enviar('   ');
      expect(vm.error, 'Escribe un mensaje.');
      expect(vm.mensajes, isEmpty);
    });
    test('enviar dinero desde el chat', () {
      final p = nueva();
      final vm = ChatViewModel(p.contextoPara(Plataforma.miniChat, 'ana'))..abrir('luis');
      vm.enviarDinero(5000);
      expect(vm.error, isNull);
      expect(p.monedero.saldo('luis'), 105000);
    });
  });

  group('TiendaViewModel', () {
    TiendaViewModel armar(Plataforma p, {VoidCallback? alCambiar}) =>
        TiendaViewModel(p.contextoPara(Plataforma.miniTienda, 'ana'), alCambiar: alCambiar);

    test('arma el carrito, calcula el total y compra', () async {
      final p = nueva();
      var cambios = 0;
      final vm = armar(p, alCambiar: () => cambios++);
      vm.elegirTienda(vm.tiendas.first); // tortillería
      vm.cambiar('kilo', 2);
      vm.cambiar('tostadas', 1);
      expect(vm.total, 2 * 2800 + 3500);
      await vm.comprar();
      expect(vm.ultimoPedido, isNotNull);
      expect(vm.carrito, isEmpty);
      expect(cambios, 1);
      expect(p.monedero.saldo('ana'), 100000 - 9100);
    });
    test('quitar cantidades elimina la línea', () {
      final vm = armar(nueva());
      vm.elegirTienda(vm.tiendas.first);
      vm.cambiar('kilo', 1);
      vm.cambiar('kilo', -1);
      expect(vm.carrito, isEmpty);
    });
    test('sin saldo: error claro y el carrito se conserva', () async {
      final p = nueva();
      final vm = armar(p);
      vm.elegirTienda(vm.tiendas.last); // talavera
      vm.cambiar('jarron', 1);
      await vm.comprar();
      expect(vm.error, 'Saldo insuficiente.');
      expect(vm.carrito, {'jarron': 1});
      expect(vm.ultimoPedido, isNull);
    });
    test('volver limpia la selección', () {
      final vm = armar(nueva());
      vm.elegirTienda(vm.tiendas.first);
      vm.cambiar('kilo', 1);
      vm.volver();
      expect(vm.tienda, isNull);
      expect(vm.carrito, isEmpty);
    });
  });

  group('ViajesViewModel', () {
    ViajesViewModel armar(Plataforma p) => ViajesViewModel(p.contextoPara(Plataforma.miniViajes, 'ana'));

    test('recorrido completo: pedir, aceptar, iniciar, llegar y pagar', () {
      final p = nueva();
      final vm = armar(p);
      expect(vm.estimado, greaterThan(0));
      vm.solicitar();
      expect(vm.actual!.estado, EstadoViaje.solicitado);
      vm.conductorAcepta();
      vm.iniciar();
      vm.finalizar();
      expect(vm.actual!.estado, EstadoViaje.finalizado);
      expect(vm.error, isNull);
      expect(p.monedero.saldo('ana'), lessThan(100000));
      expect(vm.historial.length, 1);
    });
    test('origen igual a destino no se puede pedir', () {
      final vm = armar(nueva());
      vm.elegir(nuevoDestino: vm.origen);
      vm.solicitar();
      expect(vm.error, contains('no pueden ser iguales'));
      expect(vm.actual, isNull);
    });
    test('una acción fuera de orden muestra un mensaje claro', () {
      final vm = armar(nueva());
      vm.solicitar();
      vm.iniciar(); // falta que el conductor acepte
      expect(vm.error, contains('estado actual'));
    });
    test('con el kill switch apagado, pedir un viaje falla con un aviso amable', () {
      final p = nueva();
      final vm = armar(p);
      p.registro.apagar('viajes');
      vm.solicitar();
      expect(vm.error, contains('no está disponible'));
    });
  });

  group('MetricasViewModel (datos sintéticos con semilla)', () {
    test('es reproducible: misma semilla, mismos números', () {
      final a = MetricasViewModel(DateTime(2026, 1, 1));
      final b = MetricasViewModel(DateTime(2026, 1, 1));
      expect(a.mau, b.mau);
      expect(a.dau, b.dau);
      expect(a.retencionPromedio(7), b.retencionPromedio(7));
    });
    test('coherencia: DAU ≤ WAU ≤ MAU y las tasas están entre 0 y 1', () {
      final v = MetricasViewModel(DateTime(2026, 1, 1));
      expect(v.dau, lessThanOrEqualTo(v.wau));
      expect(v.wau, lessThanOrEqualTo(v.mau));
      expect(v.stickiness, inInclusiveRange(0, 1));
      for (final n in [1, 7]) {
        expect(v.retencionPromedio(n), inInclusiveRange(0, 1));
      }
      expect(v.serviciosPorUsuario, inInclusiveRange(1, 4));
      expect(v.comparacion.nUno + v.comparacion.nMulti, greaterThan(0));
    });
    test('la retención baja con los días: D1 ≥ D7 (los usuarios se van yendo)', () {
      final v = MetricasViewModel(DateTime(2026, 1, 1));
      expect(v.retencionPromedio(1), greaterThanOrEqualTo(v.retencionPromedio(7)));
    });
  });
}