import 'package:dolores_rally/datos/fuentes_simuladas.dart';
import 'package:dolores_rally/dominio/geo.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas.dart';

void main() {
  group('PosicionSimulada (modo demo: "caminar" en el salón)', () {
    test('primero entrega la posición inicial', () async {
      final sim = PosicionSimulada(origen);
      final primera = await sim.posiciones.first;
      expect(primera.lat, origen.lat);
      expect(primera.lon, origen.lon);
    });

    test('avanzar 10 m hacia el norte te mueve 10 m con rumbo 0°', () async {
      final sim = PosicionSimulada(origen);
      final lista = <Coordenada>[];
      final sub = sim.posiciones.listen(lista.add);
      await pumpEventQueue();
      sim.avanzar(0, 10);
      await pumpEventQueue();
      expect(lista, hasLength(2));
      expect(distanciaMetros(lista[0], lista[1]), closeTo(10, 0.01));
      expect(diferenciaAngular(rumboGrados(lista[0], lista[1]), 0).abs(), lessThan(0.01));
      await sub.cancel();
      sim.cerrar();
    });

    test('metros negativos = retroceder (rumbo + 180°)', () async {
      final sim = PosicionSimulada(origen);
      final lista = <Coordenada>[];
      final sub = sim.posiciones.listen(lista.add);
      await pumpEventQueue();
      sim.avanzar(90, -10); // mirando al este, retrocede = ir al oeste
      await pumpEventQueue();
      expect(distanciaMetros(lista[0], lista[1]), closeTo(10, 0.01));
      expect(diferenciaAngular(rumboGrados(lista[0], lista[1]), 270).abs(), lessThan(0.01));
      await sub.cancel();
      sim.cerrar();
    });
  });

  group('BrujulaSimulada', () {
    test('entrega el rumbo inicial (0°) y luego cada giro', () async {
      final b = BrujulaSimulada();
      final lista = <double>[];
      final sub = b.rumbos.listen(lista.add);
      await pumpEventQueue();
      b.girar(90);
      b.girar(200);
      await pumpEventQueue();
      expect(lista, [0, 90, 200]);
      await sub.cancel();
      b.cerrar();
    });

    test('quien se suscribe tarde recibe el último rumbo', () async {
      final b = BrujulaSimulada();
      b.girar(135);
      expect(await b.rumbos.first, 135);
      b.cerrar();
    });
  });
}
