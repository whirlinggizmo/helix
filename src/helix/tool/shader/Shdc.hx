package helix.tool.shader;

import haxe.io.Path;
import helix.tool.shared.CommandError;
import helix.tool.shared.Downloads;
import helix.tool.shared.Files;

/** sokol-shdc, the shader compiler: the sokol-tools-bin build dependencies.json pins (sokolToolsBin), for this system, downloaded into the
	user's cache the first time from floooh's repository, or the Whirling Gizmo mirror when that can't be reached, and checked against its
	SHA-256 below as it arrives; or the user's own, which HELIX_SHDC names. To move to a newer build, change the pin, HASHES_PIN and the hashes together. */
class Shdc {
	static final SOURCES = ["floooh/sokol-tools-bin", "whirlinggizmo/sokol-tools-bin"];
	static final HASHES_PIN = "11d0cf678105d614d675e6d9bd2aaf3eeff12f8c";
	// Each system's directory in sokol-tools-bin's bin/, and its program's SHA-256.
	static final SHA256 = [
		"linux" => "ed35e89ef381d521a499096ed4ada85e4d135d8011e151cca6b7d893c43b21df",
		"linux_arm64" => "446b4bcea0c81d3ae529bc0d93533ea661b017f5b9ec2b2293a4c85f5fdcb639",
		"osx" => "8b4a6ac1172ec0d90dd41d611067d5e87a51e78dc28acb216cfc341d880b1d78",
		"osx_arm64" => "92db37975ad7ff3c3c9bc27cba1503287377cb287ebabf60d1c6b597abfa3244",
		"win32" => "bd616287f9ea689d53c6d260e443ee733e61ae1b73a9b37adc482ead0364d561"
	];

	/** The pinned sokol-shdc of the library at root, fetched the first time; or the one HELIX_SHDC names. A file of the right size where it
		belongs is taken as the one checked when it arrived (hashing it again would take seconds in Haxe's interpreter). */
	public static function path(root:String):String {
		var given = Downloads.given("HELIX_SHDC");
		if (given != null)
			return given;
		var found = location(root);
		var directory = system(), exe = Path.withoutDirectory(found);
		var stamp = found + ".sha256";
		var checked = SHA256[directory] + " " + (Files.isFile(found) ? sys.FileSystem.stat(found).size : -1);
		if (Files.isFile(found) && Files.isFile(stamp) && sys.io.File.getContent(stamp) == checked)
			return found;
		// One already there without its record (put there by hand, or by an earlier tool) is checked once, not fetched again.
		if (Files.isFile(found) && helix.tool.shared.Sha256.hex(sys.io.File.getBytes(found)) == SHA256[directory]) {
			sys.io.File.saveContent(stamp, checked);
			return found;
		}
		Downloads.say('shdc: sokol-shdc isn\'t in the cache yet: fetched once, into ${Path.directory(found)}');
		var data = try Downloads.fetch([
			for (source in SOURCES)
				'https://raw.githubusercontent.com/$source/$HASHES_PIN/bin/$directory/$exe'
		],
			SHA256[directory],
			"shdc") catch (error:CommandError) throw new CommandError(error.message
			+ '\nshdc: without a network, put sokol-tools-bin\'s bin/$directory/$exe (at $HASHES_PIN) at $found, or name a sokol-shdc in HELIX_SHDC');
		Downloads.place(found, data, true);
		sys.io.File.saveContent(stamp, SHA256[directory] + " " + data.length);
		return found;
	}

	/** Where the pinned sokol-shdc of the library at root is kept in the cache, whether it's there or not. */
	public static function location(root:String):String {
		var pin:String = haxe.Json.parse(sys.io.File.getContent(Path.join([root, "dependencies.json"]))).sokolToolsBin;
		if (pin != HASHES_PIN)
			throw new CommandError('shdc: dependencies.json pins sokol-tools-bin $pin, but src/helix/tool/shader/Shdc.hx has the hashes of $HASHES_PIN');
		system();
		var exe = Sys.systemName() == "Windows" ? "sokol-shdc.exe" : "sokol-shdc";
		return Path.join([Downloads.cache(), 'sokol-shdc-${pin.substr(0, 12)}', exe]);
	}

	// This system's directory in sokol-tools-bin's bin/.
	static function system():String {
		return switch Sys.systemName() {
			case "Linux": arm64() ? "linux_arm64" : "linux";
			case "Mac": arm64() ? "osx_arm64" : "osx";
			case "Windows": "win32";
			case other: throw new CommandError('shdc: sokol-tools-bin has no build for $other (HELIX_SHDC can name a sokol-shdc of your own)');
		}
	}

	/** Whether this machine is arm64. */
	public static function arm64():Bool {
		var machine = Sys.systemName() == "Windows" ? Sys.getEnv("PROCESSOR_ARCHITECTURE") : command("uname", ["-m"]);
		machine = machine == null ? "" : StringTools.trim(machine).toLowerCase();
		return machine == "arm64" || machine == "aarch64";
	}

	// A program's standard output, or null when it couldn't run.
	static function command(program:String, args:Array<String>):Null<String> {
		try {
			var process = new sys.io.Process(program, args);
			var out = process.stdout.readAll().toString();
			process.close();
			return out;
		} catch (_)
			return null;
	}
}
