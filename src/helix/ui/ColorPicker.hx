package helix.ui;

import helix.render2d.Node2D;
import helix.render2d.Shape2D;

/** A color, 0xRRGGBBAA, chosen as hue, saturation and brightness (HSV's value): a square of saturation (left to right) and brightness (bottom
	to top) in the hue, a bar of hue beside it (red at both ends, the hue rising upward), with alpha a bar of alpha (opaque at the top), a
	swatch of the color (its right half over a checkerboard, as its alpha shows it) and a field of hex under the swatch (hexField, a TextField
	of its own). The pointer drags in the square or a bar, the part it went down on, wherever it moves after. With focus, Enter, Space or a
	pad's South steps through the parts the arrows and the D-pad drive: the square (Left and Right saturation, Up and Down brightness), the
	hue bar, the alpha bar (Up and Right raise, Down and Left lower) and none, when they move focus again; each step a twentieth of the way.
	The part they drive has its mark in the theme's focus color. The field takes RRGGBBAA or RRGGBB (alpha 0xff), with or without a leading #,
	in either case: the color follows it as typed, text naming no color is marked invalid (TextField.invalid) and changes nothing, and once the
	field loses focus it shows the color again. Its hue (and saturation) are kept where the color doesn't say them: dragging through grey or
	black doesn't lose the hue. Ask color, and changed once a frame. */
class ColorPicker extends Widget {
	// The parts the pointer or the keys work in.
	static inline var NONE = 0;
	static inline var SQUARE = 1;
	static inline var HUE = 2;
	static inline var ALPHA = 3;
	// Held on nothing it drags (a gap, the swatch).
	static inline var ELSEWHERE = -1;
	// A key's step, as a fraction of the way.
	static inline var STEP = 1 / 20;

