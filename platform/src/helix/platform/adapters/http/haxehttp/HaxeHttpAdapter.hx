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
		transfer.started();
		var part = bytes.sub(pos, len);
		transfer.mailbox.post(() -> if (!transfer.aborted) transfer.body(part));
		return len;
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

	var http:haxe.Http;
	var headed = false;

	/** Creates a transfer of `http`'s response. */
	public function new(mailbox:Mailbox, http:haxe.Http, head:(Int, Map<String, String>) -> Void, body:Bytes->Void, done:Void->Void, failed:String->Void) {
		this.mailbox = mailbox;
		this.http = http;
		this.head = head;
		this.body = body;
		this.done = done;
		this.failed = failed;
	}

	/** Hands the head over once, before the first part or the end of an empty body; on the worker thread. */
	function started():Void {
		if (headed)
			return;
		headed = true;
		var headers:Map<String, String> = [];
		if (http.responseHeaders != null)
			for (name => value in http.responseHeaders)
				headers[name.toLowerCase()] = value;
		var code = this.status;
		mailbox.post(() -> if (!aborted) head(code, headers));
	}

	/** The response's status, as `onStatus` reported it. */
	var status = 0;
}

/** Provides `IHttp` natively over `sys.Http`, on a worker thread for each transfer.

	It fetches http and https URLs only, failing others; `noCache` has no cache to bypass; an abort stops a transfer at its next part of the
	body, not while it connects. */
class HaxeHttpAdapter implements IHttp {
	var mailbox = new Mailbox();
	var transfers:Array<Transfer> = [];

	/** Creates the adapter. */
	public function new() {}

	public function get(url:String, noCache:Bool, headers:Map<String, String>, head:(status:Int, headers:Map<String, String>) -> Void, body:Bytes->Void,
			done:Void->Void, failed:String->Void):Void->Void {
		var http = new haxe.Http(url),
			transfer = new Transfer(mailbox, http, head, body, done, failed);
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
				var error:Null<String> = null;
				http.onStatus = value -> transfer.status = value;
				http.onError = value -> error = value;
				try {
					http.customRequest(false, new Parts(transfer));
					transfer.started();
					// haxe.Http reports an HTTP error status as an error too: that's a response here.
					finish(transfer.status != 0
						&& (error == null
							|| error == "Http Error #" + transfer.status) ? null : error == null ? "No HTTP response" : error);
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
