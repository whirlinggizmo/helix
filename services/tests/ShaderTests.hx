import haxe.io.Bytes;
import helix.math.Matrix3D;
import helix.platform.Sampling;
import helix.services.assets.Assets;
import helix.services.shaders.*;
import helix.services.tools.ShaderBlockCompiler;

/** Typed values for the quad, as `ShaderValueClasses.build` makes them. */
@:build(helix.services.tools.ShaderValueClasses.build("shaders/quad.vert", "shaders/quad.frag"))
class QuadValues extends ShaderValues {}

/** The lit shader's options, in one place. */
class Lit {
	/** Its features. */
	public static final FEATURES = ["SKINNED", "FOG"];

	/** Its shared blocks, the camera declared and the lights gathered, and its file. */
	public static final OPTIONS:ShaderVariantOptions = {
		shared: [{name: "Camera"}, {name: "Lights", uniforms: ["pointLights", "ambient"]}],
		file: "shaders/lit.shader"
	};
}

/** One lit variant's values, typed. */
@:build(helix.services.tools.ShaderValueClasses.buildVariants("shaders/lit.vert", "shaders/lit.frag", Lit.FEATURES, Lit.OPTIONS))
class LitValues extends ShaderValues {}

/** A lit material across the variants, typed. */
@:build(helix.services.tools.ShaderValueClasses.buildVariants("shaders/lit.vert", "shaders/lit.frag", Lit.FEATURES, Lit.OPTIONS, "LitValues"))
class LitMaterial extends ShaderVariantValues {}

/** The camera block, typed. */
@:build(helix.services.tools.ShaderValueClasses.buildBlock("LitValues.VARIANTS", "Camera"))
class CameraValues extends ShaderBlockValues {}

/** Checks helix-services' shaders over fake graphics and assets: compiled shaders' reflection and handles; values packed by std140
	(struct arrays, floats and integers together, colors, packed floats, refusals); layering over a base by reference and copy on write,
	scenes and snapshots; shared blocks and textures; variants and their features; typed classes; a reload through an asset change, values
	and handles following; pipelines held, built outside frames only, rebuilt after a reload; vertex layouts. */
@:access(helix.services.shaders)
class ShaderTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function throws(f:Void->Void, part:String, message:String):Void {
		var thrown:Null<String> = null;
		try
			f()
		catch (e:Dynamic)
			thrown = Std.string(e);
		check(thrown != null && thrown.indexOf(part) >= 0, '$message: ' + (thrown == null ? "nothing thrown" : thrown));
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-5;

	static final QUAD = Shader.compile("shaders/quad.vert", "shaders/quad.frag");

