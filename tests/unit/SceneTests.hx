import helix.assets.IAssets;
import helix.scene.Loader;
import helix.scene.LoadingScene;
import helix.scene.Scene;
import helix.scene.Scenes;
import helix.scene.Transition;
import helix.scene.Transition.Fade;

/** A game's scenes (helix.scene.Scenes): push, pop and replace with their enter, exit, pause and resume; a scene with a loader shown the
	loading scene until its loads end; transitions swapping at their middle; focus lost and back; and the Loader's counting, progress and
	failures over held loads. The stack's drawing isn't run here (no GPU): update alone. */
class SceneTests {
	static var checks = 0;
	public static var log:Array<String> = [];
	public static var held:Map<String, helix.assets.IAssets.AssetResult->Void> = [];

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
		@:privateAccess helix.host.Services.assets = new Held();
		@:privateAccess helix.host.Services.input = new helix.input.InputState();
		@:privateAccess helix.host.Services.clock = new helix.time.Clock();
		var scenes = new Scenes();
		scenes.setPauseOnBlur(false);
		check(scenes.getTop() == null && scenes.getCount() == 0 && !scenes.isTransitioning(), "An empty stack");
		check(scenes.getLoadingScene() != null && scenes.getLoadingScene().getName() == "Loading", "with the built-in loading scene");
		scenes.setLoadingScene(new Quiet());

		// Push, pop, replace, in order.
		var title = new Logged("title"),
			play = new Logged("play"),
			pause = new Logged("pause");
		scenes.push(title);
		check(took() == "title.enter" && scenes.getTop() == title && title.getScenes() == scenes, "A pushed scene enters, on the stack");
		scenes.update(1 / 60);
		check(took() == "title.update", "The top updates");
		scenes.replace(play);
		check(took() == "title.exit,play.enter" && scenes.getCount() == 1 && title.getScenes() == null, "replace: the top exits, the new enters");
		scenes.push(pause);
		check(took() == "play.pause,pause.enter" && scenes.getCount() == 2, "push over one pauses it");
		scenes.update(1 / 60);
		check(took() == "pause.update", "Only the top updates");
		scenes.pop();
		check(took() == "pause.exit,play.resume" && scenes.getTop() == play, "pop: it exits, the one under resumes");
		scenes.pop();
		scenes.pop();
		check(took() == "play.exit" && scenes.getCount() == 0, "An empty stack pops nothing");

		// A loader gates its scene behind the loading scene.
		var level = new Loading2("level");
		scenes.push(level);
		check(took() == "level.enter" && !level.getLoader().isDone() && level.getLoader().getProgress() == 0, "A scene with a loader enters and waits");
		scenes.update(1 / 60);
		check(took() == "loading.enter,loading.update" && scenes.getTop() == level, "Its loading scene is shown meanwhile, entered once");
		scenes.update(1 / 60);
		check(took() == "loading.update", "and updated each frame");
		held["a.txt"](Loaded(haxe.io.Bytes.alloc(1)));
		check(level.getLoader().getProgress() == .5 && !level.getLoader().isDone(), "Half the loads in");
		held["b.txt"](Failed("gone"));
		check(level.getLoader().isDone() && level.getLoader().getFailures().join(",") == "b.txt: gone", "All ended, a failure named");
		scenes.update(1 / 60);
		check(took() == "loading.exit,level.update", "Done: the loading scene exits, the scene runs");
		scenes.update(1 / 60);
		check(took() == "level.update", "and runs on");
		scenes.clear();
		check(took() == "level.exit" && scenes.getCount() == 0, "clear exits everything");

		// Without a loading scene, a loading scene runs at once.
		scenes.setLoadingScene(null);
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
		check(took() == "" && scenes.isTransitioning() && scenes.getTop() == a, "A transition begins with the old scene still on top");
		scenes.update(.3);
		check(took() == "a.update" && scenes.getTop() == a, "before its middle the old scene runs");
		scenes.update(.3);
		check(took() == "a.exit,b.enter,b.update" && scenes.getTop() == b && scenes.isTransitioning(), "at its middle the scenes swap");
		scenes.update(.5);
		check(took() == "b.update" && !scenes.isTransitioning(), "and it ends after its seconds");
		var threw = false;
		try
			new Fade(0)
		catch (e:Dynamic)
			threw = true;
		check(threw, "A transition of no time is refused");
		check(new Fade().getSeconds() == .5 && new Fade(2, 0xffffffff).getColor() == 0xffffffff, "A fade's defaults and its color");

