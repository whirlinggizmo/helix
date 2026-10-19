# helix.shaders

[Back to the index](README.md)

## Dissolve

*class* in `src/helix/shaders/Dissolve.hx`

A library surface shader: the material shaded as the stage shades it, burnt away where a noise texture is below a threshold rising with amount, with a glowing edge along the cut; its shadow is cut away with it. The noise is the library's (ShaderLibrary.getNoise) unless the game gives its own. Made on a material, it is that material's surface shader from then on (LibrarySurface); make the material doubleSided to see its inside through the holes.

```haxe
function new(material:Material)
var amount(default, set):Float
var edgeColor(default, set):Int
var edgeIntensity(default, set):Float
var edgeWidth(default, set):Float
var scale(default, set):Float
var noise(default, set):Texture2D
```

- `new`: Makes Dissolve material's surface shader: whole, an orange edge .08 wide, the library's noise twice across.
- `amount`: How much is burnt away, 0 (whole, by default) to 1 (gone). Clamped to 0..1 (NaN is 0).
- `edgeColor`: The glowing edge's color, 0xRRGGBBAA (sRGB, alpha ignored): orange by default.
- `edgeIntensity`: How bright the edge glows: its color times this, 0 or more (past 1 brighter than white light): 4 by default. Under 0, or NaN, is 0.
- `edgeWidth`: How wide the edge glows, in the noise's values (0..1) past the threshold, .001 to 1: .08 by default. Clamped to .001..1 (NaN is .001).
- `scale`: How many times the noise repeats across the surface's texture coordinates (0..1), above 0: 2 by default. Under .001, or NaN, is .001.
- `noise`: The noise it burns along (its red channel, sampled as its sampling says: repeating, for scale to tile it): the library's by default.

## HitFlash

*class* in `src/helix/shaders/HitFlash.hx`

A material's hit flash: a color mixed over its light, all of it at a trigger and fading to none over some seconds of the stage's time (Stage3D.time, which the app advances, as its particles do), or an amount held. Every material has one, off until a HitFlash shows it, drawn by the stage's own shading and every library surface shader alike (an app's surface shader shows it through helix_output too), mixed in after the exposure, so the tone mapping applies to it as to the light. A HitFlash is a view of its material's: two on one material share it.

```haxe
function new(material:Material)
var material(default, null):Material
var color(get, set):Int
var amount(get, set):Float
function trigger(color:Int, seconds:Float):Bool
```

