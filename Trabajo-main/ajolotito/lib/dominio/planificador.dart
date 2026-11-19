import 'categoria.dart';
import 'mascota.dart';
import 'mensajes.dart';
import 'payload.dart';
import 'politica.dart';

/// Ids FIJOS y conocidos: programar con el mismo id REEMPLAZA.
class Ids {
  static const int hambre = 1;
  static const int critico = 2;
  static const int sorpresaBase = 100;
  static int sorpresa(int n) => sorpresaBase + n;
  static const List<int> todos = [1, 2, 100, 101, 102];
}

class PlanNotificacion {
  const PlanNotificacion({
    required this.id,
    required this.categoria,
    required this.cuando,
    required this.titulo,
    required this.cuerpo,
    required this.payload,
    required this.prioridad,
  });

  final int id;
  final Categoria categoria;
  final DateTime cuando;
  final String titulo;
  final String cuerpo;
  final String payload;
  final int prioridad;

  bool get esDeHambre => id == Ids.hambre || id == Ids.critico;
}

/// Convierte el estado del ajolote en una lista de notificaciones por programar.
/// Función pura: no toca ningún plugin.
class Planificador {
  const Planificador({this.politica = const PoliticaNotificaciones()});

  final PoliticaNotificaciones politica;

  static const int sorpresasAdelantadas = 3;
  static const int horaSorpresa = 18;

  List<PlanNotificacion> planear(Mascota m, DateTime ahora) {
    final plan = <PlanNotificacion>[];

    if (politica.habilitada(Categoria.hambre)) {
      final aH = politica.ajustar(m.momentoEnQueBajaA(Mascota.umbralHambre));
      final aC = politica.ajustar(m.momentoEnQueBajaA(Mascota.umbralCritico));
      var hayH = aH.isAfter(ahora);
      final hayC = aC.isAfter(ahora);

      // Dos avisos sobre lo mismo, casi juntos, son spam: gana el más urgente.
      if (hayH && hayC && aC.difference(aH) < politica.margenEntreAvisos) hayH = false;

      if (hayH) {
        final msg = Mensajes.hambre(m.nombre, aH.day + aH.month * 31);
        plan.add(PlanNotificacion(
          id: Ids.hambre,
          categoria: Categoria.hambre,
          cuando: aH,
          titulo: msg.titulo,
          cuerpo: msg.cuerpo,
          payload: const PayloadNotif(Destino.alimentar).codificar(),
          prioridad: 2,
        ));
      }
      if (hayC) {
        final msg = Mensajes.critico(m.nombre, aC.day + aC.month * 31);
        plan.add(PlanNotificacion(
          id: Ids.critico,
          categoria: Categoria.hambre,
          cuando: aC,
          titulo: msg.titulo,
          cuerpo: msg.cuerpo,
          payload: const PayloadNotif(Destino.alimentar).codificar(),
          prioridad: 3,
        ));
      }
    }

    if (politica.habilitada(Categoria.sorpresa)) {
      var n = 0;
      for (var d = 0; n < sorpresasAdelantadas && d < 30; d++) {
        final base = DateTime(ahora.year, ahora.month, ahora.day + d, horaSorpresa);
        final cuando = politica.ajustar(base);
        if (!cuando.isAfter(ahora)) continue;
        final msg = Mensajes.sorpresa(m.nombre, cuando.day + cuando.month * 31);
        plan.add(PlanNotificacion(
          id: Ids.sorpresa(n),
          categoria: Categoria.sorpresa,
          cuando: cuando,
          titulo: msg.titulo,
          cuerpo: msg.cuerpo,
          payload: const PayloadNotif(Destino.jugar).codificar(),
          prioridad: 1,
        ));
        n++;
      }
    }

    return _limitarPorDia(plan);
  }

  String _clave(DateTime t) => '${t.year}-${t.month}-${t.day}';

  /// Tope diario: si hay de más, se sacrifican las menos importantes.
  List<PlanNotificacion> _limitarPorDia(List<PlanNotificacion> plan) {
    final porDia = <String, List<PlanNotificacion>>{};
    for (final p in plan) {
      porDia.putIfAbsent(_clave(p.cuando), () => []).add(p);
    }
    final conservadas = <PlanNotificacion>[];
    for (final lista in porDia.values) {
      lista.sort((a, b) => b.prioridad.compareTo(a.prioridad));
      conservadas.addAll(lista.take(politica.maxPorDia));
    }
    conservadas.sort((a, b) => a.cuando.compareTo(b.cuando));
    return conservadas;
  }
}