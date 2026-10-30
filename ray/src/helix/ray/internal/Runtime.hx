package helix.ray.internal;

import haxe.io.Bytes;
import helix.platform.Event;
import helix.platform.IAudio;
import helix.platform.IAudioDecoder;
import helix.platform.IEvents;
import helix.platform.IFileSystem;
import helix.platform.IGraphics;
import helix.platform.IImageDecoder;
import helix.platform.IPollable;
import helix.platform.ISystem;
import helix.platform.IWindow;
import helix.services.assets.Assets;
import helix.services.input.Gamepads;
import helix.services.input.Keyboard;
import helix.services.input.Mouse;
import helix.services.input.Touch;
import helix.services.saves.Saves;
import helix.services.time.Time;

using StringTools;

/** Holds what `Raylib`'s functions share: the platform's adapters and the services over them, each made when first needed, the files in
	memory, and the frame.

	raylib answers a load at once. A page can't wait for a file, so on every target helix-ray loads through the `...Async` functions,
	which bring files into memory here. The saves, which hold what `SaveFileText` writes, are read when first used (`withSaves`). */
@:noCompletion
class Runtime {
	public static var system:ISystem;
	public static var window:Null<IWindow> = null;
	public static var events:Null<IEvents> = null;
	public static var graphics:Null<IGraphics> = null;
	public static var frame:Null<Frame> = null;
	public static var time:Null<Time> = null;
	public static var saves:Null<Saves> = null;
	public static var output:Null<IAudio> = null;
	public static var audioDecoder:Null<IAudioDecoder> = null;
	public static var audio:Null<helix.services.audio.Audio> = null;

	/** The program's files, as the preload found them, for what loads from them later (`Audio`, and the `...Async` loads). */
	public static var assets:Null<Assets> = null;

	/** The images, decoding the program's image files and a model's. */
	public static var decoding:Null<helix.services.images.Images> = null;

	public static final polled:Array<IPollable> = [];

	/** What runs as the window closes, before it does: keeping the saves. */
	public static final closing:Array<Void->Void> = [];

	/** The files in memory, by path, as the loads brought them in: images decoded, and every file's bytes. */
	public static final images = new Map<String, helix.services.images.Image>();

	public static final files = new Map<String, Bytes>();

	/** The frame: whether the window should close, whether it was resized this frame, frames left of the `frames` option. */
	public static var shouldClose = false;

	public static var resized = false;
	public static var framesLeft = -1;
	public static var exitKey = 256;
	public static var frames = 0;

	/** The keys pressed this frame, oldest first, read by `GetKeyPressed`. */
	public static final keysPressed:Array<Int> = [];

	static var keyboardService:Null<Keyboard> = null;
	static var mouseService:Null<Mouse> = null;
	static var touchService:Null<Touch> = null;
	static var gamepadsService:Null<Gamepads> = null;
	// The devices made so far, polled each frame; through IPollable, so a device never asked for isn't linked.
	static final devices:Array<IPollable> = [];

	/** Makes the system, then calls the program's `main`.

		@param main  The program's `main`. */
	public static function boot(main:Void->Void):Void {
		#if js
		system = new helix.platform.adapters.system.dom.DomSystemAdapter();
		#else
		system = new helix.platform.adapters.system.sdl3.Sdl3SystemAdapter();
		#end
		var frames = system.getOption("frames");
		if (frames != null)
			framesLeft = Std.parseInt(frames);
		main();
	}

	/** Natively, where the program's files are, relative to the program's directory (`-D helix-ray-native-root`). */
	public static var root = "../web";

