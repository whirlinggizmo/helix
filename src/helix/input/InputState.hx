package helix.input;

/** A touch as it's tracked: changed in place as its finger moves. */
private typedef TouchState = {
	var id:Int;
	var x:Float;
	var y:Float;
	var down:Bool;
	var pressed:Bool;
	var released:Bool;
}

/** The input an app reads, as edges and state: fed by the InputRouter from a platform's events, or directly by replay and tests.
	Tick edges (isPressed, isReleased) are counted, and consume() after a simulation tick takes one of each, so every press is seen by exactly one tick,
	and two presses between ticks reach two ticks;
	frame edges (isFramePressed, isFrameReleased), typed text, the wheel and lifted touches last one frame, until endFrame() (the InputRouter's, which the Runner calls). */
class InputState implements IInput {
	var held:Array<Bool> = [for (_ in 0...Key.COUNT) false];
	var pushes:Array<Int> = [for (_ in 0...Key.COUNT) 0];
	var lifts:Array<Int> = [for (_ in 0...Key.COUNT) 0];
	var framePushes:Array<Bool> = [for (_ in 0...Key.COUNT) false];
	var frameLifts:Array<Bool> = [for (_ in 0...Key.COUNT) false];
	var mouseHeld = [false, false, false];
	var mousePushes = [0, 0, 0];
	var mouseLifts = [0, 0, 0];
	var mouseFramePushes = [false, false, false];
	var mouseFrameLifts = [false, false, false];
	var pads:Array<Gamepad> = [for (_ in 0...4) new Gamepad()];
	var pointerX = -1.;
	var pointerY = -1.;
	var pointerDown = false;
	var pointerPushes = 0;
	var pointerLifts = 0;
	var pointerFramePressed = false;
	var pointerFrameReleased = false;
	var text = "";
	var wheelX = 0.;
	var wheelY = 0.;
	var touches:Array<TouchState> = [];

	/** The gesture's pan x, y, log scale and rotation summed this frame, and since the last tick. */
	var frameGesture = [0., 0., 0., 0.];

	var tickGesture = [0., 0., 0., 0.];

	/** Nothing held, the pointer off the window, and four empty pad slots. */
	var activated = false;

	/** Nothing down, nothing pressed, no pad connected, not activated. */
	public function new() {}

	public function isDown(key:Key):Bool
		return held[key];

	public function isPressed(key:Key):Bool
		return pushes[key] > 0;

	public function isReleased(key:Key):Bool
		return lifts[key] > 0;

	public function isFramePressed(key:Key):Bool
		return framePushes[key];

	public function isFrameReleased(key:Key):Bool
		return frameLifts[key];

	public function getPointerX():Float
		return pointerX;

	public function getPointerY():Float
		return pointerY;

	public function isPointerDown():Bool
		return pointerDown;

	public function isPointerPressed():Bool
		return pointerPushes > 0;

	public function isPointerReleased():Bool
		return pointerLifts > 0;

	public function isPointerFramePressed():Bool
		return pointerFramePressed;

	public function isPointerFrameReleased():Bool
		return pointerFrameReleased;

	public function getWheelX():Float
		return wheelX;

	public function getWheelY():Float
		return wheelY;

	public function getText():String
		return text;

	public function getTouches():Array<Touch>
		return [
			for (t in touches)
				{
					id: t.id,
					x: t.x,
					y: t.y,
					down: t.down,
					pressed: t.pressed,
					released: t.released
				}
		];

	public function getPadCount():Int
		return pads.length;

	public function getPad(index:Int):Null<Gamepad>
		return index >= 0 && index < pads.length ? pads[index] : null;

	public function isMouseDown(button:MouseButton):Bool
		return mouseHeld[button];

	public function isMousePressed(button:MouseButton):Bool
		return mousePushes[button] > 0;

	public function isMouseFramePressed(button:MouseButton):Bool
		return mouseFramePushes[button];

	public function isMouseReleased(button:MouseButton):Bool
		return mouseLifts[button] > 0;

	public function isMouseFrameReleased(button:MouseButton):Bool
		return mouseFrameLifts[button];

