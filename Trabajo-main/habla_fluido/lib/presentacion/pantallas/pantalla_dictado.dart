import 'package:flutter/material.dart';

import '../../dependencias.dart';
import '../vm/dictado_vm.dart';
import 'widgets.dart';

class PantallaDictado extends StatefulWidget {
  final Dependencias deps;
  const PantallaDictado({super.key, required this.deps});
  @override
  State<PantallaDictado> createState() => _EstadoPantalla();
}

class _EstadoPantalla extends State<PantallaDictado> {
  late final DictadoViewModel vm = DictadoViewModel(widget.deps.voz, widget.deps.aprendizaje);
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Oído: dictado')),
        body: ListenableBuilder(
          listenable: vm,
          builder: (context, _) => ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Escucha la frase y escribe exactamente lo que entiendas.'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              FilledButton.icon(
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Escuchar'),
                  onPressed: vm.ocupado ? null : () => vm.reproducir()),
              OutlinedButton.icon(
                  icon: const Icon(Icons.slow_motion_video),
                  label: const Text('Lento'),
                  onPressed: vm.ocupado ? null : () => vm.reproducir(lento: true)),
            ]),
            Text('Reproducciones: ${vm.reproducciones}'),
            const SizedBox(height: 8),
            TextField(
              controller: _texto,

              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Lo que escuché'),
            ),
            const SizedBox(height: 8),

            FilledButton(onPressed: () => vm.enviar(_texto.text), child: const Text('Comprobar')),
            Aviso(vm.error),
            if (vm.resultado != null) ...[
              const SizedBox(height: 8),

              Text('Correcta: ${vm.actual.ingles}', style: const TextStyle(fontWeight: FontWeight.bold)),
              PalabrasColoreadas(vm.resultado!),
              TextButton(
                  onPressed: () {
                    _texto.clear();
                    vm.siguiente();
                  },
                  child: const Text('Siguiente')),
            ],
          ]),
        ),
      );
}