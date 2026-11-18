import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.tweens.*;

/** Plays tweens (`helix.raylib.extras.tweens`): a panel slides in and its title fades in after it, the two placed in a sequence, and a
	ball goes back and forth for ever, all stepped by one set. The `quit_after_frame` option (`--quit_after_frame=60` natively,
	`?quit_after_frame=60` in a page) quits it after that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: tweens");
		SetTargetFPS(60);
		var tweens = new Tweens();
		var panel = new Vector2(-400, 60);
		var title = new ColorTween(BLANK, RAYWHITE, 0.2);
		tweens.add(new TweenSequence().append(new Vector2Tween(panel, new Vector2(40, 60), 0.3, Ease.outCubic, panel)).append(title));
		var ball = tweens.add(new FloatTween(60, 740, 1.2, Ease.inOutSine));
		ball.repeatCount = -1;
		ball.yoyo = true;
		while (!WindowShouldClose()) {
			tweens.update(GetFrameTime());
			BeginDrawing();
			ClearBackground(new Color(16, 14, 22, 255));
			DrawRectangleV(panel, new Vector2(360, 120), DARKBLUE);
			DrawText("tweens", Std.int(panel.x) + 20, 100, 40, title.value);
			DrawCircle(Std.int(ball.value), 330, 24, ORANGE);
			EndDrawing();
		}
		CloseWindow();
	}
}
