package helix.raylib.internal;

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
import helix.services.assets.FileSystemSource;
import helix.services.assets.RevalidateCache;
import helix.services.assets.ServerSource;
import helix.services.input.Gamepads;
import helix.services.input.Gestures;
import helix.services.input.Keyboard;
import helix.services.input.Mouse;
import helix.services.input.Touch;
import helix.services.saves.Saves;
import helix.services.time.Time;

using StringTools;

/** Holds what `Raylib`'s functions share: the platform's adapters and the services over them, each made when first needed, the files in
	memory, and the frame.

	raylib answers a load at once. A page can't wait for a file, so on every target helix-raylib loads through the `...Async` functions,
	which bring files into memory here. The saves, which hold what `SaveFileText` writes, are read when first used (`keptSaves`). */
@:noCompletion
class Runtime {
	public static var system:ISystem;
	public static var window:Null<IWindow> = null;
	public static var events:Null<IEvents> = null;

	/** The platform's events adapter itself, which the device adapters are built over; `events` wraps it (`EarlyEvents`). */
	public static var eventsAdapter:Null<IEvents> = null;

	static var early:Null<EarlyEvents> = null;
	public static var graphics:Null<IGraphics> = null;
	public static var frame:Null<Frame> = null;
	public static var time:Null<Time> = null;
	public static var saves:Null<Saves> = null;
	public static var output:Null<IAudio> = null;
	public static var audioDecoder:Null<IAudioDecoder> = null;
	public static var audio:Null<helix.services.audio.Audio> = null;

	/** The program's files, as the preload found them, for what loads from them later (`Audio`, and the `...Async` loads). */
	public static var assets:Null<Assets> = null;

	/** The files `LoadMusicStreamFromMemory` plays and the files dropped, read before the program's own, made with the assets. */
	public static var memory:Null<MemoryFiles> = null;

	/** Natively, the program's own files, read-only, made with the assets; null in a page, whose files are on its server. */
	public static var shipped:Null<IFileSystem> = null;

	/** The paths of the files last dropped, once each was read; empty when none were or after `UnloadDroppedFiles`. */
	public static var dropped:Array<String> = [];

	/** The paths of the files last dropped whose bytes `memory` holds: still read after `UnloadDroppedFiles`, as a dropped file stays on
		raylib's disk, until the next drop's files replace them. */
	public static var held:Array<String> = [];

	/** The models, reading glTF files with what they name, made when first needed (`modelling`). */
	public static var models:Null<helix.services.models.Models> = null;

	/** The images, decoding the program's image files and a model's, made when first needed (`modelling`). */
	public static var decoding:Null<helix.services.images.Images> = null;

	/** What reads a drop's files into memory: set by `DroppedFiles` when the program names a function that reads a drop
		(`IsFileDropped`, `LoadDroppedFiles`, a dropped directory listed), so a program that never reads one never links what reads it.
		While it is null a drop is ignored. It has no initial value, so the program's start never resets what `DroppedFiles` set. */
	public static var dropping:Null<Int->Void>;

	public static final polled:Array<IPollable> = [];

	/** What runs as the window closes, before it does: keeping the saves, and in a page disposing the input adapters made. */
	public static final closing:Array<Void->Void> = [];

	/** The files in memory, by path, as the loads brought them in: an image file decoded for the GPU (`pictures`, until its texture is
		made, then let go of), its pixels once a program asked for them (`images`, kept), and every file's bytes (`files`). */
	public static final pictures = new Map<String, helix.platform.IDecodedImage>();

	public static final images = new Map<String, helix.services.images.Image>();

	public static final files = new Map<String, Bytes>();

	/** The frame: whether the window should close, whether it is out of sight (minimized, or its tab in the background), frames
		left of the `quit_after_frame` option. */
	public static var shouldClose = false;

	public static var hidden = false;

	/** The screen: the window's resizes and its fullscreen, made with the window. */
	public static var screen:Null<helix.services.screen.Screen> = null;

	/** Whether the screen's fullscreen was asked for as a borderless window (`ToggleBorderlessWindowed`), which raylib tells apart
		from fullscreen: true only while the screen is fullscreen. */
	public static var borderless(get, set):Bool;

	static var borderlessAsked = false;

	static function get_borderless():Bool
		return borderlessAsked && screen.fullscreen;

	static function set_borderless(value:Bool):Bool
		return borderlessAsked = value;

	public static var framesLeft = -1;
	public static var exitKey = 256;
	public static var frames = 0;

	// In a page, when the next frame is due by the time's target (`SetTargetFPS`).
	static var frameDue = 0.;

