import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Screen.*;
import helix.raylib.extras.tweens.*;

/** Plays tweens (`helix.raylib.extras.tweens`): a panel slides in and its title fades in after it, the two placed in a sequence; a
	ball goes back and forth for ever; and a block crosses with a bounce, waits and comes back smoothly, one tween of two legs. One
	set steps them all. The `quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page) quits it
	after that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: tweens");
		// The 800 x 450 design fitted to any window, a phone's too (helix.raylib.extras.Screen).
		SetScreenFit(800, 450, SCREEN_STRETCH_CANVAS, SCREEN_FIT_EXPAND, false);
		SetTargetFPS(60);
		var tweens = new Tweens();
		var panel = new Vector2(-400, 60);
		var title = new ColorTween(BLANK, RAYWHITE, 0.2);
		tweens.add(new TweenSequence().append(new Vector2Tween(panel, new Vector2(40, 60), 0.3, Ease.outCubic, panel)).append(title));
		var ball = tweens.add(new FloatTween(60, 740, 1.2, Ease.inOutSine));
		ball.repeatCount = -1;
		ball.yoyo = true;
		var block = tweens.add(new FloatTween(40, 720, 1.5, Ease.outBounce).appendDelay(0.5).append(40, 1.5, Ease.inOutSine).appendDelay(0.5));
		block.repeatCount = -1;
		while (!WindowShouldClose()) {
			tweens.update(GetFrameTime());
			BeginDrawing();
			ClearBackground(new Color(16, 14, 22, 255));
			DrawRectangleV(panel, new Vector2(360, 120), DARKBLUE);
			DrawText("tweens", Std.int(panel.x) + 20, 100, 40, title.value);
			DrawCircle(Std.int(ball.value), 330, 24, ORANGE);
			DrawRectangle(Std.int(block.value), 380, 40, 40, SKYBLUE);
			EndDrawing();
		}
		CloseWindow();
	}
}
