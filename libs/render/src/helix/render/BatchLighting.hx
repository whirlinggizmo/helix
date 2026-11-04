package helix.render;

import haxe.ds.ObjectMap;
import helix.math.Bounds3D;
import helix.math.Matrix3D;
import helix.platform.Sampling;
import helix.services.shaders.Shader;
import helix.services.shaders.ShaderBlockValues;
import helix.services.shaders.ShaderSampler;
import helix.services.shaders.ShaderUniform;
import helix.services.shaders.ShaderValues;
import helix.services.shaders.ShaderVertexLayout;

/** `Batch3D`'s lit work: the lit materials' shader, the `Lighting` block written at each `begin` and shared through each view's scene,
	the lights read then, the 8 chosen for each draw, and a lit material's names written on its draw.

	It is linked only by what gives light (`install`, which `Light3D` lists), so a program drawing nothing lit carries none of it. */
@:noCompletion
@:allow(helix.render)
@:access(helix.render.Batch3D)
class BatchLighting {
	// The most lights a draw is lit by.
	static inline final MOST = 8;
	// The floats a light is read as (Light3D.writeLight).
	static inline final FLOATS = 16;

	/** Makes the batches light their lit materials, from their next `begin`. */
	static function install():Void {
		if (Batch3D.makeLighting == null)
			Batch3D.makeLighting = attach;
	}

	/** Gives a batch its lit work, through the hooks it calls. */
	static function attach(batch:Batch3D):Void {
		var l = new BatchLighting(batch);
		batch.lightingBegin = l.begin;
		batch.lightingPrepare = l.prepare;
	}

	// The names the draw being made fills, and its material and mesh, as prepare found them.
	var drawFill:Null<LitFill> = null;
	var drawMaterial:Null<Material3D> = null;
	var drawMesh:Null<GpuMesh3D> = null;
	// Whether each mesh layout holds tangents, for the normal map.
	final tangents = new ObjectMap<ShaderVertexLayout, Bool>();
	// A draw's box in the world, or the first view's eye, for its lights.
	final box = new Bounds3D();

	/** Reads the batch's lights and environment as its `begin` does, writes the block, and shares it with the views it opens. */
	function begin(viewCount:Int):Void {
		read(batch.lights, batch.environment);
		for (i in 0...viewCount)
			batch.viewPool[i].scene.shareBlock(block);
	}

	/** Prepares a draw: given its program's shader or null, the shader it is drawn with, the lit materials' for a material lit (a lit
		shading, or emissive light to add) or null for the unlit one; and the batch's `lightWriter` set to `write` where that shader reads
		a lit name, the lights reaching its box in the world chosen (a batch draw's, with no box, those reaching the first view's eye), or
		to null. */
	function prepare(custom:Null<Shader>, material:Null<Material3D>, mesh:Null<GpuMesh3D>, bounds:Null<Bounds3D>, transform:Null<Matrix3D>):Null<Shader> {
		batch.lightWriter = null;
		var s = custom;
		if (s == null && material != null && (material.shading != Unlit || material.emissiveColor & 0xffffff != 0))
			s = shader;
		if (s == null)
			return null;
		var f = fillFor(s);
		if (!f.reads)
			return s;
		drawFill = f;
		drawMaterial = material;
		drawMesh = mesh;
		if (f.lightCount.declared) {
			if (bounds == null) {
				var view = batch.viewPool[0];
				choose(box.makeEmpty().expand(view.eyeX, view.eyeY, view.eyeZ));
			} else
				choose(Batch3D.transformBox(bounds, transform, box));
		}
		batch.lightWriter = writer;
		return s;
	}

	// write, made once as a function value.
	final writer:ShaderValues->Void;

	/** Writes the prepared draw's lights, and its material's lit names, on its values. */
	function write(values:ShaderValues):Void {
		var f = drawFill, m = drawMaterial;
		if (m != null)
			writeMaterial(f, values, m, drawMesh);
		writeLights(f, values, m != null && batch.receiveShadows && m.receiveShadows);
	}

