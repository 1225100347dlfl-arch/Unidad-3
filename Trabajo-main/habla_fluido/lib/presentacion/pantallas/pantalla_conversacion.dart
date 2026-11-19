import 'package:flutter/material.dart';

import '../../dependencias.dart';
import '../vm/conversacion_vm.dart';
import 'widgets.dart';

class PantallaConversacion extends StatefulWidget {
  final Dependencias deps;
  const PantallaConversacion({super.key, required this.deps});
  @override
  State<PantallaConversacion> createState() => _EstadoPantalla();
}

class _EstadoPantalla extends State<PantallaConversacion> {
  late final ConversacionViewModel vm =

      ConversacionViewModel(widget.deps.tutor, widget.deps.voz, widget.deps.aprendizaje)..iniciar();
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    vm.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final t = _texto.text;
    _texto.clear();
    await vm.enviar(t);
    if (vm.textoNoEnviado != null) _texto.text = vm.textoNoEnviado!;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Conversación'), actions: [
          ListenableBuilder(
            listenable: vm,
            builder: (_, __) => IconButton(
              tooltip: 'Voz del tutor',
              icon: Icon(vm.autoVoz ? Icons.volume_up : Icons.volume_off),
              onPressed: vm.alternarAutoVoz,
            ),
          ),
        ]),
        body: ListenableBuilder(
          listenable: vm,
          builder: (context, _) => Column(children: [
            Expanded(
              child: ListView(padding: const EdgeInsets.all(12), children: [
                for (final m in vm.historial)
                  Align(
                    alignment: m.delEstudiante ? Alignment.centerRight : Alignment.centerLeft,
                    child: Card(

                      color: m.delEstudiante ? Theme.of(context).colorScheme.primaryContainer : null,
                      child: Padding(padding: const EdgeInsets.all(10), child: Text(m.texto)),
                    ),
                  ),
                for (final c in vm.ultimasCorrecciones)
                  Card(
                    color: Colors.amber.shade100,
                    child: ListTile(
                      dense: true,
                      title: Text(' ${c.original} → ${c.corregido}'),
                      subtitle: Text(c.explicacion),
                    ),
                  ),
                Aviso(vm.error),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.mic), onPressed: vm.ocupado ? null : vm.dictar),
                Expanded(
                  child: TextField(
                    controller: _texto,
                    maxLength: ConversacionViewModel.maxCaracteres,

                    decoration: const InputDecoration(hintText: 'Type or tap the mic…', counterText: ''),
                    onSubmitted: (_) => _enviar(),
                  ),
                ),

                IconButton(icon: const Icon(Icons.send), onPressed: vm.ocupado ? null : _enviar),
              ]),
            ),
          ]),
        ),
      );
}