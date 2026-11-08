package helix.raylib.internal;

import helix.math.Bounds2D;
import helix.math.Vector2D;
import helix.platform.IPollable;
import helix.raylib.*;
import helix.services.input.VirtualStick;

/** A virtual gamepad in a slot, as `EnableVirtualGamepad` made it: the service's, given its options when enabled and its rectangles,
	positions and radii in framebuffer pixels each frame, and drawn over the frame as `EndDrawing` ends it. */
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
			Runtime.capturesFinger = id -> {
				for (made in made)
					if (made.service.capturesFinger(id))
						return true;
				return false;
			};
		}
		var all:VirtualGamepadOptions = options != null ? options : {};
		gamepad.rects = all.blockedBounds != null ? all.blockedBounds : [];
		gamepad.buttons = [for (own in (all.buttons != null ? all.buttons : [])) new Button(own, all)];
		gamepad.font = all.font;
		gamepad.service.configure({
			basePlacement: cast all.basePlacement,
			deadZone: all.deadZone,
			left: gamepad.left.take(all, all.left),
			right: gamepad.right.take(all, all.right),
			buttons: [for (button in gamepad.buttons) button.options()]
		});
		for (i in 0...gamepad.buttons.length)
			gamepad.buttons[i].button = gamepad.service.buttons[i];
		gamepad.service.enabled = true;
		gamepad.poll();
	}

	/** The service's virtual gamepad. */
	public final service:helix.services.input.VirtualGamepad;

	/** Gets a stick's base or knob in the screen's pixels.

		@param right  The right stick, else the left.
		@param knob  The knob, else the base.
		@return  Its center. */
	public function stickPoint(right:Bool, knob:Bool):Vector2 {
		var stick = right ? service.right : service.left,
			screen = Runtime.screen;
		return knob ? new Vector2(screen.toDesignX(stick.knobX),
			screen.toDesignY(stick.knobY)) : new Vector2(screen.toDesignX(stick.baseX), screen.toDesignY(stick.baseY));
	}

	/** The slot it's in. */
	public final slot:Int;

	// The blocked bounds as the program gave them, and in framebuffer pixels; each stick's look and rectangles; and each button's.
	var rects:Array<Rectangle> = [];
	final blocked:Array<Bounds2D> = [];
	final left:Stick;
	final right:Stick;
	var buttons:Array<Button> = [];
	var font:Null<Font> = null;

	function new(slot:Int, service:helix.services.input.VirtualGamepad) {
		this.slot = slot;
		this.service = service;
		left = new Stick(service.left);
		right = new Stick(service.right);
	}

	/** Sets the rectangles, positions and radii in framebuffer pixels, then reads the fingers. */
	public function poll():Void {
		while (blocked.length < rects.length)
			blocked.push(new Bounds2D());
		blocked.resize(rects.length);
		for (i in 0...rects.length)
			Stick.toFramebuffer(rects[i], blocked[i]);
		service.blockedBounds = blocked;
		left.place();
		right.place();
		for (button in buttons)
			button.place();
		service.poll();
	}

	// Draws every virtual gamepad over the frame: each button and fixed stick on a device with touch, each held stick, and each stick's hint
	// until the first touch.
	static function drawAll():Void {
		for (gamepad in made)
			if (gamepad.service.enabled && !gamepad.service.physicalConnected) {
				var hint = gamepad.service.hintVisible,
					visible = gamepad.service.visible;
				gamepad.left.draw(hint, visible);
				gamepad.right.draw(hint, visible);
				if (visible)
					for (button in gamepad.buttons)
						button.draw(gamepad.font);
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
	var visible = true;
	var outline = new Color(200, 200, 200, 128);
	var fill = new Color(0, 0, 0, 0);
	var knob = new Color(200, 200, 200, 192);
	var baseTexture:Null<Texture2D> = null;
	var knobTexture:Null<Texture2D> = null;
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
		hint = (mine.hintVisible != null ? mine.hintVisible : all.hintVisible) != false;
		visible = mine.visible != false;
		baseTexture = mine.baseTexture != null ? mine.baseTexture : all.baseTexture;
		knobTexture = mine.knobTexture != null ? mine.knobTexture : all.knobTexture;
		var color = mine.baseOutlineColor != null ? mine.baseOutlineColor : all.baseOutlineColor;
		outline = color != null ? color : baseTexture != null ? new Color(255, 255, 255, 255) : new Color(200, 200, 200, 128);
		color = mine.baseFillColor != null ? mine.baseFillColor : all.baseFillColor;
		fill = color != null ? color : new Color(0, 0, 0, 0);
		color = mine.knobColor != null ? mine.knobColor : all.knobColor;
		knob = color != null ? color : knobTexture != null ? new Color(255, 255, 255, 255) : faded(outline, 1.5);
		return {enabled: mine.enabled, basePlacement: cast mine.basePlacement, deadZone: mine.deadZone};
	}

	// Sets the stick's radius, zone and fixed base in framebuffer pixels.
	public function place():Void {
		var screen = Runtime.screen;
		stick.radius = radius * (screen.toScreenX(1) - screen.toScreenX(0));
		stick.touchZone = zone != null ? toFramebuffer(zone, zoneBounds) : null;
		stick.fixedBasePosition = fixed != null ? base.set(screen.toScreenX(fixed.x), screen.toScreenY(fixed.y)) : null;
	}

	// Draws the stick held, a fixed stick at rest, or its hint at its home, fainter: each part its image, or its shapes.
	public function draw(hintShown:Bool, shown:Bool):Void {
		var held = stick.held,
			resting = !held && shown && stick.basePlacement == helix.services.input.VirtualStickBase.Fixed;
		if (!stick.enabled || !visible || !held && !resting && !(hintShown && hint))
			return;
		var screen = Runtime.screen, full = held || resting;
		var at = new Vector2(screen.toDesignX(stick.baseX), screen.toDesignY(stick.baseY));
		var ring = full ? outline : faded(outline, .4);
		if (baseTexture != null)
			image(baseTexture, at, radius, ring);
		else {
			if (held && fill.a > 0)
				helix.raylib.modules.RShapes.DrawCircleV(at, radius, fill);
			helix.raylib.modules.RShapes.DrawRing(at, radius - Math.max(2, radius / 16), radius, 0, 360, 48, ring);
		}
		if (held)
			at = new Vector2(screen.toDesignX(stick.knobX), screen.toDesignY(stick.knobY));
		if (knobTexture != null)
			image(knobTexture, at, radius * .4, full ? knob : faded(knob, .4));
		else
			helix.raylib.modules.RShapes.DrawCircleV(at, radius * .4, full ? knob : ring);
	}

	public static function toFramebuffer(r:Rectangle, out:Bounds2D):Bounds2D {
		var screen = Runtime.screen;
		return out.set(screen.toScreenX(r.x), screen.toScreenY(r.y), screen.toScreenX(r.x + r.width), screen.toScreenY(r.y + r.height));
	}

	public static function faded(color:Color, by:Float):Color
		return new Color(color.r, color.g, color.b, Std.int(Math.min(255, color.a * by)));

	// Draws a whole texture over a circle's square.
	public static function image(texture:Texture2D, at:Vector2, radius:Float, tint:Color):Void
		helix.raylib.modules.RTextures.DrawTexturePro(texture, new Rectangle(0, 0, texture.width, texture.height),
			new Rectangle(at.x - radius, at.y - radius, radius * 2, radius * 2), new Vector2(0, 0), 0, tint);
}

