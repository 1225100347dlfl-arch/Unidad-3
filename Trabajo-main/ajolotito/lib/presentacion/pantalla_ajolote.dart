import 'package:flutter/material.dart';

import '../dominio/gestor_permiso.dart';
import '../dominio/mascota.dart';
import 'ajolote_vm.dart';
import 'dibujo_ajolote.dart';
import 'pantalla_ajustes.dart';

class PantallaAjolote extends StatelessWidget {
  const PantallaAjolote({super.key, required this.vm});
  final AjoloteViewModel vm;

  String _textoHumor(Humor h) => switch (h) {
        Humor.feliz => 'Feliz y con la pancita llena',
        Humor.hambriento => 'Tiene hambre',
        Humor.famelico => '¡Está famélico!',
      };

  /// Pre-permiso: explica el VALOR antes de que salga el diálogo del sistema.
  Future<void> _activarAvisos(BuildContext context) async {
    final acepta = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Te avisamos cuando tenga hambre?'),
        content: const Text(
            'Solo te escribiremos cuando tu ajolote necesite comer, y una sorpresa por la tarde. '
            'Nada de madrugadas (silencio de 10 pm a 8 am) y puedes apagarlo cuando quieras.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Ahora no')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sí, avísame')),
        ],
      ),
    );
    if (acepta != true) return; // no gastamos el permiso si el usuario dijo "ahora no"

    final r = await vm.activarAvisos();
    if (r == ResultadoPermiso.hayQueIrAAjustes && context.mounted) {
      final ir = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Los avisos están apagados'),
          content: const Text('Puedes activarlos en los ajustes del sistema.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Abrir ajustes')),
          ],
        ),
      );
      if (ir == true) await vm.abrirAjustes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (!vm.listo) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final s = vm.saciedad;
        return Scaffold(
          appBar: AppBar(
            title: Text('Ajolotito · ${vm.nombre}'),
            actions: [
              IconButton(
                tooltip: 'Ajustes de avisos',
                icon: const Icon(Icons.tune),
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => PantallaAjustes(vm: vm))),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(child: DibujoAjolote(humor: vm.humor)),
              const SizedBox(height: 8),
              Center(child: Text(_textoHumor(vm.humor), style: Theme.of(context).textTheme.titleMedium)),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: s / 100, minHeight: 14, borderRadius: BorderRadius.circular(8)),
              const SizedBox(height: 4),
              Text('Saciedad: ${s.toStringAsFixed(0)} / 100', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              if (vm.aviso != null)
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(padding: const EdgeInsets.all(12), child: Text(vm.aviso!)),
                ),
              FilledButton.icon(
                style: vm.resaltarAlimentar
                    ? FilledButton.styleFrom(backgroundColor: Colors.deepOrange)
                    : null,
                onPressed: vm.alimentar,
                icon: const Text('🍤'),
                label: const Text('Dar de comer'),
              ),
              const SizedBox(height: 16),
              _TarjetaAvisos(vm: vm, alActivar: () => _activarAvisos(context)),
            ],
          ),
        );
      },
    );
  }
}

class _TarjetaAvisos extends StatelessWidget {
  const _TarjetaAvisos({required this.vm, required this.alActivar});
  final AjoloteViewModel vm;
  final VoidCallback alActivar;

  String _hora(DateTime t) =>
      '${t.day}/${t.month} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final activo = vm.permiso == EstadoPermiso.concedido;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Avisos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (!activo)
            OutlinedButton.icon(
              onPressed: alActivar,
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text(vm.permiso == EstadoPermiso.denegado
                  ? 'Avisos apagados · cómo activarlos'
                  : 'Avísame cuando tenga hambre'),
            )
          else ...[
            const Text('✅ Avisos activados. Próximos programados:'),
            const SizedBox(height: 4),
            if (vm.programadas.isEmpty)
              const Text('Ninguno por ahora (se programan cuando sales de la app).')
            else
              for (final p in vm.programadas) Text('• ${_hora(p.cuando)} — ${p.titulo}'),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: vm.probarAhora,
              icon: const Icon(Icons.bolt),
              label: const Text('Probar una notificación ahora'),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Modo clase (1 hora = 1 minuto)'),
            subtitle: const Text('Para ver los avisos en minutos. Sal de la app para recibirlos.'),
            value: vm.modoClase,
            onChanged: vm.cambiarModoClase,
          ),
        ]),
      ),
    );
  }
}