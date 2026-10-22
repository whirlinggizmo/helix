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

	override function get_spriteKind():Node3D.SpriteKind3D
		return Node3D.SpriteKind3D.Emitter;

	override function attachSprites(renderer:Renderer3D):Void
		Sprites3D.attach(renderer);

	override function visitSprites(sprites:Any, planes:haxe.ds.Vector<Float>, eyeX:Float, eyeY:Float, eyeZ:Float, forwardX:Float, forwardY:Float,
			forwardZ:Float, still:Bool):Void
		(sprites : Sprites3D).visitEmitter(this, eyeX, eyeY, eyeZ, forwardX, forwardY, forwardZ, still);

	override function advanceSprites(sprites:Any):Void
		(sprites : Sprites3D).advanceEmitter(this);

	/** A preset (helix.particle.ParticlePreset.Explosion): a burst of light outward, fading from white-yellow to red: a hit, a pop, a small explosion. One-shot; size about how big it is, in world units. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function explosion(size:Float):Particles3D
		return new Particles3D(helix.particle.ParticlePreset.Explosion.make(size, -1, false));

	/** A preset (helix.particle.ParticlePreset.SmokePuff): a soft gray puff, spreading and rising a little as it fades: a landing, a vanish. One-shot; size about how big it is, in world units. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function smokePuff(size:Float):Particles3D
		return new Particles3D(helix.particle.ParticlePreset.SmokePuff.make(size, -1, false));

	/** A preset (helix.particle.ParticlePreset.Sparks): hot sparks thrown up and out, streaked and falling: a hit on metal. One-shot; size about how big it is, in world units. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function sparks(size:Float):Particles3D
		return new Particles3D(helix.particle.ParticlePreset.Sparks.make(size, -1, false));

	/** A preset (helix.particle.ParticlePreset.Dust): a low, wide kick of dust that settles: footsteps, a landing, a skid. One-shot; size about how big it is, in world units. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function dust(size:Float):Particles3D
		return new Particles3D(helix.particle.ParticlePreset.Dust.make(size, -1, false));

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

	/** A preset (helix.particle.ParticlePreset.Confetti): paper of five colors thrown up, spinning and falling: a win, a level cleared. One-shot; size about how big it is, in world units. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function confetti(size:Float):Particles3D
		return new Particles3D(helix.particle.ParticlePreset.Confetti.make(size, -1, false));
}
