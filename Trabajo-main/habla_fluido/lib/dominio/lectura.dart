import 'nivel.dart';
class PreguntaLectura {
  final String enunciado;
  final List<String> opciones;
  final int correcta; // índice en [opciones]
  const PreguntaLectura(this.enunciado, this.opciones, this.correcta);
}

class TextoLectura {
  final String id;
  final String titulo;
  final String texto;
  final NivelCefr nivel;
  final List<PreguntaLectura> preguntas;
  const TextoLectura(this.id, this.titulo, this.texto, this.nivel, this.preguntas);
}

const catalogoLecturas = <TextoLectura>[
  TextoLectura(
    'l-a1-01',
    'My Morning',

    'My name is Ana. I live in Dolores Hidalgo. Every morning I wake up at six. I drink coffee and eat bread. Then I walk to school with my friend Luis.',
    NivelCefr.a1,
    [
      PreguntaLectura('What time does Ana wake up?', ['At five', 'At six', 'At seven'], 1),
      PreguntaLectura('What does Ana drink?', ['Coffee', 'Milk', 'Juice'], 0),

      PreguntaLectura('Who walks with Ana?', ['Her mother', 'Her teacher', 'Her friend Luis'], 2),
    ],
  ),
  TextoLectura(
    'l-a2-01',
    'A Weekend in Guanajuato',


    'Last weekend, Carlos visited Guanajuato with his family. They walked through the narrow streets and took many photos. On Sunday it rained, so they stayed in a cafe and played cards. Carlos says he wants to go back in the summer.',
    NivelCefr.a2,
    [

      PreguntaLectura('Who did Carlos travel with?', ['His family', 'His classmates', 'Alone'], 0),

      PreguntaLectura('Why did they stay in a cafe?', ['They were hungry', 'It rained', 'They were tired'], 1),

      PreguntaLectura('When does Carlos want to return?', ['In winter', 'Next week', 'In the summer'], 2),
    ],
  ),
];


List<TextoLectura> lecturasDeNivel(NivelCefr n) => catalogoLecturas.where((t) => t.nivel == n).toList();