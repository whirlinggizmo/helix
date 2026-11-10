package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.modules.RCore.*;
import helix.raylib.modules.RShapes.*;
import helix.raylib.modules.RTextures.*;
import helix.raylib.modules.RText.*;
import helix.raylib.Raygui.*;
import helix.raylib.internal.GuiIcons;
import helix.raylib.modules.RGuiControls.*;
#end

/** Holds raygui's state, style, icons and tooltips, and the text and rectangle drawing its controls share, as raylib 5.5's raygui
	(4.5-dev, `raygui.h`) has them.

	`Raygui` forwards to each function here (`tools/gen_raylib.py`).

	A program that calls no raygui function links none of this state. */
@:noCompletion
@:allow(helix.raylib)
class RGui {
	#if !macro
	// ---- Gui state ----

	/** Enables the controls again after `GuiDisable`.

		A state other than disabled, set with `GuiSetState`, is unchanged. */
	static function GuiEnable():Void {
		if (guiState == STATE_DISABLED)
			guiState = STATE_NORMAL;
	}

	/** Disables the controls, so they draw disabled and take no input. See `GuiLock` for stopping the controls' input while they keep
		their look.

		A state other than normal, set with `GuiSetState`, is unchanged. */
	static function GuiDisable():Void {
		if (guiState == STATE_NORMAL)
			guiState = STATE_DISABLED;
	}

	/** Locks the controls until `GuiUnlock`, so they draw as they are and take no input. See `GuiDisable` for drawing the controls
		disabled. */
	static function GuiLock():Void {
		guiLocked = true;
	}

	/** Unlocks the controls after `GuiLock`. */
	static function GuiUnlock():Void {
		guiLocked = false;
	}

	/** Returns whether the controls are locked.

		@return  True between `GuiLock` and `GuiUnlock`. */
	static function GuiIsLocked():Bool {
		return guiLocked;
	}

	/** Sets how opaque the controls are drawn.

		@param alpha  0 for clear to 1 for opaque, clamped to that range. */
	static function GuiSetAlpha(alpha:Float):Void {
		if (alpha < 0)
			alpha = 0;
		else if (alpha > 1)
			alpha = 1;
		guiAlpha = alpha;
	}

	/** Sets the state every control is drawn in.

		With `STATE_NORMAL`, each control follows the mouse.

		Any other state is forced on every control.

		@param state  The state (`STATE_NORMAL`, `STATE_FOCUSED`, `STATE_PRESSED` or `STATE_DISABLED`). */
	static function GuiSetState(state:Int):Void {
		guiState = state;
	}

	/** Returns the state set with `GuiSetState`.

		@return  The state (`STATE_*`). */
	static function GuiGetState():Int {
		return guiState;
	}

	// ---- Font and style ----

	/** Sets the font the controls draw their text in.

		A font with no texture is ignored.

		Loads the default style first when no style is loaded yet, so a control's first use of the style keeps this font.

		@param font  The font. */
	static function GuiSetFont(font:Font):Void {
		if (textureId(font) > 0) {
			if (!guiStyleLoaded)
				GuiLoadStyleDefault();
			guiFont = font;
		}
	}

	/** Returns the font the controls draw their text in.

		Once the style is loaded, the font is raylib's default font or the one set with `GuiSetFont`.

		Before anything is drawn or styled, the font is an empty font.

		@return  The font. */
	static function GuiGetFont():Font {
		return guiFont == null ? new Font() : guiFont;
	}

	/** Sets one property of a control's style.

		Setting a base property of `DEFAULT` (below 16) sets that property for every control.

		Loads the default style first when no style is loaded yet.

		@param control  The control (`DEFAULT`, `LABEL`, `BUTTON` and the rest).
		@param property  The property (`BORDER_COLOR_NORMAL`, `TEXT_SIZE`, `SLIDER_WIDTH` and the rest).
		@param value  Its value: a color as 0xRRGGBBAA, a size in pixels, or one of the property's values. */
	static function GuiSetStyle(control:Int, property:Int, value:Int):Void {
		if (!guiStyleLoaded)
			GuiLoadStyleDefault();
		guiStyle[control * PROPERTIES + property] = value;
		if (control == 0 && property < MAX_PROPS_BASE)
			for (i in 1...MAX_CONTROLS)
				guiStyle[i * PROPERTIES + property] = value;
	}

	/** Returns one property of a control's style.

		Loads the default style first when no style is loaded yet.

		@param control  The control (`DEFAULT`, `LABEL`, `BUTTON` and the rest).
		@param property  The property (`BORDER_COLOR_NORMAL`, `TEXT_SIZE`, `SLIDER_WIDTH` and the rest).
		@return  Its value: a color as 0xRRGGBBAA, a size in pixels, or one of the property's values. */
	static function GuiGetStyle(control:Int, property:Int):Int {
		if (!guiStyleLoaded)
			GuiLoadStyleDefault();
		var at = control * PROPERTIES + property;
		return at >= 0 && at < guiStyle.length ? guiStyle[at] : 0;
	}

