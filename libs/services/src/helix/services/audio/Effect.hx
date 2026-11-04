package helix.services.audio;

import haxe.exceptions.NotImplementedException;
import helix.platform.AudioEffect;

/** Represents an effect on what a group plays (`AudioEffects.add`), until it is removed. */
class Effect {
	@:allow(helix.services.audio)
	function new() {}

	/** Gets the group whose voices it changes. */
	public var group(default, null):Group;

	/** Gets or sets the effect's settings, of the same kind as when it was added. A change is ramped over a few milliseconds, so one
		made each frame doesn't click. Setting it ends a fade.

		@throws String  When set to another kind, or a setting outside its range. */
	public var settings(default, set):AudioEffect;

	function set_settings(value:AudioEffect):AudioEffect {
		throw new NotImplementedException();
	}

	/** Gets or sets a value indicating whether it is off, letting what plays through unchanged while keeping its place and settings.
		Defaults to false. */
	public var bypassed(default, set):Bool = false;

	function set_bypassed(value:Bool):Bool {
		throw new NotImplementedException();
	}

	/** Moves its settings to others over some real time. Frequencies move evenly in octaves, and every other setting in a straight line.

		@param settings  The settings to end at, of the same kind.
		@param seconds  The fade's length, in real seconds. 0 or less sets them at once.
		@param done  Optional. Called once they are reached, unless another fade or set settings end the fade first.
		@throws String  For another kind, or a setting outside its range. */
	public function fadeTo(settings:AudioEffect, seconds:Float, ?done:Void->Void):Void {
		throw new NotImplementedException();
	}

	/** Removes it from its group. Its members change nothing after. */
	public function remove():Void {
		throw new NotImplementedException();
	}
}
