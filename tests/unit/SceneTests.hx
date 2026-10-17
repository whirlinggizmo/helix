import helix.assets.IAssets;
import helix.scene.Loader;
import helix.scene.LoadingScene;
import helix.scene.Scene;
import helix.scene.Scenes;
import helix.scene.Transition;
import helix.scene.Transition.Fade;
import helix.assets.Assets;
import helix.input.Input;
import helix.time.Time;

/** A game's scenes (helix.scene.Scenes): push, pop and replace with their enter, exit, pause and resume; a scene with a loader shown the
	loading scene until its loads end; transitions swapping at their middle; focus lost and back; and the Loader's counting, progress and
	failures over held loads. The stack's drawing isn't run here (no GPU): update alone. */
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
		// What Scenes and the Loader read, bound as the runner would.
		@:privateAccess Assets.bind(new Held());
		@:privateAccess Input.bind(new helix.input.InputState());
		@:privateAccess Time.bind(null, new helix.time.Clock());
		var scenes = new Scenes();
		scenes.pauseOnBlur = false;
		check(scenes.top == null && scenes.count == 0 && !scenes.transitioning, "An empty stack");
		check(scenes.loadingScene != null && scenes.loadingScene.name == "Loading", "with the built-in loading scene");
		scenes.loadingScene = new Quiet();

		// Push, pop, replace, in order.
		var title = new Logged("title"),
			play = new Logged("play"),
			pause = new Logged("pause");
		scenes.push(title);
		check(took() == "title.enter" && scenes.top == title && title.scenes == scenes, "A pushed scene enters, on the stack");
		scenes.update(1 / 60);
		check(took() == "title.update", "The top updates");
		scenes.replace(play);
		check(took() == "title.exit,play.enter" && scenes.count == 1 && title.scenes == null, "replace: the top exits, the new enters");
		scenes.push(pause);
		check(took() == "play.pause,pause.enter" && scenes.count == 2, "push over one pauses it");
		scenes.update(1 / 60);
		check(took() == "pause.update", "Only the top updates");
		scenes.pop();
		check(took() == "pause.exit,play.resume" && scenes.top == play, "pop: it exits, the one under resumes");
		scenes.pop();
		scenes.pop();
		check(took() == "play.exit" && scenes.count == 0, "An empty stack pops nothing");

		// A loader gates its scene behind the loading scene.
		var level = new Loading2("level");
		scenes.push(level);
		check(took() == "level.enter" && !level.loader.done && level.loader.progress == 0, "A scene with a loader enters and waits");
		scenes.update(1 / 60);
		check(took() == "loading.enter,loading.update" && scenes.top == level, "Its loading scene is shown meanwhile, entered once");
		scenes.update(1 / 60);
		check(took() == "loading.update", "and updated each frame");
		held["a.txt"].loaded(haxe.io.Bytes.alloc(1));
		check(level.loader.progress == .5 && !level.loader.done, "Half the loads in");
		held["b.txt"].failed("gone");
		check(level.loader.done && level.loader.failures.join(",") == "b.txt: gone", "All ended, a failure named");
		scenes.update(1 / 60);
		check(took() == "loading.exit,level.update", "Done: the loading scene exits, the scene runs");
		scenes.update(1 / 60);
		check(took() == "level.update", "and runs on");
		scenes.clear();
		check(took() == "level.exit" && scenes.count == 0, "clear exits everything");

		// Without a loading scene, a loading scene runs at once.
		scenes.loadingScene = null;
		var early = new Loading2("early");
		scenes.push(early);
		scenes.update(1 / 60);
		check(took() == "early.enter,early.update", "No loading scene: the scene runs while it loads");
		scenes.clear();
		took();

		// A transition swaps at its middle.
		var a = new Logged("a"), b = new Logged("b");
		scenes.push(a);
		took();
		scenes.replace(b, new Fade(1));
		check(took() == "" && scenes.transitioning && scenes.top == a, "A transition begins with the old scene still on top");
		scenes.update(.3);
		check(took() == "a.update" && scenes.top == a, "before its middle the old scene runs");
		scenes.update(.3);
		check(took() == "a.exit,b.enter,b.update" && scenes.top == b && scenes.transitioning, "at its middle the scenes swap");
		scenes.update(.5);
		check(took() == "b.update" && !scenes.transitioning, "and it ends after its seconds");
		var threw = false;
		try
			new Fade(0)
		catch (e:Dynamic)
			threw = true;
		check(threw, "A transition of no time is refused");
		check(new Fade().seconds == .5 && new Fade(2, 0xffffffff).color == 0xffffffff, "A fade's defaults and its color");

		// Focus lost and back.
		scenes.pauseOnBlur = true;
		@:privateAccess scenes.focus(false);
		check(took() == "b.pause" && Time.clock.paused, "Focus lost pauses the top scene and the clock");
		scenes.update(1 / 60);
		check(took() == "", "and nothing updates meanwhile");
		@:privateAccess scenes.focus(true);
		check(took() == "b.resume" && !Time.clock.paused, "Focus back resumes both");
		Time.clock.pause();
		@:privateAccess scenes.focus(false);
		@:privateAccess scenes.focus(true);
		check(Time.clock.paused, "A clock the game paused itself stays paused");
		Time.clock.resume();
		scenes.pauseOnBlur = false;
		@:privateAccess scenes.focus(false);
		check(took() == "b.pause,b.resume" || took() == "", "Pause on blur off: focus does nothing");
		scenes.clear();

		// A loading scene that holds after the loads, until it says go; quick skips it and the transitions.
		took();
		scenes.loadingScene = new Holder();
		var held2 = new Loading2("held");
		scenes.push(held2);
		scenes.update(1 / 60);
		held["a.txt"].loaded(haxe.io.Bytes.alloc(1));
		held["b.txt"].loaded(haxe.io.Bytes.alloc(1));
		scenes.update(1 / 60);
		check(took() == "held.enter,loading.enter,loading.update,loading.update" && scenes.loading, "Loaded, the loading scene holds on");
		Holder.go = true;
		scenes.update(1 / 60);
		check(took() == "loading.exit,held.update" && !scenes.loading, "until it says go");
		scenes.clear();
		took();
		scenes.quick = true;
		var q = new Logged("q");
		scenes.push(q, new Fade(1));
		check(took() == "q.enter" && !scenes.transitioning, "Quick: a transition is skipped, the change at once");
		scenes.quick = false;
		scenes.clear();
		took();
		// A splash goes on after its most wait without a press, or at once when quick.
		var after = new Logged("after");
		var splash = new helix.scene.Splash(null, 1, after, new Fade(1));
		splash.maxWait = -1;
		check(splash.maxWait == 0, "The most wait is 0 or more");
		splash.maxWait = 2;
		scenes.push(splash);
		took();
		scenes.update(1.5);
		check(scenes.top == splash && !scenes.transitioning && took() == "", "Shown its seconds, it waits for a press");
		scenes.update(.6);
		check(scenes.transitioning, "past its most wait it goes on without one");
		scenes.update(.5);
		check(scenes.top == after && took() == "after.enter,after.update", "to the next scene");
		scenes.clear();
		took();
		scenes.quick = true;
		scenes.push(new helix.scene.Splash(null, 5, new Logged("now")));
		scenes.update(1 / 60);
		check(scenes.top.name == "now", "Quick: the splash goes on at the first update");
		scenes.quick = false;
		scenes.clear();
		took();

		// The loader by itself.
		var loader = new Loader();
		check(loader.done && loader.progress == 1 && loader.count == 0, "An empty loader is done");
		var got:Null<String> = null;
		var complete = loader.wrap("thing", (v:Int) -> got = 'got $v', v -> v < 0 ? "negative" : null);
		check(!loader.done && loader.count == 1, "wrap counts a load");
		complete(-1);
		check(loader.done && got == "got -1" && loader.failures[0] == "thing: negative", "its completion runs and a failure is named");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}

