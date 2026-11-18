package helix.raylib.internal;

import haxe.io.Bytes;
import helix.math.Matrix4;
import helix.platform.VertexBuffer;
import helix.raylib.extras.Emitter3D;
import helix.services.shaders.ShaderUniform;

/** Draws the Particles extra's 3D emitters on the GPU: each emitter's births as a data texture of records, six texels a particle (where
	and when it was born, its velocity and life, its size scale, spin, random number and phase, its tint, its offset from the emitter
	and its orbit, the axis it orbits), written when particles are born, and
	one instanced draw of a quad an emitter (`Frame.quads`) through the particle shader, which works each particle out from its age.

	The unlit and lit programs are made by the first draw of each. Linked by `DrawEmitter3D` alone. */
@:noCompletion
@:access(helix.raylib.extras.Emitter)
@:access(helix.raylib.extras.Emitter3D)
class EmitterDraws {
	/** The particles a row of the records' texture holds, and its width in texels. */
	static inline final ROW = 256;

	static inline final WIDTH = ROW * 6;

	/** How far a 3D emitter's clock runs from the time its records count from before they count from a later one, in seconds, so a
		record's 32-bit birth time stays fine. */
	static inline final REBASE = 1024.;

	static var unlit:Null<Program>;
	static var lit:Null<Program>;
	// The uniforms of each program, by the order of NAMES.
	static var unlitFields:Array<ShaderUniform>;
	static var litFields:Array<ShaderUniform>;
	static var unlitLayout:Array<VertexBuffer>;
	static var litLayout:Array<VertexBuffer>;
	static var programsGraphics:Null<helix.platform.IGraphics>;
	// The lit program's ambient, which each lit draw writes from its emitter's.
	static var litAmbient:Null<ShaderUniform>;

	static final NAMES = [
		"particleRight",
		"particleUp",
		"particleClock",
		"particleGravity",
		"particleFrames",
		"particleSource",
		"particleCounts",
		"particleSizes",
		"particleColorTimes",
		"particleColors",
		"particleEmitter"
	];

	// What a draw reads and writes, kept so a draw allocates nothing.
	static final identity = new Matrix4();
	static final white:Array<Float> = [1, 1, 1, 1];
	static final textures:Array<Int> = [];
	static final part:Array<Float> = [0, 0, 0, 0];
	static final bounds = Bytes.alloc(24);

	/** Draws a 3D emitter's particles through the current matrices and state, facing the camera, depth tested as the state says and
		written by none, in its blend mode.

		@param e  The emitter. */
	public static function draw(e:Emitter3D):Void {
		if (e.span == 0)
			return;
		var texture = Emitters.textureOf(e);
		if (texture.id == 0 || texture.width == 0 || texture.height == 0)
			return;
		var frame = Runtime.frame, graphics = Runtime.graphics;
		if (programsGraphics != graphics) {
			programsGraphics = graphics;
			unlit = lit = null;
		}
		var p:Program, fields:Array<ShaderUniform>, layout:Array<VertexBuffer>;
		if (e.lit) {
			if (lit == null) {
				lit = new Program(graphics, Defaults.particleLitShader());
				litFields = fieldsOf(lit);
				litLayout = layoutOf(lit);
				// Shadows fall on the lit particles, the empty shadow map bound until a light casts them.
				var shadowed = lit.shader.findUniform("shadowed");
				if (shadowed != null)
					lit.values.writeInt(shadowed, 1);
				ShadowSlots.bind(lit, 0);
				litAmbient = lit.shader.findUniform("ambient");
			}
			p = lit;
			fields = litFields;
			layout = litLayout;
		} else {
			if (unlit == null) {
				unlit = new Program(graphics, Defaults.particleShader());
				unlitFields = fieldsOf(unlit);
				unlitLayout = layoutOf(unlit);
			}
			p = unlit;
			fields = unlitFields;
			layout = unlitLayout;
		}
		upload(e, graphics);
		writeUniforms(e, p, fields, frame, texture);
		var bound = p.bindTextures(textures);
		if (p.texture0 >= 0)
			bound[p.texture0] = Textures.handle(texture.id);
		var records = p.shader.findSampler("particleRecords");
		if (records != null)
			bound[records.slot] = e.records;
		if (e.lit) {
			var c = e.ambient;
			if (litAmbient != null)
				p.values.writeVector(litAmbient, c.r / 255, c.g / 255, c.b / 255, 1);
			if (Frame.lighting != null)
				light(e, p);
		}
		var mode = frame.blendMode;
		if (e.blendMode != mode)
			@:privateAccess helix.raylib.modules.RCore.BeginBlendMode(e.blendMode);
		var depthMask = frame.depthMask, cull = frame.cull;
		frame.depthMask = false;
		frame.cull = false;
		e.drawBuffers[1] = e.numbers;
		frame.quads(p, layout, e.drawBuffers, e.span, bound, identity, white);
		frame.depthMask = depthMask;
		frame.cull = cull;
		if (e.blendMode != mode)
			@:privateAccess helix.raylib.modules.RCore.BeginBlendMode(mode);
	}

