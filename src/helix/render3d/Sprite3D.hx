package helix.render3d;

import helix.graphics.AlphaMode;
import helix.texture.Texture2D;

/** A sprite: a texture (or a region of it) on a quad, 1 x 1 world units by default, its pivot at its position, facing the camera, blended by
	its alpha, unlit, tinted (0xAARRGGBB, sRGB, as 2D sprites are). Its scale scales it; its rotation turns it only when its facing is its own
	(Ground, Free). */
class Sprite3D extends Node3D {
	var cutoff = .5;

	/** A sprite of texture (null for none yet: it draws nothing), tinted (0xAARRGGBB, white for none). */
	public function new(texture:Null<Texture2D>, tint = 0xffffffff) {
		super();
		this.texture = texture;
		this.tint = tint;
	}

	/** Its texture, or null. */
	public var texture:Null<Texture2D>;

	/** Its tint, 0xAARRGGBB (sRGB). */
	public var tint:Int = 0xffffffff;

	/** The effect it draws through (a sprite shader: helix.shader' SpriteOutline, SpriteFlash, SpriteDissolve, PaletteSwap, or an app's
		SpriteEffect; its shader's sprite3D variant, its alpha mode applied as ever), or null (the default) for the framework's sprite program.
		Shared, as a 2D sprite's: the sprites given one draw with its values at the stage's time, and alike ones beside each other in the draw
		order (a texture, an alpha mode, an effect) are one draw. */
	public var effect:Null<helix.graphics.SpriteEffect>;

	/** Its region of its texture, in texels from its top-left; a width or height of 0 or less (the default) shows the whole texture. */
	public function setRegion(x:Float, y:Float, width:Float, height:Float):Void {
		regionX = x;
		regionY = y;
		regionWidth = width;
		regionHeight = height;
	}

	/** Its region's left, in texels. */
	public var regionX(default, null):Float = 0.;

	/** Its region's top, in texels. */
	public var regionY(default, null):Float = 0.;

	/** Its region's width in texels (0 or less: the whole texture). */
	public var regionWidth(default, null):Float = 0.;

	/** Its region's height in texels (0 or less: the whole texture). */
	public var regionHeight(default, null):Float = 0.;

	/** Its width in world units, before its scale (1 by default). */
	public var spriteWidth(default, null):Float = 1.;

	/** Its height in world units, before its scale (1 by default). */
	public var spriteHeight(default, null):Float = 1.;

	/** Sizes it, in world units before its scale. False, changing nothing, for a size below 0. */
	public function setSpriteSize(width:Float, height:Float):Bool {
		if (!(width >= 0 && height >= 0))
			return false;
		spriteWidth = width;
		spriteHeight = height;
		return true;
	}

	/** Sets the point at its position, which it turns and scales about, as a fraction of its size: 0, 0 its top-left, 1, 1 its bottom-right
		(0.5, 0.5, its center, by default). */
	public function setPivot(x:Float, y:Float):Void {
		pivotX = x;
		pivotY = y;
	}

	/** Its pivot's x fraction. */
	public var pivotX(default, null):Float = .5;

	/** Its pivot's y fraction. */
	public var pivotY(default, null):Float = .5;

	/** How it faces. */
	public var facing:SpriteFacing3D = Camera;

	/** How its texels' alpha is used. */
	public var alphaMode(default, null):AlphaMode = Blend;

	/** The alpha below which a Mask sprite's texels are cut out (0..1). */
	public var alphaCutoff(get, never):Float;

	function get_alphaCutoff():Float
		return cutoff;

	/** Sets how it uses its texels' alpha, and a Mask's cutoff (0..1, 0.5 by default). False, changing nothing, for a cutoff outside 0..1. */
	public function setAlphaMode(mode:AlphaMode, cutoff = .5):Bool {
		if (!(cutoff >= 0 && cutoff <= 1))
			return false;
		alphaMode = mode;
		this.cutoff = cutoff;
		return true;
	}

	override function get_spriteKind():Node3D.SpriteKind3D
		return Flat;

	override function attachSprites(renderer:Renderer3D):Void
		Sprites3D.attach(renderer);

	override function visitSprites(sprites:Any, planes:haxe.ds.Vector<Float>, eyeX:Float, eyeY:Float, eyeZ:Float, forwardX:Float, forwardY:Float,
			forwardZ:Float, still:Bool):Void
		(sprites : Sprites3D).visit(this, planes, eyeX, eyeY, eyeZ, forwardX, forwardY, forwardZ);

	override function pickSprites(sprites:Any, ray:Ray3D, best:Float, hit:PickHit3D):Float
		return (sprites : Sprites3D).pickSprite(this, ray, best, hit);
}