	/** Makes what loads the program's files, once: the assets over a page's server and its cache, or natively over the files' directory,
		and the images decoding them. */
	public static function loading():Void {
		if (assets != null)
			return;
		#if js
		var http = new helix.platform.adapters.http.fetchapi.FetchApiHttpAdapter();
		var cache = new helix.platform.adapters.filesystem.browser.BrowserFileSystemAdapter({name: system.getCacheDirectory()});
		var imageDecoder = new helix.platform.adapters.imagedecoder.canvas.CanvasImageDecoderAdapter();
		polled.push(http);
		var callback = new CallbackFiles();
		polled.push(callback);
		assets = new Assets({sources: [FileSystem(callback), HttpServer(system.getProgramDirectory())], httpClient: http, cacheFileSystem: cache});
		#else
		var directory = haxe.io.Path.join([system.getProgramDirectory(), root]);
		var cache = new helix.platform.adapters.filesystem.native.NativeFileSystemAdapter({directory: directory, readOnly: true});
		var imageDecoder = new helix.platform.adapters.imagedecoder.stb.StbImageDecoderAdapter();
		var callback = new CallbackFiles();
		polled.push(callback);
		assets = new Assets({sources: [FileSystem(callback), FileSystem(cache)]});
		#end
		polled.push(cache);
		polled.push(imageDecoder);
		decoding = new helix.services.images.Images(imageDecoder, assets);
		polled.push(decoding);
	}

	/** Brings a file into memory: an image decoded, a glTF file with its images decoded and the files it points to, anything else as
		bytes. Answers at a later poll, never during the call.

		@param path  The file.
		@param done  Receives whether it was brought in, and why not when it wasn't. */
	public static function fetch(path:String, done:Null<String>->Void):Void {
		loading();
		var lower = path.toLowerCase();
		var image = lower.endsWith(".png") || lower.endsWith(".jpg") || lower.endsWith(".jpeg") || lower.endsWith(".bmp") || lower.endsWith(".tga");
		if (image ? images.exists(path) : files.exists(path)) {
			later(() -> done(null));
			return;
		}
		if (image && files.exists(path)) {
			decoding.decode(files.get(path), decoded -> {
				images.set(path, decoded);
				done(null);
			}, error -> done('$path: $error'));
			return;
		}
		assets.load(path, bytes -> {
			// The file's bytes are kept too, for LoadFileDataAsync; an image's are small beside its pixels.
			files.set(path, bytes);
			if (image) {
				decoding.decode(bytes, decoded -> {
					images.set(path, decoded);
					done(null);
				}, error -> done('$path: $error'));
				return;
			}
			if (!(lower.endsWith(".glb") || lower.endsWith(".gltf"))) {
				done(null);
				return;
			}
			// A model's images are decoded now too, and the files it points to brought in, so the model is made at once.
			var file = try Gltf.read(bytes) catch (e:Dynamic) {
				done('$path: $e');
				return;
			}
			var left = 1;
			var one = () -> if (--left == 0) done(null);
			var directory = haxe.io.Path.directory(path);
			for (missing in file.missingBuffers) {
				left++;
				fetch(directory == "" ? missing.uri : directory + "/" + missing.uri, _ -> one());
			}
			for (i in 0...file.list("images").length) {
				var key = Models.imageKey(path, file, i),
					encoded = Models.imageBytes(file, i);
				left++;
				if (encoded == null)
					fetch(key, _ -> one());
				else
					decoding.decode(encoded, image -> {
						images.set(key, image);
						one();
					}, error -> {
						log(4, '$key: $error');
						one();
					});
			}
			one();
		}, error -> done(error));
	}

	/** The least level `log` writes, as `SetTraceLogLevel` sets it: raylib's LOG_INFO (3) until set. */
	public static var logLevel = 3;

	/** The program's log, as `SetTraceLogCallback` sets it, or null for helix-ray's. */
	public static var logCallback:Null<(level:Int, text:String) -> Void> = null;

	/** Writes a message at one of raylib's levels (LOG_*): through the program's callback, or as raylib labels them.

		@param level  The level.
		@param text  The message. */
	public static function log(level:Int, text:String):Void {
		if (level < logLevel)
			return;
		if (logCallback != null) {
			logCallback(level, text);
			return;
		}
		var label = ["", "TRACE", "DEBUG", "INFO", "WARNING", "ERROR", "FATAL"][level < 7 ? level : 4];
		haxe.Log.trace('$label: $text', null);
	}

