package helix.render3d;

import haxe.ds.Vector;
import haxe.io.Bytes;
import helix.graphics.BlendMode;
import helix.graphics.IGraphics;
import helix.graphics.Sampling;
import helix.render2d.Texture2D;
import helix.render3d.Light.LightKind;
import helix.render3d.Node.NodeKind;

/** A retained 3D scene: nodes under a root, drawn by draw(camera) inside a frame. A draw walks the tree as it is now (each world matrix
	worked out only where something changed), gathers the first four lights it finds, places each model's box and culls it against the
	camera's view, sorts the opaque models so alike ones (same mesh and material) are together and the see-through ones back to front after
	them, writes each model's instance record (its matrix's rows, its normals' matrix's rows, its tint), and draws each run of alike models as
	one instanced draw. Lit by its lights and its ambient light, glTF metallic-roughness (Material). */
class Stage3D {
	static inline var MAX_LIGHTS = 4;
	static inline var RECORD_FLOATS = 28;

	var gpu:IGraphics;
	var root = Node.group();
	var ambientColor = 0xffffffff;
	var ambientIntensity = 0.;
	// The framework's lit pipelines, by variant: blended + 2 double sided + 4 mirrored (front faces clockwise).
	var pipelines:Array<Int>;
	var white:Texture2D;
	var flat:Texture2D;
	var capacity = 1024;
	var instanceBuffer:Int;
	var records:Bytes;
	var vertexUniforms = Bytes.alloc(64);
	var fragmentUniforms = Bytes.alloc(Lit3DLayout.fragmentUniformBytes);
	var items:Array<Item> = [];
	var drawn:Array<Item> = [];
	var count = 0;
	var lights:Array<Node> = [];
	var planes = new Vector<Float>(24);
	var inverse = new Vector<Float>(16);
	var eyeX = 0.;
	var eyeY = 0.;
	var eyeZ = 0.;
	var forwardX = 0.;
	var forwardY = 0.;
	var forwardZ = -1.;
	var draws = 0;
	var stack:Array<Node> = [];
	var sprites:Sprites3D;
	var time = 0.;
	// Apps' surface shaders' pipelines, by the framework's variants, and the shader version they were made for.
	var surfacePipelines = new haxe.ds.ObjectMap<helix.graphics.Shader, {pipelines:Array<Int>, version:Int}>();
	var stackChanged:Array<Bool> = [];

	/** An empty stage drawing on gpu, unlit: no lights and no ambient light until they're added. */
	public function new(gpu:IGraphics) {
		this.gpu = gpu;
		pipelines = [
			for (i in 0...8)
				gpu.createPipeline(Lit3D, i & 1 != 0 ? Alpha : Opaque, 0, i & 2 != 0, i & 4 != 0)
		];
		var pixel = Bytes.alloc(4);
		pixel.fill(0, 4, 255);
		white = Texture2D.fromRgba(gpu, 1, 1, pixel);
		// A normal map's "straight out": the default, which the shader skips anyway when a material has none.
		var normal = Bytes.alloc(4);
		normal.set(0, 128);
		normal.set(1, 128);
		normal.set(2, 255);
		normal.set(3, 255);
		flat = Texture2D.fromRgba(gpu, 1, 1, normal, true);
		instanceBuffer = gpu.createBuffer(capacity * Lit3DLayout.instanceStride);
		records = Bytes.alloc(capacity * Lit3DLayout.instanceStride);
		sprites = new Sprites3D(gpu);
	}

	/** The node everything on the stage hangs from. */
	public function getRoot():Node
		return root;

	/** Adds node to the stage, as the root's last child. */
	public function add(node:Node):Bool
		return root.add(node);

	/** Takes node from the stage's root. */
	public function remove(node:Node):Bool
		return root.remove(node);

	/** The light reaching everything evenly, from no direction: color 0xRRGGBBAA (sRGB) times intensity. False for an intensity under 0. */
	public function setAmbient(color:Int, intensity:Float):Bool {
		if (!(intensity >= 0))
			return false;
		ambientColor = color;
		ambientIntensity = intensity;
		return true;
	}

	/** The seconds surface shaders see (helix_time): what the app last set. */
	public function getTime():Float
		return time;

	/** Sets the seconds surface shaders see, for whatever moves with time in them. */
	public function setTime(seconds:Float):Void
		time = seconds;