	final batch:Batch3D;
	final renderer:Renderer;
	// The lit materials' shader, every shading.
	final shader:Shader;
	final block:ShaderBlockValues;
	final ambientLight:ShaderUniform;
	final fills = new ObjectMap<Shader, LitFill>();
	// The lights read at begin, FLOATS each, and how many.
	final lights:Array<Float> = [];
	var lightCount = 0;
	// The lights chosen for a draw, by their index in lights, with how much each reaches it, and how many.
	final chosen = [for (_ in 0...MOST) 0];
	final reach = [for (_ in 0...MOST) 0.];
	var chosenCount = 0;
	// The chosen lights as the shader reads them, four floats an element, MOST elements each.
	final positions = [for (_ in 0...MOST * 4) 0.];
	final directions = [for (_ in 0...MOST * 4) 0.];
	final colors = [for (_ in 0...MOST * 4) 0.];
	final cones = [for (_ in 0...MOST * 4) 0.];

	function new(batch:Batch3D) {
		this.batch = batch;
		renderer = batch.renderer;
		shader = RenderShaders.compileOwn("mesh.vert", "lit.frag");
		block = new ShaderBlockValues(shader, "Lighting");
		ambientLight = shader.getUniform("ambientLight");
		writer = write;
	}

	/** Reads the lights and the environment as a batch's `begin` does, and writes the block. */
	function read(lights:Array<Light3D>, environment:Environment3D):Void {
		if (environment.map != null)
			throw "helix-render: an environment map (Environment3D.setMap) is not yet built (stage 4, environment maps)";
		var floats = this.lights;
		while (floats.length < lights.length * FLOATS)
			floats.push(0);
		for (i in 0...lights.length) {
			lights[i].writeLight(floats, i * FLOATS);
			if (lights[i].castsShadow && floats[i * FLOATS + 7] != 3)
				throw "helix-render: a light casting shadows (Light3D.castsShadow) is not yet built (stage 3, shadows); set it to false";
		}
		lightCount = lights.length;
		Light3D.writeRadiance(environment.ambientColor, environment.ambientIntensity, positions, 0);
		block.writeVector(ambientLight, positions[0], positions[1], positions[2], 0);
	}

	/** Chooses the lights reaching a box in the world most, at most MOST: each light's brightness through its falloff at the box's
		nearest point and its cone toward the box. */
	function choose(box:Bounds3D):Void {
		chosenCount = 0;
		var f = lights;
		for (i in 0...lightCount) {
			var at = i * FLOATS;
			var kind = Std.int(f[at + 7]);
			var r = f[at + 8], g = f[at + 9], b = f[at + 10];
			var amount = .2126 * r + .7152 * g + .0722 * b;
			if (kind == 3)
				amount = Math.max(amount, .2126 * f[at] + .7152 * f[at + 1] + .0722 * f[at + 2]);
			if (kind == 1 || kind == 2)
				amount *= falloffAt(box, f, at, kind);
			if (!(amount > 0))
				continue;
			// Kept in order, most first; past MOST, the least drops out.
			var k = chosenCount < MOST ? chosenCount++ : MOST;
			if (k == MOST && amount <= reach[MOST - 1])
				continue;
			if (k == MOST)
				k = MOST - 1;
			while (k > 0 && reach[k - 1] < amount) {
				reach[k] = reach[k - 1];
				chosen[k] = chosen[k - 1];
				k--;
			}
			reach[k] = amount;
			chosen[k] = i;
		}
		for (n in 0...chosenCount) {
			var at = chosen[n] * FLOATS;
			for (c in 0...4) {
				positions[n * 4 + c] = f[at + c];
				directions[n * 4 + c] = f[at + 4 + c];
				colors[n * 4 + c] = f[at + 8 + c];
				cones[n * 4 + c] = f[at + 12 + c];
			}
		}
	}