	/** Frees a 3D emitter's records and numbers on the GPU, once the frame's draws asked for are drawn.

		@param e  The emitter. */
	public static function release(e:Emitter3D):Void {
		if (e.gpu != null && e.gpu == Runtime.graphics) {
			var records = e.records, numbers = e.numbers, graphics = e.gpu;
			Runtime.frame.retire(numbers);
			Runtime.frame.afterDraw(() -> graphics.disposeTexture(records));
		}
		e.gpu = null;
		e.records = e.numbers = 0;
		e.recordBytes = null;
	}

	// A program's uniforms, by NAMES.
	static function fieldsOf(p:Program):Array<ShaderUniform>
		return [for (name in NAMES) p.shader.getUniform(name)];

	// A program's buffers: the quad's corner numbers, then the instances' numbers.
	static function layoutOf(p:Program):Array<VertexBuffer> {
		var corner = p.attributes.indexOf("spriteCorner"),
			number = p.attributes.indexOf("particleIndex");
		return [
			{stride: 4, instanced: false, attributes: [{slot: corner, format: Float1, offset: 0}]},
			{stride: 4, instanced: true, attributes: [{slot: number, format: Float1, offset: 0}]}
		];
	}

	// The emitter's records on the GPU, made for the graphics drawing it, and the births since they were last written written there.
	static function upload(e:Emitter3D, graphics:helix.platform.IGraphics):Void {
		var n = e.capacity;
		if (e.gpu != graphics) {
			e.gpu = graphics;
			var rows = Std.int((n + ROW - 1) / ROW);
			e.recordBytes = Bytes.alloc(WIDTH * rows * 16);
			e.recordBytes.fill(0, e.recordBytes.length, 0);
			e.records = graphics.createDataTexture(WIDTH, rows);
			var numbers = Bytes.alloc(n * 4);
			for (i in 0...n)
				numbers.setFloat(i * 4, i);
			e.numbers = graphics.createStaticBuffer(numbers, n * 4, false);
			e.fresh = n;
		}
		if (e.clock - e.epoch > REBASE) {
			e.epoch = Math.ffloor(e.clock);
			e.fresh = n;
		}
		if (e.fresh == 0)
			return;
		var count = e.fresh < e.span ? e.fresh : e.span;
		var s = e.slots, bytes = e.recordBytes;
		for (k in 0...count) {
			var slot = (e.head - count + k + n) % n,
				at = slot * Emitters.SLOT,
				to = ((slot % ROW) * 6 + Std.int(slot / ROW) * WIDTH) * 16;
			bytes.setFloat(to, s[at + Emitters.X]);
			bytes.setFloat(to + 4, s[at + Emitters.Y]);
			bytes.setFloat(to + 8, s[at + Emitters.Z]);
			bytes.setFloat(to + 12, s[at + Emitters.BORN] - e.epoch);
			bytes.setFloat(to + 16, s[at + Emitters.VX]);
			bytes.setFloat(to + 20, s[at + Emitters.VY]);
			bytes.setFloat(to + 24, s[at + Emitters.VZ]);
			bytes.setFloat(to + 28, s[at + Emitters.LIFE]);
			bytes.setFloat(to + 32, s[at + Emitters.SCALE]);
			bytes.setFloat(to + 36, s[at + Emitters.SPIN]);
			bytes.setFloat(to + 40, s[at + Emitters.RANDOM]);
			bytes.setFloat(to + 44, s[at + Emitters.PHASE]);
			var tint = e.tints[slot];
			bytes.setFloat(to + 48, (tint & 255) / 255);
			bytes.setFloat(to + 52, ((tint >>> 8) & 255) / 255);
			bytes.setFloat(to + 56, ((tint >>> 16) & 255) / 255);
			bytes.setFloat(to + 60, (tint >>> 24) / 255);
			bytes.setFloat(to + 64, s[at + Emitters.CX]);
			bytes.setFloat(to + 68, s[at + Emitters.CY]);
			bytes.setFloat(to + 72, s[at + Emitters.CZ]);
			bytes.setFloat(to + 76, s[at + Emitters.ORBIT]);
			bytes.setFloat(to + 80, s[at + Emitters.AX]);
			bytes.setFloat(to + 84, s[at + Emitters.AY]);
			bytes.setFloat(to + 88, s[at + Emitters.AZ]);
			bytes.setFloat(to + 92, 0);
		}
		e.fresh = 0;
		graphics.updateTexture(e.records, 0, 0, WIDTH, Std.int((n + ROW - 1) / ROW), bytes);
	}

