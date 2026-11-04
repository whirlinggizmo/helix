import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.Gui.*;
import helix.raylib.internal.Automation;
import helix.raylib.internal.Runtime;
import Parity.*;

// helix-raylib's raygui: its results and the values its controls change over frames of scripted mouse input, and the vertices a few
// controls batch, printed as ref.c prints raygui's C. The mouse is played into helix-raylib's automation state, as ref.c's raygui reads it.
@:access(helix.raylib.internal.Automation)
@:access(helix.raylib.internal.Runtime)
class RayguiBits {
	static var input:Automation;

	// A frame of input: the mouse at x, y, its left button down or up, the wheel turned by w.
	static function F(x:Float, y:Float, d:Bool, w:Float):Void {
		input.previousButtons[0] = input.buttons[0];
		input.buttons[0] = d;
		input.mouseX = x;
		input.mouseY = y;
		input.wheelY = w;
	}

	static function I(name:String, v:Int):Void
		line('$name int $v');

	// A word as C's unsigned int.
	static function word(v:Int):haxe.Int64
		return haxe.Int64.make(0, v);

	static function Dump(name:String):Void
		for (c in 0...16)
			line('$name $c ' + [for (p in 0...24) GuiGetStyle(c, p)].join(" "));

	// Polls until done says it is, as a program's frames would.
	static function pump(done:Void->Bool):Void {
		for (_ in 0...10000) {
			if (done())
				return;
			Runtime.pollAll();
			var now = Runtime.waiting;
			Runtime.waiting = [];
			for (f in now)
				f();
		}
		throw "never answered";
	}

