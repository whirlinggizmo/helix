package helix.ray.internal;

import helix.platform.Event;
import helix.platform.IPollable;

/** Holds raylib's gestures (rgestures.h), fed the frame's mouse and touch events in the order they came, as raylib's callbacks feed
	it: every mouse button as one finger, and the fingers on the screen. Positions are normalized to the screen, 0 to 1. */
@:noCompletion
class Gestures implements IPollable {
	static inline final FORCE_TO_SWIPE = 0.2;
	static inline final DRAG_TIMEOUT = 0.3;
	static inline final MINIMUM_PINCH = 0.005;
	static inline final TAP_TIMEOUT = 0.3;
	static inline final DOUBLETAP_RANGE = 0.03;

	static inline final NONE = 0;
	static inline final TAP = 1;
	static inline final DOUBLETAP = 2;
	static inline final HOLD = 4;
	static inline final DRAG = 8;
	static inline final SWIPE_RIGHT = 16;
	static inline final SWIPE_LEFT = 32;
	static inline final SWIPE_UP = 64;
	static inline final SWIPE_DOWN = 128;
	static inline final PINCH_IN = 256;
	static inline final PINCH_OUT = 512;

	/** The gesture now, before the enabled flags apply. */
	public var current = NONE;

	/** The gestures `SetGesturesEnabled` allows; all of them until it is called. */
	public var enabledFlags = 0x3ff;

	/** The drag: from where the finger landed to where it is, normalized. */
	public var dragX = 0.;

	public var dragY = 0.;

	/** The swipe's angle, in degrees counterclockwise from right, as the finger lifted. */
	public var dragAngle = 0.;

	/** The pinch: from the first finger to the second, normalized. */
	public var pinchX = 0.;

	public var pinchY = 0.;

	/** The pinch's angle, in degrees counterclockwise from right. */
	public var pinchAngle = 0.;

	var holdTime = 0.;

	var pointCount = 0;
	var eventTime = 0.;
	var upX = 0.;
	var upY = 0.;
	var downAX = 0.;
	var downAY = 0.;
	var downBX = 0.;
	var downBY = 0.;
	var downDragX = 0.;
	var downDragY = 0.;
	var moveAX = 0.;
	var moveAY = 0.;
	var moveBX = 0.;
	var moveBY = 0.;
	var previousAX = 0.;
	var previousAY = 0.;
	var previousBX = 0.;
	var previousBY = 0.;
	var tapCounter = 0;
	var holdResetRequired = false;
	var swipeStart = 0.;

	// The fingers down, in the order they landed, and where each is.
	final fingers:Array<Int> = [];
	final fingerX = new Map<Int, Float>();
	final fingerY = new Map<Int, Float>();
	final xs:Array<Float> = [];
	final ys:Array<Float> = [];

	/** Creates the gestures, fed the events of the frame they are made in. */
	public function new() {
		read();
	}

	/** Steps the gestures to the new frame, as raylib's `UpdateGestures` does, then reads its events. */
	public function poll():Void {
		if ((current == TAP || current == DOUBLETAP) && pointCount < 2) {
			current = HOLD;
			holdTime = now();
		}
		if (current == SWIPE_RIGHT || current == SWIPE_UP || current == SWIPE_LEFT || current == SWIPE_DOWN)
			current = NONE;
		read();
	}

	/** Returns how long the hold has lasted, in seconds, or 0 when the gesture isn't a hold. */
	public function holdDuration():Float
		return current == HOLD ? now() - holdTime : 0;

	function read():Void {
		var width = Runtime.window.framebufferWidth,
			height = Runtime.window.framebufferHeight;
		for (event in Runtime.events.events)
			switch event {
				case MouseDown(_, x, y):
					one(1, x / width, y / height);
				case MouseUp(_, x, y):
					one(0, x / width, y / height);
				case MouseMove(x, y):
					one(2, x / width, y / height);
				case TouchDown(id, x, y):
					if (fingers.indexOf(id) < 0) {
						fingers.push(id);
						finger(id, x / width, y / height);
						touches(1);
					}
				case TouchMove(id, x, y):
					if (fingers.indexOf(id) >= 0) {
						finger(id, x / width, y / height);
						touches(2);
					}
				case TouchUp(id, x, y):
					if (fingers.indexOf(id) >= 0) {
						finger(id, x / width, y / height);
						touches(0);
						fingers.remove(id);
						fingerX.remove(id);
						fingerY.remove(id);
					}
				case _:
			}
	}

