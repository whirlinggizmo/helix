package helix.render3d;

import helix.particles.Emitter;

/** An emitter of particles (helix.particles.Emitter), placed here: it spawns where this node is (a move spreads its spawns along the way, and
	particles may inherit its velocity), and the stage advances it by its clock (Renderer3D.setTime) each draw. Particles stay where they were
	born, so they trail as the node moves. */
class Particles3D extends Node3D {
	/** emitter, placed here. */
	public function new(emitter:Emitter) {
		super();
		this.emitter = emitter;
	}

	/** Its emitter. */
	public var emitter(default, null):Emitter;

	override function get_spriteKind():Node3D.SpriteKind3D
		return Node3D.SpriteKind3D.Emitter;

	override function attachSprites(renderer:Renderer3D):Void
		Sprites3D.attach(renderer);

	override function visitSprites(sprites:Any, planes:haxe.ds.Vector<Float>, eyeX:Float, eyeY:Float, eyeZ:Float, forwardX:Float, forwardY:Float,
			forwardZ:Float, still:Bool):Void
		(sprites : Sprites3D).visitEmitter(this, eyeX, eyeY, eyeZ, forwardX, forwardY, forwardZ, still);

	override function advanceSprites(sprites:Any):Void
		(sprites : Sprites3D).advanceEmitter(this);
}
