import 'analitica.dart';
import 'comercio.dart';
import 'contexto.dart';
import 'eventos.dart';
import 'lealtad.dart';
import 'mensajeria.dart';
import 'mini_app.dart';
import 'monedero.dart';
import 'notificaciones.dart';
import 'transporte.dart';

class PerfilDemo {
  final String id;
  final String nombre;
  const PerfilDemo(this.id, this.nombre);
}

/// La "nube" simulada de la SuperApp. En producción cada servicio sería un backend
/// (microservicio) detrás de una puerta de entrada (API gateway); la app móvil usaría las
/// MISMAS interfaces, así que el cambio no se notaría en las pantallas.
class Plataforma {
  final DateTime Function() reloj;
  final Ids ids = Ids();
  final BusEventos bus = BusEventos();
  final RegistroMiniApps registro = RegistroMiniApps();
  late final Monedero monedero = Monedero(reloj: reloj);
  late final ServicioMensajes mensajes = ServicioMensajes(monedero, bus, ids, reloj);
  late final ServicioComercio comercio;
  late final ServicioViajes viajes = ServicioViajes(monedero, bus, ids, reloj);
  late final Lealtad lealtad = Lealtad(monedero);
  final Analitica analitica = Analitica();
  final Notificador notificador = Notificador();
  final List<PerfilDemo> perfiles = const [
    PerfilDemo('ana', 'Ana'),
    PerfilDemo('luis', 'Luis'),
    PerfilDemo('marta', 'Marta'),
  ];

  static const miniChat = MiniApp('chat', 'Mensajes', '💬',
      {Permiso.identidad, Permiso.mensajesLeer, Permiso.mensajesEscribir, Permiso.monederoPagar});
  static const miniMonedero =
      MiniApp('monedero', 'Monedero', '💰', {Permiso.identidad, Permiso.monederoLeer, Permiso.monederoPagar});
  static const miniTienda = MiniApp('tienda', 'Tienda', '🛒', {Permiso.identidad, Permiso.monederoPagar});
  static const miniViajes =
      MiniApp('viajes', 'Viajes', '🚕', {Permiso.identidad, Permiso.ubicacion, Permiso.monederoPagar});

  /// Mini-app de un TERCERO (demostración): solo conoce la identidad. No debe tocar dinero ni chats.
  static const miniHoroscopo = MiniApp('horoscopo', 'Horóscopo', '🔮', {Permiso.identidad});

  Plataforma({DateTime Function()? reloj, List<Tienda>? tiendas}) : reloj = reloj ?? DateTime.now {
    comercio = ServicioComercio(monedero, bus, ids, this.reloj, tiendas ?? tiendasDemo());
    for (final a in [miniChat, miniMonedero, miniTienda, miniViajes, miniHoroscopo]) {
      registro.registrar(a);
    }
    monedero.abrirCuenta(ServicioComercio.cuentaPlataforma, sinLimites: true);
    for (final p in perfiles) {
      monedero.abrirCuenta(p.id);
    }
    for (final t in comercio.tiendas) {
      monedero.abrirCuenta(t.duenoId);
    }
    for (final c in conductoresDemo) {
      monedero.abrirCuenta(c);
    }
    // El corazón de la arquitectura: los servicios se coordinan por EVENTOS.
    lealtad.conectar(bus);
    analitica.conectar(bus);
    notificador.conectar(bus);
  }

  static const conductoresDemo = ['conductor1', 'conductor2'];

  static List<Tienda> tiendasDemo() => [
        Tienda('tortilleria', 'Tortillería La Güera', '🌮', 'dueno-tortilleria', [
          ProductoTienda('kilo', 'Kilo de tortillas', 2800, 50),
          ProductoTienda('tostadas', 'Paquete de tostadas', 3500, 30),
        ]),
        Tienda('cajeta', 'Dulces Dolores', '🍯', 'dueno-cajeta', [
          ProductoTienda('cajeta', 'Cajeta artesanal', 9500, 20),
          ProductoTienda('alegrias', 'Alegrías de amaranto', 7500, 25),
        ]),
        Tienda('talavera', 'Talavera del Centro', '🏺', 'dueno-talavera', [
          ProductoTienda('taza', 'Taza de Talavera', 22000, 10),
          ProductoTienda('jarron', 'Jarrón azul', 125000, 4),
        ]),
      ];

  /// Datos de práctica: cada persona empieza con $1,000 de saldo "de juguete".
  void cargarDatosDemo() {
    for (final p in perfiles) {
      monedero.depositar(p.id, 100000, clave: 'demo-inicial', concepto: 'Saldo de práctica');
    }
  }

  ContextoMiniApp contextoPara(MiniApp app, String usuarioId) =>
      ContextoMiniApp(app, usuarioId, registro, monedero, mensajes, comercio, viajes);
}