	function finger(id:Int, x:Float, y:Float):Void {
		fingerX.set(id, x);
		fingerY.set(id, y);
	}

	function one(action:Int, x:Float, y:Float):Void {
		xs.resize(0);
		ys.resize(0);
		xs.push(x);
		ys.push(y);
		process(action, 1);
	}

	function touches(action:Int):Void {
		xs.resize(0);
		ys.resize(0);
		for (id in fingers) {
			xs.push(fingerX.get(id));
			ys.push(fingerY.get(id));
		}
		process(action, fingers.length);
	}

	// raylib's ProcessGestureEvent; action is TOUCH_ACTION_UP (0), DOWN (1) or MOVE (2).
	function process(action:Int, count:Int):Void {
		pointCount = count;
		if (count == 1) {
			if (action == 1) {
				tapCounter++;
				if (current == NONE
					&& tapCounter >= 2
					&& now() - eventTime < TAP_TIMEOUT
					&& distance(downAX, downAY, xs[0], ys[0]) < DOUBLETAP_RANGE) {
					current = DOUBLETAP;
					tapCounter = 0;
				} else {
					tapCounter = 1;
					current = TAP;
				}
				downAX = downDragX = upX = xs[0];
				downAY = downDragY = upY = ys[0];
				eventTime = swipeStart = now();
				dragX = dragY = 0;
			} else if (action == 0) {
				// A swipe can end a drag or, in a page especially, a hold.
				if (current == DRAG || current == HOLD) {
					upX = xs[0];
					upY = ys[0];
				}
				var intensity = distance(downAX, downAY, upX, upY) / (now() - swipeStart);
				if (intensity > FORCE_TO_SWIPE && current != DRAG) {
					// The angle is inverted in y.
					dragAngle = 360 - angle(downAX, downAY, upX, upY);
					current = if (dragAngle < 30 || dragAngle > 330) SWIPE_RIGHT else if (dragAngle <= 150) SWIPE_UP else if (dragAngle < 210) SWIPE_LEFT else
						SWIPE_DOWN;
				} else {
					dragAngle = 0;
					current = NONE;
				}
				downDragX = downDragY = 0;
				pointCount = 0;
			} else {
				moveAX = xs[0];
				moveAY = ys[0];
				if (current == HOLD) {
					if (holdResetRequired) {
						downAX = xs[0];
						downAY = ys[0];
					}
					holdResetRequired = false;
					if (now() - eventTime > DRAG_TIMEOUT) {
						eventTime = now();
						current = DRAG;
					}
				}
				dragX = moveAX - downDragX;
				dragY = moveAY - downDragY;
			}
		} else if (count == 2) {
			if (action == 1) {
				downAX = previousAX = xs[0];
				downAY = previousAY = ys[0];
				downBX = previousBX = xs[1];
				downBY = previousBY = ys[1];
				pinchX = downBX - downAX;
				pinchY = downBY - downAY;
				current = HOLD;
				holdTime = now();
			} else if (action == 2) {
				moveAX = xs[0];
				moveAY = ys[0];
				moveBX = xs[1];
				moveBY = ys[1];
				pinchX = moveBX - moveAX;
				pinchY = moveBY - moveAY;
				if (distance(previousAX, previousAY, moveAX, moveAY) >= MINIMUM_PINCH
					|| distance(previousBX, previousBY, moveBX, moveBY) >= MINIMUM_PINCH) {
					current = distance(previousAX, previousAY, previousBX, previousBY) > distance(moveAX, moveAY, moveBX, moveBY) ? PINCH_IN : PINCH_OUT;
				} else {
					current = HOLD;
					holdTime = now();
				}
				pinchAngle = 360 - angle(moveAX, moveAY, moveBX, moveBY);
			} else {
				pinchX = pinchY = pinchAngle = 0;
				pointCount = 0;
				current = NONE;
			}
		}
	}

	static function now():Float
		return Runtime.system.getTime();

	static function distance(x1:Float, y1:Float, x2:Float, y2:Float):Float {
		var dx = x2 - x1, dy = y2 - y1;
		return Math.sqrt(dx * dx + dy * dy);
	}

	// Degrees from the x axis, 0 to 360.
	static function angle(x1:Float, y1:Float, x2:Float, y2:Float):Float {
		var result = Math.atan2(y2 - y1, x2 - x1) * (180 / Math.PI);
		return result < 0 ? result + 360 : result;
	}
}
