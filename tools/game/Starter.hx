package tools.game;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

/** `init`: the starter game (templates/starter: src/Main.hx and src/Game.hx, web.hxml, native.hxml, assets/, .gitignore and a README with
	the commands) written into a new or empty folder, each file's {name} the game's (its folder's name) and {title} its title. */
class Starter {
	/** The starter written into folder (made when missing) from the library at root; refuses a folder with anything in it. Returns the files
		written, relative to it. */
	public static function write(root:String, folder:String):Array<String> {
		if (FileSystem.exists(folder) && (!FileSystem.isDirectory(folder) || FileSystem.readDirectory(folder).length > 0))
			throw new CommandError('init: $folder is not empty; a starter goes in a new or empty folder');
		var name = Path.withoutDirectory(Files.resolve(Sys.getCwd(), folder));
		var template = Path.join([root, "templates", "starter"]);
		var written = Files.listFiles(template);
		for (relative in written) {
			var text = File.getContent(Path.join([template, relative]));
			Files.writeText(Path.join([folder, relative]), StringTools.replace(StringTools.replace(text, "{name}", name), "{title}", title(name)));
		}
		return written;
	}

	/** The title a folder's name gives: its words (apart by -, _ or spaces) capitalized, "my-jam-game" My Jam Game; Game when it has none. */
	public static function title(name:String):String {
		var words = [
			for (word in ~/[-_\s]+/g.split(name))
				if (word != "") word.charAt(0).toUpperCase() + word.substr(1)
		];
		return words.length > 0 ? words.join(" ") : "Game";
	}
}
