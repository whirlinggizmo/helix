package helix.raylib.internal;

import helix.platform.Event;
import helix.platform.IEvents;

/** Reads the platform's events for the frame when raylib does, at its end (`EndDrawing`'s `PollInputEvents`), and looks at them as the
	frame begins (`BeginDrawing`) too, for the GPU's context being lost or given back, which the frame must know before it draws: the
	platform drops textures and static buffers at a restore, so a draw naming one before the frame has remade it is refused.

	What the look at the start takes is delivered again by the end's `poll`, so the devices and the screen see every event once, in
	order. */
@:noCompletion
class EarlyEvents implements IEvents {
	final inner:IEvents;
	// What the frame's start took from the platform, delivered with the rest at its end.
	var held:Array<Event> = [];
	var delivered:Array<Event> = [];

	/** Wraps the platform's events adapter.

		@param inner  The adapter. */
	public function new(inner:IEvents) {
		this.inner = inner;
	}

	/** Takes what the platform has so far and acts on the GPU's context: `lost` for `GraphicsLost`, `restored` for `GraphicsRestored`.
		Everything taken waits for the next `poll`.

		@param lost  What runs for the context lost.
		@param restored  What runs for the context given back. */
	public function peek(lost:Void->Void, restored:Void->Void):Void {
		inner.poll();
		for (event in inner.events) {
			held.push(event);
			switch event {
				case GraphicsLost:
					lost();
				case GraphicsRestored:
					restored();
				case _:
			}
		}
	}

	public function poll():Void {
		inner.poll();
		delivered = held.length == 0 ? inner.events : held.concat(inner.events);
		held = [];
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