	// A point or spot light's falloff at a box: by the distance to its nearest point, the range's window, and for a spot its cone toward
	// the box, widened by the box's reach about its center.
	static function falloffAt(box:Bounds3D, f:Array<Float>, at:Int, kind:Int):Float {
		if (box.isEmpty)
			return 0;
		var x = f[at], y = f[at + 1], z = f[at + 2], range = f[at + 3];
		var dx = Math.max(box.minX - x, Math.max(0, x - box.maxX)),
			dy = Math.max(box.minY - y, Math.max(0, y - box.maxY)),
			dz = Math.max(box.minZ - z, Math.max(0, z - box.maxZ));
		var d2 = dx * dx + dy * dy + dz * dz;
		var falloff = 1 / Math.max(d2, .01);
		if (range > 0) {
			var r = Math.sqrt(d2) / range;
			var window = Math.max(0, 1 - r * r * r * r);
			falloff *= window * window;
		}
		if (kind == 2 && falloff > 0) {
			var cx = (box.minX + box.maxX) / 2 - x,
				cy = (box.minY + box.maxY) / 2 - y,
				cz = (box.minZ + box.maxZ) / 2 - z;
			var distance = Math.sqrt(cx * cx + cy * cy + cz * cz);
			var hx = (box.maxX - box.minX) / 2,
				hy = (box.maxY - box.minY) / 2,
				hz = (box.maxZ - box.minZ) / 2;
			var radius = Math.sqrt(hx * hx + hy * hy + hz * hz);
			if (distance > radius) {
				var cosine = (cx * f[at + 4] + cy * f[at + 5] + cz * f[at + 6]) / distance;
				var angle = Math.max(0, Math.acos(Math.max(-1, Math.min(1, cosine))) - Math.asin(radius / distance));
				var inner = f[at + 12],
					outer = f[at + 13],
					c = Math.cos(angle);
				falloff *= inner - outer > 1e-6 ? smoothstep(outer, inner, c) : c >= outer ? 1 : 0;
			}
		}
		return falloff;
	}

	static function smoothstep(edge0:Float, edge1:Float, x:Float):Float {
		var t = Math.max(0, Math.min(1, (x - edge0) / (edge1 - edge0)));
		return t * t * (3 - 2 * t);
	}

	/** The names this shader is filled by, found once. */
	function fillFor(s:Shader):LitFill {
		var f = fills.get(s);
		if (f == null)
			fills.set(s, f = new LitFill(s));
		return f;
	}

	/** Writes the chosen lights on a draw's values, where its shader declares them. */
	function writeLights(f:LitFill, values:ShaderValues, receive:Bool):Void {
		if (LitFill.holds(f.lightCount))
			values.writeInt(f.lightCount, chosenCount);
		if (LitFill.holds(f.receiveShadows))
			values.writeInt(f.receiveShadows, receive ? 1 : 0);
		if (chosenCount == 0)
			return;
		if (LitFill.holds(f.lightPositions))
			values.writeFloats(f.lightPositions, positions);
		if (LitFill.holds(f.lightDirections))
			values.writeFloats(f.lightDirections, directions);
		if (LitFill.holds(f.lightColors))
			values.writeFloats(f.lightColors, colors);
		if (LitFill.holds(f.lightCones))
			values.writeFloats(f.lightCones, cones);
	}

	/** Whether a mesh's records hold tangents, found once a layout. */
	function hasTangents(layout:ShaderVertexLayout):Bool {
		var found = tangents.get(layout);
		if (found == null)
			tangents.set(layout, found = Lambda.exists(layout.buffers[0].placements, p -> p.name == "vertexTangent"));
		return found;
	}

	/** Writes a material's lit names on a draw's values, where its shader declares them. */
	function writeMaterial(f:LitFill, values:ShaderValues, m:Material3D, mesh:GpuMesh3D):Void {
		var white = renderer.white.handle;
		inline function map(s:ShaderSampler, t:Null<Texture2D>, srgb:Int, auto:Bool):Int {
			if (s.declared)
				values.writeTexture(s, t == null ? white : t.drawnHandle(), t == null ? Sampling.LINEAR : t.sampling);
			return t != null && (t.colorSpace == Srgb || t.colorSpace == Auto && auto) ? srgb : 0;
		}
		var flags = m.normalTexture != null && hasTangents(mesh.layout) ? 1 : 0;
		flags |= map(f.emissiveTexture, m.emissiveTexture, 2, true);
		flags |= map(f.metallicRoughnessTexture, m.metallicRoughnessTexture, 4, false);
		flags |= map(f.normalTexture, m.normalTexture, 8, false);
		flags |= map(f.occlusionTexture, m.occlusionTexture, 16, false);
		flags |= map(f.lightTexture, m.lightTexture, 32, false);
		if (m.lightTexture != null)
			flags |= 64;
		if (LitFill.holds(f.textureFlags))
			values.writeInt(f.textureFlags, flags);
		var e = m.emissiveColor;
		if (LitFill.holds(f.emissiveColor))
			values.writeVector(f.emissiveColor, (e >> 16 & 255) / 255, (e >> 8 & 255) / 255, (e & 255) / 255, m.emissiveStrength);
		if (LitFill.holds(f.specularColor))
			values.writeColor(f.specularColor, m.specularColor);
		if (LitFill.holds(f.sheenColor))
			values.writeColor(f.sheenColor, m.sheenColor);
		var floats = f.floats, n = f.floatValues;
		n[0] = m.metallic;
		n[1] = m.roughness;
		n[2] = m.normalScale;
		n[3] = m.occlusionIntensity;
		n[4] = m.lightIntensity;
		n[5] = m.environmentIntensity;
		n[6] = m.specularIntensity;
		n[7] = m.shininess;
		n[8] = m.ior;
		n[9] = m.clearcoat;
		n[10] = m.clearcoatRoughness;
		n[11] = m.sheenRoughness;
		for (i in 0...floats.length)
			if (LitFill.holds(floats[i]))
				values.writeFloat(floats[i], n[i]);
		if (LitFill.holds(f.shading))
			values.writeInt(f.shading, cast m.shading);
		if (LitFill.holds(f.fog))
			values.writeInt(f.fog, m.fog ? 1 : 0);
		if (LitFill.holds(f.flatShading))
			values.writeInt(f.flatShading, m.flatShading ? 1 : 0);
	}
}

