package helix.scene;

import helix.input.IInput;
import helix.render2d.Camera2D;
import helix.render2d.Renderer2D;
import helix.render3d.Camera3D;
import helix.render3d.PickHit3D;
import helix.render3d.Renderer3D;

/** The pointer over stages: which node it's over, and what it pressed and clicked, asked of it, never told to the nodes (DECISIONS 61). The
	stages it looks at are added in draw order, each with the camera it's drawn through; update() picks them topmost (last added) first, once
	a frame after input is polled, so a HUD drawn over the world takes the pointer first. A press on a 2D node captures the pointer: until it's
	released, the stages under it see nothing (captured, for an app's own use of the pointer too). Edges (isPressed, isClicked) last the frame
	they happen in. Nodes are compared by identity: a 3D stage's are Node3Ds, a 2D stage's Node2Ds. With no stages added, it looks at the
	Stage (helix.render2d.Stage) and the views on it, in their drawing order (docs/DISPLAY_MODEL.md). */
class Pointer {
	// The input given, or null for the program's (Input), read when used: one an autopilot plays is the program's while it plays.
	var given:Null<IInput>;
	var input(get, never):IInput;

	function get_input():IInput
		return given != null ? given : helix.input.Input.instance;

	var layers:Array<Layer> = [];
	var pressedNow:Null<Any>;
	var clickedNow:Null<Any>;
	var hit = new PickHit3D();
	// What the hovered node is in: a 2D tree (which captures a press) or a 3D one (hit3D).
	var hovered2D = false;
	var hovered3D = false;

	/** The pointer of input, or of the program's (Input) when not given, read as it's used, so a pointer made before the program runs (a
		field's initial value) works. */
	public function new(?input:IInput)
		given = input;

	/** Looks at renderer's tree through camera, above the trees added before it (a test's, a tree no view shows; a game's pointer looks at
		the stage). */
	@:noCompletion
	public function addRenderer2D(renderer:Renderer2D, camera:Camera2D):Void
		layers.push(new Layer(renderer, camera, null, null));

	/** Looks at renderer's tree through camera, above the trees added before it (a test's, a tree no view shows; a game's pointer looks at
		the stage). */
	@:noCompletion
	public function addRenderer3D(renderer:Renderer3D, camera:Camera3D):Void
		layers.push(new Layer(null, null, renderer, camera));

	/** Stops looking at renderer (2D or 3D); what it held lets go. */
	@:noCompletion
	public function remove(renderer:Any):Void {
		layers = [for (l in layers) if (l.renderer2D != renderer && l.renderer3D != renderer) l];
		hovered = held = pressedNow = clickedNow = null;
		captured = false;
	}

	/** Once a frame, after input is polled and before the stages' nodes are read: picks under the pointer, topmost stage first, and works out
		the frame's press and click. */
	public function update():Void {
		var x = input.pointerX, y = input.pointerY;
		pressedNow = clickedNow = null;
		hovered = null;
		hovered2D = hovered3D = false;
		// No stages of its own: the stage's, topmost first, through its views (docs/DISPLAY_MODEL.md).
		var stage = helix.render2d.Stage.instance;
		if (layers.length == 0 && stage != null) {
			var found = stage.pick(x, y, hit);
			hovered2D = Std.isOfType(found, helix.render2d.Node2D);
			// A captured pointer belongs to the 2D: the 3D under it sees nothing.
			hovered3D = found != null && !hovered2D && !captured;
			hovered = hovered2D || hovered3D ? found : null;
		}
		var i = layers.length;
		while (hovered == null && i-- > 0) {
			var l = layers[i];
			// A captured pointer belongs to the 2D stages: the world under them sees nothing.
			if (l.renderer2D != null)
				hovered = l.renderer2D.pick(l.camera2D, x, y);
			else if (!captured && l.renderer3D.pick(l.camera3D, x, y, hit) != null)
				hovered = hit.node;
			if (hovered != null) {
				hovered2D = l.renderer2D != null;
				hovered3D = l.renderer3D != null;
			}
		}
		if (input.pointerFramePressed) {
			held = pressedNow = hovered;
			captured = hovered2D;
		}
		if (input.pointerFrameReleased) {
			if (held != null && held == hovered)
				clickedNow = held;
			held = null;
			captured = false;
		}
	}

	/** The node under the pointer, topmost stage first, or null. */
	public var hovered(default, null):Null<Any>;

	/** Whether node is under the pointer. */
	public function isHovered(node:Any):Bool
		return node != null && hovered == node;

	/** Whether the pointer went down on node this frame. */
	public function isPressed(node:Any):Bool
		return node != null && pressedNow == node;

	/** Whether node is held: the pointer went down on it and hasn't come up, wherever it is now (a drag). */
	public function isDown(node:Any):Bool
		return node != null && held == node;

	/** Whether node was clicked this frame: the pointer came up over the node it went down on. */
	public function isClicked(node:Any):Bool
		return node != null && clickedNow == node;

	/** The node held (isDown), or null. */
	public var held(default, null):Null<Any>;

	/** Whether a press on a 2D stage holds the pointer: the stages under it, and the app's own world controls, should leave it be. */
	public var captured(default, null):Bool = false;

	/** The last hit in a 3D stage (its point, normal, distance), when the hovered node is a 3D stage's; null otherwise. */
	public var hit3D(get, never):Null<PickHit3D>;

	function get_hit3D():Null<PickHit3D>
		return hovered3D ? hit : null;
}

/** A stage the pointer looks at, and the camera it's drawn through. */
private class Layer {
	/** A 2D stage, or null. */
	public var renderer2D:Null<Renderer2D>;

	/** Its camera. */
	public var camera2D:Null<Camera2D>;

	/** A 3D stage, or null. */
	public var renderer3D:Null<Renderer3D>;

	/** Its camera. */
	public var camera3D:Null<Camera3D>;

	/** A layer of one stage. */
	public function new(renderer2D:Null<Renderer2D>, camera2D:Null<Camera2D>, renderer3D:Null<Renderer3D>, camera3D:Null<Camera3D>) {
		this.renderer2D = renderer2D;
		this.camera2D = camera2D;
		this.renderer3D = renderer3D;
		this.camera3D = camera3D;
	}
}
