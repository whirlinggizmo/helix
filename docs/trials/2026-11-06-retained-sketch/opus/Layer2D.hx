import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.Rlgl.*;
import helix.raylib.extras.Sprites.*;
import helix.raylib.extras.Textures.*;
import helix.raylib.Color;
import helix.raylib.Font;
import helix.raylib.Matrix;
import helix.raylib.Rectangle;
import helix.raylib.Texture2D;
import helix.raylib.Vector2;

/** A sketch, not an engine: a display list in Pixi's shape (`Container`, `Sprite`, `Text`, `Graphics`, children drawn in order) issuing
	raylib's calls alone, over the 3D scene, after `EndMode3D`. `GAP n` comments continue Scene3D.hx's. */
class Layer2D extends Container2D {
	/** Creates an empty layer. */
	public function new() {
		super();
	}

	/** Returns a small layer: a ship of two sprites from a sheet, a label and a health bar, all children of one turning, scaled group.

		@return  The layer. */
	public static function demo():Layer2D {
		var layer = new Layer2D();
		var ship = new Container2D();
		ship.setPosition(120, 90);
		ship.rotation = 0.3;
		ship.scaleX = 2;
		layer.addChild(ship);
		LoadTextureAsync("assets/sheet.png", sheet -> {
			// Filled shapes sample the sheet's white texel, so rectangles stay in the sprites' run (raylib's own door).
			SetShapesTexture(sheet, new Rectangle(0, 0, 1, 1));
			var hull = new Sprite2D(sheet, new Rectangle(8, 0, 32, 32));
			hull.setAnchor(0.5, 0.5);
			ship.addChild(hull);
			var gun = new Sprite2D(sheet, new Rectangle(40, 0, 16, 8));
			gun.setPosition(10, -4);
			gun.rotation = -0.5;
			gun.tint = RED;
			hull.addChild(gun);
			var bar = new Graphics2D();
			bar.setPosition(-16, 20);
			bar.drawRect(0, 0, 32, 4, GREEN);
			bar.drawCircle(36, 2, 3, YELLOW);
			ship.addChild(bar);
			var label = new Text2D(GetFontDefault(), "player", 10);
			label.setPosition(-16, -30);
			ship.addChild(label);
		});
		return layer;
	}

	/** Draws the list, children in order, each over those before it. */
	public function render():Void {
		drawTree(MatrixIdentity(), 1);
		// GAP 8: a run is one texture. Text is the font's texture, so `label` ends the sheet's run and whatever follows starts another,
		// and so does a second sheet. Merging the font's image into the sheet (ImageDraw, then `font.texture` and `font.recs`, both
		// public) brings text in. Two sheets interleaved in the list cost a draw each change, where Pixi binds several textures a batch.
	}
}

/** Represents a display node, as Pixi's `Container`: a transform and children drawn in order. */
class Container2D {
	/** Gets the children, in drawing order. */
	public var children(default, null):Array<Container2D> = [];

	/** Gets or sets the x, relative to the parent, in pixels. */
	public var x = 0.0;

	/** Gets or sets the y, relative to the parent, in pixels. */
	public var y = 0.0;

	/** Gets or sets the rotation, in radians, clockwise on screen. */
	public var rotation = 0.0;

	/** Gets or sets the scale along the node's x. */
	public var scaleX = 1.0;

	/** Gets or sets the scale along the node's y. */
	public var scaleY = 1.0;

	/** Gets or sets the opacity of the node and its subtree, 0 to 1, multiplied down the tree. */
	public var alpha = 1.0;

	/** Creates a node at the origin. */
	public function new() {}

	/** Sets the position.

		@param x  The x.
		@param y  The y. */
	public function setPosition(x:Float, y:Float):Void {
		this.x = x;
		this.y = y;
	}

	/** Adds a child, drawn last.

		@param child  The child. */
	public function addChild(child:Container2D):Void {
		children.push(child);
	}

	/** Draws the node and its subtree: its world matrix is its local one (scale, rotation, translation) then its parent's.

		@param parentWorld  The parent's world matrix.
		@param parentAlpha  The parent's opacity. */
	public function drawTree(parentWorld:Matrix, parentAlpha:Float):Void {
		var world = MatrixMultiply(MatrixMultiply(MatrixMultiply(MatrixScale(scaleX, scaleY, 1), MatrixRotateZ(rotation)), MatrixTranslate(x, y, 0)),
			parentWorld);
		var a = parentAlpha * alpha;
		draw(world, a);
		for (c in children)
			c.drawTree(world, a);
	}

