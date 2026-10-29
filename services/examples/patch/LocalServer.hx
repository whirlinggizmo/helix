import haxe.io.Bytes;
import sys.FileSystem;
import sys.io.File;
import sys.net.Host;
import sys.net.Socket;
import sys.thread.Mutex;
import sys.thread.Thread;

/** Serves a directory over HTTP on this machine, on a thread of its own, as a CDN would serve it: the example's stand-in for a real server.

	It answers GET with the file at the path, or 404, and keeps the paths it served. It listens on 127.0.0.1 at a port the OS picks. */
class LocalServer {
	/** Gets the URL it serves at, ending in `/`. */
	public final url:String;

	/** Gets or sets the directory served, so the same URL can serve an updated tree. */
	public var directory(get, set):String;

	/** Gets the paths it served a file for, in order. */
	public var served(get, never):Array<String>;

	var served_:String;
	final socket = new Socket();
	final lock = new Mutex();
	final paths:Array<String> = [];

	/** Starts serving a directory.

		@param directory  The directory served. */
	public function new(directory:String) {
		served_ = directory;
		socket.bind(new Host("127.0.0.1"), 0);
		socket.listen(8);
		url = 'http://127.0.0.1:${socket.host().port}/';
		Thread.create(() -> while (true) {
			var client = try socket.accept() catch (_:Dynamic) return;
			answer(client);
		});
	}

	function get_directory():String {
		lock.acquire();
		var value = served_;
		lock.release();
		return value;
	}

	function set_directory(value:String):String {
		lock.acquire();
		served_ = value;
		lock.release();
		return value;
	}

	function get_served():Array<String> {
		lock.acquire();
		var copy = paths.copy();
		lock.release();
		return copy;
	}

	/** Stops serving. */
	public function close():Void
		socket.close();

	function answer(client:Socket):Void {
		try {
			var request = StringTools.trim(client.input.readLine()).split(" ");
			while (StringTools.trim(client.input.readLine()) != "") {}
			var path = request[1].substr(1);
			var file = '$directory/$path';
			if (request[0] == "GET" && path.indexOf("..") < 0 && FileSystem.exists(file) && !FileSystem.isDirectory(file)) {
				var bytes = File.getBytes(file);
				lock.acquire();
				paths.push(path);
				lock.release();
				client.output.writeString('HTTP/1.1 200 OK\r\nContent-Length: ${bytes.length}\r\nConnection: close\r\n\r\n');
				client.output.write(bytes);
			} else
				client.output.writeString("HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
		} catch (_:Dynamic) {}
		client.close();
	}
}
