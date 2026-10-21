package helix.tools.setup;

import helix.tools.shared.CommandError;
import helix.tools.shared.Files;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

/** `init`: the starter game (templates/starter: src/Main.hx and src/Game.hx, its builds in hxml/, assets/, .gitignore and a README with the
	commands) written into a new or empty directory, each file's {name} the game's (its directory's name) and {title} its title. */
class Starter {
	/** The starter written into directory (made when missing) from the library at root; refuses a directory with anything in it. Returns the files
		written, relative to it. */
	public static function write(root:String, directory:String):Array<String> {
		if (FileSystem.exists(directory) && (!FileSystem.isDirectory(directory) || FileSystem.readDirectory(directory).length > 0))
			throw new CommandError('init: $directory is not empty; a starter goes in a new or empty directory');
		var name = Path.withoutDirectory(Files.resolve(Sys.getCwd(), directory));
		var template = Path.join([root, "templates", "starter"]);
		var written = Files.listFiles(template);
		for (relative in written) {
			var text = File.getContent(Path.join([template, relative]));
			Files.writeText(Path.join([directory, relative]), StringTools.replace(StringTools.replace(text, "{name}", name), "{title}", title(name)));
		}
		return written;
	}

	/** The title a directory's name gives: its words (apart by -, _ or spaces) capitalized, "my-jam-game" My Jam Game; Game when it has none. */
	public static function title(name:String):String {
		var words = [
			for (word in ~/[-_\s]+/g.split(name))
				if (word != "") word.charAt(0).toUpperCase() + word.substr(1)
		];
		return words.length > 0 ? words.join(" ") : "Game";
	}
}
