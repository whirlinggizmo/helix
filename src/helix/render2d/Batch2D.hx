package helix.render2d;

import helix.graphics.IGraphics;
import helix.graphics.BlendMode;
import helix.graphics.Pipelines;
import helix.graphics.Sampling;
import helix.render3d.Node.SpriteAlpha;
import haxe.io.Bytes;

/** Immediate 2D drawing in world units through a Camera2D, inside a frame (IGraphics.beginFrame to endFrame). A batch is one upload and one draw per
	run of a texture and camera, drawn over whatever the frame has so far, without depth. Colors are 0xRRGGBBAA. A transform (setTransform) places
	what follows, so a shape or text can be drawn turned and scaled; a Stage2D draws its nodes so. */
class Batch2D {
	var vertices = 0;
	var draws = 0;
	var font:Font2D;

	/** Vertices of the frame drawn last. */
	public function getVertexCount():Int
		return vertices;

	/** Draws of the frame drawn last: one per run of a texture. */
	public function getDrawCount():Int
		return draws;

	/** The built-in pixel font, whose texture also has the white texel shapes use. */
	public function getFont():Font2D
		return font;

	var gpu:IGraphics;
	var capacity:Int;
	var data:Bytes;
	var buffer:Int;
	var pipelines:Pipelines;
	// Block 0 of the sprite program, its clip scale, which the adapter writes.
	var clip = Bytes.alloc(16);
	var camera:Camera2D;
	var texture:Texture2D;
	var runStart = 0;
	var runs:Array<Int> = [];
	var runCameras:Array<Camera2D> = [];
	var runSamplings:Array<Sampling> = [];
	// By run: its clip in framebuffer pixels from the top-left (x, y, w, h), w -1 for none.
	var runClips:Array<Int> = [];
	// The clips pushed, each within the one before (x, y, w, h each); the current one last.
	var clips:Array<Int> = [];
	// By run: the emitter it draws (its first record and count in the batch's particle upload, its uniforms), or null for a run of quads.
	var runEmitters:Array<Null<{
		emitter:helix.particles.Emitter,
		first:Int,
		count:Int,
		uniforms:Bytes
	}>> = [];
	// Particles, made when first drawn: their quad, and the frame's records in one upload.
	var particlesReady = false;
	var particleCorners = 0;
	var particleIndices = 0;
	var particleBuffer = 0;
	var particleCapacity = 0;
	var particleRecords:Bytes = Bytes.alloc(0);
	var particleCount = 0;
	var sampling:Sampling = Sampling.NEAREST;
	var ta = 1.;
	var tb = 0.;
	var tc = 0.;
	var td = 1.;
	var tx = 0.;
	var ty = 0.;
	var r = 1.;
	var g = 1.;
	var b = 1.;
	var a = 1.;

	/** A batch of up to capacity vertices a frame, with its own buffer, pipeline and pixel font on gpu; cleanup frees them. */
	public function new(gpu:IGraphics, capacity = 32768) {
		this.gpu = gpu;
		this.capacity = capacity;
		data = Bytes.alloc(capacity * Sprite2DLayout.stride);
		buffer = gpu.createBuffer(capacity * Sprite2DLayout.stride);
		pipelines = Pipelines.of(gpu);
		font = Font2D.builtIn(gpu);
		texture = font.getTexture();
	}

	/** Starts collecting a batch seen through camera, with no transform; later calls only fill it until end. */
	public function begin(camera:Camera2D):Void {
		this.camera = camera;
		vertices = 0;
		draws = 0;
		runStart = 0;
		runs = [];
		runCameras = [];
		runSamplings = [];
		runEmitters = [];
		runClips = [];
		clips = [];
		particleCount = 0;
		texture = font.getTexture();
		sampling = texture.getSampling();
		resetTransform();
	}

	/** The camera the batch is seen through. */
	public function getCamera():Camera2D
		return camera;

	/** What follows is seen through camera, in its viewport: a world and a HUD in one batch. */
	public function setCamera(value:Camera2D):Void
		if (value != camera) {
			closeRun();
			camera = value;
		}

