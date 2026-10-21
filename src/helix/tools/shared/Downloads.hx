package helix.tools.shared;

import haxe.io.Bytes;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

/** The tools' pinned downloads, kept in the user's cache for HeliX's tools (%LOCALAPPDATA%, ~/Library/Caches or $XDG_CACHE_HOME, under
	helix/tools): each fetched once, checked against its SHA-256 as it arrives and never kept when it differs, and put in place only whole;
	and the archives they come in unpacked (zip, and gzipped tar). Messages go to the standard error, so a command's output stays its own. */
class Downloads {
	/** The user's cache for HeliX's tools. */
	public static function cache():String {
		var base = switch Sys.systemName() {
			case "Windows": var local = Sys.getEnv("LOCALAPPDATA"); local != null && local != "" ? local : Path.join([home(), "AppData", "Local"]);
			case "Mac":
				Path.join([home(), "Library", "Caches"]);
			default: var xdg = Sys.getEnv("XDG_CACHE_HOME"); xdg != null && xdg != "" ? xdg : Path.join([home(), ".cache"]);
		}
		return Path.normalize(Path.join([base, "helix", "tools"]));
	}

	/** The user's home directory. */
	public static function home():String {
		var home = Sys.getEnv(Sys.systemName() == "Windows" ? "USERPROFILE" : "HOME");
		if (home == null || home == "")
			throw new CommandError("helix: no home directory (HOME, or USERPROFILE on Windows) to keep the tools' cache in");
		return home;
	}

	/** The program the environment variable names in place of the cache's (one of the user's own, for a machine without a network), or null
		when it names none; refuses one that isn't a file. Its version is the user's to choose: it isn't checked. */
	public static function given(variable:String):Null<String> {
		var path = Sys.getEnv(variable);
		if (path == null || path == "")
			return null;
		if (!Files.isFile(path))
			throw new CommandError('helix: $variable names $path, which isn\'t a file');
		return Path.normalize(FileSystem.absolutePath(path));
	}

	/** A message on the standard error. */
	public static function say(message:String):Void
		Sys.stderr().writeString(message + "\n");

	/** The bytes at the first of urls that gives the file whose SHA-256 is sha256 (lowercase hex); refuses when none does, naming each
		failure. */
	public static function fetch(urls:Array<String>, sha256:String, tool:String):Bytes {
		var failures = [];
		for (url in urls) {
			say('$tool: downloading $url');
			var data = get(url, failures);
			if (data == null)
				continue;
			var digest = Sha256.hex(data);
			// Never used, wherever it came from, unless it's the pinned one.
			if (digest != sha256) {
				failures.push('$url: SHA-256 $digest, not the pinned $sha256');
				continue;
			}
			return data;
		}
		throw new CommandError('$tool: no source gave the pinned file:\n  ' + failures.join("\n  "));
	}

	// The body at url (https), following up to 8 redirects; null, its failure added to failures, when it can't be had. HTTP/1.1 read by
	// hand: haxe.Http follows no redirect (GitHub's release downloads are one) and reads a chunked body (GitHub's archives) through a string,
	// which binary data breaks in Haxe's interpreter.
	static function get(url:String, failures:Array<String>):Null<Bytes> {
		var at = url;
		for (_ in 0...8) {
			var parts = ~/^https:\/\/([^\/:]+)(?::([0-9]+))?(\/.*)?$/;
			if (!parts.match(at)) {
				failures.push('$url: not an https address: $at');
				return null;
			}
			var host = parts.matched(1);
			var port = parts.matched(2) == null ? 443 : Std.parseInt(parts.matched(2));
			var path = parts.matched(3) == null ? "/" : parts.matched(3);
			var socket = new sys.ssl.Socket();
			var status = 0, headers = new Map<String, String>(), body:Bytes;
			try {
				socket.setHostname(host);
				socket.connect(new sys.net.Host(host), port);
				socket.output.writeString('GET $path HTTP/1.1\r\nHost: $host\r\nUser-Agent: helix\r\nAccept-Encoding: identity\r\nConnection: close\r\n\r\n');
				socket.output.flush();
				var input = socket.input;
				var statusLine = ~/^HTTP\/1\.[01] ([0-9]{3})/;
				if (!statusLine.match(input.readLine()))
					throw "not an HTTP response";
				status = Std.parseInt(statusLine.matched(1));
				while (true) {
					var line = StringTools.trim(input.readLine());
					if (line == "")
						break;
					var colon = line.indexOf(":");
					if (colon > 0)
						headers.set(line.substr(0, colon).toLowerCase(), StringTools.trim(line.substr(colon + 1)));
				}
				if (headers.get("transfer-encoding") == "chunked") {
					var buffer = new haxe.io.BytesBuffer();
					while (true) {
						var size = Std.parseInt("0x" + StringTools.trim(input.readLine().split(";")[0]));
						if (size == null)
							throw "a chunk without its size";
						if (size == 0)
							break;
						buffer.add(input.read(size));
						input.readLine();
					}
					body = buffer.getBytes();
				} else if (headers.exists("content-length"))
					body = input.read(Std.parseInt(headers.get("content-length")));
				else
					body = input.readAll();
				socket.close();
			} catch (error:Dynamic) {
				try
					socket.close()
				catch (_:Dynamic) {}
				failures.push('$url: $error');
				return null;
			}
			if (status >= 300 && status < 400) {
				var location = headers.get("location");
				if (location == null) {
					failures.push('$url: a redirect ($status) without a location');
					return null;
				}
				at = StringTools.startsWith(location, "/") ? 'https://$host${port == 443 ? "" : ":" + port}$location' : location;
				continue;
			}
			if (status != 200) {
				failures.push('$url: HTTP $status');
				return null;
			}
			return body;
		}
		failures.push('$url: too many redirects');
		return null;
	}

