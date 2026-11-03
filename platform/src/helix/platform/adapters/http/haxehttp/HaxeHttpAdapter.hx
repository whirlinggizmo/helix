package helix.platform.adapters.http.haxehttp;

import haxe.io.Bytes;
import helix.platform.IHttp;
import helix.platform.adapters.shared.Mailbox;
import sys.thread.Thread;

/** Represents a response's body arriving on a worker thread, each part handed to the main thread; it stops the transfer, by throwing, once
	aborted. */
private class Parts extends haxe.io.Output {
	var transfer:Transfer;

	/** Creates the output, writing into `transfer`. */
	public function new(transfer:Transfer)
		this.transfer = transfer;

	public override function writeByte(value:Int):Void {
		var b = Bytes.alloc(1);
		b.set(0, value);
		writeBytes(b, 0, 1);
	}

	public override function writeBytes(bytes:Bytes, pos:Int, len:Int):Int {
		if (transfer.aborted)
			throw "Aborted";
		var part = bytes.sub(pos, len);
		transfer.mailbox.post(() -> if (!transfer.aborted) transfer.body(part));
		return len;
	}
}

/** Represents one request over `sys.Http`, reading the response itself.

	`sys.Http` retries a read that finds the connection closed while it reads the head, so a server that closes before a whole head would
	spin its thread forever; here that throws, and the transfer fails. An HTTP error status isn't thrown: it's a response. */
private class Request extends sys.Http {
	// The most bytes a response's head may have.
	static inline final HEAD_LIMIT = 65536;

	override function readHttpResponse(api:haxe.io.Output, sock:sys.net.Socket):Void {
		sock.setTimeout(cnxTimeout);
		var head = new haxe.io.BytesBuffer(), last = 0;
		// The head ends at a blank line: its last four bytes CR LF CR LF, or a bare LF LF.
		while (last != 0x0d0a0d0a && (last & 0xffff) != 0x0a0a) {
			var byte = try sock.input.readByte() catch (e:haxe.io.Eof) throw "The connection closed before the response's head was complete";
			head.addByte(byte);
			last = (last << 8) | byte;
			if (head.length > HEAD_LIMIT)
				throw "The response's head is longer than " + HEAD_LIMIT + " bytes";
		}
		var lines = [for (line in head.getBytes().toString().split("\n")) StringTools.rtrim(line)];
		var words = lines.shift().split(" "), status = Std.parseInt(words[1]);
		if (!StringTools.startsWith(words[0], "HTTP/") || status == null || status < 100 || status > 999)
			throw "The response doesn't start with an HTTP status line";
		responseHeaders = new haxe.ds.StringMap();
		var size:Null<Int> = null, chunked = false;
		for (line in lines) {
			var colon = line.indexOf(":");
			if (colon <= 0)
				continue;
			var name = line.substr(0, colon).toLowerCase(),
				value = StringTools.trim(line.substr(colon + 1));
			// A header given more than once is one header, its values in order.
			responseHeaders.set(name, responseHeaders.exists(name) ? responseHeaders.get(name) + ", " + value : value);
			switch name {
				case "content-length":
					size = Std.parseInt(value);
				case "transfer-encoding":
					chunked = value.toLowerCase() == "chunked";
			}
		}
		onStatus(status);

		var buffer = Bytes.alloc(1024);
		if (chunked) {
			chunk_size = null;
			chunk_buf = null;
			var pattern = ~/^([0-9A-Fa-f]+)[ ]*\r\n/m;
			try {
				while (readChunk(pattern, api, buffer, sock.input.readBytes(buffer, 0, buffer.length))) {}
			} catch (e:haxe.io.Eof) {
				throw "The connection closed before the last chunk";
			}
			if (chunk_size != null || chunk_buf != null)
				throw "Invalid chunk";
		} else if (size == null) {
			// Without a length, the body ends when the connection closes.
			try {
				while (true)
					api.writeBytes(buffer, 0, sock.input.readBytes(buffer, 0, buffer.length));
			} catch (e:haxe.io.Eof) {}
		} else {
			try {
				while (size > 0) {
					var len = sock.input.readBytes(buffer, 0, size < buffer.length ? size : buffer.length);
					api.writeBytes(buffer, 0, len);
					size -= len;
				}
			} catch (e:haxe.io.Eof) {
				throw "The connection closed before the body's Content-Length";
			}
		}
		api.close();
	}
}