	/** Places what follows: a point x, y it is given is drawn at a * x + c * y + tx, b * x + d * y + ty in world units. */
	public function setTransform(a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float):Void {
		ta = a;
		tb = b;
		tc = c;
		td = d;
		this.tx = tx;
		this.ty = ty;
	}

	/** What follows is drawn where it is given, in world units. */
	public function resetTransform():Void
		setTransform(1, 0, 0, 1, 0, 0);

	/** Draws the batch in the open frame: one upload of every vertex and one draw per run of a texture and camera, each in its camera's viewport.
		Once a frame. */
	public function end():Void {
		closeRun();
		gpu.updateBuffer(buffer, data, vertices * Sprite2DLayout.stride);
		if (particleCount > 0) {
			if (particleCount > particleCapacity) {
				if (particleBuffer != 0)
					gpu.destroyBuffer(particleBuffer);
				particleCapacity = 1024;
				while (particleCapacity < particleCount)
					particleCapacity *= 2;
				particleBuffer = gpu.createBuffer(particleCapacity * Particle3DLayout.instanceStride);
			}
			gpu.updateBuffer(particleBuffer, particleRecords, particleCount * Particle3DLayout.instanceStride);
		}
		var i = 0, viewport:Camera2D = null, clipped = false, cx = 0, cy = 0, cw = 0, ch = 0;
		while (i < runs.length) {
			var run = Std.int(i / 3), c = runCameras[run];
			if (c != viewport) {
				viewport = c;
				gpu.setViewport(c.getViewportX(), c.getFramebufferHeight() - c.getViewportY() - c.getViewportHeight(), c.getViewportWidth(),
					c.getViewportHeight());
			}
			// The run's clip, set when it changes (from the top-left here, the bottom-left for the GPU).
			var at = run * 4, w = runClips[at + 2];
			if (w < 0 && clipped) {
				gpu.resetScissor();
				clipped = false;
			} else if (w >= 0 && (!clipped || runClips[at] != cx || runClips[at + 1] != cy || w != cw || runClips[at + 3] != ch)) {
				cx = runClips[at];
				cy = runClips[at + 1];
				cw = w;
				ch = runClips[at + 3];
				gpu.setScissor(cx, c.getFramebufferHeight() - cy - ch, cw, ch);
				clipped = true;
			}
			var e = runEmitters[run];
			if (e != null) {
				var phase = switch e.emitter.getAlphaMode() {
					case Blend: 1;
					case Add: 2;
					case _: 0;
				};
				gpu.draw(pipelines.particle3d(cast phase), [particleCorners, particleBuffer], particleIndices, 0, 6, e.first, e.count, [runs[i]],
					[runSamplings[run]], [e.uniforms]);
			} else
				gpu.draw(pipelines.sprite2d(Alpha), [buffer], 0, runs[i + 1], runs[i + 2], 0, 1, [runs[i]], [runSamplings[run]], [clip]);
			draws++;
			i += 3;
		}
		if (clipped)
			gpu.resetScissor();
	}

	/** Clips what follows to the rectangle x, y, w, h of the world units it would be drawn in now (through the transform and the camera; a
		turned one's bounds), within any clip already pushed, until popClip. */
	public function pushClip(x:Float, y:Float, w:Float, h:Float):Void {
		closeRun();
		var lx = Math.POSITIVE_INFINITY,
			ly = Math.POSITIVE_INFINITY,
			hx = Math.NEGATIVE_INFINITY,
			hy = Math.NEGATIVE_INFINITY;
		for (k in 0...4) {
			var px = k & 1 == 0 ? x : x + w, py = k & 2 == 0 ? y : y + h;
			var sx = camera.worldToScreenX(ta * px + tc * py + tx),
				sy = camera.worldToScreenY(tb * px + td * py + ty);
			lx = Math.min(lx, sx);
			ly = Math.min(ly, sy);
			hx = Math.max(hx, sx);
			hy = Math.max(hy, sy);
		}
		var left = Math.round(lx),
			top = Math.round(ly),
			right = Math.round(hx),
			bottom = Math.round(hy);
		var n = clips.length;
		if (n > 0) {
			left = Std.int(Math.max(left, clips[n - 4]));
			top = Std.int(Math.max(top, clips[n - 3]));
			right = Std.int(Math.min(right, clips[n - 4] + clips[n - 2]));
			bottom = Std.int(Math.min(bottom, clips[n - 3] + clips[n - 1]));
		}
		clips.push(left);
		clips.push(top);
		clips.push(Std.int(Math.max(0, right - left)));
		clips.push(Std.int(Math.max(0, bottom - top)));
	}