	// The draw's uniforms: the camera's axes, the emitter's clock and its fields over a particle's life.
	static function writeUniforms(e:Emitter3D, p:Program, f:Array<ShaderUniform>, frame:Frame, texture:helix.raylib.Texture2D):Void {
		var values = p.values, n = e.capacity;
		// The camera's right and up in the world: the view's first two rows, up turned over where the projection turns y over (the
		// screen's, a pixel a unit).
		var v = frame.view, flip = frame.projection.m5 < 0 ? -1. : 1.;
		var rx = v.m0, ry = v.m4, rz = v.m8, ux = v.m1 * flip, uy = v.m5 * flip, uz = v.m9 * flip;
		var rl = Math.sqrt(rx * rx + ry * ry + rz * rz),
			ul = Math.sqrt(ux * ux + uy * uy + uz * uz);
		if (rl == 0)
			rl = 1;
		if (ul == 0)
			ul = 1;
		values.writeVector(f[0], rx / rl, ry / rl, rz / rl, (e.head - e.span + n) % n);
		values.writeVector(f[1], ux / ul, uy / ul, uz / ul, n);
		values.writeVector(f[2], e.clock - e.epoch, e.drag > 0 ? e.drag : 0, e.stretch > 0 ? e.stretch : 0, e.wanderDistance > 0 ? e.wanderDistance : 0);
		values.writeVector(f[3], e.gravity.x, e.gravity.y, e.gravity.z, e.wanderRate);
		var columns = e.frameColumns > 1 ? e.frameColumns : 1,
			rows = e.frameRows > 1 ? e.frameRows : 1;
		values.writeVector(f[4], columns, rows, Emitters.framesOf(e), e.framesPerSecond > 0 ? e.framesPerSecond : 0);
		Emitters.sourceOf(e, texture, part);
		values.writeVector(f[5], part[0] / texture.width, part[1] / texture.height, (part[0] + part[2]) / texture.width, (part[1] + part[3]) / texture.height);
		Emitters.readCurves(e, false);
		values.writeVector(f[10], e.position.x, e.position.y, e.position.z, e.localSpace ? 1 : 0);
		values.writeVector(f[6], Emitters.sizeCount, Emitters.colorCount, e.pulseRate > 0 ? e.pulseRate : 0,
			e.pulseDepth > 0 ? (e.pulseDepth < 1 ? e.pulseDepth : 1) : 0);
		for (i in 0...Emitters.sizeCount)
			values.writeVector(f[7], Emitters.sizeTimes[i], Emitters.sizeValues[i], 0, 0, i);
		for (i in 0...Emitters.colorCount) {
			var c = Emitters.colorValues[i];
			values.writeVector(f[8], Emitters.colorTimes[i], 0, 0, 0, i);
			values.writeVector(f[9], (c & 255) / 255, ((c >>> 8) & 255) / 255, ((c >>> 16) & 255) / 255, (c >>> 24) / 255, i);
		}
	}

	// Lights a lit emitter's draw by the scene's lights reaching its particles most (`Frame.lighting`): their bounds the births', grown by
	// the farthest a particle goes in its life.
	static function light(e:Emitter3D, p:Program):Void {
		var s = e.slots, n = e.capacity;
		var lowX = Math.POSITIVE_INFINITY, lowY = lowX, lowZ = lowX, highX = Math.NEGATIVE_INFINITY, highY = highX, highZ = highX;
		for (k in 0...e.span) {
			var at = ((e.head - e.span + k + n) % n) * Emitters.SLOT;
			var x = s[at + Emitters.X],
				y = s[at + Emitters.Y],
				z = s[at + Emitters.Z];
			if (x < lowX)
				lowX = x;
			if (y < lowY)
				lowY = y;
			if (z < lowZ)
				lowZ = z;
			if (x > highX)
				highX = x;
			if (y > highY)
				highY = y;
			if (z > highZ)
				highZ = z;
		}
		var life = e.maxLife > e.minLife ? e.maxLife : e.minLife;
		if (!(life > 0))
			life = 0;
		var g = e.gravity, size = 0.;
		for (k in 0...Emitters.sizeCount)
			size = Math.max(size, Math.abs(Emitters.sizeValues[k]));
		var speed = (e.speed > 0 ? e.speed : 0) * 2 + Math.sqrt(e.moveX * e.moveX + e.moveY * e.moveY + e.moveZ * e.moveZ);
		var h = e.spawnHalfSize,
			orbit = 2 * Math.max(Math.abs(h.x), Math.max(Math.abs(h.y), Math.abs(h.z)));
		var reach = orbit
			+ speed * life
			+ Math.sqrt(g.x * g.x + g.y * g.y + g.z * g.z) * life * life / 2
			+ Math.abs(e.wanderDistance)
			+ size;
		bounds.setFloat(0, lowX - reach);
		bounds.setFloat(4, lowY - reach);
		bounds.setFloat(8, lowZ - reach);
		bounds.setFloat(12, highX + reach);
		bounds.setFloat(16, highY + reach);
		bounds.setFloat(20, highZ + reach);
		Frame.lighting(p, bounds, 0, 2, 12);
	}
}
