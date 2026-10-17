package helix.render3d;

import helix.particles.Emitter;

/** An emitter of particles (helix.particles.Emitter), placed here: it spawns where this node is (a move spreads its spawns along the way, and
	particles may inherit its velocity), and the stage advances it by its clock (Stage3D.setTime) each draw. Particles stay where they were
	born, so they trail as the node moves. */
class Particles3D extends Node3D {
	/** emitter, placed here. */
	public function new(emitter:Emitter) {
		super();
		this.emitter = emitter;
	}

	/** Its emitter. */
	public var emitter(default, null):Emitter;
}
