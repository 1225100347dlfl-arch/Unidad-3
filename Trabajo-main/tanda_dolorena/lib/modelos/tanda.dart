import 'participante.dart';

class Tanda {
  final List<Participante> participantes;
  final List<String> ordenTurnos;
  final double montoAportacion;
  int turnoActual = 0;
  final Set<String> aportacionesRondaActual = {};

  Tanda({
    required this.participantes,
    required this.ordenTurnos,
    required this.montoAportacion,
  });
<<<<<<< HEAD
}
=======
}
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
