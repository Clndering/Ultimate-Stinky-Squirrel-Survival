import { spawn } from 'node:child_process';
import { createReadStream } from 'node:fs';
import { access, stat } from 'node:fs/promises';
import { createServer, request as httpRequest } from 'node:http';
import { pipeline } from 'node:stream/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const projectRoot = fileURLToPath(new URL('../', import.meta.url));
const webDir = path.join(projectRoot, 'build', 'web');
const host = '127.0.0.1';
const webPort = 8080;
const rooms = new Map([
  ['/play', { id: 'fern-creek', port: 27845 }],
  ['/play/lantern-hollow', { id: 'lantern-hollow', port: 27846 }],
]);
const mimeTypes = new Map([
  ['.html', 'text/html; charset=utf-8'],
  ['.js', 'text/javascript; charset=utf-8'],
  ['.wasm', 'application/wasm'],
  ['.pck', 'application/octet-stream'],
  ['.png', 'image/png'],
  ['.ico', 'image/x-icon'],
  ['.webmanifest', 'application/manifest+json'],
]);

function sendText(response, status, message) {
  response.writeHead(status, {
    'Content-Type': 'text/plain; charset=utf-8',
    'Cache-Control': 'no-store',
  });
  response.end(`${message}\n`);
}

async function serveGame(request, response) {
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    response.setHeader('Allow', 'GET, HEAD');
    return sendText(response, 405, 'Method not allowed.');
  }
  const pathname = request.url.split('?', 1)[0];
  if (rooms.has(pathname)) {
    return sendText(response, 426, 'Open this endpoint through the game.');
  }
  const filename = pathname === '/' ? 'index.html' : pathname.slice(1);
  const contentType = mimeTypes.get(path.extname(filename));
  if (!/^index(?:\.[A-Za-z0-9_-]+)+$/.test(filename) || !contentType) {
    return sendText(response, 404, 'Not found.');
  }
  const filePath = path.join(webDir, filename);
  const info = await stat(filePath).catch(() => null);
  if (!info?.isFile()) {
    return sendText(response, 404, 'Not found.');
  }
  response.writeHead(200, {
    'Content-Type': contentType,
    'Content-Length': info.size,
    'Cache-Control': 'no-cache',
    'X-Content-Type-Options': 'nosniff',
    'Referrer-Policy': 'same-origin',
    'Content-Security-Policy': "frame-ancestors 'none'",
  });
  if (request.method === 'HEAD') {
    response.end();
    return;
  }
  await pipeline(createReadStream(filePath), response);
}

function allowedOrigin(request) {
  if (request.headers['sec-fetch-site'] === 'cross-site') return false;
  if (!request.headers.origin) return true;
  try {
    const origin = new URL(request.headers.origin);
    return (origin.protocol === 'http:' || origin.protocol === 'https:') &&
      origin.host.toLowerCase() === request.headers.host?.toLowerCase();
  } catch {
    return false;
  }
}

function rejectUpgrade(socket, status) {
  socket.end(`HTTP/1.1 ${status}\r\nConnection: close\r\nContent-Length: 0\r\n\r\n`);
}

const gameSockets = new Set();

