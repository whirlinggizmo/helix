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

/** Holds what `Raylib`'s functions share: the platform's adapters and the services over them, each made when first needed, the files
	loaded before the program's `main`, and the frame.

	raylib answers at once where the platform answers later, so the files under the program's assets directory are loaded, and its
	images decoded, before `main` runs, as raylib's web builds preload theirs; the saves, which hold what `SaveFileText` writes, too. */
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
	public static final polled:Array<IPollable> = [];

	/** What runs as the window closes, before it does: keeping the saves. */
	public static final closing:Array<Void->Void> = [];

	/** The files loaded before `main`, by path: images decoded, the rest as bytes. */
	public static final images = new Map<String, {pixels:Bytes, width:Int, height:Int}>();

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

	/** Makes the system, then runs each preload and calls the program's `main` once all have answered.

		@param preloads  What must be read before `main`: the files (`preloadFiles`) and the saves (`preloadSaves`), as the program uses
			them.
		@param main  The program's `main`. */
	public static function boot(preloads:Array<(done:Void->Void)->Void>, main:Void->Void):Void {
		#if js
		system = new helix.platform.adapters.system.dom.DomSystemAdapter();
		#else
		system = new helix.platform.adapters.system.sdl3.Sdl3SystemAdapter();
		#end
		var frames = system.getOption("frames");
		if (frames != null)
			framesLeft = Std.parseInt(frames);
		var left = preloads.length;
		for (preload in preloads)
			preload(() -> left--);
		#if js
		var wait:Float->Void = null;
		wait = _ -> {
			pollAll();
			if (left > 0)
				js.Browser.window.requestAnimationFrame(wait);
			else
				main();
		};
		if (left > 0)
			js.Browser.window.requestAnimationFrame(wait);
		else
			main();
		#else
		while (left > 0) {
			pollAll();
			Sys.sleep(.001);
		}
		main();
		#end
	}

	/** Returns the preload of the program's files: each loaded, and each image decoded.

		@param paths  The files, as the program names them.
		@param root  Natively, the directory they're under, relative to the program's.
		@return  The preload. */
	public static function preloadFiles(paths:Array<String>, root:String):(done:Void->Void)->Void {
		return done -> {
			#if js
			var http = new helix.platform.adapters.http.fetchapi.FetchApiHttpAdapter();
			var cache = new helix.platform.adapters.filesystem.browser.BrowserFileSystemAdapter({name: system.getCacheDirectory()});
			var imageDecoder = new helix.platform.adapters.imagedecoder.canvas.CanvasImageDecoderAdapter();
			polled.push(http);
			var assets = new Assets({sources: [HttpServer(system.getProgramDirectory())], httpClient: http, cacheFileSystem: cache});
			#else
			var directory = haxe.io.Path.join([system.getProgramDirectory(), root]);
			var cache = new helix.platform.adapters.filesystem.native.NativeFileSystemAdapter({directory: directory, readOnly: true});
			var imageDecoder = new helix.platform.adapters.imagedecoder.stb.StbImageDecoderAdapter();
			var assets = new Assets({sources: [FileSystem(cache)]});
			#end
			polled.push(cache);
			polled.push(imageDecoder);
			var left = paths.length;
			var one = () -> if (--left == 0) done();
			if (left == 0)
				done();
			for (path in paths)
				assets.load(path, bytes -> {
					var lower = path.toLowerCase();
					if (lower.endsWith(".glb") || lower.endsWith(".gltf")) {
						files.set(path, bytes);
						// A model's images are decoded now too, as LoadModel answers at once.
						var embedded = [];
						try {
							var file = Gltf.read(bytes);
							for (i in 0...file.list("images").length) {
								var encoded = Models.imageBytes(file, i);
								if (encoded != null)
									embedded.push({key: Models.imageKey(path, file, i), bytes: encoded});
							}
						} catch (e:Dynamic) {
							trace('$path: $e');
						}
						left += embedded.length;
						for (image in embedded)
							imageDecoder.decode(image.bytes, (pixels, width, height) -> {
								images.set(image.key, {pixels: pixels, width: width, height: height});
								one();
							}, error -> {
								trace('${image.key}: $error');
								one();
							});
						one();
					} else if (lower.endsWith(".png") || lower.endsWith(".jpg") || lower.endsWith(".jpeg") || lower.endsWith(".bmp") || lower.endsWith(".tga"))
						imageDecoder.decode(bytes, (pixels, width, height) -> {
							images.set(path, {pixels: pixels, width: width, height: height});
							one();
						}, error -> {
							trace('$path: $error');
							one();
						});
					else {
						files.set(path, bytes);
						one();
					}
				}, error -> {
					trace('$path: $error');
					one();
				});
		};
	}

	/** Returns the preload of the saves, which hold what `SaveFileText` writes.

		@return  The preload. */
	public static function preloadSaves():(done:Void->Void)->Void {
		return done -> {
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
					trace('saves: $error');
					written = true;
				});
				while (!written) {
					pollAll();
					Sys.sleep(.001);
				}
				#end
			});
			kept.load(done, error -> {
				trace('saves: $error');
				done();
			});
		};
	}

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
