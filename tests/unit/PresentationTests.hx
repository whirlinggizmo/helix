import helix.host.Presentation;
import helix.render2d.Camera2D;
import helix.render3d.Camera3D;

/** The app's design fitted to a window (Presentation): each of the six modes on a window wider and one taller than the design, the visible
	area in units and the framebuffer pixels it covers, a camera showing it, and the pointer mapped back into units; and a 3D camera keeping its
	view's width on a narrower viewport (Camera3D.minAspect). */
class PresentationTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-6;

	static function fitted(mode:PresentationMode, width:Int, height:Int, ratio = 1.):Presentation {
		var p = new Presentation();
		p.set(mode, 1280, 720);
		@:privateAccess p.refit(width, height, ratio);
		return p;
	}

	static function main():Void {
		// None: logical pixels.
		var p = new Presentation();
		@:privateAccess p.refit(780, 1688, 2);
		check(p.mode == None && p.scaleX == 2 && p.visibleWidth == 390 && p.visibleHeight == 844, "None: a unit is a logical pixel");
		check(p.width == 390 && p.portrait && p.areaWidth == 780, "and the design is the window");
		check(!p.set(Fit, 0, 720) && p.mode == None, "A size under 1 is refused");

		// Fit: whole, bars across a wider window.
		p = fitted(Fit, 1920, 720);
		check(p.scaleX == 1 && p.areaX == 320 && p.areaWidth == 1280 && p.visibleX == 0 && p.visibleWidth == 1280,
			"Fit: bars beside the design on a wider window");
		p = fitted(Fit, 640, 720);
		check(p.scaleX == .5 && p.areaY == 180 && p.areaHeight == 360 && p.visibleHeight == 720, "and above and below on a taller one");

		// Expand: all the window, more than the design.
		p = fitted(Expand, 1920, 720);
		check(p.scaleX == 1 && p.areaX == 0 && p.areaWidth == 1920 && p.visibleX == -320 && p.visibleWidth == 1920,
			"Expand: the visible area grows past the design, centered on it");
		p = fitted(Expand, 640, 720);
		check(p.visibleY == -360 && p.visibleHeight == 1440 && p.visibleWidth == 1280 && p.portrait, "down, on a taller window");

		// Fill: covers, cropped.
		p = fitted(Fill, 1920, 720);
		check(p.scaleX == 1.5 && p.areaWidth == 1920 && p.areaHeight == 720 && p.visibleY == 120 && p.visibleHeight == 480,
			"Fill: the design covers the window, cropped top and bottom");

		// Stretch: each axis apart.
		p = fitted(Stretch, 1920, 360);
		check(p.scaleX == 1.5 && p.scaleY == .5 && p.visibleWidth == 1280 && p.visibleHeight == 720, "Stretch: each axis its own scale");

		// Integer: whole pixels, at least 1.
		p = fitted(Integer, 2700, 1500);
		check(p.scaleX == 2 && p.areaX == 70 && p.areaY == 30 && p.areaWidth == 2560, "Integer: a whole number of pixels to a unit");
		p = fitted(Integer, 640, 360);
		check(p.scaleX == 1 && p.areaWidth == 640 && p.visibleX == 320 && p.visibleWidth == 640, "and at 1, a window smaller than the design shows its middle");

		// A camera shows the visible area, and the pointer comes back in units.
		p = fitted(Fit, 1920, 720);
		var camera = new Camera2D();
		p.apply(camera);
		check(camera.viewportX == 320 && camera.viewportWidth == 1280 && near(camera.screenToWorldX(320), 0) && near(camera.screenToWorldX(1600), 1280),
			"A camera shows the visible area on the pixels it covers");
		check(near(p.toUnitsX(960), 640) && near(p.toUnitsY(360), 360), "The pointer maps back into units");
		p = fitted(Stretch, 1920, 360);
		p.apply(camera);
		check(near(camera.screenToWorldX(1920), 1280) && near(camera.screenToWorldY(360), 720) && camera.zoomY == .5,
			"A stretched camera has a zoom of its own down");
		p = fitted(Expand, 640, 720);
		p.apply(camera);
		check(near(camera.screenToWorldY(0), -360) && near(camera.screenToWorldY(720), 1080), "An expanded camera shows past the design");

		// Changing the mode refits at once, at the window's last size.
		p.set(Fit, 1280, 720);
		check(p.areaY == 180 && p.visibleY == 0, "A new mode refits at once");
		p.set(None, 0, 0);
		check(p.visibleWidth == 640 && p.scaleX == 1, "None again: logical pixels, at the last pixel ratio");

		// A 3D view keeps its width on a narrower viewport.
		var view = new Camera3D();
		view.setPerspective(1, .1, 100);
		view.setViewport(1600, 900);
		check(view.drawnFovY == 1, "A 3D view without a minimum aspect is as given");
		view.minAspect = 16 / 9;
		check(near(view.drawnFovY, 1), "and with one, on a viewport as wide");
		view.setViewport(390, 844);
		var across = Math.tan(view.drawnFovY / 2) * 390 / 844;
		check(near(across, Math.tan(.5) * 16 / 9), "On a narrower one it sees as far across as at the minimum aspect");
		view.setOrthographic(10, -1, 1);
		check(near(view.drawnHeight * 390 / 844, 10 * 16 / 9), "an orthographic one too");
		view.minAspect = -1;
		check(view.minAspect == 0, "A minimum aspect under 0 is 0");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
