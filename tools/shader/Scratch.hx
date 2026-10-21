package tools.shader;

import haxe.io.Path;
import tools.game.CommandError;

/** The packer's scratch: a new folder under the system's temporary one, and programs run with their output read (line ends as LF, as a
	program on Windows writes CRLF to a text stream). */
class Scratch {
	/** A new, empty folder under the system's temporary folder, its name starting with prefix; the caller removes it. */
	public static function make(prefix:String):String {
		var base = Sys.getEnv(Sys.systemName() == "Windows" ? "TEMP" : "TMPDIR");
		if (base == null || base == "")
			base = Sys.systemName() == "Windows" ? Sys.getEnv("TMP") : "/tmp";
		while (true) {
			var folder = Path.join([
				base,
				prefix + Std.string(Std.random(0x7fffffff)) + Std.string(Std.int(Sys.time() * 1000) % 1000000)
			]);
			if (!sys.FileSystem.exists(folder)) {
				sys.FileSystem.createDirectory(folder);
				return Path.normalize(sys.FileSystem.absolutePath(folder));
			}
		}
	}

	/** program run with args: its exit code, standard output and standard error. */
	public static function run(program:String, args:Array<String>):{code:Int, out:String, err:String} {
		var process = new sys.io.Process(program, args);
		var out = process.stdout.readAll().toString();
		var err = process.stderr.readAll().toString();
		var code = process.exitCode();
		process.close();
		return {code: code, out: lf(out), err: lf(err)};
	}

	/** program's standard output, run with args; refuses a failure, saying its error. */
	public static function output(program:String, args:Array<String>):String {
		var result = run(program, args);
		if (result.code != 0)
			throw new CommandError('${Path.withoutDirectory(program)} failed (exit ${result.code}):\n${result.out}${result.err}');
		return result.out;
	}

	static function lf(text:String):String
		return StringTools.replace(text, "\r\n", "\n");
}
