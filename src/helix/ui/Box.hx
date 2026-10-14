package helix.ui;

import helix.render2d.Font2D;
import helix.render2d.Node2D;
import helix.render2d.Text2D;

/** How a box's width or height is decided. */
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

/** Where boxes go in the room they have, along an axis. */
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

/** How a box lays its children out. */
enum BoxDirection {
	/** Left to right. */
	Row;

	/** Top to bottom. */
	Column;

	/** Over one another, each placed by its own alignment in the box (anchored to an edge, a corner or the middle). */
	Stack;
}

/** A rectangle of a layout: rows, columns and stacks of boxes, each sized fixed, fitted to its content, growing into the room left or as a
	share of its parent, with padding, gaps and alignment (Clay's model, in Haxe). A box may place a node: arrange() writes its position (by
	its pivot) and, for a sprite or rectangle, its size, once a frame. Boxes only lay out; what's drawn is the nodes'. */
class Box {
	var direction:BoxDirection;
	var node:Null<Node2D>;
	var children:Array<Box> = [];
	var width:Sizing = Fit;
	var height:Sizing = Fit;
	var paddingLeft = 0.;
	var paddingTop = 0.;
	var paddingRight = 0.;
	var paddingBottom = 0.;
	var gap = 0.;
	var mainAlign:Alignment = Start;
	var crossAlign:Alignment = Start;
	var selfX:Null<Alignment>;
	var selfY:Null<Alignment>;
	var offsetX = 0.;
	var offsetY = 0.;
	var fitWidth = 0.;
	var fitHeight = 0.;
	var x = 0.;
	var y = 0.;
	var w = 0.;
	var h = 0.;

	/** A box laying out its children direction's way, placing node (or none). */
	public function new(direction:BoxDirection, ?node:Node2D) {
		this.direction = direction;
		this.node = node;
	}

	/** A row, left to right. */
	public static function row(?node:Node2D):Box
		return new Box(Row, node);

	/** A column, top to bottom. */
	public static function column(?node:Node2D):Box
		return new Box(Column, node);

	/** A stack, its children over one another, each by its own alignment. */
	public static function stack(?node:Node2D):Box
		return new Box(Stack, node);

	/** A box holding node alone, sized to it unless sized otherwise. */
	public static function of(node:Node2D):Box
		return new Box(Stack, node);

	/** Adds child as its last; returns this box, for chaining. */
	public function add(child:Box):Box {
		children.push(child);
		return this;
	}

	/** Takes child out. */
	public function remove(child:Box):Bool
		return children.remove(child);

	/** Its children, in order. */
	public function getChildren():Array<Box>
		return children.copy();

	/** The node it places, or null. */
	public function getNode():Null<Node2D>
		return node;

	/** Sizes it; returns this box. */
	public function setSize(width:Sizing, height:Sizing):Box {
		this.width = width;
		this.height = height;
		return this;
	}

	/** Its padding inside its edges; returns this box. */
	public function setPadding(left:Float, top:Float, right:Float, bottom:Float):Box {
		paddingLeft = left;
		paddingTop = top;
		paddingRight = right;
		paddingBottom = bottom;
		return this;
	}

	/** The room between its children in a row or column; returns this box. */
	public function setGap(value:Float):Box {
		gap = value;
		return this;
	}

	/** Where its children go: along a row or column (main: Start, Center or End when none grows) and across it (cross, Stretch filling it);
		returns this box. */
	public function setAlign(main:Alignment, cross:Alignment):Box {
		mainAlign = main;
		crossAlign = cross;
		return this;
	}

	/** Where it goes in a stack (horizontally, vertically; Stretch fills that way), moved by offsetX, offsetY: anchored to an edge, a corner
		or the middle. Returns this box. */
	public function setAnchor(horizontal:Alignment, vertical:Alignment, offsetX = 0., offsetY = 0.):Box {
		selfX = horizontal;
		selfY = vertical;
		this.offsetX = offsetX;
		this.offsetY = offsetY;
		return this;
	}

	/** Where the last arrange put it, x of its left edge. */
	public function getX():Float
		return x;

	/** Its top edge as last arranged. */
	public function getY():Float
		return y;

	/** Its width as last arranged. */
	public function getWidth():Float
		return w;

	/** Its height as last arranged. */
	public function getHeight():Float
		return h;

	/** Lays root and everything in it out in the rectangle x, y, width x height (a screen's, a design resolution's) and writes the nodes'
		places: its content measured (texts in their fonts, font for those without one), then each box placed. Once a frame, before drawing. */
	public static function arrange(root:Box, x:Float, y:Float, width:Float, height:Float, font:Font2D):Void {
		root.measure(font);
		root.x = x;
		root.y = y;
		root.w = sized(root.width, root.fitWidth, width);
		root.h = sized(root.height, root.fitHeight, height);
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
		for (c in children)
			c.measure(font);
		var cw = 0., ch = 0.;
		if (children.length == 0 && node != null) {
			switch node.getKind() {
				case Text:
					var f = node.getFont() != null ? node.getFont() : font;
					cw = node.getWrapWidth() > 0 ? node.getWrapWidth() : Text2D.measure(f, node.getText(), node.getTextSize());
					ch = node.getTextHeight(f);
				case Circle:
					cw = ch = node.getRadius() * 2;
				case _:
					cw = node.getWidth();
					ch = node.getHeight();
			}
		} else
			for (c in children) {
				var fw = own(c.width, c.fitWidth),
					fh = own(c.height, c.fitHeight);
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
		var gaps = children.length > 1 && direction != Stack ? gap * (children.length - 1) : 0;
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
			switch node.getKind() {
				case Sprite | Rectangle:
					node.setSize(w, h);
				case _:
			}
			// Its position is its pivot's: a text's by its alignment, a circle's its center.
			var px = switch node.getKind() {
				case Text: node.getAlign() == Center ? w / 2 : node.getAlign() == Right ? w : 0;
				case Circle: w / 2;
				case _: node.getPivotX() * w;
			}, py = switch node.getKind() {
				case Text: 0;
				case Circle: h / 2;
				case _: node.getPivotY() * h;
			};
			node.setPosition(x + px, y + py);
		}
		var innerX = x + paddingLeft, innerY = y + paddingTop;
		var innerW = Math.max(0, w - paddingLeft - paddingRight),
			innerH = Math.max(0, h - paddingTop - paddingBottom);
		if (direction == Stack) {
			for (c in children) {
				var ax = c.selfX != null ? c.selfX : mainAlign,
					ay = c.selfY != null ? c.selfY : crossAlign;
				c.w = ax == Stretch ? innerW : sized(c.width, c.fitWidth, innerW);
				c.h = ay == Stretch ? innerH : sized(c.height, c.fitHeight, innerH);
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
		var used = children.length > 1 ? gap * (children.length - 1) : 0., weights = 0.;
		for (c in children) {
			var sizing = row ? c.width : c.height;
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
		for (c in children) {
			var sizing = row ? c.width : c.height,
				crossSizing = row ? c.height : c.width;
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
