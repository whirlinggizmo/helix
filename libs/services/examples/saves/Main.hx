import helix.platform.IFileSystem;
import helix.services.saves.Saves;
import helix.platform.IEvents;
import helix.platform.IGraphics;
import helix.platform.IPollable;
import helix.platform.ISystem;
import helix.platform.IWindow;

/** Shows Saves: the number of times it has run, loaded, counted up and written.

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
	static var files:IFileSystem;
	static var saves:Saves;

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
		window.title = "helix-services: saves";
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

	/** Makes the saves over a file system of their own, and counts this run once they're loaded. */
	static function setup():Void {
		#if js
		files = new helix.platform.adapters.filesystem.browser.BrowserFileSystemAdapter({name: system.getDataDirectory()});
		#else
		files = new helix.platform.adapters.filesystem.native.NativeFileSystemAdapter({directory: system.getDataDirectory()});
		#end
		polled.push(files);
		saves = new Saves(files);
		polled.push(saves);
		saves.load(() -> {
			var runs = saves.getInt("runs", 0) + 1;
			saves.setInt("runs", runs);
			saves.flush(() -> {
				color = DONE;
				trace('run $runs saved');
			});
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
		saves.dispose();
		files.dispose();
		graphics.dispose();
		events.dispose();
		if (window.canClose())
			window.close();
	}
}
