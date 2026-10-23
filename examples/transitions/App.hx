import helix.debug.FpsOverlay;
import helix.host.Host;
import helix.host.Screen;
import helix.host.ScreenShape;
import helix.host.Window;
import helix.input.Input;
import helix.input.Key;
import helix.render2d.Drawing2D;
import helix.render2d.Stage;
import helix.scene.transition.Transition;
import helix.scene.transition.Diamond;
import helix.scene.transition.Fade;
import helix.scene.transition.Iris;
import helix.scene.transition.Noise;
import helix.scene.transition.Slide;
import helix.scene.transition.SlideDirection;
import helix.time.Time;
import helix.tween.Ease;
import helix.ui.FullscreenButton2D;

/** The transitions between two screens on the stage (helix.scene.transition.Transition): each key swaps the screen shown through one, at its middle.
	1 fades (Fade); 2 slides a cover across (Slide), D stepping through its eight directions and B choosing whether it leaves back the way it
	came; 3 closes a round hole on a point and opens it again (Iris), 4 a diamond (Diamond), the point where the pointer last clicked (the
	middle until then); 5 covers and uncovers square by square (Noise), C stepping its squares' size (8, 16, 32, 64 units). Any of them can wait before it starts (L, a delay of half a second),
	stay covered at the middle (H, a hold of half a second) and ease each half (E: linear, cubic slamming shut in a fifth of the time and easing open over the rest, coverSeconds and
	uncoverSeconds, expo or sine in and out), S
	slowing them threefold. A graph at the bottom right, over the transitions, draws the chosen eases, time across and progress up, and while a
	transition runs a line at its progress (Transition.progress), crossing the curve where it is. The icon at the top right toggles fullscreen (FullscreenButton2D). Escape quits where quitting means anything. */
class App extends helix.App {
	static var DIRECTIONS:Array<SlideDirection> = [Left, Right, Up, Down, UpLeft, UpRight, DownLeft, DownRight];

	// The two screens, one on the stage at a time, and which.
	var screens = [new Drawing2D(), new Drawing2D()];
	var shown = 0;
	var hud = new Drawing2D();
	// The ease graph, over everything, the transition's cover included.
	var plot = new Drawing2D();
	// The fullscreen icon, top right, over everything too.
	var fullscreen = new FullscreenButton2D();
	var fps = new FpsOverlay();
	var transition:Null<Transition>;
	var direction = 0;
	var back = false;
	var delayed = false;
	var held = false;

	// The eases tried (E): a name, the covering half's and the uncovering half's.
	// The eases tried (E): a name, the share of the time spent covering, and the covering half's and uncovering half's curves.
	static var EASES:Array<{
		name:String,
		share:Float,
		cover:Float->Float,
		uncover:Float->Float
	}> = [
		{
			name: "linear",
			share: .5,
			cover: t -> t,
			uncover: t -> t
		},
		{
			name: "cubic: slam shut, ease open",
			share: .2,
			cover: t -> Ease.cubicIn(t),
			uncover: t -> Ease.cubicOut(t)
		},
		{
			name: "expo in and out",
			share: .5,
			cover: t -> Ease.expoInOut(t),
			uncover: t -> Ease.expoInOut(t)
		},
		{
			name: "sine in and out",
			share: .5,
			cover: t -> Ease.sineInOut(t),
			uncover: t -> Ease.sineInOut(t)
		}
		];

	// Each transition's seconds (S: normal or slow, to see the eases).
	var slow = false;
	var ease = 0;

	// Noise's square sizes tried (C).
	static var CELLS = [8., 16., 32., 64.];

	var cell = 2;
	// Where the iris and the diamond close: the last click, the stage's units (NaN: the middle).
	var pointX = Math.NaN;
	var pointY = Math.NaN;

	override public function init():Void {
		Window.title = "HeliX transitions";
		Window.requestSize(900, 540);
		Stage.color = 0xff000000;
		Stage.addChild(screens[0]);
		Stage.addChild(hud);
		Stage.addChild(fps);
	}