	public function isPadDown(button:PadButton):Bool {
		for (pad in pads)
			if (pad.isConnected() && pad.isDown(button))
				return true;
		return false;
	}

	public function isPadPressed(button:PadButton):Bool {
		for (pad in pads)
			if (pad.isConnected() && pad.isPressed(button))
				return true;
		return false;
	}

	public function getPadAxis(axis:PadAxis):Float {
		for (pad in pads)
			if (pad.isConnected())
				return pad.getAxis(axis);
		return 0;
	}

	public function isActivated():Bool
		return activated;

	/** A key down (true) or up (false); only a change of state counts an edge, so key repeat doesn't. A down activates (isActivated). */
	public function keyEvent(key:Key, value:Bool):Void {
		if (value)
			activated = true;
		if (value && !held[key]) {
			pushes[key]++;
			framePushes[key] = true;
		}
		if (!value && held[key]) {
			lifts[key]++;
			frameLifts[key] = true;
		}
		held[key] = value;
	}

	/** Pad 0's button or axis, connecting it: for replay and tests. */
	public function padEvent(button:PadButton, value:Bool):Void {
		if (!pads[0].isConnected())
			pads[0].connect(true, "replay");
		pads[0].buttonEvent(button, value);
	}

	/** Pad 0's axis, connecting it: for replay and tests. */
	public function axisEvent(axis:PadAxis, value:Float):Void {
		if (!pads[0].isConnected())
			pads[0].connect(true, "replay");
		pads[0].axisEvent(axis, value);
	}

	/** A mouse button down (true) or up (false); only a change of state counts an edge. */
	public function mouseEvent(button:MouseButton, value:Bool):Void {
		if (value)
			activated = true;
		if (value && !mouseHeld[button]) {
			mousePushes[button]++;
			mouseFramePushes[button] = true;
		}
		if (!value && mouseHeld[button]) {
			mouseLifts[button]++;
			mouseFrameLifts[button] = true;
		}
		mouseHeld[button] = value;
	}

	/** The primary pointer at x, y in framebuffer pixels (-1, -1 off the window), down or up; only a change of down counts an edge. */
	public function pointerEvent(x:Float, y:Float, value:Bool):Void {
		if (value)
			activated = true;
		pointerX = x;
		pointerY = y;
		if (value && !pointerDown) {
			pointerPushes++;
			pointerFramePressed = true;
		}
		if (!value && pointerDown) {
			pointerLifts++;
			pointerFrameReleased = true;
		}
		pointerDown = value;
	}

	/** Typed characters, appended to this frame's text. */
	public function textEvent(value:String):Void
		text += value;

	/** Wheel notches, added to this frame's; up and right are positive. */
	public function wheelEvent(x:Float, y:Float):Void {
		wheelX += x;
		wheelY += y;
	}