function connectToGame(request, client, clientHead) {
  client.setNoDelay(true);
  client.on('error', () => client.destroy());
  const room = rooms.get(request.url);
  if (request.method !== 'GET' || !room ||
      request.headers.upgrade?.toLowerCase() !== 'websocket') {
    return rejectUpgrade(client, '404 Not Found');
  }
  if (!allowedOrigin(request)) {
    return rejectUpgrade(client, '403 Forbidden');
  }
  if (request.headers['sec-websocket-version'] !== '13' ||
      !/^[A-Za-z0-9+/]{22}==$/.test(request.headers['sec-websocket-key'] ?? '')) {
    return rejectUpgrade(client, '400 Bad Request');
  }
  if (gameSockets.size >= 24) {
    return rejectUpgrade(client, '503 Service Unavailable');
  }
  gameSockets.add(client);
  client.on('close', () => gameSockets.delete(client));

  const headers = {
    Connection: 'Upgrade',
    Upgrade: 'websocket',
    'Sec-WebSocket-Version': '13',
    'Sec-WebSocket-Key': request.headers['sec-websocket-key'],
  };
  if (request.headers['sec-websocket-protocol']) {
    headers['Sec-WebSocket-Protocol'] = request.headers['sec-websocket-protocol'];
  }
  const upstreamRequest = httpRequest({
    hostname: host,
    port: room.port,
    path: '/play',
    method: 'GET',
    headers,
    timeout: 5000,
  });
  upstreamRequest.once('timeout', () => upstreamRequest.destroy());
  upstreamRequest.once('error', () => rejectUpgrade(client, '502 Bad Gateway'));
  upstreamRequest.once('response', response => {
    response.resume();
    rejectUpgrade(client, '502 Bad Gateway');
  });
  upstreamRequest.once('upgrade', (response, upstream, upstreamHead) => {
    if (client.destroyed) {
      upstream.destroy();
      return;
    }
    const responseHeaders = ['HTTP/1.1 101 Switching Protocols'];
    for (let i = 0; i < response.rawHeaders.length; i += 2) {
      responseHeaders.push(`${response.rawHeaders[i]}: ${response.rawHeaders[i + 1]}`);
    }
    client.write(`${responseHeaders.join('\r\n')}\r\n\r\n`);
    if (upstreamHead.length) client.write(upstreamHead);
    if (clientHead.length) upstream.write(clientHead);
    upstream.setNoDelay(true);
    upstream.setTimeout(0);
    upstream.on('error', () => client.destroy());
    upstream.on('close', () => client.destroy());
    client.once('close', () => upstream.destroy());
    upstream.pipe(client);
    client.pipe(upstream);
  });
  upstreamRequest.end();
}

const godotPath = process.argv[2];
if (!godotPath) {
  console.error('Pass the path to the Godot console executable, or use Start Online Host.cmd.');
  process.exit(1);
}
try {
  await Promise.all(['index.html', 'index.js', 'index.wasm', 'index.pck'].map(file =>
    access(path.join(webDir, file))));
} catch {
  console.error('Export the Web preset to build/web/index.html from the Godot editor first.');
  process.exit(1);
}

const gateway = createServer({ maxHeaderSize: 8192, headersTimeout: 10000, requestTimeout: 10000 },
  (request, response) => {
    serveGame(request, response).catch(() => {
      if (!response.headersSent) sendText(response, 500, 'The game file could not be read.');
      else response.destroy();
    });
  });
gateway.maxConnections = 64;
gateway.on('upgrade', connectToGame);

const games = [];
let stopping = false;
function shutdown(exitCode) {
  if (stopping) return;
  stopping = true;
  process.exitCode = exitCode;
  for (const socket of gameSockets) socket.destroy();
  gateway.close();
  gateway.closeAllConnections();
  for (const game of games) {
    if (game.exitCode === null) game.kill();
  }
}

gateway.on('error', error => {
  console.error(`Could not start the game page: ${error.message}`);
  shutdown(1);
});
gateway.listen(webPort, host, () => {
  for (const room of rooms.values()) {
    const game = spawn(godotPath, ['--headless', '--path', projectRoot, '--', '--serve', `--room=${room.id}`], {
      windowsHide: true,
      stdio: 'inherit',
    });
    games.push(game);
    game.on('error', error => {
      console.error(`Could not start ${room.id}: ${error.message}`);
      shutdown(1);
    });
    game.on('exit', code => shutdown(code ?? 1));
  }
  console.log(`Open http://${host}:${webPort} on this computer. Press Ctrl+C to stop hosting.`);
});
process.on('SIGINT', () => shutdown(0));
process.on('SIGTERM', () => shutdown(0));
