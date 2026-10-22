# helix.shaders

[Back to the index](README.md)

## Bloom

*class* in `src/helix/shaders/Bloom.hx`

Bloom, a screen effect of the library: light past a threshold spread around it, as a bright light glows in a lens or an eye. It wants HDR (ScreenEffect.hdr), so in a chain with it the scene is drawn in half floats where the GPU can, and the light running past 1 is what blooms; it decodes the frame to linear light first. The light past threshold (eased in over a soft knee) is drawn into half the frame's size through a 13-tap filter (each group of four weighted by its brightness, so a lone bright texel doesn't flicker), on down a chain of LEVELS halving sizes; each level is then added to the one above it drawn larger through a 3 x 3 tent filter, back to half the frame's size, and that is added to the frame times intensity. Where the GPU draws no half floats (or after a Tonemap of the chain's own), the frame reaching it is tone mapped, 8-bit, and toneMappedThreshold takes threshold's place. Its intermediates are the chain's levels: LEVELS going down, then LEVELS - 1 coming back up (ScreenEffect.intermediates).

```haxe
function new()
static var LEVELS(inline, null):Int
var threshold(default, set):Float
var knee(default, set):Float
var toneMappedThreshold(default, set):Float
var intensity(default, set):Float
function drawIntermediates(frame:ScreenFrame):Void
function draw(frame:ScreenFrame):Void
```

- `new`: A bloom of light past 1 (in linear light), its knee half the threshold, added at intensity 1.
- `LEVELS`: The levels of its chain going down: half the frame's size, a quarter, and so on to a 64th.
- `threshold`: Where the bloom starts in an HDR frame: light (linear, past the exposure) whose brightest channel passes it blooms, the more the further past. 0 to 64, 1 by default: light brighter than the screen's white.
- `knee`: How softly light past the threshold comes in: the width of the knee either side of it, a share of the threshold, 0 (a hard cut) to 1; .5 by default.
- `toneMappedThreshold`: Where the bloom starts in a frame already tone mapped (8-bit, where the GPU draws no half floats), in linear light 0 to 1: .8 by default, the brightest of what's there.
- `intensity`: How much of the bloom is added to the frame, 0 (none) to 16: 1 by default. At 1 the light past the threshold is added again, spread.
- `drawIntermediates`: Draws the chain: the light past the threshold into the first level, down the levels, and back up them.
- `draw`: Adds the bloom to the frame, over the open pass's viewport.

## Blur

*class* in `src/helix/shaders/Blur.hx`

