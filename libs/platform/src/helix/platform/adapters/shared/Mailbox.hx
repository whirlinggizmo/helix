package helix.platform.adapters.shared;

import sys.thread.Deque;

/** Provides how a native adapter's threads hand work back to the main thread: posted from any thread, delivered on the main thread by the
	adapter's poll. */
@:noCompletion
class Mailbox {
	var deque = new Deque<Void->Void>();

	/** Creates an empty mailbox. */
	public function new() {}

	/** Leaves work for the main thread; call from any thread.

		@param work  The work. */
	public function post(work:Void->Void):Void
		deque.add(work);

	/** Runs everything posted so far, in order; call on the main thread. */
	public function deliver():Void {
		var work:Null<Void->Void>;
		while ((work = deque.pop(false)) != null)
			work();
	}
}
