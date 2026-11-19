import 'dart:async';

import 'package:flutter/widgets.dart';

import '../dominio/categoria.dart';
import '../dominio/gestor_permiso.dart';
import '../dominio/mascota.dart';
import '../dominio/payload.dart';
import '../dominio/planificador.dart';
import '../dominio/reloj.dart';
import '../dominio/servicio.dart';

class AjoloteViewModel extends ChangeNotifier {
  AjoloteViewModel({required this.servicio, required this.gestor, required this.reloj});

  final ServicioAjolote servicio;
  final GestorPermiso gestor;
  final Reloj reloj;

  Mascota? _m;
  Timer? _timer;

  EstadoPermiso permiso = EstadoPermiso.sinPreguntar;
  Map<Categoria, bool> categorias = {for (final c in Categoria.values) c: true};
  String? aviso;
  bool resaltarAlimentar = false;

  bool get listo => _m != null;
  String get nombre => _m?.nombre ?? '';
  double get saciedad => _m?.saciedadEn(reloj.ahora()) ?? 0;
  Humor get humor => _m?.humorEn(reloj.ahora()) ?? Humor.feliz;
  bool get modoClase =>
      (_m?.puntosPorHora ?? ServicioAjolote.ritmoNormal) > ServicioAjolote.ritmoNormal;
  List<PlanNotificacion> get programadas => servicio.programadas;

  Future<void> iniciar({Destino destino = Destino.inicio, bool conReloj = true}) async {
    _m = await servicio.cargar();
    permiso = await gestor.estado();
    categorias = await servicio.categorias();
    await servicio.sincronizar(_m!);
    await _aplicarDestino(destino);
    if (conReloj) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
    }
    notifyListeners();
  }

  Future<void> _aplicarDestino(Destino d) async {
    switch (d) {
      case Destino.inicio:
        break;
      case Destino.alimentar:
        resaltarAlimentar = true;
        aviso = '$nombre te estaba esperando. ¡Dale de comer!';
      case Destino.alimentarYa:
        await alimentar();
      case Destino.jugar:
        aviso = '$nombre quiere jugar, pero primero mírale esa carita 🥺';
    }
  }

  /// Toque en una notificación con la app ya viva.
  Future<void> alTocarNotificacion(String? payload) async {
    await _aplicarDestino(PayloadNotif.decodificar(payload).destino);
    notifyListeners();
  }

  Future<void> alimentar() async {
    try {
      _m = await servicio.alimentar();
      aviso = '¡Ñam! $nombre quedó feliz 🍤';
      resaltarAlimentar = false;
    } on YaEstaLlena catch (e) {
      aviso = '${e.nombre} está llenísimo; ni un acocil más.';
    }
    notifyListeners();
  }

  /// Se llama desde un botón: el permiso se pide EN CONTEXTO.
  Future<ResultadoPermiso> activarAvisos() async {
    final r = await gestor.solicitar();
    permiso = await gestor.estado();
    if (_m != null) await servicio.sincronizar(_m!);
    notifyListeners();
    return r;
  }

  Future<void> abrirAjustes() => gestor.abrirAjustes();

  Future<void> cambiarModoClase(bool activo) async {
    _m = await servicio.cambiarRitmo(activo ? ServicioAjolote.ritmoClase : ServicioAjolote.ritmoNormal);
    notifyListeners();
  }

  Future<void> cambiarCategoria(Categoria c, bool activa) async {
    await servicio.cambiarCategoria(c, activa);
    categorias = await servicio.categorias();
    notifyListeners();
  }

  Future<void> probarAhora() => servicio.probarAhora();

  Future<void> alCambiarCicloDeVida(AppLifecycleState estado) async {
    if (estado == AppLifecycleState.paused) {
      await servicio.alPasarAFondo();
    } else if (estado == AppLifecycleState.resumed) {
      await servicio.alVolverAlFrente();
      _m = await servicio.cargar();
      permiso = await gestor.estado(); // quizá lo cambió en Ajustes
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}