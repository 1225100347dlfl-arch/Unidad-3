import 'package:flutter/material.dart';

import '../../dependencias.dart';
import '../vm/repaso_vm.dart';

class PantallaRepaso extends StatefulWidget {
  final Dependencias deps;
  const PantallaRepaso({super.key, required this.deps});
  @override
  State<PantallaRepaso> createState() => _EstadoPantalla();
}

class _EstadoPantalla extends State<PantallaRepaso> {
  late final RepasoViewModel vm = RepasoViewModel(widget.deps.aprendizaje, widget.deps.voz);

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Repaso espaciado')),
        body: ListenableBuilder(
          listenable: vm,
          builder: (context, _) {
            final t = vm.actual;

            if (t == null) return const Center(child: Text(' No tienes repasos pendientes hoy.'));
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text('Quedan ${vm.restantes}'),
              const SizedBox(height: 12),
              Text('Dilo en inglés:', style: Theme.of(context).textTheme.titleMedium),
              Text(t.traduccion, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              if (!vm.respuestaVisible)

                FilledButton(onPressed: vm.mostrarRespuesta, child: const Text('Ver y escuchar respuesta'))
              else ...[
                Text(t.frase, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                const Text('¿Qué tan bien la recordaste?'),
                Wrap(spacing: 8, children: [

                  OutlinedButton(onPressed: () => vm.calificar(1), child: const Text('Otra vez')),

                  OutlinedButton(onPressed: () => vm.calificar(3), child: const Text('Difícil')),
                  FilledButton(onPressed: () => vm.calificar(4), child: const Text('Bien')),
                  FilledButton(onPressed: () => vm.calificar(5), child: const Text('Fácil')),
                ]),
              ],
            ]);
          },
        ),
      );
}