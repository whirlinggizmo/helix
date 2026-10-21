package tools.game;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

/** `site`: the game's web build assembled for hosting: index.html from the library's template (templates/index.html) with the title, app.js
	copied from the build, assets/ copied beside it, the game's config.json (the page told of it) and favicon.png when there; and on request
	the folder zipped with index.html at its root, as itch.io takes it. */
class Site {
	/** The site assembled in out (the folder remade) from the game in game, by the library at root: the page titled title, app.js from js (or
		the -js of hxml), and zipped to zip when it isn't null. Refuses a build not made yet, and an out holding the game. Returns out's
		absolute path. */
	public static function assemble(root:String, game:String, out:String, zip:Null<String>, title:String, js:Null<String>, hxml:String):String {
		var gameFolder = Files.resolve(Sys.getCwd(), game);
		if (js == null) {
			var hxmlPath = Path.join([gameFolder, hxml]);
			if (!Files.isFile(hxmlPath))
				throw new CommandError('site: no $hxml in $gameFolder: name the hxml with --hxml, or the built JavaScript with --js');
			js = hxmlOutput(hxmlPath, gameFolder, []);
			if (js == null)
				throw new CommandError('site: $hxml names no -js output; name the built JavaScript with --js');
		}
		var script = Files.resolve(gameFolder, js);
		if (!Files.isFile(script))
			throw new CommandError('site: ${Files.relative(script, gameFolder)} is not built yet: haxe $hxml first');
		var code = File.getBytes(script);
		var site = Files.resolve(gameFolder, out);
		if (Files.contains(site, gameFolder))
			throw new CommandError('site: --out $site holds the game itself; name a folder for the site');
		Files.removeFolder(site);
		Files.makeFolder(site);
		File.saveBytes(Path.join([site, "app.js"]), code);
		var config = Path.join([gameFolder, "config.json"]);
		var hasConfig = Files.isFile(config);
		var meta = hasConfig ? '<meta name="helix-config" content="config.json">' : "";
		var page = File.getContent(Path.join([root, "templates", "index.html"]));
		File.saveContent(Path.join([site, "index.html"]), StringTools.replace(StringTools.replace(page, "{{title}}", title), "{{meta}}", meta));
		if (hasConfig)
			File.copy(config, Path.join([site, "config.json"]));
		var favicon = Path.join([gameFolder, "favicon.png"]);
		if (Files.isFile(favicon))
			File.copy(favicon, Path.join([site, "favicon.png"]));
		var assets = Path.join([gameFolder, "assets"]);
		var count = Files.isFolder(assets) ? Files.copyFolder(assets, Path.join([site, "assets"])) : 0;
		Sys.println('site: ${Files.relative(site, gameFolder)}: index.html, app.js (${Std.int(code.length / 1024)} KB), assets/ ($count files)'
			+ (hasConfig ? ", config.json" : "")
			+ (Files.isFile(favicon) ? ", favicon.png" : ""));
		if (zip != null) {
			var archive = Files.resolve(gameFolder, zip);
			Files.zipFolder(site, archive, archive);
			Sys.println('site: ${Files.relative(archive, gameFolder)} (${Std.int(FileSystem.stat(archive).size / 1024)} KB), index.html at its root');
		}
		return site;
	}

	/** The -js path an hxml names (its last, through the hxml files it includes), as written, relative to the game's folder as haxe resolves
		it; null when it names none. */
	public static function hxmlOutput(hxml:String, game:String, seen:Array<String>):Null<String> {
		var full = Files.resolve(game, hxml);
		if (seen.indexOf(full) >= 0)
			return null;
		seen.push(full);
		var tokens = [];
		for (line in File.getContent(full).split("\n")) {
			var code = StringTools.trim(line.split("#")[0]);
			if (code != "")
				tokens = tokens.concat([for (token in ~/\s+/g.split(code)) if (token != "") token]);
		}
		var found:Null<String> = null;
		for (i in 0...tokens.length) {
			var token = tokens[i];
			if ((token == "-js" || token == "--js") && i + 1 < tokens.length)
				found = tokens[i + 1];
			else if (StringTools.endsWith(token, ".hxml") && Files.isFile(Path.join([game, token]))) {
				var included = hxmlOutput(token, game, seen);
				if (included != null)
					found = included;
			}
		}
		return found;
	}
}
