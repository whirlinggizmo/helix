# Textures

[Back to the library](README.md)

## Textures

*class* in [`engines/raylib/src/helix/raylib/extras/Textures.hx`](../src/helix/raylib/extras/Textures.hx), `import helix.raylib.extras.Textures;`

Provides texture draws beyond raylib's, helix-raylib's own: fills (a bar, a beaker, a mana ball or a cooldown shown up to an amount), tiled draws, nine-patches whose edges repeat, textured polygons, atlases read from a packer's file, and a render texture fitted to the window. Imported apart: `import helix.raylib.extras.Textures.*;`, and the atlas's type apart: `import helix.raylib.extras.TextureAtlas;`. The example `engines/raylib/examples/extras/textures` uses it.

```haxe
// A mana ball: the glass, the liquid up to the mana, the froth on its surface.
DrawTexturePro(glass, new Rectangle(0, 0, 64, 64), ballRectangle, new Vector2(0, 0), 0, WHITE);
DrawTextureFill(liquid, new Rectangle(0, 0, 64, 64), ballRectangle, mana, TEXTURE_FILL_BOTTOM_TO_TOP, WHITE);
var edge = GetTextureFillEdge(ballRectangle, mana, TEXTURE_FILL_BOTTOM_TO_TOP);
DrawTexture(froth, Std.int(edge.x - froth.width / 2), Std.int(edge.y - froth.height / 2), WHITE);
```

A fill is drawn at its full size and shown up to the amount, never stretched to it, so its ends keep their shape. For a fill of one color, raylib's `DrawRectangle`, `DrawCircleSector` and `DrawRing` draw it, and `GetTextureFillEdge` finds its edge all the same.

```haxe
static inline var TEXTURE_FILL_LEFT_TO_RIGHT:Int
static inline var TEXTURE_FILL_RIGHT_TO_LEFT:Int
static inline var TEXTURE_FILL_TOP_TO_BOTTOM:Int
static inline var TEXTURE_FILL_BOTTOM_TO_TOP:Int
static inline var TEXTURE_FILL_CLOCKWISE:Int
static inline var TEXTURE_FILL_COUNTER_CLOCKWISE:Int
static inline var NPATCH_MODE_STRETCH:Int
static inline var NPATCH_MODE_TILE:Int
static inline var NPATCH_MODE_TILE_FIT:Int
```

- `TEXTURE_FILL_LEFT_TO_RIGHT`: Fills from the left edge to the right.
- `TEXTURE_FILL_RIGHT_TO_LEFT`: Fills from the right edge to the left.
- `TEXTURE_FILL_TOP_TO_BOTTOM`: Fills from the top edge down.
- `TEXTURE_FILL_BOTTOM_TO_TOP`: Fills from the bottom edge up.
- `TEXTURE_FILL_CLOCKWISE`: Fills clockwise about the middle, as a clock's hand sweeps.
- `TEXTURE_FILL_COUNTER_CLOCKWISE`: Fills counterclockwise about the middle.
- `NPATCH_MODE_STRETCH`: A nine-patch's middle and edges are stretched along an axis, as raylib's `DrawTextureNPatch` draws them.
- `NPATCH_MODE_TILE`: A nine-patch's middle and edges are repeated at the texture's size along an axis, the last tile cut where it reaches the far side.
- `NPATCH_MODE_TILE_FIT`: A nine-patch's middle and edges are repeated a whole number of times along an axis, each tile scaled a little to fit exactly.

### Macros, run as the program builds

```haxe
static macro function LoadTextureAtlasAsync(fileName:String, loaded:TextureAtlas -> Void, ?failed:String -> Void):Void
```

- `LoadTextureAtlasAsync`: Loads an atlas: a texture packed with images and the file naming each image's rectangle, calling back once its file and texture have loaded. Reads TexturePacker's JSON (hash or array, a `.json` file) and the XML of Starling and Kenney's sheets (a `.xml` file). The texture is the file the atlas names, beside it. The reader is chosen as the program builds when the file's name is a constant, as `LoadTextureAsync`'s is.
  - `fileName`: The atlas's file.
  - `loaded`: Called with the atlas.
  - `failed`: Optional. Called with the reason when refused; when omitted, it is logged.

  Refused for a file of another format, an image packed rotated, a GIF texture or a texture that doesn't load.

  An asynchronously loaded atlas is invalid until `loaded` is called.

### textures: part of a texture shown up to an amount, and the fill's edge

