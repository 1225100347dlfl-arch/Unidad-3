import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../dominio/categoria.dart';
import '../dominio/payload.dart';
import '../dominio/planificador.dart';
import '../dominio/puerto.dart';

/// ÚNICO archivo que conoce el plugin flutter_local_notifications.
class PuertoReal implements PuertoNotificaciones {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  void Function(String? payload)? _alTocar;

  static const _accionAlimentar = 'alimentar';

  @override
  Future<void> inicializar() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));

    const ajustes = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      // false: NO pedir permisos al arrancar; los pedimos en el momento oportuno.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      settings: ajustes,
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        // Tocar el botón "Dar de comer" equivale a abrir con destino alimentarYa.
        final payload = r.actionId == _accionAlimentar
            ? const PayloadNotif(Destino.alimentarYa).codificar()
            : r.payload;
        _alTocar?.call(payload);
      },
    );

    // Un canal por categoría.
    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    for (final c in Categoria.values) {
      await android?.createNotificationChannel(AndroidNotificationChannel(
        c.canal.id,
        c.canal.nombre,
        description: c.canal.descripcion,
        importance: _importancia(c.canal.importancia),
      ));
    }
  }

  Importance _importancia(Importancia i) => switch (i) {
        Importancia.baja => Importance.low,
        Importancia.normal => Importance.defaultImportance,
        Importancia.alta => Importance.high,
      };

  Priority _prioridad(Importancia i) => switch (i) {
        Importancia.baja => Priority.low,
        Importancia.normal => Priority.defaultPriority,
        Importancia.alta => Priority.high,
      };

  NotificationDetails _detalles(Categoria c) {
    final canal = c.canal;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        canal.id,
        canal.nombre,
        channelDescription: canal.descripcion,
        importance: _importancia(canal.importancia),
        priority: _prioridad(canal.importancia),
        actions: c == Categoria.hambre
            ? const [AndroidNotificationAction(_accionAlimentar, 'Dar de comer 🍤', showsUserInterface: true)]
            : null,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: c == Categoria.hambre,
      ),
    );
  }

  @override
  Future<bool> notificacionesActivas() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.areNotificationsEnabled() ?? false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return (await ios.checkPermissions())?.isEnabled ?? false;
    return true;
  }

  @override
  Future<bool> pedirPermiso() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    return true;
  }

  @override
  Future<void> programar(PlanNotificacion plan) {
    return _plugin.zonedSchedule(
      id: plan.id,
      title: plan.titulo,
      body: plan.cuerpo,
      scheduledDate: tz.TZDateTime.from(plan.cuando, tz.local),
      notificationDetails: _detalles(plan.categoria),
      // "Inexacto" NO requiere el permiso de alarmas exactas (Android 12+/14+).
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: plan.payload,
    );
  }

  @override
  Future<void> mostrarAhora({
    required int id,
    required String titulo,
    required String cuerpo,
    required Categoria categoria,
    required String payload,
  }) {
    return _plugin.show(
      id: id,
      title: titulo,
      body: cuerpo,
      notificationDetails: _detalles(categoria),
      payload: payload,
    );
  }

  @override
  Future<void> cancelar(int id) => _plugin.cancel(id: id);

  @override
  Future<String?> payloadDeLanzamiento() async {
    final detalles = await _plugin.getNotificationAppLaunchDetails();
    if (detalles?.didNotificationLaunchApp ?? false) {
      final r = detalles!.notificationResponse;
      if (r?.actionId == _accionAlimentar) return const PayloadNotif(Destino.alimentarYa).codificar();
      return r?.payload;
    }
    return null;
  }

  @override
  void escucharToques(void Function(String? payload) alTocar) => _alTocar = alTocar;

  @override
  Future<void> abrirAjustes() => AppSettings.openAppSettings(type: AppSettingsType.notification);
}