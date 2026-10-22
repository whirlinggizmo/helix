import helix.AppOptions;

/** The examples' entry point, one for every backend: the example's App (examples/<name>/App.hx) run by helix.App under the identity
	"HeliX" / the example's name (-D example), on the assets the examples share beside their directories (../assets; with the manifests
	tools/example.py writes in the browser, so a returning page re-fetches only what changed), the development extras on in every build
	(F9 screenshots; the page told the program's state, for the tools capturing the site's pages). The backend is the build's
	(-D helix-backend). */
class Main {
	public static function main():Void {
		var options = new AppOptions();
		options.product = haxe.macro.Compiler.getDefine("example");
		options.company = "HeliX";
		#if js
		options.assets = "../assets/";
		options.manifest = "manifest.json";
		#else
		options.assets = "../assets";
		#end
		options.devKeys = true;
		options.pageState = true;
		new App(options);
	}
}
