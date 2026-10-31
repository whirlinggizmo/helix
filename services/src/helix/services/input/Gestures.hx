package helix.services.input;

import helix.platform.Event;
import helix.platform.IEvents;
import helix.platform.IPollable;
import helix.platform.ISystem;
import helix.platform.IWindow;

/** Provides gestures from the mouse and the fingers on the screen: a tap, a double tap, a hold, a drag, a swipe each way and a pinch in
	or out, as raylib's gestures (rgestures.h) detect them, from the frame's events in the order they came. Every mouse button counts as
	one finger. Positions and distances are fractions of the window, 0 to 1 across it.

	The program constructs one over its `IEvents`, `IWindow` and `ISystem`, and calls `poll` once a frame. The mouse's and touch's events
	arrive only while their adapters exist, so the program constructs those too.

	```haxe
	var gestures = new Gestures(events, window, system);
	// each frame:
	gestures.poll();
	if (gestures.isDetected(Tap)) select();
	``` */
class Gestures implements IPollable {
	static inline final FORCE_TO_SWIPE = 0.2;
	static inline final DRAG_TIMEOUT = 0.3;
	static inline final MINIMUM_PINCH = 0.005;
	static inline final TAP_TIMEOUT = 0.3;
	static inline final DOUBLETAP_RANGE = 0.03;

	final events:IEvents;
	final window:IWindow;
	final system:ISystem;
	// The gesture now, before `enabled` applies.
	var gesture:Gesture = None;

	/** Creates the gestures, none detected yet.

		@param events  The platform's events, whose last `poll` this one reads.
		@param window  The window, whose framebuffer's size positions are fractions of.
		@param system  The system, whose clock times holds, double taps and swipes. */
	public function new(events:IEvents, window:IWindow, system:ISystem) {
		this.events = events;
		this.window = window;
		this.system = system;
	}

	/** Gets or sets the gestures detected, as flags or'd together. Defaults to `All`. */
	public var enabled:Gesture = All;

	/** Gets the gesture detected now, or `None`: one that isn't enabled isn't. */
	public var current(get, never):Gesture;

	function get_current():Gesture
		return enabled & gesture;

	/** Returns whether a gesture is the one detected now.

		@param gesture  The gesture.
		@return  True while it is, and it is enabled. */
	public function isDetected(gesture:Gesture):Bool
		return current == gesture;

	/** Gets how long the hold has lasted, in seconds: 0 when the gesture isn't a hold. */
	public var holdDuration(get, never):Float;

	function get_holdDuration():Float
		return gesture == Hold ? now() - holdTime : 0;

	/** Gets the drag across, from where the finger landed to where it is, in fractions of the window's width. */
	public var dragX(default, null) = 0.;

	/** Gets the drag down, in fractions of the window's height. */
	public var dragY(default, null) = 0.;

	/** Gets the last swipe's angle, in degrees counterclockwise from right. */
	public var dragAngle(default, null) = 0.;

	/** Gets the pinch across, from the first finger to the second, in fractions of the window's width. */
	public var pinchX(default, null) = 0.;

	/** Gets the pinch down, in fractions of the window's height. */
	public var pinchY(default, null) = 0.;

	/** Gets the pinch's angle, in degrees counterclockwise from right. */
	public var pinchAngle(default, null) = 0.;

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

	/** Steps the gestures to the new frame, then reads the events the last `IEvents.poll` delivered. Call it once a frame. */
	public function poll():Void {
		if ((gesture == Tap || gesture == DoubleTap) && pointCount < 2) {
			gesture = Hold;
			holdTime = now();
		}
		if (gesture == SwipeRight || gesture == SwipeUp || gesture == SwipeLeft || gesture == SwipeDown)
			gesture = None;
		read();
	}

	function read():Void {
		var width = window.framebufferWidth, height = window.framebufferHeight;
		for (event in events.events)
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
				if (gesture == None
					&& tapCounter >= 2
					&& now() - eventTime < TAP_TIMEOUT
					&& distance(downAX, downAY, xs[0], ys[0]) < DOUBLETAP_RANGE) {
					gesture = DoubleTap;
					tapCounter = 0;
				} else {
					tapCounter = 1;
					gesture = Tap;
				}
				downAX = downDragX = upX = xs[0];
				downAY = downDragY = upY = ys[0];
				eventTime = swipeStart = now();
				dragX = dragY = 0;
			} else if (action == 0) {
				// A swipe can end a drag or, in a page especially, a hold.
				if (gesture == Drag || gesture == Hold) {
					upX = xs[0];
					upY = ys[0];
				}
				var intensity = distance(downAX, downAY, upX, upY) / (now() - swipeStart);
				if (intensity > FORCE_TO_SWIPE && gesture != Drag) {
					// The angle is inverted in y.
					dragAngle = 360 - angle(downAX, downAY, upX, upY);
					gesture = if (dragAngle < 30 || dragAngle > 330) SwipeRight else if (dragAngle <= 150) SwipeUp else if (dragAngle < 210) SwipeLeft else
						SwipeDown;
				} else {
					dragAngle = 0;
					gesture = None;
				}
				downDragX = downDragY = 0;
				pointCount = 0;
			} else {
				moveAX = xs[0];
				moveAY = ys[0];
				if (gesture == Hold) {
					if (holdResetRequired) {
						downAX = xs[0];
						downAY = ys[0];
					}
					holdResetRequired = false;
					if (now() - eventTime > DRAG_TIMEOUT) {
						eventTime = now();
						gesture = Drag;
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
				gesture = Hold;
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
					gesture = distance(previousAX, previousAY, previousBX, previousBY) > distance(moveAX, moveAY, moveBX, moveBY) ? PinchIn : PinchOut;
				} else {
					gesture = Hold;
					holdTime = now();
				}
				pinchAngle = 360 - angle(moveAX, moveAY, moveBX, moveBY);
			} else {
				pinchX = pinchY = pinchAngle = 0;
				pointCount = 0;
				gesture = None;
			}
		}
	}

	function now():Float
		return system.getTime();

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
