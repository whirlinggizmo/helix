package helix.tools.shader;

import helix.tools.shader.JsonText;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import helix.tools.shared.CommandError;
import helix.tools.shared.Downloads;
import helix.tools.shared.Files;

/** SDL_GPU's shader dialects from a program's GLSL 410 (sokol-shdc's, with its layout): SPIR-V for Vulkan, MSL for Metal and HLSL (shader
	model 5.1) for Direct3D 12, each laid out as SDL_GPU binds resources. Metal compiles the MSL and Direct3D 12 the HLSL (as DXBC, through the
	system's d3dcompiler) when the program is made, so packing needs no Apple or Microsoft tool and gives the same output on every system.

	The GLSL is rewritten for Vulkan before compiling: version 450; each uniform block (a vec4 array, as sokol-shdc flattens it) a std140
	block, and each texture a combined sampler, at SDL_GPU's sets (vertex textures 0, vertex blocks 1, fragment textures 2, fragment blocks 3),
	numbered from 0 by slot within each; GL's clip depth (-1..1) moved to SDL_GPU's (0..1) after the vertex stage's main; gl_VertexID as
	gl_VertexIndex. glslang compiles it to SPIR-V and SPIRV-Cross translates that to MSL (each resource at its binding) and HLSL
	(register(xN, spaceS), SDL_GPU's).

	The tools, pinned in dependencies.json (gpuShaders) and kept in the user's cache (Downloads): glslang's official release for the system,
	checked against its SHA-256; SPIRV-Cross's source release, checked, built once by hxcpp with the system's compiler (it publishes no
	programs). HELIX_GLSLANG and HELIX_SPIRV_CROSS name the user's own instead. */
class GpuShaders {
	// SDL_GPU's descriptor sets: textures and uniform blocks, by stage.
	static final SETS = ["vertex" => {textures: 0, blocks: 1}, "fragment" => {textures: 2, blocks: 3}];

	/** dependencies.json's gpuShaders entry, of the library at root. */
	static function pin(root:String):Dynamic
		return haxe.Json.parse(File.getContent(Path.join([root, "dependencies.json"]))).gpuShaders;

	// This system's key in the glslang pin: linux, windows or macos (a universal program).
	static function system():String {
		return switch Sys.systemName() {
			case "Windows": "windows";
			case "Mac": "macos";
			default:
				if (Shdc.arm64())
					throw new CommandError("shader: glslang publishes Linux programs for x86_64 only (HELIX_GLSLANG can name a glslang of your own)");
				"linux";
		}
	}

	static function exe(name:String):String
		return Sys.systemName() == "Windows" ? name + ".exe" : name;

	/** glslang's program, its pinned release unpacked into the cache the first time; or the one HELIX_GLSLANG names. */
	public static function glslang(root:String):String {
		var given = Downloads.given("HELIX_GLSLANG");
		if (given != null)
			return given;
		var program = glslangLocation(root);
		if (Files.isFile(program))
			return program;
		var directory = Path.directory(Path.directory(program));
		var release:Dynamic = Reflect.field(pin(root).glslang, system());
		Downloads.say('shader: glslang isn\'t in the cache yet: fetched once, into $directory');
		var archive = Downloads.fetch([release.url], release.sha256, "shader");
		Files.removeDirectory(directory);
		Downloads.unzip(archive, directory);
		if (Sys.systemName() != "Windows")
			Sys.command("chmod", ["755", program]);
		return program;
	}

	/** Where glslang's pinned release keeps its program in the cache, whether it's there or not. */
	public static function glslangLocation(root:String):String
		return Path.join([
			Downloads.cache(),
			'glslang-${pin(root).glslang.version}-${system()}',
			"bin",
			exe("glslang")
		]);

