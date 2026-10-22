package helix.ui;

import helix.graphics.Color;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Input;
import helix.render2d.Drawing2D;
import helix.render2d.Stage;

/** An icon that toggles fullscreen: four corner brackets, pointing out while windowed and in while fullscreen, brighter under the pointer.
	On the stage at the visible area's top right, margin in, whatever the window's shape; hidden where the window can't go fullscreen
	(Window.canFullscreen: a page that may not). A click on it asks (Window.requestFullscreen), which the browser grants as it follows a
	click. It needs no Ui: add it to the stage, over the game, and call update once a frame. */
class FullscreenButton2D extends Drawing2D {
	/** An icon size stage units across (18 unless given), in color (0xAARRGGBB, a light gray unless given). */
	public function new(size = 18., color = 0xc0e8e8e8) {
		super();
		this.size = size > 8 ? size : 8;
		this.color = color;
	}

	/** Its size across, the stage's units. */
	public var size(default, null):Float;

	/** Its color, 0xAARRGGBB; drawn opaque under the pointer. */
	public var color:Int;

	/** How far in from the visible area's top-right corner it sits, the stage's units: 10 to start. */
	public var margin:Float = 10;

	/** Whether the pointer is over it, as of the last update: a game skips its own click there. */
	public var hovered(default, null):Bool = false;

	/** Places it, draws it for the window's state, and asks for fullscreen or a window when it's clicked: once a frame, after
		ScreenShape.update when the game uses it. Whether it was clicked. */
	public function update():Bool {
		clear();
		visible = Window.canFullscreen();
		if (!visible) {
			hovered = false;
			return false;
		}
		var x = Screen.visibleX + Screen.visibleWidth - margin - size,
			y = Screen.visibleY + margin;
		var px = Stage.camera.screenToWorldX(Input.pointerX),
			py = Stage.camera.screenToWorldY(Input.pointerY);
		hovered = Input.pointerX >= 0 && px >= x && px <= x + size && py >= y && py <= y + size;
		var clicked = hovered && Input.pointerFramePressed;
		if (clicked)
			Window.requestFullscreen(!Window.fullscreen);
		// Four brackets, one a corner: out at the corners while windowed (to fill the screen), in at the middle while fullscreen.
		var tint = hovered ? Color.withAlpha(color, 255) : color,
			thick = Math.max(1.5, size / 10),
			arm = size * .32,
			inward = Window.fullscreen;
		for (corner in 0...4) {
			var right = corner % 2 == 1, down = corner >= 2;
			// The bracket's elbow and the way its arms run.
			var ex = right ? x + size : x,
				ey = down ? y + size : y,
				ax = right ? -arm : arm,
				ay = down ? -arm : arm;
			if (inward) {
				ex += ax;
				ey += ay;
				ax = -ax;
				ay = -ay;
			}
			this.line(ex, ey, ex + ax, ey, thick, tint);
			this.line(ex, ey, ex, ey + ay, thick, tint);
		}
		return clicked;
	}
}
