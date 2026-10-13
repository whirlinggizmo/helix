package helix.debug;

import helix.input.IInput;
import helix.input.Key;
import helix.input.InputState;

/** Bounded JSON commands produce normal input. Probes are supplied by the app. */
class Autopilot {
	var done = false;
	var ticks = 0;
	var seed:Int;
	var outcomes:Array<Dynamic> = [];

	public function isDone():Bool
		return done;

	public function getTicks():Int
		return ticks;

	public function getSeed():Int
		return seed;

	public function getOutcomes():Array<Dynamic>
		return outcomes;

	var commands:Array<Dynamic>;
	var index = 0;
	var elapsed = 0;
	var input = new InputState();

	public function new(json:String) {
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
					fields(command, ["op", "probe", "timeout"], ["equals", "atLeast", "keys"]);
					condition(command);
					if (!integer(command.timeout, 1, 36000))
						throw "Invalid wait timeout";
					if (command.keys != null)
						keys(command.keys);
				case "assert":
					fields(command, ["op", "probe"], ["equals", "atLeast"]);
					condition(command);
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
					if (matches(command, value))
						finish = true;
					else if (elapsed >= command.timeout)
						throw 'Autopilot timeout at command ' + index + ': ' + command.probe + '=' + haxe.Json.stringify(value);
				case "assert":
					value = probe(command.probe);
					if (!matches(command, value))
						throw 'Autopilot assertion failed at command ' + index + ': ' + command.probe + '=' + haxe.Json.stringify(value);
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

	public function getSnapshot():Dynamic
		return {
			completed: done,
			ticks: ticks,
			command: index,
			outcomes: outcomes
		};
}
