package helix.core;

import helix.asset.IRequest;

/** Asynchronous operations an adapter carries out on its platform, scheduled and settled here, the same on every platform: a queue, at most
	maxActive running at once, each settling exactly once on the host thread (with its result, or as cancelled: by its request, or when the
	pool shuts down), its completion run at a later poll, never during the call that settled it. An operation's start runs on the host thread
	when a slot is free; it settles its Job when the platform answers, and may set an abort for cancelling it while it runs. */
@:noCompletion
@:allow(helix)
class Jobs {
	var maxActive:Int;
	var active = 0;
	var waiting:Array<{request:JobRequest<Dynamic>, start:Void->Void}> = [];
	var runningList:Array<{job:Job<Dynamic>, request:JobRequest<Dynamic>}> = [];
	var queue = new WorkQueue();

	/** A pool running at most maxActive operations at once (clamped to at least 1). */
	function new(maxActive:Int)
		this.maxActive = maxActive < 1 ? 1 : maxActive;

	/** Whether it takes operations: false once shut down. */
	var live(default, null):Bool = true;

	/** Queues an operation: start runs on the host thread at a poll once a slot is free, given the operation's Job; complete runs exactly once
		on the host thread, at a poll after it settles, with the result its Job finished with, or with cancelled when its request is cancelled
		or the pool shuts down; with refused (cancelled when not given) for one added after the pool shut down. */
	function add<T>(start:Job<T>->Void, complete:T->Void, cancelled:T, ?refused:T):IRequest {
		var job:Job<T> = null, request:JobRequest<T> = null;
		request = new JobRequest<T>(this, complete, cancelled);
		job = new Job<T>(this, request);
		request.job = job;
		if (!live) {
			request.settle(refused != null ? refused : cancelled);
			return request;
		}
		waiting.push({
			request: cast request,
			start: () -> {
				if (request.settled)
					return;
				active++;
				runningList.push({job: cast job, request: cast request});
				job.started = true;
				job.startedAt = haxe.Timer.stamp();
				start(job);
			}
		});
		return request;
	}

	/** Whether an operation is waiting, running, or its completion not yet run. */
	var busy(get, never):Bool;

	function get_busy():Bool
		return active > 0 || waiting.length > 0 || !queue.empty;

	/** Runs f on the host thread at the next poll, in order with the completions: a running operation's progress, for one. */
	function post(f:Void->Void):Void
		queue.add(f);

	/** Starts queued operations while slots are free and runs completions; the owning service calls it once a frame. */
	function poll():Void {
		while (live && active < maxActive && waiting.length > 0)
			waiting.shift().start();
		queue.poll();
	}

	/** The operations running now, for a service checking them each frame (a timeout, say). */
	var running(get, never):Array<Job<Dynamic>>;

	function get_running():Array<Job<Dynamic>>
		return [for (r in runningList) r.job];

	/** Cancels every operation, queued or running (each completes with its cancelled value at the next poll, and a running one's abort runs),
		refuses later ones, and runs the completions. */
	function shutdown():Void {
		live = false;
		for (r in runningList.copy())
			r.request.cancel();
		for (w in waiting)
			w.request.cancel();
		waiting = [];
		queue.poll();
	}

	// An operation settled: its slot frees, and its completion runs at a poll.

	@:allow(helix.core.JobRequest)
	function settled<T>(request:JobRequest<T>, deliver:Void->Void):Void {
		for (r in runningList)
			if (r.request == cast request) {
				runningList.remove(r);
				active--;
				break;
			}
		queue.add(deliver);
	}
}

/** A running operation, as its adapter sees it: it finishes it once with its result, on the host thread, and may set what cancelling it while
	it runs does. */
@:noCompletion
@:allow(helix)
class Job<T> {
	var pool:Jobs;
	var request:JobRequest<T>;

	@:allow(helix.core.Jobs)
	var startedAt = 0.;

	@:allow(helix.core.Jobs)
	var started = false;

	@:allow(helix.core.Jobs)
	function new(pool:Jobs, request:JobRequest<T>) {
		this.pool = pool;
		this.request = request;
	}

	/** Settles it with result: its completion runs at the next poll. Nothing once it has settled (finished, or cancelled). */
	function finish(result:T):Void
		request.settle(result);

	/** Whether it has finished or been cancelled: a platform answer arriving after is dropped. */
	var settled(get, never):Bool;

	function get_settled():Bool
		return request.settled;

	/** What cancelling it while it runs does on the platform (abort a transfer, release a lease that arrives late), or null: run once, on
		the host thread. */
	var abort:Null<Void->Void>;

	/** Seconds since it started running. */
	var runningSeconds(get, never):Float;

	function get_runningSeconds():Float
		return haxe.Timer.stamp() - startedAt;

	@:allow(helix.core.JobRequest)
	function aborted():Void
		if (abort != null) {
			var f = abort;
			abort = null;
			f();
		}
}

/** The IRequest a Jobs operation's caller holds. */
@:allow(helix.core.Jobs)
@:allow(helix.core.Job)
@:noCompletion
@:allow(helix)
class JobRequest<T> implements IRequest {
	var pool:Jobs;
	var complete:T->Void;
	var cancelled:T;
	var done = false;
	var job:Job<T>;

	function new(pool:Jobs, complete:T->Void, cancelled:T) {
		this.pool = pool;
		this.complete = complete;
		this.cancelled = cancelled;
	}

	/** Whether it has settled. */
	var settled(get, never):Bool;

	function get_settled():Bool
		return done;

	public function cancel():Void {
		if (done)
			return;
		var wasStarted = job != null && job.started;
		settle(cancelled);
		if (wasStarted)
			job.aborted();
	}

	function settle(result:T):Void {
		if (done)
			return;
		done = true;
		var f = complete;
		pool.settled(this, () -> f(result));
	}
}
