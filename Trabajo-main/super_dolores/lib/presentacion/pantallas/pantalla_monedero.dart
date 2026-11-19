import 'package:flutter/material.dart';

import '../../dominio/contexto.dart';
import '../../dominio/dinero.dart';
import '../../dominio/monedero.dart';
import '../../dominio/plataforma.dart';
import '../vm/monedero_vm.dart';
import 'widgets.dart';

class PantallaMonedero extends StatefulWidget {
  final ContextoMiniApp contexto;
  final VoidCallback alCambiar;
  final Plataforma plataforma;
  const PantallaMonedero({super.key, required this.contexto, required this.alCambiar, required this.plataforma});
  @override
  State<PantallaMonedero> createState() => _EstadoPantalla();
}

class _EstadoPantalla extends State<PantallaMonedero> {
  late final MonederoViewModel vm = MonederoViewModel(widget.contexto, alCambiar: widget.alCambiar);
  final _monto = TextEditingController(text: '100');
  String? _para;

  @override
  void dispose() {
    _monto.dispose();
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otros = widget.plataforma.perfiles.where((p) => p.id != widget.contexto.usuarioId).toList();
    _para ??= otros.first.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Monedero')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => ListView(padding: const EdgeInsets.all(16), children: [
          Text(formatearPesos(vm.saldo), style: Theme.of(context).textTheme.displaySmall),
          const Text('Saldo de práctica. En producción exige una entidad financiera autorizada.'),
          const SizedBox(height: 12),
          Row(children: [
            DropdownButton<String>(
              value: _para,
              items: [for (final p in otros) DropdownMenuItem(value: p.id, child: Text(p.nombre))],
              onChanged: (v) => setState(() => _para = v),
            ),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _monto, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '\$ '))),
            FilledButton(
              onPressed: vm.ocupado
                  ? null
                  : () {
                      final pesos = int.tryParse(_monto.text) ?? 0;
                      vm.enviarDinero(_para!, pesos * 100);
                    },
              child: const Text('Enviar'),
            ),
          ]),
          Aviso(vm.error),
          if (vm.exito != null) Text('✅ ${vm.exito}'),
          const Divider(),
          for (final m in vm.movimientos)
            ListTile(
              dense: true,
              leading: Icon(m.montoCentavos >= 0 ? Icons.arrow_downward : Icons.arrow_upward,
                  color: m.montoCentavos >= 0 ? Colors.green : Colors.red),
              title: Text(m.concepto),
              subtitle: Text(m.tipo.name),
              trailing: Text(formatearPesos(m.montoCentavos)),
            ),
        ]),
      ),
    );
  }
}