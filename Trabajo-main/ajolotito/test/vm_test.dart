import 'package:ajolotito/dominio/almacen.dart';
import 'package:ajolotito/dominio/categoria.dart';
import 'package:ajolotito/dominio/gestor_permiso.dart';
import 'package:ajolotito/dominio/mascota.dart';
import 'package:ajolotito/dominio/payload.dart';
import 'package:ajolotito/dominio/planificador.dart';
import 'package:ajolotito/dominio/reloj.dart';
import 'package:ajolotito/dominio/servicio.dart';
import 'package:ajolotito/presentacion/ajolote_vm.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'falsos.dart';

void main() {
  late PuertoFalso puerto;
  late RelojFalso reloj;
  late AjoloteViewModel vm;

  setUp(() {
    puerto = PuertoFalso()..activas = false;
    reloj = RelojFalso(DateTime(2026, 11, 12, 10));
    final almacen = AlmacenMemoria();
    vm = AjoloteViewModel(
      servicio: ServicioAjolote(puerto: puerto, almacen: almacen, reloj: reloj),
      gestor: GestorPermiso(puerto: puerto, almacen: almacen),
      reloj: reloj,
    );
    puerto.escucharToques(vm.alTocarNotificacion);
  });

  test('al iniciar NO pide permiso (se pide en contexto, no al arrancar)', () async {
    await vm.iniciar(conReloj: false);
    expect(puerto.vecesPidioPermiso, 0);
    expect(vm.permiso, EstadoPermiso.sinPreguntar);
    expect(vm.saciedad, 100);
  });

  test('activarAvisos pide permiso y, si lo dan, programa avisos', () async {
    await vm.iniciar(conReloj: false);
    final r = await vm.activarAvisos();
    expect(r, ResultadoPermiso.concedido);
    expect(vm.permiso, EstadoPermiso.concedido);
    expect(vm.programadas, isNotEmpty);
  });

  test('si el usuario rechaza, no se programa nada y la siguiente vez lo mandamos a Ajustes', () async {
    puerto.usuarioAcepta = false;
    await vm.iniciar(conReloj: false);
    expect(await vm.activarAvisos(), ResultadoPermiso.denegado);
    expect(puerto.programadas, isEmpty);
    expect(await vm.activarAvisos(), ResultadoPermiso.hayQueIrAAjustes);
  });

  test('alimentar con la panza llena avisa con cariño, sin tronar', () async {
    await vm.iniciar(conReloj: false);
    await vm.alimentar();
    expect(vm.aviso, contains('llenísimo'));
  });

  test('alimentar con hambre sube la saciedad', () async {
    await vm.iniciar(conReloj: false);
    reloj.avanzar(const Duration(hours: 6)); // 40
    expect(vm.humor, Humor.hambriento);
    await vm.alimentar();
    expect(vm.saciedad, 75);
    expect(vm.humor, Humor.feliz);
  });

  group('toques en notificaciones', () {
    test('tocar un aviso de hambre resalta el botón de alimentar', () async {
      await vm.iniciar(conReloj: false);
      puerto.simularToque('v1:alimentar');
      await Future<void>.delayed(Duration.zero);
      expect(vm.resaltarAlimentar, isTrue);
    });

    test('el botón "Dar de comer" de la notificación alimenta de una vez', () async {
      await vm.iniciar(conReloj: false);
      reloj.avanzar(const Duration(hours: 6));
      puerto.simularToque('v1:alimentarYa');
      await Future<void>.delayed(Duration.zero);
      expect(vm.saciedad, 75);
    });

    test('arrancar desde la notificación alimentarYa también alimenta', () async {
      await vm.servicio.cargar(); // el ajolote nace a las 10:00
      reloj.avanzar(const Duration(hours: 6));
      await vm.iniciar(destino: Destino.alimentarYa, conReloj: false);
      expect(vm.saciedad, 75);
    });
  });

  test('ciclo de vida: al pausar se programa el hambre; al volver, se quita', () async {
    puerto.activas = true;
    await vm.iniciar(conReloj: false);
    expect(puerto.programadas.containsKey(Ids.hambre), isFalse);
    await vm.alCambiarCicloDeVida(AppLifecycleState.paused);
    expect(puerto.programadas.containsKey(Ids.hambre), isTrue);
    await vm.alCambiarCicloDeVida(AppLifecycleState.resumed);
    expect(puerto.programadas.containsKey(Ids.hambre), isFalse);
  });

  test('apagar una categoría desde la VM se refleja en lo programado', () async {
    puerto.activas = true;
    await vm.iniciar(conReloj: false);
    await vm.alCambiarCicloDeVida(AppLifecycleState.paused);
    await vm.cambiarCategoria(Categoria.hambre, false);
    expect(puerto.programadas.containsKey(Ids.hambre), isFalse);
    expect(vm.categorias[Categoria.hambre], isFalse);
  });
}