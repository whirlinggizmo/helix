# helix.core

[Back to the index](README.md)

## Job<T>

*class* in `src/helix/core/Jobs.hx`

A running operation, as its adapter sees it: it finishes it once with its result, on the host thread, and may set what cancelling it while it runs does.

```haxe
function finish(result:T):Void
function isSettled():Bool
function getAbort():Null<() -> Void>
function setAbort(abort:() -> Void):Void
function getRunningSeconds():Float
```

- `finish`: Settles it with result: its completion runs at the next poll. Nothing once it has settled (finished, or cancelled).
- `isSettled`: Whether it has finished or been cancelled: a platform answer arriving after is dropped.
- `getAbort`: What cancelling it while it runs does, or null.
- `setAbort`: What cancelling it while it runs does on the platform (abort a transfer, release a lease that arrives late); run once, on the host thread.
- `getRunningSeconds`: Seconds since it started running.

## JobRequest<T>

*class* in `src/helix/core/Jobs.hx`

The IRequest a Jobs operation's caller holds.

```haxe
function isSettled():Bool
function cancel():Void
```

- `isSettled`: Whether it has settled.

## Jobs

*class* in `src/helix/core/Jobs.hx`

Asynchronous operations an adapter carries out on its platform, scheduled and settled here, the same on every platform: a queue, at most maxActive running at once, each settling exactly once on the host thread (with its result, or as cancelled: by its request, or when the pool shuts down), its completion run at a later poll, never during the call that settled it. An operation's start runs on the host thread when a slot is free; it settles its Job when the platform answers, and may set an abort for cancelling it while it runs.

```haxe
function new(maxActive:Int)
function isLive():Bool
function add(start:Job<add.T> -> Void, complete:add.T -> Void, cancelled:add.T, ?refused:add.T):IRequest
function isBusy():Bool
function post(f:() -> Void):Void
function poll():Void
function getRunning():Array<Job<Dynamic>>
function shutdown():Void
```

- `new`: A pool running at most maxActive operations at once (clamped to at least 1).
- `isLive`: Whether it takes operations: false once shut down.
- `add`: Queues an operation: start runs on the host thread at a poll once a slot is free, given the operation's Job; complete runs exactly once on the host thread, at a poll after it settles, with the result its Job finished with, or with cancelled when its request is cancelled or the pool shuts down; with refused (cancelled when not given) for one added after the pool shut down.
- `isBusy`: Whether an operation is waiting, running, or its completion not yet run.
- `post`: Runs f on the host thread at the next poll, in order with the completions: a running operation's progress, for one.
- `poll`: Starts queued operations while slots are free and runs completions; the owning service calls it once a frame.
- `getRunning`: The operations running now, for a service checking them each frame (a timeout, say).
- `shutdown`: Cancels every operation, queued or running (each completes with its cancelled value at the next poll, and a running one's abort runs), refuses later ones, and runs the completions.

## WorkQueue

*class* in `src/helix/core/WorkQueue.hx`

Cooperative host work. Individual operations can exceed the nominal budget.

```haxe
function new()
function getBudgetMs():Float
function setBudgetMs(value:Float):Bool
function isEmpty():Bool
function add(work:() -> Void):Void
function poll():Void
```

- `new`: An empty queue with a 2 ms budget.
- `getBudgetMs`: Milliseconds poll may spend before it leaves the rest for the next poll; 2 to start.
- `setBudgetMs`: False for a budget under 0.
- `isEmpty`: Whether no work is queued.
- `add`: Queues work for a later poll, in order.
- `poll`: Runs queued work in order until the budget is spent (at least one item, when any is queued); work added meanwhile waits for the next poll.
