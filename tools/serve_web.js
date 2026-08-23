// Minimal static file server for the exported Web build, for phone testing on
// the LAN. `export_presets.cfg` disables thread_support, so this does not need
// the COOP/COEP headers a threaded Godot Web export would require.
const http = require('http');
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..', 'build', 'web');
const port = process.argv[2] ? parseInt(process.argv[2], 10) : 8060;

const types = {
	'.html': 'text/html',
	'.js': 'application/javascript',
	'.wasm': 'application/wasm',
	'.pck': 'application/octet-stream',
	'.png': 'image/png',
	'.import': 'application/octet-stream',
};

http.createServer((req, res) => {
	let reqPath = decodeURIComponent(req.url.split('?')[0]);
	if (reqPath === '/') reqPath = '/index.html';
	const filePath = path.join(root, reqPath);

	if (!filePath.startsWith(root)) {
		res.writeHead(403);
		res.end('Forbidden');
		return;
	}

	fs.readFile(filePath, (err, data) => {
		if (err) {
			res.writeHead(404);
			res.end('Not found');
			return;
		}
		const ext = path.extname(filePath);
		res.writeHead(200, { 'Content-Type': types[ext] || 'application/octet-stream' });
		res.end(data);
	});
}).listen(port, '0.0.0.0', () => {
	console.log(`Serving ${root} on http://0.0.0.0:${port}`);
});