	/** Stands for raygui's style file load, which doesn't compile. See `GuiLoadStyleAsync` for loading
		a style file.

		@param fileName  The style file (.rgs). */
	@:unsupported("GuiLoadStyle: Synchronous loading is not supported. See GuiLoadStyleAsync(fileName:String, ?done:Void->Void, ?failed:String->Void)")
	static function GuiLoadStyle(fileName:String):Void {
		throw "GuiLoadStyle is unimplemented";
	}

	/** Loads raygui's default style, its light theme, over every control's colors, borders, text and sizes.

		Sets the font back to raylib's default font and unloads the font set before.

		Sets raylib's shapes to draw from the default font's white glyph, so text and shapes share one texture. */
	static function GuiLoadStyleDefault():Void {
		guiStyleLoaded = true;
		GuiSetStyle(DEFAULT, BORDER_COLOR_NORMAL, 0x838383ff);
		GuiSetStyle(DEFAULT, BASE_COLOR_NORMAL, 0xc9c9c9ff);
		GuiSetStyle(DEFAULT, TEXT_COLOR_NORMAL, 0x686868ff);
		GuiSetStyle(DEFAULT, BORDER_COLOR_FOCUSED, 0x5bb2d9ff);
		GuiSetStyle(DEFAULT, BASE_COLOR_FOCUSED, 0xc9effeff);
		GuiSetStyle(DEFAULT, TEXT_COLOR_FOCUSED, 0x6c9bbcff);
		GuiSetStyle(DEFAULT, BORDER_COLOR_PRESSED, 0x0492c7ff);
		GuiSetStyle(DEFAULT, BASE_COLOR_PRESSED, 0x97e8ffff);
		GuiSetStyle(DEFAULT, TEXT_COLOR_PRESSED, 0x368bafff);
		GuiSetStyle(DEFAULT, BORDER_COLOR_DISABLED, 0xb5c1c2ff);
		GuiSetStyle(DEFAULT, BASE_COLOR_DISABLED, 0xe6e9e9ff);
		GuiSetStyle(DEFAULT, TEXT_COLOR_DISABLED, 0xaeb7b8ff);
		GuiSetStyle(DEFAULT, BORDER_WIDTH, 1);
		GuiSetStyle(DEFAULT, TEXT_PADDING, 0);
		GuiSetStyle(DEFAULT, TEXT_ALIGNMENT, TEXT_ALIGN_CENTER);
		GuiSetStyle(DEFAULT, TEXT_SIZE, 10);
		GuiSetStyle(DEFAULT, TEXT_SPACING, 1);
		GuiSetStyle(DEFAULT, LINE_COLOR, 0x90abb5ff);
		GuiSetStyle(DEFAULT, BACKGROUND_COLOR, 0xf5f5f5ff);
		GuiSetStyle(DEFAULT, TEXT_LINE_SPACING, 15);
		GuiSetStyle(DEFAULT, TEXT_ALIGNMENT_VERTICAL, TEXT_ALIGN_MIDDLE);
		GuiSetStyle(LABEL, TEXT_ALIGNMENT, TEXT_ALIGN_LEFT);
		GuiSetStyle(BUTTON, BORDER_WIDTH, 2);
		GuiSetStyle(SLIDER, TEXT_PADDING, 4);
		GuiSetStyle(PROGRESSBAR, TEXT_PADDING, 4);
		GuiSetStyle(CHECKBOX, TEXT_PADDING, 4);
		GuiSetStyle(CHECKBOX, TEXT_ALIGNMENT, TEXT_ALIGN_RIGHT);
		GuiSetStyle(DROPDOWNBOX, TEXT_PADDING, 0);
		GuiSetStyle(DROPDOWNBOX, TEXT_ALIGNMENT, TEXT_ALIGN_CENTER);
		GuiSetStyle(TEXTBOX, TEXT_PADDING, 4);
		GuiSetStyle(TEXTBOX, TEXT_ALIGNMENT, TEXT_ALIGN_LEFT);
		GuiSetStyle(VALUEBOX, TEXT_PADDING, 0);
		GuiSetStyle(VALUEBOX, TEXT_ALIGNMENT, TEXT_ALIGN_LEFT);
		GuiSetStyle(SPINNER, TEXT_PADDING, 0);
		GuiSetStyle(SPINNER, TEXT_ALIGNMENT, TEXT_ALIGN_LEFT);
		GuiSetStyle(STATUSBAR, TEXT_PADDING, 8);
		GuiSetStyle(STATUSBAR, TEXT_ALIGNMENT, TEXT_ALIGN_LEFT);
		GuiSetStyle(TOGGLE, GROUP_PADDING, 2);
		GuiSetStyle(SLIDER, SLIDER_WIDTH, 16);
		GuiSetStyle(SLIDER, SLIDER_PADDING, 1);
		GuiSetStyle(PROGRESSBAR, PROGRESS_PADDING, 1);
		GuiSetStyle(CHECKBOX, CHECK_PADDING, 1);
		GuiSetStyle(COMBOBOX, COMBO_BUTTON_WIDTH, 32);
		GuiSetStyle(COMBOBOX, COMBO_BUTTON_SPACING, 2);
		GuiSetStyle(DROPDOWNBOX, ARROW_PADDING, 16);
		GuiSetStyle(DROPDOWNBOX, DROPDOWN_ITEMS_SPACING, 2);
		GuiSetStyle(SPINNER, SPIN_BUTTON_WIDTH, 24);
		GuiSetStyle(SPINNER, SPIN_BUTTON_SPACING, 2);
		GuiSetStyle(SCROLLBAR, BORDER_WIDTH, 0);
		GuiSetStyle(SCROLLBAR, ARROWS_VISIBLE, 0);
		GuiSetStyle(SCROLLBAR, ARROWS_SIZE, 6);
		GuiSetStyle(SCROLLBAR, SCROLL_SLIDER_PADDING, 0);
		GuiSetStyle(SCROLLBAR, SCROLL_SLIDER_SIZE, 16);
		GuiSetStyle(SCROLLBAR, SCROLL_PADDING, 0);
		GuiSetStyle(SCROLLBAR, SCROLL_SPEED, 12);
		GuiSetStyle(LISTVIEW, LIST_ITEMS_HEIGHT, 28);
		GuiSetStyle(LISTVIEW, LIST_ITEMS_SPACING, 2);
		GuiSetStyle(LISTVIEW, SCROLLBAR_WIDTH, 12);
		GuiSetStyle(LISTVIEW, SCROLLBAR_SIDE, SCROLLBAR_RIGHT_SIDE);
		GuiSetStyle(COLORPICKER, COLOR_SELECTOR_SIZE, 8);
		GuiSetStyle(COLORPICKER, HUEBAR_WIDTH, 16);
		GuiSetStyle(COLORPICKER, HUEBAR_PADDING, 8);
		GuiSetStyle(COLORPICKER, HUEBAR_SELECTOR_HEIGHT, 8);
		GuiSetStyle(COLORPICKER, HUEBAR_SELECTOR_OVERFLOW, 2);
		var fontDefault = GetFontDefault();
		if (textureId(guiFont) != textureId(fontDefault)) {
			if (textureId(guiFont) > 0)
				UnloadTexture(guiFont.texture);
			guiFont = fontDefault;
			// raylib's default font's glyph 95 is a white square: shapes drawn from it, a pixel in from its edges.
			var white = guiFont.recs[95];
			SetShapesTexture(guiFont.texture, new Rectangle(white.x + 1, white.y + 1, white.width - 2, white.height - 2));
		}
	}

