enum Importancia { baja, normal, alta }

/// Un canal es una "perilla" que el usuario controla en Ajustes del sistema.
class CanalNotif {
  const CanalNotif(this.id, this.nombre, this.descripcion, this.importancia);
  final String id;
  final String nombre;
  final String descripcion;
  final Importancia importancia;
}

enum Categoria {
  hambre(CanalNotif('hambre', 'Hambre del ajolote',
      'Te avisamos cuando tu ajolote necesita comer', Importancia.alta)),
  sorpresa(CanalNotif('sorpresas', 'Sorpresas y juegos',
      'Datos curiosos y invitaciones a jugar (máximo una al día)', Importancia.baja));

  const Categoria(this.canal);
  final CanalNotif canal;
}