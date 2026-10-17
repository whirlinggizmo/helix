package helix.scene;

import helix.input.IInput;
import helix.render2d.Camera2D;
import helix.render2d.Stage2D;
import helix.render3d.Camera3D;
import helix.render3d.PickHit;
import helix.render3d.Stage3D;

/** The pointer over stages: which node it's over, and what it pressed and clicked, asked of it, never told to the nodes (DECISIONS 61). The
	stages it looks at are added in draw order, each with the camera it's drawn through; update() picks them topmost (last added) first, once
	a frame after input is polled, so a HUD drawn over the world takes the pointer first. A press on a 2D node captures the pointer: until it's
	released, the stages under it see nothing (isCaptured, for an app's own use of the pointer too). Edges (isPressed, isClicked) last the frame
	they happen in. Nodes are compared by identity: a 3D stage's are Node3Ds, a 2D stage's Node2Ds. */
class Pointer {
	var input:IInput;
	var layers:Array<Layer> = [];
	var hovered:Null<Any>;
	var held:Null<Any>;
	var pressedNow:Null<Any>;
	var clickedNow:Null<Any>;
	var captured = false;
	var hit = new PickHit();
	var hitLayer:Null<Layer>;

	/** The pointer of input. */
	public function new(input:IInput)
		this.input = input;

	/** Looks at stage through camera, above the stages added before it. */
	public function addStage2D(stage:Stage2D, camera:Camera2D):Void
		layers.push(new Layer(stage, camera, null, null));

	/** Looks at stage through camera, above the stages added before it. */
	public function addStage3D(stage:Stage3D, camera:Camera3D):Void
		layers.push(new Layer(null, null, stage, camera));

	/** Stops looking at stage (2D or 3D); what it held lets go. */
	public function remove(stage:Any):Void {
		layers = [for (l in layers) if (l.stage2D != stage && l.stage3D != stage) l];
		hovered = held = pressedNow = clickedNow = null;
		captured = false;
	}

	/** Once a frame, after input is polled and before the stages' nodes are read: picks under the pointer, topmost stage first, and works out
		the frame's press and click. */
	public function update():Void {
		var x = input.getPointerX(), y = input.getPointerY();
		pressedNow = clickedNow = null;
		hovered = null;
		hitLayer = null;
		var i = layers.length;
		while (hovered == null && i-- > 0) {
			var l = layers[i];
			// A captured pointer belongs to the 2D stages: the world under them sees nothing.
			if (l.stage2D != null)
				hovered = l.stage2D.pick(l.camera2D, x, y);
			else if (!captured && l.stage3D.pick(l.camera3D, x, y, hit) != null)
				hovered = hit.getNode();
			if (hovered != null)
				hitLayer = l;
		}
		if (input.isPointerFramePressed()) {
			held = pressedNow = hovered;
			captured = hitLayer != null && hitLayer.stage2D != null;
		}
		if (input.isPointerFrameReleased()) {
			if (held != null && held == hovered)
				clickedNow = held;
			held = null;
			captured = false;
		}
	}

	/** The node under the pointer, topmost stage first, or null. */
	public function getHovered():Null<Any>
		return hovered;

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
	public function getHeld():Null<Any>
		return held;

	/** Whether a press on a 2D stage holds the pointer: the stages under it, and the app's own world controls, should leave it be. */
	public function isCaptured():Bool
		return captured;

	/** The last hit in a 3D stage (its point, normal, distance), when the hovered node is a 3D stage's; null otherwise. */
	public function getHit3D():Null<PickHit>
		return hitLayer != null && hitLayer.stage3D != null ? hit : null;
}

/** A stage the pointer looks at, and the camera it's drawn through. */
private class Layer {
	/** A 2D stage, or null. */
	public var stage2D:Null<Stage2D>;

	/** Its camera. */
	public var camera2D:Null<Camera2D>;

	/** A 3D stage, or null. */
	public var stage3D:Null<Stage3D>;

	/** Its camera. */
	public var camera3D:Null<Camera3D>;

	/** A layer of one stage. */
	public function new(stage2D:Null<Stage2D>, camera2D:Null<Camera2D>, stage3D:Null<Stage3D>, camera3D:Null<Camera3D>) {
		this.stage2D = stage2D;
		this.camera2D = camera2D;
		this.stage3D = stage3D;
		this.camera3D = camera3D;
	}
}