	// ---- Tooltips ----

	/** Turns tooltips on, so a control the mouse is over draws the text set with `GuiSetTooltip` below it. */
	static function GuiEnableTooltip():Void {
		guiTooltip = true;
	}

	/** Turns tooltips off after `GuiEnableTooltip`. */
	static function GuiDisableTooltip():Void {
		guiTooltip = false;
	}

	/** Sets the tooltip the next controls show while tooltips are on, until the next call. See `GuiEnableTooltip` for turning
		tooltips on.

		@param tooltip  The text, or null for none. */
	static function GuiSetTooltip(tooltip:String):Void {
		guiTooltipPtr = tooltip;
	}

	// ---- Icons ----

	/** Returns a control's text with an icon before it, as raygui writes one.

		The icon is "#", the icon's number padded to three characters with a minus sign counting as one (`#012#`, `#-01#`), then "#".

		@param iconId  The icon (`ICON_*`).
		@param text  The text, or null for the icon alone.
		@return  The text, as "#012#text". */
	static function GuiIconText(iconId:Int, text:String):String {
		var digits = Std.string(iconId < 0 ? -iconId : iconId);
		while (digits.length < (iconId < 0 ? 2 : 3))
			digits = "0" + digits;
		var icon = "#" + (iconId < 0 ? "-" : "") + digits + "#";
		return text == null ? icon : icon + text;
	}

	/** Sets the size icons are drawn at in text, a whole multiple of their 16 pixels.

		@param scale  The scale, 1 or more; less is ignored. */
	static function GuiSetIconScale(scale:Int):Void {
		if (scale >= 1)
			guiIconScale = scale;
	}

	/** Returns the icons' bits, which a program may change.

		The bits are laid out as:

		- eight 32-bit words an icon, the icon's first at `ICON_*` times 8
		- two 16-pixel rows a word
		- bit 0 the leftmost pixel of the word's first row

		@return  The icons, 2048 words. */
	static function GuiGetIcons():Array<Int> {
		return icons();
	}

	/** Stands for raygui's icon file load, which doesn't compile. See `GuiLoadIconsAsync` for loading
		an icon file.

		@param fileName  The icon file (.rgi).
		@param loadIconsName  Whether the icons' names are read.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("GuiLoadIcons: Synchronous loading is not supported. See GuiLoadIconsAsync(fileName:String, loadIconsName:Bool, loaded:Array<String>->Void, ?failed:String->Void)")
	static function GuiLoadIcons(fileName:String, loadIconsName:Bool):Array<String> {
		throw "GuiLoadIcons is unimplemented";
	}

	/** Draws an icon, each of its pixels a square.

		Fades the icon by the alpha set with `GuiSetAlpha`.

		@param iconId  The icon (`ICON_*`).
		@param posX  Its left edge, in pixels.
		@param posY  Its top edge, in pixels.
		@param pixelSize  The size of each of its pixels.
		@param color  The color. */
	static function GuiDrawIcon(iconId:Int, posX:Int, posY:Int, pixelSize:Int, color:Color):Void {
		var bits = icons(), y = 0;
		for (i in 0...ICON_DATA_ELEMENTS) {
			var at = iconId * ICON_DATA_ELEMENTS + i;
			var word = at >= 0 && at < bits.length ? bits[at] : 0;
			for (k in 0...32) {
				if (word & (1 << k) != 0)
					drawRectangle(new Rectangle(posX + (k % ICON_SIZE) * pixelSize, posY + y * pixelSize, pixelSize, pixelSize), 0, BLANK, color);
				if (k == 15 || k == 31)
					y++;
			}
		}
	}

