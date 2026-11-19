import 'package:flutter/material.dart';

import '../../dominio/contexto.dart';
import '../../dominio/dinero.dart';
import '../../dominio/transporte.dart';
import '../vm/viajes_vm.dart';
import 'widgets.dart';

class PantallaViajes extends StatefulWidget {
  final ContextoMiniApp contexto;
  final VoidCallback alCambiar;
  const PantallaViajes({super.key, required this.contexto, required this.alCambiar});
  @override
  State<PantallaViajes> createState() => _EstadoPantalla();
}

class _EstadoPantalla extends State<PantallaViajes> {
  late final ViajesViewModel vm = ViajesViewModel(widget.contexto, alCambiar: widget.alCambiar);

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  Widget _selector(String etiqueta, Lugar valor, void Function(Lugar) alElegir) => DropdownButtonFormField<Lugar>(
        value: valor,
        decoration: InputDecoration(labelText: etiqueta, border: const OutlineInputBorder()),
        items: [for (final l in lugaresDolores) DropdownMenuItem(value: l, child: Text(l.nombre))],
        onChanged: (l) => l == null ? null : alElegir(l),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Viajes')),
        body: ListenableBuilder(
          listenable: vm,
          builder: (context, _) {
            final v = vm.actual;
            final activo = v != null && v.estado != EstadoViaje.finalizado && v.estado != EstadoViaje.cancelado;
            return ListView(padding: const EdgeInsets.all(16), children: [
              _selector('Origen', vm.origen, (l) => vm.elegir(nuevoOrigen: l)),
              const SizedBox(height: 12),
              _selector('Destino', vm.destino, (l) => vm.elegir(nuevoDestino: l)),
              const SizedBox(height: 12),
              Text('${vm.distancia.toStringAsFixed(1)} km · estimado ${formatearPesos(vm.estimado)}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (!activo) FilledButton(onPressed: vm.solicitar, child: const Text('Pedir viaje')),
              Aviso(vm.error),
              if (v != null) ...[
                const Divider(),
                Text('Estado: ${v.estado.name}', style: Theme.of(context).textTheme.titleMedium),
                if (v.cobradoCentavos != null) Text('Cobrado: ${formatearPesos(v.cobradoCentavos!)}'),
                Wrap(spacing: 8, children: [
                  if (v.estado == EstadoViaje.solicitado) OutlinedButton(onPressed: vm.conductorAcepta, child: const Text('(Simular) conductor acepta')),
                  if (v.estado == EstadoViaje.aceptado) OutlinedButton(onPressed: vm.iniciar, child: const Text('(Simular) iniciar')),
                  if (v.estado == EstadoViaje.enCurso) FilledButton(onPressed: vm.finalizar, child: const Text('(Simular) llegar y pagar')),
                  if (v.estado == EstadoViaje.solicitado || v.estado == EstadoViaje.aceptado)
                    TextButton(onPressed: vm.cancelar, child: const Text('Cancelar')),
                ]),
              ],
              const Divider(),
              Text('Historial', style: Theme.of(context).textTheme.titleMedium),
              for (final h in vm.historial) ListTile(dense: true, title: Text(h.id), subtitle: Text(h.estado.name)),
            ]);
          },
        ),
      );
}