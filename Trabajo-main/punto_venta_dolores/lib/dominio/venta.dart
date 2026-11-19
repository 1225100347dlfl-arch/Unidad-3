class LineaVenta {
  final String codigo;
  final String nombre;
  final int cantidad;
  final int precioCentavos;
<<<<<<< HEAD

  const LineaVenta(this.codigo, this.nombre, this.cantidad, this.precioCentavos);

=======
  const LineaVenta(this.codigo, this.nombre, this.cantidad, this.precioCentavos);
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
  int get importeCentavos => cantidad * precioCentavos;
}

class Venta {
  final int? id;
  final DateTime fecha;
  final int totalCentavos;
  final int ivaCentavos;
  final int pagoCentavos;
  final List<LineaVenta> lineas;

  const Venta({
    this.id,
    required this.fecha,
    required this.totalCentavos,
    required this.ivaCentavos,
    required this.pagoCentavos,
    required this.lineas,
  });

  int get cambioCentavos => pagoCentavos - totalCentavos;
}

class ResumenDia {
  final int numeroVentas;
  final int totalCentavos;
  final int ivaCentavos;
<<<<<<< HEAD

  const ResumenDia(this.numeroVentas, this.totalCentavos, this.ivaCentavos);
}
=======
  const ResumenDia(this.numeroVentas, this.totalCentavos, this.ivaCentavos);
}
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
