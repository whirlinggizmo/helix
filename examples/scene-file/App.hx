import helix.assets.Assets;
import helix.behavior.Behavior;
import helix.debug.Autopilot;
import helix.debug.FpsOverlay;
import helix.debug.TestHarness;
import helix.graphics.Graphics;
import helix.graphics.Screenshots;
import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.IInput;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Stage2D;
import helix.render2d.Text2D;
import helix.render3d.Camera3D;
import helix.render3d.Stage3D;
import helix.scene.Scene;
import helix.scene.SceneFile;
import helix.scene.SceneFiles;
import helix.scene.SceneInstance;
import helix.scene.Scenes;
import helix.time.Ticker;
import helix.time.Time;
import helix.host.ScreenShape;

/** A racer slice entirely from a scene file (helix.scene.SceneFile) and behaviors (helix.behavior): scenes/track.scene holds the stage's
	sky, ambient light and tone mapping, the sun with its shadows, a closed loop of Kenney's Racing Kit pieces with barriers, a gantry and
	scenery (laid by tools/gen_loop.py), eight checkpoints, the race, the car (a prefab, scenes/car.scene, the kit's sports car) and the chase
	camera; nothing of the world is in code. The behaviors (Car, ChaseCamera, Checkpoint, Race) drive it, run by the Play scene's pass
	(Scene.behaviors) at a fixed 60 Hz through a Ticker. UP / DOWN or W / S drive and brake, LEFT / RIGHT or A / D steer, a pad's left stick
	and triggers too; R restarts the race (the instance destroyed and made again); Escape quits where quitting means anything. The HUD shows
	the lap, its time and the best. Options: autopilot (a script under assets/), fast (1: up to 120 ticks a frame under autopilot) and
	autoclose (1: quit once the script is done); the probes are loaded, state, lap, checkpoint, passed, lapTime, bestLap, carX, carZ and
	speed. */
class App extends helix.App {
	/** The input the game is played with this tick: the window's, or the autopilot's while a script runs. The Car reads it. Kept across a
		hot reload (@:hot): set every tick, but a reload between ticks would leave it null for a frame otherwise. */
	@:hot public static var input:IInput;

	/** The behaviors the scene file names: listed so the build keeps their classes, which register themselves with BehaviorRegistry as the
		program starts (a class nothing names is never compiled in). */
	static var BEHAVIORS:Array<Class<Behavior>> = [Car, ChaseCamera, Checkpoint, Race];

	var scenes:Scenes;
	var play:Play;
	var ticker:Ticker;
	var pilot:Null<Autopilot>;
	var fast = false;
	var published = false;

	override public function init():Void {
		scenes = new Scenes();
		play = new Play();
		Window.title = "HeliX scene-file";
		Window.requestSize(1200, 675);
		ticker = new Ticker(Input.instance);
		ticker.maxSteps = 6;
		fast = Host.getOption("fast", "0") == "1";
		var script = Host.getOption("autopilot", "");
		if (script != "")
			Assets.load(script, bytes -> startPilot(bytes), message -> throw 'Autopilot load failed: ' + message);
		else
			scenes.push(play);
	}

	// The autopilot's script in: the pilot made, then the game started.
	function startPilot(bytes:haxe.io.Bytes):Void {
		pilot = new Autopilot(bytes.toString(), name -> Screenshots.take(name));
		// The window of a headless run isn't focused: its ticks run regardless.
		scenes.pauseOnBlur = false;
		scenes.push(play);
	}

	// A named value of the game for the autopilot, and the final game it publishes.
	function probe(name:String):Dynamic {
		var race = play.race, car = play.car;
		return switch name {
			// The instance's ready, and its ready lambda run (the pass's update after the flag), so the race and the car are found.
			case "loaded": play.instance != null && play.instance.ready && race != null;
			case "state": race == null ? "" : race.state;
			case "lap": race == null ? 0 : race.lap;
			case "checkpoint": race == null ? 0 : race.checkpoint;
			case "passed": race == null ? 0 : race.passed;
			case "lapTime": race == null ? 0 : hundredths(race.lapTime);
			case "bestLap": race == null ? 0 : hundredths(race.bestLap);
			case "carX": car == null ? 0 : hundredths(car.carX);
			case "carZ": car == null ? 0 : hundredths(car.carZ);
			case "speed": car == null ? 0 : hundredths(car.speed);
			default: throw 'Unknown probe ' + name;
		}
	}

	// A value to two decimals, the same on every target.
	static function hundredths(value:Float):Float
		return Math.round(value * 100) / 100;

	// One tick of the game from source: the behaviors and the scene at a sixtieth of a second.
	function tick(source:IInput):Void {
		input = source;
		scenes.input = source;
		scenes.update(1 / 60);
	}