	/** Draws the node alone. A bare container draws nothing.

		@param world  Its world matrix.
		@param alpha  Its opacity. */
	function draw(world:Matrix, alpha:Float):Void {}
}

/** Represents a part of a texture with a pivot, as Pixi's `Sprite`. */
class Sprite2D extends Container2D {
	/** Gets or sets the texture. */
	public var texture:Texture2D;

	/** Gets or sets the region of the texture, in texels. */
	public var region:Rectangle;

	/** Gets or sets the tint. */
	public var tint = WHITE;

	/** Gets the pivot's x, a fraction of the width. */
	public var anchorX(default, null) = 0.0;

	/** Gets the pivot's y, a fraction of the height. */
	public var anchorY(default, null) = 0.0;

	// One element, reused: DrawTextureInstanced takes an array, and is the one texture draw taking a whole matrix.
	static final one:Array<Matrix> = [MatrixIdentity()];

	/** Creates a sprite.

		@param texture  The texture.
		@param region  The region. */
	public function new(texture:Texture2D, region:Rectangle) {
		super();
		this.texture = texture;
		this.region = region;
	}

	/** Sets the pivot, as fractions of the size.

		@param x  The x fraction.
		@param y  The y fraction. */
	public function setAnchor(x:Float, y:Float):Void {
		anchorX = x;
		anchorY = y;
	}

	override function draw(world:Matrix, alpha:Float):Void {
		// A whole matrix, so a child of a scaled, turned parent shears as Pixi's does. DrawTexturePro's rectangle, origin and angle can't.
		one[0] = MatrixMultiply(MatrixTranslate(-anchorX * region.width, -anchorY * region.height, 0), world);
		DrawTextureInstanced(texture, region, one, Fade(tint, alpha));
	}
}

/** Represents a line of text, as Pixi's `Text`. */
class Text2D extends Container2D {
	/** Gets or sets the text. */
	public var text:String;

	/** Gets or sets the font. */
	public var font:Font;

	/** Gets or sets the size, in pixels. */
	public var fontSize:Float;

	/** Gets or sets the color. */
	public var color = WHITE;

	/** Creates a text.

		@param font  The font.
		@param text  The text.
		@param fontSize  The size. */
	public function new(font:Font, text:String, fontSize:Float) {
		super();
		this.font = font;
		this.text = text;
		this.fontSize = fontSize;
	}

	override function draw(world:Matrix, alpha:Float):Void {
		// DrawTextPro has an angle and no scale, so the world matrix goes through rlgl. Each glyph stays a sprite record under it.
		rlPushMatrix();
		rlMultMatrixf(MatrixToFloatV(world));
		DrawTextEx(font, text, new Vector2(0, 0), fontSize, 1, Fade(color, alpha));
		rlPopMatrix();
	}
}

/** Represents shapes in a node's own space, as Pixi's `Graphics`. */
class Graphics2D extends Container2D {
	final commands:Array<Float->Void> = [];

	/** Creates an empty graphics node. */
	public function new() {
		super();
	}

	/** Adds a filled rectangle.

		@param x  Its left.
		@param y  Its top.
		@param width  Its width.
		@param height  Its height.
		@param color  Its color. */
	public function drawRect(x:Float, y:Float, width:Float, height:Float, color:Color):Void {
		commands.push(alpha -> DrawRectangleRec(new Rectangle(x, y, width, height), Fade(color, alpha)));
	}

	/** Adds a filled circle.

		@param x  Its center's x.
		@param y  Its center's y.
		@param radius  Its radius.
		@param color  Its color. */
	public function drawCircle(x:Float, y:Float, radius:Float, color:Color):Void {
		// Triangles, so a vertex run of its own between the sprites' runs, in order.
		commands.push(alpha -> DrawCircleV(new Vector2(x, y), radius, Fade(color, alpha)));
	}

	override function draw(world:Matrix, alpha:Float):Void {
		rlPushMatrix();
		rlMultMatrixf(MatrixToFloatV(world));
		for (c in commands)
			c(alpha);
		rlPopMatrix();
	}
}
