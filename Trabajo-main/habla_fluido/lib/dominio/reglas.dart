/// Todas las "perillas" pedagógicas en UN solo lugar, con nombre y motivo.

/// Ajustarlas con datos reales (playtesting) es parte del trabajo de un docente-desarrollador.
class Reglas {
  /// Una sesión diaria corta y constante supera a un maratón semanal (práctica distribuida).
  static const int minutosPorSesion = 20;

  /// Puntaje desde el cual un intento se considera "logrado".
  static const double umbralAprobado = 0.8;

  /// Dos palabras con esta similitud (0 a 1) cuentan como "parecidas" (casi bien).
  static const double umbralParecida = 0.75;

  /// Peso del último intento en el promedio móvil exponencial (EMA) del dominio.
  static const double pesoUltimoIntento = 0.3;

  /// Para subir de nivel: dominio mínimo y número mínimo de intentos en CADA habilidad.
  static const double dominioParaSubir = 0.8;
  static const int intentosParaSubir = 5;

  /// Extra de tiempo (fracción del total) para la habilidad más débil.
  static const double extraHabilidadDebil = 0.15;

  /// Máximo de errores que el tutor corrige por turno (corregir todo abruma).
  static const int maxCorreccionesPorTurno = 2;

  /// Palabras mínimas para que un texto cuente como ejercicio de escritura.
  static const int palabrasMinimasEscritura = 5;

  /// Estimación inicial de dominio para una habilidad aún no evaluada.
  static const double dominioSinEvaluar = 0.5;
}