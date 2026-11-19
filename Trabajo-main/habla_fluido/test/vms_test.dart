import 'package:flutter_test/flutter_test.dart';
import 'package:habla_fluido/datos/almacen_avance.dart';
import 'package:habla_fluido/datos/tutor_simulado.dart';
import 'package:habla_fluido/datos/voz_simulada.dart';
import 'package:habla_fluido/dominio/frase.dart';
import 'package:habla_fluido/dominio/nivel.dart';
import 'package:habla_fluido/dominio/tutor.dart';
import 'package:habla_fluido/dominio/voz.dart';
import 'package:habla_fluido/presentacion/vm/aprendizaje_vm.dart';
import 'package:habla_fluido/presentacion/vm/conversacion_vm.dart';
import 'package:habla_fluido/presentacion/vm/dictado_vm.dart';
import 'package:habla_fluido/presentacion/vm/escritura_vm.dart';
import 'package:habla_fluido/presentacion/vm/lectura_vm.dart';
import 'package:habla_fluido/presentacion/vm/pronunciacion_vm.dart';
import 'package:habla_fluido/presentacion/vm/repaso_vm.dart';

var _dia = DateTime(2026, 11, 5);
AprendizajeViewModel nuevoCerebro([AlmacenAvanceMemoria? a]) =>
    AprendizajeViewModel(a ?? AlmacenAvanceMemoria(), reloj: () => _dia);

/// Tutor que falla las primeras N veces con un error "desconocido".
class TutorQueFalla implements TutorIA {
  int fallos;
  final List<List<Mensaje>> vistos = [];
  TutorQueFalla(this.fallos);
  @override

  Future<RespuestaTutor> conversar({required NivelCefr nivel, required List<Mensaje> historial}) async {
    vistos.add([...historial]);
    if (fallos-- > 0) throw Exception('sin red: detalle interno secreto');
    return const RespuestaTutor('Nice!', siguientePregunta: 'And you?');
  }
  @override
  Future<RespuestaTutor> corregir({required NivelCefr nivel, required String texto}) =>
      throw UnimplementedError();
}