/** Represents one GET on its worker thread, with its callbacks, run on the main thread through the mailbox. */
@:allow(helix.platform.adapters.http.haxehttp)
private class Transfer {
	/** The adapter's mailbox. */
	var mailbox:Mailbox;

	/** Whether the transfer was aborted, set on the main thread; the worker stops at its next write, and nothing more is delivered. */
	var aborted = false;

	/** The response's head, delivered once. */
	var head:(Int, Map<String, String>) -> Void;

	/** Each part of the body. */
	var body:Bytes->Void;

	/** Called when the body is all here. */
	var done:Void->Void;

	/** Receives why the transfer failed. */
	var failed:String->Void;

	/** Creates a transfer with its callbacks. */
	public function new(mailbox:Mailbox, head:(Int, Map<String, String>) -> Void, body:Bytes->Void, done:Void->Void, failed:String->Void) {
		this.mailbox = mailbox;
		this.head = head;
		this.body = body;
		this.done = done;
		this.failed = failed;
	}
}

/** Provides `IHttp` natively over `sys.Http`, on a worker thread for each transfer.

	It fetches http and https URLs only, failing others; `noCache` has no cache to bypass; an abort stops a transfer at its next part of the
	body, not while it connects. A server that sends nothing for 10 seconds fails the transfer, as does one that doesn't take the connection
	within about 20 (10 for the connection, 10 more for the request). */
class HaxeHttpAdapter implements IHttp {
	var mailbox = new Mailbox();
	var transfers:Array<Transfer> = [];

	/** Creates the adapter. */
	public function new() {}

	public function get(url:String, noCache:Bool, headers:Map<String, String>, head:(status:Int, headers:Map<String, String>) -> Void, body:Bytes->Void,
			done:Void->Void, failed:String->Void):Void->Void {
		var http = new Request(url),
			transfer = new Transfer(mailbox, head, body, done, failed);
		for (name => value in headers)
			http.setHeader(name, value);
		transfers.push(transfer);
		function finish(error:Null<String>):Void
			mailbox.post(() -> {
				transfers.remove(transfer);
				if (transfer.aborted)
					return;
				if (error == null)
					transfer.done();
				else
					transfer.failed(error);
			});
		if (!(StringTools.startsWith(url, "http://") || StringTools.startsWith(url, "https://")))
			finish("Only http and https URLs are fetched natively");
		else
			Thread.create(() -> {
				var error:Null<String> = null, headed = false;
				// Request reads the whole head, its headers in responseHeaders, before it reports the status.
				http.onStatus = status -> {
					headed = true;
					var names:Map<String, String> = [for (name => value in http.responseHeaders) name => value];
					mailbox.post(() -> if (!transfer.aborted) transfer.head(status, names));
				};
				// A socket's timeout, sys.Http's 10 seconds, is reported as Blocked; a connection refused or broken, as EOF.
				http.onError = value -> error = switch value {
					case "Blocked": "The server didn't answer in time";
					case "EOF": "The connection was refused or lost";
					case _: value;
				};
				try {
					http.customRequest(false, new Parts(transfer));
					finish(error != null ? error : headed ? null : "No HTTP response");
				} catch (e:Dynamic) {
					finish(Std.string(e));
				}
			});
		return () -> transfer.aborted = true;
	}

	public function poll():Void
		mailbox.deliver();

	public function dispose():Void
		for (t in transfers)
			t.aborted = true;
}
