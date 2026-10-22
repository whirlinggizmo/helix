import helix.assets.Assets;
import helix.assets.IAssets;
import helix.host.Presentation;
import helix.input.Input;
import helix.input.InputState;
import helix.render2d.Node2D;
import helix.render2d.Stage;
import helix.render2d.StageService;
import helix.scene.Loader;
import helix.scene.Loading;
import helix.scene.Splash;
import helix.scene.Transition;
import helix.scene.Transition.Fade;
import helix.time.Time;

/** The screens that run themselves on the stage (docs/DISPLAY_MODEL.md): a transition swapping what's shown at its middle and taking its cover
	off at its end; the loading screen shown until its loader is done, held for a press when asked; the splash leaving after its seconds and a
	press, or after its most wait; and the Loader's counting, progress and failures over held loads. Their frames are ticked here by hand
	(Flow.tick), the stage bound as the runner would; nothing is drawn but the stage's own walk. */
class SceneTests {
	static var checks = 0;
	public static var log:Array<String> = [];
	// The loads the test's assets hold, by path: what each does when it loads and when it fails.
	public static var held:Map<String, {loaded:haxe.io.Bytes->Void, failed:String->Void}> = [];

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function took():String {
		var s = log.join(",");
		log = [];
		return s;
	}

	static function main():Void {
		// What the screens and the Loader read, bound as the runner would.
		@:privateAccess Assets.bind(new Held());
		var input = new InputState();
		@:privateAccess Input.bind(input);
		@:privateAccess Time.bind(null, new helix.time.Clock());
		var presentation = new Presentation();
		@:privateAccess presentation.refit(800, 600, 1);
		@:privateAccess helix.host.Screen.bind(presentation);
		var stage = new StageService(new Render2DTests.CountingGraphics(), presentation);
		@:privateAccess Stage.bind(stage);
		function frame(dt:Float):Void {
			@:privateAccess helix.scene.Flow.tick(dt);
			input.endFrame();
		}

		// A transition swaps at its middle, its cover over what's shown, and leaves at its end.
		var title = new Node2D(), level = new Node2D();
		Stage.addChild(title);
		var ended = false, fade = new Fade(1);
		check(fade.swap(title, level, () -> ended = true)
			&& fade.running
			&& Stage.childCount == 2, "Running: its cover on the stage over the title");
		check(!fade.swap(level, title), "Refused while it runs");
		frame(.4);
		check(title.parent != null && level.parent == null, "Before the middle, the title still shown");
		frame(.2);
		check(title.parent == null && level.parent != null && Stage.childCount == 2, "Past the middle: swapped, the cover still over the level");
		frame(.5);
		check(ended && !fade.running && Stage.childCount == 1 && level.parent != null, "Done: its cover off, done called");
		check(new Transition(1).run(() -> {}) && throws(() -> new Transition(0)), "A transition of no time is refused");
		frame(2);

		// The loading screen: shown until its loader is done, then off, then called.
		var loader = new Loader();
		loader.asset("a.txt", _ -> {});
		loader.asset("b.txt", _ -> {});
		var loading = new Loading(loader), started = false;
		check(loading.show(() -> started = true) && loading.shown && !loading.show(() -> {}), "Shown, once");
		frame(1 / 60);
		check(!started && Stage.childCount == 2, "Waiting, on the stage over the level");
		held["a.txt"].loaded(haxe.io.Bytes.alloc(1));
		check(loader.progress == .5 && !loader.done, "Half the loads in");
		held["b.txt"].failed("gone");
		check(loader.done && loader.failures.join(",") == "b.txt: gone", "All ended, a failure named");
		frame(1 / 60);
		check(started && !loading.shown && Stage.childCount == 1, "Done: off the stage, then called");

		// Held for a press once loaded.
		var holding = new Loading(new Loader()), went = false;
		holding.holdForPress = true;
		holding.show(() -> went = true);
		frame(1 / 60);
		frame(1 / 60);
		check(!went && holding.shown, "Loaded, held for a press");
		input.keyEvent(Space, true);
		frame(1 / 60);
		check(went && !holding.shown, "A press lets it go");
		input.keyEvent(Space, false);

		// The splash: at least its seconds, and a press (already come above); or its most wait without one.
		var splash = new Splash(null, 1, new Fade(.5)), next = false;
		check(splash.show(() -> next = true) && !splash.show(() -> {}), "Shown, once");
		frame(.5);
		check(!next && splash.elapsed == .5, "Before its seconds");
		frame(.6);
		frame(.3);
		check(next, "After its seconds, the press come: its transition's middle calls next");
		frame(1);
		check(Stage.childCount == 1, "Gone from the stage, its cover too");
		@:privateAccess Input.bind(new InputState());
		var patient = new Splash(null, .1), onward = false;
		patient.maxWait = 2;
		patient.show(() -> onward = true);
		frame(1);
		check(!onward, "No press: it waits");
		frame(1.1);
		frame(1);
		check(onward, "Past its most wait it goes on without one");
		@:privateAccess Input.bind(input);

		// The loader by itself.
		var loader = new Loader();
		check(loader.done && loader.progress == 1 && loader.count == 0, "An empty loader is done");
		var got:Null<String> = null;
		var complete = loader.wrap("thing", (v:Int) -> got = 'got $v', v -> v < 0 ? "negative" : null);
		check(!loader.done && loader.count == 1, "wrap counts a load");
		complete(-1);
		check(loader.done && got == "got -1" && loader.failures[0] == "thing: negative", "its completion runs and a failure is named");
		@:privateAccess Stage.bind(null);
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}