/// Voz cuya reproducción nunca termina hasta que se libera (para probar el doble toque).
class VozLenta implements Voz {
  int llamadas = 0;
  @override
  Future<void> hablar(String texto, {double velocidad = 1.0}) async {
    llamadas++;
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
  @override
  Future<String?> escuchar({Duration limite = const Duration(seconds: 8)}) async => 'x';
  @override
  Future<void> detener() async {}
}
void main() {
  setUp(() => _dia = DateTime(2026, 11, 5));

  group('PronunciacionViewModel', () {
    test('compara, registra el intento y crea tarjeta de repaso', () async {
      final cerebro = nuevoCerebro();
      final vm = PronunciacionViewModel(VozSimulada(['nice to meet you']), cerebro);
      await vm.grabar();
      expect(vm.resultado!.puntaje, 1.0);
      expect(cerebro.progreso.de(Habilidad.pronunciacion)!.intentos, 1);
      expect(cerebro.mazo.todas.single.id, 'a1-01');
    });
    test('silencio → mensaje amable y no registra nada', () async {
      final cerebro = nuevoCerebro();
      final vm = PronunciacionViewModel(VozSimulada([null]), cerebro);
      await vm.grabar();
      expect(vm.error, contains('No te escuché'));
      expect(vm.resultado, isNull);
      expect(cerebro.progreso.de(Habilidad.pronunciacion), isNull);
    });
    test('el modelo lento usa velocidad 0.6', () async {
      final voz = VozSimulada();
      final vm = PronunciacionViewModel(voz, nuevoCerebro());
      await vm.escucharModelo(lento: true);
      expect(voz.velocidades.single, 0.6);
      expect(voz.dichos.single, 'Nice to meet you.');
    });
    test('un error del micrófono no revela detalles', () async {
      final vm = PronunciacionViewModel(_VozRota(), nuevoCerebro());
      await vm.grabar();
      expect(vm.error, 'Ocurrió un error inesperado. Intenta de nuevo.');
    });
    test('siguiente avanza y limpia el resultado', () async {
      final vm = PronunciacionViewModel(VozSimulada(['hola']), nuevoCerebro());
      await vm.grabar();
      vm.siguiente();
      expect(vm.resultado, isNull);
      expect(vm.actual.id, 'a1-02');
    });
    test('doble toque en "Escuchar" se ignora mientras habla', () async {
      final voz = VozLenta();
      final vm = PronunciacionViewModel(voz, nuevoCerebro());
      final a = vm.escucharModelo();
      final b = vm.escucharModelo();
      await Future.wait([a, b]);
      expect(voz.llamadas, 1);
    });
  });

  group('DictadoViewModel', () {
    test('exige escuchar primero', () async {
      final vm = DictadoViewModel(VozSimulada(), nuevoCerebro());
      await vm.enviar('algo');
      expect(vm.error, 'Primero escucha la frase.');
    });
    test('puntúa el oído y registra', () async {
      final cerebro = nuevoCerebro();
      final vm = DictadoViewModel(VozSimulada(), cerebro);
      await vm.reproducir();
      await vm.enviar('nice to meet you');
      expect(vm.resultado!.puntaje, 1.0);
      expect(cerebro.progreso.de(Habilidad.escucha)!.intentos, 1);
    });
    test('texto vacío', () async {
      final vm = DictadoViewModel(VozSimulada(), nuevoCerebro());
      await vm.reproducir();
      await vm.enviar(' ');
      expect(vm.error, 'Escribe lo que entendiste.');
    });
    test('siguiente reinicia las reproducciones', () async {
      final vm = DictadoViewModel(VozSimulada(), nuevoCerebro());
      await vm.reproducir();
      vm.siguiente();
      expect(vm.reproducciones, 0);
    });
  });

  group('LecturaViewModel', () {
    test('puntúa cuando se responden todas, una sola vez', () async {
      final cerebro = nuevoCerebro();
      final vm = LecturaViewModel(cerebro);
      await vm.responder(0, 1); // correcta
      await vm.responder(1, 2); // incorrecta
      expect(vm.terminado, isFalse);
      await vm.responder(2, 2); // correcta
      expect(vm.terminado, isTrue);
      expect(vm.correctas, 2);
      expect(vm.puntaje, closeTo(2 / 3, 1e-9));
      await vm.responder(0, 0); // intento de cambiar: ignorado
      expect(vm.correctas, 2);
      expect(cerebro.progreso.de(Habilidad.lectura)!.intentos, 1);
    });
    test('opciones o preguntas inexistentes se ignoran', () async {
      final vm = LecturaViewModel(nuevoCerebro());
      await vm.responder(9, 0);
      await vm.responder(0, 9);
      expect(vm.respuestas, isEmpty);
    });
    test('siguienteTexto reinicia', () async {
      final vm = LecturaViewModel(nuevoCerebro());
      await vm.responder(0, 1);
      vm.siguienteTexto();
      expect(vm.respuestas, isEmpty);
    });
  });

  group('EscrituraViewModel', () {
    test('menos de 5 palabras no se envía', () async {
      final vm = EscrituraViewModel(TutorSimulado(), nuevoCerebro());
      await vm.enviar('hello there');
      expect(vm.error, contains('5 palabras'));
      expect(vm.resultado, isNull);
    });
    test('texto con un error → puntaje 0.8 y se registra', () async {
      final cerebro = nuevoCerebro();
      final vm = EscrituraViewModel(TutorSimulado(), cerebro);
      await vm.enviar('He go to school every day');
      expect(vm.resultado!.correcciones.length, 1);
      expect(cerebro.progreso.dominioDe(Habilidad.escritura), closeTo(0.8, 1e-9));
    });
    test('puntajeDe', () {
      expect(EscrituraViewModel.puntajeDe(0), 1.0);
      expect(EscrituraViewModel.puntajeDe(2), closeTo(0.6, 1e-9));
      expect(EscrituraViewModel.puntajeDe(9), 0.0);
    });
  });
  group('ConversacionViewModel', () {
    test('inicia con un saludo del tutor, una sola vez', () {
      final vm = ConversacionViewModel(TutorSimulado(), VozSimulada(), nuevoCerebro());
      vm.iniciar();
      vm.iniciar();
      expect(vm.historial.length, 1);
      expect(vm.historial.single.delEstudiante, isFalse);
    });
    test('turno completo: mensajes, correcciones, voz y progreso', () async {
      final voz = VozSimulada();
      final cerebro = nuevoCerebro();
      final vm = ConversacionViewModel(TutorSimulado(), voz, cerebro)..iniciar();
      await vm.enviar('I am agree with you');
      expect(vm.historial.length, 3);
      expect(vm.ultimasCorrecciones.single.corregido, 'I agree');
      expect(voz.dichos.length, 1); // el tutor habló
      expect(cerebro.progreso.dominioDe(Habilidad.conversacion), closeTo(0.75, 1e-9));
    });
    test('sin autoVoz el tutor no habla', () async {
      final voz = VozSimulada();
      final vm = ConversacionViewModel(TutorSimulado(), voz, nuevoCerebro())
        ..iniciar()
        ..alternarAutoVoz();
      await vm.enviar('Hello');
      expect(voz.dichos, isEmpty);
    });

    test('si el tutor falla: mensaje genérico, historial sin duplicar roles y texto recuperable', () async {
      final tutor = TutorQueFalla(1);
      final vm = ConversacionViewModel(tutor, VozSimulada(), nuevoCerebro())..iniciar();
      await vm.enviar('My text');
      expect(vm.error, 'Ocurrió un error inesperado. Intenta de nuevo.');
      expect(vm.error, isNot(contains('secreto')));
      expect(vm.historial.length, 1); // solo el saludo
      expect(vm.textoNoEnviado, 'My text');
      await vm.enviar('My text'); // reintento
      expect(vm.historial.length, 3);
      expect(vm.error, isNull);
    });
    test('mensajes vacíos o enormes se rechazan sin llamar al tutor', () async {
      final tutor = TutorQueFalla(0);
      final vm = ConversacionViewModel(tutor, VozSimulada(), nuevoCerebro())..iniciar();
      await vm.enviar(' ');
      await vm.enviar('x' * 501);
      expect(tutor.vistos, isEmpty);
      expect(vm.error, contains('más corto'));
    });
    test('dictar: reconoce la voz y la envía', () async {

      final vm = ConversacionViewModel(TutorSimulado(), VozSimulada(['I like music']), nuevoCerebro())..iniciar();
      await vm.dictar();
      expect(vm.historial[1].texto, 'I like music');
    });
    test('puntajeTurno', () {
      expect(ConversacionViewModel.puntajeTurno(0), 1.0);
      expect(ConversacionViewModel.puntajeTurno(2), 0.5);
      expect(ConversacionViewModel.puntajeTurno(9), 0.0);
    });
  });

  group('AprendizajeViewModel y persistencia', () {
    test('guarda y recupera progreso y tarjetas', () async {
      final almacen = AlmacenAvanceMemoria();
      final a = nuevoCerebro(almacen);
      final vm = PronunciacionViewModel(VozSimulada(['nice to meet you']), a);
      await vm.grabar();

      final b = nuevoCerebro(almacen);
      await b.cargar();
      expect(b.progreso.dominioDe(Habilidad.pronunciacion), 1.0);
      expect(b.mazo.todas.length, 1);
    });
    test('un fallo al guardar no interrumpe la práctica', () async {
      final a = AprendizajeViewModel(_AlmacenRoto(), reloj: () => _dia);
      await a.registrarIntento(Habilidad.lectura, 1.0);
      expect(a.progreso.de(Habilidad.lectura)!.intentos, 1);
    });
    test('plan de 20 minutos', () {
      expect(nuevoCerebro().plan.fold<int>(0, (s, b) => s + b.minutos), 20);
    });
  });

  group('RepasoViewModel', () {
    Future<AprendizajeViewModel> conTarjeta() async {
      final a = nuevoCerebro();
      await a.registrarIntento(Habilidad.pronunciacion, 0.2,
          frase: catalogoFrases.first);
      _dia = DateTime(2026, 11, 6); // pasó un día: la tarjeta vence
      return a;
    }

    test('hay que ver la respuesta antes de calificar', () async {
      final a = await conTarjeta();
      final vm = RepasoViewModel(a, VozSimulada());
      expect(vm.restantes, 1);
      await vm.calificar(5);
      expect(vm.restantes, 1);
    });
    test('calificar bien la saca de la cola y la aleja', () async {
      final a = await conTarjeta();
      final vm = RepasoViewModel(a, VozSimulada());
      await vm.mostrarRespuesta();
      await vm.calificar(5);
      expect(vm.terminado, isTrue);
      expect(a.pendientes, isEmpty);
    });
    test('"otra vez" la vuelve a poner al final de la cola', () async {
      final a = await conTarjeta();
      final vm = RepasoViewModel(a, VozSimulada());
      await vm.mostrarRespuesta();
      await vm.calificar(1);
      expect(vm.restantes, 1);
      expect(vm.respuestaVisible, isFalse);
    });
  });
}

class _VozRota implements Voz {
  @override

  Future<void> hablar(String texto, {double velocidad = 1.0}) async => throw Exception('boom');
  @override

  Future<String?> escuchar({Duration limite = const Duration(seconds: 8)}) async => throw Exception('boom');
  @override
  Future<void> detener() async {}
}

class _AlmacenRoto extends AlmacenAvanceMemoria {
  @override
  Future<void> guardar(Map<String, Object?> datos) async => throw Exception('disco lleno');
}