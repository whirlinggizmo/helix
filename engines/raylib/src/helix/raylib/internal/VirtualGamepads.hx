package helix.raylib.internal;

import helix.math.Bounds2D;
import helix.math.Vector2D;
import helix.platform.IPollable;
import helix.raylib.*;
import helix.services.input.VirtualStick;

/** A virtual gamepad in a slot, as `EnableVirtualGamepad` made it: the service's, given its options when enabled and its rectangles in
	framebuffer pixels each frame, and drawn over the frame as `EndDrawing` ends it. */
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
			Runtime.holdsFinger = id -> {
				for (made in made)
					if (made.service.holdsFinger(id))
						return true;
				return false;
			};
		}
		var all:VirtualGamepadOptions = options != null ? options : {};
		gamepad.rects = all.blockedBounds != null ? all.blockedBounds : [];
		gamepad.service.configure({
			basePlacement: cast all.basePlacement,
			deadZone: all.deadZone,
			left: gamepad.left.take(all, all.left),
			right: gamepad.right.take(all, all.right)
		});
		gamepad.service.enabled = true;
		gamepad.poll();
	}

	/** The service's virtual gamepad. */
	public final service:helix.services.input.VirtualGamepad;

	/** The slot it's in. */
	public final slot:Int;

	// The blocked bounds as the program gave them, and in framebuffer pixels; and each stick's look and rectangles.
	var rects:Array<Rectangle> = [];
	final blocked:Array<Bounds2D> = [];
	final left:Stick;
	final right:Stick;

	function new(slot:Int, service:helix.services.input.VirtualGamepad) {
		this.slot = slot;
		this.service = service;
		left = new Stick(service.left);
		right = new Stick(service.right);
	}

	/** Sets the rectangles in framebuffer pixels, then reads the fingers. */
	public function poll():Void {
		while (blocked.length < rects.length)
			blocked.push(new Bounds2D());
		blocked.resize(rects.length);
		for (i in 0...rects.length)
			Stick.toFramebuffer(rects[i], blocked[i]);
		service.blockedBounds = blocked;
		left.place();
		right.place();
		service.poll();
	}

	// Draws every virtual gamepad over the frame: each held stick, and each stick's hint until the first touch on a touch screen.
	static function drawAll():Void {
		for (gamepad in made)
			if (gamepad.service.enabled && !gamepad.service.physicalConnected) {
				var hint = gamepad.service.hintVisible;
				gamepad.left.draw(hint);
				gamepad.right.draw(hint);
			}
	}
}

// One stick's look and rectangles, which the service doesn't know: taken when the virtual gamepad is enabled, the rectangles read each
// frame.
private class Stick {
	final stick:VirtualStick;
	var zone:Null<Rectangle> = null;
	var fixed:Null<Vector2> = null;
	var radius = 60.;
	var hint = true;
	var outline = new Color(200, 200, 200, 128);
	var fill = new Color(0, 0, 0, 0);
	var knob = new Color(200, 200, 200, 192);
	final zoneBounds = new Bounds2D();
	final base = new Vector2D();

	public function new(stick:VirtualStick) {
		this.stick = stick;
	}

	// Takes the stick's look and rectangles, its own options else the gamepad's, and gives the service the rest.
	public function take(all:VirtualGamepadOptions, own:Null<VirtualStickOptions>):helix.services.input.VirtualStickOptions {
		var mine:VirtualStickOptions = own != null ? own : {};
		radius = mine.radius != null ? mine.radius : 60;
		zone = mine.touchZone;
		fixed = mine.fixedBasePosition;
		hint = (mine.drawHint != null ? mine.drawHint : all.drawHint) != false;
		var color = mine.baseOutlineColor != null ? mine.baseOutlineColor : all.baseOutlineColor;
		outline = color != null ? color : new Color(200, 200, 200, 128);
		color = mine.baseFillColor != null ? mine.baseFillColor : all.baseFillColor;
		fill = color != null ? color : new Color(0, 0, 0, 0);
		color = mine.knobColor != null ? mine.knobColor : all.knobColor;
		knob = color != null ? color : faded(outline, 1.5);
		return {enabled: mine.enabled, basePlacement: cast mine.basePlacement, deadZone: mine.deadZone};
	}

	// Sets the stick's radius, zone and fixed base in framebuffer pixels.
	public function place():Void {
		var screen = Runtime.screen;
		stick.radius = radius * (screen.toScreenX(1) - screen.toScreenX(0));
		stick.touchZone = zone != null ? toFramebuffer(zone, zoneBounds) : null;
		stick.fixedBasePosition = fixed != null ? base.set(screen.toScreenX(fixed.x), screen.toScreenY(fixed.y)) : null;
	}

	// Draws the stick held, or its hint at its home, fainter.
	public function draw(drawHint:Bool):Void {
		var held = stick.held;
		if (!stick.enabled || !held && !(drawHint && hint))
			return;
		var screen = Runtime.screen;
		var at = new Vector2(screen.toDesignX(stick.baseX), screen.toDesignY(stick.baseY));
		var ring = held ? outline : faded(outline, .4);
		if (held && fill.a > 0)
			helix.raylib.modules.RShapes.DrawCircleV(at, radius, fill);
		helix.raylib.modules.RShapes.DrawRing(at, radius - Math.max(2, radius / 16), radius, 0, 360, 48, ring);
		if (held)
			at = new Vector2(screen.toDesignX(stick.knobX), screen.toDesignY(stick.knobY));
		helix.raylib.modules.RShapes.DrawCircleV(at, radius * .4, held ? knob : ring);
	}

	public static function toFramebuffer(r:Rectangle, out:Bounds2D):Bounds2D {
		var screen = Runtime.screen;
		return out.set(screen.toScreenX(r.x), screen.toScreenY(r.y), screen.toScreenX(r.x + r.width), screen.toScreenY(r.y + r.height));
	}

	static function faded(color:Color, by:Float):Color
		return new Color(color.r, color.g, color.b, Std.int(Math.min(255, color.a * by)));
}
