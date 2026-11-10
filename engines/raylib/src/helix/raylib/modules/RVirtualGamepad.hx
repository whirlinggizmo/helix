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
		options. Its held sticks and buttons, and whether it's plugged in, stay as they
		were.

		```haxe
		EnableVirtualGamepad(0, {
			right: {enabled: false},
			buttons: [{button: GAMEPAD_BUTTON_RIGHT_FACE_DOWN}, {button: GAMEPAD_BUTTON_RIGHT_FACE_RIGHT}]
		});
		```

		@param gamepad  The slot, 0 to 3.
		@param options  Optional. Its sticks, its buttons and their look. Two floating sticks, on the screen's left and right halves, when omitted. */
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

	/** Returns whether the virtual gamepad in a slot is drawn: enabled, on a device with touch, with no physical gamepad in its slot. A
		program drawing its own sticks (`visible: false`) draws them while this is true.

		@param gamepad  The slot, 0 to 3.
		@return  True while drawn. */
	static function IsVirtualGamepadVisible(gamepad:Int):Bool {
		var made = VirtualGamepads.inSlot(gamepad);
		return made != null && made.service.visible;
	}

	/** Returns whether a finger holds a stick of the virtual gamepad in a slot.

		@param gamepad  The slot, 0 to 3.
		@param stick  `VIRTUAL_STICK_LEFT` or `VIRTUAL_STICK_RIGHT`.
		@return  True while held. */
	static function IsVirtualStickHeld(gamepad:Int, stick:Int):Bool {
		var made = VirtualGamepads.inSlot(gamepad);
		return made != null && (stick == 1 ? made.service.right : made.service.left).held;
	}

	/** Returns where a stick's base is, in the screen's pixels. While the stick isn't held, the base is at the stick's home: the fixed base
		position, or one and a half radii in from the touch zone's bottom outer corner.

		@param gamepad  The slot, 0 to 3.
		@param stick  `VIRTUAL_STICK_LEFT` or `VIRTUAL_STICK_RIGHT`.
		@return  The base's center. (0, 0) without a virtual gamepad in the slot. */
	static function GetVirtualStickBase(gamepad:Int, stick:Int):Vector2 {
		var made = VirtualGamepads.inSlot(gamepad);
		return made != null ? made.stickPoint(stick == 1, false) : new Vector2(0, 0);
	}

	/** Returns where a stick's knob is, in the screen's pixels: under the finger, held within the radius of the base. While the stick isn't
		held, the knob is at the base.

		@param gamepad  The slot, 0 to 3.
		@param stick  `VIRTUAL_STICK_LEFT` or `VIRTUAL_STICK_RIGHT`.
		@return  The knob's center. (0, 0) without a virtual gamepad in the slot. */
	static function GetVirtualStickKnob(gamepad:Int, stick:Int):Vector2 {
		var made = VirtualGamepads.inSlot(gamepad);
		return made != null ? made.stickPoint(stick == 1, true) : new Vector2(0, 0);
	}
	#end
}