	/** Models and sprites drawn by the last draw (in view). */
	public function getDrawnCount():Int
		return count + sprites.getDrawnCount();

	/** Draws of the last draw: one a run of alike models, or of sprites of one texture. */
	public function getDrawCount():Int
		return draws + sprites.getDrawCount();

	static inline function linear(channel:Int):Float {
		var c = channel / 255;
		return c <= .04045 ? c / 12.92 : Math.pow((c + .055) / 1.055, 2.4);
	}

	/** Draws the stage in the open frame, through camera, in its viewport. */
	public function draw(camera:Camera3D):Void {
		var viewProjection = camera.getViewProjection();
		planesOf(viewProjection);
		eyeX = camera.getEyeX();
		eyeY = camera.getEyeY();
		eyeZ = camera.getEyeZ();
		var fx = camera.getTargetX() - eyeX,
			fy = camera.getTargetY() - eyeY,
			fz = camera.getTargetZ() - eyeZ;
		var fl = Math.sqrt(fx * fx + fy * fy + fz * fz);
		forwardX = fx / fl;
		forwardY = fy / fl;
		forwardZ = fz / fl;
		count = 0;
		draws = 0;
		lights.resize(0);
		sprites.begin();
		walk();
		drawn.resize(count);
		for (i in 0...count)
			drawn[i] = items[i];
		drawn.sort(compare);
		if (count > capacity) {
			while (capacity < count)
				capacity *= 2;
			gpu.destroyBuffer(instanceBuffer);
			instanceBuffer = gpu.createBuffer(capacity * Lit3DLayout.instanceStride);
			records = Bytes.alloc(capacity * Lit3DLayout.instanceStride);
		}
		for (i in 0...count)
			writeRecord(i, drawn[i]);
		gpu.updateBuffer(instanceBuffer, records, count * Lit3DLayout.instanceStride);
		gpu.setViewport(camera.getViewportX(), camera.getFramebufferHeight() - camera.getViewportY() - camera.getViewportHeight(), camera.getViewportWidth(),
			camera.getViewportHeight());
		viewProjection.writeTo(vertexUniforms);
		writeScene();
		sprites.prepare(viewProjection, camera, forwardX, forwardY, forwardZ);
		// The opaque models, the opaque and masked sprites, the see-through models with the blended sprites between them back to front, then the
		// blended sprites nearer than any of those and the added ones.
		var i = 0, opaqueSprites = false;
		while (i < count) {
			var last = i;
			while (last + 1 < count && alike(drawn[i], drawn[last + 1]))
				last++;
			if (drawn[i].blended) {
				if (!opaqueSprites) {
					sprites.drawOpaque();
					opaqueSprites = true;
				}
				sprites.drawBlendedBeyond(drawn[i].depth);
			}
			drawRun(i, last - i + 1);
			i = last + 1;
		}
		if (!opaqueSprites)
			sprites.drawOpaque();
		sprites.drawRest();
	}

	// The tree depth first, each node's world matrix brought up to date on the way down; hidden nodes skip their children.
	function walk():Void {
		stack.resize(0);
		stackChanged.resize(0);
		// The root's own transform places everything on the stage.
		var rootChanged = root.update(null, false);
		for (i in 0...root.getChildCount()) {
			stack.push(root.getChild(root.getChildCount() - 1 - i));
			stackChanged.push(rootChanged);
		}
		while (stack.length > 0) {
			var node = stack.pop(), parentChanged = stackChanged.pop();
			if (!node.isVisible())
				continue;
			var parent = node.getParent();
			var changed = node.update(parent.getWorldMatrix(), parentChanged);
			switch (node.getKind()) {
				case Model:
					visitModel(node);
				case LightNode:
					if (lights.length < MAX_LIGHTS)
						lights.push(node);
				case SpriteNode:
					sprites.visit(node, planes, eyeX, eyeY, eyeZ, forwardX, forwardY, forwardZ);
				case TextNode:
					sprites.visitText(node, planes, eyeX, eyeY, eyeZ, forwardX, forwardY, forwardZ);
				case Group | CameraNode:
			}
			for (i in 0...node.getChildCount()) {
				stack.push(node.getChild(node.getChildCount() - 1 - i));
				stackChanged.push(changed);
			}
		}
	}

