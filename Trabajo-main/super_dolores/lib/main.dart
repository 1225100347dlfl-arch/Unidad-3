import 'package:flutter/material.dart';

import 'dominio/dinero.dart';
import 'dominio/mini_app.dart';
import 'dominio/plataforma.dart';
import 'presentacion/pantallas/pantalla_chat.dart';
import 'presentacion/pantallas/pantalla_inicio.dart';
import 'presentacion/pantallas/pantalla_monedero.dart';
import 'presentacion/pantallas/pantalla_tienda.dart';
import 'presentacion/pantallas/pantalla_viajes.dart';
import 'presentacion/vm/inicio_vm.dart';

void main() => runApp(const SuperDoloresApp());

class SuperDoloresApp extends StatelessWidget {
  const SuperDoloresApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Super Dolores',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: const Color(0xFF6A1B9A), useMaterial3: true),
        home: const Concha(),
      );
}

/// La "concha" (shell) de la SuperApp: identidad única + navegación entre mini-apps.
class Concha extends StatefulWidget {
  const Concha({super.key});
  @override
  State<Concha> createState() => _ConchaState();
}

class _ConchaState extends State<Concha> {
  late final Plataforma plataforma = Plataforma()..cargarDatosDemo();
  late final InicioViewModel inicio = InicioViewModel(plataforma, 'ana');
  int _tab = 0;

  ({String id, String nombre, IconData icono}) _destino(MiniApp a) => (
        id: a.id,
        nombre: a.nombre,
        icono: switch (a.id) {
          'chat' => Icons.chat,
          'monedero' => Icons.account_balance_wallet,
          'tienda' => Icons.storefront,
          'viajes' => Icons.local_taxi,
          _ => Icons.apps,
        },
      );

  Widget _pagina(String id, String usuario) {
    final app = plataforma.registro.porId(id)!;
    final ctx = plataforma.contextoPara(app, usuario);
    final alCambiar = inicio.notificar;
    return switch (id) {
      'chat' => PantallaChat(contexto: ctx, alCambiar: alCambiar, plataforma: plataforma),
      'monedero' => PantallaMonedero(contexto: ctx, alCambiar: alCambiar, plataforma: plataforma),
      'tienda' => PantallaTienda(contexto: ctx, alCambiar: alCambiar),
      'viajes' => PantallaViajes(contexto: ctx, alCambiar: alCambiar),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: inicio,
        builder: (context, _) {
          final usuario = inicio.usuarioId;
          // Solo las mini-apps ACTIVAS aparecen: apagar una desde el registro la oculta sin actualizar la app.
          final apps = plataforma.registro.activas.where((a) => a.id != 'horoscopo').toList();
          final paginas = <Widget>[
            PantallaInicio(vm: inicio),
            for (final a in apps) KeyedSubtree(key: ValueKey('${a.id}-$usuario'), child: _pagina(a.id, usuario)),
          ];
          if (_tab >= paginas.length) _tab = 0;
          return Scaffold(
            body: IndexedStack(index: _tab, children: paginas),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: [
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: inicio.noLeidos > 0,
                    label: Text('${inicio.noLeidos}'),
                    child: const Icon(Icons.home),
                  ),
                  label: 'Inicio · ${formatearPesos(inicio.saldo)}',
                ),
                for (final a in apps)
                  NavigationDestination(icon: Icon(_destino(a).icono), label: a.nombre),
              ],
            ),
          );
        },
      );
}