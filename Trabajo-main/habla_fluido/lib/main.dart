import 'package:flutter/material.dart';

import 'dependencias.dart';
import 'presentacion/pantallas/pantalla_inicio.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HablaFluidoApp());
}

class HablaFluidoApp extends StatefulWidget {
  const HablaFluidoApp({super.key});
  @override
  State<HablaFluidoApp> createState() => _HablaFluidoAppState();
}

class _HablaFluidoAppState extends State<HablaFluidoApp> {
  late final Dependencias deps = Dependencias.crear();
  late final Future<void> _inicio = deps.aprendizaje.cargar();

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Habla Fluido',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: const Color(0xFF0E7C86), useMaterial3: true),
        home: FutureBuilder<void>(
          future: _inicio,
          builder: (_, s) => s.connectionState == ConnectionState.done
              ? PantallaInicio(deps: deps)
              : const Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
      );
}