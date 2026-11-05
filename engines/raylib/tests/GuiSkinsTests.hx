import haxe.io.Bytes;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
import helix.raylib.modules.RGui;

/** Checks helix-raylib's skins for raygui (`helix.raylib.extras.GuiSkins`), on graphics that keep nothing: no hook until a skin is set, so
	a program setting none draws as raygui does; a skinned button drawing exactly the vertices `DrawTextureNPatch` draws for its state's
	patch, normal, focused, pressed (falling back to focused) and disabled (falling back to normal); a skin set on `DEFAULT` set on every
	control, a control's own after it kept; a sheet cut down and across; a skin put back after one call; and `GuiClearSkins` drawing flat
	again. The controls are locked (`GuiLock`), so the state is the one `GuiSetState` gives, with no mouse. */
@:access(helix.raylib.internal.Frame)
@:access(helix.raylib.modules.RGui)
class GuiSkinsTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// The immediate vertices drawn since the last read, as bytes, quads read through their indices, the frame drawn after.
	static function drawn():String {
		var f = Runtime.frame, out = new StringBuf();
		f.flush();
		for (d in f.pass.draws) {
			if (d.buffers != null)
				continue;
			out.add('${d.texture}:');
			if (d.sprite) {
				// A sprite run: its records.
				for (i in d.firstInstance...d.firstInstance + d.instances)
					out.add(f.spriteData.sub(i * 52, 52).toHex());
				out.add(";");
				continue;
			}
			for (k in d.first...d.first + d.count) {
				var i = d.indices == 0 ? k : Std.int(k / 6) * 4 + [0, 1, 2, 0, 2, 3][k % 6];
				out.add(f.data.sub(i * 36, 36).toHex());
			}
			out.add(";");
		}
		f.draw(64, 64, true);
		return out.toString();
	}

	static function patch(y:Int):NPatchInfo
		return new NPatchInfo(new Rectangle(0, y, 64, 32), 8, 8, 8, 8, NPATCH_NINE_PATCH);

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		var sheet = LoadTextureFromImage(GenImageColor(64, 128, WHITE));
		var bounds = new Rectangle(10, 20, 150, 40);
		GuiLock();

		// No skin set: no hook, and a button draws flat.
		check(RGui.skinned == null, "no hook until a skin is set");
		GuiButton(bounds, "");
		var flat = drawn();
		check(flat.length > 0, "a flat button draws");

		// A skinned button draws its state's patch, as DrawTextureNPatch does.
		var skin = GuiSkinFromTexture(sheet, patch(0), patch(32), null, patch(96));
		GuiSetSkin(BUTTON, GUI_SKIN_BASE, skin);
		check(RGui.skinned != null, "the hook is set with the first skin");
		for (state => y in [
			STATE_NORMAL => 0,
			STATE_FOCUSED => 32,
			STATE_PRESSED => 32,
			STATE_DISABLED => 96
		]) {
			GuiSetState(state);
			GuiButton(bounds, "");
			var skinned = drawn();
			GuiSetState(STATE_NORMAL);
			DrawTextureNPatch(sheet, patch(y), bounds, new Vector2(0, 0), 0, WHITE);
			check(skinned == drawn(), 'state $state draws the patch at y $y');
		}
		GuiSetState(STATE_NORMAL);

		// Skins from a sheet, down and across.
		var down = GuiSkinFromSheet(sheet, 64, 32, 8, 8, 8, 8);
		check(down.normal.source.y == 0 && down.focused.source.y == 32 && down.pressed.source.y == 64 && down.disabled.source.y == 96,
			"a sheet's cells, top down");
		var across = GuiSkinFromSheet(sheet, 32, 128, 4, 4, 4, 4);
		check(across.normal.source.x == 0 && across.focused.source.x == 32 && across.pressed == null && across.disabled == null,
			"a sheet one cell high, read across");

		// DEFAULT sets every control; a control's own after it is kept.
		GuiSetSkin(DEFAULT, GUI_SKIN_BASE, down);
		check(GuiGetSkin(SLIDER, GUI_SKIN_BASE) == down && GuiGetSkin(DEFAULT, GUI_SKIN_BASE) == down, "DEFAULT sets every control");
		GuiSetSkin(BUTTON, GUI_SKIN_BASE, skin);
		check(GuiGetSkin(BUTTON, GUI_SKIN_BASE) == skin && GuiGetSkin(TOGGLE, GUI_SKIN_BASE) == down, "a control's own after DEFAULT");

		// A skin put back after one call changes that call alone.
		var kept = GuiGetSkin(BUTTON, GUI_SKIN_BASE);
		GuiSetSkin(BUTTON, GUI_SKIN_BASE, GuiSkinFromTexture(sheet, patch(64)));
		GuiButton(bounds, "");
		var once = drawn();
		GuiSetSkin(BUTTON, GUI_SKIN_BASE, kept);
		DrawTextureNPatch(sheet, patch(64), bounds, new Vector2(0, 0), 0, WHITE);
		check(once == drawn(), "a skin for one call");
		GuiButton(bounds, "");
		var back = drawn();
		DrawTextureNPatch(sheet, patch(0), bounds, new Vector2(0, 0), 0, WHITE);
		check(back == drawn(), "the skin put back");

		// Cleared: flat again.
		GuiClearSkins();
		GuiButton(bounds, "");
		check(drawn() == flat, "cleared, a button draws flat again");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
