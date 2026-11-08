package helix.raylib.internal;

import helix.math.Bounds2D;
import helix.math.Vector2D;
import helix.platform.IPollable;
import helix.raylib.*;
import helix.services.input.VirtualStick;

/** A virtual gamepad in a slot, as `EnableVirtualGamepad` made it: the service's, set each frame from the program's options in the
	screen's pixels, and drawn over the frame as `EndDrawing` ends it. */
@:noCompletion
@:allow(helix.raylib)
class VirtualGamepads implements IPollable {
	// The virtual gamepads made, one a slot at most.
	static final made:Array<VirtualGamepads> = [];

	/** Gets the virtual gamepad in a slot, or null while none was enabled there.

		@param slot  The slot.
		@return  The virtual gamepad, or null. */
	public static function inSlot(slot:Int):Null<VirtualGamepads> {
		for (gamepad in made)
			if (gamepad.slot == slot)
				return gamepad;
		return null;
	}

	/** Enables the virtual gamepad in a slot with options: the one there takes them, or one is made in front of the gamepads.

		@param slot  The slot.
		@param options  The options, or null for the defaults. */
	public static function enable(slot:Int, options:Null<VirtualGamepadOptions>):Void {
		var gamepad = inSlot(slot);
		if (gamepad == null) {
			Runtime.gamepads();
			var standing:helix.platform.IGamepads = made.length > 0 ? made[made.length - 1].service : Runtime.gamepadsAdapter;
			gamepad = new VirtualGamepads(slot, new helix.services.input.VirtualGamepad(Runtime.touch(), Runtime.window, standing, slot));
			made.push(gamepad);
			Runtime.standInFront(gamepad.service, gamepad);
			Runtime.overlay = drawAll;
		}
		gamepad.options = options != null ? options : {};
		gamepad.service.enabled = true;
		gamepad.sync();
	}

	/** The service's virtual gamepad. */
	public final service:helix.services.input.VirtualGamepad;

	/** The slot it's in. */
	public final slot:Int;

	/** The program's options, read each frame. */
	public var options:VirtualGamepadOptions = {};

	// The fingers its sticks hold, and those that lifted from one this frame.
	final owned:Array<Int> = [];
	// The blocked bounds and each stick's zone and fixed base, in framebuffer pixels.
	final blocked:Array<Bounds2D> = [];
	final zones = [new Bounds2D(), new Bounds2D()];
	final bases = [new Vector2D(), new Vector2D()];

	function new(slot:Int, service:helix.services.input.VirtualGamepad) {
		this.slot = slot;
		this.service = service;
	}

	/** Sets the service from the options, then reads the fingers. */
	public function poll():Void {
		sync();
		service.poll();
		var touch = Runtime.touch();
		var i = owned.length;
		while (i-- > 0)
			if (!touch.isFingerDown(owned[i]) && !touch.isFingerReleased(owned[i]))
				owned.splice(i, 1);
		for (stick in [service.left, service.right])
			if (stick.held && owned.indexOf(stick.finger) < 0)
				owned.push(stick.finger);
		Runtime.stickFingers.resize(0);
		for (gamepad in made)
			for (id in gamepad.owned)
				Runtime.stickFingers.push(id);
	}

	// The service's sticks and blocked bounds from the options, in framebuffer pixels: a stick's own option, else the gamepad's, else
	// the default.
	function sync():Void {
		var screen = Runtime.screen;
		var scale = screen.toScreenX(1) - screen.toScreenX(0);
		var rects = options.blockedBounds != null ? options.blockedBounds : [];
		while (blocked.length < rects.length)
			blocked.push(new Bounds2D());
		blocked.resize(rects.length);
		for (i in 0...rects.length) {
			var r = rects[i];
			blocked[i].set(screen.toScreenX(r.x), screen.toScreenY(r.y), screen.toScreenX(r.x + r.width), screen.toScreenY(r.y + r.height));
		}
		service.blockedBounds = blocked;
		syncStick(service.left, options.left, 0, scale);
		syncStick(service.right, options.right, 1, scale);
	}

