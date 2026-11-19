import 'package:flutter/material.dart';

import '../dominio/categoria.dart';
import '../dominio/gestor_permiso.dart';
import 'ajolote_vm.dart';

/// El usuario manda: cada tipo de aviso se puede apagar por separado.
class PantallaAjustes extends StatelessWidget {
  const PantallaAjustes({super.key, required this.vm});
  final AjoloteViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Ajustes de avisos')),
        body: ListView(children: [
          ListTile(
            leading: Icon(vm.permiso == EstadoPermiso.concedido ? Icons.check_circle : Icons.block),
            title: Text(switch (vm.permiso) {
              EstadoPermiso.concedido => 'El sistema permite notificaciones',
              EstadoPermiso.denegado => 'El sistema las tiene bloqueadas',
              EstadoPermiso.sinPreguntar => 'Aún no has decidido',
            }),
            trailing: TextButton(onPressed: vm.abrirAjustes, child: const Text('Ajustes del sistema')),
          ),
          const Divider(),
          for (final c in Categoria.values)
            SwitchListTile(
              title: Text(c.canal.nombre),
              subtitle: Text(c.canal.descripcion),
              value: vm.categorias[c] ?? true,
              onChanged: (v) => vm.cambiarCategoria(c, v),
            ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Silencio automático de 10 pm a 8 am. Máximo 3 avisos al día.'),
          ),
        ]),
      ),
    );
  }
}