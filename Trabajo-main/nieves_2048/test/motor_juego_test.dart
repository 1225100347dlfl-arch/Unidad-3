import 'package:flutter_test/flutter_test.dart';
import 'package:nieves_2048/logica/grid.dart';
import 'package:nieves_2048/logica/direccion.dart';
import 'package:nieves_2048/logica/estado_juego.dart';
import 'package:nieves_2048/logica/motor_juego.dart';

void main() {
<<<<<<< HEAD
=======
  // RONDA 10
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
  test('mover sin ningun desplazamiento no agrega una ficha nueva', () {
    final motor = MotorJuego();
    motor.grid = Grid([
      [2, 4, 8, 16],
      [null, null, null, null],
      [null, null, null, null],
      [null, null, null, null],
    ]);
    final vaciasAntes = motor.grid.celdas.expand((f) => f).where((v) => v == null).length;
<<<<<<< HEAD

    motor.mover(Direccion.izquierda); // la fila ya esta compactada, sin fusiones posibles

=======
    motor.mover(Direccion.izquierda);
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
    final vaciasDespues = motor.grid.celdas.expand((f) => f).where((v) => v == null).length;
    expect(vaciasDespues, vaciasAntes);
  });

  test('alcanzar el valor objetivo cambia el estado a ganado', () {
    final motor = MotorJuego();
    motor.grid = Grid([
      [1024, 1024, null, null],
      [null, null, null, null],
      [null, null, null, null],
      [null, null, null, null],
    ]);
<<<<<<< HEAD

    motor.mover(Direccion.izquierda);

    expect(motor.estado, EstadoJuego.ganado);
    expect(motor.puntaje, 2048);
  });
    test('una serie de movimientos combina fichas y acumula puntaje', () {
=======
    motor.mover(Direccion.izquierda);
    expect(motor.estado, EstadoJuego.ganado);
    expect(motor.puntaje, 2048);
  });

  // INTEGRACION
  test('una serie de movimientos combina fichas y acumula puntaje', () {
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
    final motor = MotorJuego();
    motor.grid = Grid([
      [2, 2, null, null],
      [null, null, null, null],
      [null, null, null, null],
      [null, null, null, null],
    ]);
<<<<<<< HEAD

    motor.mover(Direccion.izquierda); // fusiona en 4, aparece una ficha nueva

=======
    motor.mover(Direccion.izquierda);
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
    expect(motor.grid.celdas[0][0], 4);
    expect(motor.puntaje, 4);
    expect(motor.estado, EstadoJuego.jugando);
  });
<<<<<<< HEAD
}
=======
}
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