	// ---- State, as raygui keeps it ----
	static inline final MAX_CONTROLS = 16;
	static inline final MAX_PROPS_BASE = 16;
	static inline final MAX_PROPS_EXTENDED = 8;
	static inline final PROPERTIES = MAX_PROPS_BASE + MAX_PROPS_EXTENDED;
	static inline final ICON_SIZE = 16;
	static inline final ICON_MAX_ICONS = 256;
	static inline final ICON_MAX_NAME_LENGTH = 32;
	static inline final ICON_DATA_ELEMENTS = 8;
	static inline final ICON_TEXT_PADDING = 4;
	static inline final MAX_LINE_BUFFER_SIZE = 256;
	static inline final MAX_TEXT_LINES = 128;
	static inline final TEXTSPLIT_MAX_ITEMS = 128;
	static inline final TEXTSPLIT_MAX_TEXT_SIZE = 1024;
	// A property's color element: its border, base and text, each state's three in a row.
	static inline final BORDER = 0;
	static inline final BASE = 1;
	static inline final TEXT = 2;

	static var guiState = STATE_NORMAL;
	static var guiFont:Null<Font> = null;
	static var guiLocked = false;
	static var guiAlpha = 1.;
	static var guiIconScale = 1;
	static var guiTooltip = false;
	static var guiTooltipPtr:Null<String> = null;
	static var guiControlExclusiveMode = false;
	static var guiControlExclusiveRec = new Rectangle();
	static var guiStyle:Array<Int> = [for (_ in 0...MAX_CONTROLS * PROPERTIES) 0];
	static var guiStyleLoaded = false;
	static var guiIcons:Null<Array<Int>> = null;

	// The icons' bits, raygui's set made at the first use.
	static function icons():Array<Int> {
		if (guiIcons == null)
			guiIcons = GuiIcons.make();
		return guiIcons;
	}

	// A font's texture's id, 0 for none, as a C font of zeros has.
	static function textureId(font:Null<Font>):Int {
		return font == null || font.texture == null ? 0 : font.texture.id;
	}

	// C's integer division, toward zero.
	static inline function idiv(a:Int, b:Int):Int {
		return Std.int(a / b);
	}

	// ---- Drawing, as raygui's controls share it ----
	// A color faded by an alpha, as raygui's GuiFade: the color's own alpha times it.
	static function guiFade(color:Color, alpha:Float):Color {
		if (alpha < 0)
			alpha = 0;
		else if (alpha > 1)
			alpha = 1;
		return new Color(color.r, color.g, color.b, Std.int(color.a * alpha));
	}

	// A rectangle filled and bordered, as raygui's GuiDrawRectangle, faded by the gui's alpha.
	static function drawRectangle(rec:Rectangle, borderWidth:Int, borderColor:Color, color:Color):Void {
		var x = Std.int(rec.x),
			y = Std.int(rec.y),
			w = Std.int(rec.width),
			h = Std.int(rec.height);
		if (color.a > 0)
			DrawRectangle(x, y, w, h, guiFade(color, guiAlpha));
		if (borderWidth > 0) {
			var border = guiFade(borderColor, guiAlpha);
			DrawRectangle(x, y, w, borderWidth, border);
			DrawRectangle(x, y + borderWidth, borderWidth, h - 2 * borderWidth, border);
			DrawRectangle(x + w - borderWidth, y + borderWidth, borderWidth, h - 2 * borderWidth, border);
			DrawRectangle(x, y + h - borderWidth, w, borderWidth, border);
		}
	}

	// A control's text's bounds within its bounds, as raygui's GetTextBounds: in by its border and padding, the padding on the side its
	// alignment leaves.
	static function textBounds(control:Int, bounds:Rectangle):Rectangle {
		var border = GuiGetStyle(control, BORDER_WIDTH),
			padding = GuiGetStyle(control, TEXT_PADDING);
		var r = new Rectangle(bounds.x
			+ border, bounds.y
			+ border
			+ padding, bounds.width
			- 2 * border
			- 2 * padding,
			bounds.height
			- 2 * border
			- 2 * padding);
		if (GuiGetStyle(control, TEXT_ALIGNMENT) == TEXT_ALIGN_RIGHT)
			r.x -= padding;
		else
			r.x += padding;
		return r;
	}

	// Text as its UTF-8 bytes, which raygui reads; empty for null.
	static function bytes(text:Null<String>):Array<Int> {
		return RText.utf8(text);
	}

	// A byte of text, 0 past its end, as C's string ends.
	static inline function byteAt(b:Array<Int>, i:Int):Int {
		return i >= 0 && i < b.length ? b[i] : 0;
	}