	function planesOf(m:Mat4):Void
		for (p in 0...6) {
			var row = Std.int(p / 2), sign = p % 2 == 0 ? 1. : -1.;
			for (c in 0...4)
				planes[p * 4 + c] = m.get(c * 4 + 3) + sign * m.get(c * 4 + row);
			var length = Math.sqrt(planes[p * 4] * planes[p * 4] + planes[p * 4 + 1] * planes[p * 4 + 1] + planes[p * 4 + 2] * planes[p * 4 + 2]);
			if (length > 0)
				for (c in 0...4)
					planes[p * 4 + c] /= length;
		}

	function visitModel(node:Node):Void {
		var mesh = node.getMesh(), w = node.getWorldMatrix();
		// The mesh's box placed: its center moved, each world axis's reach the absolute matrix times the half extents.
		var hx = (mesh.getMaxX() - mesh.getMinX()) / 2,
			hy = (mesh.getMaxY() - mesh.getMinY()) / 2,
			hz = (mesh.getMaxZ() - mesh.getMinZ()) / 2;
		var mx = (mesh.getMaxX() + mesh.getMinX()) / 2,
			my = (mesh.getMaxY() + mesh.getMinY()) / 2,
			mz = (mesh.getMaxZ() + mesh.getMinZ()) / 2;
		var cx = w.get(0) * mx + w.get(4) * my + w.get(8) * mz + w.get(12);
		var cy = w.get(1) * mx + w.get(5) * my + w.get(9) * mz + w.get(13);
		var cz = w.get(2) * mx + w.get(6) * my + w.get(10) * mz + w.get(14);
		var rx = Math.abs(w.get(0)) * hx + Math.abs(w.get(4)) * hy + Math.abs(w.get(8)) * hz;
		var ry = Math.abs(w.get(1)) * hx + Math.abs(w.get(5)) * hy + Math.abs(w.get(9)) * hz;
		var rz = Math.abs(w.get(2)) * hx + Math.abs(w.get(6)) * hy + Math.abs(w.get(10)) * hz;
		for (p in 0...6) {
			var a = planes[p * 4],
				b = planes[p * 4 + 1],
				c = planes[p * 4 + 2];
			if (a * (cx + (a >= 0 ? rx : -rx)) + b * (cy + (b >= 0 ? ry : -ry)) + c * (cz + (c >= 0 ? rz : -rz)) + planes[p * 4 + 3] < 0)
				return;
		}
		if (count == items.length)
			items.push(new Item());
		var item = items[count];
		item.node = node;
		item.mesh = mesh;
		item.material = node.getMaterial();
		item.blended = item.material.isBlended() || node.getTint() & 255 < 255;
		// A placement that mirrors (its matrix's determinant below 0) turns the triangles' winding over.
		item.mirrored = w.get(0) * (w.get(5) * w.get(10) - w.get(9) * w.get(6)) - w.get(4) * (w.get(1) * w.get(10) - w.get(9) * w.get(2))
			+ w.get(8) * (w.get(1) * w.get(6) - w.get(5) * w.get(2)) < 0;
		item.depth = (cx - eyeX) * forwardX + (cy - eyeY) * forwardY + (cz - eyeZ) * forwardZ;
		item.order = count;
		count++;
	}

	static function compare(a:Item, b:Item):Int {
		if (a.blended != b.blended)
			return a.blended ? 1 : -1;
		if (a.blended)
			return a.depth > b.depth ? -1 : a.depth < b.depth ? 1 : a.order - b.order;
		if (a.material.id != b.material.id)
			return a.material.id - b.material.id;
		if (a.mesh.id != b.mesh.id)
			return a.mesh.id - b.mesh.id;
		if (a.mirrored != b.mirrored)
			return a.mirrored ? 1 : -1;
		return a.order - b.order;
	}

	static inline function alike(a:Item, b:Item):Bool
		return a.mesh == b.mesh && a.material == b.material && a.blended == b.blended && a.mirrored == b.mirrored;

