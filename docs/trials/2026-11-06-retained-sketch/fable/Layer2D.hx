import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.Rlgl.*;
import helix.raylib.extras.Textures.*;

// A sketch, not an engine: a display list in Pixi's shape (Container, Sprite, Text, Graphics) drawn through raylib's calls alone, over
// the 3D scene of Scene3D.hx, to find what raylib's API has no door for. Each place the sketch hits one is marked GAP with a number,
// and docs/trials/2026-11-06-retained-sketch/sketch.md lists them. Type-checks; nothing here runs.

/** Represents a node in the display list (Pixi's `Container`): a transform in a tree, its children drawn after it, in order. */
class Container2D {
	/** Gets or sets the x of the pivot, in the parent's pixels. */
	public var x = 0.;

	/** Gets or sets the y of the pivot. */
	public var y = 0.;

	/** Gets or sets the rotation about the pivot, in radians, clockwise on the screen. */
	public var rotation = 0.;

	/** Gets or sets the scale across. */
	public var scaleX = 1.;

	/** Gets or sets the scale down. */
	public var scaleY = 1.;

	/** Gets or sets the pivot's x, in the node's own pixels: the point placed at `x`, `y` and turned about (Pixi's `pivot`). */
	public var pivotX = 0.;

	/** Gets or sets the pivot's y. */
	public var pivotY = 0.;

	/** Gets or sets the alpha, 0 to 1, multiplied down the tree. */
	public var alpha = 1.;

	/** Gets or sets a value indicating whether the node and its subtree are drawn. */
	public var visible = true;

	/** Gets the children, in drawing order. */
	public var children(default, null):Array<Container2D> = [];

	/** Gets the node's transform in the layer's pixels, as `updateTransform` last computed it: a 2D affine in raylib's `Matrix`, the fields
		`DrawTextureInstanced` reads. */
	public var worldTransform(default, null) = MatrixIdentity();

	/** Gets the alpha in the world, the node's times every parent's. */
	public var worldAlpha(default, null) = 1.;

	public function new() {}

	/** Adds a child last. */
	public function addChild(child:Container2D):Void
		children.push(child);

	/** Computes the world transform of the node and its subtree. The local is the pivot moved to the origin, then scale, rotation and the
		position, each a raymath matrix, `MatrixMultiply` applying its left first. */
	public function updateTransform(parent:Matrix, parentAlpha:Float):Void {
		var local = MatrixMultiply(MatrixMultiply(MatrixMultiply(MatrixTranslate(-pivotX, -pivotY, 0), MatrixScale(scaleX, scaleY, 1)),
			MatrixRotateZ(rotation)),
			MatrixTranslate(x, y, 0));
		worldTransform = MatrixMultiply(local, parent);
		worldAlpha = alpha * parentAlpha;
		for (child in children)
			child.updateTransform(worldTransform, worldAlpha);
	}

	/** Draws the node's own picture in its own pixels, under the world transform `Layer2D` pushed. A bare container draws nothing. */
	public function draw(layer:Layer2D):Void {}
}

/** Represents a sheet of sprites: a texture and the rectangle of each frame on it. */
class SpriteSheet2D {
	public var texture:Texture2D;
	public var frames:Array<Rectangle>;

	/** Gets or sets a white texel of the sheet, for the layer's shapes to sample so they stay in the sheet's batch (`SetShapesTexture`),
		or null when the sheet has none. */
	public var whiteTexel:Null<Rectangle> = null;

	public function new(texture:Texture2D, frames:Array<Rectangle>) {
		this.texture = texture;
		this.frames = frames;
	}
}

/** Represents a sprite (Pixi's `Sprite`): one frame of a sheet, its top left at the node's origin, tinted. */
class Sprite2D extends Container2D {
	public var sheet:SpriteSheet2D;
	public var frameIndex:Int;

	/** Gets or sets the tint, its alpha scaled by the world alpha when drawn. */
	public var tint = WHITE;

	public function new(sheet:SpriteSheet2D, frameIndex:Int) {
		super();
		this.sheet = sheet;
		this.frameIndex = frameIndex;
	}

	/** Draws the frame at the origin: `DrawTexturePro` with no turn of its own, the world transform pushed around it. Each such quad is
		one record of the frame's sprite run while the texture stays the sheet's. */
	override public function draw(layer:Layer2D):Void {
		var frame = sheet.frames[frameIndex];
		DrawTexturePro(sheet.texture, frame, new Rectangle(0, 0, frame.width, frame.height), new Vector2(0, 0), 0, Fade(tint, worldAlpha));
	}
}

/** Represents text (Pixi's `Text`): a string in a font at a size, its top left at the node's origin. */
class Text2D extends Container2D {
	public var text:String;
	public var font:Font;
	public var fontSize = 20.;
	public var spacing = 1.;
	public var color = BLACK;

	public function new(text:String, font:Font) {
		super();
		this.text = text;
		this.font = font;
	}

