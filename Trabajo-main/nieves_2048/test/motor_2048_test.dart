import 'package:flutter_test/flutter_test.dart';
import 'package:nieves_2048/logica/motor_2048.dart';

void main() {
<<<<<<< HEAD
=======
  // RONDA 1
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
  test('compactarFila quita los huecos y mantiene el orden', () {
    final resultado = Motor2048.compactarFila([2, null, 4, null]);
    expect(resultado, [2, 4, null, null]);
  });
<<<<<<< HEAD

=======
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
  test('compactarFila sin huecos no cambia nada', () {
    final resultado = Motor2048.compactarFila([2, 4, 8, 16]);
    expect(resultado, [2, 4, 8, 16]);
  });

<<<<<<< HEAD
=======
  // RONDA 2
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
  test('fusionarFila combina un par adyacente igual', () {
    final resultado = Motor2048.fusionarFila([2, 2, 4, null]);
    expect(resultado.fila, [4, null, 4, null]);
    expect(resultado.puntosGanados, 4);
  });
<<<<<<< HEAD

=======
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
  test('fusionarFila no fusiona tres iguales seguidos mas de una vez', () {
    final resultado = Motor2048.fusionarFila([2, 2, 2, null]);
    expect(resultado.fila, [4, null, 2, null]);
    expect(resultado.puntosGanados, 4);
  });

<<<<<<< HEAD
=======
  // RONDA 3
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
  test('mover una fila hacia la izquierda compacta y fusiona correctamente', () {
    final resultado = Motor2048.moverFilaIzquierda([null, 2, 2, 4]);
    expect(resultado.fila, [4, 4, null, null]);
    expect(resultado.puntosGanados, 4);
    expect(resultado.seMovio, true);
  });
<<<<<<< HEAD

=======
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
  test('una fila ya en su posicion final reporta seMovio en falso', () {
    final resultado = Motor2048.moverFilaIzquierda([2, 4, null, null]);
    expect(resultado.seMovio, false);
  });
<<<<<<< HEAD
}
=======
}
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