	// The record: the world matrix's rows, the normals' matrix's rows (the inverse transpose's), the tint (linear).
	function writeRecord(index:Int, item:Item):Void {
		var w = item.node.getWorldMatrix(), r = inverse, at = index * Lit3DLayout.instanceStride;
		inverseOf(w);
		for (row in 0...3)
			for (col in 0...4)
				records.setFloat(at + Lit3DLayout.model0Offset + row * 16 + col * 4, w.get(col * 4 + row));
		// The w of the normals' first row: the tangents' handedness, -1 where the placement mirrors them.
		var mirrored = r[0] * (r[5] * r[10] - r[9] * r[6]) - r[4] * (r[1] * r[10] - r[9] * r[2]) + r[8] * (r[1] * r[6] - r[5] * r[2]) < 0;
		for (row in 0...3)
			for (col in 0...4)
				records.setFloat(at + Lit3DLayout.normal0Offset + row * 16 + col * 4,
					col < 3 ? r[row * 4 + col] : row == 0 && mirrored ? -1 : row == 0 ? 1 : 0);
		var tint = item.node.getTint();
		records.setFloat(at + Lit3DLayout.tintOffset, linear(tint >>> 24));
		records.setFloat(at + Lit3DLayout.tintOffset + 4, linear((tint >>> 16) & 255));
		records.setFloat(at + Lit3DLayout.tintOffset + 8, linear((tint >>> 8) & 255));
		records.setFloat(at + Lit3DLayout.tintOffset + 12, (tint & 255) / 255);
	}

	// The inverse of m into `inverse`, by its adjugate; all zeros for a singular m.
	function inverseOf(w:Mat4):Void {
		var m0 = w.get(0), m1 = w.get(1), m2 = w.get(2), m3 = w.get(3), m4 = w.get(4), m5 = w.get(5), m6 = w.get(6), m7 = w.get(7);
		var m8 = w.get(8), m9 = w.get(9), m10 = w.get(10), m11 = w.get(11), m12 = w.get(12), m13 = w.get(13), m14 = w.get(14), m15 = w.get(15);
		var r = inverse;
		r[0] = m5 * m10 * m15 - m5 * m11 * m14 - m9 * m6 * m15 + m9 * m7 * m14 + m13 * m6 * m11 - m13 * m7 * m10;
		r[4] = -m4 * m10 * m15 + m4 * m11 * m14 + m8 * m6 * m15 - m8 * m7 * m14 - m12 * m6 * m11 + m12 * m7 * m10;
		r[8] = m4 * m9 * m15 - m4 * m11 * m13 - m8 * m5 * m15 + m8 * m7 * m13 + m12 * m5 * m11 - m12 * m7 * m9;
		r[12] = -m4 * m9 * m14 + m4 * m10 * m13 + m8 * m5 * m14 - m8 * m6 * m13 - m12 * m5 * m10 + m12 * m6 * m9;
		r[1] = -m1 * m10 * m15 + m1 * m11 * m14 + m9 * m2 * m15 - m9 * m3 * m14 - m13 * m2 * m11 + m13 * m3 * m10;
		r[5] = m0 * m10 * m15 - m0 * m11 * m14 - m8 * m2 * m15 + m8 * m3 * m14 + m12 * m2 * m11 - m12 * m3 * m10;
		r[9] = -m0 * m9 * m15 + m0 * m11 * m13 + m8 * m1 * m15 - m8 * m3 * m13 - m12 * m1 * m11 + m12 * m3 * m9;
		r[13] = m0 * m9 * m14 - m0 * m10 * m13 - m8 * m1 * m14 + m8 * m2 * m13 + m12 * m1 * m10 - m12 * m2 * m9;
		r[2] = m1 * m6 * m15 - m1 * m7 * m14 - m5 * m2 * m15 + m5 * m3 * m14 + m13 * m2 * m7 - m13 * m3 * m6;
		r[6] = -m0 * m6 * m15 + m0 * m7 * m14 + m4 * m2 * m15 - m4 * m3 * m14 - m12 * m2 * m7 + m12 * m3 * m6;
		r[10] = m0 * m5 * m15 - m0 * m7 * m13 - m4 * m1 * m15 + m4 * m3 * m13 + m12 * m1 * m7 - m12 * m3 * m5;
		r[14] = -m0 * m5 * m14 + m0 * m6 * m13 + m4 * m1 * m14 - m4 * m2 * m13 - m12 * m1 * m6 + m12 * m2 * m5;
		r[3] = -m1 * m6 * m11 + m1 * m7 * m10 + m5 * m2 * m11 - m5 * m3 * m10 - m9 * m2 * m7 + m9 * m3 * m6;
		r[7] = m0 * m6 * m11 - m0 * m7 * m10 - m4 * m2 * m11 + m4 * m3 * m10 + m8 * m2 * m7 - m8 * m3 * m6;
		r[11] = -m0 * m5 * m11 + m0 * m7 * m9 + m4 * m1 * m11 - m4 * m3 * m9 - m8 * m1 * m7 + m8 * m3 * m5;
		r[15] = m0 * m5 * m10 - m0 * m6 * m9 - m4 * m1 * m10 + m4 * m2 * m9 + m8 * m1 * m6 - m8 * m2 * m5;
		var det = m0 * r[0] + m1 * r[4] + m2 * r[8] + m3 * r[12];
		var scale = det != 0 ? 1 / det : 0;
		for (i in 0...16)
			r[i] *= scale;
	}