	/** Draws the text with `DrawTextEx`. Its glyphs sample the font's atlas, another texture than the sheet, so the sprite run ends here
		and a new one starts after it, as rlgl's batch starts a draw call at each texture: raylib's own cost, not a gap. */
	override public function draw(layer:Layer2D):Void
		DrawTextEx(font, text, new Vector2(0, 0), fontSize, spacing, Fade(color, worldAlpha));
}

/** Represents a shape (Pixi's `Graphics`): rectangles and circles kept in order, each its own color, drawn where the node is. */
class Graphics2D extends Container2D {
	var rectangles:Array<Rectangle> = [];
	var rectangleColors:Array<Color> = [];
	var circles:Array<Vector3> = [];
	var circleColors:Array<Color> = [];

	public function new()
		super();

	/** Adds a filled rectangle. */
	public function drawRect(x:Float, y:Float, width:Float, height:Float, color:Color):Void {
		rectangles.push(new Rectangle(x, y, width, height));
		rectangleColors.push(color);
	}

	/** Adds a filled circle. */
	public function drawCircle(x:Float, y:Float, radius:Float, color:Color):Void {
		circles.push(new Vector3(x, y, radius));
		circleColors.push(color);
	}

	/** Draws the shapes: `DrawRectangleRec` quads join the sprite run when the shapes texture is the sheet (`SetShapesTexture`, set by the
		layer); `DrawCircleV` is triangles, kept as vertices in their own run, in order. */
	override public function draw(layer:Layer2D):Void {
		for (i in 0...rectangles.length)
			DrawRectangleRec(rectangles[i], Fade(rectangleColors[i], worldAlpha));
		for (i in 0...circles.length)
			DrawCircleV(new Vector2(circles[i].x, circles[i].y), circles[i].z, Fade(circleColors[i], worldAlpha));
	}
}

/** Provides the layer: a root container drawn in the screen's pixels after the 3D scene, each node under its world transform through
	rlgl's matrix stack, in the list's order. */
class Layer2D {
	/** Gets the root. */
	public var root(default, null) = new Container2D();

	/** Gets or sets the sheet whose white texel the shapes sample, or null for raylib's own white pixel. */
	public var sheet:Null<SpriteSheet2D> = null;

	public function new() {}

	/** Draws the list, after `EndMode3D`: the world transforms, then each visible node's `draw` between `rlPushMatrix` and `rlPopMatrix`
		with its transform multiplied in. A quad under a pushed transform is still one sprite record, flat in z, so the sheet's sprites stay
		one run through the hierarchy. */
	public function render():Void {
		root.updateTransform(MatrixIdentity(), 1);
		if (sheet != null && sheet.whiteTexel != null)
			SetShapesTexture(sheet.texture, sheet.whiteTexel);
		walk(root);
	}

	function walk(node:Container2D):Void {
		if (!node.visible)
			return;
		rlPushMatrix();
		rlMultMatrixf(MatrixToFloatV(node.worldTransform));
		node.draw(this);
		rlPopMatrix();
		for (child in node.children)
			walk(child);
	}
}

/** The layer the sketch draws: a sheet's sprites in a hierarchy with pivots, rotation and tint, a text, and a shape, over the 3D scene. */
class Sketch2D {
	static function main():Void {
		InitWindow(800, 450, "sketch");
		var layer = new Layer2D();
		LoadTextureAsync("assets/sheet.png", texture -> {
			var sheet = new SpriteSheet2D(texture, [for (i in 0...4) new Rectangle(i * 32, 0, 32, 32)]);
			sheet.whiteTexel = new Rectangle(127, 0, 1, 1);
			layer.sheet = sheet;

			// A ship turning about its center, its two guns under it turning about their own bases.
			var ship = new Sprite2D(sheet, 0);
			ship.pivotX = 16;
			ship.pivotY = 16;
			ship.x = 400;
			ship.y = 225;
			layer.root.addChild(ship);
			for (side in [-1, 1]) {
				var gun = new Sprite2D(sheet, 1);
				gun.pivotX = 16;
				gun.pivotY = 32;
				gun.x = 16 + side * 12;
				gun.y = 8;
				gun.tint = side < 0 ? RED : BLUE;
				ship.addChild(gun);
			}

			// A label and a health bar, drawn after the sprites, in the list's order.
			var label = new Text2D("ship", GetFontDefault());
			label.x = 10;
			label.y = 10;
			layer.root.addChild(label);
			var bar = new Graphics2D();
			bar.drawRect(10, 40, 100, 8, GREEN);
			bar.drawCircle(120, 44, 4, GREEN);
			layer.root.addChild(bar);
		});
		while (!WindowShouldClose()) {
			if (layer.root.children.length > 0)
				layer.root.children[0].rotation = GetTime();
			BeginDrawing();
			ClearBackground(RAYWHITE);
			// The 3D scene goes here (Scene3D.hx), then the layer over it, depth off after EndMode3D.
			layer.render();
			EndDrawing();
		}
		CloseWindow();
	}
}
