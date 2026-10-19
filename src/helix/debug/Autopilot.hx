package helix.debug;

import helix.input.IInput;
import helix.input.Key;
import helix.input.InputState;

/** Bounded JSON commands produce normal input, a tick at a time; probes (named values) are supplied by the app. A script replays alike on
	every target when it keeps two rules:
	- It waits on state, never on time, for anything that isn't the simulation's (a load, a menu, a screen appearing): `wait` on a probe, its
	  limit in seconds (`"seconds"`); tick counts (`"timeout"`, `hold`) only for what the simulation itself does, once a wait has found it
	  running.
	- The game starts each replayed phase from a known state when it begins: play starting fresh from the seed (a new level), however late it
	  starts; a title screen's motion is dressing, not part of the game. Then a menu, a slow load or a frame's timing can delay a start without
	  the game differing.

	A `sample` reads the frame's pixels at points and puts them in snapshot's samples under its name, which tools/example.py compares
	between the browser and native: `{"op": "sample", "name": "lit", "points": [[x, y], ...]}`, the points in the design's units (Screen's),
	1 to 64 of them; `"tolerance"`, how far each channel (0 to 255) may differ across targets, 3 when not given; and `"differsFrom"` with
	`"by"`, an earlier sample's name and an amount, failing the script unless every point differs from the same point there by at least that
	much in some channel (an effect turned on against it off, so a shader drawing nothing fails); and `"matches"` with `"within"`, an earlier
	sample's name and an amount, failing it unless every point is within that much of the same point there in every channel (what must look
	the same either way, as a background with an HDR chain and without). The frame read is the one drawn after the
	ticks before it: while it waits for that frame to end, awaitingFrame is true and the app runs no tick. */
class Autopilot {
	var ticks = 0;

	/** Whether every command has finished. */
	public var done(default, null):Bool = false;

	/** Ticks the commands have run so far. */
	public var tickCount(get, never):Int;

	function get_tickCount():Int
		return ticks;

	/** The input the script plays, the one advance returns: the same object for the whole script, so what reads it (a UI, an Actions map)
		can be given it before the first tick. */
	public var input(get, never):IInput;

	function get_input():IInput
		return state;

	/** The script's seed, 1 to 2147483647, for the app's random numbers. */
	public var seed(default, null):Int;

	/** One record a finished command: its index, op, the tick it finished on and the probe's value. */
	public var outcomes(default, null):Array<Dynamic> = [];

	var commands:Array<Dynamic>;
	var index = 0;
	var elapsed = 0;
	var state = new InputState();
	var screenshot:Null<Null<String>->Void>;
	var press:Null<String->Bool>;
	var sample:Null<(points:Array<Array<Float>>, done:Array<Array<Int>>->Void, failed:String->Void) -> Void>;
	var waitStarted = 0.;
	var samples:Dynamic = {};
	var sampleAsked = false;
	var sampled:Null<Array<Array<Int>>>;
	var sampleFailure:Null<String>;

	/** Whether a sample waits for the frame being drawn to end: the input advance returned isn't to be played, and the app runs no tick this
		frame (its tick loop stops when this is true, as it does when done). */
	public var awaitingFrame(default, null):Bool = false;

