import helix.platform.Blend;
import helix.platform.BlendFactor;
import helix.platform.ColorChannels;
import helix.platform.Filter;
import helix.platform.MipmapFilter;
import helix.platform.Sampling;
import helix.platform.TextureFormat;
import helix.platform.Wrap;

/** Checks helix-platform's own values, built with -lib helix-platform alone so nothing above it is visible: a sampling's parts, texture formats' level sizes, and the enum abstracts read as their names; and, where there is a
	file system (the interpreter and hxcpp), `NativeFileSystemAdapter`'s file information and listing. Run by helix.py test on the
	interpreter and Node. */
class PlatformTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	#if sys
	// Waits for a file system's answer, polling it: the native adapter answers at a later poll, from its worker thread.
	static function await(files:helix.platform.IFileSystem, ask:(Dynamic->Void)->Void):Dynamic {
		var answer:Dynamic = null, answered = false;
		ask(value -> {
			answer = value;
			answered = true;
		});
		var until = Sys.time() + 10;
		while (!answered && Sys.time() < until) {
			files.poll();
			Sys.sleep(.001);
		}
		check(answered, "the file system answered within 10 seconds");
		return answer;
	}

	// A file's size and time, its directory's listing, and what is missing, on a directory of the tests' own.
	static function fileSystem():Void {
		var directory = "build/tests/platform-files";
		function remove(path:String):Void {
			if (!sys.FileSystem.exists(path))
				return;
			if (sys.FileSystem.isDirectory(path)) {
				for (entry in sys.FileSystem.readDirectory(path))
					remove('$path/$entry');
				sys.FileSystem.deleteDirectory(path);
			} else
				sys.FileSystem.deleteFile(path);
		}
		remove(directory);
		var files:helix.platform.IFileSystem = new helix.platform.adapters.filesystem.native.NativeFileSystemAdapter({directory: directory});
		function info(path:String):Dynamic
			return await(files,
				done -> files.getInfo(path, (size, modified) -> done({size: size, modified: modified}), () -> done("missing"), why -> done('failed: $why')));
		function list(path:String):Dynamic
			return await(files, done -> files.list(path, names -> done(names.join(",")), () -> done("missing"), why -> done('failed: $why')));
		check(list("") == "", "a root not yet written lists nothing");
		var before = Date.now().getTime() / 1000;
		for (path in ["a.txt", "sub/b.bin", "sub/deep/c.txt", "sub-x.txt"])
			check(await(files, done -> files.write(path, haxe.io.Bytes.ofString('of $path'), () -> done(true), why -> done(why))) == true, 'write $path');
		var a:Dynamic = info("a.txt");
		check(a.size == 8, "a file's size: " + '${a.size}');
		check(a.modified > before - 2
			&& a.modified < Date.now().getTime() / 1000 + 2, "a file's time, seconds since the epoch: " + '${a.modified}');
		check(info("sub") == "missing", "a directory has no file information");
		check(info("nope.txt") == "missing", "a missing file has none");
		check(info("bad path") == 'failed: ${helix.platform.FilePath.INVALID}', "an invalid path fails");
		check(list("") == "a.txt,sub-x.txt,sub/", 'the root: files, and directories ending in a slash, sorted: ${list("")}');
		check(list("sub") == "b.bin,deep/" && list("sub/deep") == "c.txt", "a directory's own entries");
		check(list("a.txt") == "missing" && list("nope") == "missing", "a file or nothing is no directory");
		check(list("../x") == 'failed: ${helix.platform.FilePath.INVALID}', "an invalid directory fails");
		remove(directory);
	}
	#end

	static function main():Void {
		// A program's company and product, each one directory's name on every OS.
		var name = helix.platform.FilePath.isDirectoryName;
		check(name("Whirling Gizmo") && name("asteroids-2") && name("Ünïcode"), "directory names: spaces, digits and letters of any script");
		check(!name("") && !name(".") && !name("..") && !name("a/b") && !name("a\\b") && !name("a:b") && !name("what?"),
			"directory names: not empty, . or .., no separator or reserved character");
		check(!name("trailing ") && !name("trailing.") && !name([for (_ in 0...65) "x"].join("")),
			"directory names: no space or . at the end, 64 characters at most");

		// A sampling keeps its filter and wraps in a small value, and with* change one part.
		var sampling = new Sampling(Linear, Repeat, Mirror);
		check(sampling.filter == Linear && sampling.wrapU == Repeat && sampling.wrapV == Mirror && (sampling : Int) < Sampling.COUNT,
			"Sampling keeps its filter and wraps");
		check(sampling.withFilter(Nearest).filter == Nearest
			&& sampling.withFilter(Nearest).wrapU == Repeat, "withFilter changes the filter alone");
		check(sampling.withWrap(Clamp, Clamp).wrapV == Clamp
			&& sampling.withWrap(Clamp, Clamp).filter == Linear, "withWrap changes the wraps alone");
		check(Sampling.NEAREST.filter == Nearest && Sampling.LINEAR.filter == Linear && Sampling.LINEAR.wrapU == Clamp, "The two clamped samplings");
		// The mipmap filter follows the filter unless given; anisotropy rounds down to a power of two, at most 16.
		check(sampling.mipmapFilter == Linear && Sampling.NEAREST.mipmapFilter == Nearest && sampling.anisotropy == 1,
			"The mipmap filter defaults to the filter's, the anisotropy to 1");
		var mipped = new Sampling(Nearest, Clamp, Repeat, None, 6);
		check(mipped.mipmapFilter == None
			&& mipped.anisotropy == 4
			&& new Sampling(Linear, Clamp, Clamp, Linear,
				40).anisotropy == 16
					&& mipped.withMipmapFilter(Linear)
						.mipmapFilter == Linear
					&& mipped.withMipmapFilter(Linear)
						.anisotropy == 4
					&& mipped.withAnisotropy(8)
						.anisotropy == 8
					&& mipped.withAnisotropy(8)
						.wrapV == Repeat
					&& mipped.withFilter(Linear)
						.mipmapFilter == None,
			"Mipmap filter and anisotropy kept, and changed alone");
		var seen = new Map<Int, Bool>();
		for (filter in [Filter.Nearest, Filter.Linear])
			for (u in [Clamp, Repeat, Mirror])
				for (v in [Clamp, Repeat, Mirror])
					for (mipmaps in [MipmapFilter.None, MipmapFilter.Nearest, MipmapFilter.Linear])
						for (anisotropy in [1, 2, 4, 8, 16])
							seen.set(new Sampling(filter, u, v, mipmaps, anisotropy), true);
		check(Lambda.count(seen) == 270 && [for (s in seen.keys()) s].filter(s -> s < 0 || s >= Sampling.COUNT).length == 0,
			"Every combination distinct and under COUNT");

		// Level sizes: blocks of 4x4 of 16 bytes, or bytes a texel.
		check((Astc4x4 : TextureFormat).levelBytes(5, 3) == 32
			&& (Bc7 : TextureFormat).levelBytes(4, 4) == 16, "Compressed: 16 bytes a 4x4 block");
		check((Rgba8 : TextureFormat).levelBytes(5, 3) == 60
			&& (Rgba16f : TextureFormat).levelBytes(5, 3) == 120, "Uncompressed: 4 or 8 bytes a texel");

		// The enum abstracts read as their names where typed (helix.platform.macros.EnumNames), staying numbers.
		var blend = BlendFactor.SourceAlpha,
			format = TextureFormat.Etc2Rgba8,
			wrap = Wrap.Mirror;
		check(Std.string(blend) == "SourceAlpha" && '$format' == "Etc2Rgba8" && "" + wrap == "Mirror" && (blend : Int) == 6,
			"BlendFactor, TextureFormat, Wrap by name, still their numbers");
		// A blend keeps its six fields, the alpha's defaulting to the color's.
		var separate = new Blend(DestinationColor, OneMinusSourceAlpha, ReverseSubtract, Zero, SourceAlphaSaturated, Max),
			same = new Blend(SourceColor, OneMinusDestinationAlpha, Subtract);
		check(separate.colorSource == DestinationColor
			&& separate.colorDestination == OneMinusSourceAlpha
			&& separate.colorOperation == ReverseSubtract
			&& separate.alphaSource == Zero
			&& separate.alphaDestination == SourceAlphaSaturated
			&& separate.alphaOperation == Max
			&& same.alphaSource == SourceColor
			&& same.alphaDestination == OneMinusDestinationAlpha
			&& same.alphaOperation == Subtract,
			"Blend: six fields, the alpha's defaulting to the color's");
		check(Blend.OPAQUE.colorSource == One
			&& Blend.OPAQUE.alphaDestination == Zero
			&& Blend.ALPHA.alphaSource == One
			&& Blend.ALPHA.colorSource == SourceAlpha
			&& Blend.ADDITIVE.colorDestination == One,
			"Blend's OPAQUE, ALPHA and ADDITIVE");
		var channels:ColorChannels = Red | Alpha;
		check(channels.hasChannels(Red)
			&& channels.hasChannels(Red | Alpha)
			&& !channels.hasChannels(Green)
			&& (channels : Int) == 9 && ColorChannels.All.hasChannels(Red | Green | Blue | Alpha),
			"ColorChannels combined with |");

		#if sys
		fileSystem();
		#end

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
