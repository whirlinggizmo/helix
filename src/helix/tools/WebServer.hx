package helix.tools;

#if macro
import haxe.io.Bytes;
import haxe.io.Path;
import helix.tools.shared.CommandError;
import helix.tools.shared.Files;
import sys.io.File;
import sys.net.Host;
import sys.net.Socket;
#end

/** A web server for a directory of files, as a macro an hxml of its own calls (`--macro helix.tools.WebServer.serveDirectory(...)`), run by
	the compiler from the game's directory until Ctrl+C: a built game served on this machine as a host serves it, to try before uploading.

	- `serveDirectory(directory, port = 8095)`: directory served at http://localhost:port/ over HTTP, GET and HEAD, each file with its type
	  (what a browser needs to take an SVG icon, a module, a WebAssembly file), a directory's index.html, nothing outside the directory. No
	  building, no watching, no script added: the page is what ships. */
class WebServer {
	#if macro
	static final TYPES = [
		"html" => "text/html; charset=utf-8",
		"js" => "text/javascript",
		"mjs" => "text/javascript",
		"json" => "application/json",
		"map" => "application/json",
		"css" => "text/css",
		"svg" => "image/svg+xml",
		"png" => "image/png",
		"jpg" => "image/jpeg",
		"jpeg" => "image/jpeg",
		"webp" => "image/webp",
		"gif" => "image/gif",
		"wasm" => "application/wasm",
		"txt" => "text/plain; charset=utf-8",
		"md" => "text/plain; charset=utf-8",
		"ogg" => "audio/ogg",
		"mp3" => "audio/mpeg",
		"wav" => "audio/wav",
		"ttf" => "font/ttf",
		"woff2" => "font/woff2",
		"glb" => "model/gltf-binary",
		"gltf" => "model/gltf+json",
		"zip" => "application/zip"
	];

	/** The directory (relative to the game's) served at http://localhost:port/, until Ctrl+C. Refuses a directory that isn't there. */
	public static function serveDirectory(directory:String, port = 8095):Void {
		var root = Files.resolve(Sys.getCwd(), directory);
		try {
			if (!Files.isDirectory(root))
				throw new CommandError('serveDirectory: $directory is not a directory (build it first)');
			var server = new Socket();
			try {
				server.bind(new Host("127.0.0.1"), port);
			} catch (_) {
				throw new CommandError('serveDirectory: can\'t serve on port $port: is something else using it?');
			}
			server.listen(16);
			Sys.println('serveDirectory: http://localhost:$port/ ($root); Ctrl+C stops');
			// One connection at a time: a macro can't start threads, and a page on this machine needs no more. A client that stalls is
			// dropped after a few seconds.
			while (true) {
				var client = server.accept();
				client.setTimeout(5);
				answer(client, root);
			}
		} catch (error:CommandError) {
			Sys.stderr().writeString(error.message + "\n");
			Sys.exit(1);
		}
	}

	// One request read and answered, the connection then closed.
	static function answer(client:Socket, root:String):Void {
		try {
			var request = client.input.readLine();
			while (client.input.readLine() != "") {}
			var parts = request.split(" ");
			var method = parts[0];
			var path = StringTools.urlDecode(parts.length > 1 ? parts[1].split("?")[0] : "/");
			var file = Path.normalize(Path.join([root, path]));
			if (method != "GET" && method != "HEAD")
				respond(client, 405, "text/plain", Bytes.ofString("GET or HEAD"), true);
			else {
				if (Files.isDirectory(file))
					file = Path.join([file, "index.html"]);
				if (!StringTools.startsWith(file, root) || !Files.isFile(file))
					respond(client, 404, "text/plain", Bytes.ofString('$path: not found'), method == "GET");
				else {
					var type = TYPES.get(Path.extension(file).toLowerCase());
					respond(client, 200, type == null ? "application/octet-stream" : type, File.getBytes(file), method == "GET");
				}
			}
		} catch (_) {}
		client.close();
	}

	static function respond(client:Socket, status:Int, type:String, body:Bytes, withBody:Bool):Void {
		var reason = switch status {
			case 200: "OK";
			case 404: "Not Found";
			default: "Method Not Allowed";
		}
		client.output.writeString('HTTP/1.1 $status $reason\r\nContent-Type: $type\r\nContent-Length: ${body.length}\r\nCache-Control: no-cache\r\nConnection: close\r\n\r\n');
		if (withBody)
			client.output.write(body);
		client.output.flush();
	}
	#end
}