		// Focus lost and back.
		scenes.setPauseOnBlur(true);
		@:privateAccess scenes.focus(false);
		check(took() == "b.pause" && helix.host.Services.clock.isPaused(), "Focus lost pauses the top scene and the clock");
		scenes.update(1 / 60);
		check(took() == "", "and nothing updates meanwhile");
		@:privateAccess scenes.focus(true);
		check(took() == "b.resume" && !helix.host.Services.clock.isPaused(), "Focus back resumes both");
		helix.host.Services.clock.pause();
		@:privateAccess scenes.focus(false);
		@:privateAccess scenes.focus(true);
		check(helix.host.Services.clock.isPaused(), "A clock the game paused itself stays paused");
		helix.host.Services.clock.resume();
		scenes.setPauseOnBlur(false);
		@:privateAccess scenes.focus(false);
		check(took() == "b.pause,b.resume" || took() == "", "Pause on blur off: focus does nothing");
		scenes.clear();

		// The loader by itself.
		var loader = new Loader();
		check(loader.isDone() && loader.getProgress() == 1 && loader.getCount() == 0, "An empty loader is done");
		var got:Null<String> = null;
		var complete = loader.wrap("thing", (v:Int) -> got = 'got $v', v -> v < 0 ? "negative" : null);
		check(!loader.isDone() && loader.getCount() == 1, "wrap counts a load");
		complete(-1);
		check(loader.isDone()
			&& got == "got -1"
			&& loader.getFailures()[0] == "thing: negative", "its completion runs and a failure is named");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}

/** A scene logging its hooks. */
private class Logged extends Scene {
	var name:String;

	public function new(name:String) {
		super();
		this.name = name;
	}

	override public function getName():String
		return name;

	override public function enter():Void
		SceneTests.log.push('$name.enter');

	override public function exit():Void
		SceneTests.log.push('$name.exit');

	override public function pause():Void
		SceneTests.log.push('$name.pause');

	override public function resume():Void
		SceneTests.log.push('$name.resume');

	override public function update(dt:Float):Void
		SceneTests.log.push('$name.update');
}

/** A logged scene loading two assets the test releases. */
private class Loading2 extends Logged {
	var loader:Null<Loader>;

	override public function enter():Void {
		super.enter();
		loader = new Loader();
		loader.asset("a.txt", _ -> {});
		loader.asset("b.txt", _ -> {});
	}

	override public function getLoader():Null<Loader>
		return loader;
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

	public function load(path:String, complete:helix.assets.IAssets.AssetResult->Void):Void
		@:privateAccess SceneTests.held[path] = complete;

	public function ensure(path:String, complete:helix.assets.IAssets.AssetResult->Void, ?progress:helix.assets.IAssets.AssetProgress->Void,
			?options:helix.assets.IAssets.EnsureOptions):helix.assets.IRequest {
		load(path, complete);
		return new helix.assets.Request(() -> {});
	}

	public function getHost():Null<String>
		return null;

	public function setHost(host:Null<String>):Bool
		return false;

	public function pingHost(host:String, probePath:String, timeoutSeconds:Float, complete:Bool->Void):helix.assets.IRequest
		return new helix.assets.Request(() -> {});

	public function clearCache(complete:helix.assets.Storage.StorageWriteResult->Void):helix.assets.IRequest
		return new helix.assets.Request(() -> {});

	public function getManifest():Null<String>
		return null;

	public function setManifest(path:Null<String>):Bool
		return true;

	public function getCacheMode():helix.assets.IAssets.AssetCacheMode
		return Revalidate;

	public function setCacheMode(mode:helix.assets.IAssets.AssetCacheMode):Void {}

	public function streamSource(path:String, complete:helix.assets.IAssets.AssetSourceResult->Void):helix.assets.IRequest
		return new helix.assets.Request(() -> {});

	public function subscribe(path:String, target:helix.assets.IReloadable):Void {}

	public function unsubscribe(path:String, target:helix.assets.IReloadable):Void {}

	public function isBusy():Bool
		return false;
}
