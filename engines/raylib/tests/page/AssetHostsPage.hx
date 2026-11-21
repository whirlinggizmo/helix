import helix.raylib.Raylib.*;
import helix.raylib.extras.Assets.*;
import js.Browser;

/** Checks the asset hosts in a page (tools/test_raylib_pages.py), over the directories of AssetHostsPage.files beside the page: the
	default host, the page's own directory; a directory host before a URL host overriding its file, and the second read for a file the
	first has none of, which costs the page's one 404 (AssetHostsPage.check.json); the cache listed by directory, each file with its
	host's URL, whatever the hosts in use; the cache emptied, and a deleted file fetched and listed again. Leaves
	{passed, checks, failures} in `window.helixResult`. */
class AssetHostsPage {
	static var checks = 0;
	static final failures:Array<String> = [];

	static function check(value:Bool, message:String):Void {
		if (value)
			checks++;
		else
			failures.push(message);
	}

	// The cache's files under a directory, each "<file name> <host>", joined by `,`.
	static function cached(path:String):String {
		var list:Null<String> = null;
		ListAssetCacheAsync(path, assets -> list = [for (asset in assets) asset.fileName + " " + asset.host].join(","), error -> list = 'failed: $error');
		var frames = 0;
		while (list == null && frames++ < 600) {
			BeginDrawing();
			EndDrawing();
		}
		return list;
	}

	// The whole cache's listing once it is the one expected, a fetched file being stored after its load answers, or as it is two seconds on.
	static function settled(expected:String):String {
		var list = cached(""), tries = 0;
		while (list != expected && tries++ < 20) {
			WaitTime(.1);
			list = cached("");
		}
		return list;
	}

	static function main():Void {
		Reflect.setField(Browser.window, "helixResult", null);
		InitWindow(320, 240, "hosts");
		var page = Browser.location.href;
		var root = page.substr(0, page.lastIndexOf("/") + 1);
		check(GetAssetHosts().length == 1 && GetAssetHosts()[0] == "", 'the default host, the page\'s own directory: ${GetAssetHosts()}');
		check(LoadFileText("base/a.txt") == "base a", "a file read from the page's own directory");

		// A directory before a URL overrides its file, and the URL is read for a file the directory has none of.
		SetAssetHosts(["mods/", root + "base/"]);
		check(LoadFileText("a.txt") == "modded a", 'the first host\'s file: ${LoadFileText("a.txt")}');
		check(LoadFileText("levels/b.txt") == "b", "the second host's file where the first has none");
		var both = 'a.txt ${root}mods/,base/a.txt $root,levels/b.txt ${root}base/';
		check(settled(both) == both, 'the cache listed by file name, each file with its host\'s URL: ${cached("")}');

		// The cache is every host's, whatever the hosts in use.
		SetAssetHosts(["base/"]);
		check(LoadFileText("a.txt") == "base a", 'the hosts set again: a file loaded before read from the host now in use: ${LoadFileText("a.txt")}');
		check(settled('a.txt ${root}base/,$both') == 'a.txt ${root}base/,$both', 'the cache listed with the earlier hosts\' files: ${cached("")}');
		check(cached("levels") == 'levels/b.txt ${root}base/', 'the cache listed under a directory: ${cached("levels")}');

		// Emptied, and a deleted file fetched and listed again.
		var cleared:Null<String> = null, frames = 0;
		ClearAssetCacheAsync(() -> cleared = "", error -> cleared = error);
		while (cleared == null && frames++ < 600) {
			BeginDrawing();
			EndDrawing();
		}
		check(cleared == "" && cached("") == "", 'the cache emptied: $cleared, ${cached("")}');
		ReleaseAsset("levels/b.txt");
		check(LoadFileText("levels/b.txt") == "b", "a deleted file, released from memory, fetched again");
		check(settled('levels/b.txt ${root}base/') == 'levels/b.txt ${root}base/', 'and listed with its host again: ${cached("")}');

		CloseWindow();
		var result:Dynamic = {passed: failures.length == 0, checks: checks, failures: failures};
		Reflect.setField(Browser.window, "helixResult", result);
	}
}
