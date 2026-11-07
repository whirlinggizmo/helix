package helix.platform.tools;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

/** Provides the programs `ShaderCompiler` runs: glslang, which compiles GLSL to SPIR-V, and SPIRV-Cross, which translates SPIR-V to every
	other dialect and reflects it.

	Each is pinned here and kept in the user's cache (`Downloads`), fetched the first time it's needed and checked against its SHA-256:
	glslang's official release for the system, or for Linux on ARM, which it doesn't publish for, Whirling Gizmo's build of it
	(github.com/whirlinggizmo/helix-tools); SPIRV-Cross, which publishes source only, from Whirling Gizmo's builds, or on a system they
	don't cover built from its pinned source once by hxcpp with the system's C++ compiler. Windows on ARM runs the x86_64 programs.
	`HELIX_GLSLANG` and `HELIX_SPIRV_CROSS` name programs of the user's own instead, unchecked. To move to newer releases, change a version,
	its URLs and its hashes together (helix-tools builds the new ones from its own pins). */
@:noCompletion
class ShaderTools {
	/** The pinned glslang's version. */
	public static final GLSLANG_VERSION = "16.6.0";

	// Each system's release of glslang and its archive's SHA-256.
	static final GLSLANG = [
		"linux-x86_64" => {
			url: 'https://github.com/KhronosGroup/glslang/releases/download/$GLSLANG_VERSION/glslang-$GLSLANG_VERSION-linux-x86_64-release.zip',
			sha256: "a3fc4f083b1793eb53e55fa3577ac9649ffbe0340715e30d116290fb5382393f"
		},
		"linux-arm64" => {
			url: 'https://github.com/whirlinggizmo/helix-tools/releases/download/glslang-$GLSLANG_VERSION/glslang-$GLSLANG_VERSION-linux-arm64.zip',
			sha256: "58bdf989259d8631619665552d5a3894ae5c2032192df7bcca98bb45862c2c87"
		},
		"macos" => {
			url: 'https://github.com/KhronosGroup/glslang/releases/download/$GLSLANG_VERSION/glslang-$GLSLANG_VERSION-macos-universal-release.zip',
			sha256: "1086bc6c7ce8ff188e4e1d1a69078e9e38156a4c2c3f13e4f91b9289a1d90453"
		},
		"windows" => {
			url: 'https://github.com/KhronosGroup/glslang/releases/download/$GLSLANG_VERSION/glslang-$GLSLANG_VERSION-windows-x86_64-release.zip',
			sha256: "82bf434e69b9bb4829de7e2b4bc2c5e7a7861e53d66cf75e5cc70f5f694a8d9b"
		}
	];

	/** The pinned SPIRV-Cross's version: the tag of its source. */
	public static final SPIRV_CROSS_VERSION = "vulkan-sdk-1.4.363.0";

	// Each system's build of SPIRV-Cross (helix-tools) and its archive's SHA-256.
	static final SPIRV_CROSS = [
		"linux-x86_64" => {
			url: 'https://github.com/whirlinggizmo/helix-tools/releases/download/spirv-cross-$SPIRV_CROSS_VERSION/spirv-cross-$SPIRV_CROSS_VERSION-linux-x86_64.zip',
			sha256: "239b7547fc172eaffcb87836eb9800c4e4d3623911ab7a6b4c87042f1bc80d18"
		},
		"linux-arm64" => {
			url: 'https://github.com/whirlinggizmo/helix-tools/releases/download/spirv-cross-$SPIRV_CROSS_VERSION/spirv-cross-$SPIRV_CROSS_VERSION-linux-arm64.zip',
			sha256: "2c77a8d59c5a019da5bdc940c0d00c576789938ca074653f08f104ba467b426d"
		},
		"macos" => {
			url: 'https://github.com/whirlinggizmo/helix-tools/releases/download/spirv-cross-$SPIRV_CROSS_VERSION/spirv-cross-$SPIRV_CROSS_VERSION-macos-universal.zip',
			sha256: "6278ed84d11cdb580653cbed8ba9e4e28612fe5729913e9248e7364159dcad7d"
		},
		"windows" => {
			url: 'https://github.com/whirlinggizmo/helix-tools/releases/download/spirv-cross-$SPIRV_CROSS_VERSION/spirv-cross-$SPIRV_CROSS_VERSION-windows-x86_64.zip',
			sha256: "ad534875cb78aeb8266d1a4adc9676797a47418bb15ccd241f6c2b2a5d59dceb"
		}
	];

	// SPIRV-Cross's source, built where there's no build for the system.
	static final SPIRV_CROSS_SOURCE = {
		url: 'https://github.com/KhronosGroup/SPIRV-Cross/archive/refs/tags/$SPIRV_CROSS_VERSION.tar.gz',
		sha256: "f708982e88b763ef5b0394ed468fc2c3628f68cdab89f2e7a946cd628c04e721"
	};

	/** Returns glslang's program, its pinned release unpacked into the cache the first time, or the one `HELIX_GLSLANG` names.

		@throws CommandException  There's no release for this system, or it can't be fetched. */
	public static function glslang():String {
		var given = Downloads.given("HELIX_GLSLANG");
		if (given != null)
			return given;
		var program = glslangLocation();
		if (Files.isFile(program))
			return program;
		var release = GLSLANG[system()];
		Downloads.say('shader: glslang isn\'t in the cache yet: fetched once, into ${Path.directory(Path.directory(program))}');
		unpack(release, program);
		return program;
	}