	/** Checks a whole script ({version: 1, seed, commands}: press, hold, wait, assert, click, screenshot, sample; at most 128) and throws on
		anything invalid or unknown. A wait has one limit: "timeout" in ticks, or "seconds" of the clock. A click uses a UI's widget by name,
		waiting (as a web suite's actions do) until press, the app's (Ui.press, say), finds it shown and usable, within its limit; without press
		it fails. A screenshot command calls screenshot with its name (null for the default name; Screenshots.take, say), or does nothing without
		one. A sample calls sample with its points (Screenshots.sample, say), which calls done with each point's color as [r, g, b, a], 0 to 255,
		once the frame has ended, or failed; without sample it fails. */
	public function new(json:String, ?screenshot:Null<String>->Void, ?press:String->Bool,
			?sample:(points:Array<Array<Float>>, done:Array<Array<Int>>->Void, failed:String->Void) -> Void) {
		this.screenshot = screenshot;
		this.press = press;
		this.sample = sample;
		var document:Dynamic = haxe.Json.parse(json);
		fields(document, ["version", "seed", "commands"]);
		if (document.version != 1
			|| !integer(document.seed, 1, 2147483647)
			|| !Std.isOfType(document.commands, Array)
			|| document.commands.length == 0
			|| document.commands.length > 128)
			throw "Invalid autopilot header";
		seed = document.seed;
		commands = document.commands;
		// Each sample's name and its number of points, in the script's order: what a later one's differsFrom may name.
		var sampleCounts = new Map<String, Int>();
		for (command in commands) {
			switch (command.op) {
				case "press":
					fields(command, ["op", "key"]);
					if (!Std.isOfType(command.key, String))
						throw "Invalid press";
					Key.named(command.key);
				case "hold":
					fields(command, ["op", "keys", "ticks"]);
					keys(command.keys);
					if (!integer(command.ticks, 1, 36000))
						throw "Invalid hold duration";
				case "wait":
					fields(command, ["op", "probe"], ["equals", "atLeast", "keys", "timeout", "seconds"]);
					condition(command);
					// Exactly one limit: ticks for what the simulation does, seconds for what happens outside it (a load, a menu).
					if (Reflect.hasField(command, "timeout") == Reflect.hasField(command, "seconds"))
						throw "A wait needs a timeout in ticks or in seconds";
					if (Reflect.hasField(command, "timeout") && !integer(command.timeout, 1, 36000))
						throw "Invalid wait timeout";
					if (Reflect.hasField(command, "seconds")
						&& (!Std.isOfType(command.seconds, Float) || !(command.seconds > 0) || command.seconds > 600))
						throw "Invalid wait seconds";
					if (command.keys != null)
						keys(command.keys);
				case "assert":
					fields(command, ["op", "probe"], ["equals", "atLeast"]);
					condition(command);
				case "click":
					fields(command, ["op", "target"], ["timeout", "seconds"]);
					if (!Std.isOfType(command.target, String) || command.target == "")
						throw "Invalid click target";
					if (Reflect.hasField(command, "timeout") == Reflect.hasField(command, "seconds"))
						throw "A click needs a timeout in ticks or in seconds";
					if (Reflect.hasField(command, "timeout") && !integer(command.timeout, 1, 36000))
						throw "Invalid click timeout";
					if (Reflect.hasField(command, "seconds")
						&& (!Std.isOfType(command.seconds, Float) || !(command.seconds > 0) || command.seconds > 600))
						throw "Invalid click seconds";
				case "screenshot":
					fields(command, ["op"], ["name"]);
					if (command.name != null
						&& (!Std.isOfType(command.name, String) || !~/^[A-Za-z0-9_-]{1,64}\.png$/.match(command.name)))
						throw "Invalid screenshot name";
				case "sample":
					fields(command, ["op", "name", "points"], ["tolerance", "differsFrom", "by", "matches", "within"]);
					if (!Std.isOfType(command.name, String)
						|| !~/^[A-Za-z0-9_-]{1,64}$/.match(command.name)
						|| sampleCounts.exists(command.name))
						throw "Invalid or repeated sample name";
					var count = points(command.points);
					if (Reflect.hasField(command, "tolerance") && !integer(command.tolerance, 0, 255))
						throw "Invalid sample tolerance";
					if (Reflect.hasField(command, "differsFrom") != Reflect.hasField(command, "by"))
						throw "A sample's differsFrom and by go together";
					if (Reflect.hasField(command, "differsFrom")
						&& (!Std.isOfType(command.differsFrom, String) || sampleCounts.get(command.differsFrom) != count))
						throw "A sample differs from an earlier sample of as many points";
					if (Reflect.hasField(command, "by") && !integer(command.by, 1, 255))
						throw "Invalid sample difference";
					if (Reflect.hasField(command, "matches") != Reflect.hasField(command, "within"))
						throw "A sample's matches and within go together";
					if (Reflect.hasField(command, "matches")
						&& (!Std.isOfType(command.matches, String) || sampleCounts.get(command.matches) != count))
						throw "A sample matches an earlier sample of as many points";
					if (Reflect.hasField(command, "within") && !integer(command.within, 0, 255))
						throw "Invalid sample match";
					sampleCounts.set(command.name, count);
				default:
					throw "Unknown autopilot command";
			}
		}
	}