	var face:Shape2D;
	var squareHue:Shape2D;
	var whiteRamp:Shape2D;
	var blackRamp:Shape2D;
	var hueBase:Shape2D;
	var hueBands:Array<Shape2D> = [];
	var alphaBase:Shape2D;
	var alphaChecks = new Node2D();
	var alphaChecksPool:Array<Shape2D> = [];
	var alphaRamp:Shape2D;
	var swatchSolid:Shape2D;
	var swatchBase:Shape2D;
	var swatchChecks = new Node2D();
	var swatchChecksPool:Array<Shape2D> = [];
	var swatchAlpha:Shape2D;
	var squareShadow:Shape2D;
	var squareMark:Shape2D;
	var hueShadow:Shape2D;
	var hueMark:Shape2D;
	var alphaShadow:Shape2D;
	var alphaMark:Shape2D;
	var squareBox:Box;
	var hueBox:Box;
	var alphaBox:Null<Box>;
	var swatchBox:Box;
	var side:Box;
	var hasAlpha:Bool;
	var h = 0.;
	var s = 0.;
	var v = 0.;
	var a = 1.;
	var dragging = NONE;
	var editing = NONE;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, color:Int, alpha:Bool) {
		super(ui, name);
		hasAlpha = alpha;
		var theme = ui.theme,
			length = theme.widgetHeight * 4,
			bar = theme.widgetHeight / 2;
		face = rectangle(0);
		face.pickable = true;
		squareHue = rectangle(0xff0000ff);
		whiteRamp = rectangle(0xffffffff);
		whiteRamp.shading = Across;
		whiteRamp.endColor = 0xffffff00;
		blackRamp = rectangle(0x00000000);
		blackRamp.shading = Down;
		blackRamp.endColor = 0x000000ff;
		hueBase = rectangle(0);
		for (n in [face, squareHue, whiteRamp, blackRamp, hueBase])
			root.addChild(n);
		// Top to bottom: hue 1 (red) through magenta, blue, cyan, green and yellow to hue 0 (red).
		for (k in 0...6) {
			var band = rectangle(fromHsv((6 - k) / 6, 1, 1));
			band.shading = Down;
			band.endColor = fromHsv((5 - k) / 6, 1, 1);
			hueBands.push(band);
			root.addChild(band);
		}
		alphaBase = rectangle(0xccccccff);
		alphaRamp = rectangle(0);
		alphaRamp.shading = Down;
		swatchSolid = rectangle(0);
		swatchBase = rectangle(0xccccccff);
		swatchAlpha = rectangle(0);
		for (n in [
			alphaBase,
			alphaChecks,
			alphaRamp,
			swatchSolid,
			swatchBase,
			swatchChecks,
			swatchAlpha
		])
			root.addChild(n);
		alphaBase.visible = alphaChecks.enabled = alphaRamp.visible = hasAlpha;
		// The marks: white over a dark shadow, so they show on any color.
		squareShadow = mark(Shape2D.circle(6, 0x00000090), 4);
		squareMark = mark(Shape2D.circle(6, 0xffffffff), 2);
		hueShadow = mark(Shape2D.rectangle(bar + 6, 6, 0x00000090), 4);
		hueMark = mark(Shape2D.rectangle(bar + 6, 6, 0xffffffff), 2);
		alphaShadow = mark(Shape2D.rectangle(bar + 6, 6, 0x00000090), 4);
		alphaMark = mark(Shape2D.rectangle(bar + 6, 6, 0xffffffff), 2);
		alphaShadow.visible = alphaMark.visible = hasAlpha;
		// A row: the square, the hue bar, the alpha bar, then a column of the swatch and the field (attach).
		squareBox = Box.of(squareHue);
		squareBox.setSizing(Fixed(length), Fixed(length));
		hueBox = Box.of(hueBase);
		hueBox.setSizing(Fixed(bar), Fixed(length));
		var row = Box.row();
		row.gap = theme.gap * 2;
		row.setAnchor(Stretch, Start);
		row.add(squareBox);
		row.add(hueBox);
		if (hasAlpha) {
			alphaBox = Box.of(alphaBase);
			alphaBox.setSizing(Fixed(bar), Fixed(length));
			row.add(alphaBox);
		}
		side = Box.column();
		side.gap = theme.gap;
		side.setSizing(Grow(1), Fit);
		swatchBox = Box.of(swatchSolid);
		swatchBox.setSizing(Grow(1), Fixed(theme.widgetHeight));
		side.add(swatchBox);
		row.add(side);
		box = Box.stack(face);
		box.setSizing(Grow(1), Fit);
		box.add(row);
		this.color = color;
	}

	// A rectangle of the widget, its top-left at its position, not picked (the face is what the pointer uses).
	function rectangle(color:Int):Shape2D {
		var shape = Shape2D.rectangle(1, 1, color);
		shape.setPivot(0, 0);
		shape.pickable = false;
		return shape;
	}

	// A mark outlined width wide, centered on its position, over the parts.
	function mark(shape:Shape2D, width:Float):Shape2D {
		shape.setPivot(.5, .5);
		shape.outline = width;
		shape.pickable = false;
		root.addChild(shape);
		return shape;
	}

	// The hex field: its box under the swatch, its nodes with the picker's (hidden with it), taken out with it.

	@:allow(helix.ui.Ui)
	function attach(field:TextField):Void {
		hexField = field;
		parts.push(field);
		field.root.parent = null;
		root.addChild(field.root);
		side.add(field.box);
	}

	/** Its hex field: the color as RRGGBBAA (RRGGBB without alpha), typed in. */
	public var hexField(default, null):TextField;

	/** Its color, 0xRRGGBBAA. Assigning one keeps the hue where the color doesn't say it (a grey, black), and the saturation where it's black;
		without alpha, the alpha is 0xff whatever is assigned. */
	public var color(get, set):Int;

	function get_color():Int
		return fromHsv(h, s, v, Math.round(a * 255));

	function set_color(value:Int):Int {
		if (!hasAlpha)
			value = value | 0xff;
		// The color it shows already: nothing to work out (hue 1 and 0 are both red).
		if (value == get_color())
			return value;
		var r = (value >>> 24) / 255,
			g = ((value >>> 16) & 255) / 255,
			b = ((value >>> 8) & 255) / 255;
		var max = Math.max(r, Math.max(g, b)), min = Math.min(r, Math.min(g, b)), d = max - min;
		a = (value & 255) / 255;
		v = max;
		if (max > 0)
			s = d / max;
		if (d > 0) {
			var sixths = max == r ? (g - b) / d : max == g ? (b - r) / d + 2 : (r - g) / d + 4;
			h = (sixths < 0 ? sixths + 6 : sixths) / 6;
		}
		return value;
	}

	/** Its hue, 0 to 1 around (red at 0 and 1, then yellow, green, cyan, blue and magenta at sixths); kept through greys and black. Clamped to 0
		to 1. */
	public var hue(get, set):Float;

	function get_hue():Float
		return h;

	function set_hue(value:Float):Float {
		h = clamp(value);
		return h;
	}

	/** Its saturation, 0 (grey) to 1 (the full hue); kept through black. Clamped to 0 to 1. */
	public var saturation(get, set):Float;

	function get_saturation():Float
		return s;

	function set_saturation(value:Float):Float {
		s = clamp(value);
		return s;
	}

	/** Its brightness (HSV's value), 0 (black) to 1. Clamped to 0 to 1. */
	public var brightness(get, set):Float;

	function get_brightness():Float
		return v;

	function set_brightness(value:Float):Float {
		v = clamp(value);
		return v;
	}

	/** Whether its color changed this frame: dragged, nudged by keys or typed. */
	public var changed(default, null):Bool = false;

	/** The color 0xRRGGBBAA of hue (0 to 1 around, red at both ends), saturation and brightness (0 to 1 each; out of range clamped) and
		alpha (0 to 255), each channel rounded to the nearest of 255. */
	public static function fromHsv(hue:Float, saturation:Float, brightness:Float, alpha = 0xff):Int {
		hue = clamp(hue);
		saturation = clamp(saturation);
		brightness = clamp(brightness);
		alpha = alpha < 0 ? 0 : alpha > 255 ? 255 : alpha;
		return (channel(5, hue, saturation,
			brightness) << 24) | (channel(3, hue, saturation, brightness) << 16) | (channel(1, hue, saturation, brightness) << 8) | alpha;
	}

	// One channel of an HSV color, 0 to 255: n 5 for red, 3 for green, 1 for blue.
	static function channel(n:Int, hue:Float, saturation:Float, brightness:Float):Int {
		var k = (n + hue * 6) % 6, f = Math.min(k, 4 - k);
		f = f < 0 ? 0 : f > 1 ? 1 : f;
		return Math.round((brightness - brightness * saturation * f) * 255);
	}

	/** The color text names, 0xRRGGBBAA: RRGGBBAA, or RRGGBB meaning alpha 0xff, hex digits in either case, with or without a leading # and
		with spaces around. Null for anything else. */
	public static function parseHex(text:String):Null<Int> {
		text = StringTools.trim(text);
		if (StringTools.startsWith(text, "#"))
			text = text.substr(1);
		if (text.length != 6 && text.length != 8)
			return null;
		var value = 0;
		for (i in 0...text.length) {
			var c = text.charCodeAt(i);
			var digit = c >= "0".code
				&& c <= "9".code ? c - "0".code : c >= "a".code
					&& c <= "f".code ? c - "a".code + 10 : c >= "A".code && c <= "F".code ? c - "A".code + 10 : -1;
			if (digit < 0)
				return null;
			value = (value << 4) | digit;
		}
		return text.length == 6 ? (value << 8) | 0xff : value;
	}

	/** color as lowercase hex, RRGGBBAA, or RRGGBB without alpha. */
	public static function formatHex(color:Int, alpha:Bool):String
		return alpha ? StringTools.hex(color, 8).toLowerCase() : StringTools.hex(color >>> 8, 6).toLowerCase();

	static function clamp(value:Float):Float
		return value > 0 ? (value < 1 ? value : 1) : 0;

	override function get_focusable():Bool
		return true;

	override function target():Null<Node2D>
		return face;

	// The arrows are its own while a part is being driven by them.

	override function takesSideways():Bool
		return editing != NONE;

	override function takesUpDown():Bool
		return editing != NONE;

	// The part under world point x, y (as the last draw placed the parts), or ELSEWHERE.
	function partAt(x:Float, y:Float):Int {
		for (part in [SQUARE, HUE, ALPHA]) {
			var base = part == SQUARE ? squareHue : part == HUE ? hueBase : alphaBase;
			if (part == ALPHA && !hasAlpha)
				continue;
			var lx = base.toLocalX(x, y), ly = base.toLocalY(x, y);
			if (lx >= 0 && ly >= 0 && lx <= base.width && ly <= base.height)
				return part;
		}
		return ELSEWHERE;
	}

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, stepX:Int, stepY:Int):Void {
		var input = ui.input, camera = ui.camera, was = get_color();
		if (!focused)
			editing = NONE;
		// The pointer: the part it went down on follows it while it's held.
		if (enabled && held) {
			var wx = camera.screenToWorldX(input.pointerX),
				wy = camera.screenToWorldY(input.pointerY);
			if (dragging == NONE) {
				dragging = partAt(wx, wy);
				if (dragging != ELSEWHERE)
					editing = dragging;
			}
			switch dragging {
				case SQUARE:
					s = clamp(squareHue.toLocalX(wx, wy) / squareHue.width);
					v = clamp(1 - squareHue.toLocalY(wx, wy) / squareHue.height);
				case HUE:
					h = clamp(1 - hueBase.toLocalY(wx, wy) / hueBase.height);
				case ALPHA:
					a = clamp(1 - alphaBase.toLocalY(wx, wy) / alphaBase.height);
				default:
			}
		} else
			dragging = NONE;
		// Keys and the D-pad: activating steps through the parts, the arrows drive the one stepped to.
		if (enabled && activated)
			editing = editing == SQUARE ? HUE : editing == HUE ? (hasAlpha ? ALPHA : NONE) : editing == ALPHA ? NONE : SQUARE;
		if (enabled && (stepX != 0 || stepY != 0))
			switch editing {
				case SQUARE:
					s = clamp(s + stepX * STEP);
					v = clamp(v - stepY * STEP);
				case HUE:
					h = clamp(h + (stepX - stepY) * STEP);
				case ALPHA:
					a = clamp(a + (stepX - stepY) * STEP);
				default:
			}
		// The field: what was typed in it last frame, when it names a color; shown again as the color once it's left.
		if (hexField != null) {
			hexField.enabled = enabled;
			if (hexField.changed) {
				var typed = parseHex(hexField.text);
				hexField.invalid = typed == null;
				if (typed != null)
					set_color(typed);
			}
			if (ui.focused != hexField) {
				var hex = formatHex(get_color(), hasAlpha);
				if (hexField.text != hex)
					hexField.text = hex;
				hexField.invalid = false;
			}
		}
		var color = get_color();
		changed = color != was;
		draw(color, focused);
	}

	// The parts where the layout last placed them, in the color now.
	function draw(color:Int, focused:Bool):Void {
		var theme = ui.theme,
			x = squareBox.x,
			y = squareBox.y,
			w = squareBox.width,
			height = squareBox.height;
		squareHue.color = fromHsv(h, 1, 1);
		for (n in [whiteRamp, blackRamp]) {
			n.setPosition(x, y);
			n.setSize(w, height);
		}
		var hx = hueBox.x, hy = hueBox.y, hw = hueBox.width, hh = hueBox.height;
		for (k in 0...hueBands.length) {
			hueBands[k].setPosition(hx, hy + hh * k / 6);
			hueBands[k].setSize(hw, hh / 6);
		}
		var opaque = color | 0xff, clear = color & 0xffffff00;
		if (alphaBox != null) {
			alphaRamp.setPosition(alphaBox.x, alphaBox.y);
			alphaRamp.setSize(alphaBox.width, alphaBox.height);
			alphaRamp.color = opaque;
			alphaRamp.endColor = clear;
			checker(alphaChecks, alphaChecksPool, alphaBox.x, alphaBox.y, alphaBox.width, alphaBox.height, hw / 2);
		}
		// The swatch: the color opaque, and with alpha, its right half as its alpha shows it over a checkerboard.
		var sx = swatchBox.x,
			sy = swatchBox.y,
			sw = swatchBox.width,
			sh = swatchBox.height,
			half = hasAlpha ? sw / 2 : sw;
		swatchSolid.setSize(half, sh);
		swatchSolid.color = opaque;
		swatchBase.visible = swatchAlpha.visible = swatchChecks.enabled = hasAlpha;
		if (hasAlpha) {
			swatchBase.setPosition(sx + half, sy);
			swatchBase.setSize(sw - half, sh);
			swatchAlpha.setPosition(sx + half, sy);
			swatchAlpha.setSize(sw - half, sh);
			swatchAlpha.color = color;
			checker(swatchChecks, swatchChecksPool, sx + half, sy, sw - half, sh, hw / 2);
		}
		// The marks, the one the keys drive in the focus color, dimmed when it can't be used.
		var markColor = enabled ? 0xffffffff : theme.disabledTextColor;
		squareShadow.setPosition(x + s * w, y + (1 - v) * height);
		squareMark.setPosition(x + s * w, y + (1 - v) * height);
		squareMark.color = focused && editing == SQUARE ? theme.focusColor : markColor;
		hueShadow.setPosition(hx + hw / 2, hy + (1 - h) * hh);
		hueMark.setPosition(hx + hw / 2, hy + (1 - h) * hh);
		hueMark.color = focused && editing == HUE ? theme.focusColor : markColor;
		if (alphaBox != null) {
			alphaShadow.setPosition(alphaBox.x + alphaBox.width / 2, alphaBox.y + (1 - a) * alphaBox.height);
			alphaMark.setPosition(alphaBox.x + alphaBox.width / 2, alphaBox.y + (1 - a) * alphaBox.height);
			alphaMark.color = focused && editing == ALPHA ? theme.focusColor : markColor;
		}
	}

	// The dark squares of a checkerboard of cells cell wide over x, y, w x h (the light ones the base under them), from pool under group: those
	// past what it needs hidden, the pool grown as needed, the last row and column cut to the area.
	function checker(group:Node2D, pool:Array<Shape2D>, x:Float, y:Float, w:Float, h:Float, cell:Float):Void {
		var used = 0;
		if (cell > 0) {
			var columns = Math.ceil(w / cell), rows = Math.ceil(h / cell);
			for (row in 0...rows)
				for (column in 0...columns) {
					if ((row + column) % 2 == 0)
						continue;
					if (used == pool.length) {
						var square = rectangle(0x888888ff);
						pool.push(square);
						group.addChild(square);
					}
					var square = pool[used++],
						cx = column * cell,
						cy = row * cell;
					square.visible = true;
					square.setPosition(x + cx, y + cy);
					square.setSize(Math.min(cell, w - cx), Math.min(cell, h - cy));
				}
		}
		for (i in used...pool.length)
			pool[i].visible = false;
	}
}