	/** Returns SPIRV-Cross's program, its build for this system unpacked into the cache the first time (or on a system without one, built
		once from its pinned source by hxcpp), or the one `HELIX_SPIRV_CROSS` names.

		@throws CommandException  It can't be fetched; or, built from source, hxcpp isn't installed or the build fails. */
	public static function spirvCross():String {
		var given = Downloads.given("HELIX_SPIRV_CROSS");
		if (given != null)
			return given;
		var program = spirvCrossLocation();
		if (Files.isFile(program))
			return program;
		var built = SPIRV_CROSS[system()];
		if (built != null) {
			Downloads.say('shader: SPIRV-Cross isn\'t in the cache yet: fetched once, into ${Path.directory(Path.directory(program))}');
			unpack(built, program);
			return program;
		}
		var directory = Path.directory(program);
		var hxcpp = try Scratch.run("haxelib", ["path", "hxcpp"]).code == 0 catch (_) false;
		if (!hxcpp)
			throw new CommandException("shader: there's no build of SPIRV-Cross for this system, so it's built from its source once, by hxcpp, which isn't"
				+
				" installed: haxelib install hxcpp (and a C++ compiler: MSVC on Windows, clang or gcc elsewhere), or name a spirv-cross in HELIX_SPIRV_CROSS");
		var archive = Downloads.fetch([SPIRV_CROSS_SOURCE.url], SPIRV_CROSS_SOURCE.sha256, "shader");
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
		Downloads.say('shader: building SPIRV-Cross $SPIRV_CROSS_VERSION into $directoryPath (once; hxcpp and the system\'s C++ compiler)');
		Files.makeDirectory(directory);
		var cwd = Sys.getCwd();
		Sys.setCwd(source);
		var arch = arm64() ? "-DHXCPP_ARM64" : "-DHXCPP_M64";
		// Its output on the standard error, as the tools' messages are: the standard output is a command's result. Through the shell (sh and
		// cmd both take 1>&2), as a macro can't start the thread that would read two pipes at once.
		var code = Sys.command('haxelib run hxcpp Build.xml $arch -DHXCPP_COMPILE_THREADS=4 1>&2');
		Sys.setCwd(cwd);
		if (code != 0)
			throw new CommandException('shader: building SPIRV-Cross failed (haxelib run hxcpp, exit $code)');
		Files.removeDirectory(source);
		if (!Files.isFile(program))
			throw new CommandException('shader: SPIRV-Cross built, but $program is missing');
		return program;
	}

	/** Returns where the pinned glslang's program is kept in the cache, whether it's there or not.

		@throws CommandException  There's no release for this system. */
	public static function glslangLocation():String
		return Path.join([
			Downloads.cache(),
			'glslang-$GLSLANG_VERSION-${glslangSystem()}',
			"bin",
			exe("glslang")
		]);

	/** Returns where the pinned SPIRV-Cross's program is kept in the cache, whether it's there or not. */
	public static function spirvCrossLocation():String
		return Path.join([Downloads.cache(), 'spirv-cross-$SPIRV_CROSS_VERSION', "bin", exe("spirv-cross")]);

	/** Returns whether this machine is ARM 64-bit, as the system says. */
	public static function arm64():Bool {
		var machine = Sys.systemName() == "Windows" ? Sys.getEnv("PROCESSOR_ARCHITECTURE") : output("uname", ["-m"]);
		machine = machine == null ? "" : StringTools.trim(machine).toLowerCase();
		return machine == "arm64" || machine == "aarch64";
	}

	// This system's key in GLSLANG and SPIRV_CROSS: windows, macos, linux-x86_64 or linux-arm64; another Linux's machine name.
	static function system():String {
		return switch Sys.systemName() {
			case "Windows": "windows";
			case "Mac": "macos";
			default:
				if (arm64()) "linux-arm64" else {
					var machine = output("uname", ["-m"]);
					'linux-${machine == null ? "unknown" : StringTools.trim(machine)}';
				}
		}
	}

	// This system's key in GLSLANG, which has a release for each system SPIRV-Cross can be built on but other Linux machines.
	static function glslangSystem():String {
		var key = system();
		if (!GLSLANG.exists(key))
			throw new CommandException('shader: there\'s no glslang release for $key (HELIX_GLSLANG can name a glslang of your own)');
		return key;
	}

	// Unpacks a release's zip, fetched and checked, into the directory above program's bin/. Unpacked beside it first and renamed into
	// place, so compiles fetching at once never see a part: the first to finish places it, and the others drop theirs.
	static function unpack(release:{url:String, sha256:String}, program:String):Void {
		var directory = Path.directory(Path.directory(program));
		var archive = Downloads.fetch([release.url], release.sha256, "shader");
		var partial = '$directory.part-${Std.random(0x7fffffff)}';
		Downloads.unzip(archive, partial);
		if (Sys.systemName() != "Windows")
			Sys.command("chmod", ["755", Path.join([partial, "bin", Path.withoutDirectory(program)])]);
		if (!Files.isFile(program)) {
			Files.removeDirectory(directory);
			try
				FileSystem.rename(partial, directory)
			catch (e:Dynamic)
				if (!Files.isFile(program))
					throw new CommandException('shader: unpacking into $directory failed: $e');
		}
		Files.removeDirectory(partial);
	}

	static function exe(name:String):String
		return Sys.systemName() == "Windows" ? name + ".exe" : name;

	// A program's standard output, or null when it couldn't run.
	static function output(program:String, args:Array<String>):Null<String> {
		try {
			var process = new sys.io.Process(program, args);
			var out = process.stdout.readAll().toString();
			process.close();
			return out;
		} catch (_:Dynamic) {
			return null;
		}
	}
}
