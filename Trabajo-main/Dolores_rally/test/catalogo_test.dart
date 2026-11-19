import 'package:dolores_rally/dominio/catalogo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Pruebas de integridad de los datos: protegen contra una pregunta mal escrita.
  for (final entrada in {'personajes': personajes, 'personajesExtendidos': personajesExtendidos}.entries) {
    group('catálogo ${entrada.key}', () {
      final lista = entrada.value;

      test('los ids no se repiten', () {
        expect(lista.map((p) => p.id).toSet().length, lista.length);
      });

      test('cada pregunta tiene al menos 2 opciones y una correcta válida', () {
        for (final p in lista) {
          final q = p.pregunta;
          expect(q.opciones.length, greaterThanOrEqualTo(2), reason: p.id);
          expect(q.correcta, inInclusiveRange(0, q.opciones.length - 1), reason: p.id);
          expect(q.esCorrecta(q.correcta), true, reason: p.id);
        }
      });

      test('nada queda vacío (nombre, bio, emoji, texto de la pregunta)', () {
        for (final p in lista) {
          expect(p.nombre.trim(), isNotEmpty, reason: p.id);
          expect(p.bio.trim(), isNotEmpty, reason: p.id);
          expect(p.emoji.trim(), isNotEmpty, reason: p.id);
          expect(p.pregunta.texto.trim(), isNotEmpty, reason: p.id);
        }
      });

      test('las respuestas correctas están repartidas (no siempre la A)', () {
        expect(lista.map((p) => p.pregunta.correcta).toSet().length, greaterThanOrEqualTo(2));
      });
    });
  }

  test('el juego trae 6 personajes y la versión extendida 8', () {
    expect(personajes.length, 6);
    expect(personajesExtendidos.length, 8);
  });
}
