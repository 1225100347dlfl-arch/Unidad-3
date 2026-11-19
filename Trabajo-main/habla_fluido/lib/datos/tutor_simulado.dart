import '../dominio/nivel.dart';
import '../dominio/reglas.dart';
import '../dominio/tutor.dart';

class _Regla {
  final RegExp patron;
  final String Function(Match) reemplazo;
  final String explicacion;
  const _Regla(this.patron, this.reemplazo, this.explicacion);
}

const _pasado = {'go': 'went', 'eat': 'ate', 'see': 'saw', 'buy': 'bought'};

const _terceraPersona = {'go': 'goes', 'have': 'has', 'do': 'does', 'like': 'likes', 'want': 'wants', 'live': 'lives', 'play': 'plays'};

final List<_Regla> _reglas = [
  _Regla(RegExp(r'\bi am agree\b', caseSensitive: false), (_) => 'I agree',
      '"agree" ya es un verbo: no lleva "am". Se dice "I agree".'),
  _Regla(RegExp(r'\bmore better\b', caseSensitive: false), (_) => 'better',
      '"better" ya es comparativo; no necesita "more".'),
  _Regla(
      RegExp(r'\b(he|she|it) (go|have|do|like|want|live|play)\b', caseSensitive: false),
      (m) => '${m[1]} ${_terceraPersona[m[2]!.toLowerCase()]}',
      'Con he/she/it, el verbo en presente lleva -s (o -es): he goes, she has.'),
  _Regla(RegExp(r'\bi (is|are)\b', caseSensitive: false), (_) => 'I am',
      'Con "I" se usa "am": I am.'),
  _Regla(RegExp(r'\byesterday i (go|eat|see|buy)\b', caseSensitive: false),
      (m) => 'yesterday I ${_pasado[m[1]!.toLowerCase()]}',
      'Con "yesterday" usa el pasado: went, ate, saw, bought.'),
];

const _temas = {

  NivelCefr.a1: ['What is your name?', 'Where do you live?', 'What do you eat for breakfast?', 'Do you have a pet?'],

  NivelCefr.a2: ['What did you do last weekend?', 'What is your favorite food?', 'Where would you like to travel?', 'Who is your best friend?'],

  NivelCefr.b1: ['What are your plans for next year?', 'Tell me about a book you enjoyed.', 'What would you change about your city?', 'Why are you learning English?'],

  NivelCefr.b2: ['What is a skill you want to master and why?', 'How has technology changed the way we study?'],

  NivelCefr.c1: ['How do you think education will look in 20 years?', 'What makes a good argument persuasive?'],
};

/// Tutor "de mentiras" basado en reglas: no necesita internet ni IA.
/// Sirve para (1) probar la app sin gastar dinero y (2) trabajar en el salón sin red.
class TutorSimulado implements TutorIA {
  int _turno = 0;
  List<Correccion> _detectar(String texto) {
    final out = <Correccion>[];
    for (final r in _reglas) {
      final m = r.patron.firstMatch(texto);
      if (m != null) out.add(Correccion(m[0]!, r.reemplazo(m), r.explicacion));
    }
    // "i" suelta en minúscula
    final sola = RegExp(r'(^|\s)i(\s|$)').firstMatch(texto);
    if (sola != null && out.length < Reglas.maxCorreccionesPorTurno) {

      out.add(const Correccion('i', 'I', 'En inglés, "I" (yo) siempre se escribe con mayúscula.'));
    }
    return out.take(Reglas.maxCorreccionesPorTurno).toList();
  }

  @override

  Future<RespuestaTutor> conversar({required NivelCefr nivel, required List<Mensaje> historial}) async {

    final ultimo = historial.lastWhere((m) => m.delEstudiante, orElse: () => const Mensaje(true, '')).texto;
    final correcciones = _detectar(ultimo);
    final temas = _temas[nivel]!;
    final pregunta = temas[_turno % temas.length];
    final animo = ['Nice!', 'Great!', 'Good job!', 'I see.'][_turno % 4];
    _turno++;

    return RespuestaTutor('$animo Thanks for sharing.', correcciones: correcciones, siguientePregunta: pregunta);
  }

  @override
  Future<RespuestaTutor> corregir({required NivelCefr nivel, required String texto}) async {
    final correcciones = _detectar(texto);
    var corregido = texto;
    for (final c in correcciones) {
      corregido = corregido.replaceFirst(c.original, c.corregido);
    }
    return RespuestaTutor(

      correcciones.isEmpty ? 'Well done! I found no mistakes.' : 'Good effort! Check these corrections.',
      correcciones: correcciones,
      textoCorregido: corregido,
      siguientePregunta: 'Write 3 sentences about your best day.',
    );
  }
}