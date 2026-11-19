import 'almacen.dart';
import 'categoria.dart';
import 'mascota.dart';
import 'payload.dart';
import 'planificador.dart';
import 'politica.dart';
import 'puerto.dart';
import 'reloj.dart';

/// Orquesta todo: carga/guarda al ajolote y mantiene las notificaciones
/// programadas SIEMPRE sincronizadas con su estado real.
class ServicioAjolote {
  ServicioAjolote({
    required this.puerto,
    required this.almacen,
    required this.reloj,
    this.nombre = 'Xólotl',
  });

  final PuertoNotificaciones puerto;
  final Almacen almacen;
  final Reloj reloj;
  final String nombre;

  static const _kMascota = 'mascota';
  static const double ritmoNormal = 10;
  static const double ritmoClase = 600; // 1 hora de vida pasa en 1 minuto

  bool _enPrimerPlano = true;
  List<PlanNotificacion> _programadas = const [];
  List<PlanNotificacion> get programadas => _programadas;

  Future<Mascota> cargar() async {
    final guardada = Mascota.desdeTexto(await almacen.leerTexto(_kMascota));
    if (guardada != null) return guardada;
    final nueva = Mascota.nueva(nombre, reloj.ahora());
    await _guardar(nueva);
    return nueva;
  }

  Future<void> _guardar(Mascota m) => almacen.guardarTexto(_kMascota, m.aTexto());

  Future<Map<Categoria, bool>> categorias() async => {
        for (final c in Categoria.values) c: await almacen.leerBool('cat_${c.name}') ?? true,
      };

  Future<PoliticaNotificaciones> _politica(Mascota m) async {
    final cats = await categorias();
    // En modo clase el tiempo corre más rápido; el margen entre avisos también.
    final escala = ritmoNormal / m.puntosPorHora;
    return PoliticaNotificaciones(
      activas: {for (final e in cats.entries) if (e.value) e.key},
      margenEntreAvisos: Duration(microseconds: (const Duration(minutes: 30).inMicroseconds * escala).round()),
    );
  }

  Future<Mascota> alimentar() async {
    final nuevo = (await cargar()).alimentar(reloj.ahora());
    await _guardar(nuevo);
    await sincronizar(nuevo);
    return nuevo;
  }

  Future<Mascota> cambiarRitmo(double puntosPorHora) async {
    final nuevo = (await cargar()).conRitmo(reloj.ahora(), puntosPorHora);
    await _guardar(nuevo);
    await sincronizar(nuevo);
    return nuevo;
  }

  Future<void> cambiarCategoria(Categoria c, bool activa) async {
    await almacen.guardarBool('cat_${c.name}', activa);
    await sincronizar(await cargar());
  }

  /// EL corazón de la app: borra lo programado y vuelve a programar lo que
  /// corresponde HOY. Se llama cada vez que algo cambia.
  Future<void> sincronizar(Mascota m) async {
    for (final id in Ids.todos) {
      await puerto.cancelar(id);
    }
    _programadas = const [];
    if (!await puerto.notificacionesActivas()) return; // sin permiso, no hay nada que programar

    final plan = Planificador(politica: await _politica(m)).planear(m, reloj.ahora());
    // Si el usuario está MIRANDO la app, avisar del hambre sería redundante.
    final aProgramar = plan.where((p) => !(_enPrimerPlano && p.esDeHambre)).toList();
    for (final p in aProgramar) {
      await puerto.programar(p);
    }
    _programadas = aProgramar;
  }

  Future<void> alPasarAFondo() async {
    _enPrimerPlano = false;
    await sincronizar(await cargar());
  }

  Future<void> alVolverAlFrente() async {
    _enPrimerPlano = true;
    await sincronizar(await cargar());
  }

  Future<Destino> destinoDeLanzamiento() async =>
      PayloadNotif.decodificar(await puerto.payloadDeLanzamiento()).destino;

  Future<void> probarAhora() async {
    final m = await cargar();
    await puerto.mostrarAhora(
      id: 999,
      titulo: '${m.nombre} te saluda 👋',
      cuerpo: 'Esta es una notificación de prueba: apareció al instante.',
      categoria: Categoria.sorpresa,
      payload: const PayloadNotif(Destino.jugar).codificar(),
    );
  }
}