// One button's look and position, which the service doesn't know: taken when the virtual gamepad is enabled, the position and radius read
// each frame.
private class Button {
	public var button:Null<helix.services.input.VirtualButton> = null;

	final own:VirtualButtonOptions;
	final radius:Float;
	final label:String;
	final outline:Color;
	final fill:Color;
	final text:Null<Color>;
	final texture:Null<Texture2D>;
	final downTexture:Null<Texture2D>;
	final center = new Vector2D();

	// Takes the button's options, its colors defaulting to the gamepad's ring and knob colors.
	public function new(own:VirtualButtonOptions, all:VirtualGamepadOptions) {
		this.own = own;
		radius = own.radius != null ? own.radius : 40;
		label = own.label != null ? own.label : switch own.button {
			case helix.raylib.Raylib.GAMEPAD_BUTTON_RIGHT_FACE_DOWN: "A";
			case helix.raylib.Raylib.GAMEPAD_BUTTON_RIGHT_FACE_RIGHT: "B";
			case helix.raylib.Raylib.GAMEPAD_BUTTON_RIGHT_FACE_LEFT: "X";
			case helix.raylib.Raylib.GAMEPAD_BUTTON_RIGHT_FACE_UP: "Y";
			case _: "";
		};
		texture = own.texture;
		downTexture = own.downTexture;
		var color = all.baseOutlineColor != null ? all.baseOutlineColor : new Color(200, 200, 200, 128);
		outline = own.outlineColor != null ? own.outlineColor : texture != null ? new Color(255, 255, 255, 255) : color;
		color = all.knobColor != null ? all.knobColor : Stick.faded(color, 1.5);
		fill = own.fillColor != null ? own.fillColor : color;
		text = own.labelColor;
	}

	// The service's options: its gamepad button, and its center, which place moves, or null for its place in the diamond.
	public function options():helix.services.input.VirtualButtonOptions {
		var b = helix.raylib.modules.RCore.toGamepadButton(own.button);
		return {button: cast(b >= 0 ? b : 0), position: own.position != null ? center : null, enabled: own.enabled != false && b >= 0};
	}

	// Sets the center and radius in framebuffer pixels.
	public function place():Void {
		var screen = Runtime.screen, position = own.position;
		if (position != null)
			center.set(screen.toScreenX(position.x), screen.toScreenY(position.y));
		if (button != null)
			button.radius = radius * (screen.toScreenX(1) - screen.toScreenX(0));
	}

	// Draws the button's image, or its ring and its disc while down, then the label, in the gamepad's font, shrunk to fit the button.
	public function draw(font:Null<Font>):Void {
		var button = button;
		if (button == null || !button.enabled || !button.placed || own.visible == false)
			return;
		var down = button.down, screen = Runtime.screen;
		var at = new Vector2(screen.toDesignX(button.centerX), screen.toDesignY(button.centerY));
		if (texture != null || downTexture != null) {
			var image = down && downTexture != null ? downTexture : texture;
			if (image != null)
				Stick.image(image, at, radius, down && downTexture == null ? fill : outline);
		} else {
			if (down)
				helix.raylib.modules.RShapes.DrawCircleV(at, radius, fill);
			helix.raylib.modules.RShapes.DrawRing(at, radius - Math.max(2, radius / 16), radius, 0, 360, 48, outline);
		}
		if (label == "")
			return;
		var face = font != null ? font : helix.raylib.modules.RText.GetFontDefault();
		var size = radius, width = helix.raylib.modules.RText.MeasureTextEx(face, label, size, size / 10).x;
		if (width > radius * 1.6) {
			size *= radius * 1.6 / width;
			width = radius * 1.6;
		}
		helix.raylib.modules.RText.DrawTextEx(face, label, new Vector2(at.x - width / 2, at.y - size / 2), size, size / 10,
			text != null ? text : down ? new Color(0, 0, 0, 153) : outline);
	}
}
