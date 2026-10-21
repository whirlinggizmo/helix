package helix.tools;

#if macro
import haxe.io.Bytes;
import haxe.io.Path;
import helix.tools.shared.CommandError;
import helix.tools.shared.Files;
import eval.luv.Buffer;
import eval.luv.Handle;
import eval.luv.Loop;
import eval.luv.SockAddr;
import eval.luv.Stream;
import eval.luv.Tcp;
import sys.io.File;
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

	/** The directory (relative to the game's) served at http://localhost:port/, until Ctrl+C. Refuses a directory that isn't there, and a
		port another program is using. */
	public static function serveDirectory(directory:String, port = 8095):Void {
		var root = Files.resolve(Sys.getCwd(), directory);
		try {
			if (!Files.isDirectory(root))
				throw new CommandError('serveDirectory: $directory is not a directory (build it first)');
			// libuv's sockets (eval.luv): its bind reuses the address, so serving again needn't wait out the last run's closed connections,
			// and it says when it fails. One loop answers each request in turn: a macro can't start threads, and a page on this machine
			// needs no more.
			var loop = Loop.init().resolve();
			var server = Tcp.init(loop).resolve();
			var failure:Null<String> = null;
			switch server.bind(SockAddr.ipv4("127.0.0.1", port).resolve()) {
				case Error(e):
					failure = e.toString();
				case Ok(_):
			}
			// libuv tells of an address in use at the listen.
			if (failure == null)
				Stream.listen(server, result -> switch result {
					case Error(e): failure = e.toString();
					case Ok(_): accept(loop, server, root);
				}, 16);
			if (failure != null)
				throw new CommandError('serveDirectory: can\'t serve on port $port ($failure): is something else using it?');
			Sys.println('serveDirectory: http://localhost:$port/ ($root); Ctrl+C stops');
			loop.run(DEFAULT);
		} catch (error:CommandError) {
			Sys.stderr().writeString(error.message + "\n");
			Sys.exit(1);
		}
	}

	// A connection accepted, its request read (the line and headers, to the blank line: a GET has no body) and answered.
	static function accept(loop:Loop, server:Tcp, root:String):Void {
		var client = Tcp.init(loop).resolve();
		if (!Stream.accept(server, client).isOk()) {
			Handle.close(client, () -> {});
			return;
		}
		var head = new StringBuf();
		Stream.readStart(client, result -> switch result {
			case Ok(data):
				head.add(data.toString());
				var text = head.toString();
				if (text.indexOf("\r\n\r\n") >= 0) {
					Stream.readStop(client);
					try
						answer(client, root, text.split("\r\n")[0])
					catch (_)
						Handle.close(client, () -> {});
				}
			case Error(_):
				Handle.close(client, () -> {});
		});
	}

	// The request line answered: the file, a directory's index.html, or a refusal.
	static function answer(client:Tcp, root:String, request:String):Void {
		var parts = request.split(" ");
		var method = parts[0];
		var path = StringTools.urlDecode(parts.length > 1 ? parts[1].split("?")[0] : "/");
		var file = Path.normalize(Path.join([root, path]));
		if (method != "GET" && method != "HEAD") {
			respond(client, 405, "text/plain", Bytes.ofString("GET or HEAD"), true);
			return;
		}
		if (Files.isDirectory(file))
			file = Path.join([file, "index.html"]);
		if (!StringTools.startsWith(file, root) || !Files.isFile(file)) {
			respond(client, 404, "text/plain", Bytes.ofString('$path: not found'), method == "GET");
			return;
		}
		var type = TYPES.get(Path.extension(file).toLowerCase());
		respond(client, 200, type == null ? "application/octet-stream" : type, File.getBytes(file), method == "GET");
	}

	// A response written, and the connection then closed.
	static function respond(client:Tcp, status:Int, type:String, body:Bytes, withBody:Bool):Void {
		var reason = switch status {
			case 200: "OK";
			case 404: "Not Found";
			default: "Method Not Allowed";
		}
		var head = 'HTTP/1.1 $status $reason\r\nContent-Type: $type\r\nContent-Length: ${body.length}\r\nCache-Control: no-cache\r\nConnection: close\r\n\r\n';
		var buffers = [Buffer.fromString(head)];
		if (withBody && body.length > 0)
			buffers.push(Buffer.fromBytes(body));
		Stream.write(client, buffers, (_, _) -> Handle.close(client, () -> {}));
	}
	#end
}