	// raylib's GetCodepointNext at a byte of text.
	static function codepointNext(b:Array<Int>, at:Int, size:Array<Int>):Int {
		return RText.next(b, at, size);
	}

	// raylib's GetCodepoint at a byte of text.
	static function codepointAt(b:Array<Int>, at:Int, size:Array<Int>):Int {
		return RText.checked([for (k in 0...4) byteAt(b, at + k)], size);
	}

	// raylib's GetCodepointPrevious before a byte of text: the codepoint starting before it, its size in size.
	static function codepointPrevious(b:Array<Int>, at:Int, size:Array<Int>):Int {
		var p = at, inner = [0];
		size[0] = 0;
		do
			p-- while (byteAt(b, p) & 0x80 != 0 && byteAt(b, p) & 0xc0 == 0x80);
		var codepoint = codepointNext(b, p, inner);
		if (codepoint != 0)
			size[0] = inner[0];
		return codepoint;
	}

	// The width of a glyph of the gui's font, its advance or, with none, its rectangle's width, scaled.
	static function glyphWidth(codepoint:Int, scale:Float):Float {
		var index = GetGlyphIndex(guiFont, codepoint);
		var advance = guiFont.glyphs[index].advanceX;
		return advance == 0 ? guiFont.recs[index].width * scale : advance * scale;
	}

	// The width of text's first line, as raygui's GetTextWidth: an icon before it ("#12#") counted as an icon, at most 256 bytes.
	static function textWidth(b:Array<Int>, at:Int):Int {
		var width = 0., iconOffset = 0;
		if (byteAt(b, at) != 0) {
			if (byteAt(b, at) == "#".code) {
				var i = 1;
				while (i < 5 && byteAt(b, at + i) != 0) {
					if (byteAt(b, at + i) == "#".code) {
						iconOffset = i;
						break;
					}
					i++;
				}
			}
			at += iconOffset;
			var fontSize:Float = GuiGetStyle(DEFAULT, TEXT_SIZE);
			if (textureId(guiFont) > 0) {
				var size = 0;
				while (size < MAX_LINE_BUFFER_SIZE && byteAt(b, at + size) != 0 && byteAt(b, at + size) != "\n".code)
					size++;
				var scale = fontSize / guiFont.baseSize, codepointSize = [0], i = 0;
				while (i < size) {
					var codepoint = codepointNext(b, at + i, codepointSize);
					width += glyphWidth(codepoint, scale) + GuiGetStyle(DEFAULT, TEXT_SPACING);
					i += codepointSize[0];
				}
			}
			if (iconOffset > 0)
				width += ICON_SIZE + ICON_TEXT_PADDING;
		}
		return Std.int(width);
	}

	// The width of a String's first line, as raygui's GetTextWidth; 0 for null.
	static function stringWidth(text:Null<String>):Int {
		return text == null ? 0 : textWidth(bytes(text), 0);
	}

	// The icon at a line's start ("#12#"), as raygui's GetTextIcon: its number in icon[0], -1 for none, and where the text after it starts.
	static function textIcon(b:Array<Int>, at:Int, icon:Array<Int>):Int {
		icon[0] = -1;
		if (byteAt(b, at) == "#".code) {
			var digits = "", pos = 1;
			while (pos < 4 && byteAt(b, at + pos) >= "0".code && byteAt(b, at + pos) <= "9".code) {
				digits += String.fromCharCode(byteAt(b, at + pos));
				pos++;
			}
			if (byteAt(b, at + pos) == "#".code) {
				icon[0] = digits == "" ? 0 : Std.parseInt(digits);
				if (icon[0] >= 0)
					at += pos + 1;
			}
		}
		return at;
	}

	// The width of text up to its next space, as raygui's GetNextSpaceWidth: where that space is in nextSpace[0], left as it is when
	// there is none.
	static function nextSpaceWidth(b:Array<Int>, at:Int, nextSpace:Array<Int>):Float {
		var width = 0., size = [0], scale = GuiGetStyle(DEFAULT, TEXT_SIZE) / guiFont.baseSize, i = 0;
		while (byteAt(b, at + i) != 0) {
			if (byteAt(b, at + i) != " ".code) {
				var codepoint = codepointAt(b, at + i, size);
				width += glyphWidth(codepoint, scale) + GuiGetStyle(DEFAULT, TEXT_SPACING);
			} else {
				nextSpace[0] = i;
				break;
			}
			i++;
		}
		return width;
	}

	// Draws a String as raygui's GuiDrawText; nothing for null or empty text.
	static function drawText(text:Null<String>, bounds:Rectangle, alignment:Int, tint:Color):Void {
		if (text != null && text != "")
			drawTextBytes(bytes(text), 0, bounds, alignment, tint);
	}

