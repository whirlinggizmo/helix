package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.modules.RGui.*;
import helix.raylib.modules.RTextures.*;
#end

/** Holds raygui's skins, helix-raylib's own: parts of controls drawn from textures as nine-patches. Each is written here, and
	`helix.raylib.extras.GuiSkins` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RGuiSkins {
	#if !macro
	// Each control's skin for each part, by control * 4 + part, made at the first skin set.
	static var skins:Null<Map<Int, GuiSkin>>;

	/** Makes a skin from a texture and its patches, one for each state.

		@param texture  The texture the patches are cut from.
		@param normal  The patch drawn in `STATE_NORMAL`.
		@param focused  Optional. The patch drawn in `STATE_FOCUSED`; `normal` when omitted.
		@param pressed  Optional. The patch drawn in `STATE_PRESSED`; `focused` when omitted, or `normal` without it.
		@param disabled  Optional. The patch drawn in `STATE_DISABLED`; `normal` when omitted.
		@param tint  Optional. The color the patches are multiplied by; `WHITE` when omitted.
		@return  The skin. */
	static function GuiSkinFromTexture(texture:Texture2D, normal:NPatchInfo, ?focused:NPatchInfo, ?pressed:NPatchInfo, ?disabled:NPatchInfo,
			?tint:Color):GuiSkin {
		return {
			texture: texture,
			normal: normal,
			focused: focused,
			pressed: pressed,
			disabled: disabled,
			tint: tint == null ? WHITE : tint
		};
	}

	/** Makes a skin from a sheet of a control's states, cells of one size in raygui's order of states: normal, focused, pressed and
		disabled, from the top down, or from the left across when the sheet is one cell high. A sheet of fewer than four cells leaves the
		rest to their fallbacks (`GuiSkin`). Each cell is cut as a nine-patch by the same borders.

		@param texture  The sheet.
		@param cellWidth  A cell's width, in texels.
		@param cellHeight  A cell's height, in texels.
		@param left  The left border's width, in texels, kept unstretched.
		@param top  The top border's height.
		@param right  The right border's width.
		@param bottom  The bottom border's height.
		@return  The skin. */
	static function GuiSkinFromSheet(texture:Texture2D, cellWidth:Int, cellHeight:Int, left:Int, top:Int, right:Int, bottom:Int):GuiSkin {
		var down = texture.height >= 2 * cellHeight;
		var count = down ? Std.int(texture.height / cellHeight) : Std.int(texture.width / cellWidth);
		function cell(i:Int):Null<NPatchInfo>
			return i >= count ? null : new NPatchInfo(new Rectangle(down ? 0 : i * cellWidth, down ? i * cellHeight : 0, cellWidth, cellHeight), left, top,
				right, bottom, NPATCH_NINE_PATCH);
		return GuiSkinFromTexture(texture, cell(0), cell(1), cell(2), cell(3));
	}

	/** Sets the skin a part of a control is drawn with, in place of its style's border and base colors. It is read as each control
		draws, so a skin set before one call and put back after it changes that call's control alone.

		Set on `DEFAULT`, it is set on every control too, as raygui's `GuiSetStyle` sets `DEFAULT`'s base properties, so set it first and
		each control's own after. `DEFAULT`'s own `GUI_SKIN_BASE` is what `GuiPanel`, `GuiWindowBox` and `GuiScrollPanel` draw their body
		with.
		@param control  The control: `DEFAULT`, `BUTTON`, `SLIDER` and the rest of raygui's.
		@param part  `GUI_SKIN_BASE`, `GUI_SKIN_FILL`, `GUI_SKIN_HANDLE` or `GUI_SKIN_ITEM`.
		@param skin  The skin, or null to draw the part flat in its style's colors again. */
	static function GuiSetSkin(control:Int, part:Int, skin:Null<GuiSkin>):Void {
		if (skins == null) {
			skins = new Map();
			RGui.skinned = drawSkin;
		}
		var last = control == DEFAULT ? STATUSBAR : control;
		for (c in control...last + 1)
			if (skin == null)
				skins.remove(c * 4 + part);
			else
				skins.set(c * 4 + part, skin);
	}

	/** Returns the skin a part of a control is drawn with, for putting it back after a change.

		@param control  The control.
		@param part  The part.
		@return  The skin, or null when the part is drawn flat. */
	static function GuiGetSkin(control:Int, part:Int):Null<GuiSkin> {
		return skins == null ? null : skins.get(control * 4 + part);
	}

	/** Removes every skin, so every control is drawn flat in its style's colors again. Loading a style leaves skins as they are. */
	static function GuiClearSkins():Void {
		if (skins != null)
			skins.clear();
	}

	// A part of a control drawn from its skin, faded by the gui's alpha: false, drawing nothing, when it has none.
	static function drawSkin(control:Int, part:Int, state:Int, rec:Rectangle):Bool {
		var skin = skins.get(control * 4 + part);
		if (skin == null)
			return false;
		var patch = switch state {
			case STATE_FOCUSED: skin.focused;
			case STATE_PRESSED: skin.pressed != null ? skin.pressed : skin.focused;
			case STATE_DISABLED: skin.disabled;
			default: null;
		}
		DrawTextureNPatch(skin.texture, patch != null ? patch : skin.normal, rec, new Vector2(0, 0), 0, guiFade(skin.tint, guiAlpha));
		return true;
	}
	#end
}
