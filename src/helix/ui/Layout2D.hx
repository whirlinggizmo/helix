package helix.ui;

import helix.render2d.Font2D;
import helix.render2d.Node2D;
import helix.render2d.Shape2D;
import helix.render2d.Sprite2D;
import helix.render2d.Text2D;

/** How a layout's width or height is decided. */
enum Sizing {
	/** This many units. */
	Fixed(units:Float);

	/** Its content's: its children's (and gaps and padding), or its node's own (a text's measured width, a sprite's or rectangle's size). */
	Fit;

	/** A share of the room its row or column has left, by weight against its siblings' (across, the whole room). */
	Grow(weight:Float);

	/** This fraction of its parent's room inside the padding (0 to 1). */
	Percent(fraction:Float);
}

/** Where layouts go in the room they have, along an axis. */
enum Alignment {
	/** At its start: the left, or the top. */
	Start;

	/** In its middle. */
	Center;

	/** At its end: the right, or the bottom. */
	End;

	/** Across a row or column only: filling it. */
	Stretch;
}

/** How a layout lays its children out. */
enum Layout2DDirection {
	/** Left to right. */
	Row;

	/** Top to bottom. */
	Column;

	/** Over one another, each placed by its own alignment in the layout (anchored to an edge, a corner or the middle). */
	Stack;
}

/** A rectangle of a 2D layout: rows, columns and stacks of them, each sized fixed, fitted to its content, growing into the room left or as a
	share of its parent, with padding, gaps and alignment (Clay's model, in Haxe). A layout may place a node: arrange() writes its position (by
	its pivot) and, for a sprite or rectangle, its size, once a frame. Layouts only lay out; what's drawn is the nodes'. A widget's layout takes its
	sizing, padding and gap from the theme (Theme) until the game sets that value itself (setSizing, widthSizing, heightSizing, setPadding,
	gap): from then on the game's value is kept whatever the theme becomes, even one equal to the theme's, as an inline style wins over a
	stylesheet. Each value is decided apart: a game sizing a button's width leaves its height the theme's. */
class Layout2D {
	var direction:Layout2DDirection;
	var childLayouts:Array<Layout2D> = [];
	var widthRule:Sizing = Fit;
	var heightRule:Sizing = Fit;
	var selfX:Null<Alignment>;
	var selfY:Null<Alignment>;
	var offsetX = 0.;
	var offsetY = 0.;
	// Which of its values a game set (setSizing, widthSizing, heightSizing, setPadding, gap): the theme's (themeSizing, themePadding,
	// themeGap) never replace those.
	var gameWidth = false;
	var gameHeight = false;
	var gamePadding = false;
	var gameGap = false;
	var fitWidth = 0.;
	var fitHeight = 0.;
	var w = 0.;
	var h = 0.;

	/** A layout placing its children direction's way, placing node (or none). */
	public function new(direction:Layout2DDirection, ?node:Node2D) {
		this.direction = direction;
		this.node = node;
	}

	/** A row, left to right. */
	public static function row(?node:Node2D):Layout2D
		return new Layout2D(Row, node);

	/** A column, top to bottom. */
	public static function column(?node:Node2D):Layout2D
		return new Layout2D(Column, node);

	/** A stack, its children over one another, each by its own alignment. */
	public static function stack(?node:Node2D):Layout2D
		return new Layout2D(Stack, node);

	/** A layout holding node alone, sized to it unless sized otherwise. */
	public static function of(node:Node2D):Layout2D
		return new Layout2D(Stack, node);

	/** Adds child as its last. */
	public function add(child:Layout2D):Void
		childLayouts.push(child);

	/** Takes child out. */
	public function remove(child:Layout2D):Bool
		return childLayouts.remove(child);

	/** Its children, in order. */
	public var children(get, never):Array<Layout2D>;

	function get_children():Array<Layout2D>
		return childLayouts.copy();

	/** The node it places, or null. */
	public var node(default, null):Null<Node2D>;

	/** How its width is decided (Fit, to start, or what the widget it places takes from the theme). Assigning it makes it the game's: the
		theme no longer changes it. */
	public var widthSizing(get, set):Sizing;

	function get_widthSizing():Sizing
		return widthRule;

	function set_widthSizing(value:Sizing):Sizing {
		widthRule = value;
		gameWidth = true;
		return value;
	}

	/** How its height is decided, as widthSizing. */
	public var heightSizing(get, set):Sizing;

	function get_heightSizing():Sizing
		return heightRule;

	function set_heightSizing(value:Sizing):Sizing {
		heightRule = value;
		gameHeight = true;
		return value;
	}

	/** How its width and height are decided, both made the game's (widthSizing and heightSizing). */
	public function setSizing(width:Sizing, height:Sizing):Void {
		set_widthSizing(width);
		set_heightSizing(height);
	}

	/** Its padding inside its left edge. */
	public var paddingLeft(default, null):Float = 0.;

	/** Its padding inside its top edge. */
	public var paddingTop(default, null):Float = 0.;

	/** Its padding inside its right edge. */
	public var paddingRight(default, null):Float = 0.;