	override public function frame(dt:Float):Void {
		if (pilot != null && !pilot.done) {
			// The script's ticks, each a sixtieth of a second to the game, many a frame when fast.
			for (_ in 0...(fast ? 120 : 1)) {
				var source:IInput = pilot.advance(name -> probe(name));
				if (pilot.done)
					break;
				tick(source);
				source.consume();
			}
		} else
			ticker.advance(Time.clock.elapsed, () -> tick(Input.instance));
		play.fps.update(dt, Time.frameCpu);
		if (scenes.top == null) {
			Graphics.beginFrame(Window.framebufferWidth, Window.framebufferHeight, 0x14161cff);
			Graphics.endFrame();
		} else
			scenes.draw();
		if (pilot != null && pilot.done && !published) {
			published = true;
			var game:Dynamic = {};
			for (name in [
				"loaded",
				"state",
				"lap",
				"checkpoint",
				"passed",
				"lapTime",
				"bestLap",
				"carX",
				"carZ",
				"speed"
			])
				Reflect.setField(game, name, probe(name));
			TestHarness.publish({game: game, autopilot: pilot.snapshot});
			if (Host.getOption("autoclose", "0") == "1")
				Host.quit();
		}
	}

	override public function cleanup():Void {
		scenes.destroy();
	}
}

/** The level: the track's file loaded through SceneFiles and instantiated onto its stage with the scene's own pass; drawn with the camera
	the file made (the Camera3D named chase), the sun's shadows first; a HUD line over it. R destroys the instance and makes it again. */
class Play extends Scene {
	/** The track's file. */
	public static inline var TRACK = "scenes/track.scene";

	/** The file instantiated, or null until it has loaded. */
	public var instance(default, null):Null<SceneInstance>;

	/** The race's behavior, once the instance is ready; null before. */
	public var race(default, null):Null<Race>;

	/** The car's behavior, once the instance is ready; null before. */
	public var car(default, null):Null<Car>;

	/** The frame rate readout. */
	public var fps(default, null) = new FpsOverlay();

	var stage = new Stage3D();
	var file:Null<SceneFile>;
	var camera:Null<Camera3D>;
	var fallback = new Camera3D();
	var hud = new Stage2D();
	var hudCamera = new Camera2D();
	var line:Text2D;
	var help:Text2D;
	var batch:Batch2D;

	override public function enter():Void {
		batch = new Batch2D();
		line = new Text2D("Loading the track", 22, 0xf5f5f5ff);
		help = new Text2D("", 15, 0xc8c8c8ff);
		hud.add(line);
		hud.add(help);
		fallback.setView(0, 40, 60, 0, 0, 0);
		SceneFiles.load(TRACK, loaded -> place(loaded), message -> line.text = message);
	}

	// The file in: instantiated onto the stage, with this scene's pass.
	function place(loaded:SceneFile):Void {
		file = loaded;
		restart();
	}

	// The instance made from the file (the last one destroyed first): the race starts over from its countdown.
	function restart():Void {
		if (instance != null)
			instance.destroy();
		race = null;
		car = null;
		camera = null;
		instance = file.instantiate(stage, behaviors, () -> ready());
	}

	// Everything has landed and the behaviors have started: the camera and the behaviors the HUD and the probes read.
	function ready():Void {
		camera = Std.downcast(instance.node("chase"), Camera3D);
		race = behaviors.find(Race);
		car = behaviors.find(Car);
	}

	override public function update(dt:Float):Void {
		var input = scenes.input;
		if (input.isFramePressed(Key.Escape) && Host.canQuit())
			Host.quit();
		if (input.isFramePressed(Key.R) && file != null)
			restart();
	}

	override public function draw():Void {
		var width = Window.framebufferWidth, height = Window.framebufferHeight;
		var view = camera != null ? camera : fallback;
		view.setViewport(width, height);
		ScreenShape.update();
		var presentation = Screen.instance;
		presentation.apply(hudCamera);
		var vx = presentation.visibleX,
			vy = presentation.visibleY,
			vw = presentation.visibleWidth;
		line.setPosition(vx + 12, vy + 36);
		help.setPosition(vx + 12, vy + 66);
		if (race != null) {
			line.text = race.racing ? 'Lap ${race.lap}   ${seconds(race.lapTime)}   best ${race.bestLap > 0 ? seconds(race.bestLap) : "--"}' : 'Ready: ${Math.ceil(race.remaining)}';
			help.text = "UP / DOWN drive, LEFT / RIGHT steer, R restart" + (Host.canQuit() ? ", ESC quit" : "");
		}
		stage.drawShadows(view);
		Graphics.beginFrame(width, height, 0x7896c8ff);
		stage.draw(view);
		batch.begin(hudCamera);
		hud.draw(batch, hudCamera);
		fps.draw(batch, vx + vw - 150, vy + 10);
		batch.end();
	}

	// Seconds as m:ss.hh.
	static function seconds(value:Float):String {
		var whole = Math.floor(value),
			hundredths = Math.floor((value - whole) * 100);
		var minutes = Math.floor(whole / 60), rest = whole - minutes * 60;
		return '$minutes:${rest < 10 ? "0" : ""}$rest.${hundredths < 10 ? "0" : ""}$hundredths';
	}

	override public function exit():Void {
		if (instance != null)
			instance.destroy();
		instance = null;
		stage.destroy();
		batch.destroy();
	}
}
