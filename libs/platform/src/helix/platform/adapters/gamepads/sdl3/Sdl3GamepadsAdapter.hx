package helix.platform.adapters.gamepads.sdl3;

import helix.platform.IGamepads;
import helix.platform.GamepadAxis;
import helix.platform.GamepadButton;
import helix.platform.adapters.shared.sdl3.Sdl3EventsBridge;

/** Provides `IGamepads` on SDL3, natively, through SDL's controller database, in the W3C standard layout.

	SDL's gamepad subsystem starts with it and stops at `dispose`. Gamepads are read whether the window has the keyboard or not. */
class Sdl3GamepadsAdapter implements IGamepads {
	/** Starts SDL's gamepads.

		@param options  The events adapter its events are delivered by. */
	public function new(options:Sdl3GamepadsAdapterOptions) {
		Sdl3EventsBridge.want(Sdl3EventsBridge.GAMEPADS, 1);
	}

	public function isConnected(slot:Int):Bool
		return Sdl3EventsBridge.gamepadConnected(slot) != 0;

	public function getName(slot:Int):String
		return (Sdl3EventsBridge.gamepadName(slot) : String);

	public function isButtonDown(slot:Int, button:GamepadButton):Bool
		return Sdl3EventsBridge.gamepadButton(slot, button) != 0;

	public function getAxis(slot:Int, axis:GamepadAxis):Float
		return Sdl3EventsBridge.gamepadAxis(slot, axis);

	public function setVibration(slot:Int, low:Float, high:Float, seconds:Float):Bool
		return Sdl3EventsBridge.gamepadRumble(slot, low, high, Math.round(seconds * 1000)) != 0;

	public function addMappings(mappings:String):Int
		return Sdl3EventsBridge.gamepadAddMappings(mappings);

	public function dispose():Void
		Sdl3EventsBridge.want(Sdl3EventsBridge.GAMEPADS, 0);
}