	static function throws(f:Void->Void):Bool {
		try
			f()
		catch (e:Dynamic)
			return true;
		return false;
	}
}

/** Assets whose loads the test releases by path. */
private class Held implements IAssets {
	public function new() {}

	public function load(path:String, loaded:haxe.io.Bytes->Void, ?failed:String->Void):helix.assets.IRequest
		return ensure(path, loaded, failed);

	public function ensure(path:String, loaded:haxe.io.Bytes->Void, ?failed:String->Void, ?progress:helix.assets.IAssets.AssetProgress->Void,
			?options:helix.assets.IAssets.EnsureOptions):helix.assets.IRequest {
		@:privateAccess SceneTests.held[path] = {loaded: loaded, failed: message -> helix.assets.Failure.report(path, message, failed)};
		return new helix.assets.Request(() -> {});
	}

	public var host(get, never):Null<String>;

	function get_host():Null<String>
		return null;

	public function setHost(host:Null<String>):Bool
		return false;

	public function pingHost(host:String, probePath:String, timeoutSeconds:Float, complete:Bool->Void):helix.assets.IRequest
		return new helix.assets.Request(() -> {});

	public function clearCache(complete:helix.assets.StorageService.StorageWriteResult->Void):helix.assets.IRequest
		return new helix.assets.Request(() -> {});

	public var manifest(get, never):Null<String>;

	function get_manifest():Null<String>
		return null;

	public function setManifest(path:Null<String>):Bool
		return true;

	public var cacheMode(get, set):helix.assets.IAssets.AssetCacheMode;

	function get_cacheMode():helix.assets.IAssets.AssetCacheMode
		return Revalidate;

	function set_cacheMode(mode:helix.assets.IAssets.AssetCacheMode):helix.assets.IAssets.AssetCacheMode {
		return mode;
	}

	public function streamSource(path:String, located:helix.assets.IAssets.AudioLocation->Void, ?failed:String->Void,
			download:Bool = false):helix.assets.IRequest
		return new helix.assets.Request(() -> {});

	public function subscribe(path:String, target:helix.assets.IReloadable):Void {}

	public function unsubscribe(path:String, target:helix.assets.IReloadable):Void {}

	public var busy(get, never):Bool;

	function get_busy():Bool
		return false;
}