	/** Ends the clip pushClip began; what follows is clipped as before it. Nothing with no clip pushed. */
	public function popClip():Void {
		if (clips.length == 0)
			return;
		closeRun();
		clips.resize(clips.length - 4);
	}

	function pushRunClip():Void {
		var n = clips.length;
		for (k in 0...4)
			runClips.push(n == 0 ? (k == 2 ? -1 : 0) : clips[n - 4 + k]);
	}

	/** Later quads sample this texture, as its sampling is now (Texture2D.setSampling). */
	public function useTexture(value:Texture2D):Void
		if (value != texture || value.getSampling() != sampling) {
			closeRun();
			texture = value;
			sampling = value.getSampling();
		}

	function closeRun():Void {
		if (vertices > runStart) {
			runs.push(texture.getHandle());
			runs.push(runStart);
			runs.push(vertices - runStart);
			runCameras.push(camera);
			runSamplings.push(sampling);
			runEmitters.push(null);
			pushRunClip();
		}
		runStart = vertices;
	}

	inline function color(value:Int):Void {
		r = (value >>> 24) / 255;
		g = ((value >>> 16) & 255) / 255;
		b = ((value >>> 8) & 255) / 255;
		a = (value & 255) / 255;
	}

	inline function vertex(x:Float, y:Float, u:Float, v:Float):Void {
		if (vertices >= capacity)
			throw "Batch2D capacity exceeded";
		var p = vertices++ * Sprite2DLayout.stride,
			position = p + Sprite2DLayout.positionOffset,
			uv = p + Sprite2DLayout.uvOffset,
			c = p + Sprite2DLayout.colorOffset;
		data.setFloat(position, camera.clipX(ta * x + tc * y + tx));
		data.setFloat(position + 4, camera.clipY(tb * x + td * y + ty));
		data.setFloat(uv, u);
		data.setFloat(uv + 4, v);
		data.setFloat(c, r);
		data.setFloat(c + 4, g);
		data.setFloat(c + 8, b);
		data.setFloat(c + 12, a);
	}

	/** Untextured shapes need a white texel; switch back to the font's texture when the current one has none. */
	inline function solid():Void
		if (texture.getWhiteU() < 0)
			useTexture(font.getTexture());

	/** A textured rectangle in world units, top-left at x, y, sampling u0, v0 to u1, v1 of the current texture, tinted. With distanceField, the texture's alpha is
		a distance from an outline (Font2D.isDistanceField), drawn with a smooth edge at any scale. Throws when the frame's vertices pass capacity, as every shape does. */
	public function quad(x:Float, y:Float, w:Float, h:Float, u0:Float, v0:Float, u1:Float, v1:Float, tint:Int, distanceField = false):Void {
		color(tint);
		// The 2D shader reads an alpha over 1 as "the texture's alpha is a distance field", tinted by the alpha less 2.
		if (distanceField)
			a += 2;
		vertex(x, y, u0, v0);
		vertex(x + w, y, u1, v0);
		vertex(x + w, y + h, u1, v1);
		vertex(x, y, u0, v0);
		vertex(x + w, y + h, u1, v1);
		vertex(x, y + h, u0, v1);
	}