	static function main():Void {
		reflection();
		packing();
		layering();
		sharing();
		variants();
		typed();
		reload();
		programs();
		layouts();
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	static function reflection():Void {
		var s = QUAD;
		check(s == Shader.compile("shaders/quad.vert", "shaders/quad.frag"), "one shader for the same text and options");
		check([for (u in s.uniforms) u.name].join(",") == "offsetScale,tint,time,offsets,mode,bright,mask,lights.color,lights.on,turn,weights,cells",
			"every uniform, in block order: " + [for (u in s.uniforms) u.name]);
		var lights = s.getUniform("lights.color");
		check(lights.elementCount == 2 && lights.type == Vec3 && lights.blockName == "Look" && lights.active && lights.declared,
			"a struct array's field is one uniform");
		check(s.getUniform("tint") == s.getUniform("tint"), "the same handle each call");
		check(!s.getUniform("cells").type.integer == false && s.getUniform("bright").type == Bool && s.getUniform("mask").type == Uint,
			"integers, bools and uints reflected");
		throws(() -> s.getUniform("lights[0].color"), "getUniformPath", "a bracketed name points at getUniformPath");
		throws(() -> s.getUniform("missing"), "tint", "an unknown name lists what is declared");
		check(s.findUniform("missing") == null && !s.hasUniform("missing") && s.hasUniform("tint"), "find and has");
		var path = s.getUniformPath("lights[1].color");
		check(path.uniform == lights && path.elementIndex == 1 && s.getUniformPath("lights[1].color") == path, "a path, once");
		check(s.findUniformPath("lights[2].color") == null && s.findUniformPath("lights[1]") == null && s.findUniformPath("image") == null,
			"no path past the end, to a struct, or to a sampler");
		var place = s.findUniformPlace(s.getUniform("offsetScale"));
		check(place.blockSlot == 0 && place.offset == 0, "a uniform's place");
		check(s.getSampler("image").kind == Texture2D
			&& s.getSampler("sky").kind == Cube
			&& s.getSampler("table").kind == Data
			&& s.getSampler("sky").slot == 1,
			"samplers' kinds and slots");
		var a = s.getAttribute("texCoord");
		check(a.slot == 1 && a.type == Vec2 && a.active && !s.getAttribute("unread").active, "attributes, read and unread");
		var buffer = s.computeVertexBuffer(["position", "texCoord"]);
		check(buffer.stride == 16 && buffer.attributes[1].slot == 1 && buffer.attributes[1].offset == 8, "a vertex buffer built for the shader");
		throws(() -> s.computeVertexBuffer(["nothing"]), "nothing", "a buffer naming an attribute not declared");
		check(s.computeUnfedAttributes([buffer]).map(a -> a.glslName).join(",") == "unread", "the unfed attributes listed");
		var reserved = s.reserveUniform("later");
		check(!reserved.declared
			&& s.reserveUniform("later") == reserved
			&& s.findUniform("later") == null, "a reserved handle, not declared");
		var renamed = s.withNames(["tint" => "baseColor", "texCoord" => "uv0", "lights" => "lamps"]);
		check(renamed.getUniform("baseColor").type == Vec4
			&& renamed.findUniform("tint") == null
			&& renamed.getAttribute("uv0").slot == 1
			&& renamed.hasUniform("lamps.color"),
			"renamed: found by the new names, struct paths too");
		throws(() -> s.withNames(["tint" => "time"]), "time", "a new name another has refused");
	}

	static function packing():Void {
		var s = QUAD;
		var v = new ShaderValues(s);
		var look = s.blocks[1];
		check(look.name == "Look" && look.size == 256 && look.indices.join(",") == "5", "the fragment block at 4 + its slot");
		v.writeColor(s.getUniform("tint"), 0x80ff4000);
		v.writeFloat(s.getUniform("time"), 2.5);
		v.writeVector2(s.getUniform("offsets"), .25, -.5, 3);
		v.writeInt(s.getUniform("mode"), -3);
		v.writeBool(s.getUniform("bright"), true);
		v.writeInt(s.getUniform("mask"), 0xffffffff);
		v.writeVector3(s.getUniform("lights.color"), 1, .5, .25, 1);
		v.writeInt(s.getUniform("lights.on"), 1, 1);
		v.writeFloats(s.getUniform("turn"), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
		v.writeFloats(s.getUniform("weights"), [.5, .75], 1);
		v.writeInts(s.getUniform("cells"), [7, 9]);
		var b = v.uniforms[5];
		check(v.uniforms.length == 6 && v.uniforms[0] != null && v.uniforms[1] == null && b.length == 256, "uniforms by stage and slot");
		check(near(b.getFloat(0), 1) && near(b.getFloat(4), 64 / 255) && b.getFloat(8) == 0 && near(b.getFloat(12), 128 / 255),
			"writeColor: 0xAARRGGBB's channels over 255");
		check(b.getFloat(16) == 2.5 && b.getFloat(32 + 3 * 16) == .25 && b.getFloat(32 + 3 * 16 + 4) == -.5, "a float and an array's element at its stride");
		check(b.getInt32(96) == -3 && b.getInt32(100) == 1 && b.getInt32(104) == -1, "an int, a bool as 1, a uint's bits");
		check(b.getFloat(128) == 1 && b.getFloat(132) == .5 && b.getFloat(136) == .25 && b.getInt32(140) == 1, "an array of structs' fields");
		check(b.getFloat(144) == 1 && b.getFloat(152) == 3 && b.getFloat(160) == 4 && b.getFloat(176 + 8) == 9, "a mat3 a column every 16 bytes");
		check(b.getFloat(192 + 16) == .5 && b.getFloat(192 + 32) == .75 && b.getInt32(240) == 7 && b.getInt32(244) == 9,
			"packed floats into their elements, ints into an ivec2");
		throws(() -> v.writeFloat(s.getUniform("tint"), 1), "writeFloat", "a value of the wrong kind refused");
		throws(() -> v.writeFloats(s.getUniform("weights"), [1, 2, 3], 1), "past", "a write past the end refused");
		check(b.getFloat(192 + 16) == .5, "writing nothing");
		throws(() -> v.writeVector2(s.getUniform("offsets"), 0, 0, 4), "no element 4", "an element past the end refused");
		throws(() -> v.write(s.getUniform("tint"), Texture(1)), "sampler", "a texture value refused for a uniform");
		v.writeRgb(s.getUniform("tint"), 0x00ff00);
		check(near(b.getFloat(4), 1) && b.getFloat(0) == 0 && near(b.getFloat(12), 128 / 255), "writeRgb keeps a vec4's alpha");
		v.writeLinearRgb(s.getUniform("tint"), 0x808080, 2);
		check(near(b.getFloat(0), 2 * Math.pow((128 / 255 + .055) / 1.055, 2.4)), "writeLinearRgb decodes sRGB and scales");
		v.write(s.getUniform("offsetScale"), Vector(1, 2, 3, 4));
		check(v.uniforms[0].getFloat(12) == 4, "a value held as data");
		var m = new Matrix3D();
		check(m.values.length == 16, "a matrix's values");
		v.writeTexture(s.getSampler("image"), 42, Sampling.NEAREST);
		check(v.textures.join(",") == "42,0,0" && v.samplings[0] == Sampling.NEAREST && v.samplings[1] == Sampling.LINEAR, "textures and samplings by slot");
		v.writeSamplerValue(s.getSampler("sky"), Texture(7));
		check(v.textures[1] == 7, "a sampler from a value held as data");
		var later = s.reserveUniform("later");
		v.writeFloat(later, 3);
		check(v.uniforms[5] == b, "a write through a handle not declared is kept, writing nothing");
		check(v.uniforms == v.uniforms && v.textures == v.textures, "the arrays kept, not made again");
	}

	static function layering():Void {
		var s = QUAD;
		var tint = s.getUniform("tint"),
			time = s.getUniform("time"),
			offset = s.getUniform("offsetScale");
		var defaults = new ShaderValues(s);
		defaults.writeVector(offset, 0, 0, 1, 1);
		var material = new ShaderValues(s, defaults);
		check(material.uniforms[0] == defaults.uniforms[0], "a block not written read by reference");
		defaults.writeVector(offset, 1, 1, 1, 1);
		check(material.uniforms[0].getFloat(0) == 1, "the base read live");
		material.writeColor(tint, 0xffffffff);
		check(material.uniforms[5] != defaults.uniforms[5], "the first write copies the block");
		defaults.writeFloat(time, 9);
		check(material.uniforms[5].getFloat(16) == 9 && material.uniforms[5].getFloat(0) == 1, "the base's other uniforms reach the copy");
		defaults.writeColor(tint, 0xff000000);
		check(material.uniforms[5].getFloat(0) == 1, "a uniform written stays the written one");
		var drawn = new ShaderValues(s);
		drawn.writeVector(offset, 5, 5, 5, 5);
		drawn.base = material;
		check(drawn.uniforms[5] == material.uniforms[5] && drawn.uniforms[0].getFloat(0) == 5, "a draw's values over a material");
		var other = new ShaderValues(s, defaults);
		other.writeFloat(time, 4);
		drawn.base = other;
		check(drawn.uniforms[5].getFloat(16) == 4 && drawn.uniforms[0].getFloat(0) == 5, "a base set again, what the draw wrote kept");
		throws(() -> drawn.base = new ShaderValues(Shader.compile("shaders/quad.vert", "shaders/quad.frag", {defines: ["OTHER"]})), "another shader",
			"a base of another shader refused");
		material.deleteValue(tint);
		check(material.uniforms[5] == defaults.uniforms[5], "a value removed: the base's again");
		var snapshot = new ShaderSnapshot();
		drawn.capture(snapshot);
		var kept = snapshot.uniforms[0];
		drawn.writeVector(offset, 6, 6, 6, 6);
		check(snapshot.uniforms[0].getFloat(0) == 5, "a snapshot is a copy");
		drawn.capture(snapshot);
		check(snapshot.uniforms[0] == kept && kept.getFloat(0) == 6, "its bytes reused");
		defaults.writeTexture(s.getSampler("image"), 3);
		var shared = new ShaderSharedTexture(8);
		check(material.textures[0] == 3, "a base's texture");
		material.shareTexture(s.getSampler("image"), shared);
		shared.texture = 9;
		check(material.textures[0] == 9, "a shared texture, changed, seen");
		material.unshareTexture(s.getSampler("image"));
		check(material.textures[0] == 3, "unshared: the base's again");
		var scene = new ShaderScene();
		scene.shareTexture("sky", new ShaderSharedTexture(11));
		material.scene = scene;
		check(material.textures[1] == 11 && drawn.textures[1] == 0, "a scene's texture where nothing else gives one");
		drawn.base = material;
		check(drawn.scene == scene && drawn.textures[1] == 11, "the scene through the base");
		material.deleteValues();
		check(material.uniforms[5] == defaults.uniforms[5] && material.textures[0] == 3, "every value removed");
	}

	static function sharing():Void {
		var lit = LitValues.VARIANTS;
		var plain = lit.getShader(ShaderFeatures.NONE);
		var camera = plain.blockNamed("Camera"),
			lights = plain.blockNamed("Lights"),
			rest = plain.blockNamed("helix_uniforms");
		check(camera.shared && camera.stage == "both" && lights.shared && lights.stage == "both" && !rest.shared, "shared blocks, both stages'");
		check([for (m in lights.members) m.glslName].join(",") == "pointLights.position,pointLights.range,pointLights.color,ambient",
			"gathered in the order given");
		var values = new ShaderValues(plain);
		throws(() -> values.uniforms, "Camera", "a shared block shared nowhere refused at the read");
		throws(() -> values.writeMatrix(lit.getUniform("viewProjection"), new Matrix3D()), "shared block", "a shared uniform written on values refused");
		var block = new ShaderBlockValues(lit, "Camera");
		var lightBlock = ShaderBlockCompiler.compile("shaders/lights.glsl", "Lights", ["pointLights", "ambient"]);
		var scene = new ShaderScene();
		scene.shareBlock(block);
		scene.shareBlock(lightBlock);
		values.scene = scene;
		block.writeVector(lit.getUniform("eye"), 1, 2, 3, 4);
		check(values.uniforms[camera.slot] == block.bytes
			&& values.uniforms[4 + camera.slot] == block.bytes, "the block's bytes, at both indices");
		check(block.bytes.getFloat(64 + 12) == 4, "written on the block");
		check(scene.findSharedBlockOf(lit.getUniform("eye")) == block && scene.findSharedBlockOf(lit.getUniform("baseColor")) == null,
			"a shared uniform's block through the scene");
		lightBlock.writeColor(lit.getUniform("pointLights.color"), 0xffffffff, 2);
		check(values.uniforms[lights.slot].getFloat(2 * 32 + 16) == 1, "a block made from its declaration alone, shared");
		var lightCamera = new CameraValues();
		lightCamera.setEye(9, 9, 9, 9);
		var shadowScene = new ShaderScene();
		shadowScene.shareBlock(lightCamera);
		shadowScene.shareBlock(lightBlock);
		values.scene = shadowScene;
		check(values.uniforms[camera.slot].getFloat(64) == 9, "a scene swapped: the other camera");
		values.shareBlock(block);
		check(values.uniforms[camera.slot] == block.bytes
			&& values.findSharedBlock("Camera") == block, "a block shared on the values first");
		throws(() -> values.shareBlock(new ShaderBlockValues(QUAD_SHARED, "Look")), "no shared block", "a block the shader doesn't share refused");
		throws(() -> new ShaderBlockValues(QUAD, "Look"), "no shared block", "a block not shared can't be a shared block's");
		throws(() -> block.writeFloat(lit.getUniform("roughness"), 1), "isn't in", "a handle outside the block refused");
	}

	static final QUAD_SHARED = Shader.compile("shaders/quad.vert", "shaders/quad.frag", {shared: [{name: "Look"}]});

	static function variants():Void {
		var lit = LitValues.VARIANTS;
		check(lit.featureNames.join(",") == "SKINNED,FOG" && lit.shaders.length == 4, "every combination of two features");
		check(lit.getFeature("FOG") == LitValues.FOG && (LitValues.SKINNED | LitValues.FOG) == lit.getFeatures(["FOG", "SKINNED"]),
			"features as bits, the constants too");
		check(lit.computeFeatureNames(LitValues.SKINNED | LitValues.FOG).join(",") == "SKINNED,FOG", "a combination's names");
		var skinned = lit.getShader(LitValues.SKINNED);
		check(skinned.hasUniform("boneMatrices")
			&& !lit.getShader(ShaderFeatures.NONE).hasUniform("boneMatrices")
			&& lit.hasUniform("boneMatrices"),
			"a feature's uniforms in its variants");
		check(skinned.getAttribute("joints").slot == 3 && lit.getAttribute("joints") != null, "its attributes");
		throws(() -> lit.getFeature("SHADOWS"), "SHADOWS", "an unknown feature refused");
		var set = ShaderFeatures.NONE.with(LitValues.SKINNED).switched(LitValues.FOG, true).toggled(LitValues.SKINNED);
		check(set == LitValues.FOG && set.hasFeatures(LitValues.FOG) && !set.hasFeatures(LitValues.SKINNED), "features combined");
		var defaults = new ShaderVariantValues(lit);
		defaults.writeFloat(lit.getUniform("roughness"), .5);
		// Shared on the defaults, every material over them reads them.
		defaults.shareBlock(new ShaderBlockValues(lit, "Camera"));
		defaults.shareBlock(new ShaderBlockValues(lit, "Lights"));
		var red = new ShaderVariantValues(lit, defaults);
		red.writeColor(lit.getUniform("baseColor"), 0xffff0000);
		red.writeVector3(lit.getUniform("fogColor"), 1, 1, 1);
		var plain = red.getValues(ShaderFeatures.NONE);
		check(red.getValues(ShaderFeatures.NONE) == plain
			&& plain.base == defaults.getValues(ShaderFeatures.NONE), "a variant's values over the base's");
		var block = plain.shader.blockNamed("helix_uniforms");
		var bytes = plain.uniforms[block.slot];
		var place = plain.shader.placesOf(lit.getUniform("baseColor"))[0],
			rough = plain.shader.placesOf(lit.getUniform("roughness"))[0];
		check(bytes.getFloat(place.offset) == 1 && bytes.getFloat(rough.offset) == .5, "what was written before, in a variant made after");
		red.writeColor(lit.getUniform("baseColor"), 0xff00ff00);
		check(plain.uniforms[block.slot].getFloat(place.offset) == 0, "a write after reaches the variant made");
		var fog = red.getValues(LitValues.FOG);
		var fogPlace = fog.shader.placesOf(lit.getUniform("fogColor"))[0];
		check(fog.uniforms[fog.shader.blockNamed("helix_uniforms").slot].getFloat(fogPlace.offset) == 1, "a value a variant lacks, kept for one with it");
		throws(() -> lit.getShader(1 << 3), "no variant", "a combination not compiled refused");
		check(lit.findShader(1 << 3) == null, "or not found");
	}

	static function typed():Void {
		var defaults = new QuadValues();
		defaults.setOffsetScale(0, 0, 1, 1);
		defaults.setTintArgb(0xffffffff);
		var quad = new QuadValues(defaults);
		quad.setTime(2);
		quad.setOffsets(2, .5, .5);
		quad.setLightsColor(1, 1, 0, 0);
		quad.setLightsOn(1, 1);
		quad.setBright(true);
		quad.setCells(1, 2);
		quad.setTurn([1, 0, 0, 0, 1, 0, 0, 0, 1]);
		quad.setImage(5);
		check(quad.uniforms[5].getFloat(16) == 2 && quad.uniforms[5].getFloat(0) == 1 && quad.textures[0] == 5, "a typed class's members");
		check(QuadValues.SHADER == QUAD, "its SHADER the program's one shader for the files");
		var material = new LitMaterial();
		material.setBaseColorArgb(0xff0000ff);
		material.setRoughness(.25);
		material.setBaseColorTexture(3);
		var typed:LitValues = material.getValues(LitValues.SKINNED);
		var drawn = new LitValues(LitValues.SKINNED);
		drawn.base = typed;
		drawn.setModel(new Matrix3D());
		drawn.setBoneMatrices(2, new Matrix3D());
		check(typed.textures[0] == 3 && LitMaterial.SKINNED == LitValues.SKINNED, "typed per-variant values from a material class");
		var camera = new CameraValues();
		camera.setViewProjection(new Matrix3D());
		camera.setEye(0, 0, 0, 1);
		check(camera.bytes.getFloat(0) == 1 && camera.bytes.getFloat(76) == 1, "a typed shared block");
	}

	static function reload():Void {
		var files = new FakeFileSystem();
		var assets = new Assets({sources: [FileSystem(files)]});
		var shaders = new Shaders(assets);
		var s = Shader.compile("shaders/quad.vert", "shaders/quad.frag", {file: "shaders/quad.shader"});
		check(s.filePath == "shaders/quad.shader" && s != QUAD, "a shader with a file is another shader");
		throws(() -> shaders.watch(QUAD), "ShaderOptions.file", "a shader without a file can't be watched");
		var stop = shaders.watch(s);
		check(shaders.watch(s) == stop, "watching twice is watching once");
		var values = new ShaderValues(s);
		var tint = s.getUniform("tint"), time = s.getUniform("time");
		values.writeColor(tint, 0xffffffff);
		values.writeFloat(time, 3);
		var heard = 0;
		s.reloadListeners.push(_ -> heard++);
		// The new program: the fragment stage's block without time, with a new member first.
		var next = Shader.compile("shaders/quad.vert", "shaders/quad2.frag");
		files.files.set("shaders/quad.shader", Bytes.ofString(haxe.Json.stringify({kind: "shader", source: next.source, shared: []})));
		assets.notifyChanged("shaders/quad.shader");
		for (_ in 0...4)
			files.poll();
		check(s.reloadCount == 0, "nothing replaced before the frame's start");
		shaders.prepareFrame();
		check(s.reloadCount == 1 && heard == 1 && s.reloadError == null, "replaced at prepareFrame, its listeners called");
		check(!time.declared && tint.declared && s.getUniform("tint") == tint, "handles follow: one gone, one kept");
		var place = s.placesOf(tint)[0];
		check(values.uniforms[5].getFloat(place.offset) == 1 && place.offset != 0, "values packed again into the new layout");
		values.writeFloat(time, 4);
		files.files.set("shaders/quad.shader", Bytes.ofString(haxe.Json.stringify({kind: "shader", source: QUAD.source, shared: []})));
		assets.notifyChanged("shaders/quad.shader");
		for (_ in 0...4)
			files.poll();
		shaders.prepareFrame();
		check(time.declared && values.uniforms[5].getFloat(16) == 4, "a uniform brought back gets the value kept for it");
		files.files.set("shaders/quad.shader", Bytes.ofString("not a shader"));
		assets.notifyChanged("shaders/quad.shader");
		for (_ in 0...4)
			files.poll();
		shaders.prepareFrame();
		check(s.reloadCount == 2 && s.reloadError != null, "a file that doesn't read: the shader as it was, reloadError saying why");
		stop();
		var loaded:Null<Shader> = null;
		files.files.set("mods/quad.shader", Bytes.ofString(haxe.Json.stringify({kind: "shader", source: QUAD.source, shared: []})));
		shaders.load("mods/quad.shader", shader -> loaded = shader);
		check(loaded == null, "a load answers later");
		for (_ in 0...4)
			files.poll();
		check(loaded != null && loaded.hasUniform("tint") && loaded.filePath == "mods/quad.shader", "a shader that is only a file, loaded");
		var failure:Null<String> = null;
		shaders.loadVariants("mods/quad.shader", _ -> {}, message -> failure = message);
		for (_ in 0...4)
			files.poll();
		check(failure != null && failure.indexOf("not a file of variants") >= 0, "one shader where variants were refused");
	}

	static function programs():Void {
		var graphics = new FakeGraphics();
		var programs = new ShaderPrograms(graphics);
		var s = Shader.compile("shaders/quad.vert", "shaders/quad.frag", {file: "shaders/quad-programs.shader", clipScale: true});
		var layout = ShaderVertexLayout.fromAttributes(s, ["position", "texCoord"]);
		var state = ShaderPipelineState.CLIP_SCALE.with({cull: None});
		var pipeline = programs.getPipeline(s, state, layout);
		check(pipeline.handle != 0 && pipeline.buildCount == 1 && graphics.shaderCount == 1, "a pipeline built the first time");
		check(programs.getPipeline(s, state, ShaderVertexLayout.fromAttributes(s, ["position", "texCoord"])) == pipeline
			&& programs.getPipeline(s, ShaderPipelineState.CLIP_SCALE.with({
				cull: None
			}), layout) == pipeline, "the same for the same values");
		var desc = graphics.pipelines.get(pipeline.handle);
		var place = s.findUniformPlace(s.getUniform("helix_clipScale"));
		check(desc.flip == ClipScale && desc.flipBlockSlot == place.blockSlot && desc.flipOffset == place.offset, "the flip at its place");
		check(desc.attributeConstants.length == 0 && desc.buffers[0].attributes.length == 2, "the layout resolved");
		var dots = Shader.compile("shaders/quad.vert", "shaders/quad.frag", {clipScale: true, points: true});
		check(dots.source.points == true && s.source.points != true, "the point size written when asked, and only then");
		var dotted = programs.getPipeline(dots, state.with({primitive: Points}), ShaderVertexLayout.fromAttributes(dots, ["position", "texCoord"]));
		check(graphics.pipelines.get(dotted.handle).primitive == Points, "a points pipeline over it");
		throws(() -> programs.getPipeline(s, ShaderPipelineState.OPAQUE, layout), "viewProjection", "a flip uniform the shader lacks refused");
		programs.prepareFrame();
		throws(() -> programs.getPipeline(s, ShaderPipelineState.ALPHA.with({flip: None}), layout), "inside a frame", "no first build inside a frame");
		check(programs.findPipeline(s, ShaderPipelineState.ALPHA, layout) == null && programs.getPipeline(s, state, layout) == pipeline,
			"one built found inside a frame");
		programs.finishFrame();
		// A replacement: rebuilt at the next frame's start, the old drawing till then.
		var old = pipeline.handle;
		s.replace(Shader.compile("shaders/quad.vert", "shaders/quad2.frag", {clipScale: true}).source);
		check(pipeline.handle == old, "the old pipeline until the frame's start");
		programs.prepareFrame();
		check(pipeline.handle != old && pipeline.buildCount == 2 && !graphics.pipelines.exists(old), "rebuilt there, the old disposed");
		programs.finishFrame();
		graphics.refuseShaders = true;
		s.replace(Shader.compile("shaders/quad.vert", "shaders/quad.frag", {clipScale: true}).source);
		programs.prepareFrame();
		check(pipeline.buildError != null
			&& s.reloadError != null
			&& graphics.pipelines.exists(pipeline.handle), "a refused rebuild keeps the old");
		programs.disposeShader(s);
		check(pipeline.handle != 0, "a dispose inside a frame waits");
		programs.finishFrame();
		check(pipeline.handle == 0, "till the frame's finish");
		graphics.refuseShaders = false;
		check(programs.getPipeline(s, state, layout) == pipeline && pipeline.handle != 0, "built again, the same object");
		var lit = LitValues.VARIANTS;
		var mesh = new ShaderVertexLayout([
			{
				stride: 64,
				placements: [
					{name: "position", offset: 0},
					{name: "normal", offset: 12, optional: true},
					{name: "joints", offset: 24, optional: true},
					{name: "weights", offset: 40, optional: true}
				]
			}
		], [{name: "color", values: [1, 1, 1, 1]}]);
		var made = programs.prepareVariants(lit, [
			{features: ShaderFeatures.NONE, state: ShaderPipelineState.OPAQUE, layout: mesh},
			{features: LitValues.SKINNED, state: ShaderPipelineState.OPAQUE, layout: mesh}
		]);
		var plainDesc = graphics.pipelines.get(made[0].handle),
			skinnedDesc = graphics.pipelines.get(made[1].handle);
		check(plainDesc.buffers[0].attributes.length == 2 && skinnedDesc.buffers[0].attributes.length == 4,
			"optional placements a variant doesn't read left out");
		check(plainDesc.attributeConstants.length == 1 && plainDesc.attributeConstants[0].values[3] == 1, "an unfed attribute's constant");
		programs.dispose();
		check(Lambda.count(graphics.shaders) == 0, "every program disposed");
	}

	static function layouts():Void {
		var s = QUAD;
		var layout = new ShaderVertexLayout([
			{
				stride: 20,
				placements: [
					{slot: 0, offset: 0},
					{name: "texCoord", offset: 8},
					{name: "normal", offset: 16, optional: true}
				]
			}
		]);
		var buffers = layout.computeBuffers(s);
		check(buffers[0].attributes.length == 2 && buffers[0].attributes[1].offset == 8, "by slot and by name, an optional one undeclared skipped");
		throws(() -> new ShaderVertexLayout([{stride: 8, placements: [{name: "normal", offset: 0}]}]).computeBuffers(s), "normal",
			"an undeclared placement not optional refused");
		throws(() -> new ShaderVertexLayout([{stride: 12, placements: [{name: "texCoord", offset: 8}]}]).computeBuffers(s), "runs past",
			"one past its stride refused");
		var short = new ShaderVertexLayout([{stride: 8, placements: [{name: "unread", offset: 0, format: Float2}]}]).computeBuffers(s);
		check(short[0].attributes[0].format == Float2, "fewer floats than the attribute takes");
		check(layout.computeBuffers(s)[0].attributes[1].format == Float2, "an attribute's own floats when no format is given");
		var bytes = new ShaderVertexLayout([{stride: 4, placements: [{name: "unread", offset: 0, format: UByte4Norm}]}]);
		check(bytes.computeBuffers(s)[0].attributes[0].format == UByte4Norm, "more components than the attribute takes, a format passed through");
		throws(() -> new ShaderVertexLayout([{stride: 4, placements: [{name: "unread", offset: 0, format: Short4Norm}]}]).computeBuffers(s), "runs past",
			"a format's bytes past its stride refused");
		var signed = new ShaderVertexLayout([{stride: 4, placements: [{name: "unread", offset: 0, format: Byte4Norm}]}]);
		check(bytes.key != signed.key, "the key tells two formats apart");
		check(new ShaderVertexLayout([{stride: 4, placements: [{name: "unread", offset: 0, format: UByte4Norm}]}]).key == bytes.key, "and finds the same one");
		var instanced = LitValues.VARIANTS.getShader(LitValues.SKINNED).computeVertexBuffer(["joints", "weights"], true);
		check(instanced.instanced && instanced.stride == 32, "an instanced buffer");

		// A matrix's constant spread over its columns' slots, four values apiece; none for a matrix a buffer feeds.
		var placed = Shader.compileText("#version 450
in vec2 position;
in mat4 placement;
in vec4 tint;
void main() { gl_Position = placement * vec4(position, 0.0, 1.0) * tint; }", "#version 450
layout(location = 0) out vec4 result;
void main() { result = vec4(1.0); }");
		var identity = [1., 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
		var unfed = new ShaderVertexLayout([{stride: 8, placements: [{name: "position", offset: 0}]}],
			[{name: "placement", values: identity}, {name: "tint", values: [1, 1, 1, 1]}]);
		var constants = unfed.computeConstants(placed, unfed.computeBuffers(placed));
		check(constants.length == 5
			&& [for (c in constants) c.slot].join(",") == "1,2,3,4,5"
			&& constants[2].values.join(",") == "0,0,1,0"
			&& constants[4].values.join(",") == "1,1,1,1",
			'a matrix\'s constant a column a slot: $constants');
		var fed = new ShaderVertexLayout([
			{stride: 72, placements: [{name: "position", offset: 0}, {name: "placement", offset: 8}]}
		], [{name: "placement", values: identity}]);
		var none = fed.computeConstants(placed, fed.computeBuffers(placed));
		check(none.length == 0, 'a matrix a buffer feeds left to it: $none');
	}
}