	// Draws text in its bounds, as raygui's GuiDrawText: line by line, each aligned, the lines aligned vertically as a block, an icon
	// before a line ("#12#") drawn as an icon; text too wide for its bounds ends in "..." unless the style wraps it.
	static function drawTextBytes(b:Array<Int>, start:Int, bounds:Rectangle, alignment:Int, tint:Color):Void {
		if (byteAt(b, start) == 0)
			return;
		inline function pixelOffset(h:Float):Int
			return Std.int(h) % 2;
		// Its lines, at each '\n', as raygui's GetTextLines.
		var lines = [start], end = start;
		while (byteAt(b, end) != 0)
			end++;
		var i = start;
		while (i < end && lines.length < MAX_TEXT_LINES) {
			if (b[i] == "\n".code)
				lines.push(i + 1);
			i++;
		}
		var lineCount = lines.length;
		var alignmentVertical = GuiGetStyle(DEFAULT, TEXT_ALIGNMENT_VERTICAL);
		var wrapMode = GuiGetStyle(DEFAULT, TEXT_WRAP_MODE);
		var textSize = GuiGetStyle(DEFAULT, TEXT_SIZE);
		var totalHeight:Float = lineCount * textSize + idiv((lineCount - 1) * textSize, 2);
		var posOffsetY = 0.;
		var icon = [0], size = [0], nextSpace = [0];
		for (l in 0...lineCount) {
			var line = textIcon(b, lines[l], icon);
			var iconId = icon[0];
			var x = bounds.x, y = bounds.y, widthOffset = 0.;
			var textSizeX = textWidth(b, line);
			if (iconId >= 0) {
				textSizeX += ICON_SIZE * guiIconScale;
				if (byteAt(b, line) != 0)
					textSizeX += ICON_TEXT_PADDING;
			}
			switch alignment {
				case TEXT_ALIGN_LEFT:
					x = bounds.x;
				case TEXT_ALIGN_CENTER:
					x = f32(f32(bounds.x + f32(bounds.width / 2)) - idiv(textSizeX, 2));
				case TEXT_ALIGN_RIGHT:
					x = f32(f32(bounds.x + bounds.width) - textSizeX);
				default:
			}
			if (textSizeX > bounds.width && byteAt(b, line) != 0)
				x = bounds.x;
			switch alignmentVertical {
				case TEXT_ALIGN_TOP:
					y = bounds.y + posOffsetY;
				case TEXT_ALIGN_MIDDLE:
					y = f32(f32(f32(bounds.y + posOffsetY) + f32(bounds.height / 2)) - f32(totalHeight / 2)) + pixelOffset(bounds.height);
				case TEXT_ALIGN_BOTTOM:
					y = f32(f32(f32(bounds.y + posOffsetY) + bounds.height) - totalHeight) + pixelOffset(bounds.height);
				default:
			}
			x = Std.int(x);
			y = Std.int(y);
			if (iconId >= 0) {
				GuiDrawIcon(iconId, Std.int(x), Std.int(bounds.y + bounds.height / 2 - idiv(ICON_SIZE * guiIconScale, 2) + pixelOffset(bounds.height)),
					guiIconScale, tint);
				x += ICON_SIZE * guiIconScale + ICON_TEXT_PADDING;
				widthOffset = ICON_SIZE * guiIconScale + ICON_TEXT_PADDING;
			}
			var lineSize = 0;
			while (byteAt(b, line + lineSize) != 0 && byteAt(b, line + lineSize) != "\n".code && byteAt(b, line + lineSize) != "\r".code)
				lineSize++;
			var scale = textSize / guiFont.baseSize;
			var lastSpaceIndex = 0, tempWrapCharMode = false;
			var offsetY = 0, offsetX = 0., width = 0.;
			var ellipsisWidth = textWidth(bytes("..."), 0), overflow = false;
			var c = 0;
			while (c < lineSize) {
				var codepoint = codepointNext(b, line + c, size);
				var index = GetGlyphIndex(guiFont, codepoint);
				if (codepoint == 0x3f)
					size[0] = 1;
				width = glyphWidth(codepoint, scale);
				if (wrapMode == TEXT_WRAP_CHAR) {
					if (offsetX + width > bounds.width - widthOffset) {
						offsetX = 0;
						offsetY += GuiGetStyle(DEFAULT, TEXT_LINE_SPACING);
						if (tempWrapCharMode) {
							wrapMode = TEXT_WRAP_WORD;
							tempWrapCharMode = false;
						}
					}
				} else if (wrapMode == TEXT_WRAP_WORD) {
					if (codepoint == 32)
						lastSpaceIndex = c;
					nextSpace[0] = 0;
					var spaceWidth = nextSpaceWidth(b, line + c, nextSpace);
					nextSpace[0] = 0;
					var wordSize = nextSpaceWidth(b, line + lastSpaceIndex + 1, nextSpace);
					if (wordSize > bounds.width - widthOffset) {
						tempWrapCharMode = true;
						wrapMode = TEXT_WRAP_CHAR;
					} else if (offsetX + spaceWidth > bounds.width - widthOffset) {
						offsetX = 0;
						offsetY += GuiGetStyle(DEFAULT, TEXT_LINE_SPACING);
					}
				}
				if (codepoint == "\n".code)
					break;
				if (codepoint != " ".code && codepoint != "\t".code) {
					var fontSize:Float = GuiGetStyle(DEFAULT, TEXT_SIZE);
					if (wrapMode == TEXT_WRAP_NONE) {
						if (textSizeX > bounds.width) {
							if (offsetX <= bounds.width - width - widthOffset - ellipsisWidth)
								DrawTextCodepoint(guiFont, codepoint, new Vector2(x + offsetX, y + offsetY), fontSize, guiFade(tint, guiAlpha));
							else if (!overflow) {
								overflow = true;
								var j = 0;
								while (j < ellipsisWidth) {
									DrawTextCodepoint(guiFont, ".".code, new Vector2(x + offsetX + j, y + offsetY), fontSize, guiFade(tint, guiAlpha));
									j += idiv(ellipsisWidth, 3);
								}
							}
						} else
							DrawTextCodepoint(guiFont, codepoint, new Vector2(x + offsetX, y + offsetY), fontSize, guiFade(tint, guiAlpha));
					} else if (wrapMode == TEXT_WRAP_CHAR || wrapMode == TEXT_WRAP_WORD) {
						if (y + offsetY <= bounds.y + bounds.height - GuiGetStyle(DEFAULT, TEXT_SIZE))
							DrawTextCodepoint(guiFont, codepoint, new Vector2(x + offsetX, y + offsetY), fontSize, guiFade(tint, guiAlpha));
					}
				}
				var advance = guiFont.glyphs[index].advanceX;
				offsetX += (advance == 0 ? guiFont.recs[index].width * scale : advance * scale) + GuiGetStyle(DEFAULT, TEXT_SPACING);
				c += size[0];
			}
			if (wrapMode == TEXT_WRAP_NONE)
				posOffsetY += GuiGetStyle(DEFAULT, TEXT_LINE_SPACING);
			else if (wrapMode == TEXT_WRAP_CHAR || wrapMode == TEXT_WRAP_WORD)
				posOffsetY += offsetY + GuiGetStyle(DEFAULT, TEXT_LINE_SPACING);
		}
	}

