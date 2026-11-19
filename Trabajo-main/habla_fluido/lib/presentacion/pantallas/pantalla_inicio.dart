import 'package:flutter/material.dart';

import '../../dependencias.dart';
import '../../dominio/nivel.dart';
import 'pantalla_conversacion.dart';
import 'pantalla_dictado.dart';
import 'pantalla_escritura.dart';
import 'pantalla_lectura.dart';
import 'pantalla_pronunciacion.dart';
import 'pantalla_repaso.dart';

class PantallaInicio extends StatelessWidget {
  final Dependencias deps;
  const PantallaInicio({super.key, required this.deps});


  void _ir(BuildContext c, Widget w) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));

  Widget _destino(Habilidad h) => switch (h) {
        Habilidad.escucha => PantallaDictado(deps: deps),
        Habilidad.pronunciacion => PantallaPronunciacion(deps: deps),
        Habilidad.lectura => PantallaLectura(deps: deps),
        Habilidad.escritura => PantallaEscritura(deps: deps),
        Habilidad.conversacion => PantallaConversacion(deps: deps),
      };

  @override
  Widget build(BuildContext context) {
    final vm = deps.aprendizaje;
    return Scaffold(
      appBar: AppBar(title: const Text('Habla Fluido')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => ListView(padding: const EdgeInsets.all(16), children: [
          Text('Nivel ${vm.nivel.etiqueta} · Racha: ${vm.progreso.racha} día(s)',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (vm.puedeSubirDeNivel)
            Card(
              child: ListTile(
                title: const Text(' ¡Dominas este nivel!'),
                subtitle: Text('Pasa a ${vm.nivel.siguiente!.etiqueta}'),

                trailing: FilledButton(onPressed: vm.subirDeNivel, child: const Text('Subir')),
              ),
            ),
          const SizedBox(height: 8),
          Text('Plan de hoy (${vm.plan.fold<int>(0, (a, b) => a + b.minutos)} min)',
              style: Theme.of(context).textTheme.titleMedium),
          for (final b in vm.plan)
            Card(
              child: ListTile(

                title: Text('${b.habilidad.nombre} · ${b.minutos} min${b.esRefuerzo ? " refuerzo" : ""}'),
                subtitle: LinearProgressIndicator(value: vm.progreso.dominioDe(b.habilidad)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _ir(context, _destino(b.habilidad)),
              ),
            ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.replay),
              title: Text('Repaso espaciado: ${vm.pendientes.length} pendiente(s)'),
              onTap: () => _ir(context, PantallaRepaso(deps: deps)),
            ),
          ),
        ]),
      ),
    );
  }
}