Blur, a screen effect of the library: the frame blurred, a Gaussian over radius pixels either way, in two passes (across, into a texture at resolution of the frame's size, then down, from it drawn larger). Its one intermediate is that texture (ScreenEffect.intermediates).

```haxe
function new(?radius:Float = 8., ?resolution:Float = .5)
var radius(default, set):Float
var resolution(default, set):Float
function drawIntermediates(frame:ScreenFrame):Void
function draw(frame:ScreenFrame):Void
```

- `new`: A blur of radius pixels (the frame's) drawn at resolution of the frame's size.
- `radius`: How far it reaches either way, in the frame's pixels, 0 (none) to 128: 8 by default. Its standard deviation is a third of it.
- `resolution`: The size of its first pass's texture, a fraction of the frame's each way, 1/16 to 1: .5 by default. Smaller is cheaper and, for a wide radius, no worse.
- `drawIntermediates`: Draws the pass across, from the frame into its texture.
- `draw`: Draws the pass down, from its texture over the open pass's viewport.

## ChromaticAberration

*class* in `src/helix/shaders/ChromaticAberration.hx`

Chromatic aberration, a screen effect of the library: red and blue parted from green, red toward the middle and blue away from it, by amount at the frame's edges and less toward its middle, as a cheap lens splits colors.

```haxe
function new(?amount:Float = 3.)
var amount(default, set):Float
```

- `new`: Colors parted by amount pixels at the edges.
- `amount`: How far red and blue part from green at the frame's edges, each its way, in the frame's pixels, 0 (none) to 64: 3 by default.

## ColorLut

*class* in `src/helix/shaders/ColorLut.hx`

A color grade, a screen effect of the library: the frame's colors looked up in a 32 x 32 x 32 color cube (a LUT) laid out as a strip of SIZE squares, 1024 x 32 texels: blue chooses a square left to right, red runs across it, green down it, and each texel holds what that color becomes (sRGB). A grade is made by grading identity()'s strip in an image editor with the game's look and loading the PNG (linear sampling; Textures2D.load). Put it after the tone mapping, as the colors it grades are the screen's.

```haxe
function new(?lut:Texture2D)
static var SIZE(inline, null):Int
static function identity():haxe.io.Bytes
var lut(default, set):Null<Texture2D>
var amount(default, set):Float
```

- `new`: A grade through lut (a strip as above, sampled linear), or the identity strip until a lut is given.
- `SIZE`: The cube's size: SIZE values of each channel, so the strip is SIZE * SIZE x SIZE texels.
- `identity`: The identity strip's texels, RGBA8, rows top first (SIZE * SIZE x SIZE): each color itself, its channels i * 255 / 31 rounded.
- `lut`: The strip it looks colors up in, or null for the identity (the library's, ShaderLibrary.getIdentityLut: the frame unchanged). The texture stays its owner's.
- `amount`: How much of the grade shows, 0 (the frame as it is) to 1 (all of it): 1 by default.

## Crt

*class* in `src/helix/shaders/Crt.hx`

CRT, a screen effect of the library: the frame as an old monitor shows it, its glass curved (black beyond the bent frame), dark lines between its rows, an aperture grille (columns of red, green and blue), and a flicker over the effect's time.

```haxe
function new()
var lines(default, set):Float
var darkness(default, set):Float
var curvature(default, set):Float
var mask(default, set):Float
var maskSize(default, set):Float
var flicker(default, set):Float
```

- `new`: A CRT of 240 lines, darkness .35, curvature .3, mask .3 of columns a pixel wide, flicker .5.
- `lines`: The rows down the frame, 1 to 4096: 240 by default.
- `darkness`: How dark the lines between rows go, 0 (none) to 1 (black): .35 by default.
- `curvature`: How far the glass bends, 0 (flat) to 1: .3 by default.
- `mask`: How strong the aperture grille is, 0 (none) to 1: .3 by default.
- `maskSize`: A grille column's width, in the frame's pixels, 1 to 64: 1 by default.
- `flicker`: How much the brightness wobbles over time, 0 (steady) to 1 (6% either way): .5 by default.

## Dissolve

*class* in `src/helix/shaders/Dissolve.hx`

A library surface shader: the material shaded as the stage shades it, burnt away where a noise texture is below a threshold rising with amount, with a glowing edge along the cut; its shadow is cut away with it. The noise is laid over the model at rest in its own space (helix_model_position: a skinned model's bind pose), read along the three planes of that space and blended by the surface's facing (triplanar), so the holes stay where they are on the body as it moves and animates, whatever its texture coordinates, and every GPU reads the same noise. The noise is the library's (ShaderLibrary.getNoise) unless the game gives its own. Made on a material, it is that material's surface shader from then on (LibrarySurface); make the material doubleSided to see its inside through the holes.

```haxe
function new(material:Material3D)
var amount(default, set):Float
var edgeColor(default, set):Int
var edgeIntensity(default, set):Float
var edgeWidth(default, set):Float
var scale(default, set):Float
var noise(default, set):Texture2D
```

- `new`: Makes Dissolve material's surface shader: whole, an orange edge .08 wide, the library's noise repeating every unit.
- `amount`: How much is burnt away, 0 (whole, by default) to 1 (gone). Clamped to 0..1 (NaN is 0).
- `edgeColor`: The glowing edge's color, 0xAARRGGBB (sRGB): its alpha how much of the edge shows, what's behind the model through the rest (dithered: a share of its pixels thrown away in a fixed pattern, so the model stays opaque and its shadow alike); opaque orange by default.
- `edgeIntensity`: How bright the edge glows: its color times this, 0 or more (past 1 brighter than white light): 4 by default. Under 0, or NaN, is 0.
- `edgeWidth`: How wide the edge glows, in the noise's values (0..1) past the threshold, .001 to 1: .08 by default. Clamped to .001..1 (NaN is .001).
- `scale`: How many times the noise repeats per unit of the model's own space (its mesh's, before the model's placing and scale), above 0: 1 by default, the library's noise's 8 cells across then each an eighth of a unit. Under .001, or NaN, is .001.
- `noise`: The noise it burns along (its red channel, sampled as its sampling says: repeating, for scale to tile it): the library's by default.

## Fxaa

*class* in `src/helix/shaders/Fxaa.hx`

FXAA, a screen effect of the library: Timothy Lottes's FXAA 3.11 (its quality version, preset 12), smoothing the stair steps along edges in the finished frame by the contrast of its luma, which it works out itself. Put it after the tone mapping (in an HDR chain, after the last effect wanting HDR: PostProcess runs the tone mapping there) and before effects that add their own detail (grain, scanlines), so what it smooths is the frame as shown.

```haxe
function new()
var subpixel(default, set):Float
var edgeThreshold(default, set):Float
var edgeThresholdMin(default, set):Float
```

- `new`: FXAA at its defaults: subpixel .75, edgeThreshold .166, edgeThresholdMin .0833.
- `subpixel`: How much edges thinner than a pixel are smoothed, 0 (sharper; none) to 1 (softer): .75 by default.
- `edgeThreshold`: The least contrast smoothed, a share of the brightest luma around a pixel, .063 (slower, more edges) to .333 (faster, fewer): .166 by default.
- `edgeThresholdMin`: The least contrast smoothed in all, so dark areas are left alone, 0 to .1 (luma): .0833 by default.

## HitFlash

*class* in `src/helix/shaders/HitFlash.hx`

A material's hit flash: a color mixed over its light, all of it at a trigger and fading to none over some seconds of the stage's time (Renderer3D.time, which the app advances, as its particles do), or an amount held. Every material has one, off until a HitFlash shows it, drawn by the stage's own shading and every library surface shader alike (an app's surface shader shows it through helix_output too), mixed in after the exposure, so the tone mapping applies to it as to the light. A HitFlash is a view of its material's: two on one material share it.

```haxe
function new(material:Material3D)
var material(default, null):Material3D
var color(get, set):Int
var amount(get, set):Float
function trigger(color:Int, seconds:Float):Bool
```

- `new`: Shows material's hit flash: none until triggered or an amount is held.
- `material`: The material it flashes.
- `color`: The flash's color, 0xAARRGGBB (sRGB), its alpha how strong at most. White by default.
- `amount`: How much of the flash is held, 0 to 1 (times its color's alpha): 0, none, by default. Assigning holds it, ending a fade; read during a fade, it's the fade's start, 1. Clamped to 0..1 (NaN is 0).
- `trigger`: Flashes color (0xAARRGGBB, sRGB, its alpha how strong) all at once, fading to nothing over seconds of the stage's time from the next draw. False, changing nothing, for seconds not above 0.

## LibraryScreenEffect

*class* in `src/helix/shaders/LibraryScreenEffect.hx`

What the shader library's screen effects share (Bloom, Fxaa, Blur, Vignette, ColorLut, Crt, ChromaticAberration, Pixelate, Tonemap): a ScreenEffect whose shader is the library's, built on the program's GPU (Graphics) the first time one is made and shared by every effect of its kind, and whose fields write its parameters, each held to its range. PostProcess chains them as any effect (PostProcess.add).

## LibrarySurface

*class* in `src/helix/shaders/LibrarySurface.hx`

What the shader library's surface shader classes share (Unlit, Toon, Dissolve, Water): made on a material, the class's shader is that material's surface shader from then on (Material3D.setShader), built on the program's GPU (Graphics) the first time a material asks for it, and its fields write their parameters into the material's (Material3D.shaderParameters) while the material keeps it: with another shader on the material since, a field changes nothing there. Every library surface shader shows the material's hit flash and rim light (HitFlash, Rim), as the stage's own shading does.

```haxe
var material(default, null):Material3D
var attached(get, never):Bool
```

- `material`: The material it draws.
- `attached`: Whether it is still its material's surface shader.

## Outline

*class* in `src/helix/shaders/Outline.hx`

An outline round a model: a pass (ModelPass3D) drawing the model again after the stage's opaque models, pushed out by a width in world units, its front faces culled, so the far side of that shell shows as a band past the model's edges, in a flat color; depth tested, so what's nearer covers it. Static or skinned, instanced like the model. Each vertex is pushed along its normal averaged over the vertices at its place (Mesh3D.passVertices), so where a low-poly model's normals split at its hard edges the shell stays closed; a flat face between hard edges moves out less than the width (a cube's by .58 of it, its corners along their diagonals). A model's separate meshes are pushed apart each on its own. Made on a model, it draws from then on; remove takes it off.

```haxe
function new(model:Model3D, ?color:Int = 0xff000000, ?width:Float = .02)
var width(get, set):Float
```

- `new`: Outlines model in color (0xAARRGGBB, sRGB: black by default; its alpha ignored, an outline is opaque), width world units wide (.02 by default; under 0 is 0).
- `width`: How far the outline reaches past the model's surface, world units, 0 or more. Under 0, or NaN, is 0.

## PaletteSwap

*class* in `src/helix/shaders/PaletteSwap.hx`

A sprite effect of the library: the sprite drawn in a palette's colors. Its texels' red channel (0..255) is a column of the palette, a texture a row a variant (a game's PNG: the first row the colors as drawn, a row below for each swap), and row chooses which; the sprite's alpha is kept, times the palette's, and both are times the tint. The sprite and the palette are read texel by texel at exact texel centers, whatever either's sampling, so an index never blends with its neighbor; a red past the palette's width takes its last column. Shared by the sprites given it (SpriteEffect): a sprite of another variant has a PaletteSwap of its own. Built on the program's GPU (Graphics) the first time one is made.

```haxe
function new(palette:Texture2D, ?row:Int = 0)
var palette(default, set):Texture2D
var row(default, set):Int
```

- `new`: The sprite in palette's colors, its row row (0 by default).
- `palette`: The palette: a column an index, a row a variant.
- `row`: The palette's row drawn, 0 (its top, by default) or more; one past its last draws its last. Under 0 is 0.

## Pixelate

*class* in `src/helix/shaders/Pixelate.hx`

Pixelate, a screen effect of the library: the frame in square cells, each one color, the frame's at the cell's middle.

```haxe
function new(?cellSize:Int = 6)
var cellSize(default, set):Int
```

- `new`: Cells cellSize pixels a side.
- `cellSize`: A cell's side, in the frame's pixels, 1 (the frame as it is) to 256: 6 by default.

## Rim

*class* in `src/helix/shaders/Rim.hx`

A material's rim light: a color brightest where its surface turns away from the viewer, round its edge, added to its light. Every material has one, off until a Rim turns it on, drawn by the stage's own shading and every library surface shader alike (an app's surface shader shows it through helix_output too). A Rim is a view of its material's: two on one material share it.

```haxe
function new(material:Material3D, ?color:Int = 0x80ffffff, ?power:Float = 3.)
var material(default, null):Material3D
var color(get, set):Int
var power(get, set):Float
```

- `new`: Turns material's rim light on: color (0xAARRGGBB, sRGB, its alpha how strong) and power (.1 to 64, clamped).
- `material`: The material it lights.
- `color`: The rim's color, 0xAARRGGBB (sRGB), its alpha how strong (0 none, 255 all of it).
- `power`: How tight the rim keeps to the edge, .1 to 64: 1 spreads it over the surface, 3 a rim, 8 a thin line. Clamped to .1..64 (NaN is .1).

## ShaderLibrary

*class* in `src/helix/shaders/ShaderLibrary.hx`

The shader library's programs on each GPU. A library shader's source (src/helix/shaders/*.glsl) is packed at build time into generated Haxe holding its .hxshader (src/helix/tools/shader/ShaderPacker.hx: <Name>Packed.text()), so a class in helix.shaders gets its shader at once, with no load and no asset, and a shader nothing uses is left out of the build. Each is built the first time it's asked for on a GPU and kept, shared by everything drawing with it, until the runner releases the GPU's. In development a hot reload brings the shaders packed again from changed sources, and each built is built again in place, as Shaders does an app's.

```haxe
static function get(gpu:IGraphics, name:String, text:String):Shader
static var NOISE_SIZE(inline, null):Int
static function getNoise(gpu:IGraphics):Texture2D
static function getIdentityLut(gpu:IGraphics):Texture2D
static function noisePixels():haxe.io.Bytes
static function release(gpu:IGraphics):Void
```

- `get`: The library shader name (its source's file stem: "unlit") on gpu, built from text (its packed .hxshader, <Name>Packed.text()) the first time it's asked for there. Throws, saying why, for a program that doesn't build.
- `NOISE_SIZE`: The size of the library's noise texture, texels a side.
- `getNoise`: The library's noise texture on gpu (Dissolve's unless a game gives its own), made the first time it's asked for there: NOISE_SIZE texels a side, tiling, smooth value noise of three octaves in its red, green and blue alike, its values spread evenly over 0..1 (so a threshold at t keeps the share 1 - t of it); the same texels on every target. Sampled linear, repeating. The library frees it with its shaders.
- `getIdentityLut`: The identity color LUT on gpu (ColorLut's until a game gives its own grade), made the first time it's asked for there from ColorLut.identity(): every color itself. Sampled linear, clamped. The library frees it with its shaders.
- `noisePixels`: The noise texture's texels (getNoise), RGBA8, rows top first.
- `release`: Frees gpu's library shaders, the pipelines made over them, its noise texture and its identity LUT, before the adapter shuts down.

## Silhouette

*class* in `src/helix/shaders/Silhouette.hx`

A model seen through what hides it: a pass (ModelPass3D) drawing the model's shape where something nearer hides it (depth greater), in a flat color blended by its alpha, over the stage's other opaque models and sprites; the model itself is drawn after it, so its own parts never hide it (layered clothes, hair over a head). Static or skinned, instanced like the model. Made on a model, it draws from then on; remove takes it off.

```haxe
function new(model:Model3D, ?color:Int = 0x993fa9ff)
```

- `new`: Shows model where it's hidden in color (0xAARRGGBB, sRGB, blended by its alpha): a light blue at 60% by default.

## SpriteDissolve

*class* in `src/helix/shaders/SpriteDissolve.hx`

A sprite effect of the library: the sprite burnt away where a noise texture, laid across its region, is below a threshold rising with amount, with a glowing edge along the cut. The noise is the library's (ShaderLibrary.getNoise) unless the game gives its own. Shared by the sprites given it (SpriteEffect). Built on the program's GPU (Graphics) the first time one is made.

```haxe
function new()
var amount(default, set):Float
var edgeColor(default, set):Int
var edgeWidth(default, set):Float
var scale(default, set):Float
var noise(default, set):Texture2D
```

- `new`: Whole, an orange edge .1 wide, the library's noise once across.
- `amount`: How much is burnt away, 0 (whole, by default) to 1 (gone). Clamped to 0..1 (NaN is 0).
- `edgeColor`: The edge's color, 0xAARRGGBB (sRGB, its alpha how much of it over the sprite's): orange by default.
- `edgeWidth`: How wide the edge glows, in the noise's values (0..1) past the threshold, .001 to 1: .1 by default. Clamped to .001..1 (NaN is .001).
- `scale`: How many times the noise repeats across the sprite's region, above 0: 1 by default. Under .001, or NaN, is .001.
- `noise`: The noise it burns along (its red channel, sampled as its sampling says: repeating, for scale to tile it): the library's by default.

## SpriteFlash

*class* in `src/helix/shaders/SpriteFlash.hx`

A sprite effect of the library: a color mixed over the sprite's (its alpha kept), all of it at a trigger and fading to none over some seconds of the batch's time (Batch2D.time; a Renderer2D's time), as a hit flashes a sprite, or an amount held. Shared by the sprites given it (SpriteEffect): each sprite flashing on its own has a SpriteFlash of its own. Built on the program's GPU (Graphics) the first time one is made.

```haxe
function new()
var color(default, set):Int
var amount(get, set):Float
function trigger(color:Int, seconds:Float):Bool
function prepare(time:Float):Void
```

- `new`: No flash until triggered or an amount is held.
- `color`: The flash's color, 0xAARRGGBB (sRGB, its alpha how strong at most). White by default.
- `amount`: How much of the flash is held, 0 to 1 (times its color's alpha): 0, none, by default. Assigning holds it, ending a fade; read during a fade, it's the fade's start, 1. Clamped to 0..1 (NaN is 0).
- `trigger`: Flashes color (0xAARRGGBB, sRGB, its alpha how strong) all at once, fading to nothing over seconds of the batch's time from the next draw. False, changing nothing, for seconds not above 0.
- `prepare`: Brings a fade to time (seconds of the batch's clock): its start the first time after a trigger.

## SpriteOutline

*class* in `src/helix/shaders/SpriteOutline.hx`

A sprite effect of the library: the sprite's shape outlined in a color, a width of texels out from its edge (eight reads around each pixel: the sides and the diagonals). The outline is drawn where the sprite's region is see-through, so a sprite needs that much transparent margin around its shape; what lies past its region in an atlas is never read. Shared by the sprites given it (SpriteEffect). Built on the program's GPU (Graphics) the first time one is made.

```haxe
function new(?color:Int = 0xff000000, ?width:Float = 1.)
var color(default, set):Int
var width(default, set):Float
```

- `new`: An outline of color (0xAARRGGBB, black by default) width texels wide (1 by default).
- `color`: The outline's color, 0xAARRGGBB (sRGB, its alpha how opaque), faded with each sprite's tint's alpha.
- `width`: How far it reaches out from the shape, in the sprite's texels, 0 (none) to 32. Clamped to 0..32 (NaN is 0).

## Tonemap

*class* in `src/helix/shaders/Tonemap.hx`

An HDR chain's tone mapping, a screen effect of the library: the frame's light (a stage's after its exposure, drawn into a half-float scene as sRGB values running past 1) brought into the screen's 0..1 by mode, as Renderer3D does drawing straight to the screen, and written as the screen's sRGB. It wants HDR itself (ScreenEffect.hdr). PostProcess adds one after the last effect wanting HDR, with its stage's mode, to a chain that has none; one added by hand runs where it's added, with its own mode, and only in an HDR chain. Built on the program's GPU (Graphics) the first time one is made.

```haxe
function new()
static var MAX_LIGHT(inline, null):Float
static function map(mode:Tonemap, linear:Array<Float>):Array<Float>
var mode(default, set):Tonemap
function computeHdrColor(color:Int, out:Array<Float>):Void
```

- `new`: A tone mapping by Khronos PBR Neutral.
- `MAX_LIGHT`: The most linear light computeHdrColor answers with, for a color the mode never reaches (Neutral never reaches 1): Neutral shows it as white written in 8 bits.
- `map`: linear (red, green, blue light) tone mapped by mode as the shader does it, into 0..1, a new array.
- `mode`: How the light comes into 0..1 (helix.render3d.Tonemap's modes, as Renderer3D.tonemap): Khronos PBR Neutral to start.
- `computeHdrColor`: Fills out (its first four) with what an HDR frame holds where this tone mapping shows color (0xAARRGGBB): red, green and blue as sRGB values running past 1, alpha as given, 0 to 1. PostProcess clears an HDR scene to it, so a background of clear color alone looks the same with and without an HDR chain. Solved on the CPU (this tone mapping as the shader works it, one channel at a time by bisection, round after round, as the modes mix the channels a little), no channel past MAX_LIGHT. A color the mode can't show comes as near as it lets: Neutral desaturates what nears white, so a bright saturated color (0xffff2000) is shown paler.

## Toon

*class* in `src/helix/shaders/Toon.hx`

A library surface shader: the stage's lights in a few flat bands over the material's base color and texture (their shadows banded with them), its unlit side no darker than a shadow color, and its emission; with a rim of light round its edge (the material's Rim, which it turns on). Made on a material, it is that material's surface shader from then on (LibrarySurface).

```haxe
function new(material:Material3D)
var bands(default, set):Int
var shadowColor(default, set):Int
var rim(default, null):Rim
```

- `new`: Makes Toon material's surface shader: 3 bands, the shadow color dark blue grey, a rim of light.
- `bands`: How many levels of light there are, 1 to 16: 3 by default. Clamped to 1..16.
- `shadowColor`: The least light the surface shows, its unlit side's, 0xAARRGGBB (sRGB, alpha ignored): the material's color times this where no light reaches. A dark blue grey by default.
- `rim`: Its rim of light: the material's rim light (Rim), on to start, white at a third, power 3.

## Unlit

*class* in `src/helix/shaders/Unlit.hx`

A library surface shader: a material drawn without light, its base color and texture times color, and its emission, under the stage's exposure and tone mapping as a material that isn't lit is. Made on a material, it is that material's surface shader from then on (LibrarySurface).

```haxe
function new(material:Material3D)
var color(default, set):Int
```

- `new`: Makes Unlit material's surface shader, color white.
- `color`: What the material's base color and texture are multiplied by, 0xAARRGGBB, its color sRGB as the material's are: white (the material as it is) by default.

## Vignette

*class* in `src/helix/shaders/Vignette.hx`

Vignette, a screen effect of the library: the frame shaded toward color from radius out to its corners.

```haxe
function new(?strength:Float = .4)
var strength(default, set):Float
var color(default, set):Int
var radius(default, set):Float
var softness(default, set):Float
```

- `new`: A black vignette of strength (0..1), from .4 of the way to a corner, softness .6.
- `strength`: How far the corners go toward color, 0 (none) to 1 (all the way): .4 by default.
- `color`: What the corners go toward, 0xAARRGGBB (sRGB as the frame is, alpha ignored): black by default.
- `radius`: Where the shading starts, a share of the way from the middle to a corner, 0 to 1: .4 by default.
- `softness`: How far past radius the shading takes to reach its strength, the same share, .001 (a hard edge) to 2: .6 by default.

## Water

*class* in `src/helix/shaders/Water.hx`

A library surface shader: travelling waves moving the surface along its normals (a vertex hook: the model needs vertices enough to show them), colored deep where it's looked into and shallow toward grazing, lit by the stage's lights with their glints, reflecting the stage's environment (or a sky color without one) at grazing angles; its shadow moves with its waves. The material's base color's alpha is its alpha (a blended material is see-through). Made on a material, it is that material's surface shader from then on (LibrarySurface).

```haxe
function new(material:Material3D)
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
- `deepColor`: Its color looked straight into, 0xAARRGGBB (sRGB, alpha ignored): a deep blue by default.
- `shallowColor`: Its color toward grazing, 0xAARRGGBB (sRGB, alpha ignored): a green blue by default.
- `skyColor`: What it reflects at grazing angles when the stage has no environment, 0xAARRGGBB (sRGB, alpha ignored): a pale sky by default.
- `shininess`: How tight the lights' glints are, 1 to 2048: 120 by default. Clamped to 1..2048 (NaN is 1).