	/** texture drawn centered on x, y, width x height in world units, turned rotation radians (clockwise on screen), sampling u0, v0 to u1, v1 of it
		(the whole texture by default), tinted (0xRRGGBBAA, white by default). Throws when the frame's vertices pass capacity. */
	public function sprite(texture:Texture2D, x:Float, y:Float, width:Float, height:Float, rotation = 0., tint = 0xffffffff, u0 = 0., v0 = 0., u1 = 1.,
			v1 = 1.):Void {
		useTexture(texture);
		color(tint);
		var c = Math.cos(rotation),
			s = Math.sin(rotation),
			hw = width / 2,
			hh = height / 2;
		// The corners from the center, turned: top-left, top-right, bottom-right, bottom-left.
		var ax = x + -hw * c - -hh * s, ay = y + -hw * s + -hh * c;
		var bx = x + hw * c - -hh * s, by = y + hw * s + -hh * c;
		var cx = x + hw * c - hh * s, cy = y + hw * s + hh * c;
		var dx = x + -hw * c - hh * s, dy = y + -hw * s + hh * c;
		vertex(ax, ay, u0, v0);
		vertex(bx, by, u1, v0);
		vertex(cx, cy, u1, v1);
		vertex(ax, ay, u0, v0);
		vertex(cx, cy, u1, v1);
		vertex(dx, dy, u0, v1);
	}

	/** texture drawn top-left at x, y, width x height in world units, tinted (white by default): the region sourceX, sourceY, sourceWidth x
		sourceHeight of it in texels, or the whole texture when sourceWidth or sourceHeight is 0 or less. Sampled as the texture's sampling is
		now. */
	public function image(texture:Texture2D, x:Float, y:Float, width:Float, height:Float, tint = 0xffffffff, sourceX = 0., sourceY = 0., sourceWidth = 0.,
			sourceHeight = 0.):Void {
		useTexture(texture);
		var tw = texture.getWidth(), th = texture.getHeight();
		if (!(sourceWidth > 0 && sourceHeight > 0)) {
			sourceX = sourceY = 0;
			sourceWidth = tw;
			sourceHeight = th;
		}
		quad(x, y, width, height, sourceX / tw, sourceY / th, (sourceX + sourceWidth) / tw, (sourceY + sourceHeight) / th, tint);
	}

	/** Draws emitter's particles here in the batch's order (over what came before, under what comes after), through its camera: their places
		are world units (the batch's transform doesn't move them; they were born where their emitter was), the quads square to the screen. An
		emitter with nothing to draw draws nothing. */
	public function emitter(emitter:helix.particles.Emitter):Void {
		if (!emitter.isDrawable())
			return;
		closeRun();
		if (!particlesReady) {
			particlesReady = true;
			var quad = Bytes.alloc(4 * Particle3DLayout.stride), at = 0;
			for (c in [-.5, -.5, .5, -.5, .5, .5, -.5, .5]) {
				quad.setFloat(at, c);
				at += 4;
			}
			particleCorners = gpu.createStaticBuffer(quad, quad.length, false);
			var order = Bytes.alloc(24);
			for (k in 0...6)
				order.setInt32(k * 4, [0, 1, 2, 0, 2, 3][k]);
			particleIndices = gpu.createStaticBuffer(order, 24, true);
		}
		var needed = (particleCount + emitter.getCount()) * Particle3DLayout.instanceStride;
		if (needed > particleRecords.length) {
			var grown = Bytes.alloc(Std.int(Math.max(needed, particleRecords.length * 2)));
			grown.blit(0, particleRecords, 0, particleCount * Particle3DLayout.instanceStride);
			particleRecords = grown;
		}
		var first = particleCount,
			count = emitter.writeRecords(particleRecords, first * Particle3DLayout.instanceStride);
		particleCount += count;
		// The camera's mapping from the world to clip space as a matrix; z at the near plane, so nothing drawn before hides them.
		var projection = new helix.render3d.Mat4(), zoom = camera.getZoom();
		var sx = zoom * 2 / camera.getViewportWidth(),
			sy = zoom * 2 / camera.getViewportHeight();
		projection.set(0, sx);
		projection.set(5, -sy);
		projection.set(10, 0);
		projection.set(12, -camera.getX() * sx);
		projection.set(13, camera.getY() * sy);
		projection.set(14, -1);
		var uniforms = Bytes.alloc(Particle3DLayout.vertexUniformBytes);
		// Across the screen, and up it (y grows down in 2D).
		emitter.writeUniforms(uniforms, projection, [1, 0, 0], [0, -1, 0]);
		var texture = emitter.getTexture();
		runs.push(texture.getHandle());
		runs.push(first);
		runs.push(count);
		runCameras.push(camera);
		runSamplings.push(texture.getSampling());
		pushRunClip();
		runEmitters.push({
			emitter: emitter,
			first: first,
			count: count,
			uniforms: uniforms
		});
	}

