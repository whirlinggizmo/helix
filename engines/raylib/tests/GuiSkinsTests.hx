import haxe.io.Bytes;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.GuiSkins.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
import helix.raylib.modules.RGui;
import helix.raylib.modules.RGuiSkins;

/** Checks helix-raylib's skins for raygui (`helix.raylib.extras.GuiSkins`), on graphics that keep nothing: no hook until a skin is set, so
	a program setting none draws as raygui does; a skinned button drawing exactly the vertices `DrawTextureNPatch` draws for its state's
	patch, normal, focused, pressed (falling back to focused) and disabled (falling back to normal); a skin set on `DEFAULT` set on every
	control, a control's own after it kept; a sheet cut down and across; a skin put back after one call; a one-call skin used by the
	next call alone; the text offsets a sheet's lip and lift produce, and a base moving its control's text; icon textures laid out
	by their width; a button of images and its click mask; and `GuiClearSkins` drawing flat again. The controls are locked
	(`GuiLock`), so the state is the one `GuiSetState` sets, with no mouse. */
@:access(helix.raylib.internal.Frame)
@:access(helix.raylib.modules.RGui)
@:access(helix.raylib.modules.RGuiSkins)
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
		check(!RGui.drawSkin(BUTTON, GUI_SKIN_BASE, STATE_NORMAL, bounds, null, BLANK), "no skin drawn until one is set");
		GuiButton(bounds, "");
		var flat = drawn();
		check(flat.length > 0, "a flat button draws");

		// A skinned button draws its state's patch, as DrawTextureNPatch does.
		var skin = GuiSkinFromTexture(sheet, patch(0), patch(32), null, patch(96));
		GuiSetSkin(BUTTON, GUI_SKIN_BASE, skin);
		check(RGui.drawSkin(BUTTON, GUI_SKIN_BASE, STATE_NORMAL, bounds, null, BLANK), "the hook is set with the first skin");
		drawn();
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

		// A one-call skin: the next call uses it, the one after draws GuiSetSkin's again.
		GuiSetSkinOnce(BUTTON, GUI_SKIN_BASE, GuiSkinFromTexture(sheet, patch(64)));
		GuiButton(bounds, "");
		check(drawn() == once, "the next call uses the one-call skin");
		GuiButton(bounds, "");
		check(drawn() == back, "the call after draws GuiSetSkin's again");
		GuiSetSkinOnce(BUTTON, GUI_SKIN_BASE, null);
		GuiButton(bounds, "");
		check(drawn() == flat, "a null one-call skin draws that call flat");
		GuiButton(bounds, "");
		check(drawn() == back, "and the next call skinned again");

		// The text offsets from a sheet's lip and lift, and a base moving its control's text by its state's.
		var lipped = GuiSkinFromSheet(sheet, 64, 32, 8, 8, 8, 8, 4, 2);
		check(lipped.normalTextOffset.y == -2 && lipped.disabledTextOffset.y == -2 && lipped.pressedTextOffset.y == 2 && lipped.focusedTextOffset.y == -4,
			"the offsets from a lip of 4 and a lift of 2");
		check(GuiSkinFromSheet(sheet, 64, 32, 8, 8, 8, 8).pressedTextOffset.y == 0, "no lip, no offsets");
		GuiSetSkin(BUTTON, GUI_SKIN_BASE, lipped);
		RGui.drawSkin(BUTTON, GUI_SKIN_BASE, STATE_PRESSED, bounds, null, BLANK);
		check(RGui.textOffsetBounds == bounds && RGui.textOffsetY == 2, "a pressed base moves the text 2 down inside it");
		RGui.drawSkin(SLIDER, GUI_SKIN_BASE, STATE_NORMAL, bounds, null, BLANK);
		check(RGui.textOffsetBounds == null, "a base with no offset moves none");
		drawn();

		// An icon drawn from a texture is laid out by its width, raygui's icon by its own.
		var icon = LoadTextureFromImage(GenImageColor(24, 10, WHITE));
		GuiSetIconTexture(ICON_229, icon);
		check(RGui.iconWidth(ICON_229) == 24 && RGui.iconWidth(ICON_FILE) == 16, "an icon texture's width, raygui's icon's 16");
		GuiSetIconTexture(ICON_229, icon, new Rectangle(0, 0, 12, 10));
		check(RGui.iconWidth(ICON_229) == 12, "the source's width");
		GuiSetIconTexture(ICON_229, null);
		check(RGui.iconWidth(ICON_229) == 16, "raygui's icon again");

		// A button of images draws its state's texture over its bounds; a click mask's clear texels don't answer.
		var up = LoadTextureFromImage(GenImageColor(8, 8, WHITE)),
			off = LoadTextureFromImage(GenImageColor(8, 8, GRAY));
		check(GuiTextureButton(bounds, up, null, null, off) == 0, "a locked image button isn't clicked");
		var normalDrawn = drawn();
		GuiSetState(STATE_DISABLED);
		GuiTextureButton(bounds, up, null, null, off);
		GuiSetState(STATE_NORMAL);
		check(drawn() != normalDrawn, "a disabled image button draws its disabled texture");
		var mask = GenImageColor(2, 2, BLANK);
		ImageDrawPixel(mask, 1, 1, WHITE);
		check(!RGuiSkins.masked(mask, bounds, new Vector2(20, 25)), "a clear texel doesn't answer");
		check(RGuiSkins.masked(mask, bounds, new Vector2(150, 55)), "an opaque one does");
		check(RGuiSkins.masked(null, bounds, new Vector2(20, 25)), "no mask, the whole rectangle answers");

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
