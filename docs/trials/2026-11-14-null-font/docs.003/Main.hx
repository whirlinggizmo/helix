import helix.raylib.*;
import helix.raylib.Raylib.*;

class Main {
    static function main() {
        var maxFrames = -1;
        for (a in Sys.args())
            if (StringTools.startsWith(a, "--frames="))
                maxFrames = Std.parseInt(a.substr(9));

        InitWindow(800, 450, "WARDENS");
        SetTargetFPS(60);

        var panel:Texture2D = null;
        var font:Font = null;
        LoadTextureAsync("assets/ui/panel.png", function(t) panel = t);
        LoadFontExAsync("assets/ui/font.ttf", 64, null, 0, function(f) font = f);

        var frame = 0;
        var shooting = false;
        var shotDone = false;
        while (!WindowShouldClose()) {
            frame++;
            if (IsKeyPressed(KEY_ENTER)) break;

            BeginDrawing();
            ClearBackground(new Color(20, 20, 28, 255));

            if (panel != null) {
                DrawTexturePro(panel,
                    new Rectangle(0, 0, panel.width, panel.height),
                    new Rectangle((800 - 420) / 2, (450 - 260) / 2, 420, 260),
                    new Vector2(0, 0), 0, WHITE);
            }

            if (font != null) {
                var title = "WARDENS";
                var ts = MeasureTextEx(font, title, 64, 2);
                DrawTextEx(font, title, new Vector2((800 - ts.x) / 2, 120), 64, 2, WHITE);

                // blinks once a second: on for half a second, off for half
                if (Std.int(GetTime() * 2) % 2 == 0) {
                    var prompt = "PRESS ENTER";
                    var ps = MeasureTextEx(font, prompt, 24, 2);
                    DrawTextEx(font, prompt, new Vector2((800 - ps.x) / 2, 120 + ts.y + 30), 24, 2, LIGHTGRAY);
                }
            }
            EndDrawing();

            if (maxFrames > 0 && frame >= maxFrames) {
                if (!shooting) {
                    shooting = true;
                    TakeScreenshotAsync("shot.png", function() shotDone = true);
                }
                if (shotDone) break;
            }
        }
        CloseWindow();
    }
}
