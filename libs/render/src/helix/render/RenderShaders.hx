package helix.render;

#if macro
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import helix.platform.ShaderSource;
import helix.services.shaders.Shader;
import helix.services.shaders.ShaderBuildOptions;
import helix.services.shaders.ShaderMacros;
import helix.services.shaders.ShaderSharedBlock;
import sys.FileSystem;
import sys.io.File;

using StringTools;
#end

/** helix-render's build-time shader work, which the compile macros of `Batch2D`, `Batch3D` and `Material3D` call: its own stages given in
	the form of the program's, its includes added, the `View` block shared where a shader declares it, a fragment stage wrapped so the
	clip planes cut it, every shader compiled with `clipScale` and `points`, and the names helix-render fills checked for their types. */
@:noCompletion
class RenderShaders {
	/** Compiles one of helix-render's own pairs of stages, beside this file, as every helix-render shader is compiled. */
	public static macro function compileOwn(vertex:String, fragment:String):ExprOf<helix.services.shaders.Shader> {
		var pos = Context.currentPos();
		return make(own(vertex), own(fragment), {}, pos);
	}

	#if macro
	/** The includes helix-render gives, by the name an angle-bracket include takes. */
	public static final INCLUDES = [
		"view.glsl",
		"clip.glsl",
		"color.glsl",
		"batch.glsl",
		"mesh.glsl",
		"lighting.glsl",
		"material.glsl"
	];

	/** Each name helix-render fills, with the GLSL type it is declared with, so a shader declaring one with another type stops the build. */
	static final NAMES = [
		"vertexPosition" => "vec3",
		"vertexTexCoord" => "vec2",
		"vertexNormal" => "vec3",
		"vertexColor" => "vec4",
		"vertexCustomData" => "vec4",
		"vertexCorner" => "vec2",
		"vertexLineEnd" => "vec3",
		"vertexTangent" => "vec4",
		"vertexTexCoord2" => "vec2",
		"vertexJoints" => "vec4",
		"vertexWeights" => "vec4",
		"instanceModel" => "mat4",
		"instanceColor" => "vec4",
		"model" => "mat4",
		"normalMatrix" => "mat4",
		"modelViewProjection" => "mat4",
		"baseColor" => "vec4",
		"fontKind" => "int",
		"lineWidth" => "float",
		"pointSize" => "float",
		"pointSizeAttenuated" => "int",
		"clipPlanes" => "vec4",
		"clipPlaneCount" => "int",
		"fogged" => "int",
		"toneMapped" => "int",
		"skinned" => "int",
		"boneOffset" => "int",
		"morphTargetCount" => "int",
		"morphWeights" => "vec4",
		"boneMatrices" => "mat4",
		"textureTransform" => "mat3",
		"viewMatrix" => "mat4",
		"projectionMatrix" => "mat4",
		"viewProjection" => "mat4",
		"cameraPosition" => "vec4",
		"viewportSize" => "vec4",
		"linearTarget" => "int",
		"exposure" => "float",
		"toneMapping" => "int",
		"fogColor" => "vec4",
		"fogParams" => "vec4",
		"emissiveColor" => "vec4",
		"specularColor" => "vec4",
		"sheenColor" => "vec4",
		"metallic" => "float",
		"roughness" => "float",
		"normalScale" => "float",
		"alphaCutoff" => "float",
		"occlusionIntensity" => "float",
		"lightIntensity" => "float",
		"environmentIntensity" => "float",
		"specularIntensity" => "float",
		"shininess" => "float",
		"ior" => "float",
		"clearcoat" => "float",
		"clearcoatRoughness" => "float",
		"sheenRoughness" => "float",
		"shading" => "int",
		"fog" => "int",
		"flatShading" => "int",
		"vertexColors" => "int",
		"colorSpaceSrgb" => "int",
		"lightCount" => "int",
		"lightPositions" => "vec4",
		"lightDirections" => "vec4",
		"lightColors" => "vec4",
		"lightCones" => "vec4",
		"receiveShadows" => "int",
		"ambientLight" => "vec4",
		"environmentIrradiance" => "vec4",
		"environmentParams" => "vec4",
		"shadowMatrices" => "mat4",
		"shadowParams" => "vec4",
		"shadowColors" => "vec4",
		"shadowCascadeSplits" => "vec4"
	];

	/** The textures helix-render binds, each a 2D texture. */
	static final TEXTURES = [
		"baseColorTexture",
		"alphaTexture",
		"metallicRoughnessTexture",
		"normalTexture",
		"occlusionTexture",
		"lightTexture",
		"emissiveTexture",
		"boneTexture",
		"morphTexture",
		"brdfTexture"
	];

	/** One of helix-render's own shader files, in helix/render/shaders/. */
	public static function own(name:String):{name:String, text:String} {
		var path = Context.resolvePath('helix/render/shaders/$name');
		return {name: FileSystem.fullPath(path), text: File.getContent(path)};
	}

	/** A program's file, relative to the file holding the call. */
	public static function file(path:String, pos:Position):{name:String, text:String} {
		return ShaderMacros.file(path, pos);
	}