	// The fragment uniforms the whole draw shares: the camera, the ambient light and the lights (the material is a run's).
	function writeScene():Void {
		var u = fragmentUniforms;
		u.setFloat(0, eyeX);
		u.setFloat(4, eyeY);
		u.setFloat(8, eyeZ);
		u.setFloat(12, 0);
		u.setFloat(16, linear(ambientColor >>> 24) * ambientIntensity);
		u.setFloat(20, linear((ambientColor >>> 16) & 255) * ambientIntensity);
		u.setFloat(24, linear((ambientColor >>> 8) & 255) * ambientIntensity);
		u.setFloat(28, 0);
		for (i in 0...MAX_LIGHTS) {
			var position = 80 + i * 16,
				direction = 144 + i * 16,
				radiance = 208 + i * 16;
			if (i >= lights.length) {
				for (k in 0...4) {
					u.setFloat(position + k * 4, 0);
					u.setFloat(direction + k * 4, 0);
					u.setFloat(radiance + k * 4, 0);
					u.setFloat(272 + i * 16 + k * 4, 0);
				}
				continue;
			}
			var node = lights[i],
				light = node.getLight(),
				w = node.getWorldMatrix();
			var dx = -w.get(8),
				dy = -w.get(9),
				dz = -w.get(10),
				dl = Math.sqrt(dx * dx + dy * dy + dz * dz);
			u.setFloat(position, w.get(12));
			u.setFloat(position + 4, w.get(13));
			u.setFloat(position + 8, w.get(14));
			u.setFloat(position + 12, light.getRange());
			u.setFloat(direction, dl > 0 ? dx / dl : 0);
			u.setFloat(direction + 4, dl > 0 ? dy / dl : -1);
			u.setFloat(direction + 8, dl > 0 ? dz / dl : 0);
			u.setFloat(direction + 12, light.getKind() == Spot ? 2 : light.getKind() == Point ? 1 : 0);
			u.setFloat(272 + i * 16, Math.cos(light.getInnerCone()));
			u.setFloat(276 + i * 16, Math.cos(light.getOuterCone()));
			u.setFloat(280 + i * 16, 0);
			u.setFloat(284 + i * 16, 0);
			var color = light.getColor(), intensity = light.getIntensity();
			u.setFloat(radiance, linear(color >>> 24) * intensity);
			u.setFloat(radiance + 4, linear((color >>> 16) & 255) * intensity);
			u.setFloat(radiance + 8, linear((color >>> 8) & 255) * intensity);
			u.setFloat(radiance + 12, 0);
		}
	}

