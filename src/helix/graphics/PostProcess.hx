package helix.graphics;

import haxe.io.Bytes;
import helix.render2d.Texture2D;

/** Screen effects over a finished frame: the scene is drawn into a texture the screen's size (beginScene to endScene, a target pass), the
	enabled effects but the last draw in turn from one texture into another (target passes, still before the screen's), and present draws the
	last over the screen's pass, or the frame as it is when no effect is on. Its textures follow the screen's size. Effects run in the order
	given, so turning one off and on keeps its place. */
class PostProcess {
	var gpu:IGraphics;
	var targets:Array<Null<Texture2D>> = [null, null, null];
	var width = 0;
	var height = 0;
	var result:Null<Texture2D>;
	var last:Null<ScreenEffect>;
	var time = 0.;
	// Drawing the frame as it is: two clip-space triangles, sampling it whole.
	var copyBuffer:Int;
	// The sprite program's block 0, its clip scale, which the adapter writes.
	var clip = Bytes.alloc(16);
	var quad = Bytes.alloc(6 * Sprite2DLayout.stride);

	/** Effects drawn on gpu. */
	public function new(gpu:IGraphics) {
		this.gpu = gpu;
		copyBuffer = gpu.createBuffer(6 * Sprite2DLayout.stride);
		var corners = [
			[-1, 1, 0, 0],
			[1, 1, 1, 0],
			[1, -1, 1, 1],
			[-1, 1, 0, 0],
			[1, -1, 1, 1],
			[-1, -1, 0, 1]
		];
		for (i in 0...6) {
			var at = i * Sprite2DLayout.stride, c = corners[i];
			quad.setFloat(at + Sprite2DLayout.positionOffset, c[0]);
			quad.setFloat(at + Sprite2DLayout.positionOffset + 4, c[1]);
			quad.setFloat(at + Sprite2DLayout.uvOffset, c[2]);
			quad.setFloat(at + Sprite2DLayout.uvOffset + 4, c[3]);
			for (k in 0...4)
				quad.setFloat(at + Sprite2DLayout.colorOffset + k * 4, 1);
		}
	}

	/** The texture the scene is drawn into (the last beginScene's), or null before one. */
	public function getSceneTexture():Null<Texture2D>
		return targets[0];

	/** Starts the frame's scene: a target pass into a width x height texture (the screen's size), cleared to clearColor. Draw it as the screen;
		endScene ends it. Throws inside another pass. */
	public function beginScene(width:Int, height:Int, clearColor:Int):Void {
		if (width != this.width || height != this.height) {
			for (i in 0...targets.length)
				if (targets[i] != null) {
					targets[i].destroy(gpu);
					targets[i] = null;
				}
			this.width = width;
			this.height = height;
		}
		if (targets[0] == null)
			targets[0] = Texture2D.renderTarget(gpu, width, height);
		gpu.beginTargetPass(targets[0].getHandle(), clearColor);
	}

	/** Ends the scene's pass and draws effects (each that is enabled, in order) but the last, each from the one before's result into a texture
		of its own, at time seconds; the last waits for present. */
	public function endScene(effects:Array<ScreenEffect>, time:Float):Void {
		gpu.endTargetPass();
		this.time = time;
		var on = [for (e in effects) if (e.isEnabled()) e];
		result = targets[0];
		last = on.length > 0 ? on[on.length - 1] : null;
		for (i in 0...on.length - 1) {
			// Back and forth between two textures.
			var into = 1 + i % 2;
			if (targets[into] == null)
				targets[into] = Texture2D.renderTarget(gpu, width, height);
			gpu.beginTargetPass(targets[into].getHandle(), 0x000000ff);
			on[i].draw(result, width, height, time);
			gpu.endTargetPass();
			result = targets[into];
		}
	}

	/** Draws the processed frame over the open screen pass's viewport: the last effect over the others' result, or the frame as it is. */
	public function present():Void {
		if (result == null)
			return;
		if (last != null) {
			last.draw(result, width, height, time);
			return;
		}
		gpu.updateBuffer(copyBuffer, quad, quad.length);
		gpu.draw(Pipelines.of(gpu).sprite2D(Opaque), [copyBuffer], 0, 0, 6, 0, 1, [result.getHandle()], [Sampling.NEAREST], [clip]);
	}

	/** Frees its textures and buffer; the effects stay their owner's. */
	public function destroy():Void {
		for (t in targets)
			if (t != null)
				t.destroy(gpu);
		gpu.destroyBuffer(copyBuffer);
	}
}
