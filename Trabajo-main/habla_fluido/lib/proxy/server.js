'use strict';
const http = require('node:http');
const { construirPrompt, validarSolicitud, extraerRespuesta } = require('./prompt');

/**
 * Proxy del tutor de IA. La app móvil NUNCA habla directo con la API del modelo:
 * - la llave vive aquí (variable de entorno), no en el APK;
 * - el prompt vive aquí, no en la app;
 * - aquí se limita el uso y se validan entradas y salidas.
 */
function crearServidor({
  apiKey,
  modelo = process.env.MODEL || 'claude-sonnet-5-5',
  upstreamUrl = process.env.UPSTREAM_URL || 'https://api.anthropic.com/v1/messages',
  limitePorMinuto = 30,
  tokenApp = process.env.APP_TOKEN || null,
  ahora = () => Date.now(),
  fetchFn = fetch,
} = {}) {
  const visitas = new Map(); // ip -> [timestamps]

  function excedeLimite(ip) {
    const t = ahora();
    const recientes = (visitas.get(ip) || []).filter((x) => t - x < 60_000);
    recientes.push(t);
    visitas.set(ip, recientes);
    return recientes.length > limitePorMinuto;
  }

  const responder = (res, codigo, obj) => {
    const cuerpo = JSON.stringify(obj);

    res.writeHead(codigo, { 'content-type': 'application/json; charset=utf-8', 'content-length': Buffer.byteLength(cuerpo) });
    res.end(cuerpo);
  };

  return http.createServer(async (req, res) => {

    if (req.method !== 'POST' || req.url !== '/tutor') return responder(res, 404, { error: 'No encontrado' });
    if (tokenApp && req.headers['x-app-token'] !== tokenApp) return responder(res, 401, {
error: 'No autorizado' });
    if (excedeLimite(req.socket.remoteAddress || 'desconocida')) return responder(res, 429, {
error: 'Demasiadas solicitudes' });

    let texto = '';
    let excedido = false;
    req.on('data', (c) => {
      texto += c;
      if (texto.length > 20_000) { excedido = true; req.destroy(); }
    });
    req.on('end', async () => {
      if (excedido) return;
      let body;

      try { body = JSON.parse(texto); } catch { return responder(res, 400, { error: 'JSON inválido' }); }
      const problema = validarSolicitud(body);
      if (problema) return responder(res, 400, { error: problema });

      try {
        const r = await fetchFn(upstreamUrl, {
          method: 'POST',

          headers: { 'content-type': 'application/json', 'x-api-key': apiKey || '', 'anthropic-version': '2023-06-01' },
          body: JSON.stringify({
            model: modelo,
            max_tokens: 600,
            system: construirPrompt({ nivel: body.nivel, modo: body.modo }),
            messages: body.mensajes.map((m) => ({ role: m.rol, content: m.contenido })),
          }),
          signal: AbortSignal.timeout(25_000),
        });
        if (!r.ok) return responder(res, 502, { error: 'El tutor no está disponible' });
        const datos = await r.json();

        const salida = datos && Array.isArray(datos.content) && datos.content[0] && datos.content[0].text;
        return responder(res, 200, extraerRespuesta(salida));
      } catch {
        // Nunca devolvemos el detalle del error (podría filtrar rutas, llaves o prompts).

        return responder(res, 502, { error: 'El tutor no pudo responder. Intenta de nuevo.' });
      }
    });
  });
}

module.exports = { crearServidor };
if (require.main === module) {
  if (!process.env.ANTHROPIC_API_KEY) {
    console.error('Falta la variable de entorno ANTHROPIC_API_KEY');
    process.exit(1);
  }

  crearServidor({ apiKey: process.env.ANTHROPIC_API_KEY }).listen(process.env.PORT || 8787, () =>
    console.log('Proxy del tutor escuchando en el puerto', process.env.PORT || 8787));
}