package helix.render3d;

import helix.render2d.Texture2D;

/** A sprite: a texture (or a region of it) on a quad, 1 x 1 world units by default, its pivot at its position, facing the camera, blended by
	its alpha, unlit, tinted (0xRRGGBBAA, sRGB, as 2D sprites are). Its scale scales it; its rotation turns it only when its facing is its own
	(Ground, Free). */
class Sprite3D extends Node3D {
	var texture:Null<Texture2D>;
	var tint = 0xffffffff;
	var regionX = 0.;
	var regionY = 0.;
	var regionWidth = 0.;
	var regionHeight = 0.;
	var spriteWidth = 1.;
	var spriteHeight = 1.;
	var pivotX = .5;
	var pivotY = .5;
	var facing:SpriteFacing = Camera;
	var alphaMode:SpriteAlpha = Blend;
	var cutoff = .5;

	/** A sprite of texture (null for none yet: it draws nothing), tinted (0xRRGGBBAA, white for none). */
	public function new(texture:Null<Texture2D>, tint = 0xffffffff) {
		super();
		this.texture = texture;
		this.tint = tint;
	}

	/** Its texture, or null. */
	public function getTexture():Null<Texture2D>
		return texture;

	/** Gives it a texture (null for none: it draws nothing). */
	public function setTexture(value:Null<Texture2D>):Void
		texture = value;

	/** Its tint, 0xRRGGBBAA (sRGB). */
	public function getTint():Int
		return tint;

	/** Sets its tint, 0xRRGGBBAA (sRGB): white for none. */
	public function setTint(value:Int):Void
		tint = value;

	/** Its region of its texture, in texels from its top-left; a width or height of 0 or less (the default) shows the whole texture. */
	public function setRegion(x:Float, y:Float, width:Float, height:Float):Void {
		regionX = x;
		regionY = y;
		regionWidth = width;
		regionHeight = height;
	}

	/** Its region's left, in texels. */
	public function getRegionX():Float
		return regionX;

	/** Its region's top, in texels. */
	public function getRegionY():Float
		return regionY;

	/** Its region's width in texels (0 or less: the whole texture). */
	public function getRegionWidth():Float
		return regionWidth;

	/** Its region's height in texels (0 or less: the whole texture). */
	public function getRegionHeight():Float
		return regionHeight;

	/** Its width in world units, before its scale (1 by default). */
	public function getSpriteWidth():Float
		return spriteWidth;

	/** Its height in world units, before its scale (1 by default). */
	public function getSpriteHeight():Float
		return spriteHeight;

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
	public function getPivotX():Float
		return pivotX;

	/** Its pivot's y fraction. */
	public function getPivotY():Float
		return pivotY;

	/** How it faces. */
	public function getFacing():SpriteFacing
		return facing;

	/** Sets how it faces. */
	public function setFacing(value:SpriteFacing):Void
		facing = value;

	/** How its texels' alpha is used. */
	public function getAlphaMode():SpriteAlpha
		return alphaMode;

	/** The alpha below which a Mask sprite's texels are cut out (0..1). */
	public function getAlphaCutoff():Float
		return cutoff;

	/** Sets how it uses its texels' alpha, and a Mask's cutoff (0..1, 0.5 by default). False, changing nothing, for a cutoff outside 0..1. */
	public function setAlphaMode(mode:SpriteAlpha, cutoff = .5):Bool {
		if (!(cutoff >= 0 && cutoff <= 1))
			return false;
		alphaMode = mode;
		this.cutoff = cutoff;
		return true;
	}
}