	/** data written to path whole: into a .part file first, renamed into place (made executable with executable, outside Windows). */
	public static function place(path:String, data:Bytes, executable = false):Void {
		Files.makeDirectory(Path.directory(path));
		var partial = path + ".part";
		File.saveBytes(partial, data);
		if (executable && Sys.systemName() != "Windows")
			Sys.command("chmod", ["755", partial]);
		if (FileSystem.exists(path))
			FileSystem.deleteFile(path);
		FileSystem.rename(partial, path);
	}

	/** The zip archive's files written under directory, at their paths in it; only those keep returns true for, when given. */
	public static function unzip(archive:Bytes, directory:String, ?keep:String->Bool):Void {
		for (entry in haxe.zip.Reader.readZip(new haxe.io.BytesInput(archive))) {
			if (StringTools.endsWith(entry.fileName, "/") || (keep != null && !keep(entry.fileName)))
				continue;
			safe(entry.fileName);
			var target = Path.join([directory, entry.fileName]);
			Files.makeDirectory(Path.directory(target));
			File.saveBytes(target, haxe.zip.Reader.unzip(entry));
		}
	}

	/** A gzipped tar archive's regular files, as (name, bytes), those keep returns true for (its pax headers skipped). */
	public static function untarGz(archive:Bytes, keep:String->Bool):Array<{name:String, data:Bytes}> {
		var tar = gunzip(archive);
		var out = [];
		var at = 0;
		var longName:Null<String> = null;
		while (at + 512 <= tar.length) {
			if (tar.get(at) == 0)
				break;
			var name = field(tar, at, 100);
			var prefix = field(tar, at + 345, 155);
			if (prefix != "")
				name = prefix + "/" + name;
			if (longName != null) {
				name = longName;
				longName = null;
			}
			var size = octal(field(tar, at + 124, 12));
			var type = tar.get(at + 156);
			var data = tar.sub(at + 512, size);
			if (type == "x".code) {
				// A pax header: a long path for the next entry.
				var path = ~/[0-9]+ path=([^\n]*)\n/;
				if (path.match(data.toString()))
					longName = path.matched(1);
			} else if (type == "L".code)
				longName = field(data, 0, data.length);
			else if ((type == "0".code || type == 0) && keep(name)) {
				safe(name);
				out.push({name: name, data: data});
			}
			at += 512 + ((size + 511) >> 9 << 9);
		}
		return out;
	}

	static function gunzip(data:Bytes):Bytes {
		var inflate = new haxe.zip.Uncompress(31);
		var out = new haxe.io.BytesBuffer();
		var chunk = Bytes.alloc(1 << 20);
		var read = 0;
		while (true) {
			var step = inflate.execute(data, read, chunk, 0);
			out.addBytes(chunk, 0, step.write);
			read += step.read;
			if (step.done || (step.read == 0 && step.write == 0))
				break;
		}
		inflate.close();
		return out.getBytes();
	}

	static function octal(text:String):Int {
		var value = 0;
		for (i in 0...text.length) {
			var c = text.charCodeAt(i);
			if (c >= "0".code && c <= "7".code)
				value = value * 8 + (c - "0".code);
		}
		return value;
	}

	// A NUL-ended field of the header.
	static function field(bytes:Bytes, at:Int, length:Int):String {
		var end = at;
		while (end < at + length && bytes.get(end) != 0)
			end++;
		return bytes.getString(at, end - at);
	}

	// Refuses an archive path that would land outside its directory.
	static function safe(name:String):Void {
		if (Path.isAbsolute(name) || name.split("/").indexOf("..") >= 0 || name.indexOf("\\") >= 0)
			throw new CommandError('helix: an archive names $name, outside its directory');
	}
}