	static function fields(value:Dynamic, required:Array<String>, optional:Array<String> = null):Void {
		if (value == null || !Reflect.isObject(value) || Std.isOfType(value, Array))
			throw "Expected autopilot object";
		if (optional == null)
			optional = [];
		for (field in required)
			if (!Reflect.hasField(value, field))
				throw 'Missing autopilot field ' + field;
		for (field in Reflect.fields(value))
			if (required.indexOf(field) < 0 && optional.indexOf(field) < 0)
				throw 'Unknown autopilot field ' + field;
	}

	static function integer(value:Dynamic, min:Int, max:Int):Bool
		return Std.isOfType(value, Int) && value >= min && value <= max;

	// A sample's points: 1 to 64 [x, y] pairs of finite numbers. Their count.
	static function points(value:Dynamic):Int {
		if (!Std.isOfType(value, Array) || value.length < 1 || value.length > 64)
			throw "Invalid sample points";
		for (point in (cast value : Array<Dynamic>))
			if (!Std.isOfType(point, Array) || point.length != 2 || !finite(point[0]) || !finite(point[1]))
				throw "Invalid sample point";
		return value.length;
	}

	static function finite(value:Dynamic):Bool
		return Std.isOfType(value, Float) && Math.isFinite(value);

	static function keys(value:Dynamic):Array<Key> {
		if (!Std.isOfType(value, Array) || value.length > 12)
			throw "Invalid autopilot keys";
		var result:Array<Key> = [];
		for (item in (cast value : Array<Dynamic>)) {
			if (!Std.isOfType(item, String))
				throw "Invalid key name";
			var key = Key.named(item);
			if (result.indexOf(key) >= 0)
				throw "Duplicate key";
			result.push(key);
		}
		return result;
	}

	static function condition(command:Dynamic):Void {
		if (!Std.isOfType(command.probe, String) || Reflect.hasField(command, "equals") == Reflect.hasField(command, "atLeast"))
			throw "Expected one probe comparison";
		if (Reflect.hasField(command, "atLeast") && (!Std.isOfType(command.atLeast, Float) || !Math.isFinite(command.atLeast)))
			throw "Invalid numeric comparison";
	}

	static function matches(command:Dynamic, value:Dynamic):Bool
		return Reflect.hasField(command,
			"equals") ? haxe.Json.stringify(value) == haxe.Json.stringify(command.equals) : Std.isOfType(value, Float) && value >= command.atLeast;

	function setKeys(desired:Array<Key>):Void {
		for (key in Key.all)
			state.keyEvent(key, desired.indexOf(key) >= 0);
	}

