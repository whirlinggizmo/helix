package helix.render2d;

import helix.particles.Emitter;

/** An emitter of particles (helix.particles.Emitter, made flat for 2D), placed here: it spawns where this node is in the world, and the stage
	advances it by its clock (Stage2D.time) each draw. Its particles draw at its place in the stage's order, through the GPU, and stay where
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
	@:allow(helix.render2d.Stage2D)
	var advancedAt = Math.NaN;
}