/** A scene logging its hooks. */
private class Logged extends Scene {
	var label:String;

	public function new(name:String) {
		super();
		this.label = name;
	}

	override function get_name():String
		return label;

	override public function enter():Void
		SceneTests.log.push('$label.enter');

	override public function exit():Void
		SceneTests.log.push('$label.exit');

	override public function pause():Void
		SceneTests.log.push('$label.pause');

	override public function resume():Void
		SceneTests.log.push('$label.resume');

	override public function update(dt:Float):Void
		SceneTests.log.push('$label.update');
}

/** A logged scene loading two assets the test releases. */
private class Loading2 extends Logged {
	var loads:Null<Loader>;

	override public function enter():Void {
		super.enter();
		loads = new Loader();
		loads.asset("a.txt", _ -> {});
		loads.asset("b.txt", _ -> {});
	}

	override function get_loader():Null<Loader>
		return loads;
}

/** A loading scene holding after the loads until told to go. */
private class Holder extends Quiet {
	public static var go = false;

	override function get_holding():Bool
		return !go;
}

/** A loading scene logging its hooks. */
private class Quiet extends LoadingScene {
	override public function enter():Void
		SceneTests.log.push("loading.enter");

	override public function exit():Void
		SceneTests.log.push("loading.exit");

	override public function update(dt:Float):Void
		SceneTests.log.push("loading.update");
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

	public function streamSource(path:String, located:helix.assets.IAssets.AudioLocation->Void, ?failed:String->Void):helix.assets.IRequest
		return new helix.assets.Request(() -> {});

	public function subscribe(path:String, target:helix.assets.IReloadable):Void {}

	public function unsubscribe(path:String, target:helix.assets.IReloadable):Void {}

	public var busy(get, never):Bool;

	function get_busy():Bool
		return false;
}
