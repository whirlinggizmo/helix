import Render2DTests.CountingGraphics;
import haxe.io.Bytes;
import helix.graphics.Graphics;
import helix.graphics.PipelineDesc;
import helix.graphics.Shader;
import helix.render3d.Camera3D;
import helix.render3d.DirectionalLight3D;
import helix.render3d.Material3D;
import helix.render3d.Mesh3D;
import helix.render3d.Model3D;
import helix.render3d.Node3D;
import helix.render3d.Skin3D;
import helix.render3d.Renderer3D;
import helix.shaders.Dissolve;
import helix.shaders.HitFlash;
import helix.shaders.Outline;
import helix.shaders.Rim;
import helix.shaders.ShaderLibrary;
import helix.shaders.Silhouette;
import helix.shaders.Toon;
import helix.shaders.Unlit;
import helix.shaders.Water;

/** The shader library packed into the program (src/helix/src/helix/tools/shader/ShaderPacker.hx's generated <Name>Packed classes): each packed shader reads and builds
	with its variants (skinned, and the casters of a shader with a vertex hook or a discard), is built once a GPU and shared, freed with the
	GPU's release; each library class's fields write their parameters where the shader's reflection puts them; the hit flash and rim reach the
	stage's uniforms; a skinned model draws through a surface shader's skinned variant; a dissolving shadow is drawn by its caster; and a
	model's passes come in their order, instanced. */
class ShaderLibraryTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-6;

	// An sRGB channel (0..255) as linear light.
	static function linear(channel:Int):Float {
		var c = channel / 255;
		return c <= .04045 ? c / 12.92 : Math.pow((c + .055) / 1.055, 2.4);
	}

	public static function main():Void {
		var gpu = new CountingGraphics();
		@:privateAccess Graphics.bind(gpu);
		packed(gpu);
		noise(gpu);
		unlit(gpu);
		toon();
		dissolve(gpu);
		water();
		flashAndRim(gpu);
		skinned(gpu);
		casters(gpu);
		passes(gpu);
		passVertices(gpu);
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}

	// Every packed shader reads as a .hxshader and builds, with its variants; the library builds each once a GPU, until the GPU's release.
	static function packed(gpu:CountingGraphics):Void {
		var texts = PackedShaders.texts();
		for (name in ["unlit", "toon", "dissolve", "water", "tonemap"])
			check(texts.exists(name), 'The library\'s $name is packed, by its file\'s stem');
		for (name => text in texts) {
			var shader = Shader.fromText(gpu, text());
			check(shader.kind == "surface" || shader.kind == "screen" || shader.kind == "sprite", '$name packs as a kind the framework has');
			check((shader.kind == "surface") == (shader.skinned != null), '$name: a surface shader has a skinned variant, a screen or sprite shader none');
			if (shader.kind == "surface") {
				var casts = name == "dissolve" || name == "water";
				check((shader.caster != null) == casts && (shader.skinned.caster != null) == casts,
					'$name: casters only for a vertex hook or a discard, static and skinned');
				check(shader.skinned.textureSlots.indexOf(5) >= 0 && shader.textureSlots.indexOf(5) < 0,
					'$name: the skinned variant samples the joints at slot 5, the static one doesn\'t');
				check(shader.skinned.handle != shader.handle, '$name: each variant is a program of its own');
			}
			shader.destroy();
		}
		var first = ShaderLibrary.get(gpu, "unlit", UnlitPacked.text());
		check(ShaderLibrary.get(gpu, "unlit", UnlitPacked.text()) == first, "A library shader is built once a GPU, and shared");
		check(ShaderLibrary.get(new CountingGraphics(), "unlit", UnlitPacked.text()) != first, "Another GPU builds its own");
		ShaderLibrary.release(gpu);
		check(ShaderLibrary.get(gpu, "unlit", UnlitPacked.text()) != first, "Released with its GPU, it is built again when next asked for");
		var stale = haxe.Json.parse(UnlitPacked.text());
		stale.helixShader = 1;
		var refused = false;
		try
			Shader.fromText(gpu, haxe.Json.stringify(stale))
		catch (e:Dynamic)
			refused = true;
		check(refused, "A file of another format is refused");
	}

	// The library's noise: the same texels every time, spread evenly over 0..1, made once a GPU.
	static function noise(gpu:CountingGraphics):Void {
		var pixels = ShaderLibrary.noisePixels(),
			again = ShaderLibrary.noisePixels();
		check(pixels.compare(again) == 0, "The noise is the same every time");
		var n = ShaderLibrary.NOISE_SIZE * ShaderLibrary.NOISE_SIZE, below = 0, hash = 0;
		for (i in 0...n) {
			if (pixels.get(i * 4) < 128)
				below++;
			hash = (hash * 31 + pixels.get(i * 4)) & 0xffffff;
		}
		check(Math.abs(below - n / 2) <= n / 100, "Spread evenly: half its texels below the middle");
		check(pixels.get(3) == 255 && pixels.get(0) == pixels.get(1) && pixels.get(1) == pixels.get(2), "Opaque, its channels alike");
		// Its texels, pinned: a change to the noise (or to integer arithmetic on a target) shows here.
		check(hash == 0xc57dd0, 'The noise\'s texels as pinned (hash ${StringTools.hex(hash, 6)})');
		var texture = ShaderLibrary.getNoise(gpu);
		check(ShaderLibrary.getNoise(gpu) == texture && texture.sampling.wrapU == Repeat, "Made once a GPU, repeating");
	}

	// The material's parameters' bytes as a draw writes them: by slot, null for a slot the shader lacks.
	static function blocks(material:Material3D):Array<Null<Bytes>> {
		var out = [for (size in material.shader.blockSizes) size > 0 ? Bytes.alloc(size) : null];
		material.shaderParameters.write(out);
		return out;
	}

	// The value parameter name was written as, its component i.
	static function written(material:Material3D, name:String, i = 0):Float {
		var p = material.shader.getParameter(name);
		return blocks(material)[p.slot].getFloat(p.offset + i * 4);
	}

	static function unlit(gpu:CountingGraphics):Void {
		var material = new Material3D(), other = new Material3D();
		var unlit = new Unlit(material), alike = new Unlit(other);
		check(material.shader != null && material.shader.kind == "surface", "Unlit is its material's surface shader");
		check(other.shader == material.shader, "Two materials share the library's one");
		check(unlit.color == 0xffffffff && unlit.attached, "White by default: the material as it is");
		var p = material.shader.getParameter("color");
		check(p != null && p.slot == 2 && p.type == "vec4" && p.elementCount == 1, "Its color is its own block's vec4");
		var bytes = blocks(material)[p.slot];
		check(near(bytes.getFloat(p.offset), 1) && near(bytes.getFloat(p.offset + 12), 1), "Written white from the start");
		unlit.color = 0xcc336699;
		bytes = blocks(material)[p.slot];
		check(near(bytes.getFloat(p.offset), 0x33 / 255)
			&& near(bytes.getFloat(p.offset + 4), 0x66 / 255)
			&& near(bytes.getFloat(p.offset + 8), 0x99 / 255)
			&& near(bytes.getFloat(p.offset + 12), 0xcc / 255),
			"The color field writes its member at the reflection's offset, rgba 0 to 1");
		check(near(blocks(other)[p.slot].getFloat(p.offset), 1), "Each material keeps its own color");
		material.setShader(null);
		unlit.color = 0xffff0000;
		check(material.shaderParameters == null && unlit.color == 0xffff0000 && !unlit.attached,
			"With another shader on the material, the field writes nothing there");
	}

	static function toon():Void {
		var material = new Material3D(), toon = new Toon(material);
		var bands = material.shader.getParameter("bands"),
			shadow = material.shader.getParameter("shadow_color");
		check(bands.slot == 2 && bands.offset == 16 && shadow.slot == 2 && shadow.offset == 0, "Toon's parameters where its block has them");
		check(toon.bands == 3 && written(material, "bands") == 3, "Three bands by default, written");
		toon.bands = 40;
		check(toon.bands == 16 && written(material, "bands") == 16, "Bands held to 16");
		toon.shadowColor = 0x00804020;
		check(near(written(material, "shadow_color"), linear(0x80)) && near(written(material, "shadow_color", 1), linear(0x40)),
			"The shadow color written as linear light");
		check(toon.rim.material == material && @:privateAccess material.rimColor == 0x55ffffff, "Toon turns its material's rim on");
	}

	static function dissolve(gpu:CountingGraphics):Void {
		var material = new Material3D(), dissolve = new Dissolve(material);
		check(material.shader.caster != null, "Dissolve casts its own shadow (it discards)");
		var amount = material.shader.getParameter("amount"),
			edge = material.shader.getParameter("edge_color"),
			width = material.shader.getParameter("edge_width"),
			scale = material.shader.getParameter("scale");
		check(edge.offset == 0 && amount.offset == 16 && width.offset == 20 && scale.offset == 24, "Dissolve's parameters where its block has them");
		dissolve.amount = .4;
		dissolve.edgeWidth = 0;
		check(near(written(material, "amount"), .4)
			&& near(written(material, "edge_width"), .001), "Amount written; a width held above 0");
		dissolve.amount = 2;
		check(dissolve.amount == 1, "Amount held to 1");
		dissolve.edgeColor = 0x00ff0000;
		dissolve.edgeIntensity = 3;
		check(near(written(material, "edge_color"), 3)
			&& near(written(material, "edge_color", 1), 0), "The edge's color times its intensity");
		var slot = material.shader.getTextureSlot("dissolve_noise");
		check(slot == 6
			&& material.shaderParameters.textureSlots[slot] == ShaderLibrary.getNoise(gpu), "The library's noise at its own slot, 6");
	}

	static function water():Void {
		var material = new Material3D(), water = new Water(material);
		check(material.shader.caster != null, "Water casts its own shadow (its waves move it)");
		var amplitude = material.shader.getParameter("amplitude"),
			shininess = material.shader.getParameter("shininess");
		check(amplitude.slot == 3 && amplitude.offset == 0 && material.shader.getParameter("wave_speed").offset == 8,
			"The waves' parameters in the vertex hook's block, 3");
		check(shininess.slot == 2 && shininess.offset == 48, "The fragment's parameters in its block, 2");
		water.amplitude = -1;
		water.shininess = 1e9;
		check(written(material, "amplitude") == 0 && written(material, "shininess") == 2048, "Fields held to their ranges");
		water.deepColor = 0xff00ff00;
		check(near(written(material, "deep_color", 1), 1) && near(written(material, "deep_color"), 0), "Colors written as linear light");
	}

	// A stage drawing one cube of material through camera: the fragment block of its draw.
	static function drawn(gpu:CountingGraphics, stage:Renderer3D, camera:Camera3D):Bytes {
		gpu.meshDraws = [];
		gpu.beginFrame(800, 600, 0);
		stage.draw(camera);
		return gpu.meshDraws[gpu.meshDraws.length - 1].uniforms[1];
	}

	static function flashAndRim(gpu:CountingGraphics):Void {
		var stage = new Renderer3D(gpu),
			material = new Material3D(),
			camera = new Camera3D();
		camera.setViewport(800, 600);
		camera.setView(0, 0, 5, 0, 0, 0);
		stage.add(new Model3D(Mesh3D.cube(1, 1, 1), material));
		// The material's flash and rim in the stage's fragment block, after its emission: the flash's rgb and amount, the rim's rgb and power.
		var u = drawn(gpu, stage, camera);
		check(u.getFloat(92) == 0 && u.getFloat(96) == 0 && u.getFloat(108) == 3, "No flash and no rim by default");
		var flash = new HitFlash(material),
			rim = new Rim(material, 0x80ff0000, 5);
		check(!flash.trigger(0xffffffff, 0), "A flash over no time is refused");
		check(flash.trigger(0xffff0000, .5), "A flash triggered");
		stage.time = 10;
		u = drawn(gpu, stage, camera);
		check(near(u.getFloat(80), 1) && near(u.getFloat(84), 0) && near(u.getFloat(92), 1), "All of it at the first draw after the trigger");
		check(near(u.getFloat(96), 128 / 255) && near(u.getFloat(100), 0) && near(u.getFloat(108), 5),
			"The rim's linear color times its strength, and its power");
		stage.time = 10.25;
		check(near(drawn(gpu, stage, camera).getFloat(92), .5), "Half of it halfway through, by the stage's time");
		stage.time = 11;
		check(drawn(gpu, stage, camera).getFloat(92) == 0, "None once its seconds are past");
		flash.amount = .25;
		check(near(drawn(gpu, stage, camera).getFloat(92), .25) && flash.amount == .25, "An amount held");
		var alike = new HitFlash(material);
		alike.amount = 2;
		check(flash.amount == 1, "Two flashes on a material share it; the amount held to 1");
		rim.power = 0;
		check(rim.power == .1
			&& new Rim(material, 0x00000000).color == 0x00000000, "The power held above 0; a rim of no strength is none");
		// The same terms reach a surface shader's stage block: the library's Unlit is drawn with them.
		new Unlit(material);
		flash.amount = 1;
		var block = drawn(gpu, stage, camera);
		check(block.length > 1760 && near(block.getFloat(92), 1), "A library surface shader gets the flash in the stage's block too");
	}

	// A model of a mesh skinned to two joints, bound to a skeleton of its own on stage.
	static function skinnedModel(stage:Renderer3D, material:Material3D):Model3D {
		var positions = [0., 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 2, 0, 0, 1, 1, 0];
		var mesh = Mesh3D.fromArrays(positions, null, null, null, null, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
			[1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]);
		var skin = new Skin3D(["hip", "knee"], [
			1., 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -1, 0, 0, 1
		]);
		var character = new Node3D(), hip = new Node3D(), knee = new Node3D();
		hip.name = "hip";
		knee.name = "knee";
		knee.setPosition(1, 0, 0);
		hip.addChild(knee);
		character.addChild(hip);
		var model = new Model3D(mesh, material);
		character.addChild(model);
		model.bindSkeleton(character, skin);
		stage.add(character);
		return model;
	}

	// A skinned model draws through its material's surface shader's skinned variant, with the skin's buffer and the joints at slot 5.
	static function skinned(gpu:CountingGraphics):Void {
		var stage = new Renderer3D(gpu),
			material = new Material3D(),
			camera = new Camera3D();
		camera.setViewport(800, 600);
		camera.setView(1, 0, 5, 1, 0, 0);
		new Toon(material);
		skinnedModel(stage, material);
		gpu.meshDraws = [];
		gpu.meshPipelines = [];
		gpu.beginFrame(800, 600, 0);
		stage.draw(camera);
		var desc = gpu.describe(gpu.meshPipelines[0]), draw = gpu.meshDraws[0];
		check(gpu.meshDraws.length == 1
			&& desc.shader == material.shader.skinned.handle, "A skinned model draws through the skinned variant");
		check(desc.buffers.length == 3 && draw.buffers.length == 3, "With the skin's joints and weights beside its vertices and records");
		check(draw.textures[5] == @:privateAccess stage.palette.texture, "The stage's joints at slot 5");
	}

	// Shadows: a shader with a discard draws its casters itself, never reading the map it draws into; another's are the framework's.
	static function casters(gpu:CountingGraphics):Void {
		var stage = new Renderer3D(gpu),
			camera = new Camera3D(),
			sun = new DirectionalLight3D();
		camera.setViewport(800, 600);
		camera.setView(0, 2, 6, 0, 0, 0);
		sun.shadowCasting = true;
		sun.lookAt(-.3, -1, -.2);
		stage.add(sun);
		var cut = new Material3D(),
			plain = new Material3D(),
			banded = new Material3D();
		new Dissolve(cut);
		new Toon(banded);
		var cube = Mesh3D.cube(1, 1, 1);
		for (material in [cut, cut, plain, banded])
			stage.add(new Model3D(cube, material));
		gpu.meshDraws = [];
		gpu.meshPipelines = [];
		stage.drawShadows(camera);
		var shaded = [
			for (i in 0...gpu.meshPipelines.length)
				if (gpu.describe(gpu.meshPipelines[i]).shader == cut.shader.caster.handle) i
		];
		check(shaded.length == 1 && gpu.meshDraws[shaded[0]].instances == 2, "The dissolving cubes' shadows drawn by its caster, as one run");
		var desc = gpu.describe(gpu.meshPipelines[shaded[0]]),
			draw = gpu.meshDraws[shaded[0]];
		check(desc.depthOnly && desc.cull == None && desc.buffers.length == 2, "Depth only, nothing culled, from the lit records");
		check(draw.textures[2] == @:privateAccess stage.noShadows && draw.textures[6] == ShaderLibrary.getNoise(gpu).handle,
			"The stand-in at the shadow slot, never the map drawn into; its noise at its own");
		var plainRun = [
			for (i in 0...gpu.meshPipelines.length)
				if (gpu.describe(gpu.meshPipelines[i]).shader != cut.shader.caster.handle) i
		];
		check(plainRun.length == 1
			&& gpu.meshDraws[plainRun[0]].instances == 2, "The plain and toon cubes' shadows: the framework's caster, one run");
	}

	// A model's passes: its silhouette before it (so its own parts never hide it), every outline after the opaque models, alike ones instanced.
	static function passes(gpu:CountingGraphics):Void {
		var stage = new Renderer3D(gpu),
			camera = new Camera3D(),
			material = new Material3D();
		camera.setViewport(800, 600);
		camera.setView(0, 0, 8, 0, 0, 0);
		var cube = Mesh3D.cube(1, 1, 1);
		var plain = new Model3D(cube, material),
			seen = new Model3D(Mesh3D.sphere(.5), material),
			left = new Model3D(cube, material),
			right = new Model3D(cube, material);
		left.setPosition(-2, 0, 0);
		right.setPosition(2, 0, 0);
		for (model in [plain, seen, left, right])
			stage.add(model);
		var silhouette = new Silhouette(seen);
		var outlines = [new Outline(left, 0xff000000, .05), new Outline(right, 0xff000000, .05)];
		check(seen.passCount == 1 && seen.getPass(0) == silhouette && outlines[0].width == .05, "A pass adds itself to its model");
		gpu.meshDraws = [];
		gpu.meshPipelines = [];
		gpu.beginFrame(800, 600, 0);
		stage.draw(camera);
		var descs = [for (p in gpu.meshPipelines) gpu.describe(p)];
		var flats = [
			for (i in 0...descs.length)
				if (descs[i].buffers[1].stride == 144 && descs[i].buffers[0].attributes.length == 2) i
		];
		check(flats.length == 2, "One silhouette draw and one outline draw");
		var behind = descs[flats[0]], shell = descs[flats[1]];
		check(behind.depthTest == Greater && !behind.depthWrite && behind.cull == Back && behind.blend == Alpha, "The silhouette: only where hidden, blended");
		check(shell.depthTest == LessEqual && shell.depthWrite && shell.cull == Front && shell.blend == Opaque,
			"The outline: front faces culled, depth tested and written");
		check(flats[0] == descs.length - 3 && flats[1] == descs.length - 1, "The silhouette before its model, the outlines after every opaque model");
		check(gpu.meshDraws[flats[1]].instances == 2, "Alike outlines of models next to each other in the draw are one instanced draw");
		check(near(gpu.meshDraws[flats[1]].uniforms[0].getFloat(64), .05), "The outline's width pushes its shell out");
		var color = gpu.meshDraws[flats[0]].uniforms[1];
		check(near(color.getFloat(0), 0x3f / 255) && near(color.getFloat(12), 0x99 / 255), "The silhouette's color as it is, sRGB rgba");
		outlines[0].enabled = false;
		check(silhouette.remove() && !silhouette.remove() && seen.passCount == 0, "A pass is taken off its model once");
		gpu.meshDraws = [];
		gpu.meshPipelines = [];
		gpu.beginFrame(800, 600, 0);
		stage.draw(camera);
		var count = 0;
		for (p in gpu.meshPipelines)
			if (gpu.describe(p).cull == Front)
				count++;
		check(count == 1 && gpu.meshDraws[gpu.meshDraws.length - 1].instances == 1, "A pass not enabled isn't drawn");
		outlines[1].width = -1;
		check(outlines[1].width == 0, "A width held to 0 or more");
	}

	// A pass's vertices: each normal averaged over the vertices at its position, so an outline's shell stays closed at a hard edge; drawn
	// from their own buffer, static or skinned.
	static function passVertices(gpu:CountingGraphics):Void {
		var cube = Mesh3D.cube(1, 1, 1), data = cube.passVertices, corners = true, kept = true;
		var third = 1 / Math.sqrt(3);
		for (i in 0...cube.vertexCount) {
			var at = i * Flat3DProgram.stride, lit = i * Lit3DProgram.stride;
			for (c in 0...3) {
				var p = data.getFloat(at + Flat3DProgram.positionOffset + c * 4),
					n = data.getFloat(at + Flat3DProgram.normalOffset + c * 4);
				kept = kept && p == cube.vertices.getFloat(lit + Lit3DProgram.positionOffset + c * 4);
				corners = corners && Math.abs(Math.abs(n) - third) < 1e-6 && (n > 0) == (p > 0);
			}
		}
		check(cube.vertexCount == 24 && kept, "A pass's vertices keep the mesh's positions, one a vertex");
		check(corners, "A cube's three faces at a corner share one normal there, out along the diagonal: its shell doesn't crack");
		check(cube.passVertices == data, "Worked out once");
		var sphere = Mesh3D.sphere(.5), smooth = true;
		for (i in 0...sphere.vertexCount)
			for (c in 0...3)
				smooth = smooth
					&& Math.abs(sphere.passVertices.getFloat(i * Flat3DProgram.stride + Flat3DProgram.normalOffset + c * 4)
						- sphere.vertices.getFloat(i * Lit3DProgram.stride + Lit3DProgram.normalOffset + c * 4)) < 1e-5;
		check(smooth, "A smooth mesh's normals stay as they are");
		// Two faces back to back at the same place: their normals cancel, so each keeps its own.
		var sheet = Mesh3D.fromArrays([0., 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0], [0., 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, -1, 0, 0, -1, 0, 0, -1],
			null, null, null);
		check(near(sheet.passVertices.getFloat(Flat3DProgram.normalOffset + 8), 1)
			&& near(sheet.passVertices.getFloat(3 * Flat3DProgram.stride + Flat3DProgram.normalOffset + 8), -1),
			"Normals cancelling out leave each vertex its own");

		var stage = new Renderer3D(gpu),
			camera = new Camera3D(),
			material = new Material3D();
		camera.setViewport(800, 600);
		camera.setView(1, 0, 5, 1, 0, 0);
		var model = skinnedModel(stage, material);
		new Outline(model);
		gpu.meshDraws = [];
		gpu.meshPipelines = [];
		gpu.beginFrame(800, 600, 0);
		stage.draw(camera);
		var lit = gpu.meshDraws[0],
			shell = gpu.meshDraws[gpu.meshDraws.length - 1],
			desc = gpu.describe(gpu.meshPipelines[gpu.meshPipelines.length - 1]);
		check(desc.cull == Front && desc.buffers.length == 3 && desc.buffers[0].stride == Flat3DProgram.stride,
			"A skinned outline reads its pass vertices, its records and its skin");
		check(shell.buffers.length == 3
			&& shell.buffers[0] == model.mesh.getPassVertexBuffer(gpu)
			&& shell.buffers[0] != lit.buffers[0]
			&& shell.buffers[1] == lit.buffers[1]
			&& shell.buffers[2] == lit.buffers[2],
			"From the mesh's pass vertex buffer, beside the lit draw's records and skin");
	}
}
