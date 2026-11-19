import 'package:flutter/material.dart';

import '../../dominio/contexto.dart';
import '../../dominio/dinero.dart';
import '../vm/tienda_vm.dart';
import 'widgets.dart';

class PantallaTienda extends StatefulWidget {
  final ContextoMiniApp contexto;
  final VoidCallback alCambiar;
  const PantallaTienda({super.key, required this.contexto, required this.alCambiar});
  @override
  State<PantallaTienda> createState() => _EstadoPantalla();
}

class _EstadoPantalla extends State<PantallaTienda> {
  late final TiendaViewModel vm = TiendaViewModel(widget.contexto, alCambiar: widget.alCambiar);

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final t = vm.tienda;
          return Scaffold(
            appBar: AppBar(
              title: Text(t == null ? 'Negocios de Dolores' : t.nombre),
              leading: t == null ? null : IconButton(icon: const Icon(Icons.arrow_back), onPressed: vm.volver),
            ),
            body: t == null
                ? ListView(children: [
                    for (final x in vm.tiendas)
                      ListTile(leading: Text(x.emoji, style: const TextStyle(fontSize: 28)), title: Text(x.nombre), onTap: () => vm.elegirTienda(x)),
                  ])
                : ListView(padding: const EdgeInsets.all(12), children: [
                    for (final p in t.productos)
                      ListTile(
                        title: Text(p.nombre),
                        subtitle: Text('${formatearPesos(p.precioCentavos)} · quedan ${p.existencias}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => vm.cambiar(p.id, -1)),
                          Text('${vm.carrito[p.id] ?? 0}'),
                          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => vm.cambiar(p.id, 1)),
                        ]),
                      ),
                    Aviso(vm.error),
                    if (vm.ultimoPedido != null)
                      Card(child: ListTile(title: Text('🧾 Pedido ${vm.ultimoPedido!.id}'), subtitle: Text('Total ${formatearPesos(vm.ultimoPedido!.totalCentavos)}'))),
                    FilledButton(
                      onPressed: vm.carrito.isEmpty || vm.ocupado ? null : vm.comprar,
                      child: Text('Pagar con monedero ${formatearPesos(vm.total)}'),
                    ),
                  ]),
          );
        },
      );
}