	#if js
	/** Asks for a function to be called at the next frame: the page's `requestAnimationFrame`, or a test's own. */
	static var requestFrame:(Float->Void) -> Void = f -> js.Browser.window.requestAnimationFrame(f);

	/** Counts the calls of `WindowShouldClose` since the last frame began: a loop calling it that ends no frame would hang the page. */
	public static var unframed = 0;
	#end

	/** The keys pressed this frame, oldest first, as the keyboard has them, read one at a time by `GetKeyPressed`. */
	public static final keysPressed:Array<Int> = [];

	/** The characters typed this frame, as codepoints, oldest first, as the keyboard has them, read one at a time by `GetCharPressed`. */
	public static final charsPressed:Array<Int> = [];

	static var keyboardService:Null<Keyboard> = null;

	/** What reads the keyboard's keys and characters into `keysPressed` and `charsPressed` each poll: set when `keyboard` makes it, null
		until then, so a program that never asks for the keyboard never links it from the poll. */
	static var keyboardRead:Null<Void->Void> = null;

	static var mouseService:Null<Mouse> = null;

	/** The platform's mouse, made with the mouse: its cursor and lock. */
	public static var mouseAdapter:Null<helix.platform.IMouse> = null;

	/** Whether the mouse is over the window, from its moves and its leaving. */
	public static var cursorOnScreen = false;

	static var touchService:Null<Touch> = null;
	static var gamepadsService:Null<Gamepads> = null;

	/** Whether the window was closed (`close`). */
	public static var closed = false;

	/** The platform's gamepads, made with the gamepads: their vibration and mappings. */
	public static var gamepadsAdapter:Null<helix.platform.IGamepads> = null;