	static function main() {
		open();
		var files = new DiskFiles();
		Runtime.polled.push(files);
		Runtime.assets = new helix.services.assets.Assets([new helix.services.assets.FileSystemSource(files)]);
		Runtime.saves = new helix.services.saves.Saves(files);
		Runtime.polled.push(Runtime.saves);
		depth = false;
		input = new Automation();
		Automation.active = input;
		Runtime.played = input;
		input.mouseX = input.mouseY = -100;
		GuiLoadStyleDefault();
		for (c in 0...16)
			line('style $c ' + [for (p in 0...24) GuiGetStyle(c, p)].join(" "));
		GuiSetStyle(DEFAULT, BORDER_WIDTH, 3);
		I("propagated", GuiGetStyle(SLIDER, BORDER_WIDTH));
		GuiSetStyle(DEFAULT, TEXT_SIZE, 12);
		I("extended", GuiGetStyle(SLIDER, TEXT_SIZE));
		GuiLoadStyleDefault();
		I("reloaded", GuiGetStyle(SLIDER, BORDER_WIDTH));
		str("icontext", GuiIconText(5, "Open"));
		str("iconalone", GuiIconText(123, null));
		str("iconnegative", GuiIconText(-1, null));
		var icons = GuiGetIcons(), sum = haxe.Int64.ofInt(0);
		for (i in 0...2048)
			sum += word(icons[i]);
		line('icons sum ${haxe.Int64.toStr(sum)} ${haxe.Int64.toStr(word(icons[8]))} ${haxe.Int64.toStr(word(icons[2047]))}');
		GuiLock();
		I("locked", GuiIsLocked() ? 1 : 0);
		GuiUnlock();
		I("unlocked", GuiIsLocked() ? 1 : 0);
		GuiDisable();
		I("disabled", GuiGetState());
		GuiEnable();
		I("enabled", GuiGetState());
		shape("start");

		var b = R(10, 10, 100, 30);
		F(50, 20, false, 0);
		I("button.hover", GuiButton(b, "Ok"));
		F(50, 20, true, 0);
		I("button.down", GuiButton(b, "Ok"));
		F(50, 20, false, 0);
		I("button.released", GuiButton(b, "Ok"));
		F(200, 20, true, 0);
		F(200, 20, false, 0);
		I("button.away", GuiButton(b, "Ok"));
		shape("button");

		var on = [false];
		F(50, 20, true, 0);
		GuiToggle(b, "T", on);
		F(50, 20, false, 0);
		GuiToggle(b, "T", on);
		I("toggle", on[0] ? 1 : 0);
		var checked = [false];
		F(15, 15, true, 0);
		GuiCheckBox(R(10, 10, 12, 12), "Check", checked);
		F(40, 15, false, 0);
		I("checkbox.result", GuiCheckBox(R(10, 10, 12, 12), "Check", checked));
		I("checkbox", checked[0] ? 1 : 0);
		var combo = [1];
		F(50, 20, true, 0);
		GuiComboBox(b, "A;B;C", combo);
		I("combo", combo[0]);
		F(50, 20, false, 0);
		F(50, 20, true, 0);
		GuiComboBox(b, "A;B;C", combo);
		I("combo.wrapped", combo[0]);
		var drop = [0];
		F(50, 20, false, 0);
		F(50, 20, true, 0);
		I("dropdown.open", GuiDropdownBox(b, "A;B;C", drop, false));
		F(50, 85, true, 0);
		GuiDropdownBox(b, "A;B;C", drop, true);
		F(50, 85, false, 0);
		I("dropdown.chosen", GuiDropdownBox(b, "A;B;C", drop, true));
		I("dropdown", drop[0]);
		shape("choices");

		var group = [0];
		F(10, 10, false, 0);
		F(160, 20, true, 0);
		F(160, 20, false, 0);
		GuiToggleGroup(R(10, 10, 60, 20), "A;B;C\nD;E", group);
		I("group", group[0]);
		F(40, 40, true, 0);
		F(40, 40, false, 0);
		GuiToggleGroup(R(10, 10, 60, 20), "A;B;C\nD;E", group);
		I("group.row", group[0]);
		var slide = [0];
		F(50, 20, true, 0);
		F(50, 20, false, 0);
		I("toggleslider.result", GuiToggleSlider(b, "Off;On;Auto", slide));
		I("toggleslider", slide[0]);
		shape("toggles");

		var value = [0.];
		var s = R(20, 50, 200, 20);
		F(120, 60, true, 0);
		I("slider.result", GuiSlider(s, "L", "R", value, 0, 10));
		num("slider", value[0]);
		F(300, 60, true, 0);
		GuiSlider(s, "L", "R", value, 0, 10);
		num("slider.dragged", value[0]);
		F(77.5, 60, true, 0);
		GuiSlider(s, "L", "R", value, 0, 10);
		num("slider.back", value[0]);
		F(77.5, 60, false, 0);
		GuiSlider(s, "L", "R", value, 0, 10);
		num("slider.released", value[0]);
		var bar = [0.];
		F(90, 60, true, 0);
		GuiSliderBar(s, null, null, bar, -5, 5);
		num("sliderbar", bar[0]);
		F(90, 60, false, 0);
		GuiSliderBar(s, null, null, bar, -5, 5);
		var progress = [150.];
		GuiProgressBar(s, null, null, progress, 0, 100);
		num("progress", progress[0]);
		shape("sliders");

		var spin = [5];
		F(205, 60, true, 0);
		GuiSpinner(s, null, spin, 0, 6, false);
		F(205, 60, false, 0);
		GuiSpinner(s, null, spin, 0, 6, false);
		I("spinner", spin[0]);
		F(205, 60, true, 0);
		GuiSpinner(s, null, spin, 0, 6, false);
		F(205, 60, false, 0);
		GuiSpinner(s, null, spin, 0, 6, false);
		I("spinner.held", spin[0]);
		var box = [500];
		F(0, 0, false, 0);
		GuiValueBox(s, "V", box, 0, 100, false);
		I("valuebox", box[0]);
		F(50, 60, true, 0);
		I("valuebox.click", GuiValueBox(s, "V", box, 0, 100, false));
		shape("numbers");

		var scrollIndex = [0], active = [-1], focus = [-1];
		var items = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"];
		var l = R(10, 10, 100, 100);
		F(50, 30, false, -3);
		GuiListViewEx(l, items, 10, scrollIndex, active, focus);
		I("list.scroll", scrollIndex[0]);
		I("list.focus", focus[0]);
		F(50, 30, true, 0);
		GuiListViewEx(l, items, 10, scrollIndex, active, focus);
		I("list.active", active[0]);
		F(50, 30, false, 0);
		F(50, 30, true, 0);
		GuiListViewEx(l, items, 10, scrollIndex, active, focus);
		I("list.unchosen", active[0]);
		F(105, 100, false, 0);
		F(105, 100, true, 0);
		GuiListView(l, "x;y;z;w;v;u", scrollIndex, active);
		I("list.bar", scrollIndex[0]);
		F(105, 100, false, 0);
		shape("list");

		var scroll = V2(0, 0), cell = V2(0, 0), view = R(0, 0, 0, 0);
		F(50, 50, false, -1);
		GuiScrollPanel(R(10, 10, 150, 120), "Panel", R(0, 0, 400, 300), scroll, view);
		vec2("scroll", scroll);
		rect("view", view);
		F(50, 50, false, 2);
		GuiScrollPanel(R(10, 10, 150, 120), null, R(0, 0, 400, 300), scroll, view);
		vec2("scroll.up", scroll);
		rect("view.plain", view);
		F(73, 58, false, 0);
		GuiGrid(R(10, 10, 200, 100), null, 20, 2, cell);
		vec2("grid.cell", cell);
		F(500, 58, false, 0);
		GuiGrid(R(10, 10, 200, 100), null, 20, 2, cell);
		vec2("grid.outside", cell);
		shape("panels");

		var col = new Color(200, 50, 50, 255);
		var p = R(10, 10, 100, 100);
		F(30, 40, true, 0);
		GuiColorPanel(p, null, col);
		color("colorpanel", col);
		F(80, 90, true, 0);
		GuiColorPanel(p, null, col);
		color("colorpanel.drag", col);
		F(80, 90, false, 0);
		GuiColorPanel(p, null, col);
		var hue = [0.];
		F(15, 70, true, 0);
		GuiColorBarHue(R(10, 10, 20, 120), null, hue);
		num("hue", hue[0]);
		F(15, 300, true, 0);
		GuiColorBarHue(R(10, 10, 20, 120), null, hue);
		num("hue.below", hue[0]);
		F(15, 300, false, 0);
		GuiColorBarHue(R(10, 10, 20, 120), null, hue);
		var alpha = [1.];
		F(47, 15, true, 0);
		GuiColorBarAlpha(R(10, 10, 120, 16), null, alpha);
		num("alpha", alpha[0]);
		F(47, 15, false, 0);
		GuiColorBarAlpha(R(10, 10, 120, 16), null, alpha);
		var pick = new Color(10, 120, 240, 255);
		F(500, 500, false, 0);
		GuiColorPicker(p, null, pick);
		color("picker.idle", pick);
		F(120, 40, true, 0);
		GuiColorPicker(p, null, pick);
		color("picker.hue", pick);
		F(120, 40, false, 0);
		GuiColorPicker(p, null, pick);
		var hsv = V3(120, 0.5, 0.5);
		F(60, 30, true, 0);
		GuiColorPickerHSV(p, null, hsv);
		line('hsv vec3 ${hsv.x} ${hsv.y} ${hsv.z}');
		F(60, 30, false, 0);
		GuiColorPickerHSV(p, null, hsv);
		shape("colors");

		var m = R(10, 10, 250, 150);
		F(50, 140, false, 0);
		F(50, 140, true, 0);
		GuiMessageBox(m, "Title", "Message", "Yes;No");
		F(50, 140, false, 0);
		I("message.yes", GuiMessageBox(m, "Title", "Message", "Yes;No"));
		F(245, 20, true, 0);
		GuiMessageBox(m, "Title", "Message", "Yes;No");
		F(245, 20, false, 0);
		I("message.close", GuiMessageBox(m, "Title", "Message", "Yes;No"));
		F(500, 500, false, 0);
		I("labelbutton", GuiLabelButton(R(10, 10, 5, 10), "A long label"));
		GuiLabel(R(10, 10, 60, 30), "#12#Cut text that runs on\nand a second line");
		GuiSetStyle(DEFAULT, TEXT_WRAP_MODE, TEXT_WRAP_CHAR);
		GuiLabel(R(10, 10, 60, 60), "Wrapped by character at the edge");
		GuiSetStyle(DEFAULT, TEXT_WRAP_MODE, TEXT_WRAP_NONE);
		shape("text");

		// Style and icon files.
		var loaded = false;
		GuiLoadStyleAsync("web/style.rgs", () -> loaded = true);
		pump(() -> loaded);
		Dump("textstyle");
		I("textstyle.font", GuiGetFont().texture.id == GetFontDefault().texture.id ? 1 : 0);
		loaded = false;
		GuiLoadStyleAsync("web/dark.rgs", () -> loaded = true, e -> throw e);
		pump(() -> loaded);
		Dump("binarystyle");
		var names:Array<String> = null;
		loaded = false;
		GuiLoadIconsAsync("web/icons.rgi", true, n -> {
			names = n;
			loaded = true;
		});
		pump(() -> loaded);
		str("icon.name0", names[0]);
		str("icon.name1", names[1]);
		line("icons loaded " + [for (i in 0...18) haxe.Int64.toStr(word(GuiGetIcons()[i]))].join(" "));
		loaded = false;
		GuiLoadIconsAsync("web/icons.rgi", false, n -> {
			names = n;
			loaded = true;
		});
		pump(() -> loaded);
		I("icons.unnamed", names == null ? 1 : 0);
		loaded = false;
		GuiLoadStyleAsync("web/none.rgs", () -> loaded = true, _ -> loaded = true);
		pump(() -> loaded);
		Dump("nostyle");
		save();
	}
}
