import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../dominio/excepciones.dart';
import '../dominio/nivel.dart';
import '../dominio/tutor.dart';

/// Habla con TU proxy (ver carpeta proxy/), nunca directo con la API de la IA:
/// la llave y el prompt viven en el servidor.
class TutorHttp implements TutorIA {
  static const int maxMensajes = 20;
  static const int maxCaracteres = 500;

  final Uri endpoint;
  final http.Client _cliente;
  final Duration timeout;
  final Map<String, String> _cabeceras;

  TutorHttp(this.endpoint, this._cliente,

      {this.timeout = const Duration(seconds: 30), String? tokenApp, bool permitirHttpLocal = false})
      : _cabeceras = {
          'content-type': 'application/json',
          if (tokenApp != null) 'x-app-token': tokenApp,
        } {
    final seguro = endpoint.scheme == 'https';
    final local = permitirHttpLocal &&
        endpoint.scheme == 'http' &&

        (endpoint.host == 'localhost' || endpoint.host == '10.0.2.2' || endpoint.host == '127.0.0.1');
    if (!seguro && !local) throw ArgumentError('El tutor exige HTTPS');
  }
  @override

  Future<RespuestaTutor> conversar({required NivelCefr nivel, required List<Mensaje> historial}) {

    // El servidor exige alternar roles empezando por el estudiante: recortamos a los últimos N
    // y nos aseguramos de que el primero sea del estudiante.

    var h = historial.length > maxMensajes ? historial.sublist(historial.length - maxMensajes) : [...historial];
    while (h.isNotEmpty && !h.first.delEstudiante) {
      h = h.sublist(1);
    }
    return _enviar(nivel, 'conversar', h);
  }

  @override
  Future<RespuestaTutor> corregir({required NivelCefr nivel, required String texto}) =>
      _enviar(nivel, 'corregir', [Mensaje(true, texto)]);

  Future<RespuestaTutor> _enviar(NivelCefr nivel, String modo, List<Mensaje> mensajes) async {
    if (mensajes.isEmpty) throw const DatosInvalidosException('No hay nada que enviar.');
    final cuerpo = jsonEncode({
      'nivel': nivel.name,
      'modo': modo,
      'mensajes': [
        for (final m in mensajes)
          {
            'rol': m.delEstudiante ? 'user' : 'assistant',

            'contenido': m.texto.length > maxCaracteres ? m.texto.substring(0, maxCaracteres) : m.texto,
          },
      ],
    });
    final http.Response r;
    try {
      r = await _cliente.post(endpoint, headers: _cabeceras, body: cuerpo).timeout(timeout);
    } on TimeoutException {
      throw const TutorNoDisponibleException();
    } catch (_) {
      throw const TutorNoDisponibleException();
    }
    if (r.statusCode != 200) throw const TutorNoDisponibleException();
    try {
      return RespuestaTutor.desdeMapa(jsonDecode(utf8.decode(r.bodyBytes)));
    } on ErrorHablaFluido {
      rethrow;
    } catch (_) {
      throw const TutorInvalidoException();
    }
  }
}