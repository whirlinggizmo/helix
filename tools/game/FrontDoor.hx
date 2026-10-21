package tools.game;

/** `haxelib run helix <command>`'s commands, read from the command line and run on the game in the current folder; Run.hx calls it. A
	refusal (CommandError) is said on the standard error and exits with 1; a command line it can't read, with 2. */
class FrontDoor {
	/** What `--help` says. */
	public static final HELP = "usage: haxelib run helix <command> [options]

A game on -lib helix, from its own folder: a starter written, its shaders packed, its web build assembled for hosting.

  init FOLDER                 a starter game in FOLDER (empty or not yet there): src/Main.hx and src/Game.hx (a window title, a rectangle
                              and a greeting), web.hxml, native.hxml, assets/, .gitignore and a README with the commands
  shader [FILE.glsl ...] [--out DIR] [--sdl-gpu] [--watch]
                              the game's shaders packed: shaders/*.glsl, or the files named, into assets/shaders/<name>.hxshader (or
                              --out), loaded as \"shaders/<name>.hxshader\"; --sdl-gpu adds SDL_GPU's dialects, for an sdl3-gpu build;
                              --watch packs each again as it changes, until Ctrl+C
  site [--out DIR] [--zip [FILE]] [--title TITLE] [--js FILE] [--hxml FILE]
                              the web build assembled for hosting in out/site (or --out): index.html from the library's template,
                              app.js (the -js of web.hxml, or --hxml's), assets/ copied beside, config.json and favicon.png from the
                              game's folder when there; --title the page's (the folder's name); --zip writes it as a zip with
                              index.html at the root (out/<game>-web.zip, or FILE), what itch.io takes

The game's folder is the current one. `shader` fetches sokol-shdc into the user's cache the first time, and with --sdl-gpu glslang and
SPIRV-Cross (built by hxcpp) too (BUILDING.md).";

	/** Runs the command args name for the game in the current folder, the library being at root; returns the exit code. */
	public static function run(args:Array<String>, root:String):Int {
		if (args.length == 0)
			return usage("a command is needed: init, shader or site");
		var command = args[0], rest = args.slice(1);
		if (command == "--help" || command == "-h") {
			Sys.println(HELP);
			return 0;
		}
		try {
			switch command {
				case "init":
					var options = new Options(rest, []);
					if (options.help)
						return help("init FOLDER: a starter game in a new or empty folder");
					if (options.positional.length != 1)
						return usage("init: name one folder");
					var folder = options.positional[0];
					Sys.println('init: $folder: ' + Starter.write(root, folder).join(", "));
				case "site":
					var options = new Options(rest, ["--out", "--title", "--js", "--hxml"], ["--zip"]);
					if (options.help)
						return help("site [--out DIR] [--zip [FILE]] [--title TITLE] [--js FILE] [--hxml FILE]: the web build assembled for hosting");
					if (options.positional.length > 0)
						return usage('site: unexpected ${options.positional[0]}');
					var name = haxe.io.Path.withoutDirectory(Files.resolve(Sys.getCwd(), "."));
					var zip = options.values.get("--zip");
					Site.assemble(root, ".", options.value("--out", "out/site"), zip == null ? null : (zip == "" ? 'out/$name-web.zip' : zip),
						options.value("--title", name), options.values.get("--js"), options.value("--hxml", "web.hxml"));
				case "shader":
					var options = new Options(rest, ["--out"], [], ["--sdl-gpu", "--watch"]);
					if (options.help)
						return help("shader [FILE.glsl ...] [--out DIR] [--sdl-gpu] [--watch]: the game's shaders packed into .hxshader assets");
					GameShaders.pack(root, ".", options.positional, options.value("--out", "assets/shaders"), options.values.exists("--sdl-gpu"),
						options.values.exists("--watch"));
				default:
					return usage('unknown command $command: init, shader or site');
			}
		} catch (error:OptionError) {
			return usage('$command: ${error.message}');
		} catch (error:CommandError) {
			Sys.stderr().writeString(error.message + "\n");
			return 1;
		}
		return 0;
	}

	static function help(line:String):Int {
		Sys.println("usage: haxelib run helix " + line);
		return 0;
	}

	static function usage(message:String):Int {
		Sys.stderr().writeString('usage: haxelib run helix <command> [options] (--help lists them)\nhelix: $message\n');
		return 2;
	}
}

/** A command line that can't be read: an unknown option, or one missing its value. */
private class OptionError extends haxe.Exception {}

/** A command's options read from its arguments: those taking a value, those whose value is optional (given as "" when absent), flags (given
	as ""), --help. */
private class Options {
	public var positional:Array<String> = [];
	public var values = new Map<String, String>();
	public var help = false;

	public function new(args:Array<String>, valued:Array<String>, ?optional:Array<String>, ?flags:Array<String>) {
		var i = 0;
		while (i < args.length) {
			var arg = args[i++];
			if (arg == "--help" || arg == "-h")
				help = true;
			else if (valued.indexOf(arg) >= 0) {
				if (i >= args.length)
					throw new OptionError('$arg needs a value');
				values.set(arg, args[i++]);
			} else if (flags != null && flags.indexOf(arg) >= 0)
				values.set(arg, "");
			else if (optional != null && optional.indexOf(arg) >= 0)
				values.set(arg, i < args.length && !StringTools.startsWith(args[i], "-") ? args[i++] : "");
			else if (StringTools.startsWith(arg, "-") && arg.length > 1)
				throw new OptionError('unknown option $arg');
			else
				positional.push(arg);
		}
	}

	/** The option's value, or fallback when it wasn't given. */
	public function value(name:String, fallback:String):String {
		var found = values.get(name);
		return found == null ? fallback : found;
	}
}