	// A run of alike models: the material's uniforms, then one instanced draw.
	function drawRun(first:Int, runCount:Int):Void {
		var item = drawn[first],
			material = item.material,
			color = material.getBaseColor(),
			u = fragmentUniforms;
		u.setFloat(32, linear(color >>> 24));
		u.setFloat(36, linear((color >>> 16) & 255));
		u.setFloat(40, linear((color >>> 8) & 255));
		u.setFloat(44, (color & 255) / 255);
		u.setFloat(48, material.getMetallic());
		u.setFloat(52, material.getRoughness());
		u.setFloat(56, material.isLit() ? 1 : 0);
		u.setFloat(60, lights.length);
		var emissive = material.getEmissive(),
			strength = material.getEmissiveStrength(),
			normal = material.getNormalTexture();
		u.setFloat(64, linear(emissive >>> 24) * strength);
		u.setFloat(68, linear((emissive >>> 16) & 255) * strength);
		u.setFloat(72, linear((emissive >>> 8) & 255) * strength);
		u.setFloat(76, normal == null ? 0 : material.getNormalScale());
		var base = material.getTexture();
		if (base == null)
			base = white;
		if (normal == null)
			normal = flat;
		var shader = material.getShader();
		if (shader == null) {
			gpu.drawMesh(pipelines[variant(item)], item.mesh.getVertexBuffer(gpu), item.mesh.getIndexBuffer(gpu), item.mesh.getIndexCount(), instanceBuffer,
				first, runCount, [base.getHandle(), normal.getHandle()], [base.getSampling(), normal.getSampling()], [vertexUniforms, u]);
			draws++;
			return;
		}
		// An app's surface shader: the stage's blocks with the time after them, the shader's own values, its own textures (white where unset).
		var blocks = [for (size in shader.getBlockSizes()) size > 0 ? Bytes.alloc(size) : null];
		if (blocks.length > 0 && blocks[0] != null) {
			blocks[0].blit(0, vertexUniforms, 0, vertexUniforms.length);
			blocks[0].setFloat(vertexUniforms.length, time);
		}
		if (blocks.length > 1 && blocks[1] != null) {
			blocks[1].blit(0, u, 0, u.length);
			blocks[1].setFloat(u.length, time);
		}
		var parameters = material.getShaderParameters();
		parameters.write(blocks);
		var own = parameters.getTextureSlots(), textures = [], samplings = [];
		for (slot in shader.getTextureSlots()) {
			var texture = slot == 0 ? base : slot == 1 ? normal : own.exists(slot) ? own[slot] : white;
			while (textures.length < slot) {
				textures.push(0);
				samplings.push(Sampling.NEAREST);
			}
			textures.push(texture.getHandle());
			samplings.push(texture.getSampling());
		}
		gpu.drawMesh(surfacePipeline(shader)[variant(item)], item.mesh.getVertexBuffer(gpu), item.mesh.getIndexBuffer(gpu), item.mesh.getIndexCount(),
			instanceBuffer, first, runCount, textures, samplings, blocks);
		draws++;
	}

	// Which of a program's pipelines draws item: blended or not, double sided or not, mirrored or not.
	static inline function variant(item:Item):Int
		return (item.blended ? 1 : 0) + (item.material.isDoubleSided() ? 2 : 0) + (item.mirrored ? 4 : 0);

	// shader's pipelines, made again after the shader reloads.
	function surfacePipeline(shader:helix.graphics.Shader):Array<Int> {
		var made = surfacePipelines.get(shader);
		if (made == null || made.version != shader.getVersion()) {
			if (made != null)
				for (p in made.pipelines)
					gpu.destroyPipeline(p);
			made = {
				pipelines: [
					for (i in 0...8)
						gpu.createPipeline(Lit3D, i & 1 != 0 ? Alpha : Opaque, shader.getHandle(), i & 2 != 0, i & 4 != 0)
				],
				version: shader.getVersion()
			};
			surfacePipelines.set(shader, made);
		}
		return made.pipelines;
	}

	/** Frees the stage's own GPU objects (its pipelines, instance buffer and white texture); meshes and textures are their owners' to free. */
	public function destroy():Void {
		for (made in surfacePipelines)
			for (p in made.pipelines)
				gpu.destroyPipeline(p);
		surfacePipelines.clear();
		for (p in pipelines)
			gpu.destroyPipeline(p);
		sprites.destroy();
		gpu.destroyBuffer(instanceBuffer);
		white.destroy(gpu);
		flat.destroy(gpu);
	}
}

/** A model in view this draw. Pooled. */
private class Item {
	/** The model's node. */
	public var node:Node;

	/** Its mesh. */
	public var mesh:Mesh;

	/** Its material. */
	public var material:Material;

	/** Whether it is see-through (its material's or its tint's alpha). */
	public var blended = false;

	/** Whether its placement mirrors it, so its front faces wind clockwise. */
	public var mirrored = false;

	/** Its box's center's distance along the camera's view. */
	public var depth = 0.;

	/** Its place in the walk: ties keep it. */
	public var order = 0;

	/** An empty item, filled by the walk. */
	public function new() {}
}
