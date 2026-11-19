import 'package:flutter/material.dart';

import '../vm/metricas_vm.dart';

class PantallaMetricas extends StatefulWidget {
  const PantallaMetricas({super.key});
  @override
  State<PantallaMetricas> createState() => _EstadoPantalla();
}

class _EstadoPantalla extends State<PantallaMetricas> {
  late final MetricasViewModel vm = MetricasViewModel(DateTime(2026, 1, 1));

  String _pct(double v) => '${(v * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final c = vm.comparacion;
    return Scaffold(
      appBar: AppBar(title: const Text('Tablero de retención')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text('🧪 Datos SIMULADOS con semilla fija (200 usuarios inventados). Sirven para aprender a leer las métricas, no para sacar conclusiones reales.'),
          ),
        ),
        ListTile(title: const Text('DAU (activos hoy)'), trailing: Text('${vm.dau}')),
        ListTile(title: const Text('WAU (últimos 7 días)'), trailing: Text('${vm.wau}')),
        ListTile(title: const Text('MAU (últimos 30 días)'), trailing: Text('${vm.mau}')),
        ListTile(title: const Text('Stickiness DAU/MAU'), trailing: Text(_pct(vm.stickiness))),
        ListTile(title: const Text('Retención D1 (promedio)'), trailing: Text(_pct(vm.retencionPromedio(1)))),
        ListTile(title: const Text('Retención D7 (promedio)'), trailing: Text(_pct(vm.retencionPromedio(7)))),
        ListTile(title: const Text('Servicios por usuario'), trailing: Text(vm.serviciosPorUsuario.toStringAsFixed(2))),
        ListTile(title: const Text('% usuarios multiservicio'), trailing: Text(_pct(vm.multiservicio))),
        const Divider(),
        Text('Semana 2 según servicios usados en la semana 1', style: Theme.of(context).textTheme.titleMedium),
        ListTile(title: Text('1 servicio (n=${c.nUno})'), trailing: Text(_pct(c.unServicio))),
        ListTile(title: Text('2 o más servicios (n=${c.nMulti})'), trailing: Text(_pct(c.multiservicio))),
        const Text('Cuidado: es una correlación. Quien está motivado prueba más servicios Y se queda más; '
            'no sabemos si usar más servicios CAUSA quedarse. Para saberlo hace falta un experimento controlado (prueba A/B).',
            style: TextStyle(fontStyle: FontStyle.italic)),
      ]),
    );
  }
}