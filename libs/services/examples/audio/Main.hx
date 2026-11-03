import helix.platform.IAudio;
import helix.platform.IAudioDecoder;
import helix.platform.IFileSystem;
#if js
import helix.platform.IHttp;
#end
import helix.services.assets.Assets;
import helix.services.assets.FileSystemSource;
import helix.services.assets.RevalidateCache;
import helix.services.assets.ServerSource;
import helix.services.audio.Audio;
import helix.platform.IEvents;
import helix.platform.IGraphics;
import helix.platform.IPollable;
import helix.platform.ISystem;
import helix.platform.IWindow;

/** Shows Audio: one sound loaded whole and played.

	The screen is grey until that happens, then green. The window, its events and the loop are the platform's, written out by hand, as a
	program does them until the layer above the services does. The `frames` option (`--frames=60` natively, `?frames=60` in a page)
	stops it after that many frames. */
class Main {
	static inline final WAITING = 0xff1a1d26;
	static inline final DONE = 0xff2a9d4a;

	static var window:IWindow;
	static var events:IEvents;
	static var graphics:IGraphics;
	static var system:ISystem;
	static final polled:Array<IPollable> = [];
	static var color = WAITING;
	static var framesLeft = -1;
	#if js
	static var httpClient:IHttp;
	static var downloads:IFileSystem;
	#else
	static var shipped:IFileSystem;
	#end
	static var assets:Assets;
	static var output:IAudio;
	static var decoder:IAudioDecoder;
	static var audio:Audio;

	static function main():Void {
		#if js
		window = new helix.platform.adapters.window.dom.DomWindowAdapter({canvasId: "canvas"});
		events = new helix.platform.adapters.events.dom.DomEventsAdapter({canvasId: "canvas"});
		graphics = new helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter({canvasId: "canvas"});
		system = new helix.platform.adapters.system.dom.DomSystemAdapter();
		#else
		window = new helix.platform.adapters.window.sdl3.Sdl3WindowAdapter({graphics: Gl});
		graphics = new helix.platform.adapters.graphics.sokol.SokolGraphicsAdapter();
		events = new helix.platform.adapters.events.sdl3.Sdl3EventsAdapter();
		system = new helix.platform.adapters.system.sdl3.Sdl3SystemAdapter();
		#end
		window.title = "helix-services: audio";
		var frames = system.getOption("frames");
		if (frames != null)
			framesLeft = Std.parseInt(frames);
		polled.push(events);
		setup();
		#if js
		var frame:Float->Void = null;
		frame = _ -> if (tick()) js.Browser.window.requestAnimationFrame(frame) else dispose();
		js.Browser.window.requestAnimationFrame(frame);
		#else
		while (tick()) {}
		dispose();
		#end
	}

	/** Makes the audio over the platform's output and decoder, finding sounds through the assets, and plays one. */
	static function setup():Void {
		#if js
		output = new helix.platform.adapters.audio.webaudio.WebAudioAdapter();
		decoder = new helix.platform.adapters.audiodecoder.webaudio.WebAudioDecoderAdapter();
		httpClient = new helix.platform.adapters.http.fetchapi.FetchApiHttpAdapter();
		downloads = new helix.platform.adapters.filesystem.browser.BrowserFileSystemAdapter({name: system.getCacheDirectory()});
		polled.push(httpClient);
		polled.push(downloads);
		assets = new Assets([
			new ServerSource(system.getProgramDirectory() + "assets/", httpClient, new RevalidateCache(downloads))
		]);
		#else
		output = new helix.platform.adapters.audio.sdl3mixer.Sdl3MixerAudioAdapter();
		decoder = new helix.platform.adapters.audiodecoder.sdl3mixer.Sdl3MixerAudioDecoderAdapter();
		// The example keeps one copy of its files for both builds, beside its page: a directory up from the program, then web/assets.
		var files = haxe.io.Path.join([system.getProgramDirectory(), "../web/assets"]);
		shipped = new helix.platform.adapters.filesystem.native.NativeFileSystemAdapter({directory: files, readOnly: true});
		polled.push(shipped);
		assets = new Assets([new FileSystemSource(shipped)]);
		#end
		polled.push(assets);
		polled.push(output);
		polled.push(decoder);
		audio = new Audio(output, decoder, assets, system);
		polled.push(audio);
		audio.load("blip.wav", sound -> {
			audio.play(sound);
			color = DONE;
			trace("playing blip.wav");
		});
	}

	/** Runs one frame: polls what answers later, then clears the screen to its color; false once the program should stop. */
	static function tick():Bool {
		for (pollable in polled)
			pollable.poll();
		for (event in events.events)
			switch event {
				case CloseRequested | GraphicsLost:
					return false;
				case _:
			}
		graphics.beginFrame(window.framebufferWidth, window.framebufferHeight, color);
		graphics.endFrame();
		graphics.present();
		return framesLeft < 0 || --framesLeft > 0;
	}

	/** Frees what was made, in the reverse order, and closes the window where the program owns one. */
	static function dispose():Void {
		audio.dispose();
		decoder.dispose();
		output.dispose();
		assets.dispose();
		#if js
		downloads.dispose();
		httpClient.dispose();
		#else
		shipped.dispose();
		#end
		graphics.dispose();
		events.dispose();
		if (window.canClose())
			window.close();
	}
}
