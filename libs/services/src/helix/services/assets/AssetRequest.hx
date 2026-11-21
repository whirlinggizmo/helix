package helix.services.assets;

import helix.log.Log;

/** Represents a call of the assets in flight, as the sources answer it.

	It keeps the abort of the step in flight, the last failure, and why the file is missing when that is more than not being found. What it answers with
	nothing of the platform's to wait on, it answers at the assets' next `poll`. */
@:noCompletion
class AssetRequest {
	/** Gets the path asked for. */
	public final path:String;

	/** Gets a value indicating whether it was aborted. Once aborted, nothing more is called. */
	public var aborted(default, null) = false;

	/** Gets or sets the abort of the step in flight. */
	public var cancel:Null<Void->Void> = null;

	/** Gets or sets the last failure, reported when no source has the file. */
	public var failure:Null<String> = null;

	/** Gets or sets why the file is missing, naming the path, when it is more than not being found in any asset source. */
	public var reason:Null<String> = null;

	final missing:Null<Void->Void>;
	final failed:Null<String->Void>;
	final requests:Array<AssetRequest>;
	final queue:Array<Void->Void>;

	/** Creates a request, which stays in requests while it is in flight and answers later through queue. Without missing, a missing
		file fails. */
	public function new(path:String, missing:Null<Void->Void>, failed:Null<String->Void>, requests:Array<AssetRequest>, queue:Array<Void->Void>) {
		this.path = path;
		this.missing = missing;
		this.failed = failed;
		this.requests = requests;
		this.queue = queue;
	}

	/** Returns a request of its own for another path, answering through the same assets' polls and belonging to no load, so aborting this
		one leaves it running. */
	public function detached(path:String):AssetRequest
		return new AssetRequest(path, null, null, [], queue);

	/** Calls f at the assets' next poll, unless the request is aborted first. */
	public function later(f:Void->Void):Void
		queue.push(() -> if (!aborted) f());

	/** Ends the request and calls f with the answer. Does nothing once aborted. */
	public function answer(f:Void->Void):Void {
		if (aborted)
			return;
		end();
		f();
	}

	/** Moves on to the next source by calling f, keeping the optional message as the last failure. Does nothing once aborted. */
	public function next(f:Void->Void, ?message:String):Void {
		if (aborted)
			return;
		if (message != null)
			failure = message;
		cancel = null;
		f();
	}

	/** Ends the request with its last failure, or as missing when there was none: missing called and the reason logged, or without
		missing, the reason as the failure. Does nothing once aborted. */
	public function fail():Void {
		if (aborted)
			return;
		end();
		var why = reason != null ? reason : '$path: file not found in any of the asset sources';
		if (failure == null && missing != null) {
			Log.info(why, "assets");
			missing();
			return;
		}
		var message = failure != null ? '$path: $failure' : why;
		if (failed != null)
			failed(message);
		else
			Log.warn(message, "assets");
	}

	/** Aborts the request and the step in flight. Nothing more is called. */
	public function abort():Void {
		if (aborted)
			return;
		end();
		aborted = true;
		if (cancel != null)
			cancel();
	}

	function end():Void {
		requests.remove(this);
	}
}
