import 'package:flutter/material.dart';

import '../../dominio/contexto.dart';
import '../../dominio/dinero.dart';
import '../../dominio/mensajeria.dart';
import '../../dominio/plataforma.dart';
import '../vm/chat_vm.dart';
import 'widgets.dart';

class PantallaChat extends StatefulWidget {
  final ContextoMiniApp contexto;
  final VoidCallback alCambiar;
  final Plataforma plataforma;
  const PantallaChat({super.key, required this.contexto, required this.alCambiar, required this.plataforma});
  @override
  State<PantallaChat> createState() => _EstadoPantalla();
}

class _EstadoPantalla extends State<PantallaChat> {
  late final ChatViewModel vm = ChatViewModel(widget.contexto, alCambiar: widget.alCambiar);
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    vm.dispose();
    super.dispose();
  }

  String _nombre(String id) {
    for (final p in widget.plataforma.perfiles) {
      if (p.id == id) return p.nombre;
    }
    return id == ServicioMensajes.sistema ? 'Super Dolores' : id;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: vm,
        builder: (context, _) => vm.con == null ? _lista(context) : _conversacion(context),
      );

  Widget _lista(BuildContext context) {
    final yo = widget.contexto.usuarioId;
    final otros = widget.plataforma.perfiles.where((p) => p.id != yo).toList();
    final res = vm.resumenes;
    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes')),
      body: ListView(children: [
        const Padding(padding: EdgeInsets.all(12), child: Text('Iniciar chat con:')),
        Wrap(spacing: 8, children: [
          for (final p in otros) ActionChip(label: Text(p.nombre), onPressed: () => vm.abrir(p.id)),
        ]),
        const Divider(),
        for (final r in res)
          ListTile(
            leading: CircleAvatar(child: Text(_nombre(r.con)[0])),
            title: Text(_nombre(r.con)),
            subtitle: Text(r.ultimo.texto, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: r.noLeidos > 0 ? Badge(label: Text('${r.noLeidos}')) : null,
            onTap: () => vm.abrir(r.con),
          ),
      ]),
    );
  }

  Widget _conversacion(BuildContext context) {
    final yo = widget.contexto.usuarioId;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: vm.cerrar),
        title: Text(_nombre(vm.con!)),
        actions: [
          IconButton(
            tooltip: 'Enviar \$50',
            icon: const Icon(Icons.attach_money),
            onPressed: vm.con == ServicioMensajes.sistema ? null : () => vm.enviarDinero(5000),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.all(12), children: [
            for (final m in vm.mensajes)
              Align(
                alignment: m.de == yo ? Alignment.centerRight : Alignment.centerLeft,
                child: Card(
                  color: m.tipo == TipoMensaje.dinero ? Colors.green.shade100 : null,
                  child: Padding(padding: const EdgeInsets.all(10), child: Text(m.texto)),
                ),
              ),
            Aviso(vm.error),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(child: TextField(controller: _texto, maxLength: 1000, decoration: const InputDecoration(hintText: 'Mensaje', counterText: ''))),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                vm.enviar(_texto.text);
                if (vm.error == null) _texto.clear();
              },
            ),
          ]),
        ),
        Text('Tip: el botón \$ envía ${formatearPesos(5000)} sin salir del chat.', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
      ]),
    );
  }
}