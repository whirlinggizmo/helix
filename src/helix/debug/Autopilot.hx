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
	  the game differing. */
class Autopilot {
	var done = false;
	var ticks = 0;
	var seed:Int;
	var outcomes:Array<Dynamic> = [];

	/** Whether every command has finished. */
	public function isDone():Bool
		return done;

	/** Ticks the commands have run so far. */
	public function getTicks():Int
		return ticks;

	/** The script's seed, 1 to 2147483647, for the app's random numbers. */
	public function getSeed():Int
		return seed;

	/** One record a finished command: its index, op, the tick it finished on and the probe's value. */
	public function getOutcomes():Array<Dynamic>
		return outcomes;

	var commands:Array<Dynamic>;
	var index = 0;
	var elapsed = 0;
	var input = new InputState();
	var screenshot:Null<Null<String>->Void>;
	var press:Null<String->Bool>;
	var waitStarted = 0.;

	/** Checks a whole script ({version: 1, seed, commands}: press, hold, wait, assert, screenshot; at most 128) and throws on anything invalid or
		unknown. A wait has one limit: "timeout" in ticks, or "seconds" of the clock. A click uses a UI's widget by name, waiting (as a web
		suite's actions do) until press, the app's (Ui.press, say), finds it shown and usable, within its limit; without press it fails. A screenshot command calls screenshot with its name (null for the default name; Screenshots.take, say), or does nothing without
		one. */
	public function new(json:String, ?screenshot:Null<String>->Void, ?press:String->Bool) {
		this.screenshot = screenshot;
		this.press = press;
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
			input.keyEvent(key, desired.indexOf(key) >= 0);
	}

	/** Once a tick: runs commands until one needs this tick, asking probe for named values, and returns the input to play it with. Throws when a wait times out or an assert fails. */
	public function advance(probe:String->Dynamic):IInput {
		input.consume();
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
			return input;
		}
		return input;
	}

	/** Progress as a record: completed, ticks, the current command index and the outcomes. */
	public function getSnapshot():Dynamic
		return {
			completed: done,
			ticks: ticks,
			command: index,
			outcomes: outcomes
		};
}
