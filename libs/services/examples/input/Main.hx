import helix.services.input.Actions;
import helix.services.input.Gamepads;
import helix.services.input.Keyboard;
import helix.platform.IEvents;
import helix.platform.IGamepads;
import helix.platform.IKeyboard;
import helix.platform.IGraphics;
import helix.platform.IPollable;
import helix.platform.ISystem;
import helix.platform.IWindow;

/** Shows Keyboard, Gamepads and Actions: one action, "jump", bound to Space and the first gamepad's bottom button, read each frame.

	The screen is grey until that happens, then green. The window, its events and the loop are the platform's, written out by hand, as a
	program does them until the layer above the services does. The `frames` option (`--frames=60` natively, `?frames=60` in a page)
	stops it after that many frames. */
class Main {
	static inline final WAITING = 0xff1a1d26;
	static inline final DONE = 0xff2a9d4a;

	static var window:IWindow;
	static var events:IEvents;
	static var keyboardAdapter:IKeyboard;
	static var gamepadsAdapter:IGamepads;
	static var graphics:IGraphics;
	static var system:ISystem;
	static final polled:Array<IPollable> = [];
	static var color = WAITING;
	static var framesLeft = -1;
	static var keyboard:Keyboard;
	static var pads:Gamepads;
	static var actions:Actions;

	static function main():Void {
		#if js
		window = new helix.platform.adapters.window.dom.DomWindowAdapter({canvasId: "canvas"});
		var domEvents = new helix.platform.adapters.events.dom.DomEventsAdapter({canvasId: "canvas"});
		events = domEvents;
		keyboardAdapter = new helix.platform.adapters.keyboard.dom.DomKeyboardAdapter({events: domEvents});
		gamepadsAdapter = new helix.platform.adapters.gamepads.dom.DomGamepadsAdapter({events: domEvents});
		graphics = new helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter({canvasId: "canvas"});
		system = new helix.platform.adapters.system.dom.DomSystemAdapter();
		#else
		window = new helix.platform.adapters.window.sdl3.Sdl3WindowAdapter({graphics: Gl});
		graphics = new helix.platform.adapters.graphics.sokol.SokolGraphicsAdapter();
		var sdlEvents = new helix.platform.adapters.events.sdl3.Sdl3EventsAdapter();
		events = sdlEvents;
		keyboardAdapter = new helix.platform.adapters.keyboard.sdl3.Sdl3KeyboardAdapter({events: sdlEvents});
		gamepadsAdapter = new helix.platform.adapters.gamepads.sdl3.Sdl3GamepadsAdapter({events: sdlEvents});
		system = new helix.platform.adapters.system.sdl3.Sdl3SystemAdapter();
		#end
		window.title = "helix-services: input";
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

	/** Makes the keyboard and the gamepads over the events and the platform's devices, and the action over them. */
	static function setup():Void {
		keyboard = new Keyboard(events, keyboardAdapter);
		pads = new Gamepads(events, gamepadsAdapter);
		polled.push(keyboard);
		polled.push(pads);
		actions = new Actions([keyboard, pads]);
		actions.bind("jump", Keyboard(Space), Pad(0, South));
		trace("hold Space or the pad's bottom button");
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
		color = actions.isDown("jump") ? DONE : WAITING;
		graphics.beginFrame(window.framebufferWidth, window.framebufferHeight, color);
		graphics.endFrame();
		graphics.present();
		return framesLeft < 0 || --framesLeft > 0;
	}

	/** Frees what was made, in the reverse order, and closes the window where the program owns one. */
	static function dispose():Void {
		graphics.dispose();
		gamepadsAdapter.dispose();
		keyboardAdapter.dispose();
		events.dispose();
		if (window.canClose())
			window.close();
	}
}
