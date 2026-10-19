# helix.render2d

[Back to the index](README.md)

## Align2D

*abstract* in `src/helix/render2d/Align2D.hx`

Which point of a line of text its x names: its left edge, center or right edge.

## BakedFont

*typedef* in `src/helix/render2d/FontBaker.hx`

A font's characters baked into one distance-field atlas: a byte a texel, 128 on the outline, rising inward and falling outward by 128 / padding a pixel.

- `width:Int`
- `scale:Float`
- `pixelHeight:Float`
- `lineGap:Float`
- `height:Int`
- `glyphs:Array<BakedGlyph>`
- `field:haxe.io.Bytes`
- `descent:Float`
- `ascent:Float`

## BakedGlyph

*typedef* in `src/helix/render2d/FontBaker.hx`

A baked glyph: its place in the atlas, its box's offset from the pen on the baseline (y down) and its advance, in pixels at the baked height. A glyph with nothing to draw (a space) has no size.

- `yOffset:Int`
- `y:Int`
- `xOffset:Int`
- `x:Int`
- `width:Int`
- `height:Int`
- `code:Int`
- `advance:Float`

## Batch2D

*class* in `src/helix/render2d/Batch2D.hx`

Immediate 2D drawing in world units through a Camera2D, inside a frame (IGraphics.beginFrame to endFrame). A batch is one upload and one draw per run of a texture, camera and effect, drawn over whatever the frame has so far, without depth. Colors are 0xRRGGBBAA. A transform (setTransform) places what follows, so a shape or text can be drawn turned and scaled; a Stage2D draws its nodes so. What is drawn with an effect (effect: a sprite shader) goes through it in place of the framework's sprite program, its vertices in an upload of their own.

```haxe
function new(?gpu:IGraphics, ?maxVertices:Int = 32768)
var vertexCount(get, never):Int
var drawCallCount(get, never):Int
var font(default, null):Font2D
function begin(camera:Camera2D):Void
var camera(default, set):Camera2D
var effect(default, set):Null<SpriteEffect>
var time:Float
var transformA(get, never):Float
var transformB(get, never):Float
var transformC(get, never):Float
var transformD(get, never):Float
var transformX(get, never):Float
var transformY(get, never):Float
function setTransform(a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float):Void
function resetTransform():Void
function end():Void
function pushClip(x:Float, y:Float, w:Float, h:Float):Void
function popClip():Void
function useTexture(value:Texture2D):Void
function quad(x:Float, y:Float, w:Float, h:Float, u0:Float, v0:Float, u1:Float, v1:Float, tint:Int, ?distanceField:Bool = false):Void
function sprite(texture:Texture2D, x:Float, y:Float, width:Float, height:Float, ?rotation:Float = 0., ?tint:Int = 0xffffffff, ?u0:Float = 0., ?v0:Float = 0., ?u1:Float = 1., ?v1:Float = 1.):Void
function image(texture:Texture2D, x:Float, y:Float, width:Float, height:Float, ?tint:Int = 0xffffffff, ?sourceX:Float = 0., ?sourceY:Float = 0., ?sourceWidth:Float = 0., ?sourceHeight:Float = 0.):Void
function nineSlice(texture:Texture2D, x:Float, y:Float, width:Float, height:Float, left:Float, top:Float, right:Float, bottom:Float, ?tint:Int = 0xffffffff, ?sourceX:Float = 0., ?sourceY:Float = 0., ?sourceWidth:Float = 0., ?sourceHeight:Float = 0.):Void
function emitter(emitter:Emitter):Void
function drawText(text:String, x:Float, y:Float, size:Float, color:Int, ?align:Align2D = Left, ?font:Font2D):Void
function drawTextWrapped(text:String, x:Float, y:Float, size:Float, width:Float, color:Int, ?align:Align2D = Left, ?lineHeight:Float = 1.25, ?font:Font2D):Float
function rect(x:Float, y:Float, w:Float, h:Float, tint:Int):Void
function triangle(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, tint:Int):Void
function line(x0:Float, y0:Float, x1:Float, y1:Float, width:Float, tint:Int):Void
function frame(x:Float, y:Float, w:Float, h:Float, width:Float, tint:Int):Void
function roundedRect(x:Float, y:Float, w:Float, h:Float, radius:Float, tint:Int):Void
function roundedFrame(x:Float, y:Float, w:Float, h:Float, radius:Float, width:Float, tint:Int):Void
function circle(x:Float, y:Float, radius:Float, tint:Int):Void
function circleLines(x:Float, y:Float, radius:Float, width:Float, tint:Int):Void
function triangleLines(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, width:Float, tint:Int):Void
function polygon(points:Array<Float>, tint:Int, ?triangles:Array<Int>):Void
function polygonLines(points:Array<Float>, width:Float, tint:Int):Void
function destroy():Void
```

