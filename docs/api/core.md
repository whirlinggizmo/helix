# helix.core

[Back to the index](README.md)

## Job<T>

*class* in [`src/helix/core/Jobs.hx`](../../src/helix/core/Jobs.hx)

A running operation, as its adapter sees it: it finishes it once with its result, on the host thread, and may set what cancelling it while it runs does.

```haxe
function finish(result:T):Void
var settled(get, never):Bool
var abort:Null<() -> Void>
var runningSeconds(get, never):Float
```

- `finish`: Settles it with result: its completion runs at the next poll. Nothing once it has settled (finished, or cancelled).
- `settled`: Whether it has finished or been cancelled: a platform answer arriving after is dropped.
- `abort`: What cancelling it while it runs does on the platform (abort a transfer, release a lease that arrives late), or null: run once, on the host thread.
- `runningSeconds`: Seconds since it started running.

## JobRequest<T>

*class* in [`src/helix/core/Jobs.hx`](../../src/helix/core/Jobs.hx)

The IRequest a Jobs operation's caller holds.

```haxe
var settled(get, never):Bool
function cancel():Void
```

- `settled`: Whether it has settled.

## Jobs

*class* in [`src/helix/core/Jobs.hx`](../../src/helix/core/Jobs.hx)

Asynchronous operations an adapter carries out on its platform, scheduled and settled here, the same on every platform: a queue, at most maxActive running at once, each settling exactly once on the host thread (with its result, or as cancelled: by its request, or when the pool shuts down), its completion run at a later poll, never during the call that settled it. An operation's start runs on the host thread when a slot is free; it settles its Job when the platform answers, and may set an abort for cancelling it while it runs.

```haxe
function new(maxActive:Int)
var live(default, null):Bool
function add(start:Job<T> -> Void, complete:T -> Void, cancelled:T, ?refused:T):IRequest
var busy(get, never):Bool
function post(f:() -> Void):Void
function poll():Void
var running(get, never):Array<Job<Dynamic>>
function shutdown():Void
```

- `new`: A pool running at most maxActive operations at once (clamped to at least 1).
- `live`: Whether it takes operations: false once shut down.
- `add`: Queues an operation: start runs on the host thread at a poll once a slot is free, given the operation's Job; complete runs exactly once on the host thread, at a poll after it settles, with the result its Job finished with, or with cancelled when its request is cancelled or the pool shuts down; with refused (cancelled when not given) for one added after the pool shut down.
- `busy`: Whether an operation is waiting, running, or its completion not yet run.
- `post`: Runs f on the host thread at the next poll, in order with the completions: a running operation's progress, for one.
- `poll`: Starts queued operations while slots are free and runs completions; the owning service calls it once a frame.
- `running`: The operations running now, for a service checking them each frame (a timeout, say).
- `shutdown`: Cancels every operation, queued or running (each completes with its cancelled value at the next poll, and a running one's abort runs), refuses later ones, and runs the completions.

## WorkQueue

*class* in [`src/helix/core/WorkQueue.hx`](../../src/helix/core/WorkQueue.hx)

Cooperative host work. Individual operations can exceed the nominal budget.

```haxe
function new()
var budgetMs(default, set):Float
var empty(get, never):Bool
function add(work:() -> Void):Void
function poll():Void
```

- `new`: An empty queue with a 2 ms budget.
- `budgetMs`: Milliseconds poll may spend before it leaves the rest for the next poll; 2 to start. 0 or more (under 0, or NaN, is 0).
- `empty`: Whether no work is queued.
- `add`: Queues work for a later poll, in order.
- `poll`: Runs queued work in order until the budget is spent (at least one item, when any is queued); work added meanwhile waits for the next poll.
