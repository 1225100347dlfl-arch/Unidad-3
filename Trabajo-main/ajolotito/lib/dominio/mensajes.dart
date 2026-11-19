class Mensaje {
  const Mensaje(this.titulo, this.cuerpo);
  final String titulo;
  final String cuerpo;
}

/// Textos con personalidad. Se elige uno según una semilla determinista
/// (el día) para no repetir siempre lo mismo y poder probarlo.
class Mensajes {
  static const _hambre = <(String, String)>[
    ('{n} tiene hambre 🥺', 'Un acocil, por favor. Sus branquias ya se arrugaron de tanto esperar.'),
    ('Glub, glub… 🫧', '{n} dice que su pancita hace más ruido que una banda de pueblo.'),
    ('¡Hora de la comida! 🍽️', '{n} soñó con tamales de plancton. ¿Le cumples?'),
    ('{n} pide botana 🦐', 'Nada elegante: unas larvitas y se pone feliz.'),
  ];

  static const _critico = <(String, String)>[
    ('{n} está muy triste 😢', 'Lleva horas sin comer y te mira con ojitos de cachorro. ¡Aliméntalo!'),
    ('SOS desde el acuario 🆘', '{n} ya está pensando en comerse el decorado. Rescátalo.'),
    ('Hambre nivel: ajolote 😵', 'Casi se desvanece de hambre. Un acocil y todo se arregla.'),
  ];

  static const _sorpresa = <(String, String)>[
    ('{n} quiere jugar 🎈', 'Dice que aprendió un truco nuevo: quedarse quieto. Le sale perfecto.'),
    ('Dato curioso 🤓', 'Los ajolotes pueden regenerar una patita. ¿Y tú, ya regeneraste tu paciencia?'),
    ('¡Pasa a saludar! 👋', '{n} se peinó las branquias para ti.'),
    ('Plan de la tarde 🌇', '{n} propone: nadar, mirar la pared y pedirte comida.'),
  ];

  static Mensaje _elegir(List<(String, String)> l, String n, int semilla) {
    final (t, c) = l[semilla.abs() % l.length];
    return Mensaje(t.replaceAll('{n}', n), c.replaceAll('{n}', n));
  }

  static Mensaje hambre(String n, int semilla) => _elegir(_hambre, n, semilla);
  static Mensaje critico(String n, int semilla) => _elegir(_critico, n, semilla);
  static Mensaje sorpresa(String n, int semilla) => _elegir(_sorpresa, n, semilla);
}