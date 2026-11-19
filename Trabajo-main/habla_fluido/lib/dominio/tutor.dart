import 'dart:convert';

import 'excepciones.dart';
import 'nivel.dart';

class Correccion {
  final String original;
  final String corregido;
  final String explicacion;
  const Correccion(this.original, this.corregido, this.explicacion);
}

class RespuestaTutor {
  final String respuesta;
  final List<Correccion> correcciones;
  final String? siguientePregunta;
  final String? textoCorregido;


  const RespuestaTutor(this.respuesta, {this.correcciones = const [], this.siguientePregunta, this.textoCorregido});

  /// La salida de la IA es entrada NO confiable: se valida como cualquier dato externo.
  /// Acepta JSON "limpio" o envuelto en texto/cercas de markdown.
  static RespuestaTutor desdeTexto(String texto) {
    final a = texto.indexOf('{');
    final b = texto.lastIndexOf('}');
    if (a < 0 || b <= a) throw const TutorInvalidoException();
    final Object? o;
    try {
      o = jsonDecode(texto.substring(a, b + 1));
    } catch (_) {
      throw const TutorInvalidoException();
    }
    return desdeMapa(o);
  }

  static RespuestaTutor desdeMapa(Object? o) {
    if (o is! Map) throw const TutorInvalidoException();
    final respuesta = _texto(o['respuesta'], 1000);
    if (respuesta == null) throw const TutorInvalidoException();
    final cs = <Correccion>[];
    final lista = o['correcciones'];
    if (lista is List) {
      for (final c in lista.take(5)) {
        if (c is! Map) continue;
        final orig = _texto(c['original'], 300);
        final corr = _texto(c['corregido'], 300);
        final expl = _texto(c['explicacion'], 400);
        if (orig != null && corr != null && expl != null) cs.add(Correccion(orig, corr, expl));
      }
    }
    return RespuestaTutor(
      respuesta,
      correcciones: cs,
      siguientePregunta: _texto(o['siguientePregunta'], 300),
      textoCorregido: _texto(o['textoCorregido'], 2000),
    );
  }

  static String? _texto(Object? v, int max) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty || t.length > max ? null : t;
  }
}

class Mensaje {
  final bool delEstudiante;
  final String texto;
  const Mensaje(this.delEstudiante, this.texto);
}

abstract class TutorIA {

  Future<RespuestaTutor> conversar({required NivelCefr nivel, required List<Mensaje> historial});
  Future<RespuestaTutor> corregir({required NivelCefr nivel, required String texto});
}