/** The lit names helix-render fills in one shader, found once by name: the draw's lights and a material's lit colors, values and maps. */
@:noCompletion
@:allow(helix.render)
class LitFill {
	final lightCount:ShaderUniform;
	final lightPositions:ShaderUniform;
	final lightDirections:ShaderUniform;
	final lightColors:ShaderUniform;
	final lightCones:ShaderUniform;
	final receiveShadows:ShaderUniform;
	final emissiveColor:ShaderUniform;
	final specularColor:ShaderUniform;
	final sheenColor:ShaderUniform;
	final shading:ShaderUniform;
	final fog:ShaderUniform;
	final flatShading:ShaderUniform;
	final textureFlags:ShaderUniform;
	// metallic to sheenRoughness, in BatchLighting.writeMaterial's order, and their values for a draw.
	final floats:Array<ShaderUniform>;
	final floatValues = [for (_ in 0...12) 0.];
	final metallicRoughnessTexture:ShaderSampler;
	final normalTexture:ShaderSampler;
	final occlusionTexture:ShaderSampler;
	final lightTexture:ShaderSampler;
	final emissiveTexture:ShaderSampler;
	// Whether the shader reads any of them.
	final reads:Bool;

	function new(s:Shader) {
		lightCount = s.reserveUniform("lightCount");
		lightPositions = s.reserveUniform("lightPositions");
		lightDirections = s.reserveUniform("lightDirections");
		lightColors = s.reserveUniform("lightColors");
		lightCones = s.reserveUniform("lightCones");
		receiveShadows = s.reserveUniform("receiveShadows");
		emissiveColor = s.reserveUniform("emissiveColor");
		specularColor = s.reserveUniform("specularColor");
		sheenColor = s.reserveUniform("sheenColor");
		shading = s.reserveUniform("shading");
		fog = s.reserveUniform("fog");
		flatShading = s.reserveUniform("flatShading");
		textureFlags = s.reserveUniform("textureFlags");
		floats = [
			for (n in [
				"metallic",
				"roughness",
				"normalScale",
				"occlusionIntensity",
				"lightIntensity",
				"environmentIntensity",
				"specularIntensity",
				"shininess",
				"ior",
				"clearcoat",
				"clearcoatRoughness",
				"sheenRoughness"
			])
				s.reserveUniform(n)
		];
		metallicRoughnessTexture = s.reserveSampler("metallicRoughnessTexture");
		normalTexture = s.reserveSampler("normalTexture");
		occlusionTexture = s.reserveSampler("occlusionTexture");
		lightTexture = s.reserveSampler("lightTexture");
		emissiveTexture = s.reserveSampler("emissiveTexture");
		reads = Lambda.exists([
			lightCount,
			lightPositions,
			lightDirections,
			lightColors,
			lightCones,
			receiveShadows,
			emissiveColor,
			specularColor,
			sheenColor,
			shading,
			fog,
			flatShading,
			textureFlags
		].concat(floats),
			u -> u.declared && !u.shared)
			|| metallicRoughnessTexture.declared
			|| normalTexture.declared
			|| occlusionTexture.declared
			|| lightTexture.declared
			|| emissiveTexture.declared;
	}

	/** Whether the draw's own values hold a name: declared, and not in a shared block. */
	static inline function holds(u:ShaderUniform):Bool
		return u.declared && !u.shared;
}
