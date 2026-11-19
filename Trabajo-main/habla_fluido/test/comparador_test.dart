import 'package:flutter_test/flutter_test.dart';
import 'package:habla_fluido/dominio/comparador.dart';

List<EstadoPalabra> estados(ResultadoComparacion r) => [for (final p in r.palabras) p.estado];

void main() {
  group('normalizar', () {
    test('minúsculas, sin puntuación, conserva apóstrofos', () {
      expect(normalizar("Don't worry, be HAPPY!"), ["don't", 'worry', 'be', 'happy']);
    });
    test('apóstrofo tipográfico', () => expect(normalizar('don’t'), ["don't"]));
    test('espacios múltiples y vacío', () {
      expect(normalizar(' a b '), ['a', 'b']);
      expect(normalizar(''), isEmpty);
    });
  });

  group('distancia y similitud', () {
    test('Levenshtein clásico', () {
      expect(distanciaLevenshtein('ship', 'sheep'), 2);
      expect(distanciaLevenshtein('kitten', 'sitting'), 3);
      expect(distanciaLevenshtein('', 'abc'), 3);
      expect(distanciaLevenshtein('igual', 'igual'), 0);
    });
    test('similitud 0..1', () {
      expect(similitud('think', 'tink'), closeTo(0.8, 1e-9));
      expect(similitud('ship', 'sheep'), closeTo(0.6, 1e-9));
      expect(similitud('', ''), 1.0);
    });
  });

  group('comparar', () {
    test('idéntico (ignora mayúsculas y signos) = 100%', () {
      final r = comparar('Where is the bathroom?', 'where is the bathroom');
      expect(r.puntaje, 1.0);
      expect(r.aprobado, isTrue);
      expect(r.porPracticar, isEmpty);
    });
    test('par mínimo ship/sheep + think/tink', () {
      final r = comparar('I think the ship is big', 'i tink the sheep is big');
      expect(estados(r), [
        EstadoPalabra.correcta, EstadoPalabra.parecida, EstadoPalabra.correcta,
        EstadoPalabra.sustituida, EstadoPalabra.correcta, EstadoPalabra.correcta,
      ]);
      expect(r.puntaje, closeTo(0.75, 1e-9));
      expect(r.aprobado, isFalse);
      expect(r.porPracticar, ['think', 'ship']);
    });
    test('palabra omitida', () {
      final r = comparar('I want to go home', 'i want go home');
      expect(estados(r)[2], EstadoPalabra.omitida);
      expect(r.puntaje, closeTo(0.8, 1e-9));
      expect(r.aprobado, isTrue); // justo en el umbral
    });
    test('palabra sobrante resta 0.25', () {
      final r = comparar('Hello world', 'hello big world');

      expect(estados(r), [EstadoPalabra.correcta, EstadoPalabra.sobrante, EstadoPalabra.correcta]);
      expect(r.puntaje, closeTo(0.875, 1e-9));
    });
    test('no dijo nada = 0 y todo omitido', () {
      final r = comparar('I like coffee', '');
      expect(r.puntaje, 0);
      expect(estados(r), everyElement(EstadoPalabra.omitida));
    });

    test('esperado vacío no divide entre cero', () => expect(comparar('', 'hola').puntaje, 0));
    test('el puntaje nunca baja de 0 ni pasa de 1', () {
      expect(comparar('hi', 'a b c d e f g').puntaje, 0);
      expect(comparar('hi there', 'hi there').puntaje, 1);
    });
  });
}