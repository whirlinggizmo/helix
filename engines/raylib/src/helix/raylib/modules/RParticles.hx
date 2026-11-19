package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.extras.Emitter2D;
import helix.raylib.extras.Emitter3D;
import helix.raylib.internal.EmitterDraws;
import helix.raylib.internal.Emitters;
#end

/** Holds helix-raylib's particle emitters, in 3D and in 2D. Each is written here, and `helix.raylib.extras.Particles` forwards to each
	(`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
@:access(helix.raylib.extras.Emitter)
class RParticles {
	#if !macro
	/** Returns a 3D emitter of at most `maxParticles` alive at once, at the origin, every field at its default. A particle born past the
		most alive replaces the oldest one.

		A `maxParticles` over 524288 is held to 524288.

		@param maxParticles  The most alive at once, 1 or more.
		@return  The emitter, the program's until `UnloadEmitter3D`. */
	static function LoadEmitter3D(maxParticles:Int):Emitter3D {
		var e = @:privateAccess new Emitter3D(maxParticles);
		e.seed = @:privateAccess RCore.random.nextBits();
		return e;
	}

	/** Frees a 3D emitter and its particles.

		@param emitter  The emitter. */
	static function UnloadEmitter3D(emitter:Emitter3D):Void {
		Emitters.clear(emitter);
		EmitterDraws.release(emitter);
	}

	/** Advances a 3D emitter by the frame's time. The particles its rate owes are born along the way from where it was to its `position`,
		so a fast emitter leaves an even trail. Call it once a frame, before `DrawEmitter3D`. An emitter not updated holds still.

		@param emitter  The emitter.
		@param deltaTime  The seconds since its last update, as `GetFrameTime` returns them. */
	static function UpdateEmitter3D(emitter:Emitter3D, deltaTime:Float):Void {
		var p = emitter.position;
		Emitters.update(emitter, deltaTime, p.x, p.y, p.z, false);
	}

	/** Draws a 3D emitter's particles through the current camera, as `DrawCube` draws: inside `BeginMode3D`, in world units facing the
		camera, hidden by what's drawn before them but not hiding what's drawn after. Outside it, through the screen's, a unit a pixel.

		@param emitter  The emitter. */
	static function DrawEmitter3D(emitter:Emitter3D):Void {
		EmitterDraws.draw(emitter);
	}

	/** Emits particles at once at a 3D emitter's position, whatever its rate: a burst.

		@param emitter  The emitter.
		@param count  How many. */
	static function EmitParticles3D(emitter:Emitter3D, count:Int):Void {
		var p = emitter.position;
		Emitters.emit(emitter, count, p.x, p.y, p.z, false);
	}

	/** Runs a 3D emitter ahead in time without drawing, so a fire is already going when first seen.

		@param emitter  The emitter.
		@param seconds  How far ahead. */
	static function PrewarmEmitter3D(emitter:Emitter3D, seconds:Float):Void {
		var p = emitter.position;
		Emitters.prewarm(emitter, seconds, p.x, p.y, p.z, false);
	}

	/** Removes every particle alive, and starts the emitter's random numbers again from its `seed`.

		@param emitter  The emitter. */
	static function ClearEmitter3D(emitter:Emitter3D):Void {
		Emitters.clear(emitter);
	}

	/** Returns a 2D emitter of at most `maxParticles` alive at once, at the origin, every field at its default. A particle born past the
		most alive replaces the oldest one.

		@param maxParticles  The most alive at once, 1 or more.
		@return  The emitter, the program's until `UnloadEmitter2D`. */
	static function LoadEmitter2D(maxParticles:Int):Emitter2D {
		helix.raylib.internal.Sprites.register();
		var e = @:privateAccess new Emitter2D(maxParticles);
		e.seed = @:privateAccess RCore.random.nextBits();
		return e;
	}

	/** Frees a 2D emitter and its particles.

		@param emitter  The emitter. */
	static function UnloadEmitter2D(emitter:Emitter2D):Void {
		Emitters.clear(emitter);
	}

	/** Advances a 2D emitter by the frame's time, moving each particle. The particles its rate owes are born along the way from where it
		was to its `position`. Call it once a frame, before `DrawEmitter2D`. An emitter not updated holds still.

		@param emitter  The emitter.
		@param deltaTime  The seconds since its last update, as `GetFrameTime` returns them. */
	static function UpdateEmitter2D(emitter:Emitter2D, deltaTime:Float):Void {
		var p = emitter.position;
		Emitters.update(emitter, deltaTime, p.x, p.y, 0, true);
	}

	/** Draws a 2D emitter's particles into the batch through the current camera, as `DrawTexture` draws: in screen pixels, or through
		`BeginMode2D`'s camera. Inside `BeginMode3D`, flat in the world's XY plane, a pixel a unit.

		@param emitter  The emitter. */
	static function DrawEmitter2D(emitter:Emitter2D):Void {
		Emitters.draw2D(emitter);
	}

	/** Emits particles at once at a 2D emitter's position, whatever its rate: a burst.

		@param emitter  The emitter.
		@param count  How many. */
	static function EmitParticles2D(emitter:Emitter2D, count:Int):Void {
		var p = emitter.position;
		Emitters.emit(emitter, count, p.x, p.y, 0, true);
	}

	/** Runs a 2D emitter ahead in time without drawing.

		@param emitter  The emitter.
		@param seconds  How far ahead. */
	static function PrewarmEmitter2D(emitter:Emitter2D, seconds:Float):Void {
		var p = emitter.position;
		Emitters.prewarm(emitter, seconds, p.x, p.y, 0, true);
	}

	/** Removes every particle alive, and starts the emitter's random numbers again from its `seed`.

		@param emitter  The emitter. */
	static function ClearEmitter2D(emitter:Emitter2D):Void {
		Emitters.clear(emitter);
	}
	#end
}