```haxe
static function DrawTextureFill(texture:Texture2D, source:Rectangle, dest:Rectangle, amount:Float, fillDirection:Int, tint:Color):Void
static function DrawTextureFillEx(texture:Texture2D, source:Rectangle, dest:Rectangle, amount:Float, fillDirection:Int, origin:Vector2, startAngle:Float, fillDegrees:Float, tint:Color):Void
static function GetTextureFillEdge(dest:Rectangle, amount:Float, fillDirection:Int, ?out:Vector3):Vector3
static function GetTextureFillEdgeEx(dest:Rectangle, amount:Float, fillDirection:Int, origin:Vector2, startAngle:Float, fillDegrees:Float, ?out:Vector3):Vector3
```

- `DrawTextureFill`: Draws part of a texture as a fill: drawn at dest's size and shown up to the amount, in the direction. A radial fill turns about dest's middle, starts straight up and sweeps the whole circle. See `DrawTextureFillEx` for a radial fill's origin, start and sweep.
  - `texture`: The texture.
  - `source`: The part of the texture, in pixels.
  - `dest`: Where the fill is drawn, in pixels.
  - `amount`: How full, clamped to [0, 1].
  - `fillDirection`: A `TEXTURE_FILL_` value.
  - `tint`: The tint.
- `DrawTextureFillEx`: Draws part of a texture as a fill, as `DrawTextureFill` does, a radial fill turning about an origin, starting at an angle and sweeping part of the circle: a gauge's half circle about its hub, say. A fill across or down ignores the origin and the angles.
  - `texture`: The texture.
  - `source`: The part of the texture, in pixels.
  - `dest`: Where the fill is drawn, in pixels.
  - `amount`: How full, clamped to [0, 1].
  - `fillDirection`: A `TEXTURE_FILL_` value.
  - `origin`: The point a radial fill turns about, from dest's top-left, in pixels, as `DrawTexturePro`'s origin.
  - `startAngle`: Where a radial fill starts, in degrees clockwise from straight up, wrapped to [0, 360).
  - `fillDegrees`: How far a full radial fill sweeps, in degrees, clamped to [0, 360].
  - `tint`: The tint.
- `GetTextureFillEdge`: Returns the middle of a fill's moving edge, for drawing something there: froth on a liquid, a thermometer's tip, a needle. At an amount of 0 the edge is at the fill's start, and at 1 at its far end. A radial fill's edge runs out from the point the fill turns about: x and y are that point, and z the edge's angle, in degrees clockwise from straight up. See `GetTextureFillEdgeEx` for a radial fill's origin, start and sweep.
  - `dest`: Where the fill is drawn, in pixels.
  - `amount`: How full, clamped to [0, 1].
  - `fillDirection`: A `TEXTURE_FILL_` value.
  - `out`: Optional. The vector to fill, or null for a new one.
  - returns: out, or the new vector: x and y in screen pixels, as dest's, z a radial fill's angle and 0 for the others.
- `GetTextureFillEdgeEx`: Returns the middle of a fill's moving edge, as `GetTextureFillEdge` does, for a radial fill turning about an origin, starting at an angle and sweeping part of the circle.
  - `dest`: Where the fill is drawn, in pixels.
  - `amount`: How full, clamped to [0, 1].
  - `fillDirection`: A `TEXTURE_FILL_` value.
  - `origin`: The point a radial fill turns about, from dest's top-left, in pixels, as `DrawTexturePro`'s origin.
  - `startAngle`: Where a radial fill starts, in degrees clockwise from straight up, wrapped to [0, 360).
  - `fillDegrees`: How far a full radial fill sweeps, in degrees, clamped to [0, 360].
  - `out`: Optional. The vector to fill, or null for a new one.
  - returns: out, or the new vector.

### textures: tiled draws, nine-patches whose edges repeat, and textured polygons

```haxe
static function DrawTextureTiled(texture:Texture2D, source:Rectangle, dest:Rectangle, origin:Vector2, rotation:Float, scale:Float, tint:Color):Void
static function DrawTextureNPatchEx(texture:Texture2D, nPatchInfo:NPatchInfo, dest:Rectangle, origin:Vector2, rotation:Float, horizontalPatchMode:Int, verticalPatchMode:Int, tint:Color):Void
static function DrawTexturePoly(texture:Texture2D, center:Vector2, points:Array<Vector2>, texcoords:Array<Vector2>, pointCount:Int, tint:Color):Void
```

- `DrawTextureTiled`: Draws part of a texture repeated across dest, the last copies cut where they reach dest's far sides, as raylib's `DrawTexturePro` draws one copy.
  - `texture`: The texture.
  - `source`: The part of the texture repeated, in pixels.
  - `dest`: Where the copies are drawn, in pixels.
  - `origin`: The point dest rotates about, from its top-left, in pixels.
  - `rotation`: The rotation, in degrees clockwise.
  - `scale`: Each copy's size, a multiple of source's.
  - `tint`: The tint.