	/** Calls a function at the next poll: an answer that is ready now, given later, as every answer is.

		@param f  The function. */
	public static function later(f:Void->Void):Void {
		waiting.push(f);
	}

	static var waiting:Array<Void->Void> = [];

	/** Returns a file's bytes, as the program's load callback gives them or an async load brought them in.

		@param path  The file.
		@return  Its bytes, or null when it isn't in memory. */
	public static function file(path:String):Null<Bytes> {
		if (CallbackFiles.load != null) {
			var given = CallbackFiles.load(path);
			if (given != null)
				return given;
		}
		return files.get(path);
	}

	/** Returns an image an async load decoded: an image file's, or one a model holds, by its key (`Models.imageKey`).

		@param key  The file's path, or the model image's key.
		@return  The image, or null when it isn't in memory. */
	public static function image(key:String):Null<helix.services.images.Image> {
		return images.get(key);
	}

	/** Calls a function with the saves once they are read: at once when they are, else when the read answers, in the order asked. The
		first call starts the read, so a program that never saves never reads them. A write asked for during the read is made after it,
		so it wins over what was kept.

		@param ready  Receives the saves. */
	public static function withSaves(ready:Saves->Void):Void {
		if (saves != null && saves.loaded) {
			ready(saves);
			return;
		}
		savesWaiting.push(ready);
		if (saves != null)
			return;
		#if js
		var data = new helix.platform.adapters.filesystem.browser.BrowserFileSystemAdapter({name: system.getDataDirectory()});
		#else
		var data = new helix.platform.adapters.filesystem.native.NativeFileSystemAdapter({directory: system.getDataDirectory()});
		#end
		polled.push(data);
		var kept = new Saves(data);
		saves = kept;
		polled.push(kept);
		closing.push(() -> {
			#if js
			kept.flush();
			#else
			var written = false;
			kept.flush(() -> written = true, error -> {
				log(4, 'saves: $error');
				written = true;
			});
			while (!written) {
				pollAll();
				Sys.sleep(.001);
			}
			#end
		});
		function answer() {
			var waiting = savesWaiting;
			savesWaiting = [];
			for (f in waiting)
				f(kept);
		}
		kept.load(answer, error -> {
			log(4, 'saves: $error');
			answer();
		});
	}

	static var savesWaiting:Array<Saves->Void> = [];

	/** Runs the program's loop body once a frame, in a page, then what follows the loop when it stops.

		@param body  The loop's body.
		@param after  What follows the loop. */
	public static function run(body:Void->Void, after:Void->Void):Void {
		#if js
		var frame:Float->Void = null;
		frame = _ -> {
			body();
			if (shouldClose)
				after();
			else
				js.Browser.window.requestAnimationFrame(frame);
		};
		js.Browser.window.requestAnimationFrame(frame);
		#else
		while (!helix.ray.Raylib.WindowShouldClose())
			body();
		after();
		#end
	}

	/** Opens the window, with the graphics and the events.

		@param width  The window's width, natively.
		@param height  The window's height, natively.
		@param title  The window's title. */
	public static function open(width:Int, height:Int, title:String):Void {
		#if js
		window = new helix.platform.adapters.window.dom.DomWindowAdapter({canvasId: "canvas"});
		events = new helix.platform.adapters.events.dom.DomEventsAdapter({canvasId: "canvas"});
		graphics = new helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter({canvasId: "canvas"});
		#else
		#if sdl_gpu
		window = new helix.platform.adapters.window.sdl3.Sdl3WindowAdapter({graphics: Gpu});
		graphics = new helix.platform.adapters.graphics.sdl3gpu.Sdl3GpuGraphicsAdapter();
		#else
		window = new helix.platform.adapters.window.sdl3.Sdl3WindowAdapter({graphics: Gl});
		graphics = new helix.platform.adapters.graphics.sokol.SokolGraphicsAdapter();
		#end
		events = new helix.platform.adapters.events.sdl3.Sdl3EventsAdapter();
		window.requestSize(width, height);
		// The exit key closes a native window, as raylib's does; a page has none.
		keyboard();
		#end
		window.title = title;
		frame = new Frame(graphics);
		time = new Time(system);
		poll();
	}