	/** SPIRV-Cross's program, built once from its pinned source into the cache by hxcpp (the compiler HeliX's native builds use); or the one
		HELIX_SPIRV_CROSS names. */
	public static function spirvCross(root:String):String {
		var given = Downloads.given("HELIX_SPIRV_CROSS");
		if (given != null)
			return given;
		var entry:Dynamic = pin(root).spirvCross;
		var program = spirvCrossLocation(root);
		if (Files.isFile(program))
			return program;
		var directory = Path.directory(program);
		var hxcpp = try Scratch.run("haxelib", ["path", "hxcpp"]).code == 0 catch (_) false;
		if (!hxcpp)
			throw new CommandError("shader: SPIRV-Cross publishes no programs, so it's built from its source once, by hxcpp, which isn't installed:"
				+ " haxelib install hxcpp (and a C++ compiler: MSVC on Windows, clang or gcc elsewhere), or name a spirv-cross in HELIX_SPIRV_CROSS");
		var archive = Downloads.fetch([entry.url], entry.sha256, "shader");
		var source = Path.join([Downloads.cache(), "spirv-cross-source"]);
		Files.removeDirectory(source);
		// Its top directory's sources and license alone: its tests' names pass Windows' 260-character paths.
		var names = [];
		for (file in Downloads.untarGz(archive, name -> name.split("/").length == 2)) {
			var name = file.name.split("/")[1];
			Files.makeDirectory(source);
			File.saveBytes(Path.join([source, name]), file.data);
			names.push(name);
		}
		names.sort(Reflect.compare);
		var files = [
			for (name in ["main.cpp"].concat(names.filter(n -> StringTools.startsWith(n, "spirv_") && StringTools.endsWith(n, ".cpp"))))
				'  <file name="$name"/>\n'
		].join("");
		var sourcePath = Path.normalize(FileSystem.absolutePath(source));
		var directoryPath = Path.normalize(FileSystem.absolutePath(directory));
		File.saveContent(Path.join([source, "Build.xml"]), '<xml>
 <include name="$${HXCPP}/build-tool/BuildCommon.xml"/>
 <files id="spirv-cross" dir="$sourcePath">
  <compilerflag value="-std=c++14" unless="windows"/>
  <compilerflag value="-EHsc" if="windows"/>
  <compilerflag value="-O2"/>
$files </files>
 <target id="default" tool="linker" toolid="exe" output="spirv-cross">
  <outdir name="$directoryPath"/>
  <files id="spirv-cross"/>
 </target>
</xml>
');
		Downloads.say('shader: building SPIRV-Cross ${entry.version} into $directoryPath (once; hxcpp and the system\'s C++ compiler)');
		Files.makeDirectory(directory);
		var cwd = Sys.getCwd();
		Sys.setCwd(source);
		var arch = Shdc.arm64() ? "-DHXCPP_ARM64" : "-DHXCPP_M64";
		// Its output on the standard error, as the tools' messages are: the standard output is a command's result. Through the shell (sh and
		// cmd both take 1>&2), as a macro can't start the thread that would read two pipes at once.
		var code = Sys.command('haxelib run hxcpp Build.xml $arch -DHXCPP_COMPILE_THREADS=4 1>&2');
		Sys.setCwd(cwd);
		if (code != 0)
			throw new CommandError('shader: building SPIRV-Cross failed (haxelib run hxcpp, exit $code); SDL_GPU\'s dialects need hxcpp installed');
		Files.removeDirectory(source);
		if (!Files.isFile(program))
			throw new CommandError('shader: SPIRV-Cross built, but $program is missing');
		return program;
	}

	/** Where SPIRV-Cross's pinned build keeps its program in the cache, whether it's there or not. */
	public static function spirvCrossLocation(root:String):String
		return Path.join([
			Downloads.cache(),
			'spirv-cross-${pin(root).spirvCross.version}',
			exe("spirv-cross")
		]);

	/** A stage's GLSL 410 rewritten as SDL_GPU's Vulkan GLSL 450 (see the class's description). blocks and textures are the program's (slot,
		stage, glslName each); every uniform the stage declares must be one of them. */
	public static function vulkanGlsl(source:String, stage:String, blocks:Array<Dynamic>, textures:Array<Dynamic>):String {
		var sets = SETS[stage];
		var bySlot = (a:Dynamic, b:Dynamic) -> Reflect.compare(a.slot, b.slot);
		var ownBlocks = blocks.filter(b -> b.stage == stage);
		ownBlocks.sort(bySlot);
		var ownTextures = textures.filter(t -> t.stage == stage);
		ownTextures.sort(bySlot);
		var blockBinding = new Map<String, Int>(),
			textureBinding = new Map<String, Int>();
		for (i => b in ownBlocks)
			blockBinding.set(b.glslName, i);
		for (i => t in ownTextures)
			textureBinding.set(t.glslName, i);
		var uniform = ~/^uniform (\w+) (\w+)(\[\d+\])?;$/;
		var out = [];
		var lines = source.split("\n");
		// Python's splitlines: a final newline ends the last line rather than starting another.
		if (lines.length > 0 && lines[lines.length - 1] == "")
			lines.pop();
		for (line in lines) {
			if (StringTools.startsWith(line, "#version")) {
				out.push("#version 450");
				continue;
			}
			if (uniform.match(StringTools.trim(line))) {
				var kind = uniform.matched(1),
					name = uniform.matched(2),
					count = uniform.matched(3);
				if (kind == "vec4" && count != null && blockBinding.exists(name))
					out.push('layout(set = ${sets.blocks}, binding = ${blockBinding[name]}, std140) uniform ${name}_block { vec4 $name$count; };');
				else if (StringTools.startsWith(kind, "sampler") && count == null && textureBinding.exists(name))
					out.push('layout(set = ${sets.textures}, binding = ${textureBinding[name]}) uniform $kind $name;');
				else
					throw new CommandError('shader: a uniform the layout doesn\'t list: ${StringTools.trim(line)}');
				continue;
			}
			if (StringTools.startsWith(StringTools.ltrim(line), "uniform "))
				throw new CommandError('shader: an unexpected uniform declaration: ${StringTools.trim(line)}');
			out.push(line);
		}
		var text = out.join("\n") + "\n";
		text = ~/\bgl_VertexID\b/g.replace(text, "gl_VertexIndex");
		text = ~/\bgl_InstanceID\b/g.replace(text, "gl_InstanceIndex");
		if (stage == "vertex") {
			var main = ~/\bvoid main\(\)/g;
			if (main.split(text).length != 2)
				throw new CommandError("shader: expected one main in the vertex stage");
			text = main.replace(text, "void helix_main()");
			text += "\n// GL's clip depth (-1..1) as SDL_GPU's (0..1).\nvoid main()\n{\n    helix_main();\n    gl_Position.z = (gl_Position.z + gl_Position.w) * 0.5;\n}\n";
		}
		return text;
	}

	/** A program's GLSL 410 stages in SDL_GPU's dialects: spirv (each stage base64), msl and hlsl (each stage's text), each {vertex, fragment}.
		MSL's entry points are main0, HLSL's main. */
	public static function translate(root:String, vertex:String, fragment:String, blocks:Array<Dynamic>, textures:Array<Dynamic>):JsonValue {
		// SPIRV-Cross first: without hxcpp it can't be had, and glslang's download would be for nothing.
		var cross = spirvCross(root), compiler = glslang(root);
		var spirv = [], msl = [], hlsl = [];
		var directory = Scratch.make("helix-gpu-");
		try {
			for (stage in [
				{name: "vertex", source: vertex, suffix: "vert"},
				{name: "fragment", source: fragment, suffix: "frag"}
			]) {
				var glsl = Path.join([directory, '${stage.name}.${stage.suffix}']);
				var binary = Path.join([directory, '${stage.name}.spv']);
				File.saveContent(glsl, vulkanGlsl(stage.source, stage.name, blocks, textures));
				var run = Scratch.run(compiler, ["-V", "--target-env", "vulkan1.0", "-o", binary, glsl]);
				if (run.code != 0)
					throw new CommandError('shader: glslang refused the ${stage.name} stage:\n${run.out}${run.err}\n${File.getContent(glsl)}');
				spirv.push({key: stage.name, value: JString(haxe.crypto.Base64.encode(File.getBytes(binary)))});
				msl.push({key: stage.name, value: JString(Scratch.output(cross, [binary, "--msl", "--msl-version", "20100", "--msl-decoration-binding"]))});
				hlsl.push({key: stage.name, value: JString(Scratch.output(cross, [binary, "--hlsl", "--shader-model", "51"]))});
			}
		} catch (error:haxe.Exception) {
			Files.removeDirectory(directory);
			throw error;
		}
		Files.removeDirectory(directory);
		return JObject([
			{key: "spirv", value: JObject(spirv)},
			{key: "msl", value: JObject(msl)},
			{key: "hlsl", value: JObject(hlsl)}
		]);
	}
}
