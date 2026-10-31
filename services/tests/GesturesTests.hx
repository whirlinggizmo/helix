import helix.services.input.Gesture;
import helix.services.input.Gestures;

/** Checks Gestures over fake events, window and clock: a click as a tap for a frame, then a hold, then none; a second quick click as a
	double tap; a slow drag; a fast swipe up; two fingers pinching out; positions as fractions of the window; and the enabled flags hiding
	what isn't enabled. */
class GesturesTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		var events = new FakeEvents(), system = new FakeSystem();
		var gestures = new Gestures(events, new FakeWindow(), system);
		function frame(seconds:Float, ?list:Array<helix.platform.Event>) {
			system.now += seconds;
			if (list != null)
				for (e in list)
					events.next.push(e);
			events.poll();
			gestures.poll();
		}

		frame(.016);
		check(gestures.current == None, "nothing yet");
		frame(.016, [MouseDown(Left, 400, 300)]);
		check(gestures.isDetected(Tap), "a click: a tap");
		frame(.016);
		check(gestures.isDetected(Hold) && gestures.holdDuration >= 0, "the next frame: a hold");
		frame(.1, [MouseUp(Left, 400, 300)]);
		check(gestures.current == None, "let go: none");
		frame(.05, [MouseDown(Left, 401, 300)]);
		check(gestures.isDetected(DoubleTap), "a second click soon after and near: a double tap");
		frame(.016, [MouseUp(Left, 401, 300)]);
		frame(1);

		frame(.016, [MouseDown(Left, 200, 300)]);
		frame(.4, [MouseMove(240, 300)]);
		frame(.016, [MouseMove(400, 300)]);
		check(gestures.isDetected(Drag) && Math.abs(gestures.dragX - 200 / 800) < 1e-9 && gestures.dragY == 0,
			"held a moment, then moved: a drag, in fractions of the window");
		frame(.016, [MouseUp(Left, 400, 300)]);
		check(gestures.current == None, "a drag let go: none, not a swipe");
		frame(1);

		frame(.016, [MouseDown(Left, 400, 500)]);
		frame(.03, [MouseMove(400, 100), MouseUp(Left, 400, 100)]);
		check(gestures.isDetected(SwipeUp)
			&& Math.abs(gestures.dragAngle - 90) < 1e-6, "a fast move up as it lifts: a swipe up, at 90 degrees");
		frame(.016);
		check(gestures.current == None, "a swipe lasts a frame");

		frame(1, [TouchDown(1, 350, 300)]);
		frame(.05, [TouchDown(2, 450, 300)]);
		check(gestures.isDetected(Hold), "a second finger: a hold");
		frame(.05, [TouchMove(1, 300, 300), TouchMove(2, 500, 300)]);
		check(gestures.isDetected(PinchOut) && gestures.pinchX > 0, "two fingers moving apart: a pinch out");
		frame(.05, [TouchUp(1, 300, 300), TouchUp(2, 500, 300)]);

		gestures.enabled = Drag;
		frame(1, [MouseDown(Left, 400, 300)]);
		check(gestures.current == None && !gestures.isDetected(Tap), "a tap that isn't enabled isn't detected");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
