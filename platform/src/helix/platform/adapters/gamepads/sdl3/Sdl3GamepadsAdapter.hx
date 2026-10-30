package helix.platform.adapters.gamepads.sdl3;

import helix.platform.IGamepads;
import helix.platform.PadAxis;
import helix.platform.PadButton;
import helix.platform.adapters.shared.sdl3.Sdl3EventsBridge;

/** Provides `IGamepads` on SDL3, natively, through SDL's controller database, in the W3C standard layout.

	SDL's gamepad subsystem starts with it and stops at `dispose`. Pads are read whether the window has the keyboard or not. */
class Sdl3GamepadsAdapter implements IGamepads {
	/** Starts SDL's gamepads.

		@param options  The events adapter its events are delivered by. */
	public function new(options:Sdl3GamepadsAdapterOptions) {
		Sdl3EventsBridge.want(Sdl3EventsBridge.GAMEPADS, 1);
	}

	public function isConnected(slot:Int):Bool
		return Sdl3EventsBridge.padConnected(slot) != 0;

	public function getName(slot:Int):String
		return (Sdl3EventsBridge.padName(slot) : String);

	public function isButtonDown(slot:Int, button:PadButton):Bool
		return Sdl3EventsBridge.padButton(slot, button) != 0;

	public function getAxis(slot:Int, axis:PadAxis):Float
		return Sdl3EventsBridge.padAxis(slot, axis);

	public function dispose():Void
		Sdl3EventsBridge.want(Sdl3EventsBridge.GAMEPADS, 0);
}
