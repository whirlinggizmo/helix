package helix.render2d;

import helix.particle.Emitter;

/** An emitter of particles (helix.particle.Emitter, made flat for 2D), placed here: it spawns where this node is in the world, and the stage
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

	// The clock it was last advanced at: a tree several views show advances it once a frame.
	var advancedAt = Math.NaN;

	// Moved on by dt where it is (none while frozen), once a frame however many views show its tree; drawn when shown. Not culled: particles
	// reach past where it is.
	override function drawOwn(batch:Batch2D, camera:Camera2D, time:Float, dt:Float, frozen:Bool, shown:Bool):Bool {
		if (advancedAt != time) {
			advancedAt = time;
			emitter.advance(frozen ? 0 : dt, wx, wy, 0);
			removeIfSpent();
		}
		if (shown) {
			batch.resetTransform();
			batch.emitter(emitter);
		}
		return true;
	}

	// A one-shot preset's node: off its parent once spent.
	static function oneShot(emitter:Emitter):Particles2D {
		var node = new Particles2D(emitter);
		node.removeWhenSpent = true;
		return node;
	}

	/** A preset (helix.particle.ParticlePreset.Explosion): a burst of light outward, fading from white-yellow to red: a hit, a pop, a small explosion. One-shot, off its parent once spent (removeWhenSpent); size about how big it is, in pixels on the stage, or the units of the 2D tree it's in. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function explosion(size:Float):Particles2D
		return oneShot(helix.particle.ParticlePreset.Explosion.make(size, 1, true));

	/** A preset (helix.particle.ParticlePreset.SmokePuff): a soft gray puff, spreading and rising a little as it fades: a landing, a vanish. One-shot, off its parent once spent (removeWhenSpent); size about how big it is, in pixels on the stage, or the units of the 2D tree it's in. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function smokePuff(size:Float):Particles2D
		return oneShot(helix.particle.ParticlePreset.SmokePuff.make(size, 1, true));

	/** A preset (helix.particle.ParticlePreset.Sparks): hot sparks thrown up and out, streaked and falling: a hit on metal. One-shot, off its parent once spent (removeWhenSpent); size about how big it is, in pixels on the stage, or the units of the 2D tree it's in. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function sparks(size:Float):Particles2D
		return oneShot(helix.particle.ParticlePreset.Sparks.make(size, 1, true));

	/** A preset (helix.particle.ParticlePreset.Dust): a low, wide kick of dust that settles: footsteps, a landing, a skid. One-shot, off its parent once spent (removeWhenSpent); size about how big it is, in pixels on the stage, or the units of the 2D tree it's in. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function dust(size:Float):Particles2D
		return oneShot(helix.particle.ParticlePreset.Dust.make(size, 1, true));

	/** A preset (helix.particle.ParticlePreset.Fire): a steady flame, rising and fading from yellow to red: a torch, a campfire; size about how big it is, in pixels on the stage, or the units of the 2D tree it's in. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function fire(size:Float):Particles2D
		return new Particles2D(helix.particle.ParticlePreset.Fire.make(size, 1, true));

	/** A preset (helix.particle.ParticlePreset.Smoke): a steady column of gray smoke, rising and spreading: a chimney, a wreck; size about how big it is, in pixels on the stage, or the units of the 2D tree it's in. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function smoke(size:Float):Particles2D
		return new Particles2D(helix.particle.ParticlePreset.Smoke.make(size, 1, true));

	/** A preset (helix.particle.ParticlePreset.Rain): steady rain over a width of size, falling size below the node; size about how big it is, in pixels on the stage, or the units of the 2D tree it's in. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function rain(size:Float):Particles2D
		return new Particles2D(helix.particle.ParticlePreset.Rain.make(size, 1, true));

	/** A preset (helix.particle.ParticlePreset.Snow): steady snow over a width of size, drifting down size below the node; size about how big it is, in pixels on the stage, or the units of the 2D tree it's in. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function snow(size:Float):Particles2D
		return new Particles2D(helix.particle.ParticlePreset.Snow.make(size, 1, true));

	/** A preset (helix.particle.ParticlePreset.Confetti): paper of five colors thrown up, spinning and falling: a win, a level cleared. One-shot, off its parent once spent (removeWhenSpent); size about how big it is, in pixels on the stage, or the units of the 2D tree it's in. Drawn with the built-in dot
		(Emitter.getDot); its emitter is an ordinary one, to change what doesn't fit. */
	public static function confetti(size:Float):Particles2D
		return oneShot(helix.particle.ParticlePreset.Confetti.make(size, 1, true));
}