	function syncStick(stick:VirtualStick, own:Null<VirtualStickOptions>, index:Int, scale:Float):Void {
		var screen = Runtime.screen;
		var enabled = own != null && own.enabled != null ? own.enabled : true;
		if (stick.enabled != enabled)
			stick.enabled = enabled;
		var placement = own != null
			&& own.basePlacement != null ? own.basePlacement : options.basePlacement != null ? options.basePlacement : 0;
		stick.basePlacement = placement == 2 ? Fixed : placement == 1 ? Following : Floating;
		stick.deadZone = own != null && own.deadZone != null ? own.deadZone : options.deadZone != null ? options.deadZone : .12;
		stick.radius = (own != null && own.radius != null ? own.radius : 60) * scale;
		var zone = own != null ? own.touchZone : null;
		if (zone != null) {
			stick.touchZone = zones[index].set(screen.toScreenX(zone.x), screen.toScreenY(zone.y), screen.toScreenX(zone.x + zone.width),
				screen.toScreenY(zone.y + zone.height));
		} else
			stick.touchZone = null;
		var fixed = own != null ? own.fixedBasePosition : null;
		stick.fixedBasePosition = fixed != null ? bases[index].set(screen.toScreenX(fixed.x), screen.toScreenY(fixed.y)) : null;
	}

	// Draws every virtual gamepad over the frame: each held stick, and each stick's hint until the first touch on a touch screen.
	static function drawAll():Void {
		for (gamepad in made)
			gamepad.draw();
	}

	function draw():Void {
		if (!service.enabled || service.physicalConnected)
			return;
		var hint = service.hintVisible && Runtime.system.device.touchScreen;
		drawStick(service.left, options.left, hint);
		drawStick(service.right, options.right, hint);
	}

	function drawStick(stick:VirtualStick, own:Null<VirtualStickOptions>, hint:Bool):Void {
		if (!stick.enabled)
			return;
		var drawHint = own != null && own.drawHint != null ? own.drawHint : options.drawHint != null ? options.drawHint : true;
		if (!stick.held && !(hint && drawHint))
			return;
		var outline:Color = own != null
			&& own.baseOutlineColor != null ? own.baseOutlineColor : options.baseOutlineColor != null ? options.baseOutlineColor : new Color(200, 200, 200,
				128);
		var fill:Color = own != null
			&& own.baseFillColor != null ? own.baseFillColor : options.baseFillColor != null ? options.baseFillColor : new Color(0, 0, 0, 0);
		var knob:Null<Color> = own != null && own.knobColor != null ? own.knobColor : options.knobColor;
		var screen = Runtime.screen;
		var base = new Vector2(screen.toDesignX(stick.baseX), screen.toDesignY(stick.baseY));
		var radius = stick.radius * (screen.toDesignX(1) - screen.toDesignX(0));
		var width = Math.max(2, radius / 16);
		if (!stick.held) {
			// The hint: the ring and the knob at the stick's home, fainter.
			var faint = withAlpha(outline, outline.a * .4);
			helix.raylib.modules.RShapes.DrawRing(base, radius - width, radius, 0, 360, 48, faint);
			helix.raylib.modules.RShapes.DrawCircleV(base, radius * .4, faint);
			return;
		}
		if (fill.a > 0)
			helix.raylib.modules.RShapes.DrawCircleV(base, radius, fill);
		helix.raylib.modules.RShapes.DrawRing(base, radius - width, radius, 0, 360, 48, outline);
		var knobAt = new Vector2(screen.toDesignX(stick.knobX), screen.toDesignY(stick.knobY));
		helix.raylib.modules.RShapes.DrawCircleV(knobAt, radius * .4, knob != null ? knob : withAlpha(outline, Math.min(255, outline.a * 1.5)));
	}

	static function withAlpha(color:Color, alpha:Float):Color
		return new Color(color.r, color.g, color.b, Std.int(alpha));
}
