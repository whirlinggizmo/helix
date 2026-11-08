package helix.services.input;

import helix.platform.IEvents;
import helix.platform.IPollable;
import helix.platform.ITouch;

/** Provides the fingers on the screen as state: which are down, where each is, and which landed or lifted this frame.

	The program constructs one over its `IEvents` and its `ITouch`, and calls `poll` once a frame, as `Keyboard` is. A finger is known
	by its id from the frame it lands until the frame it lifts. Positions are in framebuffer pixels. When the window loses focus, every
	finger counts as lifted.

	```haxe
	var touch = new Touch(events, touchAdapter);
	// each frame:
	touch.poll();
	for (id in touch.pressed) tapAt(touch.getX(id), touch.getY(id));
	``` */
class Touch implements IPollable {
	final events:IEvents;
	final touch:ITouch;
	final down:Array<Int> = [];
	final landed:Array<Int> = [];
	final lifted:Array<Int> = [];
	// Where each finger down or lifted this frame is.
	final xs = new Map<Int, Float>();
	final ys = new Map<Int, Float>();

	/** Creates the touch over the platform's events and touch, with no finger down.

		@param events  The platform's events, whose last `poll` this one reads.
		@param touch  The platform's touch, whose fingers those events carry. */
	public function new(events:IEvents, touch:ITouch) {
		this.events = events;
		this.touch = touch;
	}

	/** Gets a value indicating whether the device has touch. */
	public var available(get, never):Bool;

	function get_available():Bool
		return touch.available;

	/** Gets the fingers down, by id, in the order they landed. The array is reused by the next poll. */
	public var fingers(get, never):Array<Int>;

	function get_fingers():Array<Int>
		return down;

	/** Gets the fingers that landed this frame, by id. The array is reused by the next poll. */
	public var pressed(get, never):Array<Int>;

	function get_pressed():Array<Int>
		return landed;

	/** Gets the fingers that lifted this frame, by id. The array is reused by the next poll. */
	public var released(get, never):Array<Int>;

	function get_released():Array<Int>
		return lifted;

	/** Reads the events the last `IEvents.poll` delivered. Call it once a frame. */
	public function poll():Void {
		for (id in lifted) {
			xs.remove(id);
			ys.remove(id);
		}
		landed.resize(0);
		lifted.resize(0);
		for (event in events.events)
			switch event {
				case TouchDown(id, x, y):
					if (down.indexOf(id) < 0) {
						down.push(id);
						landed.push(id);
						xs[id] = x;
						ys[id] = y;
					}
				case TouchMove(id, x, y):
					if (down.indexOf(id) >= 0) {
						xs[id] = x;
						ys[id] = y;
					}
				case TouchUp(id, x, y):
					if (down.remove(id)) {
						lifted.push(id);
						xs[id] = x;
						ys[id] = y;
					}
				case FocusLost:
					for (id in down)
						lifted.push(id);
					down.resize(0);
				case _:
			}
	}

	/** Returns whether a finger is down.

		@param id  The finger.
		@return  True from the frame it landed until the frame it lifted. */
	public function isFingerDown(id:Int):Bool {
		return down.indexOf(id) >= 0;
	}

	/** Returns whether a finger landed this frame.

		@param id  The finger.
		@return  True for that frame alone. */
	public function isFingerPressed(id:Int):Bool {
		return landed.indexOf(id) >= 0;
	}

	/** Returns whether a finger lifted this frame.

		@param id  The finger.
		@return  True for that frame alone. */
	public function isFingerReleased(id:Int):Bool {
		return lifted.indexOf(id) >= 0;
	}

	/** Returns a finger's distance from the window's left edge.

		@param id  The finger.
		@return  Where it is in framebuffer pixels, or where it lifted this frame; 0 for one that isn't down or lifting. */
	public function getX(id:Int):Float {
		var x = xs[id];
		return x == null ? 0 : x;
	}

	/** Returns a finger's distance from the window's top edge.

		@param id  The finger.
		@return  Where it is in framebuffer pixels, or where it lifted this frame; 0 for one that isn't down or lifting. */
	public function getY(id:Int):Float {
		var y = ys[id];
		return y == null ? 0 : y;
	}
}