	/** A filled rectangle in world units, top-left at x, y. */
	public function rect(x:Float, y:Float, w:Float, h:Float, tint:Int):Void {
		solid();
		var u = texture.getWhiteU(), v = texture.getWhiteV();
		quad(x, y, w, h, u, v, u, v, tint);
	}

	/** A filled triangle through three world points. */
	public function triangle(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, tint:Int):Void {
		solid();
		var u = texture.getWhiteU(), v = texture.getWhiteV();
		color(tint);
		vertex(x0, y0, u, v);
		vertex(x1, y1, u, v);
		vertex(x2, y2, u, v);
	}

	/** A segment width world units wide, centered on its ends with square ends; nothing for a segment of length 0. */
	public function line(x0:Float, y0:Float, x1:Float, y1:Float, width:Float, tint:Int):Void {
		var dx = x1 - x0, dy = y1 - y0, length = Math.sqrt(dx * dx + dy * dy);
		if (length == 0)
			return;
		var px = -dy * width / (2 * length), py = dx * width / (2 * length);
		triangle(x0 + px, y0 + py, x0 - px, y0 - py, x1 - px, y1 - py, tint);
		triangle(x0 + px, y0 + py, x1 - px, y1 - py, x1 + px, y1 + py, tint);
	}

	/** Rectangle outline drawn inside its bounds. */
	public function frame(x:Float, y:Float, w:Float, h:Float, width:Float, tint:Int):Void {
		rect(x, y, w, width, tint);
		rect(x, y + h - width, w, width, tint);
		rect(x, y + width, width, h - 2 * width, tint);
		rect(x + w - width, y + width, width, h - 2 * width, tint);
	}

	/** A filled rectangle with corners of radius world units, the radius clamped to half the shorter side. */
	public function roundedRect(x:Float, y:Float, w:Float, h:Float, radius:Float, tint:Int):Void {
		radius = Math.min(radius, Math.min(w, h) / 2);
		rect(x + radius, y, w - 2 * radius, h, tint);
		rect(x, y + radius, radius, h - 2 * radius, tint);
		rect(x + w - radius, y + radius, radius, h - 2 * radius, tint);
		for (corner in 0...4) {
			var cx = corner == 0 || corner == 3 ? x + radius : x + w - radius,
				cy = corner < 2 ? y + radius : y + h - radius,
				start = Math.PI + corner * Math.PI / 2;
			for (i in 0...6) {
				var p = start + i * Math.PI / 12, q = p + Math.PI / 12;
				triangle(cx, cy, cx + Math.cos(p) * radius, cy + Math.sin(p) * radius, cx + Math.cos(q) * radius, cy + Math.sin(q) * radius, tint);
			}
		}
	}

	/** Enough segments for the circle's size on screen: about one per 2.5 pixels of circumference, 12 at least. */
	function segments(radius:Float):Int
		return Std.int(Math.max(12, Math.min(256, Math.PI * 2 * radius * Math.sqrt(Math.abs(ta * td - tb * tc)) * camera.getZoom() / 2.5)));

	/** A filled circle in world units, centered on x, y, with segments for its size on screen. */
	public function circle(x:Float, y:Float, radius:Float, tint:Int):Void {
		var n = segments(radius);
		for (i in 0...n) {
			var p = i * Math.PI * 2 / n, q = (i + 1) * Math.PI * 2 / n;
			triangle(x, y, x + Math.cos(p) * radius, y + Math.sin(p) * radius, x + Math.cos(q) * radius, y + Math.sin(q) * radius, tint);
		}
	}

