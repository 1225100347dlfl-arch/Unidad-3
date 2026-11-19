import 'dart:math';

import 'package:dolores_rally/dominio/aparicion.dart';
import 'package:dolores_rally/dominio/catalogo.dart';
import 'package:dolores_rally/dominio/geo.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas.dart';

void main() {
  test('genera una aparición por personaje', () {
    final a = generarApariciones(centro: origen, personajes: personajes, random: Random(1));
    expect(a.length, personajes.length);
    expect(a.map((x) => x.personaje.id).toSet().length, personajes.length);
  });

  test('todas quedan entre el radio mínimo y el máximo', () {
    final a = generarApariciones(
        centro: origen, personajes: personajes, random: Random(7), radioMin: 60, radioMax: 500);
    for (final x in a) {
      final d = distanciaMetros(origen, x.coordenada);
      expect(d, inInclusiveRange(59.9, 500.1));
    }
  });

  test('con la misma semilla el "azar" se repite (pruebas confiables)', () {
    final a = generarApariciones(centro: origen, personajes: personajes, random: Random(42));
    final b = generarApariciones(centro: origen, personajes: personajes, random: Random(42));
    for (var i = 0; i < a.length; i++) {
      expect(a[i].coordenada.lat, b[i].coordenada.lat);
      expect(a[i].coordenada.lon, b[i].coordenada.lon);
    }
  });

  test('con semillas distintas los lugares son distintos', () {
    final a = generarApariciones(centro: origen, personajes: personajes, random: Random(1));
    final b = generarApariciones(centro: origen, personajes: personajes, random: Random(2));
    expect(a.first.coordenada.lat, isNot(b.first.coordenada.lat));
  });

  test('los puntos se reparten por TODAS las direcciones', () {
    final r = Random(5);
    final rumbos = [
      for (var i = 0; i < 400; i++) rumboGrados(origen, puntoAleatorio(origen, 60, 500, r))
    ];
    for (final cuadrante in [0, 90, 180, 270]) {
      expect(rumbos.where((g) => g >= cuadrante && g < cuadrante + 90).length, greaterThan(60),
          reason: 'cuadrante $cuadrante');
    }
  });

  // Pregunta de clase 27: sin la raíz cuadrada se amontonan cerca del centro.
  test('con raíz cuadrada, ~30% de los puntos cae a menos de 280 m (reparto por área)', () {
    final r = Random(11);
    const n = 2000;
    final cerca = [
      for (var i = 0; i < n; i++) distanciaMetros(origen, puntoAleatorio(origen, 60, 500, r))
    ].where((d) => d < 280).length;
    // Teoría: (280²−60²)/(500²−60²) ≈ 0.304. Sin raíz sería 0.50.
    expect(cerca / n, closeTo(0.304, 0.05));
  });

  // RETO Ronda 3: ¿se rompe algo con más personajes? No: las pruebas usan .length.
  test('el motor funciona igual con los 8 personajes (6 + 2 extra)', () {
    final a = generarApariciones(
        centro: origen, personajes: personajesExtendidos, random: Random(3));
    expect(a.length, 8);
    expect(a.map((x) => x.personaje.id).toSet().length, 8);
  });

  // RETO Ronda 4: separación mínima entre personajes.
  group('separación mínima (reto)', () {
    test('con separacionMin 30 ningún par queda a menos de 30 m', () {
      for (final semilla in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) {
        final a = generarApariciones(
            centro: origen,
            personajes: personajes,
            random: Random(semilla),
            separacionMin: 30);
        for (var i = 0; i < a.length; i++) {
          for (var j = i + 1; j < a.length; j++) {
            expect(distanciaMetros(a[i].coordenada, a[j].coordenada), greaterThanOrEqualTo(30),
                reason: 'semilla $semilla, par $i-$j');
          }
        }
      }
    });

    test('una regla imposible NO cuelga el juego: se rinde tras maxIntentos', () {
      // Anillo de 1 m de ancho y 6 personajes separados 1000 m: imposible.
      final a = generarApariciones(
          centro: origen,
          personajes: personajes,
          random: Random(1),
          radioMin: 60,
          radioMax: 61,
          separacionMin: 1000,
          maxIntentos: 20);
      expect(a.length, personajes.length); // devolvió a todos, sin quedarse en un ciclo
    });

    test('con separacionMin 0 el resultado es el mismo que sin la regla', () {
      final sin = generarApariciones(centro: origen, personajes: personajes, random: Random(42));
      final con = generarApariciones(
          centro: origen, personajes: personajes, random: Random(42), separacionMin: 0);
      for (var i = 0; i < sin.length; i++) {
        expect(sin[i].coordenada.lat, con[i].coordenada.lat);
      }
    });
  });
}