	/** Gets the keyboard, made when first asked for. */
	public static function keyboard():Keyboard {
		if (keyboardService == null) {
			#if js
			keyboardService = new Keyboard(events, new helix.platform.adapters.keyboard.dom.DomKeyboardAdapter({events: cast events}));
			#else
			keyboardService = new Keyboard(events, new helix.platform.adapters.keyboard.sdl3.Sdl3KeyboardAdapter({events: cast events}));
			#end
			devices.push(keyboardService);
		}
		return keyboardService;
	}

	/** Gets the mouse, made when first asked for, with the touch, as raylib takes the first finger for the mouse. */
	public static function mouse():Mouse {
		if (mouseService == null) {
			#if js
			mouseService = new Mouse(events, new helix.platform.adapters.mouse.dom.DomMouseAdapter({events: cast events}));
			#else
			mouseService = new Mouse(events, new helix.platform.adapters.mouse.sdl3.Sdl3MouseAdapter({events: cast events}));
			#end
			devices.push(mouseService);
			touch();
		}
		return mouseService;
	}

	/** Gets the touch, made when first asked for. */
	public static function touch():Touch {
		if (touchService == null) {
			#if js
			touchService = new Touch(events, new helix.platform.adapters.touch.dom.DomTouchAdapter({events: cast events}));
			#else
			touchService = new Touch(events, new helix.platform.adapters.touch.sdl3.Sdl3TouchAdapter({events: cast events}));
			#end
			devices.push(touchService);
		}
		return touchService;
	}

	/** Gets the gamepads, made when first asked for, without a dead zone, as raylib's axes have none. */
	public static function gamepads():Gamepads {
		if (gamepadsService == null) {
			#if js
			gamepadsService = new Gamepads(events, new helix.platform.adapters.gamepads.dom.DomGamepadsAdapter({events: cast events}));
			#else
			gamepadsService = new Gamepads(events, new helix.platform.adapters.gamepads.sdl3.Sdl3GamepadsAdapter({events: cast events}));
			#end
			gamepadsService.deadZone = 0;
			devices.push(gamepadsService);
		}
		return gamepadsService;
	}

	/** Draws the frame, shows it, and reads the next frame's input. */
	public static function endFrame():Void {
		frame.draw(window.framebufferWidth, window.framebufferHeight);
		frames++;
		if (framesLeft > 0 && --framesLeft == 0)
			shouldClose = true;
		poll();
	}

	/** Polls the platform and the services, then reads the frame's events. */
	static function poll():Void {
		pollAll();
		if (waiting.length > 0) {
			var now = waiting;
			waiting = [];
			for (f in now)
				f();
		}
		events.poll();
		keysPressed.resize(0);
		resized = false;
		for (event in events.events)
			switch event {
				case CloseRequested:
					shouldClose = true;
				case Resized(_, _):
					resized = true;
				case KeyDown(key, false):
					keysPressed.push(key);
				case _:
			}
		for (device in devices)
			device.poll();
		#if !js
		if (exitKey != 0 && keyboardService.isKeyPressed(cast exitKey))
			shouldClose = true;
		#end
		time.poll();
	}

	static function pollAll():Void {
		for (p in polled)
			p.poll();
	}

	/** Frees what was made, and closes the window where the program owns one. */
	public static function close():Void {
		for (f in closing)
			f();
		if (frame != null)
			frame.dispose();
		if (graphics != null)
			graphics.dispose();
		if (events != null)
			events.dispose();
		if (window != null && window.canClose())
			window.close();
	}
}