	/** Circle outline drawn inside its radius. */
	public function circleLines(x:Float, y:Float, radius:Float, width:Float, tint:Int):Void {
		var n = segments(radius), inner = Math.max(0, radius - width);
		for (i in 0...n) {
			var p = i * Math.PI * 2 / n,
				q = (i + 1) * Math.PI * 2 / n,
				cp = Math.cos(p),
				sp = Math.sin(p),
				cq = Math.cos(q),
				sq = Math.sin(q);
			triangle(x + cp * inner, y + sp * inner, x + cp * radius, y + sp * radius, x + cq * radius, y + sq * radius, tint);
			triangle(x + cp * inner, y + sp * inner, x + cq * radius, y + sq * radius, x + cq * inner, y + sq * inner, tint);
		}
	}

	/** Triangle outline drawn along its edges. */
	public function triangleLines(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, width:Float, tint:Int):Void {
		line(x0, y0, x1, y1, width, tint);
		line(x1, y1, x2, y2, width, tint);
		line(x2, y2, x0, y0, width, tint);
	}

	/** A filled polygon through points (x and y in turn, at least 3), convex or not, as triangles of their indices (Polygon2D.triangulate's, three
		a triangle; worked out here when null: keep them for a polygon drawn every frame). */
	public function polygon(points:Array<Float>, tint:Int, ?triangles:Array<Int>):Void {
		if (triangles == null)
			triangles = Polygon2D.triangulate(points);
		var i = 0;
		while (i + 2 < triangles.length) {
			var a = triangles[i] * 2,
				b = triangles[i + 1] * 2,
				c = triangles[i + 2] * 2;
			triangle(points[a], points[a + 1], points[b], points[b + 1], points[c], points[c + 1], tint);
			i += 3;
		}
	}

	/** A polygon's outline, closed, width world units wide centered on its edges, its corners mitered (a miter longer than twice the width is cut
		to that). Nothing for fewer than 2 points. */
	public function polygonLines(points:Array<Float>, width:Float, tint:Int):Void {
		var n = points.length >> 1;
		if (n < 2)
			return;
		// Each corner's offset, half the width out along its miter: inner and outer points.
		var ox = [], oy = [];
		for (i in 0...n) {
			var p = (i + n - 1) % n, q = (i + 1) % n;
			var ax = points[i * 2] - points[p * 2],
				ay = points[i * 2 + 1] - points[p * 2 + 1],
				bx = points[q * 2] - points[i * 2],
				by = points[q * 2 + 1] - points[i * 2 + 1];
			var al = Math.sqrt(ax * ax + ay * ay),
				bl = Math.sqrt(bx * bx + by * by);
			if (al == 0)
				al = 1;
			if (bl == 0)
				bl = 1;
			// The edges' normals, averaged, then stretched so the strip keeps its width.
			var nx = -ay / al - by / bl,
				ny = ax / al + bx / bl,
				nl = Math.sqrt(nx * nx + ny * ny);
			if (nl < 1e-9) {
				nx = -ay / al;
				ny = ax / al;
				nl = 1;
			}
			nx /= nl;
			ny /= nl;
			var dot = nx * -ay / al + ny * ax / al,
				scale = width / 2 / Math.max(dot, .25);
			ox.push(nx * scale);
			oy.push(ny * scale);
		}
		for (i in 0...n) {
			var j = (i + 1) % n,
				x0 = points[i * 2],
				y0 = points[i * 2 + 1],
				x1 = points[j * 2],
				y1 = points[j * 2 + 1];
			triangle(x0 + ox[i], y0 + oy[i], x0 - ox[i], y0 - oy[i], x1 - ox[j], y1 - oy[j], tint);
			triangle(x0 + ox[i], y0 + oy[i], x1 - ox[j], y1 - oy[j], x1 + ox[j], y1 + oy[j], tint);
		}
	}

	/** Frees the buffers and font made by new; the batch is unusable after. */
	public function destroy():Void {
		gpu.destroyBuffer(buffer);
		if (particlesReady) {
			gpu.destroyBuffer(particleCorners);
			gpu.destroyBuffer(particleIndices);
		}
		if (particleBuffer != 0)
			gpu.destroyBuffer(particleBuffer);
		font.destroy(gpu);
	}
}
