package helix.raylib.internal;

import helix.platform.Event;
import helix.platform.IEvents;

/** Reads the platform's events for the frame when raylib does, at its end (`EndDrawing`'s `PollInputEvents`), and looks at them as the
	frame begins (`BeginDrawing`) too, for the GPU's context being lost or restored, which the frame must know before it draws: the
	platform drops textures and static buffers at a restore, so a draw naming one before the frame has remade it is refused. A loss or
	restore read at the end is acted on there, before the next frame draws: in a page, the browser restores the context between frames.

	What the look at the start reads is delivered again by the end's `poll`, so the devices and the screen see every event once, in
	order. */
@:noCompletion
class EarlyEvents implements IEvents {
	final inner:IEvents;
	// What the frame's start read from the platform, delivered with the rest at its end.
	var held:Array<Event> = [];
	var delivered:Array<Event> = [];
	final lost:Void->Void;
	final restored:Void->Void;

	/** Wraps the platform's events adapter.

		@param inner  The adapter.
		@param lost  What runs for the GPU's context lost (`GraphicsLost`).
		@param restored  What runs for the GPU's context restored (`GraphicsRestored`). */
	public function new(inner:IEvents, lost:Void->Void, restored:Void->Void) {
		this.inner = inner;
		this.lost = lost;
		this.restored = restored;
	}

	/** Reads what the platform has so far and acts on the GPU's context. Everything read waits for the next `poll`. */
	public function peek():Void {
		inner.poll();
		for (event in inner.events) {
			held.push(event);
			act(event);
		}
	}

	public function poll():Void {
		inner.poll();
		for (event in inner.events)
			act(event);
		delivered = held.length == 0 ? inner.events : held.concat(inner.events);
		held = [];
	}

	// Runs what the GPU's context lost or restored calls for.
	function act(event:Event):Void
		switch event {
			case GraphicsLost:
				lost();
			case GraphicsRestored:
				restored();
			case _:
		}

	public var events(get, never):Array<Event>;

	function get_events():Array<Event>
		return delivered;

	public function wait(timeout:Float):Void
		inner.wait(timeout);

	public var unlocked(get, never):Bool;

	function get_unlocked():Bool
		return inner.unlocked;

	public function dispose():Void
		inner.dispose();
}