	// A control's text split at each delimiter and '\n', as raygui's GuiTextSplit: at most 1024 bytes and 128 items; rows, when given,
	// receives each item's row, counted by the '\n's before it.
	static function textSplit(text:Null<String>, delimiter:Int, rows:Null<Array<Int>>):Array<String> {
		var b = bytes(text), items = [], start = 0;
		if (rows != null)
			rows[0] = 0;
		var i = 0;
		while (i < TEXTSPLIT_MAX_TEXT_SIZE) {
			var c = byteAt(b, i);
			if (c == 0)
				break;
			if (c == delimiter || c == "\n".code) {
				items.push(RText.decoded(b, start, i));
				start = i + 1;
				if (rows != null)
					rows[items.length] = c == "\n".code ? rows[items.length - 1] + 1 : rows[items.length - 1];
				if (items.length + 1 > TEXTSPLIT_MAX_ITEMS)
					break;
			}
			i++;
		}
		// The last item runs to the text's end, or is empty when the items ran out at a delimiter.
		items.push(start <= i ? RText.decoded(b, start, i < b.length ? i : b.length) : "");
		return items;
	}

	// A control's tooltip below it, as raygui's GuiTooltip, while tooltips are on and one is set.
	static function tooltip(controlRec:Rectangle):Void {
		if (!guiLocked && guiTooltip && guiTooltipPtr != null && !guiControlExclusiveMode) {
			var size = MeasureTextEx(GuiGetFont(), guiTooltipPtr, GuiGetStyle(DEFAULT, TEXT_SIZE), GuiGetStyle(DEFAULT, TEXT_SPACING));
			var x = controlRec.x;
			if (x + size.x + 16 > GetScreenWidth())
				x -= size.x + 16 - controlRec.width;
			var rec = new Rectangle(x, controlRec.y + controlRec.height + 4, size.x + 16, GuiGetStyle(DEFAULT, TEXT_SIZE) + 8.);
			GuiPanel(rec, null);
			var textPadding = GuiGetStyle(LABEL, TEXT_PADDING),
				textAlignment = GuiGetStyle(LABEL, TEXT_ALIGNMENT);
			GuiSetStyle(LABEL, TEXT_PADDING, 0);
			GuiSetStyle(LABEL, TEXT_ALIGNMENT, TEXT_ALIGN_CENTER);
			GuiLabel(new Rectangle(rec.x, rec.y, rec.width, rec.height), guiTooltipPtr);
			GuiSetStyle(LABEL, TEXT_ALIGNMENT, textAlignment);
			GuiSetStyle(LABEL, TEXT_PADDING, textPadding);
		}
	}

	// A normalized RGB color as HSV, as raygui's ConvertRGBtoHSV: hue in degrees, saturation and value 0 to 1.
	static function rgbToHsv(r:Float, g:Float, b:Float):Vector3 {
		var hsv = new Vector3();
		var min = r < g ? r : g;
		min = min < b ? min : b;
		var max = r > g ? r : g;
		max = max > b ? max : b;
		hsv.z = max;
		var delta = f32(max - min);
		if (delta < f32(0.00001))
			return hsv;
		if (max > 0)
			hsv.y = f32(delta / max);
		else
			return hsv;
		if (r >= max)
			hsv.x = f32((g - b) / delta);
		else if (g >= max)
			hsv.x = f32(2 + f32((b - r) / delta));
		else
			hsv.x = f32(4 + f32((r - g) / delta));
		hsv.x = f32(hsv.x * 60);
		if (hsv.x < 0)
			hsv.x = f32(hsv.x + 360);
		return hsv;
	}