- `DrawTextureNPatchEx`: Draws a nine-patch, as raylib's `DrawTextureNPatch` does, its middle and edges stretched or repeated along each axis: a rope frame whose twists repeat along its sides.
  - `texture`: The texture.
  - `nPatchInfo`: The patch and its borders.
  - `dest`: Where the patch is drawn, in pixels.
  - `origin`: The point dest rotates about, from its top-left, in pixels.
  - `rotation`: The rotation, in degrees clockwise.
  - `horizontalPatchMode`: How the middle and edges fill dest across: `NPATCH_MODE_STRETCH`, `NPATCH_MODE_TILE` or `NPATCH_MODE_TILE_FIT`.
  - `verticalPatchMode`: How the middle and edges fill dest down, as `horizontalPatchMode`.
  - `tint`: The tint.
- `DrawTexturePoly`: Draws a texture inside a polygon: a portrait in a hexagon, a ground texture on a hill. Each point is drawn with the texture at its texture coordinate, the points joined to center as a triangle fan. The polygon is closed from the last point back to the first.
  - `texture`: The texture.
  - `center`: The fan's middle, in pixels, drawn with the texture's middle.
  - `points`: The polygon's points, in pixels, in order around it.
  - `texcoords`: Each point's texture coordinate, from (0, 0) at the texture's top-left to (1, 1) at its bottom-right.
  - `pointCount`: How many points are drawn, each counted once.
  - `tint`: The tint.

### textures: an atlas's images by name

```haxe
static function UnloadTextureAtlas(atlas:TextureAtlas):Void
static function GetTextureAtlasRectangle(atlas:TextureAtlas, name:String, ?out:Rectangle):Rectangle
```

- `UnloadTextureAtlas`: Unloads an atlas's texture.
  - `atlas`: The atlas.
- `GetTextureAtlasRectangle`: Returns the rectangle of an image in an atlas, for a draw's source. Refused, with the name logged, for a name the atlas lacks.
  - `atlas`: The atlas.
  - `name`: The image's name, as the atlas's file names it, extension and all: `sword.png`.
  - `out`: Optional. The rectangle to fill, or null for a new one.
  - returns: out, or the new rectangle, in pixels of the atlas's texture, or an empty rectangle when refused.

### textures: a render texture fitted to the screen, and the mouse read in its pixels

```haxe
static function DrawRenderTextureFit(target:RenderTexture2D, integerScale:Bool, tint:Color):Void
static function SetMouseRenderTextureFit(target:RenderTexture2D, integerScale:Bool):Void
static function GetRenderTextureFitRectangle(target:RenderTexture2D, integerScale:Bool, ?out:Rectangle):Rectangle
```

- `DrawRenderTextureFit`: Draws a render texture fitted to the screen: as large as fits, its aspect kept, centered with bars beside or above it, and the right way up. Drawn between `BeginDrawing` and `EndDrawing`, outside the render texture's `BeginTextureMode`.
  - `target`: The render texture.
  - `integerScale`: Whether its size is a whole multiple of the render texture's, for pixel art. A screen smaller than the render texture shrinks it all the same.
  - `tint`: The tint.
- `SetMouseRenderTextureFit`: Sets the mouse's offset and scale (raylib's `SetMouseOffset` and `SetMouseScale`) to a render texture drawn by `DrawRenderTextureFit`. `GetMousePosition` and raygui's controls then read the mouse in the render texture's pixels. Set again when the window's size changes, or each frame.
  - `target`: The render texture.
  - `integerScale`: Whether its size is a whole multiple of the render texture's, as provided to `DrawRenderTextureFit`.
- `GetRenderTextureFitRectangle`: Returns where `DrawRenderTextureFit` draws a render texture on the screen.
  - `target`: The render texture.
  - `integerScale`: Whether its size is a whole multiple of the render texture's.
  - `out`: Optional. The rectangle to fill, or null for a new one.
  - returns: out, or the new rectangle, in screen pixels.

## TextureAtlas

*class* in [`engines/raylib/src/helix/raylib/extras/TextureAtlas.hx`](../src/helix/raylib/extras/TextureAtlas.hx), `import helix.raylib.extras.TextureAtlas;`

Holds an atlas loaded by `Textures.LoadTextureAtlasAsync`: its texture and each image's rectangle in it, by name.

```haxe
var texture(default, null):Texture2D
var names(default, null):Array<String>
```

- `texture`: Gets the atlas's texture.
- `names`: Gets the names of the atlas's images, in the file's order.
