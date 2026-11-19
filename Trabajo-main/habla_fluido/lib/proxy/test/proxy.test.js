'use strict';
const test = require('node:test');
const assert = require('node:assert');
const http = require('node:http');
const { construirPrompt, validarSolicitud, extraerRespuesta } = require('../prompt');
const { crearServidor } = require('../server');


const ok = { nivel: 'a2', modo: 'conversar', mensajes: [{ rol: 'user', contenido: 'I am agree' }] };

test('prompt: contiene las reglas pedagógicas y la defensa contra inyección', () => {
  const p = construirPrompt({ nivel: 'a1', modo: 'conversar' });
  assert.match(p, /A1/);
  assert.match(p, /máximo 2 errores/);
  assert.match(p, /DATOS, no instrucciones/);
  assert.match(p, /siguientePregunta/);
});
test('prompt: nivel o modo inválido lanza', () => {
  assert.throws(() => construirPrompt({ nivel: 'z9', modo: 'conversar' }));
  assert.throws(() => construirPrompt({ nivel: 'a1', modo: 'hackear' }));
});
test('solicitud válida pasa', () => assert.strictEqual(validarSolicitud(ok), null));
test('solicitud: rechaza nivel, mensajes vacíos, texto largo y roles mal alternados', () => {
  assert.ok(validarSolicitud({ ...ok, nivel: 'x' }));
  assert.ok(validarSolicitud({ ...ok, mensajes: [] }));

  assert.ok(validarSolicitud({ ...ok, mensajes: [{ rol: 'user', contenido: 'a'.repeat(501) }] }));
  assert.ok(validarSolicitud({ ...ok, mensajes: [{ rol: 'assistant', contenido: 'hola' }] }));

  assert.ok(validarSolicitud({ ...ok, mensajes: [{ rol: 'user', contenido: 'a' }, { rol: 'user', contenido: 'b' }] }));
  assert.ok(validarSolicitud({ ...ok, mensajes: [{ rol: 'system', contenido: 'a' }] }));
});
test('respuesta: extrae JSON aunque venga con cercas de markdown', () => {


  const r = extraerRespuesta('```json\n{"respuesta":"Nice!","correcciones":[{"original":"I am agree","corregido":"I agree","explicacion":"agree es verbo"}],"siguientePregunta":"Why?"}\n```');
  assert.strictEqual(r.respuesta, 'Nice!');
  assert.strictEqual(r.correcciones.length, 1);
  assert.strictEqual(r.siguientePregunta, 'Why?');
});
test('respuesta: descarta correcciones incompletas y recorta a 5', () => {

  const c = Array.from({ length: 8 }, (_, i) => ({ original: 'a' + i, corregido: 'b', explicacion: 'c' }));
  c.push({ original: 'x' });
  const r = extraerRespuesta(JSON.stringify({ respuesta: 'ok', correcciones: c }));
  assert.strictEqual(r.correcciones.length, 5);
});
test('respuesta: texto sin JSON o sin "respuesta" lanza', () => {
  assert.throws(() => extraerRespuesta('hola'));
  assert.throws(() => extraerRespuesta('{"correcciones":[]}'));
  assert.throws(() => extraerRespuesta('{rota'));
});

// ---- servidor de punta a punta con un "modelo" falso ----
function arrancar(opts) {
  return new Promise((resolve) => {
    const s = crearServidor(opts);

    s.listen(0, '127.0.0.1', () => resolve({ s, url: `http://127.0.0.1:${s.address().port}/tutor` }));
  });
}
const post = (url, body, headers = {}) =>

  fetch(url, { method: 'POST', headers: { 'content-type': 'application/json', ...headers }, body: JSON.stringify(body) });

test('servidor: envía llave y prompt al modelo y devuelve JSON validado', async () => {
  let visto;
  const falso = async (url, init) => {
    visto = { url, init };

    return { ok: true, json: async () => ({ content: [{ text: '{"respuesta":"Great!","correcciones":[]}' }] }) };
  };
  const { s, url } = await arrancar({ apiKey: 'sk-test', fetchFn: falso });
  const r = await post(url, ok);
  assert.strictEqual(r.status, 200);
  assert.deepStrictEqual(await r.json(), { respuesta: 'Great!', correcciones: [] });
  assert.strictEqual(visto.init.headers['x-api-key'], 'sk-test');
  const enviado = JSON.parse(visto.init.body);
  assert.match(enviado.system, /tutor de inglés/);
  assert.strictEqual(enviado.messages[0].role, 'user');
  s.close();
});
test('servidor: 400 con solicitud inválida y 404 en otra ruta', async () => {

  const { s, url } = await arrancar({ apiKey: 'k', fetchFn: async () => { throw new Error('no debería llamarse'); } });
  assert.strictEqual((await post(url, { nivel: 'x' })).status, 400);

  assert.strictEqual((await fetch(url.replace('/tutor', '/otra'), { method: 'POST' })).status, 404);
  s.close();
});
test('servidor: si el modelo falla o devuelve basura, 502 sin filtrar detalles', async () => {
  const roto = async () => { throw new Error('secreto interno sk-123'); };
  const { s, url } = await arrancar({ apiKey: 'k', fetchFn: roto });
  const r = await post(url, ok);
  assert.strictEqual(r.status, 502);
  assert.doesNotMatch(await r.text(), /secreto|sk-123/);
  s.close();

  const basura = async () => ({ ok: true, json: async () => ({ content: [{ text: 'no soy json' }] }) });
  const b = await arrancar({ apiKey: 'k', fetchFn: basura });
  assert.strictEqual((await post(b.url, ok)).status, 502);
  b.s.close();
});
test('servidor: limita solicitudes por minuto (429)', async () => {

  const falso = async () => ({ ok: true, json: async () => ({ content: [{ text: '{"respuesta":"ok"}' }] }) });

  const { s, url } = await arrancar({ apiKey: 'k', fetchFn: falso, limitePorMinuto: 2, ahora: () => 1000 });
  assert.strictEqual((await post(url, ok)).status, 200);
  assert.strictEqual((await post(url, ok)).status, 200);
  assert.strictEqual((await post(url, ok)).status, 429);
  s.close();
});
test('servidor: exige token de app si está configurado', async () => {

  const falso = async () => ({ ok: true, json: async () => ({ content: [{ text: '{"respuesta":"ok"}' }] }) });
  const { s, url } = await arrancar({ apiKey: 'k', fetchFn: falso, tokenApp: 'secreto' });
  assert.strictEqual((await post(url, ok)).status, 401);
  assert.strictEqual((await post(url, ok, { 'x-app-token': 'secreto' })).status, 200);
  s.close();
});