abstract class ErrorSuperApp implements Exception {
  const ErrorSuperApp();
  String get mensaje;
  @override
  String toString() => mensaje;
}

class MontoInvalidoException extends ErrorSuperApp {
  const MontoInvalidoException();
  @override
  String get mensaje => 'El monto debe ser mayor a cero.';
}

class SaldoInsuficienteException extends ErrorSuperApp {
  const SaldoInsuficienteException();
  @override
  String get mensaje => 'Saldo insuficiente.';
}

class LimiteExcedidoException extends ErrorSuperApp {
  final String detalle;
  const LimiteExcedidoException(this.detalle);
  @override
  String get mensaje => 'Límite excedido: $detalle';
}

class CuentaNoExisteException extends ErrorSuperApp {
  const CuentaNoExisteException();
  @override
  String get mensaje => 'La cuenta no existe.';
}

class DestinatarioInvalidoException extends ErrorSuperApp {
  const DestinatarioInvalidoException();
  @override
  String get mensaje => 'Destinatario inválido.';
}

class PermisoDenegadoException extends ErrorSuperApp {
  final String miniApp;
  final String permiso;
  const PermisoDenegadoException(this.miniApp, this.permiso);
  @override
  String get mensaje => 'La mini-app "$miniApp" no tiene permiso: $permiso.';
}

class MiniAppNoDisponibleException extends ErrorSuperApp {
  const MiniAppNoDisponibleException();
  @override
  String get mensaje => 'Este servicio no está disponible por ahora.';
}

class ExistenciasInsuficientesException extends ErrorSuperApp {
  final String producto;
  const ExistenciasInsuficientesException(this.producto);
  @override
  String get mensaje => 'No hay suficientes existencias de $producto.';
}

class PedidoInvalidoException extends ErrorSuperApp {
  final String detalle;
  const PedidoInvalidoException(this.detalle);
  @override
  String get mensaje => detalle;
}

class TransicionInvalidaException extends ErrorSuperApp {
  const TransicionInvalidaException();
  @override
  String get mensaje => 'Esa acción no es posible en el estado actual del viaje.';
}

class MensajeInvalidoException extends ErrorSuperApp {
  final String detalle;
  const MensajeInvalidoException(this.detalle);
  @override
  String get mensaje => detalle;
}

class CanjeInvalidoException extends ErrorSuperApp {
  final String detalle;
  const CanjeInvalidoException(this.detalle);
  @override
  String get mensaje => detalle;
}

/// Un error inesperado NUNCA se muestra tal cual: podría filtrar detalles internos.
String mensajeSeguro(Object e) =>
    e is ErrorSuperApp ? e.mensaje : 'Ocurrió un error inesperado. Intenta de nuevo.';