	/** A finger down, moved or lifted. A lifted one stays in touches, not down, until the frame ends. */
	public function touchEvent(id:Int, x:Float, y:Float, value:Bool):Void {
		if (value)
			activated = true;
		var pair = gesturePair();
		var ax = 0., ay = 0., bx = 0., by = 0.;
		if (pair != null) {
			ax = pair[0].x;
			ay = pair[0].y;
			bx = pair[1].x;
			by = pair[1].y;
		}
		var touch = null;
		for (t in touches)
			if (t.id == id && t.down)
				touch = t;
		if (touch == null) {
			if (!value)
				return;
			touches.push({
				id: id,
				x: x,
				y: y,
				down: true,
				pressed: true,
				released: false
			});
			return;
		}
		touch.x = x;
		touch.y = y;
		if (!value) {
			touch.down = false;
			touch.released = true;
		}
		// The same two fingers before and after: they panned, pinched and twisted.
		var after = gesturePair();
		if (pair != null && after != null && after[0] == pair[0] && after[1] == pair[1]) {
			var nax = after[0].x,
				nay = after[0].y,
				nbx = after[1].x,
				nby = after[1].y;
			var before = Math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay)),
				now = Math.sqrt((nbx - nax) * (nbx - nax) + (nby - nay) * (nby - nay));
			var panX = (nax + nbx - ax - bx) / 2,
				panY = (nay + nby - ay - by) / 2;
			var turn = Math.atan2(nby - nay, nbx - nax) - Math.atan2(by - ay, bx - ax);
			if (turn > Math.PI)
				turn -= 2 * Math.PI;
			if (turn < -Math.PI)
				turn += 2 * Math.PI;
			for (g in [frameGesture, tickGesture]) {
				g[0] += panX;
				g[1] += panY;
				if (before > 0 && now > 0) {
					g[2] += Math.log(now / before);
					g[3] += turn;
				}
			}
		}
	}

	/** The two fingers down longest, which make the gesture; null with fewer than two down. */
	function gesturePair():Null<Array<TouchState>> {
		var down = [for (t in touches) if (t.down) t];
		return down.length >= 2 ? [down[0], down[1]] : null;
	}

	public function isTouchGesture():Bool
		return gesturePair() != null;

	public function getTouchGestureCenterX():Float {
		var pair = gesturePair();
		return pair == null ? 0 : (pair[0].x + pair[1].x) / 2;
	}

	public function getTouchGestureCenterY():Float {
		var pair = gesturePair();
		return pair == null ? 0 : (pair[0].y + pair[1].y) / 2;
	}

	public function getTouchGesturePanX(perTick = false):Float
		return (perTick ? tickGesture : frameGesture)[0];

	public function getTouchGesturePanY(perTick = false):Float
		return (perTick ? tickGesture : frameGesture)[1];

	public function getTouchGestureScale(perTick = false):Float
		return Math.exp((perTick ? tickGesture : frameGesture)[2]);

	public function getTouchGestureRotation(perTick = false):Float
		return (perTick ? tickGesture : frameGesture)[3];

	/** Lets go of everything held, as when focus is lost: the releases are edges; presses not yet consumed, typed text and the wheel are dropped. */
	public function clear():Void {
		for (key in Key.all)
			keyEvent(key, false);
		for (button in MouseButton.all)
			mouseEvent(button, false);
		for (pad in pads) {
			for (button in PadButton.all)
				pad.buttonEvent(button, false);
			for (axis in PadAxis.all)
				pad.axisEvent(axis, 0);
			pad.consume();
			pad.endFrame();
		}
		pointerEvent(-1, -1, false);
		for (t in touches)
			if (t.down)
				touchEvent(t.id, t.x, t.y, false);
		for (i in 0...pushes.length) {
			pushes[i] = 0;
			framePushes[i] = false;
		}
		for (i in 0...3) {
			mousePushes[i] = 0;
			mouseFramePushes[i] = false;
			mouseFrameLifts[i] = false;
		}
		pointerPushes = 0;
		pointerFramePressed = false;
		text = "";
		wheelX = 0;
		wheelY = 0;
	}

	public function consume():Void {
		tickGesture = [0., 0., 0., 0.];
		for (i in 0...pushes.length) {
			if (pushes[i] > 0)
				pushes[i]--;
			if (lifts[i] > 0)
				lifts[i]--;
		}
		for (pad in pads)
			pad.consume();
		for (i in 0...3) {
			if (mousePushes[i] > 0)
				mousePushes[i]--;
			if (mouseLifts[i] > 0)
				mouseLifts[i]--;
		}
		if (pointerPushes > 0)
			pointerPushes--;
		if (pointerLifts > 0)
			pointerLifts--;
	}

	/** Ends the frame's edges, text, wheel and lifted touches; the InputRouter calls it after each frame. */
	public function endFrame():Void {
		frameGesture = [0., 0., 0., 0.];
		for (i in 0...framePushes.length) {
			framePushes[i] = false;
			frameLifts[i] = false;
		}
		pointerFramePressed = false;
		pointerFrameReleased = false;
		for (i in 0...3) {
			mouseFramePushes[i] = false;
			mouseFrameLifts[i] = false;
		}
		for (pad in pads)
			pad.endFrame();
		text = "";
		wheelX = 0;
		wheelY = 0;
		touches = [for (t in touches) if (t.down) t];
		for (t in touches)
			t.pressed = false;
	}
}
