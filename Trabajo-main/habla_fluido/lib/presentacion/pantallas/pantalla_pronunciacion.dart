import 'package:flutter/material.dart';

import '../../dependencias.dart';
import '../vm/pronunciacion_vm.dart';
import 'widgets.dart';

class PantallaPronunciacion extends StatefulWidget {
  final Dependencias deps;
  const PantallaPronunciacion({super.key, required this.deps});
  @override
  State<PantallaPronunciacion> createState() => _EstadoPantalla();
}

class _EstadoPantalla extends State<PantallaPronunciacion> {

  late final PronunciacionViewModel vm = PronunciacionViewModel(widget.deps.voz, widget.deps.aprendizaje);

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pronunciación (shadowing)')),
        body: ListenableBuilder(
          listenable: vm,
          builder: (context, _) {
            final f = vm.actual;
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text(f.ingles, style: Theme.of(context).textTheme.headlineMedium),
              Text(f.espanol),
              const SizedBox(height: 8),
              Text('Foco: ${f.foco}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(' ${f.consejo}'),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                OutlinedButton.icon(
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Escuchar'),
                    onPressed: vm.ocupado ? null : () => vm.escucharModelo()),
                OutlinedButton.icon(
                    icon: const Icon(Icons.slow_motion_video),
                    label: const Text('Lento'),
                    onPressed: vm.ocupado ? null : () => vm.escucharModelo(lento: true)),
                FilledButton.icon(
                    icon: const Icon(Icons.mic),
                    label: Text(vm.ocupado ? 'Escuchando…' : 'Repetir'),
                    onPressed: vm.ocupado ? null : vm.grabar),
              ]),
              const SizedBox(height: 12),
              Aviso(vm.error),
              if (vm.resultado != null) ...[
                Text('Te entendí: "${vm.escuchado}"'),
                const SizedBox(height: 8),
                PalabrasColoreadas(vm.resultado!),
                TextButton(onPressed: vm.siguiente, child: const Text('Siguiente frase')),
              ],
              const SizedBox(height: 16),

              const Text('Nota: la app mide si el reconocedor de voz te entendió. Es una guía de inteligibilidad, '
                  'no un examen de acento.', style: TextStyle(fontStyle: FontStyle.italic)),
            ]);
          },
        ),
      );
}