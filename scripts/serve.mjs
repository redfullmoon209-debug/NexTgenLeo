import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { resolve, extname, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

export const root = resolve(fileURLToPath(new URL('../', import.meta.url)));
export function createStaticServer({ prefix = '' } = {}) {
  return http.createServer(async (req, res) => {
    try {
      let pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
      if (prefix && !pathname.startsWith(prefix + '/')) { res.writeHead(404).end(); return; }
      pathname = pathname.slice(prefix.length);
      const path = resolve(root, '.' + (pathname === '/' ? '/index.html' : pathname));
      if (!path.startsWith(root + sep) || pathname.split('/').some(p => p.startsWith('.'))) { res.writeHead(403).end(); return; }
      const data = await readFile(path);
      const mime = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.glb': 'model/gltf-binary', '.svg': 'image/svg+xml', '.ttf': 'font/ttf', '.png': 'image/png', '.md': 'text/plain' }[extname(path)] || 'application/octet-stream';
      res.writeHead(200, { 'Content-Type': mime, 'Cache-Control': 'no-cache' }).end(data);
    } catch { res.writeHead(404).end('File not found'); }
  });
}
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const port = Number(process.env.PORT || 8080);
  createStaticServer().listen(port, '0.0.0.0', () => console.log(`NexTgenLeo: http://localhost:${port}`));
}
