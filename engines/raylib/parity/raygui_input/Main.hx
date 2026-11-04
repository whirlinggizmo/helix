import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.Window.*;
import helix.raylib.internal.Runtime;

// ref.c's raygui controls over nine frames of played input, drawn by helix-raylib; the ninth frame saved as helix.png. Frame 0 turns the
// wheel over the list view and types 'H'; frame 1 presses on a list item and types 'i'; frame 2 holds the button down on the color panel
// and types '!'; frame 3 lets it go and types 'X' into a second text box, which frames 4 to 8 edit with Left, Backspace, End, Home and
// Delete. The last frame is saved.
class Main {
	static inline final KEY_UP_EVENT = 1;
	static inline final KEY_DOWN_EVENT = 2;
	static inline final MOUSE_BUTTON_UP_EVENT = 5;
	static inline final MOUSE_BUTTON_DOWN_EVENT = 6;
	static inline final MOUSE_POSITION = 7;
	static inline final MOUSE_WHEEL = 8;

	static function R(x:Float, y:Float, w:Float, h:Float):Rectangle
		return new Rectangle(x, y, w, h);

	static function Play(type:Int, a:Int, b:Int):Void {
		var e = new AutomationEvent();
		e.type = type;
		e.params = [a, b, 0, 0];
		PlayAutomationEvent(e);
	}

	// A character typed this frame, as raygui reads it.
	static function Type(c:Int):Void
		Runtime.charsPressed.push(c);

	static function main():Void {
		InitWindow(960, 600, "raygui input");
		var listScroll = [0], listActive = [-1], tab = [1], drop = [1], valueBox = [25];
		var text = ["Edit"],
			keys = ["abcdef"],
			input = ["secret"],
			secret = [false];
		var color = new Color(40, 160, 90, 255);
		var hsv = new Vector3(200, 0.5, 0.8);
		var alpha = [0.6];
		var scroll = new Vector2(-50, -30),
			cell = new Vector2(),
			view = new Rectangle();
		var tabs = ["One", "Two", "Three"];
		var frame = 0;
		while (!WindowShouldClose()) {
			BeginDrawing();
			if (frame == 0) {
				Play(MOUSE_POSITION, 400, 120);
				Play(MOUSE_WHEEL, 0, -2);
				Type("H".code);
			}
			if (frame == 1) {
				Play(MOUSE_POSITION, 400, 100);
				Play(MOUSE_BUTTON_DOWN_EVENT, 0, 0);
				Type("i".code);
			}
			if (frame == 2) {
				Play(MOUSE_POSITION, 830, 60);
				Type("!".code);
			}
			if (frame == 3) {
				Play(MOUSE_BUTTON_UP_EVENT, 0, 0);
				Play(MOUSE_POSITION, -100, -100);
				Type("X".code);
			}
			if (frame == 4)
				Play(KEY_DOWN_EVENT, KEY_LEFT, 0);
			if (frame == 5) {
				Play(KEY_UP_EVENT, KEY_LEFT, 0);
				Play(KEY_DOWN_EVENT, KEY_BACKSPACE, 0);
			}
			if (frame == 6) {
				Play(KEY_UP_EVENT, KEY_BACKSPACE, 0);
				Play(KEY_DOWN_EVENT, KEY_END, 0);
			}
			if (frame == 7) {
				Play(KEY_UP_EVENT, KEY_END, 0);
				Play(KEY_DOWN_EVENT, KEY_HOME, 0);
			}
			if (frame == 8) {
				Play(KEY_UP_EVENT, KEY_HOME, 0);
				Play(KEY_DOWN_EVENT, KEY_DELETE, 0);
			}
			ClearBackground(GetColor(GuiGetStyle(DEFAULT, BACKGROUND_COLOR)));
			GuiWindowBox(R(20, 20, 300, 200), "#198#Window box");
			GuiGroupBox(R(30, 70, 280, 50), "Group");
			GuiLabel(R(40, 80, 260, 30), "Line one\nLine two");
			GuiPanel(R(30, 130, 280, 80), "Panel");
			GuiListView(R(340, 20, 160, 200), "Zero;One;Two;Three;Four;Five;Six;Seven;Eight;Nine;Ten;Eleven", listScroll, listActive);
			GuiTextBox(R(340, 380, 160, 24), text, 32, frame < 3);
			GuiTextBox(R(620, 400, 140, 24), keys, 32, frame >= 3);
			GuiValueBox(R(380, 410, 120, 24), "Value", valueBox, 0, 100, true);
			GuiScrollPanel(R(20, 240, 300, 160), "Scroll panel", R(0, 0, 500, 400), scroll, view);
			GuiGrid(R(340, 240, 160, 120), null, 40, 4, cell);
			GuiTabBar(R(20, 450, 600, 24), tabs, 3, tab);
			GuiMessageBox(R(520, 60, 240, 140), "#191#Message", "Hello raygui", "Ok;Cancel");
			GuiTextInputBox(R(520, 220, 240, 160), "Input", "Your name:", "Ok;Cancel", input, 64, secret);
			GuiSetAlpha(0.5);
			GuiButton(R(20, 530, 120, 30), "Half alpha");
			GuiSetAlpha(1.0);
			GuiEnableTooltip();
			GuiSetTooltip("A tooltip");
			GuiSetState(STATE_FOCUSED);
			GuiButton(R(160, 530, 120, 30), "Tooltip");
			GuiSetState(STATE_NORMAL);
			GuiDisableTooltip();
			GuiColorBarAlpha(R(780, 170, 160, 16), null, alpha);
			GuiColorPickerHSV(R(780, 200, 120, 120), null, hsv);
			GuiColorPicker(R(780, 20, 120, 140), null, color);
			DrawRectangle(780, 330, 40, 40, color);
			for (i in 0...16)
				GuiDrawIcon(i + 1, 20 + i * 36, 490, 2, DARKGRAY);
			GuiSetStyle(DEFAULT, TEXT_WRAP_MODE, TEXT_WRAP_WORD);
			GuiSetStyle(DEFAULT, TEXT_ALIGNMENT_VERTICAL, TEXT_ALIGN_TOP);
			GuiLabel(R(300, 520, 140, 60), "Words wrapped at the label's edge, as raygui wraps them");
			GuiSetStyle(DEFAULT, TEXT_WRAP_MODE, TEXT_WRAP_NONE);
			GuiSetStyle(DEFAULT, TEXT_ALIGNMENT_VERTICAL, TEXT_ALIGN_MIDDLE);
			GuiSetIconScale(2);
			GuiButton(R(460, 530, 140, 40), GuiIconText(ICON_HEART, "Scaled"));
			GuiSetIconScale(1);
			GuiLabel(R(620, 530, 100, 20), "A label too long for its bounds");
			GuiDropdownBox(R(780, 440, 140, 24), "One;Two;Three;Four", drop, true);
			if (frame == 8)
				TakeScreenshotAsync("helix.png");
			EndDrawing();
			frame++;
		}
		CloseWindow();
	}
}
