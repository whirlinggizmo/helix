package helix.render2d;

import helix.particles.Emitter;

/** An emitter of particles (helix.particles.Emitter, made flat for 2D), placed here: it spawns where this node is in the world, and the stage
	advances it by its clock (Renderer2D.time) each draw. Its particles draw at its place in the stage's order, through the GPU, and stay where
	they were born, so they trail as the node moves. */
class Particles2D extends Node2D {
	/** emitter, placed here. */
	public function new(emitter:Emitter) {
		super();
		this.emitter = emitter;
	}

	/** Its emitter. */
	public var emitter(default, null):Emitter;

	// The clock it was last advanced at: a tree several views show advances it once a frame.
	var advancedAt = Math.NaN;

	// Moved on by dt where it is (none while frozen), once a frame however many views show its tree; drawn when shown. Not culled: particles
	// reach past where it is.
	override function drawOwn(batch:Batch2D, camera:Camera2D, time:Float, dt:Float, frozen:Bool, shown:Bool):Bool {
		if (advancedAt != time) {
			advancedAt = time;
			emitter.advance(frozen ? 0 : dt, wx, wy, 0);
		}
		if (shown) {
			batch.resetTransform();
			batch.emitter(emitter);
		}
		return true;
	}
}