	override public function update(dt:Float):Void {
		if (Host.canQuit() && Input.isFramePressed(Key.Escape))
			Host.quit();
		if (Input.isFramePressed(Key.D))
			direction = (direction + 1) % DIRECTIONS.length;
		if (Input.isFramePressed(Key.B))
			back = !back;
		if (Input.isFramePressed(Key.L))
			delayed = !delayed;
		if (Input.isFramePressed(Key.H))
			held = !held;
		if (Input.isFramePressed(Key.C))
			cell = (cell + 1) % CELLS.length;
		if (Input.isFramePressed(Key.S))
			slow = !slow;
		if (Input.isFramePressed(Key.E))
			ease = (ease + 1) % EASES.length;
		// The design for the window's shape first, then the icon in it: a click on the icon isn't the iris's point.
		ScreenShape.update();
		fullscreen.update();
		if (Input.pointerFramePressed && !fullscreen.hovered) {
			pointX = Stage.camera.screenToWorldX(Input.pointerX);
			pointY = Stage.camera.screenToWorldY(Input.pointerY);
		}
		if (Input.isFramePressed(Key.Digit1))
			swap(new Fade(seconds(.8)));
		if (Input.isFramePressed(Key.Digit2))
			swap(new Slide(seconds(.8), DIRECTIONS[direction], back));
		if (Input.isFramePressed(Key.Digit3)) {
			var iris = new Iris(seconds(1));
			if (!Math.isNaN(pointX))
				iris.setPoint(pointX, pointY);
			swap(iris);
		}
		if (Input.isFramePressed(Key.Digit4)) {
			var diamond = new Diamond(seconds(1));
			if (!Math.isNaN(pointX))
				diamond.setPoint(pointX, pointY);
			swap(diamond);
		}
		if (Input.isFramePressed(Key.Digit5))
			swap(new Noise(seconds(1), CELLS[cell]));
		fps.update(dt, Time.frameCpu);

		// Both screens drawn over what's visible, in the design for the window's shape.
		var x = Screen.visibleX,
			y = Screen.visibleY,
			w = Screen.visibleWidth,
			h = Screen.visibleHeight;
		for (i in 0...2) {
			var screen = screens[i];
			screen.clear();
			screen.rect(x, y, w, h, i == 0 ? 0xff2a4d7a : 0xff7a3a2a);
			screen.drawText(i == 0 ? "Screen A" : "Screen B", x + w / 2, y + h / 2 - 24, 48, 0xfff5f5f5, Center);
		}
		hud.clear();
		var keys = '[1] fade  [2] slide ${DIRECTIONS[direction]}${back ? ", back" : ""}  [D] direction  [B] back  [3] iris  [4] diamond  [5] noise ${CELLS[cell]}  [C] squares  click: the iris\'s point\n[L] delay ${delayed ? "on" : "off"}  [H] hold ${held ? "on" : "off"}  [E] ease ${EASES[ease].name}  [S] ${slow ? "slow" : "normal"}';
		hud.drawTextWrapped(keys, x + 12, y + 36, 16, w - 24, 0xffe0e0e0);
		if (!Math.isNaN(pointX))
			hud.circleLines(pointX, pointY, 6, 2, 0xffffe060);
		// Lifted over the cover each frame: a transition puts its cover on top as it starts and again at its middle.
		Stage.addChild(plot);
		Stage.addChild(fullscreen);
		plot.clear();
		graph(x + w - 172, y + h - 112, 160, 100);
		fps.setPosition(x + 12, y + 10);
	}

	// The chosen eases at x, y, width x height: the covering half on the left, the uncovering on the right, progress up; the running
	// transition's progress a line across, which crosses the curve where it is.
	function graph(x:Float, y:Float, width:Float, height:Float):Void {
		plot.rect(x, y, width, height, 0xa0101010);
		var chosen = EASES[ease], last = [0., 0.];
		// Time across, the swap where the covering share ends.
		var share = chosen.share;
		for (i in 0...41) {
			var t = i / 40, half = t < share ? chosen.cover(t / share) * .5 : .5 + chosen.uncover((t - share) / (1 - share)) * .5;
			var px = x + t * width,
				py = y + height - Math.max(0, Math.min(1, half)) * height;
			if (i > 0)
				plot.line(last[0], last[1], px, py, 2, 0xffc8c8c8);
			last[0] = px;
			last[1] = py;
		}
		var running = transition;
		if (running != null && running.running) {
			var p = running.progress;
			plot.line(x, y + height - p * height, x + width, y + height - p * height, 1, 0x80ffe060);
			plot.circle(x + 6, y + height - p * height, 4, 0xffffe060);
		}
	}

	// A transition's seconds: as given, or three times as long while slow.
	function seconds(normal:Float):Float
		return slow ? normal * 3 : normal;

	// The screen shown swapped for the other at by's middle, unless one is running.
	function swap(by:Transition):Void {
		if (transition != null && transition.running)
			return;
		transition = by;
		by.delay = delayed ? .5 : 0;
		by.hold = held ? .5 : 0;
		// The time split as the ease asks: "slam shut, ease open" closes in a fifth of it.
		var total = by.seconds;
		by.coverSeconds = total * EASES[ease].share;
		by.uncoverSeconds = total - by.coverSeconds;
		by.coverEase = EASES[ease].cover;
		by.uncoverEase = EASES[ease].uncover;
		var from = screens[shown], to = screens[1 - shown];
		shown = 1 - shown;
		by.run(() -> {
			Stage.removeChild(from);
			// Under the text over everything.
			Stage.addChild(to);
			Stage.addChild(hud);
			Stage.addChild(fps);
		});
	}
}
