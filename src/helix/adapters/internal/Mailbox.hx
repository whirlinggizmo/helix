package helix.adapters.internal;

import sys.thread.Deque;

/** How a native adapter's threads hand work back to the host thread: post from any thread, deliver on the host thread (the adapter's poll). */
class Mailbox {
	var deque = new Deque<Void->Void>();

	/** An empty mailbox. */
	public function new() {}

	/** Leaves work for the host thread; from any thread. */
	public function post(work:Void->Void):Void
		deque.add(work);

	/** Runs everything posted so far, in order; on the host thread. */
	public function deliver():Void {
		var work:Null<Void->Void>;
		while ((work = deque.pop(false)) != null)
			work();
	}
}
