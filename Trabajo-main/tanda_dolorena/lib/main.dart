import 'package:flutter/material.dart';
import 'presentation/tanda_screen.dart';

void main() => runApp(const TandaApp());

class TandaApp extends StatelessWidget {
  const TandaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tanda Dolorena',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const TandaScreen(),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 979cce114426bcb50e86e893f9500793b2ed1b6c
