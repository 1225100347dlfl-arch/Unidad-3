import 'package:ajolotito/dominio/almacen.dart';
import 'package:ajolotito/dominio/gestor_permiso.dart';
import 'package:ajolotito/dominio/reloj.dart';
import 'package:ajolotito/dominio/servicio.dart';
import 'package:ajolotito/presentacion/ajolote_vm.dart';
import 'package:ajolotito/presentacion/pantalla_ajolote.dart';
import 'package:flutter/material.dart';
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
  });

  Future<void> abrir(WidgetTester t) async {
    await t.runAsync(() => vm.iniciar(conReloj: false));
    await t.pumpWidget(MaterialApp(home: PantallaAjolote(vm: vm)));
  }

  testWidgets('muestra al ajolote feliz y el botón para activar avisos', (t) async {
    await abrir(t);
    expect(find.text('Feliz y con la pancita llena'), findsOneWidget);
    expect(find.text('Avísame cuando tenga hambre'), findsOneWidget);
  });

  testWidgets('con hambre, dar de comer sube la saciedad', (t) async {
    await abrir(t);
    reloj.avanzar(const Duration(hours: 6));
    await t.runAsync(vm.alimentar);
    await t.pump();
    expect(find.text('Saciedad: 75 / 100'), findsOneWidget);
  });

  testWidgets('el permiso se pide solo tras explicar y aceptar en el diálogo', (t) async {
    await abrir(t);
    await t.tap(find.text('Avísame cuando tenga hambre'));
    await t.pumpAndSettle();
    expect(find.text('¿Te avisamos cuando tenga hambre?'), findsOneWidget);
    expect(puerto.vecesPidioPermiso, 0, reason: 'aún no sale el diálogo del sistema');

    await t.tap(find.text('Ahora no'));
    await t.pumpAndSettle();
    expect(puerto.vecesPidioPermiso, 0, reason: 'si dice "ahora no", no gastamos el permiso');

    await t.tap(find.text('Avísame cuando tenga hambre'));
    await t.pumpAndSettle();
    await t.tap(find.text('Sí, avísame'));
    await t.pumpAndSettle();
    expect(puerto.vecesPidioPermiso, 1);
  });
}