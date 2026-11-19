/// Dinero SIEMPRE en centavos enteros (nunca double): $1,250.00 = 125000.
String formatearPesos(int centavos) {
  final negativo = centavos < 0;
  final abs = centavos.abs();
  final pesos = (abs ~/ 100).toString();
  final cents = (abs % 100).toString().padLeft(2, '0');
  final conComas = pesos.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${negativo ? '-' : ''}\$$conComas.$cents';
}

/// Porcentaje entero con redondeo al más cercano: porcentaje(9999, 5) = 500.
int porcentaje(int centavos, int pct) => (centavos * pct + 50) ~/ 100;

DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

/// El lunes de la semana de [d] (la "semana" para los bonos y la analítica).
DateTime lunesDe(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

DateTime masDias(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);