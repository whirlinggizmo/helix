import helix.services.saves.Saves;
import helix.services.screen.Screen;

/** Checks Screen over a fake window: no design (the window's own size, at its pixel ratio); a design letterboxed, fitted pixel-perfect,
	stretched and expanded, and positions both ways; a resize seen for one frame; leaving fullscreen going back to the windowed size
	and place; and the window kept between runs. */
class ScreenTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-9;

	static function main():Void {
		var events = new FakeEvents(), window = new FakeWindow();
		window.ratio = 2;
		var screen = new Screen(window, events);
		function frame(?list:Array<helix.platform.Event>) {
			if (list != null)
				for (e in list)
					events.next.push(e);
			events.poll();
			screen.poll();
		}
		frame();
		check(screen.width == 800 && screen.height == 600 && screen.scaleX == 2 && screen.viewportWidth == 1600, "no design: the window's own size");

		screen.setDesignSize(320, 180, Letterbox);
		check(screen.scaleX == 1600 / 320 && screen.viewportWidth == 1600 && screen.viewportHeight == 900 && screen.viewportY == 150,
			"letterbox: as large as fits whole, bars above and below");
		check(near(screen.toDesignX(800), 160) && near(screen.toDesignY(150), 0) && near(screen.toScreenY(180), 1050), "positions both ways");
		screen.setDesignSize(320, 180, PixelPerfect);
		check(screen.scaleX == 5 && screen.viewportWidth == 1600, "pixel-perfect: a whole number");
		window.logicalWidth = 700;
		frame([Resized(700, 600)]);
		check(screen.resized && screen.scaleX == 4 && screen.viewportWidth == 1280 && screen.viewportX == 60, "a resize: seen, the fit redone");
		frame();
		check(!screen.resized, "resized for one frame");
		screen.setDesignSize(320, 180, Stretch);
		check(screen.scaleX == 1400 / 320 && screen.scaleY == 1200 / 180 && screen.viewportX == 0, "stretch: fills, unevenly");
		screen.setDesignSize(320, 180, Expand);
		check(screen.width == 320
			&& near(screen.height, 1200 / (1400 / 320))
			&& screen.viewportHeight == 1200, "expand: grown on its short side");

		window.left = 40;
		window.top = 30;
		frame();
		screen.requestFullscreen(true);
		window.logicalWidth = 1920;
		window.logicalHeight = 1080;
		frame([Resized(1920, 1080)]);
		check(screen.fullscreen, "fullscreen");
		window.full = false;
		frame();
		check(window.logicalWidth == 700 && window.logicalHeight == 600 && window.left == 40 && window.top == 30,
			"leaving fullscreen: back to the windowed size and place");

		var files = new FakeFileSystem();
		var saves = new Saves(files);
		screen.remember(saves);
		files.poll();
		frame();
		saves.poll();
		files.poll();
		var next = new FakeWindow(), again = new Saves(files);
		var restored = new Screen(next, events);
		restored.remember(again);
		files.poll();
		check(next.logicalWidth == 700 && next.left == 40 && next.top == 30 && !next.full, "the window kept between runs, and asked for again");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
