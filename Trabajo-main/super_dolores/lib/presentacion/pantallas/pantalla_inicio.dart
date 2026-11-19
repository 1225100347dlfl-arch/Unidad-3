import 'package:flutter/material.dart';

import '../../dominio/dinero.dart';
import '../../dominio/lealtad.dart';
import '../../dominio/plataforma.dart';
import '../vm/inicio_vm.dart';
import 'pantalla_horoscopo.dart';
import 'pantalla_metricas.dart';

class PantallaInicio extends StatelessWidget {
  final InicioViewModel vm;
  const PantallaInicio({super.key, required this.vm});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Super Dolores'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.switch_account),
              tooltip: 'Cambiar de persona (demo)',
              onSelected: vm.cambiarUsuario,
              itemBuilder: (_) => [
                for (final p in vm.plataforma.perfiles) PopupMenuItem(value: p.id, child: Text(p.nombre)),
              ],
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: vm,
          builder: (context, _) {
            final s = vm.sugerencia;
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text('Hola, ${vm.plataforma.perfiles.firstWhere((p) => p.id == vm.usuarioId).nombre} 👋',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: Text(formatearPesos(vm.saldo), style: Theme.of(context).textTheme.headlineSmall),
                  subtitle: const Text('Saldo de práctica (no es dinero real)'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.workspace_premium),
                  title: Text('${vm.puntos} puntos · Nivel ${vm.nivel.nombre}'),
                  subtitle: Text('🔥 Racha: ${vm.racha} día(s)  ·  ${Lealtad.puntosPorCanje} pts = ${formatearPesos(Lealtad.centavosPorCanje)}'),
                  trailing: TextButton(
                    onPressed: vm.puntos >= Lealtad.puntosPorCanje
                        ? () {
                            final c = vm.canjearTodo();
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Canjeaste ${formatearPesos(c)}')));
                          }
                        : null,
                    child: const Text('Canjear'),
                  ),
                ),
              ),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: ListTile(
                  leading: Text(s.servicio.emoji, style: const TextStyle(fontSize: 28)),
                  title: const Text('Para ti'),
                  subtitle: Text(s.razon),
                ),
              ),
              const SizedBox(height: 8),
              Text('Servicios', style: Theme.of(context).textTheme.titleMedium),
              Wrap(spacing: 8, children: [
                for (final a in vm.miniApps) Chip(avatar: Text(a.emoji), label: Text(a.nombre)),
              ]),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.query_stats),
                label: const Text('Tablero de retención (datos simulados)'),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PantallaMetricas())),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.security),
                label: const Text('Mini-app de un tercero (probar permisos)'),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PantallaHoroscopo(plataforma: vm.plataforma, usuarioId: vm.usuarioId))),
              ),
              if (vm.plataforma.registro.estaActiva(Plataforma.miniViajes.id))
                TextButton(
                  onPressed: () {
                    vm.plataforma.registro.apagar(Plataforma.miniViajes.id);
                    vm.notificar();
                  },
                  child: const Text('Simular falla: apagar Viajes (kill switch)'),
                )
              else
                TextButton(
                  onPressed: () {
                    vm.plataforma.registro.encender(Plataforma.miniViajes.id);
                    vm.notificar();
                  },
                  child: const Text('Volver a encender Viajes'),
                ),
            ]);
          },
        ),
      );
}