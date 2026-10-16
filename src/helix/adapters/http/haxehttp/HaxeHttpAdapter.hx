package helix.adapters.http.haxehttp;

import haxe.io.Bytes;
import helix.adapters.shared.Mailbox;
import helix.assets.IHttp;
import sys.thread.Thread;

/** A response body arriving on a worker thread, each part handed to the host thread; it stops the transfer (by throwing) once aborted. */
private class Parts extends haxe.io.Output {
	var transfer:Transfer;

	/** Writes into transfer. */
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

/** One GET on its worker thread: its callbacks, run on the host thread through the mailbox. */
private class Transfer {
	/** The adapter's mailbox. */
	public var mailbox:Mailbox;

	/** Set on the host thread when aborted; the worker stops at its next write, and nothing more is delivered. */
	public var aborted = false;

	/** The response's head, delivered once. */
	public var head:(Int, Map<String, String>) -> Void;

	/** Each part of the body. */
	public var body:Bytes->Void;

	/** The end. */
	public var end:Null<String>->Void;

	var http:haxe.Http;
	var headed = false;

	/** A transfer of http's response. */
	public function new(mailbox:Mailbox, http:haxe.Http, head:(Int, Map<String, String>) -> Void, body:Bytes->Void, end:Null<String>->Void) {
		this.mailbox = mailbox;
		this.http = http;
		this.head = head;
		this.body = body;
		this.end = end;
	}

	/** Hands the head over before the first part (and before the end of an empty body), once; on the worker thread. */
	public function started():Void {
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

	/** The response's status, as onStatus reported it. */
	public var status = 0;
}

/** IHttp natively over haxe.Http, a worker thread a transfer: http and https URLs only (others end with a failure), noCache has nothing to
	bypass, and an abort stops the transfer at its next part of the body (not while it connects). */
class HaxeHttpAdapter implements IHttp {
	var mailbox = new Mailbox();
	var transfers:Array<Transfer> = [];

	/** No transfers yet. */
	public function new() {}

	public function get(url:String, noCache:Bool, headers:Map<String, String>, head:(Int, Map<String, String>) -> Void, body:Bytes->Void,
			end:Null<String>->Void):Void->Void {
		var http = new haxe.Http(url),
			transfer = new Transfer(mailbox, http, head, body, end);
		for (name => value in headers)
			http.setHeader(name, value);
		transfers.push(transfer);
		function finish(error:Null<String>):Void
			mailbox.post(() -> {
				transfers.remove(transfer);
				if (!transfer.aborted)
					transfer.end(error);
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

	public function shutdown():Void
		for (t in transfers)
			t.aborted = true;
}