- `new`: Shows material's hit flash: none until triggered or an amount is held.
- `material`: The material it flashes.
- `color`: The flash's color, 0xRRGGBBAA (sRGB), its alpha how strong at most. White by default.
- `amount`: How much of the flash is held, 0 to 1 (times its color's alpha): 0, none, by default. Assigning holds it, ending a fade; read during a fade, it's the fade's start, 1. Clamped to 0..1 (NaN is 0).
- `trigger`: Flashes color (0xRRGGBBAA, sRGB, its alpha how strong) all at once, fading to nothing over seconds of the stage's time from the next draw. False, changing nothing, for seconds not above 0.

## LibrarySurface

*class* in `src/helix/shaders/LibrarySurface.hx`

What the shader library's surface shader classes share (Unlit, Toon, Dissolve, Water): made on a material, the class's shader is that material's surface shader from then on (Material.setShader), built on the program's GPU (Graphics) the first time a material asks for it, and its fields write their parameters into the material's (Material.shaderParameters) while the material keeps it: with another shader on the material since, a field changes nothing there. Every library surface shader shows the material's hit flash and rim light (HitFlash, Rim), as the stage's own shading does.

```haxe
var material(default, null):Material
var attached(get, never):Bool
```

- `material`: The material it draws.
- `attached`: Whether it is still its material's surface shader.

## Outline

*class* in `src/helix/shaders/Outline.hx`

An outline round a model: a pass (ModelPass) drawing the model again after the stage's opaque models, pushed out along its normals by a width in world units, its front faces culled, so the far side of that shell shows as a band past the model's edges, in a flat color; depth tested, so what's nearer covers it. Static or skinned, instanced like the model. Edges where the model's normals split (a cube's corners) open gaps as wide as the width. Made on a model, it draws from then on; remove takes it off.

```haxe
function new(model:Model, ?color:Int = 0x000000ff, ?width:Float = .02)
var width(get, set):Float
```

- `new`: Outlines model in color (0xRRGGBBAA, sRGB: black by default; its alpha ignored, an outline is opaque), width world units wide (.02 by default; under 0 is 0).
- `width`: How far the outline reaches past the model's surface, world units, 0 or more. Under 0, or NaN, is 0.

## Rim

*class* in `src/helix/shaders/Rim.hx`

A material's rim light: a color brightest where its surface turns away from the viewer, round its edge, added to its light. Every material has one, off until a Rim turns it on, drawn by the stage's own shading and every library surface shader alike (an app's surface shader shows it through helix_output too). A Rim is a view of its material's: two on one material share it.

```haxe
function new(material:Material, ?color:Int = 0xffffff80, ?power:Float = 3.)
var material(default, null):Material
var color(get, set):Int
var power(get, set):Float
```

- `new`: Turns material's rim light on: color (0xRRGGBBAA, sRGB, its alpha how strong) and power (.1 to 64, clamped).
- `material`: The material it lights.
- `color`: The rim's color, 0xRRGGBBAA (sRGB), its alpha how strong (0 none, 255 all of it).
- `power`: How tight the rim keeps to the edge, .1 to 64: 1 spreads it over the surface, 3 a rim, 8 a thin line. Clamped to .1..64 (NaN is .1).

## ShaderLibrary

*class* in `src/helix/shaders/ShaderLibrary.hx`

The shader library's programs on each GPU. A library shader's source (src/helix/shaders/*.glsl) is packed at build time into generated Haxe holding its .hxshader (tools/pack_shader.py: <Name>Packed.text()), so a class in helix.shaders gets its shader at once, with no load and no asset, and a shader nothing uses is left out of the build. Each is built the first time it's asked for on a GPU and kept, shared by everything drawing with it, until the runner releases the GPU's. In development a hot reload brings the shaders packed again from changed sources, and each built is built again in place, as Shaders does an app's.

```haxe
static function get(gpu:IGraphics, name:String, text:String):Shader
static var NOISE_SIZE(inline, null):Int
static function getNoise(gpu:IGraphics):Texture2D
static function noisePixels():haxe.io.Bytes
static function release(gpu:IGraphics):Void
```

- `get`: The library shader name (its source's file stem: "unlit") on gpu, built from text (its packed .hxshader, <Name>Packed.text()) the first time it's asked for there. Throws, saying why, for a program that doesn't build.
- `NOISE_SIZE`: The size of the library's noise texture, texels a side.
- `getNoise`: The library's noise texture on gpu (Dissolve's unless a game gives its own), made the first time it's asked for there: NOISE_SIZE texels a side, tiling, smooth value noise of three octaves in its red, green and blue alike, its values spread evenly over 0..1 (so a threshold at t keeps the share 1 - t of it); the same texels on every target. Sampled linear, repeating. The library frees it with its shaders.
- `noisePixels`: The noise texture's texels (getNoise), RGBA8, rows top first.
- `release`: Frees gpu's library shaders, the pipelines made over them and its noise texture, before the adapter shuts down.

## Silhouette

*class* in `src/helix/shaders/Silhouette.hx`

A model seen through what hides it: a pass (ModelPass) drawing the model's shape where something nearer hides it (depth greater), in a flat color blended by its alpha, over the stage's other opaque models and sprites; the model itself is drawn after it, so its own parts never hide it (layered clothes, hair over a head). Static or skinned, instanced like the model. Made on a model, it draws from then on; remove takes it off.

```haxe
function new(model:Model, ?color:Int = 0x3fa9ff99)
```

- `new`: Shows model where it's hidden in color (0xRRGGBBAA, sRGB, blended by its alpha): a light blue at 60% by default.

## Tonemap

*class* in `src/helix/shaders/Tonemap.hx`

An HDR chain's tone mapping, a screen effect of the library: the frame's light (a stage's after its exposure, drawn into a half-float scene as sRGB values running past 1) brought into the screen's 0..1 by mode, as Stage3D does drawing straight to the screen, and written as the screen's sRGB. It wants HDR itself (ScreenEffect.hdr). PostProcess adds one after the last effect wanting HDR, with its stage's mode, to a chain that has none; one added by hand runs where it's added, with its own mode, and only in an HDR chain. Built on the program's GPU (Graphics) the first time one is made.

```haxe
function new()
var mode(default, set):Tonemap
```

- `new`: A tone mapping by Khronos PBR Neutral.
- `mode`: How the light comes into 0..1 (helix.render3d.Tonemap's modes, as Stage3D.tonemap): Khronos PBR Neutral to start.

## Toon

*class* in `src/helix/shaders/Toon.hx`

A library surface shader: the stage's lights in a few flat bands over the material's base color and texture (their shadows banded with them), its unlit side no darker than a shadow color, and its emission; with a rim of light round its edge (the material's Rim, which it turns on). Made on a material, it is that material's surface shader from then on (LibrarySurface).

```haxe
function new(material:Material)
var bands(default, set):Int
var shadowColor(default, set):Int
var rim(default, null):Rim
```

- `new`: Makes Toon material's surface shader: 3 bands, the shadow color dark blue grey, a rim of light.
- `bands`: How many levels of light there are, 1 to 16: 3 by default. Clamped to 1..16.
- `shadowColor`: The least light the surface shows, its unlit side's, 0xRRGGBBAA (sRGB, alpha ignored): the material's color times this where no light reaches. A dark blue grey by default.
- `rim`: Its rim of light: the material's rim light (Rim), on to start, white at a third, power 3.

## Unlit

*class* in `src/helix/shaders/Unlit.hx`

A library surface shader: a material drawn without light, its base color and texture times color, and its emission, under the stage's exposure and tone mapping as a material that isn't lit is. Made on a material, it is that material's surface shader from then on (LibrarySurface).

```haxe
function new(material:Material)
var color(default, set):Int
```

- `new`: Makes Unlit material's surface shader, color white.
- `color`: What the material's base color and texture are multiplied by, 0xRRGGBBAA, its color sRGB as the material's are: white (the material as it is) by default.

## Water

*class* in `src/helix/shaders/Water.hx`

A library surface shader: travelling waves moving the surface along its normals (a vertex hook: the model needs vertices enough to show them), colored deep where it's looked into and shallow toward grazing, lit by the stage's lights with their glints, reflecting the stage's environment (or a sky color without one) at grazing angles; its shadow moves with its waves. The material's base color's alpha is its alpha (a blended material is see-through). Made on a material, it is that material's surface shader from then on (LibrarySurface).

```haxe
function new(material:Material)
var amplitude(default, set):Float
var wavelength(default, set):Float
var waveSpeed(default, set):Float
var deepColor(default, set):Int
var shallowColor(default, set):Int
var skyColor(default, set):Int
var shininess(default, set):Float
```

- `new`: Makes Water material's surface shader, its waves and colors at their defaults.
- `amplitude`: The waves' height in the model's units, 0 or more: .03 by default. Under 0, or NaN, is 0.
- `wavelength`: The distance between crests in the model's units, .001 or more: .4 by default. Under .001, or NaN, is .001.
- `waveSpeed`: How fast the crests travel, the model's units a second (by the stage's time): .2 by default.
- `deepColor`: Its color looked straight into, 0xRRGGBBAA (sRGB, alpha ignored): a deep blue by default.
- `shallowColor`: Its color toward grazing, 0xRRGGBBAA (sRGB, alpha ignored): a green blue by default.
- `skyColor`: What it reflects at grazing angles when the stage has no environment, 0xRRGGBBAA (sRGB, alpha ignored): a pale sky by default.
- `shininess`: How tight the lights' glints are, 1 to 2048: 120 by default. Clamped to 1..2048 (NaN is 1).