	/** Its padding inside its bottom edge. */
	public var paddingBottom(default, null):Float = 0.;

	/** Its padding inside its edges (none, to start, or what the widget it places takes from the theme), made the game's: the theme no longer
		changes it. */
	public function setPadding(left:Float, top:Float, right:Float, bottom:Float):Void {
		applyPadding(left, top, right, bottom);
		gamePadding = true;
	}

	function applyPadding(left:Float, top:Float, right:Float, bottom:Float):Void {
		paddingLeft = left;
		paddingTop = top;
		paddingRight = right;
		paddingBottom = bottom;
	}

	/** The room between its children in a row or column (0, to start, or what the widget it places takes from the theme). Assigning it makes
		it the game's: the theme no longer changes it. */
	public var gap(default, set):Float = 0.;

	function set_gap(value:Float):Float {
		gap = value;
		gameGap = true;
		return value;
	}

	// The theme's values, from widgets (their readTheme, and the defaults their constructors give their layouts): each applied only while the
	// game hasn't set that value itself, and never making it the game's, so a theme changed later still reaches it. A widget's own sizes for a
	// widget it holds (a color picker's field) are its, as a game's: set through the game's calls.
	// Its width's and height's sizing from the theme (null: that way's left be).

	@:allow(helix.ui)
	function themeSizing(width:Null<Sizing>, height:Null<Sizing>):Void {
		if (width != null && !gameWidth)
			widthRule = width;
		if (height != null && !gameHeight)
			heightRule = height;
	}

	// Its padding from the theme.

	@:allow(helix.ui)
	function themePadding(left:Float, top:Float, right:Float, bottom:Float):Void {
		if (!gamePadding)
			applyPadding(left, top, right, bottom);
	}

	// Its gap from the theme.

	@:allow(helix.ui)
	function themeGap(value:Float):Void {
		if (!gameGap)
			@:bypassAccessor gap = value;
	}

	/** Where its children go along its row or column. */
	public var mainAlign(default, null):Alignment = Start;

	/** Where its children go across its row or column. */
	public var crossAlign(default, null):Alignment = Start;

	/** Where its children go: along a row or column (main: Start, Center or End when none grows) and across it (cross, Stretch filling it);
		Start both, to start. */
	public function setAlign(main:Alignment, cross:Alignment):Void {
		mainAlign = main;
		crossAlign = cross;
	}

	/** Where it goes across a stack, or null for its stack's alignment. */
	public var anchorX(get, never):Null<Alignment>;

	function get_anchorX():Null<Alignment>
		return selfX;

	/** Where it goes down a stack, or null for its stack's alignment. */
	public var anchorY(get, never):Null<Alignment>;

	function get_anchorY():Null<Alignment>
		return selfY;

	/** How far it's moved right from its anchor. */
	public var anchorOffsetX(get, never):Float;

	function get_anchorOffsetX():Float
		return offsetX;

	/** How far it's moved down from its anchor. */
	public var anchorOffsetY(get, never):Float;

	function get_anchorOffsetY():Float
		return offsetY;

	/** Where it goes in a stack (horizontally, vertically; Stretch fills that way), moved by offsetX, offsetY: anchored to an edge, a corner
		or the middle. */
	public function setAnchor(horizontal:Alignment, vertical:Alignment, offsetX = 0., offsetY = 0.):Void {
		selfX = horizontal;
		selfY = vertical;
		this.offsetX = offsetX;
		this.offsetY = offsetY;
	}

	/** Where the last arrange put it, x of its left edge. */
	public var x(default, null):Float = 0.;

	/** Its top edge as last arranged. */
	public var y(default, null):Float = 0.;

	/** Its width as last arranged. */
	public var width(get, never):Float;

	function get_width():Float
		return w;

	/** Its height as last arranged. */
	public var height(get, never):Float;

	function get_height():Float
		return h;

	/** Lays root and everything in it out in the rectangle x, y, width x height (a screen's, a design resolution's) and writes the nodes'
		places: its content measured (texts in their fonts, font for those without one), then each layout placed. Once a frame, before drawing. */
	public static function arrange(root:Layout2D, x:Float, y:Float, width:Float, height:Float, font:Font2D):Void {
		root.measure(font);
		root.x = x;
		root.y = y;
		root.w = sized(root.widthRule, root.fitWidth, width);
		root.h = sized(root.heightRule, root.fitHeight, height);
		root.place(font);
	}

	static function sized(sizing:Sizing, fit:Float, room:Float):Float
		return switch sizing {
			case Fixed(units): units;
			case Fit: fit;
			case Grow(_): room;
			case Percent(f): room * f;
		}