	// An HSV color as normalized RGB, as raygui's ConvertHSVtoRGB.
	static function hsvToRgb(h:Float, s:Float, v:Float):Vector3 {
		if (s <= 0)
			return new Vector3(v, v, v);
		var hh = h;
		if (hh >= 360)
			hh = 0;
		hh = f32(hh / 60);
		var i = Std.int(hh);
		var ff = f32(hh - i);
		var p = f32(v * f32(1 - s)),
			q = f32(v * f32(1 - f32(s * ff))),
			t = f32(v * f32(1 - f32(s * f32(1 - ff))));
		return switch i {
			case 0: new Vector3(v, t, p);
			case 1: new Vector3(q, v, p);
			case 2: new Vector3(p, v, t);
			case 3: new Vector3(p, q, v);
			case 4: new Vector3(t, p, v);
			default: new Vector3(v, p, q);
		}
	}

	// A number rounded to a C float, as raygui computes colors.
	static inline function f32(x:Float):Float {
		return helix.raylib.internal.Pixels.f32(x);
	}

	// Whether two rectangles are the same, as raygui's CHECK_BOUNDS_ID tells a dragged control by its bounds.
	static function sameBounds(a:Rectangle, b:Rectangle):Bool {
		return a.x == b.x && a.y == b.y && a.width == b.width && a.height == b.height;
	}

	// The bytes of a style file, as raygui's GuiLoadStyleFromMemory reads a binary .rgs file: its properties, then its font, if it has
	// one, set as the gui's font. A file of another kind changes nothing.
	static function loadStyleFromMemory(data:haxe.io.Bytes):Void {
		if (data.length < 12 || data.getString(0, 4) != "rGS ")
			return;
		var version = data.getUInt16(4), propertyCount = data.getInt32(8), p = 12;
		for (_ in 0...propertyCount) {
			var controlId = data.getUInt16(p),
				propertyId = data.getUInt16(p + 2),
				value = data.getInt32(p + 4);
			p += 8;
			if (controlId == 0) {
				GuiSetStyle(0, propertyId, value);
				if (propertyId < MAX_PROPS_BASE)
					for (j in 1...MAX_CONTROLS)
						GuiSetStyle(j, propertyId, value);
			} else
				GuiSetStyle(controlId, propertyId, value);
		}
		if (p + 4 > data.length)
			return;
		var fontDataSize = data.getInt32(p);
		p += 4;
		if (fontDataSize <= 0)
			return;
		var font = new Font();
		font.baseSize = data.getInt32(p);
		font.glyphCount = data.getInt32(p + 4);
		p += 12;
		var white = new Rectangle(data.getFloat(p), data.getFloat(p + 4), data.getFloat(p + 8), data.getFloat(p + 12));
		p += 16;
		var imageSize = data.getInt32(p),
			imageCompressed = data.getInt32(p + 4);
		p += 8;
		var image = new Image(null, data.getInt32(p), data.getInt32(p + 4), 1, data.getInt32(p + 8));
		p += 12;
		if (imageCompressed > 0 && imageCompressed != imageSize) {
			var size = [0];
			image.data = DecompressData(data.sub(p, imageCompressed), imageCompressed, size);
			p += imageCompressed;
			if (size[0] != imageSize)
				helix.raylib.internal.Runtime.log(LOG_WARNING, "Uncompressed font atlas image data could be corrupted");
		} else {
			image.data = data.sub(p, imageSize);
			p += imageSize;
		}
		font.texture = LoadTextureFromImage(image);
		if (font.texture.id != 0) {
			var recsSize = font.glyphCount * 16, recsCompressed = 0;
			if (version >= 400) {
				recsCompressed = data.getInt32(p);
				p += 4;
			}
			var recs = data, at = p;
			if (recsCompressed > 0 && recsCompressed != recsSize) {
				recs = DecompressData(data.sub(p, recsCompressed), recsCompressed, [0]);
				at = 0;
				p += recsCompressed;
			} else
				p += recsSize;
			font.recs = [
				for (i in 0...font.glyphCount)
					new Rectangle(recs.getFloat(at + i * 16), recs.getFloat(at + i * 16 + 4), recs.getFloat(at + i * 16 + 8), recs.getFloat(at + i * 16 + 12))
			];
			var glyphsSize = font.glyphCount * 16, glyphsCompressed = 0;
			if (version >= 400) {
				glyphsCompressed = data.getInt32(p);
				p += 4;
			}
			var glyphs = data;
			at = p;
			if (glyphsCompressed > 0 && glyphsCompressed != glyphsSize) {
				glyphs = DecompressData(data.sub(p, glyphsCompressed), glyphsCompressed, [0]);
				at = 0;
			}
			font.glyphs = [
				for (i in 0...font.glyphCount) {
					var g = new GlyphInfo();
					g.value = glyphs.getInt32(at + i * 16);
					g.offsetX = glyphs.getInt32(at + i * 16 + 4);
					g.offsetY = glyphs.getInt32(at + i * 16 + 8);
					g.advanceX = glyphs.getInt32(at + i * 16 + 12);
					g.image = new Image();
					g;
				}
			];
		} else
			font = GetFontDefault();
		GuiSetFont(font);
		if (white.x > 0 && white.y > 0 && white.width > 0 && white.height > 0)
			SetShapesTexture(font.texture, white);
	}
	#end
}
