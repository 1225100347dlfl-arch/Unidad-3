abstract class ErrorHablaFluido implements Exception {
  const ErrorHablaFluido();
  String get mensaje;
  @override
  String toString() => mensaje;
}

class DatosInvalidosException extends ErrorHablaFluido {
  @override
  final String mensaje;
  const DatosInvalidosException(this.mensaje);
}

class TutorNoDisponibleException extends ErrorHablaFluido {
  const TutorNoDisponibleException();
  @override
  String get mensaje => 'El tutor no está disponible ahora. Intenta en un momento.';
}

class TutorInvalidoException extends ErrorHablaFluido {
  const TutorInvalidoException();
  @override
  String get mensaje => 'El tutor dio una respuesta que no pude entender. Intenta de nuevo.';
}

class MicrofonoNoDisponibleException extends ErrorHablaFluido {
  const MicrofonoNoDisponibleException();
  @override
  String get mensaje => 'No pude usar el micrófono. Revisa los permisos de la app.';
}


/// Los errores inesperados (red, bugs) NO se muestran tal cual: podrían filtrar detalles técnicos.
String mensajeSeguro(Object e) =>
    e is ErrorHablaFluido ? e.mensaje : 'Ocurrió un error inesperado. Intenta de nuevo.';