	static var gesturesService:Null<Gestures> = null;
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
		var frames = system.getOption("quit_after_frame");
		if (frames != null)
			framesLeft = Std.parseInt(frames);
		#if helix_raylib_frame_stats
		var measured = system.getOption("frame_stats");
		if (measured != null) {
			var at = measured.split(",");
			statsFrom = Std.parseInt(at[0]);
			statsTo = Std.parseInt(at[1]);
			#if js
			// tools/page_check.cjs waits on a null result until it holds one.
			js.Syntax.code("window.helixResult = null");
			#end
		}
		#end
		main();
	}

	/** Natively, where the program's files are, relative to the program's directory (`-D helix-raylib-native-root`). */
	public static var root = "../web";

	/** Makes what loads the program's files, once: the assets over a page's server and its cache, or natively over the files' directory.
		What decodes images is `imaging`'s, so a program loading only sounds or text never links an image decoder. */
	public static function loading():Void {
		if (assets != null)
			return;
		#if js
		var http = new helix.platform.adapters.http.fetchapi.FetchApiHttpAdapter();
		var cache = new helix.platform.adapters.filesystem.browser.BrowserFileSystemAdapter({name: system.getCacheDirectory()});
		polled.push(http);
		var callback = new CallbackFiles();
		polled.push(callback);
		memory = new MemoryFiles();
		polled.push(memory);
		assets = new Assets([
			new FileSystemSource(memory),
			new FileSystemSource(callback),
			new ServerSource(system.getProgramDirectory(), http, new RevalidateCache(cache))
		]);
		#else
		var directory = haxe.io.Path.join([system.getProgramDirectory(), root]);
		var cache = new helix.platform.adapters.filesystem.native.NativeFileSystemAdapter({directory: directory, readOnly: true});
		shipped = cache;
		var callback = new CallbackFiles();
		polled.push(callback);
		memory = new MemoryFiles();
		polled.push(memory);
		assets = new Assets([
			new FileSystemSource(memory),
			new FileSystemSource(callback),
			new FileSystemSource(cache)
		]);
		#end
		polled.push(cache);
		polled.push(assets);
	}

	/** Makes what decodes the program's images, once, over the assets (`loading`): the platform's image decoder and the images over it.
		What reads models is `modelling`'s. */
	public static function imaging():Void {
		loading();
		if (decoding != null)
			return;
		#if js
		var imageDecoder = new helix.platform.adapters.imagedecoder.canvas.CanvasImageDecoderAdapter();
		#else
		var imageDecoder = new helix.platform.adapters.imagedecoder.stb.StbImageDecoderAdapter();
		#end
		polled.push(imageDecoder);
		decoding = new helix.services.images.Images(imageDecoder, assets);
		polled.push(decoding);
	}

	/** Makes what reads the program's models, once, over the assets and the images (`modelling`). */
	public static function modelling():Void {
		imaging();
		if (models == null)
			models = new helix.services.models.Models(assets, decoding);
	}

	/** Brings a file into memory as bytes, in `files`. Answers at a later poll, never during the call. It decodes nothing, so a program
		loading text or data never links an image decoder; `fetchImage` is for an image file.

		@param path  The file.
		@param done  Receives whether it was brought in, and why not when it wasn't. */
	public static function fetch(path:String, done:Null<String>->Void):Void {
		loading();
		if (files.exists(path)) {
			later(() -> done(null));
			return;
		}
		// Named before it's asked for, so a file that isn't there (a page's 404, which the browser reports without naming the program's call)
		// can be told from the log.
		log(3, 'FILEIO: [$path] Loading');
		assets.load(path, bytes -> {
			// The file's bytes are kept too, for LoadFileDataAsync; an image's are small beside its pixels.
			files.set(path, bytes);
			done(null);
		}, error -> done(error));
	}

	/** Brings an image file into memory: its bytes in `files` and, for a PNG, JPEG, BMP or TGA file, its pixels decoded for the GPU in
		`pictures`. Any other file is brought in as `fetch` does. Answers at a later poll, never during the call.

		@param path  The file.
		@param done  Receives whether it was brought in, and why not when it wasn't. */
	public static function fetchImage(path:String, done:Null<String>->Void):Void {
		var lower = path.toLowerCase();
		if (!(lower.endsWith(".png") || lower.endsWith(".jpg") || lower.endsWith(".jpeg") || lower.endsWith(".bmp") || lower.endsWith(".tga"))) {
			fetch(path, done);
			return;
		}
		loading();
		imaging();
		if (pictures.exists(path) || images.exists(path)) {
			later(() -> done(null));
			return;
		}
		if (files.exists(path)) {
			decoding.decodeForGpu(files.get(path), decoded -> {
				pictures.set(path, decoded);
				done(null);
			}, error -> done('$path: $error'));
			return;
		}
		fetch(path, error -> {
			if (error != null) {
				done(error);
				return;
			}
			decoding.decodeForGpu(files.get(path), decoded -> {
				pictures.set(path, decoded);
				done(null);
			}, error -> done('$path: $error'));
		});
	}

	/** The least level `log` writes, as `SetTraceLogLevel` sets it: raylib's LOG_INFO (3) until set. */
	public static var logLevel = 3;

	/** The program's log, as `SetTraceLogCallback` sets it, or null for helix-raylib's. */
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
		// The line alone, as raylib prints it: a trace without a position starts "??" natively.
		#if js
		js.Browser.console.log('$label: $text');
		#else
		Sys.println('$label: $text');
		#end
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

	/** Returns an image file an async load decoded.

		@param key  The file's path.
		@return  The image, or null when it isn't in memory. */
	public static function image(key:String):Null<helix.services.images.Image> {
		var image = images.get(key);
		if (image == null) {
			// Its pixels from the picture, read once and kept, as a load of the file brought it in for the GPU.
			var picture = pictures.get(key);
			if (picture != null)
				images.set(key, image = new helix.services.images.Image(key, picture.width, picture.height, picture.pixels()));
		}
		return image;
	}

	/** Returns a file's image decoded for the GPU, while it is in memory: from its load until its texture is made (`Textures.handle`), or
		until it is let go of (`forgetPicture`).

		@param path  The file.
		@return  The image, or null. */
	public static function picture(path:String):Null<helix.platform.IDecodedImage>
		return pictures.get(path);

	/** Lets go of a file's image decoded for the GPU, freeing it: its texture is made, or it isn't wanted. A load of the file again
		decodes its bytes again.

		@param path  The file. */
	public static function forgetPicture(path:String):Void {
		var picture = pictures.get(path);
		if (picture == null)
			return;
		pictures.remove(path);
		picture.dispose();
	}

	/** Gets the saves, made and read when first asked for, so a program that never saves never reads them. A value set before the read
		has finished is held by the saves and made after it, so it wins over what was kept.

		@return  The saves. */
	public static function keptSaves():Saves {
		if (saves != null)
			return saves;
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
		kept.load(() -> {}, error -> log(4, 'saves: $error'));
		return kept;
	}

	/** Calls a function with the saves once they are read, at a later poll, in the order asked; the first call starts the read.

		@param ready  Receives the saves. */
	public static function withSaves(ready:Saves->Void):Void {
		var kept = keptSaves();
		kept.load(() -> ready(kept), _ -> ready(kept));
	}

	/** Opens the window, with the graphics and the events.

		@param width  The window's width, natively.
		@param height  The window's height, natively.
		@param title  The window's title. */
	public static function open(width:Int, height:Int, title:String):Void {
		// SetConfigFlags' hints, as raylib takes them: 4 samples for FLAG_MSAA_4X_HINT, and vsync only for FLAG_VSYNC_HINT natively.
		var flags = helix.raylib.modules.RCore.configFlags;
		var samples = flags & helix.raylib.Raylib.FLAG_MSAA_4X_HINT != 0 ? 4 : 1;
		#if js
		// The page draws at the canvas's logical size, as raylib's web build does, unless FLAG_WINDOW_HIGHDPI asks for the device's ratio.
		window = new helix.platform.adapters.window.dom.DomWindowAdapter({
			canvasId: "canvas",
			highDpi: flags & helix.raylib.Raylib.FLAG_WINDOW_HIGHDPI != 0
		});
		eventsAdapter = new helix.platform.adapters.events.dom.DomEventsAdapter({canvasId: "canvas"});
		events = early = new EarlyEvents(eventsAdapter);
		graphics = new helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter({canvasId: "canvas", msaaSampleCount: samples});
		#else
		var vsync = flags & helix.raylib.Raylib.FLAG_VSYNC_HINT != 0;
		#if sdl_gpu
		window = new helix.platform.adapters.window.sdl3.Sdl3WindowAdapter({graphics: Gpu, msaaSampleCount: samples, vsync: vsync});
		graphics = new helix.platform.adapters.graphics.sdl3gpu.Sdl3GpuGraphicsAdapter();
		#else
		window = new helix.platform.adapters.window.sdl3.Sdl3WindowAdapter({graphics: Gl, msaaSampleCount: samples, vsync: vsync});
		graphics = new helix.platform.adapters.graphics.sokol.SokolGraphicsAdapter();
		#end
		eventsAdapter = new helix.platform.adapters.events.sdl3.Sdl3EventsAdapter();
		events = early = new EarlyEvents(eventsAdapter);
		window.requestSize(width, height);
		// The exit key closes a native window, as raylib's does; a page has none.
		keyboard();
		#end
		window.title = title;
		// The device, in rlgl's lines as it writes them when the window opens; a backend other than GL names itself.
		var device = graphics.device;
		log(helix.raylib.Raylib.LOG_INFO, 'GL: ${device.api == "OpenGL" || device.api == "WebGL 2" ? "OpenGL" : device.api} device information:');
		log(helix.raylib.Raylib.LOG_INFO, '    > Vendor:   ${device.vendor}');
		log(helix.raylib.Raylib.LOG_INFO, '    > Renderer: ${device.renderer}');
		log(helix.raylib.Raylib.LOG_INFO, '    > Version:  ${device.version}');
		log(helix.raylib.Raylib.LOG_INFO, '    > GLSL:     ${device.shadingLanguage}');
		frame = new Frame(graphics);
		screen = new helix.services.screen.Screen(window, events);
		devices.push(screen);
		time = new Time(system);
		// raylib's frame time isn't capped: a frame that took a second says so.
		time.maxDelta = Math.POSITIVE_INFINITY;
		pollEvents();
		time.poll();
	}

	/** Gets the keyboard, made when first asked for. */
	public static function keyboard():Keyboard {
		if (keyboardService == null) {
			#if js
			var adapter = new helix.platform.adapters.keyboard.dom.DomKeyboardAdapter({events: cast eventsAdapter});
			// In a page, the keys are the page's again once the window closes.
			closing.push(() -> adapter.dispose());
			keyboardService = new Keyboard(events, adapter);
			#else
			keyboardService = new Keyboard(events, new helix.platform.adapters.keyboard.sdl3.Sdl3KeyboardAdapter({events: cast eventsAdapter}));
			#end
			devices.push(keyboardService);
			var made = keyboardService;
			keyboardRead = () -> {
				for (key in made.pressedKeys)
					keysPressed.push(key);
				for (c in new haxe.iterators.StringIteratorUnicode(made.text))
					charsPressed.push(c);
			}
		}
		return keyboardService;
	}

	/** Turns typed text on, so the characters typed arrive in `charsPressed`; raylib reads them always, helix-raylib once asked for, as a
		phone shows its keyboard while text is on. */
	public static function typing():Void {
		keyboard().textInput = true;
	}

	/** Gets the mouse, made when first asked for, with the touch, as raylib takes the first finger for the mouse. */
	public static function mouse():Mouse {
		if (mouseService == null) {
			#if js
			mouseAdapter = new helix.platform.adapters.mouse.dom.DomMouseAdapter({events: cast eventsAdapter});
			closing.push(() -> mouseAdapter.dispose());
			#else
			mouseAdapter = new helix.platform.adapters.mouse.sdl3.Sdl3MouseAdapter({events: cast eventsAdapter});
			#end
			mouseService = new Mouse(events, mouseAdapter);
			devices.push(mouseService);
			touch();
			// raylib's gestures read the mouse and the fingers from the start, so they are made with them.
			gesturesService = new Gestures(events, window, system);
			devices.push(gesturesService);
		}
		return mouseService;
	}

	/** Gets the touch, made when first asked for. */
	public static function touch():Touch {
		if (touchService == null) {
			#if js
			var adapter = new helix.platform.adapters.touch.dom.DomTouchAdapter({events: cast eventsAdapter});
			closing.push(() -> adapter.dispose());
			touchService = new Touch(events, adapter);
			#else
			touchService = new Touch(events, new helix.platform.adapters.touch.sdl3.Sdl3TouchAdapter({events: cast eventsAdapter}));
			#end
			devices.push(touchService);
		}
		return touchService;
	}

	/** Gets the gestures, made with the mouse and touch whose events they read. */
	public static function gestures():Gestures {
		mouse();
		return gesturesService;
	}

	/** Gets the fonts service, made when first asked for, over the platform's font rasterizer, the assets and the images. */
	public static function fonts():helix.services.fonts.Fonts {
		if (fontsService == null) {
			imaging();
			#if js
			var rasterizer = new helix.platform.adapters.fontrasterizer.canvas.CanvasFontRasterizerAdapter();
			#else
			var rasterizer = new helix.platform.adapters.fontrasterizer.stb.StbFontRasterizerAdapter();
			#end
			polled.push(rasterizer);
			fontsService = new helix.services.fonts.Fonts(rasterizer, assets, decoding);
		}
		return fontsService;
	}

	static var fontsService:Null<helix.services.fonts.Fonts> = null;

	/** Gets the screenshots, made over the graphics when first asked for: the frame reads them back as each frame ends (`Frame.ended`). */
	public static function screenshots():helix.services.screenshots.Screenshots {
		if (screenshotsService == null) {
			var made = new helix.services.screenshots.Screenshots(graphics);
			screenshotsService = made;
			frame.ended.push(made.frameEnded);
		}
		return screenshotsService;
	}

	static var screenshotsService:Null<helix.services.screenshots.Screenshots> = null;

	/** Gets where files are handed out, made when first asked for: in a page a download, natively the working directory. */
	public static function exporter():helix.platform.IExport {
		if (exportAdapter == null) {
			#if js
			exportAdapter = new helix.platform.adapters.export.download.DownloadExportAdapter();
			#else
			exportAdapter = new helix.platform.adapters.export.filesystem.FileSystemExportAdapter({directory: Sys.getCwd()});
			#end
		}
		return exportAdapter;
	}

	static var exportAdapter:Null<helix.platform.IExport> = null;

	/** Makes what hands files out natively write to the working directory as it is now, after `ChangeDirectory`. */
	public static function workingDirectoryChanged():Void {
		#if !js
		exportAdapter = null;
		#end
	}

	/** Gets the system's clipboard, made when first asked for. */
	public static function clipboard():helix.platform.IClipboard {
		if (clipboardAdapter == null) {
			#if js
			clipboardAdapter = new helix.platform.adapters.clipboard.dom.DomClipboardAdapter();
			#else
			clipboardAdapter = new helix.platform.adapters.clipboard.sdl3.Sdl3ClipboardAdapter();
			#end
		}
		return clipboardAdapter;
	}

	static var clipboardAdapter:Null<helix.platform.IClipboard> = null;

	/** Gets the gamepads, made when first asked for, without a dead zone, as raylib's axes have none. */
	public static function gamepads():Gamepads {
		if (gamepadsService == null) {
			#if js
			gamepadsAdapter = new helix.platform.adapters.gamepads.dom.DomGamepadsAdapter({events: cast eventsAdapter});
			closing.push(() -> gamepadsAdapter.dispose());
			#else
			gamepadsAdapter = new helix.platform.adapters.gamepads.sdl3.Sdl3GamepadsAdapter({events: cast eventsAdapter});
			#end
			gamepadsService = new Gamepads(events, gamepadsAdapter);
			gamepadsService.deadZone = 0;
			devices.push(gamepadsService);
		}
		return gamepadsService;
	}

	/** Makes the gamepads read through a gamepad standing in front of the platform's, as a virtual gamepad does (`EnableVirtualGamepad`). The
		gamepads are made again over it, and it's polled after the touch and before the gamepads.

		@param gamepad  The gamepad the gamepads read.
		@param poller  What brings the gamepad up to date each frame. */
	public static function standInFront(gamepad:helix.platform.IGamepads, poller:IPollable):Void {
		touch();
		devices.remove(gamepads());
		gamepadsService = new Gamepads(events, gamepad);
		gamepadsService.deadZone = 0;
		devices.push(poller);
		devices.push(gamepadsService);
	}

	/** Gets the tilt, made when first asked for. Only the tilt's functions ask, so a program that never calls one links no tilt adapter. */
	public static function tilt():helix.services.input.Tilt {
		if (tiltService == null) {
			#if js
			var adapter = new helix.platform.adapters.tilt.dom.DomTiltAdapter({events: cast eventsAdapter});
			closing.push(() -> adapter.dispose());
			tiltService = new helix.services.input.Tilt(events, adapter);
			#else
			tiltService = new helix.services.input.Tilt(events, new helix.platform.adapters.tilt.sdl3.Sdl3TiltAdapter({events: cast eventsAdapter}));
			#end
			// Polled first: a virtual gamepad's tilt stick reads it the same frame.
			devices.unshift(tiltService);
		}
		return tiltService;
	}

	/** Gets the tilt once a tilt function has made it (`tilt`), or null before. A virtual gamepad's tilt stick reads it. */
	public static var tiltService(default, null):Null<helix.services.input.Tilt>;

	/** Adds what runs as each frame ends, before the frame is drawn (`ending`), after what runs there already.

		@param f  What runs. */
	public static function endingFrame(f:Void->Void):Void {
		var before = ending;
		ending = before == null ? f : () -> {
			before();
			f();
		};
	}

	/** Draws the frame, shows it, waits out the rest of the frame natively, as raylib does, and reads the next frame's input. With
		`-D helix-raylib-custom-frame-control`, raylib's `SUPPORT_CUSTOM_FRAME_CONTROL`, it only draws the frame: `SwapScreenBuffer` shows it
		and `PollInputEvents` reads the input. The input recorded for automation is recorded first, as raylib's is. In a page the wait
		is the program's own, between `showFrame` and `countFrame` (`frameWait`). */
	@:helix.raylib.waits
	public static function endFrame():Void {
		showFrame();
		#if (!js && !helix_raylib_custom_frame_control)
		wait();
		#end
		countFrame();
	}

	/** Draws the frame and shows it, the first part of `endFrame`. */
	public static function showFrame():Void {
		if (ending != null)
			ending();
		#if helix_raylib_custom_frame_control
		frame.draw(window.framebufferWidth, window.framebufferHeight, false);
		#else
		frame.draw(window.framebufferWidth, window.framebufferHeight, true);
		#end
	}

	/** Counts the frame shown and reads the next frame's input, the last part of `endFrame`. */
	public static function countFrame():Void {
		frames++;
		if (framesLeft > 0 && --framesLeft == 0)
			shouldClose = true;
		#if helix_raylib_frame_stats
		measureFrames();
		#end
		#if !helix_raylib_custom_frame_control
		poll();
		#end
	}

	#if js
	/** In a page, the wait `EndDrawing` makes: answers at the browser's next frame, or the first one the time's target
		(`SetTargetFPS`) allows.

		@return  A promise of the frame. */
	@:helix.raylib.waits
	public static function frameWait():js.lib.Promise<Dynamic> {
		return new js.lib.Promise((resolve, _) -> {
			var frame:Float->Void = null;
			frame = _ -> {
				// A frame the target rate has no room for is skipped, with a millisecond's slack for the display's jitter.
				var now = system.getTime();
				var frameTarget = time.targetDelta;
				if (frameTarget > 0 && now < frameDue - .001) {
					requestFrame(frame);
					return;
				}
				// The next is due a target after this one was: from now when it came early or far behind, so neither adds up.
				frameDue = (now < frameDue || now - frameDue > frameTarget ? now : frameDue) + frameTarget;
				unframed = 0;
				resolve(null);
			};
			requestFrame(frame);
		});
	}

	/** In a page, the wait a load makes: asks, and answers when the asked does, polling the services meanwhile.

		@param ask  Asks, given what to call with the answer.
		@return  A promise of the answer. */
	@:helix.raylib.waits
	public static function answered<T>(ask:(T->Void)->Void):js.lib.Promise<T> {
		return new js.lib.Promise((resolve, _) -> {
			var done = false;
			ask(value -> {
				done = true;
				resolve(value);
			});
			var pump:Void->Void = null;
			pump = () -> {
				if (done)
					return;
				pollAnswers();
				if (!done)
					haxe.Timer.delay(pump, 0);
			};
			haxe.Timer.delay(pump, 0);
		});
	}

	/** In a page, the wait a call without a value makes (a write): asks, and answers when the asked says it is done.

		@param ask  Asks, given what to call once it is done.
		@return  A promise of its end. */
	@:helix.raylib.waits
	public static function finished(ask:(Void->Void)->Void):js.lib.Promise<Dynamic> {
		return answered((answer:Dynamic->Void) -> ask(() -> answer(null)));
	}
	#else

	/** Natively, the wait a call without a value makes (a write): asks, and returns once the asked says it is done.

		@param ask  Asks, given what to call once it is done. */
	@:helix.raylib.waits
	public static function finished(ask:(Void->Void)->Void):Void {
		answered((answer:Dynamic->Void) -> ask(() -> answer(null)));
	}

	/** Natively, the wait a load makes: asks, and returns the answer, polling the services until it comes.

		@param ask  Asks, given what to call with the answer.
		@return  The answer. */
	@:helix.raylib.waits
	public static function answered<T>(ask:(T->Void)->Void):T {
		var done = false;
		var answer:Null<T> = null;
		ask(value -> {
			answer = value;
			done = true;
		});
		while (!done) {
			pollAnswers();
			if (!done)
				Sys.sleep(.0005);
		}
		return answer;
	}
	#end

	#if helix_raylib_frame_stats
	/** The frames `-D helix-raylib-frame-stats` records, from the `frame_stats` option (`--frame_stats=120,1200`): recording starts as
		frame `statsFrom` ends, and stops as frame `statsTo` ends, printing the stats as one line and closing the window; 0 when not
		given. */
	public static var statsFrom = 0;

	public static var statsTo = 0;

	// Starts and stops the recording at its frames: the stats printed as `frame_stats` and a JSON object, and in a page also left in
	// window.helixResult.
	static function measureFrames():Void {
		if (statsTo <= 0)
			return;
		// The frames before take their times, so the first one recorded has its start.
		if (frames < statsFrom)
			@:privateAccess helix.raylib.modules.RDebug.hook();
		else if (frames == statsFrom) {
			// Frame statsFrom's EndDrawing has just counted, so the recording's first frame starts there: frames statsFrom + 1 to
			// statsTo are recorded.
			helix.raylib.modules.RDebug.StartFrameStatsRecording();
			@:privateAccess helix.raylib.modules.RDebug.recordingStarts = false;
		} else if (frames == statsTo) {
			var s = helix.raylib.modules.RDebug.StopFrameStatsRecording();
			var json = '{"frames":${s.frames},"fps":${s.fps},"meanFrameTime":${s.meanFrameTime},"p95FrameTime":${s.p95FrameTime},'
				+ '"slowestFrameTime":${s.slowestFrameTime},"drawCalls":${s.drawCalls},"triangles":${s.triangles},'
				+ '"stateChanges":${s.stateChanges},"gpuTextureBytes":${s.gpuTextureBytes},"gpuBufferBytes":${s.gpuBufferBytes},'
				+ '"memoryBytes":${s.memoryBytes}}';
			#if js
			js.Syntax.code("console.log({0})", "frame_stats " + json);
			js.Syntax.code("window.helixResult = JSON.parse({0})", json);
			#else
			Sys.println("frame_stats " + json);
			#end
			shouldClose = true;
		}
	}
	#end

	/** What runs as each frame ends, before it is drawn (`endingFrame`): automation's recording of the frame's input, a virtual gamepad
		drawn over the frame; null while nothing does. */
	public static var ending:Null<Void->Void> = null;

	/** The input automation plays into, which the input functions read once automation is used, or null before. */
	public static var played:Null<PlayedInput> = null;

	/** What brings the input that automation plays into up to date after each poll, or null while automation isn't used. */
	public static var mirroring:Null<Void->Void> = null;

	/** Whether a native poll waits for an event, as `EnableEventWaiting` sets. */
	public static var eventWaiting = false;

	// How long a native poll waiting for an event sleeps at most before it polls the platform and the services again.
	static inline final EVENT_WAIT_SLICE = .05;

	/** Waits, as raylib's `WaitTime` does: natively a sleep for most of the time, then a spin for the last twentieth, as a sleep can
		overshoot; in a page a spin alone, as emscripten's is, so nothing else runs until it ends.

		@param seconds  How long. */
	public static function sleep(seconds:Float):Void {
		if (seconds <= 0)
			return;
		// Before InitWindow there is no system yet, and the clock is Haxe's, as raylib's WaitTime waits before a window too.
		var clock = system == null ? haxe.Timer.stamp : system.getTime;
		var until = clock() + seconds;
		#if !js
		Sys.sleep(seconds * .95);
		#end
		while (clock() < until) {}
	}

	#if !js
	// raylib's frame wait: what is left of the frame the time aims for.
	static function wait():Void {
		sleep(time.getRemaining());
	}
	#end

	/** Polls the platform and the services, reads the frame's events, then the time. Natively, while `eventWaiting`, it waits for an
		event first, polling the platform and the services meanwhile, as raylib's waits; a page can't wait, so it never does there, as
		raylib's web build doesn't. */
	public static function poll():Void {
		pollEvents();
		#if !js
		while (eventWaiting && events.events.length == 0 && !shouldClose) {
			events.wait(EVENT_WAIT_SLICE);
			pollEvents();
		}
		#end
		if (mirroring != null)
			mirroring();
		time.poll();
	}

	// Polls the platform and the services, then reads the frame's events.
	static function pollEvents():Void {
		pollAnswers();
		events.poll();
		keysPressed.resize(0);
		charsPressed.resize(0);
		for (event in events.events)
			switch event {
				case CloseRequested:
					shouldClose = true;
				case Hidden:
					hidden = true;
				case Shown:
					hidden = false;
				case MouseMove(_, _):
					cursorOnScreen = true;
				case MouseLeave:
					cursorOnScreen = false;
				case FilesDropped(count):
					if (dropping != null)
						dropping(count);
				case _:
			}
		for (device in devices)
			device.poll();
		if (keyboardRead != null)
			keyboardRead();
		#if !js
		if (exitKey != 0 && keyboardService.isKeyPressed(cast exitKey))
			shouldClose = true;
		#end
	}

	// Polls the platform and the services, then gives the answers that were ready.
	static function pollAnswers():Void {
		pollAll();
		if (waiting.length > 0) {
			var now = waiting;
			waiting = [];
			for (f in now)
				f();
		}
	}

	static function pollAll():Void {
		for (p in polled)
			p.poll();
	}

	/** Begins a frame's drawing (`BeginDrawing`): a look at the events so far for the GPU's context lost or given back, acted on before
		the frame draws (`EarlyEvents`), the rest waiting for `poll`. */
	public static function beginDrawing():Void {
		if (early != null)
			early.peek(graphicsLost, graphicsRestored);
	}

	/** The GPU's context is gone (`Event.GraphicsLost`): said once. The platform takes every call and draws nothing until it is back, so
		nothing else changes. */
	public static function graphicsLost():Void {
		log(3, "DISPLAY: GPU context lost: drawing nothing until it is restored");
	}

	/** What runs when the GPU's context is back (`graphicsRestored`), after the frame's own: the textures' and the meshes' (`Textures`,
		`Models`), each put here when the program first makes one, so a program without them links nothing of theirs. */
	public static final restoring:Array<Void->Void> = [];

	/** The GPU's context is back (`Event.GraphicsRestored`): what the platform remade keeps its handles, and what it dropped (the frame's
		own, textures, meshes' buffers) is made again now or as it is next drawn (`Frame.graphicsRestored`, then `restoring`). */
	public static function graphicsRestored():Void {
		log(3, "DISPLAY: GPU context restored: textures and meshes sent again as they are drawn");
		if (frame != null)
			frame.graphicsRestored();
		for (f in restoring)
			f();
	}

	/** Frees what was made, and closes the window where the program owns one. In a page, which a program can't close, the canvas is
		cleared and stays so, and the page's input is the page's again: the input adapters made are disposed (`closing`), taking their
		listeners and the styles they set with them. */
	public static function close():Void {
		#if js
		// The canvas cleared, and a frame of nothing shown.
		if (frame != null) {
			frame.clear(0);
			frame.draw(window.framebufferWidth, window.framebufferHeight, true);
		}
		#end
		for (f in closing)
			f();
		if (frame != null)
			frame.dispose();
		if (graphics != null)
			graphics.dispose();
		if (events != null)
			events.dispose();
		closed = true;
		if (window != null && window.canClose())
			window.close();
	}
}
