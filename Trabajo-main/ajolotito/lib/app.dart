import 'package:flutter/material.dart';

import 'dominio/payload.dart';
import 'presentacion/ajolote_vm.dart';
import 'presentacion/pantalla_ajolote.dart';

class AppAjolote extends StatefulWidget {
  const AppAjolote({super.key, required this.vm, this.destinoInicial = Destino.inicio});
  final AjoloteViewModel vm;
  final Destino destinoInicial;

  @override
  State<AppAjolote> createState() => _AppAjoloteState();
}

class _AppAjoloteState extends State<AppAjolote> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.vm.iniciar(destino: widget.destinoInicial);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => widget.vm.alCambiarCicloDeVida(state);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Ajolotito',
        theme: ThemeData(colorSchemeSeed: const Color(0xFFE56B8F), useMaterial3: true),
        home: PantallaAjolote(vm: widget.vm),
      );
}