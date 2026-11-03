package helix.services.config;

import helix.platform.ISystem;

/** Provides the options the program was started with, read as text, numbers or true and false, each with a fallback.

	Options come from `ISystem.getOption`. Natively an option is on the command line, or else an environment variable named HELIX_
	followed by the option's name in capitals. In a page it is a query parameter in the URL. The option `speed=2` is `--speed=2` or
	`HELIX_SPEED=2` natively and `?speed=2` in a page.

	```haxe
	var sound = config.getBool("audio", true);
	time.scale = config.getFloat("speed", 1);
	``` */
class Config {
	static final WHOLE = ~/^[+-]?[0-9]+$/;
	static final NUMBER = ~/^[+-]?([0-9]+\.?[0-9]*|\.[0-9]+)([eE][+-]?[0-9]+)?$/;

	final system:ISystem;

	/** Creates the options over the platform's system.

		@param system  The platform's system, whose `getOption` it reads. */
	public function new(system:ISystem) {
		this.system = system;
	}

	/** Returns whether an option was provided.

		@param name  The option's name.
		@return  True when it was provided, even with an empty value. */
	public function hasOption(name:String):Bool {
		return system.getOption(name) != null;
	}

	/** Returns an option's text, unchanged.

		@param name  The option's name.
		@param fallback  The value to return when the option wasn't provided.
		@return  Its text, or the fallback. */
	public function getString(name:String, fallback:String):String {
		var value = system.getOption(name);
		return value == null ? fallback : value;
	}

	/** Returns an option as true or false.

		1, true, yes and on are true. 0, false, no and off are false. Case is ignored, and so are spaces around the value.

		@param name  The option's name.
		@param fallback  The value to return when the option wasn't provided, or is none of those words.
		@return  The value, or the fallback. */
	public function getBool(name:String, fallback:Bool):Bool {
		var value = system.getOption(name);
		if (value == null)
			return fallback;
		return switch StringTools.trim(value).toLowerCase() {
			case "1" | "true" | "yes" | "on": true;
			case "0" | "false" | "no" | "off": false;
			case _: fallback;
		}
	}

	/** Returns an option as a whole number.

		@param name  The option's name.
		@param fallback  The value to return when the option wasn't provided, or isn't a whole number in Int's range.
		@return  The value, or the fallback. */
	public function getInt(name:String, fallback:Int):Int {
		var value = system.getOption(name);
		if (value == null)
			return fallback;
		value = StringTools.trim(value);
		// Parsed as a float first, so a number past Int's range falls back rather than wrapping.
		if (!WHOLE.match(value))
			return fallback;
		var number = Std.parseFloat(value);
		return number < -2147483648 || number > 2147483647 ? fallback : Std.parseInt(value);
	}

	/** Returns an option as a number.

		@param name  The option's name.
		@param fallback  The value to return when the option wasn't provided, or isn't a finite number.
		@return  The value, or the fallback. */
	public function getFloat(name:String, fallback:Float):Float {
		var value = system.getOption(name);
		if (value == null)
			return fallback;
		value = StringTools.trim(value);
		if (!NUMBER.match(value))
			return fallback;
		var number = Std.parseFloat(value);
		return Math.isFinite(number) ? number : fallback;
	}
}
