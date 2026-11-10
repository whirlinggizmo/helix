import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;

// ref.c's raygui controls in each state, drawn by helix-raylib; its third frame saved as helix.png. The mouse is played off the window
// each frame, so only the state set with GuiSetState shows.
class Main {
	static inline final MOUSE_POSITION = 7;

	static function R(x:Float, y:Float, w:Float, h:Float):Rectangle
		return new Rectangle(x, y, w, h);

	static function Play(type:Int, a:Int, b:Int):Void {
		var e = new AutomationEvent();
		e.type = type;
		e.params = [a, b, 0, 0];
		PlayAutomationEvent(e);
	}

	static function Toggle(r:Rectangle, t:String, v:Bool)
		GuiToggle(r, t, [v]);

	static function CheckBox(r:Rectangle, t:String, v:Bool)
		GuiCheckBox(r, t, [v]);

	static function ComboBox(r:Rectangle, t:String, v:Int)
		GuiComboBox(r, t, [v]);

	static function DropdownBox(r:Rectangle, t:String, v:Int)
		GuiDropdownBox(r, t, [v], false);

	static function Slider(r:Rectangle, a:String, b:String, v:Float)
		GuiSlider(r, a, b, [v], 0, 100);

	static function SliderBar(r:Rectangle, a:String, b:String, v:Float)
		GuiSliderBar(r, a, b, [v], 0, 100);

	static function ProgressBar(r:Rectangle, a:String, b:String, v:Float)
		GuiProgressBar(r, a, b, [v], 0, 100);

	static function Spinner(r:Rectangle, t:String, v:Int)
		GuiSpinner(r, t, [v], 0, 10, false);

	static function ValueBox(r:Rectangle, t:String, v:Int)
		GuiValueBox(r, t, [v], 0, 100, false);

	static function TextBox(r:Rectangle, t:String)
		GuiTextBox(r, [t], 64, false);

	static function ToggleGroup(r:Rectangle, t:String, v:Int)
		GuiToggleGroup(r, t, [v]);

	static function ToggleSlider(r:Rectangle, t:String, v:Int)
		GuiToggleSlider(r, t, [v]);

	static function Column(x:Int, state:Int) {
		GuiSetState(state);
		GuiButton(R(x, 20, 200, 30), "#05#Button");
		Toggle(R(x, 60, 95, 30), "Off", false);
		Toggle(R(x + 105, 60, 95, 30), "On", true);
		CheckBox(R(x, 100, 20, 20), "Checked", true);
		CheckBox(R(x + 110, 100, 20, 20), "Not", false);
		ComboBox(R(x, 130, 200, 24), "One;Two;Three", 1);
		DropdownBox(R(x, 160, 200, 24), "Alpha;Beta;Gamma", 2);
		Slider(R(x + 40, 195, 120, 16), "Min", "Max", 40);
		SliderBar(R(x + 40, 220, 120, 16), "0", "100", 70);
		ProgressBar(R(x + 40, 245, 120, 16), "P", "55%", 55);
		Spinner(R(x + 40, 270, 120, 24), "Spin", 7);
		ValueBox(R(x + 40, 300, 120, 24), "Val", 42);
		TextBox(R(x, 330, 200, 24), "Text box");
		ToggleGroup(R(x, 360, 64, 24), "A;B;C", 1);
		ToggleSlider(R(x, 390, 200, 24), "Off;On", 1);
		GuiLabel(R(x, 420, 200, 20), "#191#Label text");
		GuiLabelButton(R(x, 440, 200, 20), "Label button");
		GuiStatusBar(R(x, 465, 200, 22), "Status bar");
		GuiDummyRec(R(x, 492, 200, 30), "Dummy");
		GuiLine(R(x, 525, 200, 12), "Line");
		GuiLine(R(x, 540, 200, 12), null);
		GuiSetState(STATE_NORMAL);
	}

	static function main():Void {
		InitWindow(960, 560, "raygui");
		var frame = 0;
		while (!WindowShouldClose()) {
			BeginDrawing();
			Play(MOUSE_POSITION, -100, -100);
			ClearBackground(GetColor(GuiGetStyle(DEFAULT, BACKGROUND_COLOR)));
			Column(20, STATE_NORMAL);
			Column(255, STATE_FOCUSED);
			Column(490, STATE_PRESSED);
			Column(725, STATE_DISABLED);
			if (frame == 2)
				TakeScreenshotAsync("helix.png");
			EndDrawing();
			frame++;
		}
		CloseWindow();
	}
}
