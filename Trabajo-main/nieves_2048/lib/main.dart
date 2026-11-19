import 'package:flutter/material.dart';
import 'presentation/juego_screen.dart';

void main() => runApp(const Nieves2048App());

class Nieves2048App extends StatelessWidget {
  const Nieves2048App({super.key});
<<<<<<< HEAD
=======

>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nieves 2048',
      theme: ThemeData(primarySwatch: Colors.pink, useMaterial3: true),
      home: const JuegoScreen(),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
