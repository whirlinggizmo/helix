package helix.render3d;

import helix.particle.Emitter;

/** An emitter of particles (helix.particle.Emitter), placed here: it spawns where this node is (a move spreads its spawns along the way, and
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

	/** Whether it takes itself off its parent once its emitter is spent (Emitter.spent: a one-shot's burst died out), the frame after: true
		for the one-shot presets (explosion, smokePuff, sparks, dust, confetti), so a game puts one down and forgets it; false otherwise. */
	public var removeWhenSpent = false;

	var removing = false;

	// Off its parent the frame after it's found spent (not during the draw that found it), when it's to be.
	function removeIfSpent():Void {
		if (!removeWhenSpent || removing || !emitter.spent)
			return;
		removing = true;
		helix.scene.Flow.run(_ -> {
			removing = false;
			if (removeWhenSpent && emitter.spent && parent != null)
				parent.removeChild(this);
			return false;
		});
	}

	override function get_spriteKind():Node3D.SpriteKind3D
		return Node3D.SpriteKind3D.Emitter;

	override function attachSprites(renderer:Renderer3D):Void
		Sprites3D.attach(renderer);

	override function visitSprites(sprites:Any, planes:haxe.ds.Vector<Float>, eyeX:Float, eyeY:Float, eyeZ:Float, forwardX:Float, forwardY:Float,
			forwardZ:Float, still:Bool):Void
		(sprites : Sprites3D).visitEmitter(this, eyeX, eyeY, eyeZ, forwardX, forwardY, forwardZ, still);

	override function advanceSprites(sprites:Any):Void {
		(sprites : Sprites3D).advanceEmitter(this);
		removeIfSpent();
	}

	// A one-shot preset's node: off its parent once spent.
	static function oneShot(emitter:Emitter):Particles3D {
		var node = new Particles3D(emitter);
		node.removeWhenSpent = true;
		return node;
	}

	/** A preset (helix.particle.ParticlePreset.Explosion): a burst of light outward, fading from white-yellow to red: a hit, a pop, a small explosion. One-shot, off its parent once spent (removeWhenSpent); size about how big it is, in world units. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function explosion(size:Float):Particles3D
		return oneShot(helix.particle.ParticlePreset.Explosion.make(size, -1, false));

	/** A preset (helix.particle.ParticlePreset.SmokePuff): a soft gray puff, spreading and rising a little as it fades: a landing, a vanish. One-shot, off its parent once spent (removeWhenSpent); size about how big it is, in world units. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function smokePuff(size:Float):Particles3D
		return oneShot(helix.particle.ParticlePreset.SmokePuff.make(size, -1, false));

	/** A preset (helix.particle.ParticlePreset.Sparks): hot sparks thrown up and out, streaked and falling: a hit on metal. One-shot, off its parent once spent (removeWhenSpent); size about how big it is, in world units. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function sparks(size:Float):Particles3D
		return oneShot(helix.particle.ParticlePreset.Sparks.make(size, -1, false));

	/** A preset (helix.particle.ParticlePreset.Dust): a low, wide kick of dust that settles: footsteps, a landing, a skid. One-shot, off its parent once spent (removeWhenSpent); size about how big it is, in world units. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function dust(size:Float):Particles3D
		return oneShot(helix.particle.ParticlePreset.Dust.make(size, -1, false));

	/** A preset (helix.particle.ParticlePreset.Fire): a steady flame, rising and fading from yellow to red: a torch, a campfire; size about how big it is, in world units. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function fire(size:Float):Particles3D
		return new Particles3D(helix.particle.ParticlePreset.Fire.make(size, -1, false));

	/** A preset (helix.particle.ParticlePreset.Smoke): a steady column of gray smoke, rising and spreading: a chimney, a wreck; size about how big it is, in world units. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function smoke(size:Float):Particles3D
		return new Particles3D(helix.particle.ParticlePreset.Smoke.make(size, -1, false));

	/** A preset (helix.particle.ParticlePreset.Rain): steady rain over a width of size, falling size below the node; size about how big it is, in world units. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function rain(size:Float):Particles3D
		return new Particles3D(helix.particle.ParticlePreset.Rain.make(size, -1, false));

	/** A preset (helix.particle.ParticlePreset.Snow): steady snow over a width of size, drifting down size below the node; size about how big it is, in world units. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function snow(size:Float):Particles3D
		return new Particles3D(helix.particle.ParticlePreset.Snow.make(size, -1, false));

	/** A preset (helix.particle.ParticlePreset.Confetti): paper of five colors thrown up, spinning and falling: a win, a level cleared. One-shot, off its parent once spent (removeWhenSpent); size about how big it is, in world units. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function confetti(size:Float):Particles3D
		return oneShot(helix.particle.ParticlePreset.Confetti.make(size, -1, false));
}