- `new`: A batch of up to maxVertices vertices a frame, with its own buffer, pipeline and pixel font on gpu; cleanup frees them. Without gpu, the program's (Graphics.instance).
- `vertexCount`: Vertices of the frame drawn last, those drawn through effects among them.
- `drawCallCount`: Draws of the frame drawn last: one per run of a texture, camera and effect.
- `font`: The built-in pixel font, whose texture also has the white texel shapes use.
- `begin`: Starts collecting a batch seen through camera, with no transform; later calls only fill it until end.
- `camera`: The camera what follows is seen through, in its viewport: a world and a HUD in one batch.
- `effect`: The effect what follows is drawn through (a sprite shader: helix.shaders' SpriteOutline and the others, or an app's), or null (the default, and again at begin) for the framework's sprite program. Sprites, text and shapes alike: each is drawn through it with its region (a quad's texture coordinates; a nine-slice's whole region; a shape's white texel). One effect drawn from one sprite to the next stays one draw, as one texture does; its parameters are read as end draws.
- `time`: The clock its effects see, seconds (helix_time() in a sprite shader, a SpriteFlash's fade): read as end draws. A Stage2D's draw sets it to the stage's time.
- `transformA`: The transform's a: x's share of a point's x.
- `transformB`: The transform's b: x's share of a point's y.
- `transformC`: The transform's c: y's share of a point's x.
- `transformD`: The transform's d: y's share of a point's y.
- `transformX`: The transform's x offset, world units.
- `transformY`: The transform's y offset, world units.
- `setTransform`: Places what follows: a point x, y it is given is drawn at a * x + c * y + tx, b * x + d * y + ty in world units.
- `resetTransform`: What follows is drawn where it is given, in world units.
- `end`: Draws the batch in the open frame: one upload of every vertex (and one of those drawn through effects) and one draw per run of a texture, camera and effect, each in its camera's viewport. Once a frame.
- `pushClip`: Clips what follows to the rectangle x, y, w, h of the world units it would be drawn in now (through the transform and the camera; a turned one's bounds), within any clip already pushed, until popClip.
- `popClip`: Ends the clip pushClip began; what follows is clipped as before it. Nothing with no clip pushed.
- `useTexture`: Later quads sample this texture, as its sampling is now (Texture2D.sampling).
- `quad`: A textured rectangle in world units, top-left at x, y, sampling u0, v0 to u1, v1 of the current texture, tinted. With distanceField, the texture's alpha is a distance from an outline (Font2D.distanceField), drawn with a smooth edge at any scale. Throws when the frame's vertices pass capacity, as every shape does.
- `sprite`: texture drawn centered on x, y, width x height in world units, turned rotation radians (clockwise on screen), sampling u0, v0 to u1, v1 of it (the whole texture by default), tinted (0xRRGGBBAA, white by default). Throws when the frame's vertices pass capacity.
- `image`: texture drawn top-left at x, y, width x height in world units, tinted (white by default): the region sourceX, sourceY, sourceWidth x sourceHeight of it in texels, or the whole texture when sourceWidth or sourceHeight is 0 or less. Sampled as the texture's sampling is now.
- `nineSlice`: Draws texture's region sourceX, sourceY, sourceWidth x sourceHeight (texels; the whole texture when not given) as a frame filling x, y, width x height in world units: its corners left, top, right and bottom texels in from its edges keep their size (a texel a unit; shrunk alike when the frame is smaller than they are), its edges stretch along them and its middle both ways. A panel or button of any size from one image.
- `emitter`: Draws emitter's particles here in the batch's order (over what came before, under what comes after), through its camera: their places are world units (the batch's transform doesn't move them; they were born where their emitter was), the quads square to the screen. An emitter with nothing to draw draws nothing.
- `drawText`: Draws one line of text, its top at y and x its left edge, center or right edge by align, size world units tall (ascent to descent), tinted color (0xRRGGBBAA), in font or the batch's built-in one. Characters without a glyph are skipped.
- `drawTextWrapped`: Draws text wrapped to width (Font2D.wrap), its lines lineHeight times size apart, the first's top at y, each placed by align at x, as drawText draws a line. Returns the height its lines take, so what follows can go under them (a HUD's lines on a narrow screen).
- `rect`: A filled rectangle in world units, top-left at x, y.
- `triangle`: A filled triangle through three world points.
- `line`: A segment width world units wide, centered on its ends with square ends; nothing for a segment of length 0.
- `frame`: Rectangle outline drawn inside its bounds.
- `roundedRect`: A filled rectangle with corners of radius world units (clamped to half the shorter side), with segments for their size on screen.
- `roundedFrame`: A rounded rectangle's outline drawn inside its bounds, width wide: its inside's corners a radius less width, sharing their centers.
- `circle`: A filled circle in world units, centered on x, y, with segments for its size on screen.
- `circleLines`: Circle outline drawn inside its radius.
- `triangleLines`: Triangle outline drawn along its edges.
- `polygon`: A filled polygon through points (x and y in turn, at least 3), convex or not, as triangles of their indices (Polygon2D.triangulate's, three a triangle; worked out here when null: keep them for a polygon drawn every frame).
- `polygonLines`: A polygon's outline, closed, width world units wide centered on its edges, its corners mitered (a miter longer than twice the width is cut to that). Nothing for fewer than 2 points.
- `destroy`: Frees the buffers and font made by new; the batch is unusable after.

## Camera2D

*class* in `src/helix/render2d/Camera2D.hx`

A 2D view: the world point at the viewport's center and how many pixels a world unit covers (across and down alike, but under a Presentation that stretches). Y grows downward. The viewport is the whole framebuffer, or an area of it (setViewportArea).

```haxe
function new()
var x(default, null):Float
var y(default, null):Float
function setPosition(x:Float, y:Float):Void
var zoom(default, set):Float
var zoomY(default, set):Float
var framebufferWidth(default, null):Int
var framebufferHeight(default, null):Int
var viewportX(default, null):Int
var viewportY(default, null):Int
var viewportWidth(default, null):Int
var viewportHeight(default, null):Int
function setViewport(width:Int, height:Int):Void
function setViewportArea(x:Int, y:Int, width:Int, height:Int):Bool
function fit(left:Float, top:Float, width:Float, height:Float):Bool
function pixels(scale:Float):Bool
function screenToWorldX(px:Float):Float
function screenToWorldY(py:Float):Float
function worldToScreenX(wx:Float):Float
function worldToScreenY(wy:Float):Float
var clipX(inline, null):(wx:Float) -> Float
var clipY(inline, null):(wy:Float) -> Float
```

- `new`: A camera at world 0, 0, zoom 1, on a 1 x 1 viewport.
- `x`: The world X at the viewport's center.
- `y`: The world Y at the viewport's center.
- `setPosition`: Puts the world point x, y at the viewport's center.
- `zoom`: Framebuffer pixels per world unit across; assigning it sets the zoom down too (zoomY). At least 1e-6 (0 or less, or NaN, is 1e-6).
- `zoomY`: Framebuffer pixels per world unit down: zoom's, unless assigned apart after it (a stretched view: Presentation's Stretch). At least 1e-6 (0 or less, or NaN, is 1e-6).
- `framebufferWidth`: The framebuffer width in pixels, from setViewport.
- `framebufferHeight`: The framebuffer height in pixels, from setViewport.
- `viewportX`: The viewport's left edge in framebuffer pixels from the framebuffer's left.
- `viewportY`: The viewport's top edge in framebuffer pixels from the framebuffer's top.
- `viewportWidth`: The viewport width in framebuffer pixels.
- `viewportHeight`: The viewport height in framebuffer pixels.
- `setViewport`: The framebuffer it draws to, width x height pixels, all of it the viewport; a size under 1 clamps to 1.
- `setViewportArea`: Narrows the viewport to an area of the framebuffer last given to setViewport: x, y is its top-left in framebuffer pixels from the framebuffer's top-left. The next setViewport takes the whole framebuffer again. False, changing nothing, for a width or height under 1 or an area not inside the framebuffer.
- `fit`: Show a world rectangle whole and centered; the longer screen side shows extra world. False for a width or height of 0 or less.
- `pixels`: World units are logical pixels from the viewport's top-left: scale is the pixel ratio (framebuffer pixels per logical pixel). False for a scale of 0 or less.
- `screenToWorldX`: The world X under framebuffer pixel X px, from the framebuffer's left edge.
- `screenToWorldY`: The world Y under framebuffer pixel Y py, from the framebuffer's top edge.
- `worldToScreenX`: The framebuffer pixel X, from the framebuffer's left edge, of world X wx.
- `worldToScreenY`: The framebuffer pixel Y, from the framebuffer's top edge, of world Y wy.
- `clipX`: Clip-space X (-1 left to 1 right) of world X wx.
- `clipY`: Clip-space Y (1 top to -1 bottom) of world Y wy; the flip makes world Y grow downward.

## Font2D

*class* in `src/helix/render2d/Font2D.hx`

A font for text (Batch2D.drawText, a Text2D node): its characters as glyphs in one texture. builtIn() is JetBrains Mono's printable ASCII as a distance field, sharp at any size; fromTrueType() any TrueType font's printable ASCII and Latin-1, baked the same way (Fonts loads them from files), with its kerning; pixel() a 5x7 bitmap font. Sizes are in font pixels: the size the font was made at, which text is scaled from to the size asked for.

```haxe
static function fromTrueType(gpu:IGraphics, data:haxe.io.Bytes, ?pixelHeight:Float = 32., ?padding:Int = 6):Font2D
static function builtIn(gpu:IGraphics):Font2D
static function pixel(gpu:IGraphics):Font2D
var texture(default, null):Texture2D
var size(default, null):Float
var ascent(default, null):Float
var descent(default, null):Float
var distanceField(default, null):Bool
function getGlyph(code:Int):Null<Glyph2D>
function getKerning(left:Int, right:Int):Float
function measure(text:String, size:Float):Float
function wrap(text:String, size:Float, width:Float):Array<String>
function measureWrapped(text:String, size:Float, width:Float, ?lineHeight:Float = 1.25):Float
function destroy(gpu:IGraphics):Void
```

- `fromTrueType`: A font from a TrueType file's bytes: its printable ASCII and Latin-1 characters baked at pixelHeight (ascent to descent) into a distance field with padding pixels around each glyph (FontBaker), sharp from small text to about four times pixelHeight. Throws, saying why, for a file it can't read. The caller destroys it.
- `builtIn`: The built-in font: JetBrains Mono's printable ASCII as a distance field, baked by tools/bake_fonts.py (SIL OFL 1.1, see THIRD_PARTY_NOTICES.md).
- `pixel`: The 5x7 pixel font: crisp at whole multiples of 7, blocky between. Its texture also carries a white texel for shapes.
- `texture`: The texture holding every glyph, with a white texel for untextured shapes.
- `size`: The height the font was made at, ascent to descent, in font pixels: a text's size scales this.
- `ascent`: How far the tallest glyphs reach above the baseline, in font pixels.
- `descent`: How far glyphs reach below the baseline, in font pixels; 0 or negative.
- `distanceField`: Whether the texture's alpha is a distance from each glyph's outline (Batch2D draws it so) rather than coverage.
- `getGlyph`: A character's glyph, or null when it has none (space has an advance but nothing to draw: its glyph has no size).
- `getKerning`: How far the pen moves besides the advance between characters left and right, in font pixels: usually negative, closing a pair such as "AV". 0 for a font without kerning.
- `measure`: How far text moves the pen at size (world units, ascent to descent): its width, by its glyphs' advances and the kerning between them. Characters without a glyph count as nothing.
- `wrap`: text broken into lines no wider than width in world units at size: at spaces, and a word wider than a line within it, between its letters; a line break ("\n") always breaks. Lines keep no trailing spaces.
- `measureWrapped`: The height text takes wrapped to width at size (wrap), its lines lineHeight times size apart: what Batch2D.drawTextWrapped returns, known before drawing, for what's laid out under it (a button below a title that may wrap).
- `destroy`: Frees the font's texture on gpu, the adapter that made it.

## FontBaker

*class* in `src/helix/render2d/FontBaker.hx`

Bakes a TrueType font's characters into a signed distance field atlas, in Haxe, the same on every target: each glyph's outline is flattened into segments finer than a twentieth of a pixel, and each texel holds its signed distance to them (inside by the nonzero rule), so text drawn from it stays sharp from small to about four times the baked height. Glyphs are packed in rows, left to right.

```haxe
static function bake(font:TrueType, codes:Array<Int>, pixelHeight:Float, padding:Int, atlasWidth:Int):BakedFont
```

- `bake`: Bakes codes (characters) of font at pixelHeight (ascent to descent) with padding pixels of field around each glyph, into an atlas atlasWidth wide and as tall as it needs (a power of two), with a free last row (its last texel is set fully inside: a white texel).

## FontCache

*class* in `src/helix/render2d/FontCache.hx`

TrueType fonts loaded through the assets into Font2Ds: read and baked into a distance-field texture in Haxe (Font2D.fromTrueType), the same on every target, and baked again in place when a file changes during development. The runner's is what the Fonts static forwards to; the caller releases what it loads.

```haxe
function new(assets:IAssets, gpu:IGraphics)
function load(path:String, loaded:Font2D -> Void, ?failed:String -> Void):IRequest
function getPath(font:Font2D):Null<String>
function release(font:Font2D):Void
function reloaded(path:String, bytes:haxe.io.Bytes):Void
function shutdown():Void
```

- `new`: Loads through assets and uploads to gpu; shutdown shuts nothing down but this service.
- `load`: Loads path (a .ttf) into a font. One of loaded or failed runs once on the host thread, and neither once the request is cancelled: loaded once it is baked; failed (else the log, with the path) for a load failure or a file it can't read.
- `getPath`: The file font was loaded from, or null for one this service didn't load.
- `release`: Frees a font this service loaded, and stops reloading it.
- `reloaded`: The file behind loaded fonts changed: they're baked again in place, keeping their Font2D objects. A file that no longer reads leaves them as they were.
- `shutdown`: Frees every font still loaded and takes no more loads: a load that lands after calls nothing. The runner's, at the program's end.

## Fonts

*class* in `src/helix/render2d/Fonts.hx`

TrueType fonts from files, baked into distance fields and baked again when a file changes during development (FontCache). The program's one, a static class: each member forwards to instance, written by helix.macro.Facade from FontCache's public members with their doc comments.

```haxe
static var instance(default, null):FontCache
static function load(path:String, loaded:Font2D -> Void, ?failed:String -> Void):IRequest
static function getPath(font:Font2D):Null<String>
static function release(font:Font2D):Void
```

- `instance`: The fonts forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again.
- `load`: Loads path (a .ttf) into a font. One of loaded or failed runs once on the host thread, and neither once the request is cancelled: loaded once it is baked; failed (else the log, with the path) for a load failure or a file it can't read.
- `getPath`: The file font was loaded from, or null for one this service didn't load.
- `release`: Frees a font this service loaded, and stops reloading it.

## Glyph2D

*typedef* in `src/helix/render2d/Font2D.hx`

Where a glyph's texels are, and where it goes: x and y from the pen on the baseline (y grows down), its size, and how far the pen moves after it, in font pixels.

- `y:Float`
- `x:Float`
- `width:Float`
- `v1:Float`
- `v0:Float`
- `u1:Float`
- `u0:Float`
- `height:Float`
- `advance:Float`

## GlyphOutline

*typedef* in `src/helix/render2d/TrueType.hx`

A glyph's outline in font units (y up): closed contours, each a list of points, x and y in turn, with whether each is on the curve; two off-curve points in a row have an on-curve point between them, as TrueType draws quadratic curves.

An alias of `Array<{points:Array<Float>, onCurve:Array<Bool>}>`.

## Ktx

*class* in `src/helix/render2d/Ktx.hx`

A compressed texture as a KTX 1 file holds it: BC7, ASTC 4x4 or ETC2 RGBA8, 2D, with its mipmaps (https://registry.khronos.org/KTX/specs/1.0/ktxspec.v1.html). Read in Haxe, the same on every target; Textures loads them.

```haxe
static function read(bytes:haxe.io.Bytes):Ktx
final format:TextureFormat
final width:Int
final height:Int
final levels:Array<haxe.io.Bytes>
```

- `read`: Reads a KTX 1 file. Throws, saying why, for anything but a little-endian, 2D, BC7, ASTC 4x4 or ETC2 RGBA8 one whose levels are all there.
- `format`: The texels' format.
- `width`: Width in texels.
- `height`: Height in texels.
- `levels`: The image, then its mipmaps, each format.levelBytes of its size.

## Node2D

*class* in `src/helix/render2d/Node2D.hx`

What a Stage2D holds: a transform in a tree, with children of its own kind. A bare one is a group: it draws nothing, only a transform for its children (an empty in Blender, a dummy in 3ds Max, a null in Cinema 4D), a handle that moves or hides a set of things together, or a pivot to turn them about. The framework's kinds are its classes (Sprite2D, Shape2D, Text2D, Particles2D), each holding only its own data; a game never subclasses one, and game state lives elsewhere, the node its view (docs/DECISIONS.md, 61 and 130). Its transform is a position, a rotation in radians (clockwise on screen, y growing down) and a scale, relative to its parent; its world transform is worked out when a stage draws it, only after it or a node above it changed. Any node can clip its children (setClip).

```haxe
function new()
var parent(get, set):Null<Node2D>
function getChild(index:Int):Null<Node2D>
function find(name:String):Null<Node2D>
function addChild(child:Node2D):Bool
function addChildInPlace(child:Node2D):Bool
function removeChild(child:Node2D):Bool
var clipping(get, never):Bool
var clipWidth(default, null):Float
var clipHeight(default, null):Float
function setClip(width:Float, height:Float):Bool
function clearClip():Void
var x(get, set):Float
var y(get, set):Float
function setPosition(x:Float, y:Float):Void
var rotation(get, set):Float
var scaleX(get, set):Float
var scaleY(get, set):Float
function setScale(x:Float, y:Float):Void
function toWorldX(x:Float, y:Float):Float
function toWorldY(x:Float, y:Float):Float
function toLocalX(x:Float, y:Float):Float
function toLocalY(x:Float, y:Float):Float
```

- `new`: A group at the origin, unturned and unscaled, with no children.
- `parent`: Its parent, or null at a tree's top. Assigning a node makes this its last child as that node's addChild does, keeping this one's local transform (addChildInPlace keeps the world one); assigning null takes it from its parent as the parent's removeChild does. A node under itself or one of its own descendants is refused, leaving the tree as it was.
- `getChild`: Its child at index, in drawing order; null past the end.
- `find`: The first node named name below it (depth first, in drawing order), or null: found once and kept, never a path.
- `addChild`: Makes child its last child (drawn over the others), taking it from any parent it had, keeping child's local transform: it moves with this node as it sat under its old parent (a hat onto a head joint). addChildInPlace keeps its world transform instead. False, changing nothing, for itself or one of its own ancestors.
- `addChildInPlace`: Puts child under this node without it moving: its world transform is kept and its local one recomputed from this node's (a dropped sword picked up by a hand). addChild keeps the child's local transform instead (a hat onto a head joint). A shear the two transforms make together is lost. False, changing nothing, for itself or one of its own ancestors, or this scaled to nothing.
- `removeChild`: Takes child from its children. False when it isn't one.
- `clipping`: Whether its children are clipped (setClip).
- `clipWidth`: The clip's width in its own units, or -1 without one.
- `clipHeight`: The clip's height in its own units, or -1 without one.
- `setClip`: Clips its children (drawn and picked) to the rectangle width x height from its own origin, in its own units: a scrolling list's window. A turned node clips to the turned rectangle's bounds. Its own output isn't clipped. False, changing nothing, for a size below 0.
- `clearClip`: Stops clipping its children.
- `x`: Its position's x, relative to its parent.
- `y`: Its position's y, relative to its parent (down the screen).
- `setPosition`: Places it at x, y, relative to its parent.
- `rotation`: Its rotation in radians, clockwise on screen, relative to its parent.
- `scaleX`: Its scale along its own x; a negative scale mirrors it.
- `scaleY`: Its scale along its own y; a negative scale mirrors it.
- `setScale`: Scales it along its own x and y; a negative scale mirrors it.
- `toWorldX`: The world x of its own point x, y, as the last draw placed it.
- `toWorldY`: The world y of its own point x, y, as the last draw placed it.
- `toLocalX`: The x in its own units of world point x, y, as the last draw placed it; NaN when it is scaled to nothing.
- `toLocalY`: The y in its own units of world point x, y, as the last draw placed it; NaN when it is scaled to nothing.

## Particles2D

*class* in `src/helix/render2d/Particles2D.hx`

An emitter of particles (helix.particles.Emitter, made flat for 2D), placed here: it spawns where this node is in the world, and the stage advances it by its clock (Stage2D.time) each draw. Its particles draw at its place in the stage's order, through the GPU, and stay where they were born, so they trail as the node moves.

```haxe
function new(emitter:Emitter)
var emitter(default, null):Emitter
```

- `new`: emitter, placed here.
- `emitter`: Its emitter.

## Polygon2D

*class* in `src/helix/render2d/Polygon2D.hx`

Simple polygons as points, x and y in turn: filled by triangulating them (convex or not), outlined by mitered strips.

```haxe
static function doubleArea(points:Array<Float>):Float
static function triangulate(points:Array<Float>):Array<Int>
```

- `doubleArea`: Twice the signed area of the polygon through points: above 0 when its points go clockwise on screen (y down).
- `triangulate`: The triangles filling the simple polygon through points (at least 3, not crossing itself), as indices of points, three a triangle, by ear clipping; either winding. A polygon that crosses itself is filled as far as clipping gets.

## Shape2D

*class* in `src/helix/render2d/Shape2D.hx`

A flat shape in a color (0xRRGGBBAA), filled or outlined: a rectangle (its corners square or rounded), a circle, a line or a polygon, made by the static constructors, as they differ only in their geometry (form says which). Each form reads the values it uses: a rectangle its size, pivot and corner radius, a circle its radius, a line and a polygon their points; the others' are kept but not drawn.

```haxe
static function rectangle(width:Float, height:Float, ?color:Int = 0xffffffff):Shape2D
static function circle(radius:Float, ?color:Int = 0xffffffff):Shape2D
static function line(x0:Float, y0:Float, x1:Float, y1:Float, ?color:Int = 0xffffffff):Shape2D
static function polygon(points:Array<Float>, ?color:Int = 0xffffffff):Null<Shape2D>
var form(default, null):ShapeForm
var color:Int
var width(get, never):Float
var height(get, never):Float
function setSize(width:Float, height:Float):Void
function setPivot(x:Float, y:Float):Void
var pivotX(default, null):Float
var pivotY(default, null):Float
var radius(get, set):Float
var cornerRadius(get, set):Float
var outline(get, set):Float
var points(get, never):Array<Float>
function setPoints(value:Array<Float>):Bool
```

- `rectangle`: A filled rectangle width x height (below 0 is 0), its top-left at its position (pivot 0, 0).
- `circle`: A filled circle of radius (below 0 is 0), centered on its position.
- `line`: A line from x0, y0 to x1, y1 in its own units, as wide as its outline (1 to start).
- `polygon`: A filled polygon through points in its own units (x and y in turn, copied; at least 3 points, convex or not, not crossing itself). Null for fewer than 3 points or an odd count.
- `form`: Which shape it is.
- `color`: Its color, 0xRRGGBBAA.
- `width`: A rectangle's width, in its own units.
- `height`: A rectangle's height, in its own units.
- `setSize`: Sizes a rectangle, in its own units; below 0 is 0.
- `setPivot`: Sets the point of a rectangle at its position, which it turns and scales about, as a fraction of its size: 0, 0 its top-left (the start), 1, 1 its bottom-right.
- `pivotX`: A rectangle's pivot's x fraction.
- `pivotY`: A rectangle's pivot's y fraction.
- `radius`: A circle's radius, in its own units. At least 0 (below 0, or NaN, is 0).
- `cornerRadius`: A rectangle's corners' radius, in its own units, 0 for square (the start): drawn at most half its shorter side; outlined, the outline's middle follows the corners; picked by its rounded shape. At least 0 (below 0, or NaN, is 0).
- `outline`: Its outline's width, in its own units, centered on its edge: 0 draws a rectangle, circle or polygon filled (the start), and is a line's width (1 to start; 0 draws nothing). At least 0 (below 0, or NaN, is 0).
- `points`: A polygon's points or a line's ends, x and y in turn (a copy); empty for a rectangle or circle.
- `setPoints`: Gives a polygon new points (as polygon() takes them, copied) or a line new ends (4 floats). False, changing nothing, for a rectangle or circle or a wrong count.

## ShapeForm

*abstract* in `src/helix/render2d/Shape2D.hx`

Which shape a Shape2D is.

## Sprite2D

*class* in `src/helix/render2d/Sprite2D.hx`

A sprite: a texture (or a region of it) drawn as a rectangle, its region's size in texels unless sized, its pivot at its position (its center by default), tinted (0xRRGGBBAA). Its scale scales it and its rotation turns it, about its pivot; a nine-slice frame keeps its corners' size as it's sized (setNineSlice). It may draw through an effect (effect).

```haxe
function new(texture:Null<Texture2D>, ?tint:Int = 0xffffffff)
var texture:Null<Texture2D>
var tint:Int
var effect:Null<SpriteEffect>
function setRegion(x:Float, y:Float, width:Float, height:Float):Void
var regionX(get, never):Float
var regionY(get, never):Float
var regionWidth(get, never):Float
var regionHeight(get, never):Float
var width(get, never):Float
var height(get, never):Float
function setSize(width:Float, height:Float):Void
function setPivot(x:Float, y:Float):Void
var pivotX(default, null):Float
var pivotY(default, null):Float
function setNineSlice(left:Float, top:Float, right:Float, bottom:Float):Bool
var nineSliceLeft(get, never):Float
var nineSliceTop(get, never):Float
var nineSliceRight(get, never):Float
var nineSliceBottom(get, never):Float
var nineSlice(get, never):Bool
```

- `new`: A sprite of texture (null for none yet: it draws nothing), the whole texture at its size in texels, turning about its center, tinted (0xRRGGBBAA, white for none).
- `texture`: Its texture, or null: it draws nothing.
- `tint`: What its texels are multiplied by, 0xRRGGBBAA: white leaves them as they are.
- `effect`: The effect it draws through (a sprite shader: helix.shaders' SpriteOutline, SpriteFlash, SpriteDissolve, PaletteSwap, or an app's SpriteEffect), or null (the default) for the framework's sprite program. An effect is shared: the sprites given one draw with its values, and those drawn one after another with one effect and texture are one draw.
- `setRegion`: Its region of its texture, in texels from its top-left; a width or height of 0 or less (the default) shows the whole texture.
- `regionX`: Its region's left, in texels.
- `regionY`: Its region's top, in texels.
- `regionWidth`: Its region's width in texels: what was set, or else its texture's (0 without one).
- `regionHeight`: Its region's height in texels: what was set, or else its texture's (0 without one).
- `width`: The width it draws at, in its own units: as sized, else its region's in texels.
- `height`: The height it draws at, in its own units: as sized, else its region's in texels.
- `setSize`: Sizes it, in its own units; a width or height of 0 or less goes back to its region's size.
- `setPivot`: Sets the point at its position, which it turns and scales about, as a fraction of its size: 0, 0 its top-left, 1, 1 its bottom-right (0.5, 0.5, its center, by default).
- `pivotX`: Its pivot's x fraction.
- `pivotY`: Its pivot's y fraction.
- `setNineSlice`: Draws it as a nine-slice frame (Batch2D.nineSlice): its region's corners left, top, right and bottom texels in from its edges keep their size as it's sized, its edges and middle stretch. All 0 (the start) draws it stretched whole. False, changing nothing, for an inset below 0.
- `nineSliceLeft`: Its nine-slice's left inset, texels.
- `nineSliceTop`: Its nine-slice's top inset, texels.
- `nineSliceRight`: Its nine-slice's right inset, texels.
- `nineSliceBottom`: Its nine-slice's bottom inset, texels.
- `nineSlice`: Whether it draws as a nine-slice frame.

## Stage2D

*class* in `src/helix/render2d/Stage2D.hx`

A retained 2D scene: nodes under a root, drawn into a Batch2D by draw(batch, camera). A draw walks the tree as it is now, depth first, a parent before its children and children in order, so later ones draw over earlier ones (each world transform worked out only where something changed); it skips the nodes whose bounds are outside the camera's view, and draws the rest through the batch, which joins alike ones into runs. A frame composes its stages in the order it draws them: a backdrop, the world, then a HUD, each through its own camera.

```haxe
function new()
var root(default, null):Node2D
function add(node:Node2D):Bool
function remove(node:Node2D):Bool
var time:Float
var font(get, never):Null<Font2D>
var drawnNodeCount(get, never):Int
function draw(batch:Batch2D, camera:Camera2D):Void
function pick(camera:Camera2D, x:Float, y:Float):Null<Node2D>
```

- `new`: An empty stage.
- `root`: The node everything on the stage hangs from.
- `add`: Adds node to the stage, as the root's last child: drawn over what is there.
- `remove`: Takes node from the stage's root.
- `time`: The stage's clock, seconds: what the app last set. Its emitters advance by how far it moved since the last draw.
- `font`: The font a text without its own was last drawn in (the batch's), or null before a draw.
- `drawnNodeCount`: Nodes drawn by the last draw (in view).
- `draw`: Draws the stage into batch (begun in this frame), through camera, in its viewport, its sprites through their effects at the stage's time (batch.time is set to it); the batch is left seen through camera, with no transform and no effect. Node world transforms are up to date after it, for toLocalX and the like.
- `pick`: The topmost (last drawn) node under framebuffer pixel x, y (from the top-left, as the pointer is) seen through camera, or null for none (or a point outside camera's viewport). Each kind is hit by its own area as drawn: a sprite or filled rectangle its rectangle, a filled circle its disc, a filled polygon its inside (even-odd), an outlined shape or a line its stroke, a text its block (a text without a font of its own once a draw has given one). Emitters and groups aren't hit. The flags hold as in a draw: a disabled node and all under it are passed over, an unpickable one is passed while its children are hit, a hidden one is hit. World transforms are brought up to date; the node's own point is node.toLocalX(camera.screenToWorldX(x), camera.screenToWorldY(y)).

## Text2D

*class* in `src/helix/render2d/Text2D.hx`

A line of text in the 2D world: its value, size units tall (ascent to descent), in a color (0xRRGGBBAA) and a font (null: the drawing batch's built-in one); its position is the top of the text and, by align, its left edge, center or right edge. Wrapped to a width, it is a block of lines (setWrapWidth). Not pickable until pickable is set: a label lets the pointer through to what it's on. Batch2D.drawText draws text without a node; Font2D.measure measures it.

```haxe
function new(value:String, ?size:Float = 16., ?color:Int = 0xffffffff, ?align:Align2D = Left, ?font:Font2D)
var text:String
var textSize(get, set):Float
var color:Int
var align:Align2D
var font:Null<Font2D>
var wrapWidth(default, null):Float
var lineHeight(default, null):Float
function setWrapWidth(width:Float, ?lineHeight:Float = 1.25):Bool
function measureWidth(font:Font2D):Float
function measureHeight(font:Font2D):Float
```

- `new`: value, size units tall (0 or less, or NaN, is 1e-6), in color, aligned on its position by align, in font (null: the batch's built-in one).
- `text`: Its text.
- `textSize`: Its size, units tall (ascent to descent). At least 1e-6 (0 or less, or NaN, is 1e-6).
- `color`: Its color, 0xRRGGBBAA.
- `align`: Which point of it its position's x is: its left edge, center or right edge.
- `font`: Its font, or null for the drawing batch's built-in one.
- `wrapWidth`: Its wrap width in its own units: 0 for one line.
- `lineHeight`: Its wrapped lines apart, times its size.
- `setWrapWidth`: Wraps it to width in its own units (Font2D.wrap), its lines lineHeight times its size apart; 0 for one line. False, changing nothing, for a width below 0 or a line height of 0 or less.
- `measureWidth`: Its width in its own units as drawn in font (its own, if it has one): its wrap width, or its one line's.
- `measureHeight`: Its height in its own units as drawn in font (its own, if it has one): its size, or its wrapped lines'.

## Texture2D

*class* in `src/helix/render2d/Texture2D.hx`

A GPU texture with its size, its format and how it is sampled (Sampling: linear or nearest, and its wrap), which a draw reads when it takes the texture, so one texture can be drawn smooth and then sharp. whiteU/whiteV name an opaque white texel, -1 when it has none, for untextured shapes.

```haxe
static function fromRgba(gpu:IGraphics, width:Int, height:Int, rgba:haxe.io.Bytes, ?linear:Bool = false, ?whiteX:Int = -1, ?whiteY:Int = -1, ?mipmaps:Bool = false):Texture2D
static function fromLevels(gpu:IGraphics, width:Int, height:Int, levels:Array<haxe.io.Bytes>, format:TextureFormat, sampling:Sampling):Texture2D
static function renderTarget(gpu:IGraphics, width:Int, height:Int, ?linear:Bool = true, ?format:TextureFormat = Rgba8, ?depth:Bool = true):Texture2D
var handle(default, null):Int
var width(default, null):Int
var height(default, null):Int
var format(default, null):TextureFormat
var levelCount(get, never):Int
var byteCount(get, never):Int
var sampling:Sampling
var whiteU(default, null):Float
var whiteV(default, null):Float
function destroy(gpu:IGraphics):Void
```

- `fromRgba`: Uploads width x height RGBA8 pixels, rows top first, sampled linear (smooth) or nearest (sharp, for pixel art); whiteX, whiteY name an opaque white texel for untextured shapes, -1 for none. mipmaps adds a chain (Mipmaps.build), so it can be drawn smaller than itself without shimmering. The caller destroys it.
- `fromLevels`: Uploads levels (the image and its mipmaps, each format.levelBytes of its size) of format, width x height, sampled as sampling says. Throws when the GPU can't sample format (IGraphics.canSample). The caller destroys it.
- `renderTarget`: A render target width x height of format: a texture drawn into by target passes (IGraphics.beginTargetPass with its handle), sampled linear (smooth) or nearest (sharp: a low-resolution view shown larger); with depth a depth buffer and the screen's multisampling, without neither (IGraphics.createRenderTarget). Throws for a format the GPU can't draw into (IGraphics.canRender). The caller destroys it.
- `handle`: The IGraphics handle, for draws.
- `width`: Width in texels.
- `height`: Height in texels.
- `format`: Its texels' format: RGBA8, or a compressed one.
- `levelCount`: How many levels it has: 1, or the image and its mipmaps.
- `byteCount`: The GPU memory its levels take, in bytes.
- `sampling`: How draws sample it, from the next draw that takes it on.
- `whiteU`: U of the center of an opaque white texel, or -1 when it has none.
- `whiteV`: V of the center of an opaque white texel, or -1 when it has none.
- `destroy`: Frees the GPU texture on gpu, the adapter that made it.

## TextureCache

*class* in `src/helix/render2d/TextureCache.hx`

Textures from image files (PNG, JPEG, BMP, TGA, GIF) and compressed ones (KTX 1: BC7, ASTC 4x4, ETC2 RGBA8): loaded through the assets, decoded off the frame, uploaded, and replaced in place when a file changes during development. A path "name.ktx" picks the file this GPU can sample: name.bc7.ktx, name.astc.ktx or name.etc2.ktx, the first it can and that loads, else name.png (made beforehand, each with its mipmaps, by a texture compressor; keep the PNG). The runner's is what the Textures static forwards to; the caller releases what it loads.

```haxe
function new(assets:IAssets, images:ImageDecoding, gpu:IGraphics)
function getCandidates(path:String):Array<String>
function getPath(texture:Texture2D):Null<String>
function load(path:String, linear:Bool, loaded:Texture2D -> Void, ?failed:String -> Void):IRequest
function decode(encoded:haxe.io.Bytes, linear:Bool, decoded:Texture2D -> Void, ?failed:String -> Void):IRequest
function release(texture:Texture2D):Void
function reloaded(path:String, bytes:haxe.io.Bytes):Void
function shutdown():Void
```

- `new`: Loads through assets, decodes with images (shared, polled by its owner) and uploads to gpu; shutdown shuts nothing down but this service.
- `getCandidates`: The files path loads from, in order, the first that loads winning: a "name.ktx" this GPU's compressed variants then name.png; any other path itself.
- `getPath`: The file texture was loaded from (for a "name.ktx", the one chosen), or null for one this service didn't load.
- `load`: Loads path into a texture: linear samples it smoothly, with mipmaps so it can be drawn smaller without shimmering; otherwise nearest, for pixel art (Texture2D.sampling changes it later). A "name.ktx" loads this GPU's variant or else name.png (getCandidates). Loads of the same path and filter share one texture (a load under way is joined, not started again), so its sampling is theirs together; each load releases it once (release), and the last frees it. One of loaded or failed runs once on the host thread, and neither once the request is cancelled; failed (else the log, with the path) for a closed service, or when no candidate loads and decodes.
- `decode`: Decodes encoded image bytes (a file's contents already in memory, such as a model's embedded image) into a texture, as load does but with nothing to reload: the caller owns the texture and destroys it. One of decoded or failed runs once on the host thread, and neither once the request is cancelled; failed (else the log) for a closed service or bytes that don't decode.
- `release`: Lets go of a texture this service loaded, once for each load that gave it: the last release frees it and stops reloading it.
- `reloaded`: The file behind loaded textures changed: they're read and uploaded again, keeping their Texture2D objects and sampling, so what draws them shows the new image. A file that no longer reads leaves them as they were.
- `shutdown`: Refuses new loads; the textures already loaded stay until released.

## Textures

*class* in `src/helix/render2d/Textures.hx`

Textures from image files, shared by path and reloading in place when a file changes during development (TextureCache). The program's one, a static class: each member forwards to instance, written by helix.macro.Facade from TextureCache's public members with their doc comments.

```haxe
static var instance(default, null):TextureCache
static function getCandidates(path:String):Array<String>
static function getPath(texture:Texture2D):Null<String>
static function load(path:String, linear:Bool, loaded:Texture2D -> Void, ?failed:String -> Void):IRequest
static function decode(encoded:haxe.io.Bytes, linear:Bool, decoded:Texture2D -> Void, ?failed:String -> Void):IRequest
static function release(texture:Texture2D):Void
```

- `instance`: The textures forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again.
- `getCandidates`: The files path loads from, in order, the first that loads winning: a "name.ktx" this GPU's compressed variants then name.png; any other path itself.
- `getPath`: The file texture was loaded from (for a "name.ktx", the one chosen), or null for one this service didn't load.
- `load`: Loads path into a texture: linear samples it smoothly, with mipmaps so it can be drawn smaller without shimmering; otherwise nearest, for pixel art (Texture2D.sampling changes it later). A "name.ktx" loads this GPU's variant or else name.png (getCandidates). Loads of the same path and filter share one texture (a load under way is joined, not started again), so its sampling is theirs together; each load releases it once (release), and the last frees it. One of loaded or failed runs once on the host thread, and neither once the request is cancelled; failed (else the log, with the path) for a closed service, or when no candidate loads and decodes.
- `decode`: Decodes encoded image bytes (a file's contents already in memory, such as a model's embedded image) into a texture, as load does but with nothing to reload: the caller owns the texture and destroys it. One of decoded or failed runs once on the host thread, and neither once the request is cancelled; failed (else the log) for a closed service or bytes that don't decode.
- `release`: Lets go of a texture this service loaded, once for each load that gave it: the last release frees it and stops reloading it.

## TrueType

*class* in `src/helix/render2d/TrueType.hx`

A TrueType font file (glyf outlines) as read: its metrics, its characters' glyphs and their outlines, and the kerning between pairs (the GPOS table's pair adjustments, or the older kern table). Read in Haxe, the same on every target; Font2D bakes it into a texture. Throws, saying why, for a file it can't read: no glyf outlines (a CFF font), or a table missing or cut short.

```haxe
function new(data:haxe.io.Bytes)
final unitsPerEm:Int
final ascent:Int
final descent:Int
final lineGap:Int
function getGlyphIndex(code:Int):Int
function getAdvance(glyph:Int):Int
function getOutline(glyph:Int):GlyphOutline
function getKerning(left:Int, right:Int):Int
```

- `new`: Reads a TrueType file (the first font of a collection).
- `unitsPerEm`: Font units in an em: what the metrics below are counted in.
- `ascent`: How far the font reaches above the baseline, in font units.
- `descent`: How far it reaches below the baseline, in font units: 0 or negative.
- `lineGap`: The extra space between lines, in font units.
- `getGlyphIndex`: The glyph of character code, or 0 (the missing glyph) when the font has none.
- `getAdvance`: How far the pen moves after glyph, in font units.
- `getOutline`: glyph's outline in font units, y up: empty for a glyph with none (a space). Composite glyphs are assembled from their parts.
- `getKerning`: The horizontal kerning between glyphs left and right, in font units: added to left's advance (usually negative, closing the pair). From GPOS pair adjustments when the font has them, else its kern table; 0 for none.
