package helix.services.config;

import haxe.exceptions.NotImplementedException;
import helix.platform.ISystem;

/** Provides the options the program was started with, read as text, numbers or true and false, each with a fallback.

	Natively an option is the environment variable HELIX_ and its name in capitals, in a page the URL's query parameter
	(`ISystem.getOption`): `speed=2` is `HELIX_SPEED=2` natively and `?speed=2` in a page.

	```haxe
	var sound = config.getBool("audio", true);
	time.scale = config.getFloat("speed", 1);
	``` */
class Config {
	/** Creates the options over the platform's facts.

		@param system  The platform's facts, whose `getOption` it reads. */
	public function new(system:ISystem) {
		throw new NotImplementedException();
	}

	/** Returns whether an option was given.

		@param name  The option's name.
		@return  True when it was, even empty. */
	public function has(name:String):Bool {
		throw new NotImplementedException();
	}

	/** Returns an option as it was given.

		@param name  The option's name.
		@param fallback  What to return when it wasn't given.
		@return  Its text, or the fallback. */
	public function getString(name:String, fallback:String):String {
		throw new NotImplementedException();
	}

	/** Returns an option as true or false: 1, true, yes and on are true, 0, false, no and off false, in any case.

		@param name  The option's name.
		@param fallback  What to return when it wasn't given, or is none of those.
		@return  The value, or the fallback. */
	public function getBool(name:String, fallback:Bool):Bool {
		throw new NotImplementedException();
	}

	/** Returns an option as a whole number.

		@param name  The option's name.
		@param fallback  What to return when it wasn't given, or isn't a whole number.
		@return  The value, or the fallback. */
	public function getInt(name:String, fallback:Int):Int {
		throw new NotImplementedException();
	}

	/** Returns an option as a number.

		@param name  The option's name.
		@param fallback  What to return when it wasn't given, or isn't a finite number.
		@return  The value, or the fallback. */
	public function getFloat(name:String, fallback:Float):Float {
		throw new NotImplementedException();
	}
}
