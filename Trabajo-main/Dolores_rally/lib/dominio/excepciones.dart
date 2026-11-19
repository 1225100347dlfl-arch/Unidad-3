abstract class ErrorDeApp implements Exception {
  const ErrorDeApp();
}

class PermisoUbicacionException extends ErrorDeApp {
  const PermisoUbicacionException();
  @override
  String toString() => 'Necesito el permiso de ubicación para jugar. Actívalo en Ajustes.';
}

class UbicacionApagadaException extends ErrorDeApp {
  const UbicacionApagadaException();
  @override
  String toString() => 'El GPS está apagado. Actívalo para jugar.';
}

class SinBrujulaException extends ErrorDeApp {
  const SinBrujulaException();
  @override
  String toString() => 'Este dispositivo no tiene brújula. Usa el modo demo.';
}

class LejosException extends ErrorDeApp {
  final double metros;
  const LejosException(this.metros);
  @override
  String toString() => 'Estás a ${metros.round()} m. Acércate a menos de 15 m para atraparlo.';
}

class YaCapturadoException extends ErrorDeApp {
  const YaCapturadoException();
  @override
  String toString() => 'Ya atrapaste a este personaje.';
}

class PersonajeDesconocidoException extends ErrorDeApp {
  const PersonajeDesconocidoException();
  @override
  String toString() => 'Ese personaje no existe en el juego.';
}

// ---- RETO Ronda 1: pistas ----
class PuntosInsuficientesException extends ErrorDeApp {
  final int costo;
  const PuntosInsuficientesException(this.costo);
  @override
  String toString() => 'Necesitas al menos $costo puntos para pedir una pista.';
}

class JuegoTerminadoException extends ErrorDeApp {
  const JuegoTerminadoException();
  @override
  String toString() => 'Ya atrapaste a todos los personajes. ¡No quedan pistas por pedir!';
}

class PosicionDesconocidaException extends ErrorDeApp {
  const PosicionDesconocidaException();
  @override
  String toString() => 'Aún no tengo tu ubicación. Espera a que el GPS te encuentre.';
}

/// Mensaje que SÍ puede ver el jugador (sin detalles internos).
String mensajeSeguro(Object error) =>
    error is ErrorDeApp ? error.toString() : 'Ocurrió un error inesperado. Intenta de nuevo.';