	/** Once a tick: runs commands until one needs this tick, asking probe for named values, and returns the input to play it with. Throws when a wait times out or an assert fails. */
	public function advance(probe:String->Dynamic):IInput {
		// A tick is the script's frame too: its tick edges and frame edges both end here; not after a frame awaited, whose input wasn't played.
		if (!awaitingFrame) {
			state.consume();
			state.endFrame();
		}
		while (!done) {
			if (index == commands.length) {
				done = true;
				setKeys([]);
				break;
			}
			var command = commands[index],
				finish = false,
				value:Dynamic = null;
			switch (command.op) {
				case "press":
					setKeys([Key.named(command.key)]);
					if (elapsed == 1)
						finish = true;
				case "hold":
					setKeys(keys(command.keys));
					if (elapsed == command.ticks)
						finish = true;
				case "wait":
					setKeys(command.keys == null ? [] : keys(command.keys));
					value = probe(command.probe);
					if (elapsed == 0)
						waitStarted = haxe.Timer.stamp();
					if (matches(command, value))
						finish = true;
					else if (Reflect.hasField(command, "timeout") ? elapsed >= command.timeout : haxe.Timer.stamp() - waitStarted >= command.seconds)
						throw 'Autopilot timeout at command ' + index + ': ' + command.probe + '=' + haxe.Json.stringify(value);
				case "assert":
					value = probe(command.probe);
					if (!matches(command, value))
						throw 'Autopilot assertion failed at command ' + index + ': ' + command.probe + '=' + haxe.Json.stringify(value);
					finish = true;
				case "click":
					setKeys([]);
					if (elapsed == 0)
						waitStarted = haxe.Timer.stamp();
					if (press == null)
						throw 'Autopilot click at command ' + index + ' with nothing to press with';
					if (press(command.target))
						finish = true;
					else if (Reflect.hasField(command, "timeout") ? elapsed >= command.timeout : haxe.Timer.stamp() - waitStarted >= command.seconds)
						throw 'Autopilot timeout at command ' + index + ': no usable ' + command.target;
				case "screenshot":
					if (screenshot != null)
						screenshot(command.name);
					finish = true;
				case "sample":
					if (!sampleAsked) {
						if (sample == null)
							throw 'Autopilot sample at command ' + index + ' with nothing to read the frame with';
						sampleAsked = true;
						sampled = null;
						sampleFailure = null;
						sample(command.points, colors -> sampled = colors, message -> sampleFailure = message);
					}
					if (sampleFailure != null)
						throw 'Autopilot sample failed at command ' + index + ': ' + sampleFailure;
					if (sampled == null) {
						awaitingFrame = true;
						return state;
					}
					awaitingFrame = false;
					sampleAsked = false;
					record(command, sampled);
					finish = true;
			}
			if (finish) {
				outcomes.push({
					command: index,
					op: command.op,
					tick: ticks,
					value: value
				});
				index++;
				elapsed = 0;
				setKeys([]);
				continue;
			}
			elapsed++;
			ticks++;
			return state;
		}
		return state;
	}

	// A sample's colors kept under its name, with its points and tolerance; checked against the sample it must match or differ from.
	function record(command:Dynamic, colors:Array<Array<Int>>):Void {
		Reflect.setField(samples, command.name, {
			points: command.points,
			colors: colors,
			tolerance: Reflect.hasField(command, "tolerance") ? command.tolerance : 3
		});
		if (Reflect.hasField(command, "matches")) {
			var same:Array<Array<Int>> = Reflect.field(samples, command.matches).colors;
			for (i in 0...colors.length) {
				var most = 0;
				for (c in 0...4)
					most = Std.int(Math.max(most, Math.abs(colors[i][c] - same[i][c])));
				if (most > command.within)
					throw 'Autopilot assertion failed at command ' + index + ': sample ' + command.name + ' point ' + i + ' differs from ' + command.matches
						+ ' by ' + most + ', over ' + command.within;
			}
		}
		if (!Reflect.hasField(command, "differsFrom"))
			return;
		var other:Array<Array<Int>> = Reflect.field(samples, command.differsFrom).colors;
		for (i in 0...colors.length) {
			var most = 0;
			for (c in 0...4)
				most = Std.int(Math.max(most, Math.abs(colors[i][c] - other[i][c])));
			if (most < command.by)
				throw 'Autopilot assertion failed at command ' + index + ': sample ' + command.name + ' point ' + i + ' differs from ' + command.differsFrom
					+ ' by ' + most + ', under ' + command.by;
		}
	}

	/** Progress as a record: completed, ticks, the current command index, the outcomes and the samples (by name: points, colors as
		[r, g, b, a] and tolerance). */
	public var snapshot(get, never):Dynamic;

	function get_snapshot():Dynamic
		return {
			completed: done,
			ticks: ticks,
			command: index,
			outcomes: outcomes,
			samples: samples
		};
}
