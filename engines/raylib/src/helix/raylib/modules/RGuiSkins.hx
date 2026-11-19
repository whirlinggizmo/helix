package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.modules.RGui.*;
import helix.raylib.modules.RCore.*;
import helix.raylib.modules.RShapes.*;
import helix.raylib.modules.RTextures.*;
import helix.raylib.extras.GuiSkin;
import helix.raylib.modules.RTextureDraws;
#end

/** Provides helix-raylib's raygui skins, which draw parts of controls from textures as nine-patches.

	`helix.raylib.extras.GuiSkins` forwards to each member (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RGuiSkins {
	#if !macro
	// Each control's skin for each part, by control * 4 + part, made at the first skin set.
	static var skins:Null<Map<Int, GuiSkin>>;
	// The skins GuiSetSkinOnce set, by control * 4 + part, a null skin drawing the part flat; used by the next call of the control.
	static var onceSkins:Null<Map<Int, Null<GuiSkin>>>;
	// The once skins a call of their control has used, removed when its next call starts.
	static var onceTaken:Null<Map<Int, Bool>>;
	// The icons drawn from textures, by icon, with each one's source rectangle.
	static var iconTextures:Null<Map<Int, Texture2D>>;
	static var iconSources:Null<Map<Int, Rectangle>>;

	/** Returns a skin cut from a texture by one patch for each state. See `GuiSkinFromSheet` for cutting the patches from a sheet of equal cells.

		@param texture  The texture the patches are cut from.
		@param normal  The patch drawn in `STATE_NORMAL`, in any of raylib's layouts: `NPATCH_NINE_PATCH`, `NPATCH_THREE_PATCH_HORIZONTAL`
			for a bar with caps at its ends, or `NPATCH_THREE_PATCH_VERTICAL`.
		@param focused  Optional. The patch drawn in `STATE_FOCUSED`; `normal` when omitted.
		@param pressed  Optional. The patch drawn in `STATE_PRESSED`; `focused` when omitted, or `normal` without it.
		@param disabled  Optional. The patch drawn in `STATE_DISABLED`; `normal` when omitted.
		@param tint  Optional. The color the patches are multiplied by; `WHITE` when omitted.
		@return  The skin, its patches stretched. Set its `horizontalPatchMode` and `verticalPatchMode` to repeat them. */
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

	/** Returns a skin cut from a sheet of a control's states, one cell of one size each. See `GuiSkinFromTexture` for cutting a patch per state from one texture.

		The cells are in raygui's order of states: normal, focused, pressed, disabled.

		They run from the top down, or from the left across when the sheet is less than two cells high.

		A sheet of fewer than four cells leaves the rest to their fallbacks (`GuiSkin`).

		Each cell is cut as a nine-patch by the same borders.

		@param texture  The sheet.
		@param cellWidth  A cell's width, in texels.
		@param cellHeight  A cell's height, in texels.
		@param left  The left border's width, in texels, kept unstretched.
		@param top  The top border's height.
		@param right  The right border's width.
		@param bottom  The bottom border's height, a lip under the face included.
		@param lip  Optional. How many texels at the bottom of the normal, focused and disabled cells are a lip under a raised face,
			the pressed cell's face pushed down onto it; 0 when omitted. Sets the skin's text offsets so the text stays centered on
			the face: (0, -lip / 2) normal and disabled, (0, lip / 2) pressed.
		@param lift  Optional. How many texels higher the focused cell's face is than the normal cell's; 0 when omitted. The
			focused text offset is (0, -lip / 2 - lift).
		@return  The skin, its patches stretched. Set its `horizontalPatchMode` and `verticalPatchMode` to repeat them. */
	static function GuiSkinFromSheet(texture:Texture2D, cellWidth:Int, cellHeight:Int, left:Int, top:Int, right:Int, bottom:Int, ?lip:Int, ?lift:Int):GuiSkin {
		var down = texture.height >= 2 * cellHeight;
		var count = down ? Std.int(texture.height / cellHeight) : Std.int(texture.width / cellWidth);
		function cell(i:Int):Null<NPatchInfo>
			return i >= count ? null : new NPatchInfo(new Rectangle(down ? 0 : i * cellWidth, down ? i * cellHeight : 0, cellWidth, cellHeight), left, top,
				right, bottom, NPATCH_NINE_PATCH);
		var skin = GuiSkinFromTexture(texture, cell(0), cell(1), cell(2), cell(3));
		var half = (lip == null ? 0 : lip) / 2;
		skin.normalTextOffset.y = -half;
		skin.disabledTextOffset.y = -half;
		skin.pressedTextOffset.y = half;
		skin.focusedTextOffset.y = -half - (lift == null ? 0 : lift);
		return skin;
	}

	/** Sets the skin a part of a control is drawn with, in place of its style's border and base colors. See `GuiGetSkin` for reading the skin set, and `GuiClearSkins` for removing every one.

		A skin set on `DEFAULT` is set on every control too, as `GuiSetStyle` sets `DEFAULT`'s base properties. Set `DEFAULT`'s first and
		each control's own after.

		The skin is read as each control draws. See `GuiSetSkinOnce` for a skin for one call.

		`GuiPanel`, `GuiWindowBox` and `GuiScrollPanel` draw their body with `DEFAULT`'s own `GUI_SKIN_BASE`.

		@param control  The control: `DEFAULT`, `BUTTON`, `SLIDER` and the rest of raygui's.
		@param part  `GUI_SKIN_BASE`, `GUI_SKIN_FILL`, `GUI_SKIN_HANDLE` or `GUI_SKIN_ITEM`.
		@param skin  The skin, or null to draw the part flat in its style's colors again. */
	static function GuiSetSkin(control:Int, part:Int, skin:Null<GuiSkin>):Void {
		hook();
		var last = control == DEFAULT ? STATUSBAR : control;
		for (c in control...last + 1)
			if (skin == null)
				skins.remove(c * 4 + part);
			else
				skins.set(c * 4 + part, skin);
	}

	/** Sets the skin the next control call of a kind draws a part with, in place of the one `GuiSetSkin` set: one button in a
		different skin from the rest. The next call of that control uses it, drawn or disabled alike, and the call after it draws with
		`GuiSetSkin`'s again.

		@param control  The control: `BUTTON`, `SLIDER` and the rest of raygui's.
		@param part  `GUI_SKIN_BASE`, `GUI_SKIN_FILL`, `GUI_SKIN_HANDLE` or `GUI_SKIN_ITEM`.
		@param skin  The skin, drawn in full for that call (its patches, text offsets, fill mode and fill edge), or null to draw the
			part flat. */
	static function GuiSetSkinOnce(control:Int, part:Int, skin:Null<GuiSkin>):Void {
		hook();
		onceSkins.set(control * 4 + part, skin);
		onceTaken.remove(control * 4 + part);
	}

	/** Returns the skin a part of a control is drawn with, to put back after a change. See `GuiSetSkin` for setting it.

		@param control  The control.
		@param part  The part.
		@return  The skin, or null when the part is drawn flat. */
	static function GuiGetSkin(control:Int, part:Int):Null<GuiSkin> {
		return skins == null ? null : skins.get(control * 4 + part);
	}

	/** Draws a button of images, one for each state, as Godot's TextureButton, in place of `BUTTON`'s box and text: each state's
		texture drawn whole, stretched to `bounds`, faded by `GuiSetAlpha`'s alpha. See `GuiButton` for a button with text, and
		`GuiSetIconTexture` for an image beside its text.

		@param bounds  Where the button is drawn, and where it answers the pointer.
		@param normal  The texture drawn in `STATE_NORMAL`.
		@param focused  Optional. The texture drawn in `STATE_FOCUSED`; `normal` when omitted.
		@param pressed  Optional. The texture drawn in `STATE_PRESSED`; `focused` when omitted, or `normal` without it.
		@param disabled  Optional. The texture drawn in `STATE_DISABLED`; `normal` when omitted.
		@param clickMask  Optional. An image whose clear texels (alpha 0) don't answer the pointer, stretched to `bounds` as the
			textures are: often the normal texture's image, so a round button's corners ignore it. The whole rectangle answers when
			omitted.
		@return  1 when it's clicked, else 0, as `GuiButton`: always 0 in `STATE_DISABLED`. */
	static function GuiTextureButton(bounds:Rectangle, normal:Texture2D, ?focused:Texture2D, ?pressed:Texture2D, ?disabled:Texture2D, ?clickMask:Image):Int {
		var result = 0, state = guiState;
		if (state != STATE_DISABLED && !guiLocked && !guiControlExclusiveMode) {
			var mouse = GetMousePosition();
			if (CheckCollisionPointRec(mouse, bounds) && masked(clickMask, bounds, mouse)) {
				state = IsMouseButtonDown(MOUSE_BUTTON_LEFT) ? STATE_PRESSED : STATE_FOCUSED;
				if (IsMouseButtonReleased(MOUSE_BUTTON_LEFT))
					result = 1;
			}
		}
		var texture = switch state {
			case STATE_FOCUSED: focused;
			case STATE_PRESSED: pressed != null ? pressed : focused;
			case STATE_DISABLED: disabled;
			default: null;
		}
		if (texture == null)
			texture = normal;
		RTextures.quad(texture, 0, 0, texture.width, texture.height, bounds.x, bounds.y, bounds.width, bounds.height, 0, 0, 0, guiFade(WHITE, guiAlpha));
		return result;
	}

	/** Sets the texture drawn for one of raygui's icons in place of its pixels. Every control drawing that icon in its text
		(`GuiIconText(iconId, text)`) draws the texture there, laid out as raygui's icon is: the texture and the text after it aligned
		together as the control aligns its text, the text moved along by the texture's width. Draws raygui's
		own icon again when provided null. See `GuiDrawIcon` for an icon on its own.

		The texture is drawn at the source's size times `GuiSetIconScale`'s scale, centered on the text's line, in its own colors.
		It fades with the control: by `GuiSetAlpha`'s alpha, and to half in `STATE_DISABLED`.

		@param iconId  The icon (`ICON_*`). `ICON_229` to `ICON_255` are raygui's spare icons, blank.
		@param texture  The texture, or null for raygui's icon.
		@param source  Optional. The part of the texture drawn, in texels; the whole texture when omitted. */
	static function GuiSetIconTexture(iconId:Int, texture:Null<Texture2D>, ?source:Rectangle):Void {
		hook();
		if (texture == null) {
			iconTextures.remove(iconId);
			iconSources.remove(iconId);
		} else {
			iconTextures.set(iconId, texture);
			iconSources.set(iconId, source != null ? source : new Rectangle(0, 0, texture.width, texture.height));
		}
	}

	/** Removes every skin and icon texture. Every control is drawn flat in its style's colors again, with raygui's icons. See `GuiSetSkin` with null for
		removing one skin.

		Loading a style leaves the skins unchanged. */
	static function GuiClearSkins():Void {
		if (skins == null)
			return;
		skins.clear();
		onceSkins.clear();
		onceTaken.clear();
		iconTextures.clear();
		iconSources.clear();
	}

	// Makes the maps and puts the skins' draws in raygui's at the first skin, one-call skin or icon texture set.
	static function hook():Void {
		if (skins != null)
			return;
		skins = new Map();
		onceSkins = new Map();
		onceTaken = new Map();
		iconTextures = new Map();
		iconSources = new Map();
		RGui.drawSkin = drawSkin;
		RGui.iconWidth = iconWidth;
		RGui.drawIcon = drawIcon;
	}

	// Whether the point is on a clear texel of the mask stretched over bounds: true, answering, with no mask.
	static function masked(mask:Null<Image>, bounds:Rectangle, point:Vector2):Bool {
		if (mask == null || mask.width <= 0 || mask.height <= 0 || bounds.width <= 0 || bounds.height <= 0)
			return true;
		var x = Std.int((point.x - bounds.x) / bounds.width * mask.width),
			y = Std.int((point.y - bounds.y) / bounds.height * mask.height);
		if (x >= mask.width)
			x = mask.width - 1;
		if (y >= mask.height)
			y = mask.height - 1;
		return GetImageColor(mask, x, y).a > 0;
	}

	// The skin a part of a control draws with in this call: its one-call skin when one is set, else GuiSetSkin's. A call starts when the
	// control draws its base: the one-call skins its last call used are dropped, and those set since are applied.
	static function skinFor(control:Int, part:Int):Null<GuiSkin> {
		if (part == 0)
			for (p in 0...4) {
				var key = control * 4 + p;
				if (onceTaken.exists(key)) {
					onceSkins.remove(key);
					onceTaken.remove(key);
				} else if (onceSkins.exists(key))
					onceTaken.set(key, true);
			}
		var key = control * 4 + part;
		return onceSkins.exists(key) ? onceSkins.get(key) : skins.get(key);
	}

	// A skin's patch for a state.
	static function statePatch(skin:GuiSkin, state:Int):NPatchInfo {
		var patch = switch state {
			case STATE_FOCUSED: skin.focused;
			case STATE_PRESSED: skin.pressed != null ? skin.pressed : skin.focused;
			case STATE_DISABLED: skin.disabled;
			default: null;
		}
		return patch != null ? patch : skin.normal;
	}

	// A skin's text offset for a state.
	static function stateTextOffset(skin:GuiSkin, state:Int):Vector2 {
		return switch state {
			case STATE_FOCUSED: skin.focusedTextOffset;
			case STATE_PRESSED: skin.pressedTextOffset;
			case STATE_DISABLED: skin.disabledTextOffset;
			default: skin.normalTextOffset;
		}
	}

	// A control's fill, filled inside its whole track, from its fill skin in the skin's fill mode with its fill edge over it: false,
	// drawing nothing, when it has no fill skin.
	static function drawFill(control:Int, state:Int, filled:Rectangle, whole:Rectangle):Bool {
		var skin = skinFor(control, 1);
		if (skin == null)
			return false;
		if (skin.fillMode == GUI_SKIN_FILL_CLIPPED)
			RTextureDraws.drawPatch(skin.texture, statePatch(skin, state), whole, new Vector2(0, 0), 0, skin.horizontalPatchMode, skin.verticalPatchMode,
				guiFade(skin.tint, guiAlpha), new Rectangle(filled.x - whole.x, filled.y - whole.y, filled.width, filled.height));
		else
			RTextureDraws.drawPatch(skin.texture, statePatch(skin, state), filled, new Vector2(0, 0), 0, skin.horizontalPatchMode, skin.verticalPatchMode,
				guiFade(skin.tint, guiAlpha), null);
		var edge = skin.fillEdge;
		if (edge != null)
			RTextures.quad(edge, 0, 0, edge.width, edge.height, filled.x
				+ filled.width
				- edge.width / 2, filled.y
				+ filled.height / 2
				- edge.height / 2,
				edge.width, edge.height, 0, 0, 0, guiFade(WHITE, guiAlpha));
		return true;
	}

	// GuiSkins' GUI_SKIN_FILL_CLIPPED.
	static inline final GUI_SKIN_FILL_CLIPPED = 1;

	// A part of a control drawn from its skin, faded by the gui's alpha, a fill with its whole track drawn as drawFill: false, drawing
	// nothing, when it has none. A base sets where the control's text moves: by its skin's text offset for the state, inside rec.
	static function drawSkin(control:Int, part:Int, state:Int, rec:Rectangle, whole:Null<Rectangle>, color:Color):Bool {
		if (whole != null)
			return drawFill(control, state, rec, whole);
		var skin = skinFor(control, part);
		if (part == 0) {
			var offset = skin == null ? null : stateTextOffset(skin, state);
			RGui.textOffsetBounds = offset == null || (offset.x == 0 && offset.y == 0) ? null : rec;
			if (offset != null) {
				RGui.textOffsetX = offset.x;
				RGui.textOffsetY = offset.y;
			}
		}
		if (skin == null)
			return false;
		RTextureDraws.drawPatch(skin.texture, statePatch(skin, state), rec, new Vector2(0, 0), 0, skin.horizontalPatchMode, skin.verticalPatchMode,
			guiFade(skin.tint, guiAlpha), null);
		return true;
	}

	// An icon's width in a control's text: its texture's, scaled as raygui's icons are, or raygui's icon's.
	static function iconWidth(iconId:Int):Int {
		var source = iconSources.get(iconId);
		return source == null ? ICON_SIZE * guiIconScale : Std.int(source.width * guiIconScale);
	}

	// Draws an icon at x, centered down bounds: its texture, in its own colors, faded by the gui's alpha and to half when disabled,
	// or raygui's icon.
	static function drawIcon(iconId:Int, x:Int, bounds:Rectangle, tint:Color):Void {
		var texture = iconTextures.get(iconId);
		if (texture == null) {
			RGui.drawPixelIcon(iconId, x, bounds, tint);
			return;
		}
		var source = iconSources.get(iconId);
		var w = source.width * guiIconScale, h = source.height * guiIconScale;
		RTextures.quad(texture, source.x, source.y, source.width, source.height, x, Std.int(bounds.y + bounds.height / 2 - h / 2), w, h, 0, 0, 0,
			guiFade(WHITE, guiState == STATE_DISABLED ? guiAlpha / 2 : guiAlpha));
	}
	#end
}