	// Its content's size, bottom up: its children's along and across its direction, or its node's.
	function measure(font:Font2D):Void {
		for (c in childLayouts)
			c.measure(font);
		var cw = 0., ch = 0.;
		if (childLayouts.length == 0 && node != null) {
			var text = Std.downcast(node, Text2D),
				shape = Std.downcast(node, Shape2D),
				sprite = Std.downcast(node, Sprite2D);
			if (text != null) {
				cw = text.measureWidth(font);
				ch = text.measureHeight(font);
			} else if (shape != null && shape.form == Circle)
				cw = ch = shape.radius * 2;
			else if (shape != null) {
				cw = shape.width;
				ch = shape.height;
			} else if (sprite != null) {
				cw = sprite.width;
				ch = sprite.height;
			}
		} else
			for (c in childLayouts) {
				var fw = own(c.widthRule, c.fitWidth),
					fh = own(c.heightRule, c.fitHeight);
				switch direction {
					case Row:
						cw += fw;
						ch = Math.max(ch, fh);
					case Column:
						ch += fh;
						cw = Math.max(cw, fw);
					case Stack:
						cw = Math.max(cw, fw);
						ch = Math.max(ch, fh);
				}
			}
		var gaps = childLayouts.length > 1 && direction != Stack ? gap * (childLayouts.length - 1) : 0;
		fitWidth = cw + paddingLeft + paddingRight + (direction == Row ? gaps : 0);
		fitHeight = ch + paddingTop + paddingBottom + (direction == Column ? gaps : 0);
	}

	// What a child asks for before the room is shared: fixed or fitted, nothing yet for growing or a share.
	static function own(sizing:Sizing, fit:Float):Float
		return switch sizing {
			case Fixed(units): units;
			case Fit: fit;
			case _: 0;
		}

	// Places its node, then its children in its room, top down.
	function place(font:Font2D):Void {
		if (node != null) {
			// Its position is its pivot's: a text's by its alignment, a circle's its center; a sprite or rectangle sized to it.
			var text = Std.downcast(node, Text2D),
				shape = Std.downcast(node, Shape2D),
				sprite = Std.downcast(node, Sprite2D);
			var px = 0., py = 0.;
			if (text != null)
				px = text.align == Center ? w / 2 : text.align == Right ? w : 0;
			else if (shape != null && shape.form == Circle) {
				px = w / 2;
				py = h / 2;
			} else if (shape != null) {
				shape.setSize(w, h);
				px = shape.pivotX * w;
				py = shape.pivotY * h;
			} else if (sprite != null) {
				sprite.setSize(w, h);
				px = sprite.pivotX * w;
				py = sprite.pivotY * h;
			}
			node.setPosition(x + px, y + py);
		}
		var innerX = x + paddingLeft, innerY = y + paddingTop;
		var innerW = Math.max(0, w - paddingLeft - paddingRight),
			innerH = Math.max(0, h - paddingTop - paddingBottom);
		if (direction == Stack) {
			for (c in childLayouts) {
				var ax = c.selfX != null ? c.selfX : mainAlign,
					ay = c.selfY != null ? c.selfY : crossAlign;
				c.w = ax == Stretch ? innerW : sized(c.widthRule, c.fitWidth, innerW);
				c.h = ay == Stretch ? innerH : sized(c.heightRule, c.fitHeight, innerH);
				c.x = innerX + offset(ax, innerW, c.w) + c.offsetX;
				c.y = innerY + offset(ay, innerH, c.h) + c.offsetY;
				c.place(font);
			}
			return;
		}
		var row = direction == Row,
			room = row ? innerW : innerH,
			across = row ? innerH : innerW;
		// The room left after the fixed, fitted and shared children and the gaps, shared by the growing ones by weight.
		var used = childLayouts.length > 1 ? gap * (childLayouts.length - 1) : 0., weights = 0.;
		for (c in childLayouts) {
			var sizing = row ? c.widthRule : c.heightRule;
			switch sizing {
				case Grow(weight):
					weights += weight;
				case Percent(f):
					used += room * f;
				case _:
					used += own(sizing, row ? c.fitWidth : c.fitHeight);
			}
		}
		var left = Math.max(0, room - used),
			at = (row ? innerX : innerY) + (weights > 0 ? 0 : offset(mainAlign, room, used));
		for (c in childLayouts) {
			var sizing = row ? c.widthRule : c.heightRule,
				crossSizing = row ? c.heightRule : c.widthRule;
			var along = switch sizing {
				case Grow(weight): weights > 0 ? left * weight / weights : 0;
				case _: sized(sizing, row ? c.fitWidth : c.fitHeight, room);
			}
			var crossAlignment = crossAlign == Stretch && crossSizing == Fit ? Stretch : crossAlign;
			var thick = crossAlignment == Stretch ? across : sized(crossSizing, row ? c.fitHeight : c.fitWidth, across);
			var crossAt = (row ? innerY : innerX) + offset(crossAlignment, across, thick);
			if (row) {
				c.x = at;
				c.y = crossAt;
				c.w = along;
				c.h = thick;
			} else {
				c.y = at;
				c.x = crossAt;
				c.h = along;
				c.w = thick;
			}
			c.x += c.offsetX;
			c.y += c.offsetY;
			at += along + gap;
			c.place(font);
		}
	}

	static function offset(alignment:Alignment, room:Float, size:Float):Float
		return switch alignment {
			case Center: (room - size) / 2;
			case End: room - size;
			case _: 0;
		}
}
