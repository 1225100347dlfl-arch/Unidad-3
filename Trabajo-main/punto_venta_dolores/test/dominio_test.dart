import 'package:flutter_test/flutter_test.dart';
<<<<<<< HEAD
import 'package:punto_venta_dolores/dominio/dinero.dart';
import 'package:punto_venta_dolores/dominio/producto.dart';
import 'package:punto_venta_dolores/dominio/carrito.dart';
import 'package:punto_venta_dolores/dominio/excepciones.dart';

Producto nieve([int existencias = 10]) => Producto(
    codigo: 'NV-001', nombre: 'Nieve',
    precioCentavos: 2500, existencias: existencias);

void main() {
=======
import 'package:punto_venta_dolores/dominio/carrito.dart';
import 'package:punto_venta_dolores/dominio/dinero.dart';
import 'package:punto_venta_dolores/dominio/excepciones.dart';
import 'package:punto_venta_dolores/dominio/producto.dart';

Producto nieve([int existencias = 10]) => Producto(
    codigo: 'NV-001',
    nombre: 'Nieve',
    precioCentavos: 2500,
    existencias: existencias);

void main() {
  // ---------- RONDA 1: Dinero ----------
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
  group('Dinero', () {
    test('formatea centavos', () {
      expect(formatearPesos(0), '\$0.00');
      expect(formatearPesos(5), '\$0.05');
      expect(formatearPesos(123456), '\$1,234.56');
    });
<<<<<<< HEAD
  });
      test('convierte texto a centavos', () {
=======
    test('convierte texto a centavos', () {
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
      expect(pesosACentavos('12.5'), 1250);
      expect(pesosACentavos('\$1,200'), 120000);
      expect(pesosACentavos('0.07'), 7);
    });
<<<<<<< HEAD

=======
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
    test('rechaza texto inválido', () {
      expect(() => pesosACentavos(''), throwsFormatException);
      expect(() => pesosACentavos('1.2.3'), throwsFormatException);
    });
<<<<<<< HEAD
      group('Producto', () {
    test('ida y vuelta a mapa conserva los datos', () {
      const original = Producto(
        codigo: 'NV-001', nombre: 'Nieve de limón',
        precioCentavos: 2500, existencias: 10,
=======
    // Retos de la ronda 1 (opcionales)
    test('reto: ".5" son 50 centavos', () {
      expect(pesosACentavos('.5'), 50);
    });
    test('reto: negativos', () {
      expect(formatearPesos(-250), '-\$2.50');
    });
  });

  // ---------- RONDA 2: Producto ----------
  group('Producto', () {
    test('ida y vuelta a mapa conserva los datos', () {
      const original = Producto(
        codigo: 'NV-001',
        nombre: 'Nieve de limón',
        precioCentavos: 2500,
        existencias: 10,
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
      );
      final copia = Producto.desdeMapa(original.aMapa());
      expect(copia.codigo, 'NV-001');
      expect(copia.precioCentavos, 2500);
    });
<<<<<<< HEAD

    test('copiarCon cambia solo lo indicado', () {
      const p = Producto(codigo: 'A', nombre: 'X', precioCentavos: 100, existencias: 5);
=======
    test('copiarCon cambia solo lo indicado', () {
      const p = Producto(
          codigo: 'A', nombre: 'X', precioCentavos: 100, existencias: 5);
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
      final q = p.copiarCon(existencias: 4);
      expect(q.existencias, 4);
      expect(q.precioCentavos, 100);
    });
  });
<<<<<<< HEAD
    group('Carrito', () {
=======

  // ---------- RONDA 3: Carrito ----------
  group('Carrito', () {
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
    test('suma cantidades del mismo producto', () {
      final c = Carrito()..agregar(nieve())..agregar(nieve());
      expect(c.lineas.single.cantidad, 2);
      expect(c.totalCentavos, 5000);
    });
<<<<<<< HEAD
  });
      test('no excede existencias', () {
=======
    test('no excede existencias', () {
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
      final c = Carrito()..agregar(nieve(1));
      expect(() => c.agregar(nieve(1)),
          throwsA(isA<ExistenciasInsuficientesException>()));
    });
<<<<<<< HEAD
        test('desglosa IVA 16% del total', () {
=======
    test('desglosa IVA 16% del total', () {
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
      final c = Carrito()..agregar(nieve(), cantidad: 4); // $100.00
      expect(c.ivaCentavos, 1379);
      expect(c.subtotalCentavos + c.ivaCentavos, c.totalCentavos);
    });
<<<<<<< HEAD
        test('calcula cambio', () {
      final c = Carrito()..agregar(nieve());
      expect(c.cambio(5000), 2500);
    });

=======
    test('calcula cambio', () {
      final c = Carrito()..agregar(nieve());
      expect(c.cambio(5000), 2500);
    });
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
    test('pago insuficiente lanza', () {
      final c = Carrito()..agregar(nieve());
      expect(() => c.cambio(1000), throwsA(isA<PagoInsuficienteException>()));
    });
<<<<<<< HEAD

    test('carrito vacío no cobra', () {
      expect(() => Carrito().cambio(100), throwsA(isA<CarritoVacioException>()));
    });
}
=======
    test('carrito vacío no cobra', () {
      expect(() => Carrito().cambio(100), throwsA(isA<CarritoVacioException>()));
    });
  });
}
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
