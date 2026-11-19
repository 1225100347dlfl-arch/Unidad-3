import 'package:flutter/material.dart';

import '../../dependencias.dart';
import '../vm/escritura_vm.dart';
import 'widgets.dart';

class PantallaEscritura extends StatefulWidget {
  final Dependencias deps;
  const PantallaEscritura({super.key, required this.deps});
  @override
  State<PantallaEscritura> createState() => _EstadoPantalla();
}

class _EstadoPantalla extends State<PantallaEscritura> {

  late final EscrituraViewModel vm = EscrituraViewModel(widget.deps.tutor, widget.deps.aprendizaje);
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Escritura')),
        body: ListenableBuilder(
          listenable: vm,
          builder: (context, _) {
            final r = vm.resultado;
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text(vm.tema, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _texto,
                maxLines: 6,
                maxLength: 500,

                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Write here…'),
              ),
              FilledButton(
                onPressed: vm.ocupado ? null : () => vm.enviar(_texto.text),
                child: Text(vm.ocupado ? 'Revisando…' : 'Pedir corrección'),
              ),
              Aviso(vm.error),
              if (r != null) ...[
                const SizedBox(height: 12),
                Text(r.respuesta, style: Theme.of(context).textTheme.titleMedium),
                for (final c in r.correcciones)
                  Card(
                    child: ListTile(
                      title: Text('${c.original} → ${c.corregido}'),
                      subtitle: Text(c.explicacion),
                    ),
                  ),
                if (r.textoCorregido != null) ...[

                  const Text('Versión corregida:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(r.textoCorregido!),
                ],
                if (r.siguientePregunta != null) Text('\nReto: ${r.siguientePregunta}'),
              ],
            ]);
          },
        ),
      );
}