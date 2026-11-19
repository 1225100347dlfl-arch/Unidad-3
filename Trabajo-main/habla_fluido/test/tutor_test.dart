import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habla_fluido/datos/tutor_http.dart';
import 'package:habla_fluido/datos/tutor_simulado.dart';
import 'package:habla_fluido/dominio/excepciones.dart';
import 'package:habla_fluido/dominio/nivel.dart';
import 'package:habla_fluido/dominio/tutor.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response json(Object o, [int codigo = 200]) =>

    http.Response.bytes(utf8.encode(jsonEncode(o)), codigo, headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  group('RespuestaTutor.desdeTexto (la salida de la IA es entrada NO confiable)', () {
    test('JSON limpio', () {
      final r = RespuestaTutor.desdeTexto(

          '{"respuesta":"Nice!","correcciones":[{"original":"a","corregido":"b","explicacion":"c" }],"siguientePregunta":"Why?"}');
      expect(r.respuesta, 'Nice!');
      expect(r.correcciones.single.corregido, 'b');
      expect(r.siguientePregunta, 'Why?');
    });
    test('JSON envuelto en cercas de markdown', () {
      final r = RespuestaTutor.desdeTexto('```json\n{"respuesta":"Hi"}\n```');
      expect(r.respuesta, 'Hi');
      expect(r.correcciones, isEmpty);
    });
    test('descarta correcciones incompletas y limita a 5', () {
      final cs = [
        for (var i = 0; i < 8; i++) {'original': 'a$i', 'corregido': 'b', 'explicacion': 'c'},
        {'original': 'solo'},
      ];

      final r = RespuestaTutor.desdeTexto(jsonEncode({'respuesta': 'ok', 'correcciones': cs}));
      expect(r.correcciones.length, 5);
    });
    test('textos vacíos o demasiado largos se ignoran', () {

      final r = RespuestaTutor.desdeTexto(jsonEncode({'respuesta': 'ok', 'siguientePregunta': 'x' * 301}));
      expect(r.siguientePregunta, isNull);
    });
    test('basura lanza TutorInvalido', () {
      for (final malo in ['hola', '{rota', '{"correcciones":[]}', '{"respuesta":""}', '[]']) {

        expect(() => RespuestaTutor.desdeTexto(malo), throwsA(isA<TutorInvalidoException>()), reason: malo);
      }
    });
  });

  group('TutorSimulado', () {
    final t = TutorSimulado();
    test('corrige "I am agree"', () async {

      final r = await t.conversar(nivel: NivelCefr.a2, historial: [const Mensaje(true, 'I am agree with you')]);
      expect(r.correcciones.single.corregido, 'I agree');
      expect(r.siguientePregunta, isNotNull);
    });
    test('tercera persona: he go → he goes', () async {
      final r = await t.corregir(nivel: NivelCefr.a1, texto: 'He go to school every day');
      expect(r.correcciones.single.corregido, 'He goes');
      expect(r.textoCorregido, 'He goes to school every day');
    });
    test('máximo 2 correcciones por turno', () async {

      final r = await t.corregir(nivel: NivelCefr.a1, texto: 'i am agree and he go and more better');
      expect(r.correcciones.length, 2);
    });
    test('texto correcto no recibe correcciones', () async {
      final r = await t.corregir(nivel: NivelCefr.a1, texto: 'I like coffee very much');
      expect(r.correcciones, isEmpty);
      expect(r.textoCorregido, 'I like coffee very much');
    });
  });

  group('TutorHttp', () {
    final ok = {'respuesta': 'Great!', 'correcciones': []};

    test('exige HTTPS', () {

      expect(() => TutorHttp(Uri.parse('http://ejemplo.com/tutor'), MockClient((_) async => json(ok))),
          throwsArgumentError);
    });
    test('permite http solo a localhost y solo si se autoriza', () {

      expect(() => TutorHttp(Uri.parse('http://10.0.2.2:8787/tutor'), MockClient((_) async => json(ok))),
          throwsArgumentError);

      expect(() => TutorHttp(Uri.parse('http://10.0.2.2:8787/tutor'), MockClient((_) async => json(ok)),
          permitirHttpLocal: true), returnsNormally);

      expect(() => TutorHttp(Uri.parse('http://evil.com/tutor'), MockClient((_) async => json(ok)),
          permitirHttpLocal: true), throwsArgumentError);
    });
    test('envía nivel, modo, roles y token; interpreta la respuesta', () async {
      late http.Request visto;
      final t = TutorHttp(Uri.parse('https://x.com/tutor'), MockClient((r) async {
        visto = r;
        return json(ok);
      }), tokenApp: 'abc');
      final r = await t.conversar(nivel: NivelCefr.b1, historial: [
        const Mensaje(false, 'Hi! How was your day?'), // saludo local: se recorta
        const Mensaje(true, 'Good'),
      ]);
      expect(r.respuesta, 'Great!');
      final cuerpo = jsonDecode(visto.body) as Map;
      expect(cuerpo['nivel'], 'b1');
      expect(cuerpo['modo'], 'conversar');
      expect((cuerpo['mensajes'] as List).length, 1);
      expect((cuerpo['mensajes'] as List).first, {'rol': 'user', 'contenido': 'Good'});
      expect(visto.headers['x-app-token'], 'abc');
    });

    test('recorta el historial a los últimos 20 mensajes y los textos a 500 caracteres', () async {
      late Map cuerpo;
      final t = TutorHttp(Uri.parse('https://x.com/tutor'), MockClient((r) async {
        cuerpo = jsonDecode(r.body) as Map;
        return json(ok);
      }));
      final h = [for (var i = 0; i < 31; i++) Mensaje(i.isEven, 'm$i')];
      h[30] = Mensaje(true, 'x' * 900);
      await t.conversar(nivel: NivelCefr.a1, historial: h);
      final ms = cuerpo['mensajes'] as List;
      expect(ms.length, lessThanOrEqualTo(20));
      expect(ms.first['rol'], 'user');
      expect((ms.last['contenido'] as String).length, 500);
    });
    test('estado distinto de 200 → TutorNoDisponible', () async {
      final t = TutorHttp(Uri.parse('https://x.com/tutor'), MockClient((_) async => json({'error': 'x'}, 502)));
      expect(() => t.corregir(nivel: NivelCefr.a1, texto: 'hello there my friend'),
          throwsA(isA<TutorNoDisponibleException>()));
    });
    test('error de red → TutorNoDisponible', () async {

      final t = TutorHttp(Uri.parse('https://x.com/tutor'), MockClient((_) async => throw Exception('sin red')));
      expect(() => t.corregir(nivel: NivelCefr.a1, texto: 'hello there my friend'),
          throwsA(isA<TutorNoDisponibleException>()));
    });
    test('respuesta con forma incorrecta → TutorInvalido', () async {

      final t = TutorHttp(Uri.parse('https://x.com/tutor'), MockClient((_) async => json({'otra': 1})));
      expect(() => t.corregir(nivel: NivelCefr.a1, texto: 'hello there my friend'),
          throwsA(isA<TutorInvalidoException>()));
    });
    test('acentos y ñ llegan bien (UTF-8)', () async {
      final t = TutorHttp(Uri.parse('https://x.com/tutor'),
          MockClient((_) async => json({'respuesta': 'Muy bien, ¡qué pronunciación!'})));
      final r = await t.corregir(nivel: NivelCefr.a1, texto: 'hello there my friend');
      expect(r.respuesta, 'Muy bien, ¡qué pronunciación!');
    });
  });
}