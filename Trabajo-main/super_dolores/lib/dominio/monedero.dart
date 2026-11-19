import 'dinero.dart';
import 'excepciones.dart';

enum TipoMovimiento { deposito, pago, transferenciaEnviada, transferenciaRecibida, reembolso }

class Movimiento {
  final String id;
  final String cuentaId;
  final TipoMovimiento tipo;
  final int montoCentavos; // con signo: + entra, - sale
  final String concepto;
  final DateTime fecha;
  final String? contraparte;
  const Movimiento(this.id, this.cuentaId, this.tipo, this.montoCentavos, this.concepto, this.fecha,
      {this.contraparte});
}

/// Monedero con LIBRO DE MOVIMIENTOS: el saldo no se guarda, se CALCULA sumando
/// movimientos. Así no puede "desincronizarse" y siempre hay rastro de auditoría.
/// (Los bancos y las fintech usan la misma idea: contabilidad, no un número que se edita.)
class Monedero {
  static const int maxPorOperacion = 500000; // $5,000.00
  static const int maxSalidasDiarias = 1000000; // $10,000.00

  final DateTime Function() _reloj;
  final Map<String, List<Movimiento>> _libro = {};
  final Map<String, Movimiento> _porClave = {}; // idempotencia: "cuenta|clave"
  int _sec = 0;

  Monedero({DateTime Function()? reloj}) : _reloj = reloj ?? DateTime.now;

  final Set<String> _sinLimites = {};

  /// Las cuentas de la PLATAFORMA (custodia y pagos a negocios) no tienen el tope diario de una persona.
  void abrirCuenta(String id, {bool sinLimites = false}) {
    _libro.putIfAbsent(id, () => []);
    if (sinLimites) _sinLimites.add(id);
  }

  bool existe(String id) => _libro.containsKey(id);

  int saldo(String id) => _cuenta(id).fold(0, (s, m) => s + m.montoCentavos);

  List<Movimiento> movimientos(String id) => _cuenta(id).reversed.toList();

  int salidasDeHoy(String id) {
    final hoy = soloFecha(_reloj());
    return _cuenta(id)
        .where((m) =>
            m.montoCentavos < 0 &&
            (m.tipo == TipoMovimiento.pago || m.tipo == TipoMovimiento.transferenciaEnviada) &&
            soloFecha(m.fecha) == hoy)
        .fold(0, (s, m) => s + (-m.montoCentavos));
  }

  List<Movimiento> _cuenta(String id) => _libro[id] ?? (throw const CuentaNoExisteException());

  Movimiento _registrar(String cuenta, TipoMovimiento tipo, int monto, String concepto, {String? contraparte}) {
    final m = Movimiento('mov-${++_sec}', cuenta, tipo, monto, concepto, _reloj(), contraparte: contraparte);
    _libro[cuenta]!.add(m);
    return m;
  }

  void _validarMonto(int monto) {
    if (monto <= 0) throw const MontoInvalidoException();
    if (monto > maxPorOperacion) {
      throw LimiteExcedidoException('máximo ${formatearPesos(maxPorOperacion)} por operación');
    }
  }

  void _validarSalida(String cuenta, int monto) {
    if (saldo(cuenta) < monto) throw const SaldoInsuficienteException();
    if (!_sinLimites.contains(cuenta) && salidasDeHoy(cuenta) + monto > maxSalidasDiarias) {
      throw LimiteExcedidoException('máximo ${formatearPesos(maxSalidasDiarias)} de salidas por día');
    }
  }

  /// Recarga de saldo (en la vida real: SPEI, OXXO, tarjeta; aquí es una simulación).
  Movimiento depositar(String cuenta, int monto, {required String clave, String concepto = 'Recarga'}) {
    final previo = _porClave['$cuenta|$clave'];
    if (previo != null) return previo;
    _cuenta(cuenta);
    _validarMonto(monto);
    return _porClave['$cuenta|$clave'] = _registrar(cuenta, TipoMovimiento.deposito, monto, concepto);
  }

  Movimiento pagar(String cuenta, int monto, String concepto, {required String clave}) {
    final previo = _porClave['$cuenta|$clave'];
    if (previo != null) return previo;
    _cuenta(cuenta);
    _validarMonto(monto);
    _validarSalida(cuenta, monto);
    return _porClave['$cuenta|$clave'] = _registrar(cuenta, TipoMovimiento.pago, -monto, concepto);
  }

  /// Transferencia entre cuentas. TODO o NADA: se valida todo antes de tocar el libro.
  /// Devuelve el movimiento de salida del que envía.
  Movimiento transferir(String de, String a, int monto, String concepto, {required String clave}) {
    final previo = _porClave['$de|$clave'];
    if (previo != null) return previo;
    _cuenta(de);
    _cuenta(a);
    if (de == a) throw const DestinatarioInvalidoException();
    _validarMonto(monto);
    _validarSalida(de, monto);
    final salida = _registrar(de, TipoMovimiento.transferenciaEnviada, -monto, concepto, contraparte: a);
    _registrar(a, TipoMovimiento.transferenciaRecibida, monto, concepto, contraparte: de);
    return _porClave['$de|$clave'] = salida;
  }

  Movimiento reembolsar(String cuenta, int monto, String concepto, {required String clave}) {
    final previo = _porClave['$cuenta|$clave'];
    if (previo != null) return previo;
    _cuenta(cuenta);
    if (monto <= 0) throw const MontoInvalidoException();
    return _porClave['$cuenta|$clave'] = _registrar(cuenta, TipoMovimiento.reembolso, monto, concepto);
  }
}