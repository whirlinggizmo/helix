package helix.platform.adapters.tilt.dom;

import helix.platform.ITilt;
import helix.platform.TiltStatus;
import helix.platform.adapters.shared.EventStream;
import helix.platform.adapters.shared.dom.DomListeners;
import js.Browser;

/** Provides `ITilt` in a browser page: the device's orientation (deviceorientation), asked for at the player's next tap where the browser
	wants permission (iOS, and Chrome on Android). */
class DomTiltAdapter implements ITilt {
	final stream:EventStream;
	final answering:Void->Void;
	// The readings' listener while they're wanted, and the tap's while waiting to ask.
	final reading = new DomListeners();
	final asking = new DomListeners();
	var listening = false;
	var waiting = false;
	// The request's answers, called at the poll that delivers its outcome, once: done for the first reading, failed for a refusal.
	var whenDone:Null<Void->Void>;
	var whenFailed:Null<String->Void>;
	var answers:Array<Void->Void> = [];

	/** Creates the tilt, off until `requestAccess`.

		@param options  The events adapter its events are delivered by. */
	public function new(options:DomTiltAdapterOptions) {
		stream = options.events.stream;
		answering = () -> {
			var due = answers;
			answers = [];
			for (answer in due)
				answer();
		};
		stream.polls.push(answering);
	}

	/** Asks for the device's orientation.

		Where the browser asks for permission (iOS, and Chrome on Android), it is asked at the player's next tap, which shows its prompt. A
		page that isn't secure gets no readings (NeedsHttps). No reading within a second and a half of the page having its focus is reported
		unavailable without calling `failed`, and it goes on listening, as a phone's sensor may start late. */
	public function requestAccess(?done:Void->Void, ?failed:String->Void):Bool {
		var window:Dynamic = Browser.window;
		whenDone = done;
		whenFailed = failed;
		if (window.isSecureContext == false) {
			outcome(NeedsHttps, "the page isn't secure (not HTTPS), so the browser reads no orientation");
			return true;
		}
		if (window.DeviceOrientationEvent == null) {
			outcome(Unavailable, "this browser reads no orientation");
			return true;
		}
		if (!Std.isOfType(window.DeviceOrientationEvent.requestPermission, js.lib.Function))
			listen();
		else
			askAtNextTap();
		return true;
	}

	function listen():Void {
		if (listening)
			return;
		listening = true;
		var window = Browser.window, read = false;
		reading.add(window, "deviceorientation", e -> {
			// A reading without numbers (a sensor starting, or none) is passed over.
			if (e.beta == null || e.gamma == null)
				return;
			if (!read)
				outcome(On, null);
			read = true;
			var angle:Float = js.Syntax.code("(screen.orientation && screen.orientation.angle) || window.orientation || 0");
			stream.record(Tilt(e.beta, e.gamma, angle));
		});
		// Chrome gives no readings while the page hasn't its focus, and its prompt takes it until the player's next tap: the time is
		// counted from then.
		var count = () -> haxe.Timer.delay(() -> if (!read && listening) stream.record(TiltState(Unavailable)), 1500);
		if (Browser.document.hasFocus())
			count();
		else {
			var focused:Dynamic->Void = null;
			focused = _ -> {
				reading.remove(focused);
				count();
			};
			reading.add(window, "focus", focused);
		}
	}

	/** Stops the readings and any ask still waiting for a tap. */
	public function releaseAccess():Void {
		whenDone = null;
		whenFailed = null;
		var wanted = listening || waiting;
		reading.removeAll();
		asking.removeAll();
		listening = waiting = false;
		if (wanted)
			stream.record(TiltState(Off));
	}

	// Reports a status the request ends in, and queues its answer for the next poll; a status after the answer only reports.
	function outcome(status:TiltStatus, why:Null<String>):Void {
		stream.record(TiltState(status));
		var done = whenDone, failed = whenFailed;
		whenDone = null;
		whenFailed = null;
		if (status == On && done != null)
			answers.push(done);
		else if (status != On && failed != null)
			answers.push(() -> failed(why));
	}

	// Asks inside the next tap's own event, the only place the browser lets it be asked. An event whose press is already spent (going
	// fullscreen on the same tap spends it) is passed over: asked there, Chrome answers "denied" without asking the player. A failed ask
	// asks again at the next tap.
	function askAtNextTap():Void {
		var window:Dynamic = Browser.window;
		asking.removeAll();
		waiting = true;
		stream.record(TiltState(WaitingForTap));
		var tap = _ -> {
			var activation:Dynamic = js.Syntax.code("navigator.userActivation");
			if (activation != null && !activation.isActive)
				return;
			asking.removeAll();
			waiting = false;
			(window.DeviceOrientationEvent.requestPermission() : js.lib.Promise<String>).then(answer -> {
				if (answer == "granted")
					listen();
				else
					outcome(Refused, "the player refused the orientation's permission");
				return null;
			}, _ -> {
				askAtNextTap();
				return null;
			});
		};
		for (name in ["touchend", "click"])
			asking.add(window, name, tap, true);
	}

	public function dispose():Void {
		releaseAccess();
		stream.polls.remove(answering);
	}
}