	/** `compileShader`: a fragment stage over helix-render's vertex stage of a kind (`batch.vert`, `mesh.vert`). */
	public static function fragmentOver(vertex:String, fragment:String, options:Null<Expr>):Expr {
		var pos = Context.currentPos();
		var f = file(fragment, pos);
		var v = own(vertex);
		v = {name: v.name, text: inForm(v.text, f.text)};
		return make(v, f, ShaderMacros.buildOptions(options, pos), pos);
	}

	/** `compileShaderStages`: both stages the program's. */
	public static function stages(vertex:String, fragment:String, options:Null<Expr>):Expr {
		var pos = Context.currentPos();
		return make(file(vertex, pos), file(fragment, pos), ShaderMacros.buildOptions(options, pos), pos);
	}

	/** `Batch3D.makeShaderExpr`: a shader for helix-render from two stages' text, with what helix-render sets itself. */
	public static function make(vertex:{name:String, text:String}, fragment:{name:String, text:String}, options:ShaderBuildOptions, pos:Position):Expr {
		var includes = new Map<String, String>();
		if (options.includes != null)
			for (name => text in options.includes) {
				if (INCLUDES.indexOf(name.replace("helix/render/shaders/", "")) >= 0 && name.startsWith("helix/render/shaders/"))
					Context.error('helix-render: the include $name is helix-render\'s own; give the text under another name', pos);
				includes.set(name, text);
			}
		for (name in INCLUDES)
			includes.set('helix/render/shaders/$name', own(name).text);
		// View and Lighting are shared wherever the compiled shader declares them: the compiler decides, not the text.
		var shared:Array<ShaderSharedBlock> = options.shared == null ? [] : options.shared.copy();
		for (block in ["View", "Lighting"])
			if (!Lambda.exists(shared, s -> s.name == block))
				shared.push({name: block, whereDeclared: true});
		var given = options.check;
		var lit = false;
		// Compiled once as written, so the clip planes' wrap is decided from what the stages pass (their reflection), then again wrapped.
		var probe = ShaderMacros.compileProgram(vertex, fragment, {
			defines: options.defines,
			includes: includes,
			includeDirectories: options.includeDirectories,
			shared: shared,
			clipScale: true,
			points: true
		}, [], pos);
		var made = Shader.makeExpr(vertex, {name: fragment.name, text: wrapClip(probe, fragment.text)}, {
			defines: options.defines,
			includes: includes,
			includeDirectories: options.includeDirectories,
			shared: shared,
			clipScale: true,
			points: true,
			check: shader -> {
				if (shader.hasSharedBlock("Lighting"))
					lit = true;
				var why = given == null ? null : given(shader);
				why != null ? why : check(shader);
			},
			file: options.file
		}, pos);
		// A shader reading the lighting links it, as a light does.
		return lit ? macro @:pos(pos) {
			@:privateAccess helix.render.BatchLighting.install();
			$made;
		} : made;
	}

	/** Why a shader declares a name helix-render fills with another type than it fills, or null. */
	public static function check(shader:Shader):Null<String> {
		for (u in shader.uniforms) {
			var type = NAMES.get(u.name);
			if (type != null && (u.type : String) != type)
				return '${u.name} is declared a ${u.type}; helix-render fills it as a $type';
		}
		for (a in shader.attributes)
			if (a != null) {
				var type = NAMES.get(a.glslName);
				if (type != null && (a.type : String) != type)
					return 'the attribute ${a.glslName} is declared a ${a.type}; helix-render feeds it as a $type';
			}
		for (s in shader.samplers)
			if (TEXTURES.indexOf(s.name) >= 0 && s.kind != Texture2D && s.kind != Data)
				return '${s.name} is declared a ${s.kind} sampler; helix-render binds a 2D texture to it';
		return null;
	}

	// A stage's text with its version line the other stage's, so helix-render's stage is in the form of the program's.
	static function inForm(text:String, other:String):String {
		var version = ~/^[ \t]*#version[^\n]*/m;
		if (!version.match(other))
			return text;
		var line = version.matched(0);
		return version.replace(text, line);
	}

	// A fragment stage wrapped so the clip planes cut it before its main runs, where the vertex stage writes worldPosition: decided from
	// the stages' reflection (their outputs and inputs), never their text. Only the wrap itself, renaming main, edits the text.
	static function wrapClip(source:ShaderSource, fragment:String):String {
		var writes = Lambda.exists(source.vertexOutputs, v -> v.glslName == "worldPosition");
		var main = ~/\bvoid\s+main\s*\(\s*(?:void)?\s*\)/;
		if (!writes || !main.match(fragment))
			return fragment;
		var reads = Lambda.exists(source.fragmentInputs, v -> v.glslName == "worldPosition");
		return main.replace(fragment, "void helix_render_main()")
			+ "\n#include <helix/render/shaders/clip.glsl>\n"
			+ (reads ? "" : "in vec3 worldPosition;\n")
			+ "void main() {\n\tfor (int i = 0; i < 4; i++)\n\t\tif (i < clipPlaneCount && dot(clipPlanes[i].xyz, worldPosition) + clipPlanes[i].w < 0.0)\n"
			+ "\t\t\tdiscard;\n\thelix_render_main();\n}\n";
	}
	#end
}
