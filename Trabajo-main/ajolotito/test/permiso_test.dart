import 'package:ajolotito/dominio/almacen.dart';
import 'package:ajolotito/dominio/gestor_permiso.dart';
import 'package:flutter_test/flutter_test.dart';

import 'falsos.dart';

void main() {
  late PuertoFalso puerto;
  late GestorPermiso gestor;

  setUp(() {
    puerto = PuertoFalso()..activas = false;
    gestor = GestorPermiso(puerto: puerto, almacen: AlmacenMemoria());
  });

  test('al inicio nunca hemos preguntado', () async {
    expect(await gestor.estado(), EstadoPermiso.sinPreguntar);
    expect(puerto.vecesPidioPermiso, 0, reason: 'consultar el estado NO debe mostrar el diálogo');
  });

  test('el usuario acepta: queda concedido', () async {
    expect(await gestor.solicitar(), ResultadoPermiso.concedido);
    expect(await gestor.estado(), EstadoPermiso.concedido);
  });

  test('si ya estaba concedido, no vuelve a preguntar', () async {
    puerto.activas = true;
    expect(await gestor.solicitar(), ResultadoPermiso.yaConcedido);
    expect(puerto.vecesPidioPermiso, 0);
  });

  test('el usuario dice que no: NO insistimos, lo guiamos a Ajustes', () async {
    puerto.usuarioAcepta = false;
    expect(await gestor.solicitar(), ResultadoPermiso.denegado);
    expect(await gestor.estado(), EstadoPermiso.denegado);
    expect(await gestor.solicitar(), ResultadoPermiso.hayQueIrAAjustes);
    expect(puerto.vecesPidioPermiso, 1, reason: 'el diálogo del sistema salió una sola vez');
  });

  test('si luego lo activa en Ajustes, volvemos a verlo concedido', () async {
    puerto.usuarioAcepta = false;
    await gestor.solicitar();
    puerto.activas = true; // el usuario fue a Ajustes del sistema
    expect(await gestor.estado(), EstadoPermiso.concedido);
  });

  test('abrirAjustes delega en el puerto', () async {
    await gestor.abrirAjustes();
    expect(puerto.ajustesAbiertos, 1);
  });
}