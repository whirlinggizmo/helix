// The services' size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one a sound loaded through the assets and played.
import helix.platform.adapters.audio.webaudio.WebAudioAdapter;
import helix.platform.adapters.audiodecoder.webaudio.WebAudioDecoderAdapter;
import helix.platform.adapters.events.dom.DomEventsAdapter;
import helix.platform.adapters.gamepads.dom.DomGamepadsAdapter;
import helix.platform.adapters.filesystem.browser.BrowserFileSystemAdapter;
import helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter;
import helix.platform.adapters.keyboard.dom.DomKeyboardAdapter;
import helix.platform.adapters.http.fetchapi.FetchApiHttpAdapter;
import helix.platform.adapters.system.dom.DomSystemAdapter;
import helix.platform.adapters.window.dom.DomWindowAdapter;
import helix.services.assets.Assets;
import helix.services.assets.FileSystemSource;
import helix.services.assets.RevalidateCache;
import helix.services.assets.ServerSource;
import helix.services.audio.Audio;
import helix.services.config.Config;
import helix.services.input.Actions;
import helix.services.input.Gamepads;
import helix.services.input.Keyboard;
import helix.services.saves.Saves;
import helix.services.time.Time;

/** A program on helix-services and what it sits on, constructing only what it uses, as a game built on them would. */
@:adds("helix.platform.adapters.audio.webaudio", "helix.platform.adapters.audiodecoder.webaudio", "helix.services.audio")
class Main {
	static var window:DomWindowAdapter;
	static var events:DomEventsAdapter;
	static var graphics:WebGl2GraphicsAdapter;
	static var system:DomSystemAdapter;
	static var time:Time;
	static var keyboard:Keyboard;
	static var pads:Gamepads;
	static var actions:Actions;
	static var saveFiles:BrowserFileSystemAdapter;
	static var saves:Saves;
	static var files:BrowserFileSystemAdapter;
	static var httpClient:FetchApiHttpAdapter;
	static var downloads:BrowserFileSystemAdapter;
	static var assets:Assets;
	static var output:WebAudioAdapter;
	static var decoder:WebAudioDecoderAdapter;
	static var audio:Audio;

	static function main():Void {
		window = new DomWindowAdapter({canvasId: "canvas"});
		events = new DomEventsAdapter({canvasId: "canvas"});
		graphics = new WebGl2GraphicsAdapter({canvasId: "canvas"});
		system = new DomSystemAdapter();
		time = new Time(system);
		time.every(1, () -> trace(time.elapsed));
		time.scale = new Config(system).getFloat("speed", 1);
		keyboard = new Keyboard(events, new DomKeyboardAdapter({events: events}));
		pads = new Gamepads(events, new DomGamepadsAdapter({events: events}));
		actions = new Actions([keyboard, pads]);
		actions.bind("jump", Keyboard(Space), Pad(0, South));
		saveFiles = new BrowserFileSystemAdapter({name: "saves"});
		saves = new Saves(saveFiles);
		saves.load(() -> saves.setInt("runs", saves.getInt("runs", 0) + 1));
		httpClient = new FetchApiHttpAdapter();
		downloads = new BrowserFileSystemAdapter({name: "cache"});
		files = new BrowserFileSystemAdapter({name: "files"});
		assets = new Assets([
			new FileSystemSource(files),
			new ServerSource("", httpClient, new RevalidateCache(downloads))
		]);
		assets.load("level.json", bytes -> trace(bytes.length));
		output = new WebAudioAdapter();
		decoder = new WebAudioDecoderAdapter();
		audio = new Audio(output, decoder, assets, system);
		audio.load("jump.wav", sound -> audio.play(sound));
		var frame:Float->Void = null;
		frame = _ -> {
			events.poll();
			time.poll();
			keyboard.poll();
			pads.poll();
			if (actions.isPressed("jump"))
				trace("jump");
			saveFiles.poll();
			saves.poll();
			files.poll();
			httpClient.poll();
			downloads.poll();
			assets.poll();
			output.poll();
			decoder.poll();
			audio.poll();
			graphics.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff0a0e18);
			graphics.endFrame();
			graphics.present();
			js.Browser.window.requestAnimationFrame(frame);
		};
		js.Browser.window.requestAnimationFrame(frame);
	}
}
