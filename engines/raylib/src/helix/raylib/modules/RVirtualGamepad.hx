package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.internal.VirtualGamepads;
#end

/** Provides on-screen gamepads for phones, read through raylib's gamepad functions.

	`helix.raylib.extras.VirtualGamepad` forwards to each member (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RVirtualGamepad {
	#if !macro
	// ---- Virtual gamepad ----

	/** Enables a virtual gamepad in a slot. The first touch after enabling plugs the virtual gamepad in. Enabling it again applies the new
		options. Its held sticks, and whether it's plugged in, stay as they were.

		```haxe
		var pause = new Rectangle(GetScreenWidth() - 64, 0, 64, 64);
		EnableVirtualGamepad(0, {blockedBounds: [pause], right: {enabled: false}});
		```

		@param gamepad  The slot, 0 to 3.
		@param options  Optional. Its sticks and their look. Two floating sticks, on the screen's left and right halves, when omitted. */
	static function EnableVirtualGamepad(gamepad:Int, ?options:VirtualGamepadOptions):Void {
		if (gamepad >= 0 && gamepad < 4)
			VirtualGamepads.enable(gamepad, options);
	}

	/** Disables the virtual gamepad in a slot, unplugging it. A physical gamepad in that slot is unaffected.

		@param gamepad  The slot, 0 to 3. */
	static function DisableVirtualGamepad(gamepad:Int):Void {
		var made = VirtualGamepads.inSlot(gamepad);
		if (made != null)
			made.service.enabled = false;
	}

	/** Returns whether the gamepad in a slot is a virtual one (`EnableVirtualGamepad`).

		@param gamepad  The slot, 0 to 3.
		@return  True while a virtual gamepad is plugged in there. False for a physical one or an empty slot. */
	static function IsGamepadVirtual(gamepad:Int):Bool {
		var made = VirtualGamepads.inSlot(gamepad);
		return made != null && made.service.pluggedIn;
	}
	#end
}
