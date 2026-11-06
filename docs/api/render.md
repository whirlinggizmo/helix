# helix.render

[Back to the index](README.md)

## Batch2D

*class* in [`libs/render/src/helix/render/Batch2D.hx`](../../libs/render/src/helix/render/Batch2D.hx), `import helix.render.Batch2D;`

Provides 2D drawing: sprites, shapes and text, in a camera's world units or the viewport's pixels, through as few GPU draws as their order allows.

A program constructs one over its `Renderer`, and between `Renderer.beginFrame` and `endFrame` draws between `begin` or `beginCamera` and `end`. Units are the viewport's pixels from its top left, y down, after `begin`, or a camera's world units after `beginCamera`. Angles are radians, a positive one turning clockwise on screen. Colors are 0xAARRGGBB, blended by their alpha.

Colors and texels are sRGB values. Into an RGBA8 target or the screen they are drawn as they are stored: a tint multiplies them, and blending mixes them, as sRGB values, which is what 2D art is drawn expecting. Into an RGBA16F target, which holds linear light, they are decoded to linear as they are drawn, so they blend with the 3D drawn there and show as they would on the screen once the target is encoded. Nothing is tone mapped. A program's own shader (`shaderValues`) is given them as stored either way.

**Draw state.** `transform`, `blend`, `shaderValues` and `customData` are read as each draw is made, and kept across `begin`s and frames, as raylib's rlgl state is: a value set holds until the program sets another, and `resetState` puts all four back.

**Order and batching.** Draws are drawn in the order they are called; nothing is sorted, so what is drawn later is on top. Consecutive draws become one GPU draw while they share a texture, the shader values with nothing written to them between, a blend mode, and the renderer's clip. A draw that differs in one of them starts the next GPU draw, and so do assigning `blend` or `shaderValues`, `Renderer.applyScissor`, and `end`. `transform` and `customData` split nothing: they are written into the vertices as each draw is made. Sprites, shapes and text of every kind of font are drawn by one shader, so only their textures part them: shapes are drawn from `shapeRegion`, the batch's own white texture until set, so a white texel on a sheet (`Texture2D.writeWhiteTexel`) or a font's atlas lets its sprites or its text and the shapes between them be one GPU draw.

**Culling.** With `culling` on, read at each draw, a draw wholly outside the view is skipped: its box (a turned sprite's turned box, a shape's, a text's lines') moved by `transform`, against the camera's visible rectangle (`Camera2D.computeBounds`) or the viewport. `drawTriangles`, and every draw while `shaderValues` is set, aren't culled, as their vertices may be moved where the batch can't know.

**A program's shader** (`shaderValues`) is compiled by `compileShader` (a fragment stage over the batch's vertex stage) or `compileShaderStages`. The batch fills, by name, what it declares. Both batches fill the same names, so one shader serves `Batch2D` and `Batch3D` alike (raylib's `LoadShader`, through `Batch3D.makeShaderExpr` and `Shader.withNames`); for a 2D draw they are:

| Name | Type | What | |---|---|---| | `vertexPosition` | vec3 | The vertex, in the batch's units, moved by `transform`; z 0. | | `vertexTexCoord` | vec2 | The texture coordinates, 0 to 1 across the texture, v down. | | `vertexColor` | vec4 | The vertex's color times the tint, 0 to 1, as stored. | | `vertexCustomData` | vec4 | `customData` as the draw was made: its red, green, blue and alpha bytes, each 0 to 1. | | `vertexNormal` | vec3 | 0, 0, 1. | | `vertexCorner`, `vertexLineEnd` | vec2, vec3 | 0: the batch makes its lines and shapes as triangles itself. | | `baseColorTexture` | sampler2D | The sprite's texture, the font's atlas, the draw's texture, or `shapeRegion`'s for shapes. | | `fontKind` | int | The kind (helix-services' `FontKind`) of the font whose atlas the draw reads: 0 Coverage, 1 Bitmap, 2 Distance; 0 for any other texture. | | `model`, `normalMatrix` | mat4 | Identity: the batch moves the vertices itself. | | `modelViewProjection` | mat4 | The view's `viewProjection`. | | `baseColor` | vec4 | White: a 2D draw has no material. | | `clipPlanes`, `clipPlaneCount` | vec4[4], int | None: 0. | | `pointSize`, `pointSizeAttenuated` | float, int | 1 and 0. |

With them the view's names (`View3D`: `viewProjection`, `linearTarget` and the rest), shared through `#include <helix/render/shaders/view.glsl>` or written per draw when declared alone. A name the program writes on its values is overwritten by the batch's. A name `Shader.withNames` gives is filled exactly as the same name declared in the GLSL, and the batch shares the `View` block with each draw itself, so the program sets no `ShaderValues.scene` (`Batch3D` says how). Colors are given as stored and nothing the shader writes is encoded after it, so it works in the space it chooses; `#include <helix/render/shaders/color.glsl>` gives the conversions (`View3D` lists them). The batch's vertex stage passes `texCoord` (vec2), `color` (vec4), `customData` (vec4), `normal` (vec3) and `worldPosition` (vec3), read by name in a fragment stage, as `Batch3D`'s does.

```glsl
// flash.frag: the sprite's texel and tint, and a flash the program sets
#version 300 es
precision highp float;
in vec2 texCoord;
in vec4 color;
uniform sampler2D baseColorTexture;
uniform vec4 flashColor;
uniform float flash;
out vec4 fragColor;
void main() {
vec4 texel = texture(baseColorTexture, texCoord) * color;
fragColor = vec4(mix(texel.rgb, flashColor.rgb, flash), texel.a);
}
```

```haxe
var flashShader = Batch2D.compileShader("flash.frag");
var flash = new ShaderValues(flashShader);
flash.writeColor(flashShader.getUniform("flashColor"), 0xffffffff);
// each frame:
flash.writeFloat(flashShader.getUniform("flash"), hit ? 1 : 0);
batch.shaderValues = flash;
batch.drawSprite(enemy, x, y);
batch.shaderValues = null;
```

Lines, outlines and shapes are made of triangles, as many as keep a curve's edge within a quarter of a pixel where it is drawn. A thickness is in the batch's units, centered on the edge or the line.

```haxe
var batch = new Batch2D(renderer);
// each frame, between Renderer.beginFrame and endFrame:
batch.beginCamera(camera);
batch.drawSprite(player, x, y, angle); // turned about the region's origin
batch.fillCircle(coinX, coinY, 6, 0xffffd700);
batch.end();
batch.begin(); // the HUD, in pixels
batch.drawText(font, 'Score $score', 8, 8);
batch.end();
```

```haxe
function new(renderer:Renderer)
static macro function compileShader(fragment:String, ?options:haxe.macro.Expr.ExprOf<ShaderOptions>):haxe.macro.Expr.ExprOf<Shader>
static macro function compileShaderStages(vertex:String, fragment:String, ?options:haxe.macro.Expr.ExprOf<ShaderOptions>):haxe.macro.Expr.ExprOf<Shader>
final transform:Matrix2D
var blend(default, set):Blend
var shaderValues(default, set):Null<ShaderValues>
var shapeRegion(default, set):Null<TextureRegion2D>
var culling:Bool
var customData:Int
var open(default, null):Bool
function resetState():Void
function begin():Void
function beginCamera(camera:Camera2D):Void
function end():Void
function drawTexture(texture:Texture2D, x:Float, y:Float, ?tint:Int = 0xffffffff):Void
function drawTextureRegion(texture:Texture2D, regionX:Float, regionY:Float, regionWidth:Float, regionHeight:Float, x:Float, y:Float, width:Float, height:Float, ?rotation:Float = 0., ?originX:Float = 0., ?originY:Float = 0., ?tint:Int = 0xffffffff):Void
function drawSprite(region:TextureRegion2D, x:Float, y:Float, ?rotation:Float = 0., ?scaleX:Float = 1., ?scaleY:Float = 1., ?tint:Int = 0xffffffff, ?flipX:Bool = false, ?flipY:Bool = false, ?originX:Float, ?originY:Float):Void
function drawLine(x0:Float, y0:Float, x1:Float, y1:Float, thickness:Float, color:Int):Void
function drawPolyline(points:Array<Float>, thickness:Float, color:Int):Void
function fillTriangle(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, color:Int):Void
function fillRectangle(x:Float, y:Float, width:Float, height:Float, color:Int):Void
function strokeRectangle(x:Float, y:Float, width:Float, height:Float, thickness:Float, color:Int):Void
function fillRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, color:Int):Void
function strokeRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, thickness:Float, color:Int):Void
function fillCircle(x:Float, y:Float, radius:Float, color:Int):Void
function strokeCircle(x:Float, y:Float, radius:Float, thickness:Float, color:Int):Void
function fillEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, color:Int):Void
function strokeEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, thickness:Float, color:Int):Void
function fillPolygon(points:Array<Float>, color:Int):Bool
function strokePolygon(points:Array<Float>, thickness:Float, color:Int):Void
function drawTriangles(texture:Null<Texture2D>, positions:Array<Float>, ?texCoords:Array<Float>, ?colors:Array<Int>, ?indices:Array<Int>):Void
function drawText(font:GpuFont2D, text:String, x:Float, y:Float, ?color:Int = 0xffffffff, ?size:Float, ?letterSpacing:Float = 0., ?kerned:Bool = true):Void
function drawTextLayout(layout:TextLayout2D, x:Float, y:Float, ?color:Int = 0xffffffff):Void
function drawList(list:DrawList2D, ?placement:Matrix2D):Void
```

- `new`: Creates a batch over a renderer, with its default shader: textured and colored triangles, the texel times the color, which draw sprites, shapes and text.
  - `renderer`: The renderer it records into.
- `compileShader`: Compiles a fragment stage over the batch's vertex stage, for a `Batch2D`'s draws (`shaderValues`).
  - `fragment`: The fragment stage's file, relative to the file holding the call.
  - `options`: Optional. Defines, includes and a file to watch, as `Shader.compile` takes them.
  - returns: The shader, for a `ShaderValues` over it.

  It compiles while the program builds, as helix-services' `Shader.compile` compiles one, and returns it as a value in the program: its vertex stage drawn the right way up into a render target whatever it writes (`ShaderOptions.clipScale`) and able to draw one-pixel points (`ShaderOptions.points`), helix-render's includes found (`#include <helix/render/shaders/color.glsl>`). A name the class lists declared with another type stops the build at the call. The fragment stage is GLSL as helix-services' `Shader.compile` takes it: `#version 300 es` or 330 to 440 (GL's form), or `#version 450` (Vulkan's), the batch's vertex stage given in the same form; GLSL ES 100 (raylib's) is not taken, and a layer adapts it first. The vertex stage passes `texCoord` (vec2), `color` (vec4) and `customData` (vec4), read by name.
- `compileShaderStages`: Compiles a vertex and a fragment stage, both the program's, for a `Batch2D`'s draws (`shaderValues`).
  - `vertex`: The vertex stage's file, relative to the file holding the call.
  - `fragment`: The fragment stage's file, relative to the file holding the call.
  - `options`: Optional. Defines, includes and a file to watch.
  - returns: The shader, for a `ShaderValues` over it.

  It compiles while the program builds, as helix-services' `Shader.compile` compiles one, and returns it as a value in the program: its vertex stage drawn the right way up into a render target whatever it writes (`ShaderOptions.clipScale`) and able to draw one-pixel points (`ShaderOptions.points`), helix-render's includes found (`#include <helix/render/shaders/color.glsl>`). A name the class lists declared with another type stops the build at the call. Both stages are GLSL in one form, as helix-services' `Shader.compile` takes it: `#version 300 es` or 330 to 440, or `#version 450`. The batch makes its lines and shapes as triangles itself, so the vertex stage need only place each vertex and write what its fragment stage reads; `#include <helix/render/shaders/batch.glsl>` declares the names and outputs `Batch3D` lists, and its `placeBatchVertex(vertexPosition, vertexLineEnd)` does both, as for `Batch3D`.
- `transform`: Gets the matrix the following draws are moved by, before the camera: identity until changed.
  It is changed in place (`batch.transform.makeIdentity().appendRotation(turn, batch.transform)`), and read as each draw is made.
- `blend`: Gets or sets how the following draws are combined with what is under them: `Blend.ALPHA` until set; any factors and operations the platform's `Blend` takes (multiply, screen, premultiplied alpha).
- `shaderValues`: Gets or sets the program's own shader the following draws are drawn with, as values over it carrying its own uniforms and textures, or null for the batch's default: null until set.
  Its shader is compiled by `compileShader` or `compileShaderStages`, and reads the names the class lists. Its values are read as each draw is made.
- `shapeRegion`: Gets or sets the region shapes, lines and outlines are drawn with: null until set, for the batch's own white texture.
  Shapes read the texel at the region's center alone, so it must be white there: `Texture2D.writeWhiteTexel` makes one on a sheet or an atlas, and shapes then join one GPU draw with its sprites, as raylib's `SetShapesTexture` does. Assigning it ends the open GPU draw. It is not draw state: `resetState` leaves it.
- `culling`: Gets or sets a value indicating whether draws out of view are skipped: true until set; read at each draw.
- `customData`: Gets or sets four bytes each following vertex carries, for a program's shader to read as `customData`: a hit flash's amount, a palette row, a dissolve's threshold, a sprite's own value without a GPU draw of its own. 0xAARRGGBB, read as red, green, blue and alpha each 0 to 1; 0 until set. It is read as each draw is made and splits nothing; the batch's own shader ignores it.
- `open`: Gets a value indicating whether it is open: from `begin` or `beginCamera` until `end`.
- `resetState`: Puts the draw state back to its defaults: `transform` identity, `blend` Alpha, no `shaderValues`, `customData` 0.
  It may be called at any time, open or not. `shapeRegion` and `culling` are left as they are.
- `begin`: Opens the batch for drawing in the renderer's current pass, in the viewport's pixels from its top left, y down.
  - throws `String`: No frame being recorded, or a batch (this or another) already open.

  The draw state is kept as the program left it. `beginCamera` draws in a camera's world units.
- `beginCamera`: Opens the batch for drawing in the renderer's current pass, in a camera's world units.
  - `camera`: The camera, whose view units are the viewport's pixels.
  - throws `String`: No frame being recorded, or a batch (this or another) already open.

  The camera is read now: changing it after takes effect at the next `begin` or `beginCamera`. The draw state is kept as the program left it.
- `end`: Closes the batch, so another can open or the pass can end.
  - throws `String`: The batch isn't open.
- `drawTexture`: Draws a whole texture at its size, its top left at a point.
  - `texture`: The texture.
  - `x`: The left edge.
  - `y`: The top edge.
  - `tint`: Optional. The color its texels are multiplied by; defaults to white.
- `drawTextureRegion`: Draws a rectangle of a texture into a rectangle, turned about an origin, as raylib's `DrawTexturePro` draws it: no region is made for it.
  - `texture`: The texture.
  - `regionX`: The part's left edge, in texels from the texture's left.
  - `regionY`: The part's top edge, in texels from the texture's top.
  - `regionWidth`: The part's width, in texels; negative mirrors it left to right.
  - `regionHeight`: The part's height, in texels; negative mirrors it top to bottom.
  - `x`: Where the origin goes, across.
  - `y`: Where the origin goes, down.
  - `width`: The width it is drawn at, in the batch's units.
  - `height`: The height it is drawn at, in the batch's units.
  - `rotation`: Optional. The turn about the origin, in radians; defaults to 0.
  - `originX`: Optional. The point it turns about and is placed by, in the batch's units from the drawn rectangle's left; defaults to 0.
  - `originY`: Optional. That point, in the batch's units from the drawn rectangle's top; defaults to 0.
  - `tint`: Optional. The color its texels are multiplied by; defaults to white.

  A negative width or height of the part taken mirrors it that way.
- `drawSprite`: Draws a texture's region, turned and scaled about its origin, the origin at a point.
  - `region`: The region of the texture.
  - `x`: Where the origin goes, across.
  - `y`: Where the origin goes, down.
  - `rotation`: Optional. The turn about the origin, in radians; defaults to 0.
  - `scaleX`: Optional. The scale across; defaults to 1, the region's size in texels.
  - `scaleY`: Optional. The scale down; defaults to 1.
  - `tint`: Optional. The color its texels are multiplied by; defaults to white.
  - `flipX`: Optional. Whether it is mirrored left to right about its origin, after its scale; defaults to false.
  - `flipY`: Optional. Whether it is mirrored top to bottom about its origin, after its scale; defaults to false.
  - `originX`: Optional. The point it turns about and is placed by, in texels from the region's left; the region's `originX` when omitted.
  - `originY`: Optional. That point, in texels from the region's top; the region's `originY` when omitted.

  A negative scale flips the sprite about its origin: -1 across mirrors it left to right. `flipX` and `flipY` flip it the same way again, so they mirror a sprite whatever its scale: true with a scale of -1 draws it unflipped.
- `drawLine`: Draws a line between two points.
  - `x0`: The start, across.
  - `y0`: The start, down.
  - `x1`: The end, across.
  - `y1`: The end, down.
  - `thickness`: The width, in the batch's units; its ends are square, cut at the points.
  - `color`: The color.
- `drawPolyline`: Draws lines through points, one after another, joined at each point with a miter, or a bevel where the miter would reach past twice the thickness.
  - `points`: The points, x and y each; fewer than two draws nothing.
  - `thickness`: The width, in the batch's units.
  - `color`: The color.
- `fillTriangle`: Fills a triangle.
  - `x0`: The first corner, across.
  - `y0`: The first corner, down.
  - `x1`: The second corner, across.
  - `y1`: The second corner, down.
  - `x2`: The third corner, across.
  - `y2`: The third corner, down.
  - `color`: The color.
- `fillRectangle`: Fills a rectangle.
  - `x`: The left edge.
  - `y`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `color`: The color.
- `strokeRectangle`: Draws a rectangle's outline.
  - `x`: The left edge.
  - `y`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `thickness`: The outline's width, centered on the edges.
  - `color`: The color.
- `fillRoundedRectangle`: Fills a rectangle with rounded corners.
  - `x`: The left edge.
  - `y`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `radius`: The corners' radius, clamped to half the shorter side.
  - `color`: The color.
- `strokeRoundedRectangle`: Draws the outline of a rectangle with rounded corners.
  - `x`: The left edge.
  - `y`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `radius`: The corners' radius, clamped to half the shorter side.
  - `thickness`: The outline's width, centered on the edges.
  - `color`: The color.
- `fillCircle`: Fills a circle.
  - `x`: The center, across.
  - `y`: The center, down.
  - `radius`: The radius.
  - `color`: The color.
- `strokeCircle`: Draws a circle's outline.
  - `x`: The center, across.
  - `y`: The center, down.
  - `radius`: The radius.
  - `thickness`: The outline's width, centered on the circle.
  - `color`: The color.
- `fillEllipse`: Fills an ellipse whose axes run across and down.
  - `x`: The center, across.
  - `y`: The center, down.
  - `radiusX`: The radius across.
  - `radiusY`: The radius down.
  - `color`: The color.
- `strokeEllipse`: Draws an ellipse's outline.
  - `x`: The center, across.
  - `y`: The center, down.
  - `radiusX`: The radius across.
  - `radiusY`: The radius down.
  - `thickness`: The outline's width, centered on the ellipse.
  - `color`: The color.
- `fillPolygon`: Fills a polygon, convex or not, whose edges don't cross.
  - `points`: The corners in order, x and y each, either way round; fewer than three draws nothing.
  - `color`: The color.
  - returns: False when its edges cross, and nothing is drawn.
- `strokePolygon`: Draws a polygon's outline: lines through its corners and back to the first, joined as `drawPolyline` joins them.
  - `points`: The corners in order, x and y each; fewer than two draws nothing.
  - `thickness`: The outline's width, centered on the edges.
  - `color`: The color.
- `drawTriangles`: Draws triangles as given: textured, colored by vertex, or both, for what the shapes here don't make.
  - `texture`: The texture, or null for white.
  - `positions`: The vertices' positions, x and y each.
  - `texCoords`: Optional. The texture coordinates, u and v each, 0 to 1 across the texture; 0, 0 for every vertex when omitted.
  - `colors`: Optional. Each vertex's color, 0xAARRGGBB; white when omitted.
  - `indices`: Optional. Three a triangle, indexing the vertices; when omitted, the vertices are the triangles in order.

  The arrays are read during the call, so they may be reused for the next.
- `drawText`: Draws text in a font, line by line at each line break, left-aligned, its first line's top at a point.
  - `font`: The font.
  - `text`: The text; a character the font lacks is drawn as the font's stand-in, as `GpuFont2D` says.
  - `x`: The left edge.
  - `y`: The top of the first line: its ascent above the baseline.
  - `color`: Optional. The color; defaults to white.
  - `size`: Optional. The size, in the batch's units, as the font's size is measured; the font's own when omitted.
  - `letterSpacing`: Optional. Space added after each character, in the batch's units, as raylib's `spacing`; defaults to 0.
  - `kerned`: Optional. Whether pairs of characters are kerned as the font gives them; defaults to true. raylib's `DrawTextEx` doesn't kern.

  A distance-field font stays sharp at any size; another is scaled from its atlas. Pairs of characters are kerned as the font gives them, unless `kerned` is false.
- `drawTextLayout`: Draws laid-out text, wrapped and aligned as its layout says, the layout's top left at a point.
  - `layout`: The layout.
  - `x`: The left edge of the layout's box, in which its lines are aligned: the box is `maxWidth` wide, or as wide as its widest line when `maxWidth` is 0.
  - `y`: The top of the first line.
  - `color`: Optional. The color; defaults to white.
- `drawList`: Replays a draw list: its calls in the order recorded, in its own units placed by a transform, then by `transform` and the camera.
  - `list`: The list.
  - `placement`: Optional. Its place in the batch's units; identity when omitted.
  - throws `String`: A texture it holds disposed.

  With `culling` on, a list whose box (`DrawList2D.bounds`), so placed, is wholly out of view is skipped whole; a list drawn while `shaderValues` is set isn't culled. Its calls are drawn with the batch's `blend`, `shaderValues` and `customData` as they are now.

## Batch3D

*class* in [`libs/render/src/helix/render/Batch3D.hx`](../../libs/render/src/helix/render/Batch3D.hx), `import helix.render.Batch3D;`

Provides 3D drawing through a camera or through views: meshes and models with their materials, lit, shadowed and fogged, skinned, morphed and instanced; the environment's background; and the batch draws, for what has no mesh: lines, debug shapes, billboards, points, triangles, and sprites, shapes and text in a plane.

A program constructs one over its `Renderer`, and between `Renderer.beginFrame` and `endFrame` draws between `begin` (or `beginViews`) and `end`. Units are world units, right-handed with +y up; colors are 0xAARRGGBB, sRGB.

**What `begin` reads.** The camera or views, `lights`, `environment`, `fog`, and the renderer's `exposure` and `toneMapping` are read at `begin` and hold until `end`.

**Draw state.** `blend`, `depthTest`, `depthWrite`, `cull`, `colorWrite`, `polygonMode`, `pointSize`, `pointSizeAttenuated`, `shaderValues`, `customData`, `castShadows`, `receiveShadows`, `clipPlanes`, `fogged` and `toneMapped` are read at each draw, as `culling` and `shapeRegion` are. They are kept across `begin`s, `beginViews` and frames, as raylib's rlgl state is: a value set holds until the program sets another. `resetState` puts the draw state back to its defaults.

**Views.** `begin(camera)` draws through one view, the camera's, filling the renderer's viewport. `beginViews` draws through several at once, each with its own matrices and rectangle: every draw is drawn once in each view, in the order given, so the two eyes of a headset or two split screens see one scene drawn once by the program. Lights are chosen, shadows fitted and draws culled for all the views together: a draw is skipped only when it is out of every view.

**Light.** A material is shaded as its `shading` says by the lights in `lights` (any number; each draw by the 8 that reach it most: each light's brightness through its falloff at the nearest point of the draw's box, and a spot's cone toward the box, widened by how far the box reaches from its center), the ambient light and environment map of `environment`, and its own maps, in linear light. A batch draw whose program's shader reads the lights is lit by the 8 that reach the first view's eye most.

**Shadows.** At most 4 lights cast, on every target: each of the first 4 lights in `lights` that casts (`Light3D.castsShadow`) has its map drawn before the pass the batch draws in, at `Renderer.endFrame`, from the meshes this batch drew casting that its volume holds, and is read by those drawn receiving (`LightShadow3D` says how). A mesh casts when both the batch's `castShadows` and its material's are on, and receives when both `receiveShadows` are. A caster is drawn as it is drawn in color: skinned, morphed, instanced, cut by `alphaCutoff`. The batch draws neither cast nor receive. The shadow code is compiled into the lit stage (`shadows.glsl`), a few kilobytes of text that compress to near nothing; a program that never casts may build with `-D helix_render_no_shadows` to leave it out, and a light told to cast in such a build stops the program, naming the define.

**Targets.** What a target holds is its format's. Into an RGBA8 target or the screen, which hold sRGB, lit color and a material with `toneMapped` on are exposed and tone mapped by the renderer's `exposure` and `toneMapping`, everything is encoded, and the GPU blends the encoded values, so a blended surface mixes as sRGB colors do. Into an RGBA16F target, which holds linear light, everything is written linear, neither exposed, tone mapped nor encoded, and blends linearly: `PostProcess.draw` resolves it by the same pair.

**The batch draws' colors are multiplied as stored.** A batch draw's vertex color, tint and texel are multiplied as the 0xAARRGGBB values and the texture store them, with no decode, as raylib and `Batch2D` multiply them: a 0x80 tint on a 0x80 texel gives 0x40. Into an sRGB target the product is written as it is, unless fog reaches it (`fogged`) or it is tone mapped (`toneMapped`): then it is decoded once, fogged, exposed and tone mapped as they say, and encoded. Into an RGBA16F target it is decoded once and written linear.

**Points.** A point of `pointSize` 1, not attenuated, is the one pixel its position falls in, on every backend, shaded as its vertex; a larger one is a square facing the screen, made in the vertex stage, with its texture across it. A mesh's larger points (`polygonMode` Points) are each vertex's square, its records read one a GPU instance, so an instanced mesh's are a GPU draw for each copy; a program's own vertex stage that doesn't read `vertexCorner` draws them as one-pixel points.

**Sprites, shapes and text in a plane** (`drawSprite`, `drawTextureRegion`, the shapes from `fillTriangle` to `strokePolygon`, `drawText`, `drawTextLayout`) are what a layer drawing all its 2D through this batch needs, as raylib's rlgl does: wire and point modes and views (stereo) then reach its 2D too. Each is drawn in the plane z 0 of its transform, x across and y down the texture, as `Batch2D` draws it, so under an orthographic view whose y runs down (`View3D.setFromScreen`, raylib's 2D) it is upright in pixels; in a world whose y runs up, a transform scaled by -1 in y stands it up. They make their corners on the CPU as `Batch2D` does, and join one GPU draw with the batch draws around them that share their texture; shapes are drawn from `shapeRegion`. Lines, outlines and curves are made of triangles, as many as keep a curve's edge within a quarter of a unit of the plane (a pixel under `View3D.setFromScreen`); a thickness is in the plane's units, centered on the edge or the line. A program drawing only 2D uses `Batch2D`.

**A program's shader** for the batch draws (`shaderValues`) is compiled by `compileShader` (a fragment stage over the batch's vertex stage) or `compileShaderStages`; a mesh's is its material's (`Material3D`). The batch fills, by name, what it declares; both batches fill the same names, so one shader serves both (`makeShaderExpr`). For a batch draw, the attributes:

| Name | Type | What | |---|---|---| | `vertexPosition` | vec3 | The vertex, in world units, moved by the draw's transform. | | `vertexTexCoord` | vec2 | The texture coordinates, 0 to 1 across the texture, v down. | | `vertexNormal` | vec3 | `drawTriangles`' normal; 0, 0, 1 for the others. | | `vertexColor` | vec4 | The vertex's color times the tint, 0 to 1, as stored. | | `vertexCustomData` | vec4 | `customData` as the draw was made. | | `vertexCorner` | vec2 | A wide line's or a large point's corner, -1 to 1 (a line's x along it, start to end; y across it); 0, 0 for a vertex drawn where it is. | | `vertexLineEnd` | vec3 | The other end of a wide line's segment, in world units. |

And the uniforms:

| Name | Type | What | |---|---|---| | `baseColorTexture` | sampler2D | The draw's texture, the region's, the font's atlas, `shapeRegion`'s, or white. | | `fontKind` | int | As `Batch2D` fills it. | | `model`, `normalMatrix` | mat4 | Identity: the batch moves the vertices itself. | | `modelViewProjection` | mat4 | The view's `viewProjection`. | | `baseColor` | vec4 | White: a batch draw has no material. | | `lineWidth` | float | The draw's line width, in framebuffer pixels. | | `pointSize`, `pointSizeAttenuated` | float, int | The draw state's. | | `clipPlanes`, `clipPlaneCount` | vec4[4], int | The draw state's planes. | | `fogged`, `toneMapped` | int | The draw state's, 1 for true. |

With them the view's names (`View3D`). A name the program writes on its values is overwritten by the batch's.

**Names given by `Shader.withNames`** are filled exactly as names declared in the GLSL: a shader written for raylib's names, its `mvp`, `matView`, `colDiffuse` and `texture0` given as `modelViewProjection`, `viewMatrix`, `baseColor` and `baseColorTexture`, is filled as one declaring those names, a loose `viewMatrix` written per draw as `View3D` says. The batch shares the blocks itself: each draw reads the view's `View` block and the batch's `Lighting` (the `ShaderScene` written at `begin`) wherever the shader declares them, so the program sets no `ShaderValues.scene` and shares no block, and a scene it sets on its values is not read for them.

**The batch's vertex stage** passes, read by name in a fragment stage: `texCoord` (vec2), `color` (vec4, as stored), `customData` (vec4), `normal` (vec3) and `worldPosition` (vec3, what the clip planes cut by).

**A program's own vertex stage** (`compileShaderStages`, `makeShaderExpr`) may place its vertices itself, declaring the attributes, uniforms and outputs it uses, as raylib's GLSL 330 vertex stages do (`gl_Position = mvp * vec4(vertexPosition, 1.0)`). It then gives up what the batch's stage makes from `vertexCorner`: wide lines are drawn as one-pixel lines and large points as one-pixel points, their middles, as the build sees the stage doesn't call `placeBatchVertex`; and the planes cut it only where it writes `worldPosition`. Or it includes `batch.glsl` (`#include <helix/render/shaders/batch.glsl>`), which includes `view.glsl` and declares the attributes and uniforms above and the five outputs, so the stage declares none of them, and gives one function:

```glsl
// Places a batch draw's vertex as the batch's own stage does, from a position and a wide line's other end the stage may have moved
// (pass vertexPosition and vertexLineEnd to change nothing): a wide line's or a large point's corner pushed out across the screen by
// vertexCorner, lineWidth and pointSize. Returns the clip position, and writes the five outputs: worldPosition from the position
// given, the others from their attributes. The stage may write any of them again after the call.
vec4 placeBatchVertex(vec3 position, vec3 lineEnd);
```

A fragment stage is cut by `clipPlanes` before it runs, whichever compiled it: the macros wrap its `main`.

**The lighting include.** `#include <helix/render/shaders/lighting.glsl>` (fragment stage) declares everything a lit shader reads, so the shader declares none of it: the shared block `Lighting`, written at each `begin` and shared with every draw; its shared textures; and the draw's own lights as loose uniforms (`lightCount`, `lightPositions`, `lightDirections`, `lightColors`, `lightCones` and `receiveShadows`, which `Material3D` lists), in the shader's own loose block. It includes `view.glsl` and `color.glsl`. A material's shader includes `material.glsl` instead, which includes this and reads the material's surface (`Material3D`).

| Name | Type | What | |---|---|---| | `ambientLight` | vec4 | `environment`'s ambient light, linear radiance. | | `environmentIrradiance` | vec4[9] | Its map's spherical-harmonic irradiance. | | `environmentParams` | vec4 | Its intensity, last mip, rotation, and 1 when it has a map. | | `shadowMatrices` | mat4[24] | Each casting light's maps' matrices: a cascade or a cube face each. | | `shadowParams`, `shadowColors` | vec4[4] | Each casting light's first matrix, map count, bias and filter radius; its strength and color. | | `shadowCascadeSplits` | vec4 | Where the directional cascades end, in world units from the eye. | | `environmentTexture`, `brdfTexture`, `shadowTexture` | samplerCube, sampler2D, sampler2DArrayShadow | The prefiltered cube, the split-sum table, the shadow maps: shared textures. |

Its functions are helix-render's own shaders' shading, so a program's material shades as the built-in ones do. Every vector is in world space. The three shadings apply each of the draw's lights through its falloff, cone and shadow (when the draw receives), the ambient light, `bakedLight`, and the environment map's diffuse and reflected light, and return linear light toward the eye. They leave out what a material adds after shading: its emissive light (`emissive`), fog (`applyFog`), the alpha cutoff (a `discard`), and exposure, tone mapping and encoding (`writeColor`); `material.glsl`'s `readMaterialSurface` and `writeMaterialColor` do all four.

```glsl
struct Surface {
vec3 position;             // world units
vec3 normal;               // world space, unit length, turned toward the viewer: a back face's normal flipped
vec3 baseColor;            // linear
float alpha;               // 0 to 1: what blend mixes by; the shadings ignore it
float metallic;            // 0 to 1
float roughness;           // 0 to 1, taken as at least 0.03
float occlusion;           // 1 for none: scales the ambient, baked and environment light
vec3 specularColor;        // linear: MetallicRoughness's specular color times its intensity, Phong's specular color
float ior;
float shininess;           // Phong's exponent
float clearcoat;
float clearcoatRoughness;
vec3 clearcoatNormal;      // world space, unit length, turned as normal is
vec3 sheenColor;           // linear
float sheenRoughness;
float environmentIntensity;
vec3 bakedLight;           // linear irradiance from a light map, added as the ambient light is; 0 for none
vec3 emissive;             // linear light it gives off; the shadings leave it out
};
// A surface at a point with a normal and a base color: alpha 1, bakedLight and emissive 0, its other fields Material3D's defaults.
// The normal is taken as given: the shader turns it toward the viewer (gl_FrontFacing ? n : -n) for a face drawn from behind.
Surface makeSurface(vec3 position, vec3 normal, vec3 baseColor);
vec3 shadeMetallicRoughness(Surface surface);
vec3 shadePhong(Surface surface);
vec3 shadeLambert(Surface surface);
// One of the draw's lights (0 to lightCount - 1) arriving at a point: its radiance through its falloff, cone and shadow, and the
// unit direction toward it; for a shader shading by its own model. A hemisphere light arrives along the normal, its sky and ground
// blended by how far the normal faces up: diffuse light alone, which the built-in shadings add as they add the ambient light.
vec3 computeLightRadiance(int lightIndex, vec3 position, vec3 normal, out vec3 toLight);
// A casting light's shadow at a point (its index is lightCones[i].z): 1 where lit, toward its color by its strength where shadowed.
vec3 computeShadow(int shadowIndex, vec3 position, vec3 normal);
// The ambient light and the environment map's irradiance reaching a surface facing a direction.
vec3 computeAmbientLight(vec3 normal);
// The environment map's prefiltered light from a direction, blurred by a roughness.
vec3 computeEnvironmentLight(vec3 direction, float roughness);
```

**Order and batching.** Draws are drawn in the order they are called; nothing is sorted, so the program draws what is opaque first and what is blended after, farthest first. Each mesh is a GPU draw of its own a view, an instanced one one for all its copies. The batch draws join one GPU draw while they share a texture, the draw state and the shader values with nothing written to them between, and nothing else is drawn between them; a transform given to one, and `customData`, split nothing, as they are applied to the vertices as each draw is made. `Renderer.clearTarget` may be called with the batch open, and is recorded where it is called.

**Culling.** With `culling` on, a draw whose box is out of every view's frustum (`View3D.isInView`) is skipped: a mesh's bounds moved by its transform, each instanced copy apart, a model mesh by mesh, a billboard by the sphere it can turn in, points, lines, shapes, sprites and text by the box around them, a draw list by its box. A skinned mesh's box is its joints': each joint's box of the vertices it moves, recorded at `Renderer.createMesh`, moved by the joint's skinning matrix, all joined; a morphed mesh's grows by its targets' reach. That box can be larger than the posed mesh; `GpuMesh3D.computeBounds` gives the exact one. A shadow pass culls its casters against the light's volume, not the views'.

```haxe
var batch = new Batch3D(renderer);
var sun = new DirectionalLight3D();
sun.direction.set(-1, -2, -1);
sun.castsShadow = true;
batch.lights.push(sun);
batch.environment.setAmbient(0xff8090a0, .3);
// each frame, between Renderer.beginFrame and endFrame:
batch.begin(camera);
batch.drawBackground();
batch.drawModel(level, Matrix3D.fromTranslation(0, 0, 0, placement));
batch.end();
```

```haxe
function new(renderer:Renderer)
static macro function compileShader(fragment:String, ?options:haxe.macro.Expr.ExprOf<ShaderOptions>):haxe.macro.Expr.ExprOf<Shader>
static macro function compileShaderStages(vertex:String, fragment:String, ?options:haxe.macro.Expr.ExprOf<ShaderOptions>):haxe.macro.Expr.ExprOf<Shader>
var blend(default, set):Blend
var depthTest(default, set):DepthTest
var depthWrite(default, set):Bool
var cull(default, set):CullFace
var colorWrite(default, set):ColorChannels
var polygonMode(default, set):PolygonMode3D
var pointSize(default, set):Float
var pointSizeAttenuated(default, set):Bool
var shaderValues(default, set):Null<ShaderValues>
var customData:Int
var castShadows:Bool
var receiveShadows:Bool
final clipPlanes:Array<Float>
var fogged:Bool
var toneMapped(default, set):Bool
var shapeRegion(default, set):Null<TextureRegion2D>
final lights:Array<Light3D>
var environment:Environment3D
var fog:Null<Fog3D>
var culling:Bool
var open(default, null):Bool
function resetState():Void
function begin(camera:Camera3D):Void
function beginViews(views:Array<View3D>):Void
function end():Void
function drawBackground():Void
function drawMesh(mesh:GpuMesh3D, material:Material3D, transform:Matrix3D, ?skinning:Array<Matrix3D>, ?morphWeights:Array<Float>, ?tint:Int, ?state:MeshState3D):Void
function drawMeshInstanced(mesh:GpuMesh3D, material:Material3D, transforms:Array<Matrix3D>, ?colors:Array<Int>, ?transform:Matrix3D, ?firstInstanceIndex:Int = 0, ?instanceCount:Int):Void
function drawModel(model:GpuModel3D, transform:Matrix3D, ?boneMatrices:Array<Matrix3D>, ?tint:Int, ?state:MeshState3D):Void
function drawLine(x0:Float, y0:Float, z0:Float, x1:Float, y1:Float, z1:Float, color:Int):Void
function drawLines(positions:Array<Float>, color:Int, ?colors:Array<Int>, ?width:Float = 1., ?strip:Bool = false, ?transform:Matrix3D):Void
function strokeBox(bounds:Bounds3D, color:Int):Void
function strokeSphere(x:Float, y:Float, z:Float, radius:Float, color:Int):Void
function drawGrid(lineCount:Int, spacing:Float, color:Int):Void
function drawAxes(transform:Matrix3D, length:Float):Void
function drawBillboard(region:TextureRegion2D, x:Float, y:Float, z:Float, width:Float, height:Float, ?tint:Int = 0xffffffff, ?rotation:Float = 0.):Void
function drawPoints(positions:Array<Float>, color:Int, ?colors:Array<Int>, ?texture:Texture2D, ?transform:Matrix3D):Void
function drawTriangles(texture:Null<Texture2D>, positions:Array<Float>, ?texCoords:Array<Float>, ?colors:Array<Int>, ?indices:Array<Int>, ?normals:Array<Float>, ?transform:Matrix3D):Void
function drawPolyline(points:Array<Float>, thickness:Float, color:Int, ?transform:Matrix3D):Void
function fillTriangle(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, color:Int, ?transform:Matrix3D):Void
function fillRectangle(x:Float, y:Float, width:Float, height:Float, color:Int, ?transform:Matrix3D):Void
function strokeRectangle(x:Float, y:Float, width:Float, height:Float, thickness:Float, color:Int, ?transform:Matrix3D):Void
function fillRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, color:Int, ?transform:Matrix3D):Void
function strokeRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, thickness:Float, color:Int, ?transform:Matrix3D):Void
function fillCircle(x:Float, y:Float, radius:Float, color:Int, ?transform:Matrix3D):Void
function strokeCircle(x:Float, y:Float, radius:Float, thickness:Float, color:Int, ?transform:Matrix3D):Void
function fillEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, color:Int, ?transform:Matrix3D):Void
function strokeEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, thickness:Float, color:Int, ?transform:Matrix3D):Void
function fillPolygon(points:Array<Float>, color:Int, ?transform:Matrix3D):Bool
function strokePolygon(points:Array<Float>, thickness:Float, color:Int, ?transform:Matrix3D):Void
function drawSprite(region:TextureRegion2D, x:Float, y:Float, ?rotation:Float = 0., ?scaleX:Float = 1., ?scaleY:Float = 1., ?tint:Int = 0xffffffff, ?flipX:Bool = false, ?flipY:Bool = false, ?originX:Float, ?originY:Float, ?transform:Matrix3D):Void
function drawTextureRegion(texture:Texture2D, regionX:Float, regionY:Float, regionWidth:Float, regionHeight:Float, x:Float, y:Float, width:Float, height:Float, ?rotation:Float = 0., ?originX:Float = 0., ?originY:Float = 0., ?tint:Int = 0xffffffff, ?transform:Matrix3D):Void
function drawText(font:GpuFont2D, text:String, x:Float, y:Float, ?color:Int = 0xffffffff, ?size:Float, ?letterSpacing:Float = 0., ?kerned:Bool = true, ?transform:Matrix3D):Void
function drawTextLayout(layout:TextLayout2D, x:Float, y:Float, ?color:Int = 0xffffffff, ?transform:Matrix3D):Void
function drawList(list:DrawList3D, transform:Matrix3D):Void
```

- `new`: Creates a batch over a renderer, with its default shaders: every shading (skinned, morphed and instanced too), the shadow casters, the background, and the batch draws' (lines, points, triangles, shapes, sprites and text). A program carries the shaders of the draws it calls: the meshes' with `drawMesh` or `drawModel`, the wide lines' and large points' with `drawLines` or `drawPoints`, the tone-mapped batch draws' once `toneMapped` is set.
  - `renderer`: The renderer it records into.
- `compileShader`: Compiles a fragment stage over the batch's vertex stage, for a `Batch3D`'s batch draws (`shaderValues`).
  - `fragment`: The fragment stage's file, relative to the file holding the call.
  - `options`: Optional. Defines, includes and a file to watch, as `Shader.compile` takes them.
  - returns: The shader, for a `ShaderValues` over it.

  It compiles while the program builds, as helix-services' `Shader.compile` compiles one, and returns it as a value in the program: its vertex stage drawn the right way up into a render target whatever it writes (`ShaderOptions.clipScale`) and able to draw one-pixel points (`ShaderOptions.points`), helix-render's includes found (`#include <helix/render/shaders/color.glsl>`). A name the class lists declared with another type stops the build at the call. The fragment stage is GLSL as helix-services' `Shader.compile` takes it: `#version 300 es` or 330 to 440 (GL's form), or `#version 450` (Vulkan's), the batch's vertex stage given in the same form; GLSL ES 100 (raylib's) is not taken, and a layer adapts it first. The vertex stage passes `texCoord` (vec2), `color` (vec4), `customData` (vec4), `normal` (vec3) and `worldPosition` (vec3), read by name; the fragment stage is cut by `clipPlanes` before its `main` runs.
- `compileShaderStages`: Compiles a vertex and a fragment stage, both the program's, for a `Batch3D`'s batch draws (`shaderValues`).
  - `vertex`: The vertex stage's file, relative to the file holding the call.
  - `fragment`: The fragment stage's file, relative to the file holding the call.
  - `options`: Optional. Defines, includes and a file to watch.
  - returns: The shader, for a `ShaderValues` over it.

  It compiles while the program builds, as helix-services' `Shader.compile` compiles one, and returns it as a value in the program: its vertex stage drawn the right way up into a render target whatever it writes (`ShaderOptions.clipScale`) and able to draw one-pixel points (`ShaderOptions.points`), helix-render's includes found (`#include <helix/render/shaders/color.glsl>`). A name the class lists declared with another type stops the build at the call. Both stages are GLSL in one form, as helix-services' `Shader.compile` takes it: `#version 300 es` or 330 to 440, or `#version 450`. The vertex stage may place its vertices itself, declaring what it reads; wide lines and large points are then drawn as their one-pixel middles. Placed by `placeBatchVertex(position, lineEnd)` (`#include <helix/render/shaders/batch.glsl>`), they are drawn wide and large, as the class says.
- `blend`: Gets or sets how the following batch draws are combined with what is under them: Alpha (`Blend.ALPHA`) until set; any factors and operations the platform's `Blend` takes. A mesh is blended as its material says, or as its draw's `MeshState3D` says.
- `depthTest`: Gets or sets the following batch draws' depth test: LessEqual until set; Off draws them over everything drawn before. A mesh is tested as its material says, or as its draw's `MeshState3D` says.
- `depthWrite`: Gets or sets a value indicating whether the following batch draws write depth: true until set. A mesh writes depth as its material says, or as its draw's `MeshState3D` says.
- `cull`: Gets or sets which faces of the following batch draws' triangles aren't drawn: None until set, so both sides are. A mesh is culled as its material says, or as its draw's `MeshState3D` says.
- `colorWrite`: Gets or sets the color channels the following batch draws write: all four until set. A mesh writes what its material's `colorWrite` says, or what its draw's `MeshState3D` says.
- `polygonMode`: Gets or sets how the following meshes' and batch draws' faces are drawn: filled, as their edges, or as their corners. Fill until set.
- `pointSize`: Gets or sets the size of the following points (`drawPoints`, `PolygonMode3D.Points`), in framebuffer pixels: 1 until set. Below 0 is clamped to 0.
  With `pointSizeAttenuated` on, under a perspective projection, a point is `pointSize × (viewportHeight / 2) / -z` framebuffer pixels across, where `viewportHeight` is its view's rectangle's height in framebuffer pixels and `-z` its distance in front of the eye along the view's axis: three.js's `size` with `sizeAttenuation`, so a three.js layer passes a material's `size` as it is (and, not attenuated, `size` times the device pixel ratio, as three.js does). A point so drawn is `pointSize` world units across only where the projection's vertical field of view is 90°. Under an orthographic projection it is not attenuated.
- `pointSizeAttenuated`: Gets or sets a value indicating whether the following points shrink with distance, as `pointSize` gives the formula: false until set.
- `shaderValues`: Gets or sets the program's own shader the following batch draws are drawn with, as values over it carrying its own uniforms and textures, or null for the batch's: null until set. A mesh is drawn with its material's.
  Its shader is compiled by `compileShader` or `compileShaderStages`, and reads the names the class lists. Its values are read as each draw is made.
- `customData`: Gets or sets four bytes each vertex of the following batch draws carries, for a program's shader to read as `customData`, as `Batch2D.customData` does: 0 until set. It splits nothing; the batch's own shader ignores it.
- `castShadows`: Gets or sets a value indicating whether the following meshes and models cast shadows, where their material's `castShadows` is on too: true until set.
- `receiveShadows`: Gets or sets a value indicating whether the following meshes and models are darkened by shadows, where their material's `receiveShadows` is on too: true until set.
- `clipPlanes`: Gets the planes the following draws are cut by, a, b, c and d each, at most 4 planes: a point where a x + b y + c z + d is below 0 isn't drawn. Empty until changed; changed in place, read at each draw.
- `fogged`: Gets or sets a value indicating whether the following batch draws are faded by `fog`, as three.js's `PointsMaterial.fog` and `LineBasicMaterial.fog`: true until set. Nothing is faded while `fog` is null. A mesh is fogged as its material's `fog` says.
- `toneMapped`: Gets or sets a value indicating whether the following batch draws are exposed and tone mapped into an sRGB target by the renderer's `exposure` and `toneMapping`, as lit color is: false until set, so their colors arrive as given; three.js's `PointsMaterial.toneMapped`, true there, is set per draw by a three.js layer. Into an RGBA16F target nothing is tone mapped as it is drawn (`Material3D.toneMapped`). A mesh is tone mapped as its material's `toneMapped` says.
- `shapeRegion`: Gets or sets the region the shapes (`fillTriangle` to `strokePolygon`) are drawn with: null until set, for the batch's own white texture.
  Shapes read the texel at the region's center alone, so it must be white there: `Texture2D.writeWhiteTexel` makes one on a sheet or an atlas, and shapes then join one GPU draw with its sprites or text, as raylib's `SetShapesTexture` does. Assigning it ends the open GPU draw. It is not draw state: `resetState` leaves it.
- `lights`: Gets the lights that light its lit materials, read at each `begin`: empty until the program adds some.
- `environment`: Gets or sets the ambient light, the environment map and the background, read at each `begin`: until set, an environment of its own with no light, so a lit material is lit by what the program sets alone, black under none.
- `fog`: Gets or sets the fog, read at each `begin`, or null for none: null until set.
- `culling`: Gets or sets a value indicating whether draws out of view are skipped: true until set; read at each draw.
- `open`: Gets a value indicating whether it is open: from `begin` until `end`.
- `resetState`: Puts the draw state back to its defaults: `blend` Alpha, `depthTest` LessEqual, `depthWrite` on, `cull` None, `colorWrite` all, `polygonMode` Fill, `pointSize` 1 not attenuated, no `shaderValues`, `customData` 0, `castShadows` and `receiveShadows` on, no `clipPlanes`, `fogged` on and `toneMapped` off.
  It may be called at any time, open or not. `lights`, `environment`, `fog`, `culling` and `shapeRegion` are left as they are.
- `begin`: Opens the batch for drawing in the renderer's current pass through a camera, filling the renderer's viewport.
  - `camera`: The camera.
  - throws `String`: No frame being recorded, or a batch (this or another) already open.

  The camera is read now, its aspect the viewport's, and so are `lights`, `environment`, `fog`, and the renderer's `exposure` and `toneMapping`: changing them after takes effect at the next `begin`. The draw state is kept as the program left it.
- `beginViews`: Opens the batch for drawing in the renderer's current pass through views, each draw drawn once in each.
  - `views`: The views, in the order each draw is drawn in them; at least one.
  - throws `String`: No frame being recorded, a batch (this or another) already open, no views, or a view's rectangle outside the renderer's viewport.

  The views are read now, as `begin` reads a camera, and so are `lights`, `environment`, `fog`, and the renderer's `exposure` and `toneMapping`. The draw state is kept as the program left it.
- `end`: Closes the batch, so another can open or the pass can end.
  - throws `String`: The batch isn't open.
- `drawBackground`: Draws the environment's background behind everything: its map, turned, as bright and as blurred as `environment` says, at the far plane, depth-tested so it shows only where nothing nearer is drawn. Nothing when it has none.
  It is drawn where it is called; first, it costs every pixel; after the opaque meshes, only the ones they leave.
- `drawMesh`: Draws a mesh with a material, placed by a transform, its faces as `polygonMode` says.
  - `mesh`: The mesh.
  - `material`: The material, read as it is now.
  - `transform`: The mesh's place in the world, read now.
  - `skinning`: Optional. Its skin's matrices (`Skin3D.computeSkinning`), read now, for a mesh with joints; the mesh is drawn unskinned when omitted.
  - `morphWeights`: Optional. How much of each of its morph targets is added, read now, by target; none when omitted.
  - `tint`: Optional. A color, 0xAARRGGBB, multiplying the material's `baseColor` for this draw alone, as raylib's `DrawModel` tint does; white when omitted.
  - `state`: Optional. State this draw takes in place of the material's (`MeshState3D`), read now; the material's when omitted.
  - throws `String`: A disposed mesh, or a texture of the material disposed.

  Its blend, depth test, depth write, cull and color channels are the material's, but for those `state` gives, which hold for this draw alone and change nothing in the material: a layer whose state is global, as raylib's rlgl is, keeps one `MeshState3D` and passes it each draw.
- `drawMeshInstanced`: Draws a mesh many times with one material, each copy placed by its own transform and tinted by its own color, in one GPU draw.
  - `mesh`: The mesh.
  - `material`: The material, read as it is now.
  - `transforms`: Each copy's place in the parent's units, read now.
  - `colors`: Optional. Each copy's color, 0xAARRGGBB, multiplying its base color, read now, indexed as `transforms`; white when omitted.
  - `transform`: Optional. The parent all the copies are placed in, as an InstancedMesh's own place: each copy is at it times its own; identity when omitted.
  - `firstInstanceIndex`: Optional. The index in `transforms` of the first copy drawn; defaults to 0.
  - `instanceCount`: Optional. How many copies are drawn from it, as an InstancedMesh's `count`; every one to the end of `transforms` when omitted. None draws nothing.
  - throws `String`: A disposed mesh, a texture of the material disposed, or copies past the end of `transforms`.

  A shader for it reads each copy's transform as `instanceModel`, its color as `instanceColor`, and the parent transform as `model`; the default does. A mesh's joints are ignored here. With `culling` on, the copies out of view are left out of the draw.
- `drawModel`: Draws a model: each of its meshes with its material, placed by a transform, each skinned mesh posed by its skin.
  - `model`: The model.
  - `transform`: The model's place in the world, read now.
  - `boneMatrices`: Optional. Each of its skeleton's bones' place in the model (`Skeleton3D.computeWorld`), read now; the rest pose when omitted. Ignored for a model without a skeleton.
  - `tint`: Optional. A color, 0xAARRGGBB, multiplying each material's `baseColor` for this draw alone, as raylib's `DrawModel` tint does; white when omitted.
  - `state`: Optional. State every mesh of this draw takes in place of its material's (`MeshState3D`), read now; each material's when omitted.
  - throws `String`: A disposed model.

  Each mesh's blend, depth test, depth write, cull and color channels are its material's, but for those `state` gives, as `drawMesh` takes them.
- `drawLine`: Draws a line between two points, one pixel wide.
  - `x0`: The start's x.
  - `y0`: The start's y.
  - `z0`: The start's z.
  - `x1`: The end's x.
  - `y1`: The end's y.
  - `z1`: The end's z.
  - `color`: The color.
- `drawLines`: Draws lines through positions, as segments two by two or as one strip, of a width in pixels.
  - `positions`: The positions, x, y and z each, read now.
  - `color`: The color of lines without colors of their own.
  - `colors`: Optional. Each position's color, 0xAARRGGBB, blended along each line; `color` everywhere when omitted.
  - `width`: Optional. The width, in framebuffer pixels, whatever the transform; defaults to 1.
  - `strip`: Optional. Whether the positions are one line through them all, rather than a segment each two; defaults to false.
  - `transform`: Optional. What the positions are moved by, as a Line's own place; identity when omitted.

  A line wider than a pixel is a quad made in the vertex stage, facing the screen, the same on every backend.
- `strokeBox`: Draws a box's twelve edges.
  - `bounds`: The box, in world units.
  - `color`: The color.
- `strokeSphere`: Draws a sphere as three circles about its center, one square to each axis.
  - `x`: The center's x.
  - `y`: The center's y.
  - `z`: The center's z.
  - `radius`: The radius.
  - `color`: The color.
- `drawGrid`: Draws a grid of lines on the ground (y 0), centered on the origin.
  - `lineCount`: The number of lines each way.
  - `spacing`: The distance between two lines.
  - `color`: The color.
- `drawAxes`: Draws a transform's axes from its origin: x red, y green, z blue.
  - `transform`: The transform, as a mesh would be placed by it.
  - `length`: Each axis' length, before the transform's scale.
- `drawBillboard`: Draws a texture's region facing the camera, upright with the camera's up and turned about its center, its center at a point.
  - `region`: The region of the texture.
  - `x`: The center's x.
  - `y`: The center's y.
  - `z`: The center's z.
  - `width`: The width, in world units.
  - `height`: The height, in world units.
  - `tint`: Optional. The color its texels are multiplied by; defaults to white.
  - `rotation`: Optional. Its turn in the screen's plane, in radians, clockwise; defaults to 0.
- `drawPoints`: Draws positions as points of `pointSize`, unlit, with the draw state.
  - `positions`: The points' positions, x, y and z each, in world units; read now.
  - `color`: The color of points without one of their own.
  - `colors`: Optional. Each point's own color, 0xAARRGGBB; `color` for every point when omitted.
  - `texture`: Optional. The texture across each square; white when omitted.
  - `transform`: Optional. What the positions are moved by, as a Points object's own place; identity when omitted. A point's size is not scaled by it.

  A point of 1 pixel is the pixel its position falls in; a larger one is a square facing the screen, its center at the position, with the texture across it, as three.js's PointsMaterial's map is.
- `drawTriangles`: Draws triangles as given, in world units: textured, colored by vertex, or both, unlit, for what has no mesh; as their edges or corners in another `polygonMode`.
  - `texture`: The texture, or null for white.
  - `positions`: The vertices' positions, x, y and z each.
  - `texCoords`: Optional. The texture coordinates, u and v each; 0, 0 for every vertex when omitted.
  - `colors`: Optional. Each vertex's color, 0xAARRGGBB; white when omitted.
  - `indices`: Optional. Three a triangle, indexing the vertices; when omitted, the vertices are the triangles in order.
  - `normals`: Optional. Each vertex's normal, x, y and z; 0, 0, 1 for every vertex when omitted.
  - `transform`: Optional. What the positions and normals are moved by; identity when omitted.

  The arrays are read during the call, so they may be reused for the next. Normals are for a program's own shader (`shaderValues`), which may light them; the batch's own ignores them.
- `drawPolyline`: Draws lines through points in a plane, one after another, joined at each point with a miter, or a bevel where the miter would reach past twice the thickness, as `Batch2D.drawPolyline` draws them; two points are one line, its ends square, cut at the points.
  - `points`: The points, x and y each, in the plane's units; fewer than two draws nothing.
  - `thickness`: The width, in the plane's units.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in; identity, the world's xy plane, when omitted.
- `fillTriangle`: Fills a triangle in a plane.
  - `x0`: The first corner, across.
  - `y0`: The first corner, down.
  - `x1`: The second corner, across.
  - `y1`: The second corner, down.
  - `x2`: The third corner, across.
  - `y2`: The third corner, down.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in; identity when omitted.
- `fillRectangle`: Fills a rectangle in a plane.
  - `x`: The left edge.
  - `y`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in; identity when omitted.
- `strokeRectangle`: Draws a rectangle's outline in a plane.
  - `x`: The left edge.
  - `y`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `thickness`: The outline's width, centered on the edges.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in; identity when omitted.
- `fillRoundedRectangle`: Fills a rectangle with rounded corners in a plane.
  - `x`: The left edge.
  - `y`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `radius`: The corners' radius, clamped to half the shorter side.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in; identity when omitted.
- `strokeRoundedRectangle`: Draws the outline of a rectangle with rounded corners in a plane.
  - `x`: The left edge.
  - `y`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `radius`: The corners' radius, clamped to half the shorter side.
  - `thickness`: The outline's width, centered on the edges.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in; identity when omitted.
- `fillCircle`: Fills a circle in a plane.
  - `x`: The center, across.
  - `y`: The center, down.
  - `radius`: The radius.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in; identity when omitted.
- `strokeCircle`: Draws a circle's outline in a plane.
  - `x`: The center, across.
  - `y`: The center, down.
  - `radius`: The radius.
  - `thickness`: The outline's width, centered on the circle.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in; identity when omitted.
- `fillEllipse`: Fills an ellipse in a plane, its axes across and down.
  - `x`: The center, across.
  - `y`: The center, down.
  - `radiusX`: The radius across.
  - `radiusY`: The radius down.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in; identity when omitted.
- `strokeEllipse`: Draws an ellipse's outline in a plane.
  - `x`: The center, across.
  - `y`: The center, down.
  - `radiusX`: The radius across.
  - `radiusY`: The radius down.
  - `thickness`: The outline's width, centered on the ellipse.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in; identity when omitted.
- `fillPolygon`: Fills a polygon in a plane, convex or not, whose edges don't cross.
  - `points`: The corners in order, x and y each, either way round; fewer than three draws nothing.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in; identity when omitted.
  - returns: False when its edges cross, and nothing is drawn.
- `strokePolygon`: Draws a polygon's outline in a plane: lines through its corners and back to the first, joined as `drawPolyline` joins them.
  - `points`: The corners in order, x and y each; fewer than two draws nothing.
  - `thickness`: The outline's width, centered on the edges.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in; identity when omitted.
- `drawSprite`: Draws a texture's region in a plane, turned and scaled about its origin, the origin at a point, as `Batch2D.drawSprite` draws it.
  - `region`: The region of the texture.
  - `x`: Where the origin goes, across.
  - `y`: Where the origin goes, down the texture.
  - `rotation`: Optional. The turn about the origin, in radians, from x toward y; defaults to 0.
  - `scaleX`: Optional. The scale across; defaults to 1, a unit a texel.
  - `scaleY`: Optional. The scale down; defaults to 1.
  - `tint`: Optional. The color its texels are multiplied by; defaults to white.
  - `flipX`: Optional. Whether it is mirrored across about its origin, after its scale; defaults to false.
  - `flipY`: Optional. Whether it is mirrored down about its origin, after its scale; defaults to false.
  - `originX`: Optional. The point it turns about and is placed by, in texels from the region's left; the region's `originX` when omitted.
  - `originY`: Optional. That point, in texels from the region's top; the region's `originY` when omitted.
  - `transform`: Optional. The plane it is drawn in; identity, the world's xy plane, when omitted.

  It lies in the plane z 0 of the transform, x across and y down the texture.
- `drawTextureRegion`: Draws a rectangle of a texture into a rectangle in a plane, turned about an origin, as `Batch2D.drawTextureRegion` draws it (raylib's `DrawTexturePro`): no region is made for it.
  - `texture`: The texture.
  - `regionX`: The part's left edge, in texels from the texture's left.
  - `regionY`: The part's top edge, in texels from the texture's top.
  - `regionWidth`: The part's width, in texels; negative mirrors it across.
  - `regionHeight`: The part's height, in texels; negative mirrors it down.
  - `x`: Where the origin goes, across.
  - `y`: Where the origin goes, down the texture.
  - `width`: The width it is drawn at.
  - `height`: The height it is drawn at.
  - `rotation`: Optional. The turn about the origin, in radians, from x toward y; defaults to 0.
  - `originX`: Optional. The point it turns about and is placed by, from the drawn rectangle's left; defaults to 0.
  - `originY`: Optional. That point, from the drawn rectangle's top; defaults to 0.
  - `tint`: Optional. The color its texels are multiplied by; defaults to white.
  - `transform`: Optional. The plane it is drawn in; identity when omitted.
- `drawText`: Draws text in a font in a plane, as `Batch2D.drawText` draws it: line by line, left-aligned, its first line's top at a point.
  - `font`: The font.
  - `text`: The text; a character the font lacks is drawn as the font's stand-in, as `GpuFont2D` says.
  - `x`: The left edge.
  - `y`: The top of the first line, lines following down the texture.
  - `color`: Optional. The color; defaults to white.
  - `size`: Optional. The size, as the font's size is measured; the font's own, a unit a pixel of it, when omitted.
  - `letterSpacing`: Optional. Space added after each character; defaults to 0.
  - `kerned`: Optional. Whether pairs of characters are kerned as the font gives them; defaults to true. raylib's `DrawTextEx` doesn't kern.
  - `transform`: Optional. The plane it is drawn in; identity when omitted.
- `drawTextLayout`: Draws laid-out text in a plane, wrapped and aligned as its layout says, as `Batch2D.drawTextLayout` draws it.
  - `layout`: The layout.
  - `x`: The left edge of the layout's box, in which its lines are aligned: the box is `maxWidth` wide, or as wide as its widest line when `maxWidth` is 0.
  - `y`: The top of the first line.
  - `color`: Optional. The color; defaults to white.
  - `transform`: Optional. The plane it is drawn in; identity when omitted.
- `drawList`: Replays a draw list: its calls in the order recorded, in its own units placed by a transform.
  - `list`: The list.
  - `transform`: Its place in the world, read now.
  - throws `String`: A mesh, model or texture it holds disposed.

  With `culling` on, a list whose box (`DrawList3D.bounds`), so placed, is out of every view is skipped whole. Its calls are drawn with the draw state as it is now, `customData` among it.

## ColorSpace

*abstract* in [`libs/render/src/helix/render/ColorSpace.hx`](../../libs/render/src/helix/render/ColorSpace.hx), `import helix.render.ColorSpace;`

Specifies how a texture's texels are read by helix-render's own shaders: as sRGB colors, decoded to linear light, or as linear values.

- `ColorSpace.Auto`: As the slot it is used in: sRGB in a color slot (base color, emissive, a sprite's or a glyph's texture), linear in a data slot (normal, metallic-roughness, occlusion, alpha, light).
- `ColorSpace.Srgb`: sRGB colors, decoded to linear light wherever it is used.
- `ColorSpace.Linear`: Linear values, read as they are wherever it is used.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Auto, Srgb): what Std.string, interpolation and trace show.

## CubeTexture3D

*class* in [`libs/render/src/helix/render/CubeTexture3D.hx`](../../libs/render/src/helix/render/CubeTexture3D.hx), `import helix.render.CubeTexture3D;`

Represents a cube of six square images on the GPU, sampled by direction: a skybox a program's shader draws, or a reflection it reads (`samplerCube`).

`Renderer.createCubeTexture` makes one; a program's shader reads it through `sharedTexture` (`values.shareTexture(shader.getSampler("skybox"), cube.sharedTexture)`). The program frees it with `dispose`. An environment that lights materials is an `EnvironmentMap3D`, baked from a picture of all around.

```haxe
final size:Int
var sampling(default, set):Sampling
final sharedTexture:ShaderSharedTexture
var handle(default, null):Int
function dispose():Void
```

- `size`: Gets each face's width and height, in texels.
- `sampling`: Gets or sets how its draws sample it: `Sampling.LINEAR` until set, its mipmaps blended when it has them. A change applies to the draws after it.
- `sharedTexture`: Gets the cube as helix-services' shared texture, for a program's own shader's `samplerCube`: its handle and its `sampling`, kept current by helix-render; 0, no texture, once disposed.
- `handle`: Gets the platform's handle, for what only `IGraphics` does with it; 0 once disposed.
- `dispose`: Frees the cube on the GPU, after the frame being recorded when it holds a draw with it. A second call does nothing.

## DirectionalLight3D

*class* in [`libs/render/src/helix/render/DirectionalLight3D.hx`](../../libs/render/src/helix/render/DirectionalLight3D.hx), `import helix.render.DirectionalLight3D;`, extends `Light3D`

Represents the sun: light from one direction, reaching everything alike, wherever it is.

```haxe
var sun = new DirectionalLight3D();
sun.direction.set(-1, -2, -1);
batch.lights.push(sun);
```

```haxe
function new()
final direction:Vector3D
```

- `new`: Creates a white directional light of intensity π shining straight down: a surface facing it shows its own color.
- `direction`: Gets the direction it shines in, in world units; it needn't be of length 1. Straight down until changed; a direction of length 0 is taken as straight down.

## DrawList2D

*class* in [`libs/render/src/helix/render/DrawList2D.hx`](../../libs/render/src/helix/render/DrawList2D.hx), `import helix.render.DrawList2D;`

Represents 2D drawing recorded once and replayed by a `Batch2D` as often as wanted (`Batch2D.drawList`), under a transform: a HUD panel, a level's static decoration, a shape built of many calls.

A program records into it with the calls `Batch2D` draws with, named alike, in the list's own units; `makeEmpty` empties it to record again. A replay draws the calls in the order recorded, batched as `Batch2D` batches them, with the batch's `blend`, `shaderValues` and `customData` at the replay; the list holds no state of its own. It holds references to the textures, regions, fonts and layouts it is given and owns none: a texture disposed after it was recorded makes a replay throw, and a layout is drawn as it is at each replay. Point and vertex arrays are copied. It may be recorded at any time, outside a frame too, as it draws nothing itself.

```haxe
var panel = new DrawList2D();
panel.fillRoundedRectangle(0, 0, 220, 64, 8, 0xc0101828);
panel.strokeRoundedRectangle(0, 0, 220, 64, 8, 2, 0xff4080c0);
panel.drawText(font, "Cargo", 12, 10);
// each frame:
batch.drawList(panel, Matrix2D.fromTranslation(16, 16, place));
```

```haxe
function new()
final bounds:Bounds2D
var callCount(default, null):Int
function makeEmpty():DrawList2D
function drawTexture(texture:Texture2D, x:Float, y:Float, ?tint:Int = 0xffffffff):Void
function drawTextureRegion(texture:Texture2D, regionX:Float, regionY:Float, regionWidth:Float, regionHeight:Float, x:Float, y:Float, width:Float, height:Float, ?rotation:Float = 0., ?originX:Float = 0., ?originY:Float = 0., ?tint:Int = 0xffffffff):Void
function drawSprite(region:TextureRegion2D, x:Float, y:Float, ?rotation:Float = 0., ?scaleX:Float = 1., ?scaleY:Float = 1., ?tint:Int = 0xffffffff, ?flipX:Bool = false, ?flipY:Bool = false, ?originX:Float, ?originY:Float):Void
function drawLine(x0:Float, y0:Float, x1:Float, y1:Float, thickness:Float, color:Int):Void
function drawPolyline(points:Array<Float>, thickness:Float, color:Int):Void
function fillTriangle(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, color:Int):Void
function fillRectangle(x:Float, y:Float, width:Float, height:Float, color:Int):Void
function strokeRectangle(x:Float, y:Float, width:Float, height:Float, thickness:Float, color:Int):Void
function fillRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, color:Int):Void
function strokeRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, thickness:Float, color:Int):Void
function fillCircle(x:Float, y:Float, radius:Float, color:Int):Void
function strokeCircle(x:Float, y:Float, radius:Float, thickness:Float, color:Int):Void
function fillEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, color:Int):Void
function strokeEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, thickness:Float, color:Int):Void
function fillPolygon(points:Array<Float>, color:Int):Bool
function strokePolygon(points:Array<Float>, thickness:Float, color:Int):Void
function drawTriangles(texture:Null<Texture2D>, positions:Array<Float>, ?texCoords:Array<Float>, ?colors:Array<Int>, ?indices:Array<Int>):Void
function drawText(font:GpuFont2D, text:String, x:Float, y:Float, ?color:Int = 0xffffffff, ?size:Float, ?letterSpacing:Float = 0., ?kerned:Bool = true):Void
function drawTextLayout(layout:TextLayout2D, x:Float, y:Float, ?color:Int = 0xffffffff):Void
```

- `new`: Creates an empty list.
- `bounds`: Gets the box around what it holds, in its own units: empty when it holds nothing. Text is measured as it is recorded.
- `callCount`: Gets the number of calls recorded.
- `makeEmpty`: Removes every call, to record again.
  - returns: This list.
- `drawTexture`: Records a whole texture at its size, its top left at a point.
  - `texture`: The texture.
  - `x`: The left edge.
  - `y`: The top edge.
  - `tint`: Optional. The color its texels are multiplied by; defaults to white.
- `drawTextureRegion`: Records a rectangle of a texture drawn into a rectangle, turned about an origin, as `Batch2D.drawTextureRegion` draws it.
  - `texture`: The texture.
  - `regionX`: The part's left edge, in texels from the texture's left.
  - `regionY`: The part's top edge, in texels from the texture's top.
  - `regionWidth`: The part's width, in texels; negative mirrors it left to right.
  - `regionHeight`: The part's height, in texels; negative mirrors it top to bottom.
  - `x`: Where the origin goes, across.
  - `y`: Where the origin goes, down.
  - `width`: The width it is drawn at, in the list's units.
  - `height`: The height it is drawn at, in the list's units.
  - `rotation`: Optional. The turn about the origin, in radians; defaults to 0.
  - `originX`: Optional. The point it turns about and is placed by, in the list's units from the drawn rectangle's left; defaults to 0.
  - `originY`: Optional. That point, in the list's units from the drawn rectangle's top; defaults to 0.
  - `tint`: Optional. The color its texels are multiplied by; defaults to white.
- `drawSprite`: Records a texture's region, turned and scaled about its origin, the origin at a point.
  - `region`: The region of the texture.
  - `x`: Where the origin goes, across.
  - `y`: Where the origin goes, down.
  - `rotation`: Optional. The turn about the origin, in radians; defaults to 0.
  - `scaleX`: Optional. The scale across; defaults to 1, the region's size in texels.
  - `scaleY`: Optional. The scale down; defaults to 1.
  - `tint`: Optional. The color its texels are multiplied by; defaults to white.
  - `flipX`: Optional. Whether it is mirrored left to right about its origin, after its scale; defaults to false.
  - `flipY`: Optional. Whether it is mirrored top to bottom about its origin, after its scale; defaults to false.
  - `originX`: Optional. The point it turns about and is placed by, in texels from the region's left; the region's `originX` when omitted.
  - `originY`: Optional. That point, in texels from the region's top; the region's `originY` when omitted.

  A negative scale flips the sprite about its origin: -1 across mirrors it left to right. `flipX` and `flipY` flip it the same way again, so they mirror a sprite whatever its scale: true with a scale of -1 draws it unflipped.
- `drawLine`: Records a line between two points.
  - `x0`: The start, across.
  - `y0`: The start, down.
  - `x1`: The end, across.
  - `y1`: The end, down.
  - `thickness`: The width, in the list's units; its ends are square, cut at the points.
  - `color`: The color.
- `drawPolyline`: Records lines through points, one after another, joined at each point with a miter, or a bevel where the miter would reach past twice the thickness.
  - `points`: The points, x and y each; fewer than two draws nothing.
  - `thickness`: The width, in the list's units.
  - `color`: The color.
- `fillTriangle`: Records a filled triangle.
  - `x0`: The first corner, across.
  - `y0`: The first corner, down.
  - `x1`: The second corner, across.
  - `y1`: The second corner, down.
  - `x2`: The third corner, across.
  - `y2`: The third corner, down.
  - `color`: The color.
- `fillRectangle`: Records a filled rectangle.
  - `x`: The left edge.
  - `y`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `color`: The color.
- `strokeRectangle`: Records a rectangle's outline.
  - `x`: The left edge.
  - `y`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `thickness`: The outline's width, centered on the edges.
  - `color`: The color.
- `fillRoundedRectangle`: Records a filled rectangle with rounded corners.
  - `x`: The left edge.
  - `y`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `radius`: The corners' radius, clamped to half the shorter side.
  - `color`: The color.
- `strokeRoundedRectangle`: Records the outline of a rectangle with rounded corners.
  - `x`: The left edge.
  - `y`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `radius`: The corners' radius, clamped to half the shorter side.
  - `thickness`: The outline's width, centered on the edges.
  - `color`: The color.
- `fillCircle`: Records a filled circle.
  - `x`: The center, across.
  - `y`: The center, down.
  - `radius`: The radius.
  - `color`: The color.
- `strokeCircle`: Records a circle's outline.
  - `x`: The center, across.
  - `y`: The center, down.
  - `radius`: The radius.
  - `thickness`: The outline's width, centered on the circle.
  - `color`: The color.
- `fillEllipse`: Records a filled ellipse whose axes run across and down.
  - `x`: The center, across.
  - `y`: The center, down.
  - `radiusX`: The radius across.
  - `radiusY`: The radius down.
  - `color`: The color.
- `strokeEllipse`: Records an ellipse's outline.
  - `x`: The center, across.
  - `y`: The center, down.
  - `radiusX`: The radius across.
  - `radiusY`: The radius down.
  - `thickness`: The outline's width, centered on the ellipse.
  - `color`: The color.
- `fillPolygon`: Records a filled polygon, convex or not, whose edges don't cross.
  - `points`: The corners in order, x and y each, either way round; fewer than three draws nothing.
  - `color`: The color.
  - returns: False when its edges cross, and nothing is recorded.
- `strokePolygon`: Records a polygon's outline: lines through its corners and back to the first, joined as `drawPolyline` joins them.
  - `points`: The corners in order, x and y each; fewer than two draws nothing.
  - `thickness`: The outline's width, centered on the edges.
  - `color`: The color.
- `drawTriangles`: Records triangles as given: textured, colored by vertex, or both, for what the shapes here don't make.
  - `texture`: The texture, or null for white.
  - `positions`: The vertices' positions, x and y each.
  - `texCoords`: Optional. The texture coordinates, u and v each, 0 to 1 across the texture; 0, 0 for every vertex when omitted.
  - `colors`: Optional. Each vertex's color, 0xAARRGGBB; white when omitted.
  - `indices`: Optional. Three a triangle, indexing the vertices; when omitted, the vertices are the triangles in order.

  The arrays are copied, so they may be reused.
- `drawText`: Records text in a font, line by line at each line break, left-aligned, its first line's top at a point.
  - `font`: The font.
  - `text`: The text; a character the font lacks is drawn as the font's stand-in, as `GpuFont2D` says.
  - `x`: The left edge.
  - `y`: The top of the first line: its ascent above the baseline.
  - `color`: Optional. The color; defaults to white.
  - `size`: Optional. The size, in the list's units, as the font's size is measured; the font's own when omitted.
  - `letterSpacing`: Optional. Space added after each character, in the list's units; defaults to 0.
  - `kerned`: Optional. Whether pairs of characters are kerned as the font gives them; defaults to true. raylib's `DrawTextEx` doesn't kern.

  A distance-field font stays sharp at any size; another is scaled from its atlas. Pairs of characters are kerned as the font gives them, unless `kerned` is false.
- `drawTextLayout`: Records laid-out text, wrapped and aligned as its layout says, the layout's top left at a point.
  - `layout`: The layout.
  - `x`: The left edge of the layout's box, in which its lines are aligned: the box is `maxWidth` wide, or as wide as its widest line when `maxWidth` is 0.
  - `y`: The top of the first line.
  - `color`: Optional. The color; defaults to white.

  The layout is held, not copied: it is drawn as it is at each replay.

## DrawList3D

*class* in [`libs/render/src/helix/render/DrawList3D.hx`](../../libs/render/src/helix/render/DrawList3D.hx), `import helix.render.DrawList3D;`

Represents 3D drawing recorded once and replayed by a `Batch3D` as often as wanted (`Batch3D.drawList`), under a transform: a debug grid, a path, gizmos, a group of props placed together.

A program records into it with `Batch3D`'s calls for meshes, models and the batch draws (lines, debug shapes, billboards, points, triangles, shapes, sprites and text), named alike, in the list's own units; `makeEmpty` empties it to record again. A replay draws the calls in the order recorded, batched as `Batch3D` batches them, with the batch's draw state, views, lights, environment and fog at the replay; the list holds no state of its own. It holds references to the meshes, models, materials, textures, regions, fonts and layouts it is given and owns none: one disposed after it was recorded makes a replay throw, and a material is drawn as it is at each replay. Arrays, boxes and matrices given are copied. It may be recorded at any time, outside a frame too.

```haxe
var guides = new DrawList3D();
guides.drawGrid(40, 1, 0xff404858);
guides.drawAxes(new Matrix3D(), 2);
// each frame, inside batch.begin and end:
batch.drawList(guides, identity);
```

```haxe
function new()
final bounds:Bounds3D
var callCount(default, null):Int
function makeEmpty():DrawList3D
function drawMesh(mesh:GpuMesh3D, material:Material3D, transform:Matrix3D, ?skinning:Array<Matrix3D>, ?morphWeights:Array<Float>, ?tint:Int, ?state:MeshState3D):Void
function drawMeshInstanced(mesh:GpuMesh3D, material:Material3D, transforms:Array<Matrix3D>, ?colors:Array<Int>, ?transform:Matrix3D, ?firstInstanceIndex:Int = 0, ?instanceCount:Int):Void
function drawModel(model:GpuModel3D, transform:Matrix3D, ?boneMatrices:Array<Matrix3D>, ?tint:Int, ?state:MeshState3D):Void
function drawLine(x0:Float, y0:Float, z0:Float, x1:Float, y1:Float, z1:Float, color:Int):Void
function drawLines(positions:Array<Float>, color:Int, ?colors:Array<Int>, ?width:Float = 1., ?strip:Bool = false, ?transform:Matrix3D):Void
function strokeBox(bounds:Bounds3D, color:Int):Void
function strokeSphere(x:Float, y:Float, z:Float, radius:Float, color:Int):Void
function drawGrid(lineCount:Int, spacing:Float, color:Int):Void
function drawAxes(transform:Matrix3D, length:Float):Void
function drawBillboard(region:TextureRegion2D, x:Float, y:Float, z:Float, width:Float, height:Float, ?tint:Int = 0xffffffff, ?rotation:Float = 0.):Void
function drawPoints(positions:Array<Float>, color:Int, ?colors:Array<Int>, ?texture:Texture2D, ?transform:Matrix3D):Void
function drawTriangles(texture:Null<Texture2D>, positions:Array<Float>, ?texCoords:Array<Float>, ?colors:Array<Int>, ?indices:Array<Int>, ?normals:Array<Float>, ?transform:Matrix3D):Void
function drawPolyline(points:Array<Float>, thickness:Float, color:Int, ?transform:Matrix3D):Void
function fillTriangle(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, color:Int, ?transform:Matrix3D):Void
function fillRectangle(x:Float, y:Float, width:Float, height:Float, color:Int, ?transform:Matrix3D):Void
function strokeRectangle(x:Float, y:Float, width:Float, height:Float, thickness:Float, color:Int, ?transform:Matrix3D):Void
function fillRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, color:Int, ?transform:Matrix3D):Void
function strokeRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, thickness:Float, color:Int, ?transform:Matrix3D):Void
function fillCircle(x:Float, y:Float, radius:Float, color:Int, ?transform:Matrix3D):Void
function strokeCircle(x:Float, y:Float, radius:Float, thickness:Float, color:Int, ?transform:Matrix3D):Void
function fillEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, color:Int, ?transform:Matrix3D):Void
function strokeEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, thickness:Float, color:Int, ?transform:Matrix3D):Void
function fillPolygon(points:Array<Float>, color:Int, ?transform:Matrix3D):Bool
function strokePolygon(points:Array<Float>, thickness:Float, color:Int, ?transform:Matrix3D):Void
function drawSprite(region:TextureRegion2D, x:Float, y:Float, ?rotation:Float = 0., ?scaleX:Float = 1., ?scaleY:Float = 1., ?tint:Int = 0xffffffff, ?flipX:Bool = false, ?flipY:Bool = false, ?originX:Float, ?originY:Float, ?transform:Matrix3D):Void
function drawTextureRegion(texture:Texture2D, regionX:Float, regionY:Float, regionWidth:Float, regionHeight:Float, x:Float, y:Float, width:Float, height:Float, ?rotation:Float = 0., ?originX:Float = 0., ?originY:Float = 0., ?tint:Int = 0xffffffff, ?transform:Matrix3D):Void
function drawText(font:GpuFont2D, text:String, x:Float, y:Float, ?color:Int = 0xffffffff, ?size:Float, ?letterSpacing:Float = 0., ?kerned:Bool = true, ?transform:Matrix3D):Void
function drawTextLayout(layout:TextLayout2D, x:Float, y:Float, ?color:Int = 0xffffffff, ?transform:Matrix3D):Void
```

- `new`: Creates an empty list.
- `bounds`: Gets the box around what it holds, in its own units: empty when it holds nothing. A model counts by its box at rest, posed by the bones given; a billboard by the sphere it can turn in; text as it is measured when recorded.
- `callCount`: Gets the number of calls recorded.
- `makeEmpty`: Removes every call, to record again.
  - returns: This list.
- `drawMesh`: Records a mesh with a material, placed by a transform.
  - `mesh`: The mesh, held.
  - `material`: The material, held, drawn as it is at each replay.
  - `transform`: The mesh's place in the list's units, copied.
  - `skinning`: Optional. Its skin's matrices (`Skin3D.computeSkinning`), copied, for a mesh with joints; the mesh is drawn unskinned when omitted.
  - `morphWeights`: Optional. How much of each of its morph targets is added, copied, by target; none when omitted.
  - `tint`: Optional. A color, 0xAARRGGBB, multiplying the material's `baseColor` for this draw alone; white when omitted.
  - `state`: Optional. State this draw takes in place of the material's (`MeshState3D`), copied; the material's when omitted.
- `drawMeshInstanced`: Records a mesh many times with one material, each copy placed by its own transform and tinted by its own color, in one GPU draw.
  - `mesh`: The mesh, held.
  - `material`: The material, held, drawn as it is at each replay.
  - `transforms`: Each copy's place in the list's units, copied.
  - `colors`: Optional. Each copy's color, 0xAARRGGBB, multiplying its base color, copied, indexed as `transforms`; white when omitted.
  - `transform`: Optional. The parent all the copies are placed in, in the list's units, copied; identity when omitted.
  - `firstInstanceIndex`: Optional. The index in `transforms` of the first copy recorded; defaults to 0.
  - `instanceCount`: Optional. How many copies are recorded from it; every one to the end of `transforms` when omitted. None draws nothing.
  - throws `String`: Copies past the end of `transforms`.

  A shader for it reads each copy's transform as `instanceModel` and its color as `instanceColor`; the default does. A mesh's joints are ignored here.
- `drawModel`: Records a model: each of its meshes with its material, placed by a transform, each skinned mesh posed by its skin.
  - `model`: The model, held.
  - `transform`: The model's place in the list's units, copied.
  - `boneMatrices`: Optional. Each of its skeleton's bones' place in the model (`Skeleton3D.computeWorld`), copied; the rest pose when omitted. Ignored for a model without a skeleton.
  - `tint`: Optional. A color, 0xAARRGGBB, multiplying each material's `baseColor` for this draw alone; white when omitted.
  - `state`: Optional. State every mesh of this draw takes in place of its material's (`MeshState3D`), copied; each material's when omitted.
- `drawLine`: Records a line between two points, one pixel wide.
  - `x0`: The start's x.
  - `y0`: The start's y.
  - `z0`: The start's z.
  - `x1`: The end's x.
  - `y1`: The end's y.
  - `z1`: The end's z.
  - `color`: The color.
- `drawLines`: Records lines through positions, as segments two by two or as one strip, of a width in pixels.
  - `positions`: The positions, x, y and z each, copied.
  - `color`: The color of lines without colors of their own.
  - `colors`: Optional. Each position's color, 0xAARRGGBB, blended along each line; `color` everywhere when omitted.
  - `width`: Optional. The width, in framebuffer pixels, whatever the transform; defaults to 1.
  - `strip`: Optional. Whether the positions are one line through them all, rather than a segment each two; defaults to false.
  - `transform`: Optional. What the positions are moved by, in the list's units, copied; identity when omitted.

  A line wider than a pixel is a quad made in the vertex stage, facing the screen, the same on every backend.
- `strokeBox`: Records a box's twelve edges.
  - `bounds`: The box, in the list's units; copied.
  - `color`: The color.
- `strokeSphere`: Records a sphere as three circles about its center, one square to each axis.
  - `x`: The center's x.
  - `y`: The center's y.
  - `z`: The center's z.
  - `radius`: The radius.
  - `color`: The color.
- `drawGrid`: Records a grid of lines on the ground (y 0), centered on the origin.
  - `lineCount`: The number of lines each way.
  - `spacing`: The distance between two lines.
  - `color`: The color.
- `drawAxes`: Records a transform's axes from its origin: x red, y green, z blue.
  - `transform`: The transform, as a mesh would be placed by it, in the list's units; copied.
  - `length`: Each axis' length, before the transform's scale.
- `drawBillboard`: Records a texture's region facing the camera, upright with the camera's up and turned about its center, its center at a point.
  - `region`: The region of the texture, held.
  - `x`: The center's x.
  - `y`: The center's y.
  - `z`: The center's z.
  - `width`: The width, in the list's units.
  - `height`: The height, in the list's units.
  - `tint`: Optional. The color its texels are multiplied by; defaults to white.
  - `rotation`: Optional. Its turn in the screen's plane, in radians, clockwise; defaults to 0.
- `drawPoints`: Records positions as points, drawn at the replaying batch's `pointSize`, unlit.
  - `positions`: The points' positions, x, y and z each, in the list's units; copied.
  - `color`: The color of points without one of their own.
  - `colors`: Optional. Each point's own color, 0xAARRGGBB; `color` for every point when omitted.
  - `texture`: Optional. The texture across each square, held; white when omitted.
  - `transform`: Optional. What the positions are moved by, in the list's units, copied; identity when omitted.
- `drawTriangles`: Records triangles as given, in the list's units: textured, colored by vertex, or both, unlit, for what has no mesh.
  - `texture`: The texture, or null for white.
  - `positions`: The vertices' positions, x, y and z each.
  - `texCoords`: Optional. The texture coordinates, u and v each; 0, 0 for every vertex when omitted.
  - `colors`: Optional. Each vertex's color, 0xAARRGGBB; white when omitted.
  - `indices`: Optional. Three a triangle, indexing the vertices; when omitted, the vertices are the triangles in order.
  - `normals`: Optional. Each vertex's normal, x, y and z, for a program's own shader; 0, 0, 1 for every vertex when omitted.
  - `transform`: Optional. What the positions and normals are moved by, in the list's units, copied; identity when omitted.

  The arrays are copied, so they may be reused.
- `drawPolyline`: Records lines through points in a plane, one after another, joined at each point with a miter, or a bevel where the miter would reach past twice the thickness, as `Batch3D.drawPolyline` draws them; two points are one line, its ends square, cut at the points.
  - `points`: The points, x and y each, in the plane's units, copied; fewer than two draws nothing.
  - `thickness`: The width, in the plane's units.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.
- `fillTriangle`: Records a filled triangle in a plane.
  - `x0`: The first corner, across.
  - `y0`: The first corner, down.
  - `x1`: The second corner, across.
  - `y1`: The second corner, down.
  - `x2`: The third corner, across.
  - `y2`: The third corner, down.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.
- `fillRectangle`: Records a filled rectangle in a plane.
  - `x`: The left edge.
  - `y`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.
- `strokeRectangle`: Records a rectangle's outline in a plane.
  - `x`: The left edge.
  - `y`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `thickness`: The outline's width, centered on the edges.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.
- `fillRoundedRectangle`: Records a filled rectangle with rounded corners in a plane.
  - `x`: The left edge.
  - `y`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `radius`: The corners' radius, clamped to half the shorter side.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.
- `strokeRoundedRectangle`: Records the outline of a rectangle with rounded corners in a plane.
  - `x`: The left edge.
  - `y`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `radius`: The corners' radius, clamped to half the shorter side.
  - `thickness`: The outline's width, centered on the edges.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.
- `fillCircle`: Records a filled circle in a plane.
  - `x`: The center, across.
  - `y`: The center, down.
  - `radius`: The radius.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.
- `strokeCircle`: Records a circle's outline in a plane.
  - `x`: The center, across.
  - `y`: The center, down.
  - `radius`: The radius.
  - `thickness`: The outline's width, centered on the circle.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.
- `fillEllipse`: Records a filled ellipse in a plane, its axes across and down.
  - `x`: The center, across.
  - `y`: The center, down.
  - `radiusX`: The radius across.
  - `radiusY`: The radius down.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.
- `strokeEllipse`: Records an ellipse's outline in a plane.
  - `x`: The center, across.
  - `y`: The center, down.
  - `radiusX`: The radius across.
  - `radiusY`: The radius down.
  - `thickness`: The outline's width, centered on the ellipse.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.
- `fillPolygon`: Records a filled polygon in a plane, convex or not, whose edges don't cross.
  - `points`: The corners in order, x and y each, either way round, copied; fewer than three draws nothing.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.
  - returns: False when its edges cross, and nothing is recorded.
- `strokePolygon`: Records a polygon's outline in a plane: lines through its corners and back to the first, joined as `drawPolyline` joins them.
  - `points`: The corners in order, x and y each, copied; fewer than two draws nothing.
  - `thickness`: The outline's width, centered on the edges.
  - `color`: The color.
  - `transform`: Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.
- `drawSprite`: Records a texture's region in a plane, turned and scaled about its origin, as `Batch3D.drawSprite` draws it.
  - `region`: The region of the texture, held.
  - `x`: Where the origin goes, across.
  - `y`: Where the origin goes, down the texture.
  - `rotation`: Optional. The turn about the origin, in radians, from x toward y; defaults to 0.
  - `scaleX`: Optional. The scale across; defaults to 1, a unit a texel.
  - `scaleY`: Optional. The scale down; defaults to 1.
  - `tint`: Optional. The color its texels are multiplied by; defaults to white.
  - `flipX`: Optional. Whether it is mirrored across about its origin, after its scale; defaults to false.
  - `flipY`: Optional. Whether it is mirrored down about its origin, after its scale; defaults to false.
  - `originX`: Optional. The point it turns about and is placed by, in texels from the region's left; the region's `originX` when omitted.
  - `originY`: Optional. That point, in texels from the region's top; the region's `originY` when omitted.
  - `transform`: Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.
- `drawTextureRegion`: Records a rectangle of a texture drawn into a rectangle in a plane, as `Batch3D.drawTextureRegion` draws it.
  - `texture`: The texture, held.
  - `regionX`: The part's left edge, in texels from the texture's left.
  - `regionY`: The part's top edge, in texels from the texture's top.
  - `regionWidth`: The part's width, in texels; negative mirrors it across.
  - `regionHeight`: The part's height, in texels; negative mirrors it down.
  - `x`: Where the origin goes, across.
  - `y`: Where the origin goes, down the texture.
  - `width`: The width it is drawn at.
  - `height`: The height it is drawn at.
  - `rotation`: Optional. The turn about the origin, in radians, from x toward y; defaults to 0.
  - `originX`: Optional. The point it turns about and is placed by, from the drawn rectangle's left; defaults to 0.
  - `originY`: Optional. That point, from the drawn rectangle's top; defaults to 0.
  - `tint`: Optional. The color its texels are multiplied by; defaults to white.
  - `transform`: Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.
- `drawText`: Records text in a font in a plane, as `Batch3D.drawText` draws it.
  - `font`: The font, held.
  - `text`: The text; a character the font lacks is drawn as the font's stand-in, as `GpuFont2D` says.
  - `x`: The left edge.
  - `y`: The top of the first line, lines following down the texture.
  - `color`: Optional. The color; defaults to white.
  - `size`: Optional. The size, as the font's size is measured; the font's own when omitted.
  - `letterSpacing`: Optional. Space added after each character; defaults to 0.
  - `kerned`: Optional. Whether pairs of characters are kerned as the font gives them; defaults to true.
  - `transform`: Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.
- `drawTextLayout`: Records laid-out text in a plane, as `Batch3D.drawTextLayout` draws it; the layout is held, and drawn as it is at each replay.
  - `layout`: The layout, held.
  - `x`: The left edge of the layout's box, in which its lines are aligned: the box is `maxWidth` wide, or as wide as its widest line when `maxWidth` is 0.
  - `y`: The top of the first line.
  - `color`: Optional. The color; defaults to white.
  - `transform`: Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.

## Environment3D

*class* in [`libs/render/src/helix/render/Environment3D.hx`](../../libs/render/src/helix/render/Environment3D.hx), `import helix.render.Environment3D;`

Represents a place's light apart from its lights: the ambient light reaching every surface evenly, an environment map lighting and reflecting the lit materials, and the background behind everything.

A `Batch3D` lights by its `environment`, which several batches may share; each `begin` reads it as it is then. It starts with no light at all: lighting is what the program sets.

```haxe
function new()
var ambientColor(default, null):Int
var ambientIntensity(default, null):Float
var map(default, null):Null<EnvironmentMap3D>
var mapIntensity(default, null):Float
var rotation(default, null):Float
var background(default, null):Null<EnvironmentMap3D>
var backgroundBlur(default, null):Float
function setAmbient(color:Int, intensity:Float):Bool
function setMap(map:Null<EnvironmentMap3D>, ?intensity:Float = 1., ?rotation:Float = 0.):Bool
function setMapAndBackground(map:Null<EnvironmentMap3D>, ?intensity:Float = 1., ?rotation:Float = 0., ?blur:Float = 0.):Bool
function setBackground(map:Null<EnvironmentMap3D>, ?blur:Float = 0.):Bool
```

- `new`: Creates an environment of no light: no ambient light, no map, no background.
- `ambientColor`: Gets the ambient light's color, 0xAARRGGBB, its alpha ignored: white until set.
- `ambientIntensity`: Gets the ambient light's intensity: 0 until set, so there is none until the program sets it.
- `map`: Gets the environment map lighting the lit materials, or null for none: null until set.
- `mapIntensity`: Gets how strongly the map lights, and the background shows: 1, as its picture has it, until set.
- `rotation`: Gets how far the map and the background are turned about +y, in radians: 0 until set.
- `background`: Gets the environment map shown behind everything by `Batch3D.drawBackground`, or null for none.
- `backgroundBlur`: Gets how blurred the background is: 0 sharp, at the picture's own resolution, to 1, a few texels.
- `setAmbient`: Sets the ambient light: its color decoded from sRGB, times its intensity, reaching every surface alike from every side.
  - `color`: The color, as 0xAARRGGBB; its alpha is ignored.
  - `intensity`: The intensity.
  - returns: False, changing nothing, for an intensity below 0.

  Its intensity is three.js's AmbientLight's: the light falling on a surface whatever way it faces, so at π a white surface shows white, as under a light of π (`Light3D`). It lights the diffuse part of a lit material, darkened by its occlusion map.
- `setMap`: Sets the environment map the lit materials are lit and reflect by, beside the lights and the ambient light: diffuse light from its irradiance, reflections from its prefiltered cube, sharp to blurred by roughness.
  - `map`: The map, or null for none.
  - `intensity`: Optional. How strongly it lights, and the background shows; defaults to 1.
  - `rotation`: Optional. Its turn about +y, in radians, which the background shares; defaults to 0.
  - returns: False, changing nothing, for an intensity below 0 or a rotation that isn't finite.
- `setMapAndBackground`: Sets one environment map as both the light and the background, as a sky picture usually is: `setMap` and `setBackground` in one call.
  - `map`: The map, or null for none of either.
  - `intensity`: Optional. How strongly it lights, and the background shows; defaults to 1.
  - `rotation`: Optional. Its turn about +y, in radians; defaults to 0.
  - `blur`: Optional. How blurred the background is, 0 sharp to 1 its blurriest; defaults to 0.
  - returns: False, changing nothing, for an intensity below 0, a rotation that isn't finite, or a blur outside 0 to 1.
- `setBackground`: Sets the environment map `Batch3D.drawBackground` shows behind everything, turned and as bright as `setMap` says.
  - `map`: The map, or null for none.
  - `blur`: Optional. 0 sharp to 1 its blurriest; defaults to 0.
  - returns: False, changing nothing, for a blur outside 0 to 1.

## EnvironmentBake3D

*class* in [`libs/render/src/helix/render/EnvironmentBake3D.hx`](../../libs/render/src/helix/render/EnvironmentBake3D.hx), `import helix.render.EnvironmentBake3D;`

Represents the preparing of an environment map on the CPU, a step at a time, so that it spreads over frames: from a picture of all around, its light for image-based lighting and its background.

It makes what glTF viewers light by: the irradiance (the light a surface facing each way gets from all around) as 9 spherical-harmonic coefficients; a 128-texel cube prefiltered for roughness 0 to 1 (GGX, a mip a step); and a background cube at the picture's own resolution with box-filtered mips for blur; both cubes RGBA half floats. A program runs it a little each frame (`run`) until it is `done`, then hands it to `Renderer.createEnvironmentMap`. It is the same on every target, and needs no float render target or cube pass.

```haxe
var bake = EnvironmentBake3D.fromImage(sky); // an equirectangular image
// each frame, until done:
if (bake != null && bake.run(4)) {
batch.environment.setMap(renderer.createEnvironmentMap(bake), 1, 0);
bake = null;
}
```

```haxe
static function fromImage(image:Image):EnvironmentBake3D
static function fromPixels(width:Int, height:Int, pixels:haxe.io.Bytes):EnvironmentBake3D
static function fromCubeImages(faces:Array<Image>):EnvironmentBake3D
var done(default, null):Bool
var progress(default, null):Float
function run(budgetMs:Float):Bool
```

- `fromImage`: Returns a bake of an equirectangular picture (2:1, latitude and longitude) of 8-bit sRGB colors, as linear light up to 1.
  - `image`: The picture.
  - returns: The bake, not started.
  - throws `String`: An image that isn't twice as wide as it is high.
- `fromPixels`: Returns a bake of an equirectangular picture of linear light, which may run past 1, as a Radiance .hdr holds it.
  - `width`: The width, in pixels: twice the height.
  - `height`: The height, in pixels.
  - `pixels`: Red, green and blue a pixel, rows top first, as little-endian 32-bit floats: `width * height * 12` bytes.
  - returns: The bake, not started.
  - throws `String`: A size that isn't 2:1, or pixels too short.
- `fromCubeImages`: Returns a bake of six square pictures, a cube's faces, of 8-bit sRGB colors.
  - `faces`: The faces, in the order +X, -X, +Y, -Y, +Z, -Z, as a cube's faces are seen from inside it, each the same size.
  - returns: The bake, not started.
  - throws `String`: Not six faces, or faces not square and alike.
- `done`: Gets a value indicating whether it is finished.
- `progress`: Gets how far it is, 0 to 1.
- `run`: Works its steps until it is done or a time has passed, at least one step.
  - `budgetMs`: The time to work for, in milliseconds.
  - returns: True once it is done.

## EnvironmentMap3D

*class* in [`libs/render/src/helix/render/EnvironmentMap3D.hx`](../../libs/render/src/helix/render/EnvironmentMap3D.hx), `import helix.render.EnvironmentMap3D;`

Represents an environment map on the GPU: the irradiance, prefiltered cube and background cube a finished `EnvironmentBake3D` made.

`Renderer.createEnvironmentMap` makes one; an `Environment3D` lights by it (`setMap`) and shows it behind everything (`setBackground`, `Batch3D.drawBackground`), and a `Material3D` may name one of its own. The program frees it with `dispose`.

```haxe
final irradiance:Array<Float>
function dispose():Void
```

- `irradiance`: Gets the irradiance: 9 spherical-harmonic coefficients, red, green and blue each (27 floats), over π, in linear light.
- `dispose`: Frees its cubes on the GPU, after the frame being recorded when it holds a draw with them. A second call does nothing.

## Fog3D

*class* in [`libs/render/src/helix/render/Fog3D.hx`](../../libs/render/src/helix/render/Fog3D.hx), `import helix.render.Fog3D;`

Represents fog: what is drawn fades toward a color with its distance from the camera.

A `Batch3D` draws through its `fog`, read at each `begin`; a material opts out with `Material3D.fog`, the batch draws with `Batch3D.fogged`. The background isn't fogged.

```haxe
var mist = new Fog3D(0xffa0b0c0);
mist.near = 10;
mist.far = 60;
batch.fog = mist;
```

```haxe
function new(color:Int)
var color:Int
var mode:FogMode3D
var near:Float
var far:Float
var density(default, set):Float
```

- `new`: Creates linear fog of a color.
  - `color`: The color, as 0xAARRGGBB; its alpha is ignored.
- `color`: Gets or sets the color it fades to.
- `mode`: Gets or sets how it thickens: Linear until set.
- `near`: Gets or sets where linear fog starts, in world units from the camera: 1 until set.
- `far`: Gets or sets where linear fog is whole, in world units from the camera: 1000 until set.
- `density`: Gets or sets how thick exponential fog is, per world unit: 0.00025 until set, as three.js's FogExp2. Below 0 is clamped to 0.

## FogMode3D

*abstract* in [`libs/render/src/helix/render/FogMode3D.hx`](../../libs/render/src/helix/render/FogMode3D.hx), `import helix.render.FogMode3D;`

Specifies how fog thickens with distance from the camera.

- `FogMode3D.Linear`: From none at `Fog3D.near` to all fog at `Fog3D.far`: three.js's Fog.
- `FogMode3D.Exponential`: 1 - e^-(density × distance)²: three.js's FogExp2.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Linear, Exponential): what Std.string, interpolation and trace show.

## GpuFont2D

*class* in [`libs/render/src/helix/render/GpuFont2D.hx`](../../libs/render/src/helix/render/GpuFont2D.hx), `import helix.render.GpuFont2D;`

Represents a font ready to draw: helix-services' `Font2D` with its atlas on the GPU.

`Renderer.createFont` makes one, from a font helix-services' `Fonts` made; `Batch2D.drawText`, `Batch3D.drawText` and `TextLayout2D` use it; the program frees its atlas with `dispose`. A size is measured as the font's is, from its ascent to its descent; a font drawn at another size is scaled. Each batch's default shader draws a coverage atlas's alpha as it is stored, and a distance-field atlas's (helix-services' `Font2D.kind` Distance) as a sharp edge at any size; a hard-edged font's atlas (Bitmap) is sampled nearest. A program's shader is given the kind as `fontKind`. Pairs of characters are kerned as the font's `Font2D.kernings` give them, unless a draw's `kerned` is false.

A character the font lacks is drawn, and measured, as the font's `?`, or else as its .notdef (`Font2D.notdef`), and skipped when it has neither, as raylib draws one; the first time each such character is met in a font, a warning is logged (helix-log, tag "render"). A control character the font lacks (a tab, a carriage return) is skipped, unwarned.

```haxe
final font:Font2D
final atlas:Texture2D
var lineHeight(get, never):Float
function measureText(text:String, ?size:Float, ?letterSpacing:Float = 0., ?kerned:Bool = true, ?out:Vector2D):Vector2D
function dispose():Void
```

- `font`: Gets the font: its metrics and glyphs.
- `atlas`: Gets its atlas, as a texture: white, each glyph's coverage or distance as alpha.
- `lineHeight`: Gets the distance from one line's top to the next's at the font's size: its ascent, descent and line gap.
- `measureText`: Returns the size of text drawn on one line per line break, as `Batch2D.drawText` draws it.
  - `text`: The text.
  - `size`: Optional. The size it is drawn at; the font's own when omitted.
  - `letterSpacing`: Optional. Space added after each character, as `drawText` adds it; defaults to 0.
  - `kerned`: Optional. Whether pairs of characters are kerned as the font gives them, as `drawText`'s `kerned`; defaults to true.
  - `out`: Optional. Set to the size; a new vector when omitted.
  - returns: The width of its widest line as x, and its lines' height as y, in the units it is drawn in.
- `dispose`: Frees the atlas on the GPU, after the frame being recorded when it holds a draw of it. A second call does nothing.

## GpuMesh3D

*class* in [`libs/render/src/helix/render/GpuMesh3D.hx`](../../libs/render/src/helix/render/GpuMesh3D.hx), `import helix.render.GpuMesh3D;`

Represents a mesh on the GPU: its vertices and indices, uploaded once and drawn as often as wanted (`Batch3D.drawMesh`).

`Renderer.createMesh` makes one from helix-geometry's `Mesh3D`, and `Renderer.createModel` one for each of a model's meshes. The program frees it with `dispose`. It keeps its positions on the CPU, and a skinned mesh its joints and weights, for `computeBounds`; for a skinned mesh it also records each joint's box of the vertices it moves, which `Batch3D` culls by.

```haxe
var vertexCount(default, null):Int
var triangleCount(default, null):Int
final bounds:Bounds3D
var hasJoints(default, null):Bool
var morphTargetCount(default, null):Int
function update(mesh:Mesh3D):Void
function computeBounds(transform:Matrix3D, ?skinning:Array<Matrix3D>, ?morphWeights:Array<Float>, ?out:Bounds3D):Bounds3D
function dispose():Void
```

- `vertexCount`: Gets the number of vertices.
- `triangleCount`: Gets the number of triangles.
- `bounds`: Gets the box around its positions as uploaded, in the mesh's own units (a skinned mesh's in its bind pose).
- `hasJoints`: Gets a value indicating whether it has joints and weights, so it is drawn skinned when given a skin's matrices.
- `morphTargetCount`: Gets the number of its morph targets: 0 for none.
- `update`: Replaces its vertices and indices with a mesh's, for the draws after it.
  - `mesh`: The mesh. It may have other arrays and another vertex count than before.
  - throws `String`: A mesh without positions, or a disposed one.

  Draws already recorded this frame draw what it held before. A mesh made `updatedOften` (`Renderer.createMesh`) is replaced in place; another is uploaded again.
- `computeBounds`: Returns the box around the mesh as drawn: its vertices posed by a skin's matrices when given, on the CPU, then placed by a transform.
  - `transform`: The mesh's place in the world.
  - `skinning`: Optional. Its skin's matrices, as `Batch3D.drawMesh` takes them; the mesh as uploaded when omitted.
  - `morphWeights`: Optional. Its morph targets' weights, as `Batch3D.drawMesh` takes them; none when omitted.
  - `out`: Optional. Set to the box; a new one when omitted.
  - returns: The box, in world units.
  - throws `String`: A disposed mesh.

  It is exact where the box culling uses may be larger, so it suits framing a camera and picking. It goes through every vertex, so it is for now and then, not every mesh every frame.
- `dispose`: Frees its buffers on the GPU, after the frame being recorded when it holds a draw of it. A second call does nothing.

## GpuModel3D

*class* in [`libs/render/src/helix/render/GpuModel3D.hx`](../../libs/render/src/helix/render/GpuModel3D.hx), `import helix.render.GpuModel3D;`

Represents a model on the GPU: its meshes uploaded, its images made textures, its materials made `Material3D`s over them.

`Renderer.createModel` makes one from helix-services' `Model3D`; `Batch3D.drawModel` draws it, skinned when given its bones. It owns its meshes and textures, and `dispose` frees them; its materials may be changed, and a mesh's material swapped through `meshMaterialIndices` or `materials`. Its skeleton, skins and animations are the model's (`model.skeleton`).

```haxe
final model:Model3D
final meshes:Array<GpuMesh3D>
final materials:Array<Material3D>
final meshMaterialIndices:Array<Int>
final textures:Array<Null<Texture2D>>
final bounds:Bounds3D
function computeBounds(transform:Matrix3D, ?boneMatrices:Array<Matrix3D>, ?out:Bounds3D):Bounds3D
function dispose():Void
```

- `model`: Gets the model it was made from.
- `meshes`: Gets the meshes, beside the model's `meshes`.
- `materials`: Gets the materials, beside the model's `materials`, and one more, white, when a mesh has none in the file.
- `meshMaterialIndices`: Gets the index of each mesh's material in `materials`, beside it in `meshes`.
- `textures`: Gets the textures, beside the model's `images`; null for an image that is null.
- `bounds`: Gets the box around its meshes at rest, in the model's units.
- `computeBounds`: Returns the box around the model as drawn: each mesh's vertices, a skinned one's posed on the CPU by its skeleton's bones, placed by a transform.
  - `transform`: The model's place in the world.
  - `boneMatrices`: Optional. Each bone's place in the model, as `Batch3D.drawModel` takes them; the rest pose when omitted.
  - `out`: Optional. Set to the box; a new one when omitted.
  - returns: The box, in world units, or the box made empty for a model with no vertices.

  It is exact, for framing a camera and picking, and goes through every vertex.
- `dispose`: Frees its meshes and textures, after the frame being recorded when it holds a draw of them. A second call does nothing.
  A texture of it a program gave another material is freed too.

## HemisphereLight3D

*class* in [`libs/render/src/helix/render/HemisphereLight3D.hx`](../../libs/render/src/helix/render/HemisphereLight3D.hx), `import helix.render.HemisphereLight3D;`, extends `Light3D`

Represents light from the sky above and the ground below: a surface facing up gets the sky's color, one facing down the ground's, one between a blend, from no one direction. It is three.js's HemisphereLight, and casts no shadows.

```haxe
function new()
var groundColor:Int
final up:Vector3D
```

- `new`: Creates a hemisphere light of intensity π: a white sky over a dark grey ground.
- `groundColor`: Gets or sets the ground's color, 0xAARRGGBB, its alpha ignored: the sky's is `color`. Dark grey until set.
- `up`: Gets the way up, the sky's side, in world units: +y until changed.

## Light3D

*class* in [`libs/render/src/helix/render/Light3D.hx`](../../libs/render/src/helix/render/Light3D.hx), `import helix.render.Light3D;`

Represents a light that a `Batch3D` lights its lit materials with: a `DirectionalLight3D`, a `PointLight3D`, a `SpotLight3D` or a `HemisphereLight3D`.

A program makes its lights and puts them in `Batch3D.lights`; each `begin` reads them as they are then. Its color is 0xAARRGGBB, its alpha ignored, decoded from sRGB and multiplied by its intensity into the light's radiance, which the shaders work in.

**Intensity** is in three.js's units, so a three.js layer passes its lights' through: a directional or hemisphere light's is the light falling on a surface facing it; a point or spot light's is that light at 1 world unit, falling off with the square of the distance. Every light starts at π, at which a white surface facing it (a point or spot light 1 unit away) shows white, as a surface's diffuse light is its light over π.

A directional, spot or point light casts shadows while `castsShadow` is set, as its `shadow` says; at most 4 lights of a batch cast, the first 4 casting in `lights`. A hemisphere light casts none.

**What links the lighting.** Making a light, setting an ambient light (`Environment3D.setAmbient`), writing a lit `Material3D.shading`, an emissive color or a light map, or compiling a shader that reads the lighting links the lit shaders. A program that does none of them links none of it, and a lit material there is drawn as no light leaves it: black, its alpha kept.

```haxe
var color:Int
var intensity(default, set):Float
var castsShadow(default, set):Bool
final shadow:LightShadow3D
```

- `color`: Gets or sets its color: white until set.
- `intensity`: Gets or sets its intensity, a multiplier of its color, in the units the class says: π until set. Below 0 is clamped to 0.
- `castsShadow`: Gets or sets a value indicating whether it casts shadows: false until set, as a shadow map costs a pass and memory. Ignored for a hemisphere light.
- `shadow`: Gets how its shadows are made, while it casts them.

## LightShadow3D

*class* in [`libs/render/src/helix/render/LightShadow3D.hx`](../../libs/render/src/helix/render/LightShadow3D.hx), `import helix.render.LightShadow3D;`

Represents how a light's shadows are made: its shadow map's size and reach, its bias against a surface shadowing itself, and how soft and dark its shadows are.

Each `DirectionalLight3D`, `SpotLight3D` and `PointLight3D` has one (`Light3D.shadow`), used while its `castsShadow` is set. A casting light's map is drawn before the pass its batch draws in, from the meshes drawn with `Batch3D.castShadows` on, and read by the meshes drawn with `receiveShadows` on.

- **Directional:** a square map, or up to 4 cascades, over what the camera sees out to `distance` (or over `bounds`), its texels snapped to the world so its edges hold still as the camera moves and turns. - **Spot:** one map over its cone, out to its range or `distance`, the nearer. - **Point:** six maps, one a cube face, out to its range or `distance`.

Bias is in shadow-map texels, so it holds whatever the map's size and reach: a constant, plus a slope where the light grazes the surface, and the lookup moved off the surface along its normal by `normalOffset` texels, more where the light grazes. A shadow fades out over the last tenth of the map, so it never ends at an edge.

```haxe
function new()
var mapSize(default, set):Int
var distance(default, set):Float
var bounds:Null<Bounds3D>
var cascadeCount(default, set):Int
var cascadeSplit(default, set):Float
var bias(default, set):Float
var slopeBias(default, set):Float
var normalOffset(default, set):Float
var radius(default, set):Float
var strength(default, set):Float
var color:Int
```

- `new`: Creates the shadow settings of a light: 2048 texels, 50 units, one cascade, a bias of 1 and 4 texels and a normal offset of 1, a 3 x 3 filter, full strength.
- `mapSize`: Gets or sets the map's width and height, in texels: 2048 until set. A power of two from 256 to 4096; another is rounded down to one, and clamped. A batch's casting lights share the largest asked for.
- `distance`: Gets or sets how far from the camera a directional light's shadows reach, and at most a spot's or a point's, in world units: 50 until set. Shorter is sharper. Clamped to at least 0.000001.
- `bounds`: Gets or sets the box a directional light's map covers, in world units, in place of what the camera sees; null until set, so the map follows the camera. A fixed box suits a small scene seen whole.
- `cascadeCount`: Gets or sets a directional light's number of cascades, 1 to 4: 1 until set, a single map. Each covers a farther slice of `distance` with a map of its own, so near shadows are sharp and far ones still drawn; each costs a pass.
- `cascadeSplit`: Gets or sets how the cascades split `distance`: 0 evenly, 1 by the ratio of their ends, between them a blend. 0.6 until set; clamped to 0 to 1.
- `bias`: Gets or sets the constant bias, in texels: 1 until set. Below 0 is clamped to 0.
- `slopeBias`: Gets or sets the slope bias, in texels, added where the light grazes the surface: 4 until set. Below 0 is clamped to 0.
- `normalOffset`: Gets or sets how far the lookup moves off the surface along its normal, in texels: 1 until set, so it holds whatever the map's size and reach. three.js's `normalBias` is in world units: a layer over it divides by a texel's size in the world. Below 0 is clamped to 0.
- `radius`: Gets or sets how soft the shadow's edge is, the filter's radius in texels: 1 until set, a 3 x 3 filter; 0 a single hard lookup; more, a wider disc of lookups. Clamped to 0 to 8.
- `strength`: Gets or sets how much of the light a shadow takes away: 1 until set. Clamped to 0 to 1.
- `color`: Gets or sets what a shadow leaves of the surface's own color, 0xAARRGGBB, its alpha ignored: black until set, so nothing. A cold blue suits a sunny day's shade.

## Material3D

*class* in [`libs/render/src/helix/render/Material3D.hx`](../../libs/render/src/helix/render/Material3D.hx), `import helix.render.Material3D;`

Represents how a mesh's surface is drawn: its shading and the colors, textures and values it takes, how it is blended, culled and depth-tested, and the program's own shader when it has one.

A program makes one, or `Renderer.createModel` makes them from a model's materials. A material names its textures and environment map without owning them. A draw reads the material as it is when it is called, so one material may be changed between draws.

**Shading** (`shading`): `MetallicRoughness` (the default) shades it as glTF's model has it under the batch's lights, ambient light and environment map (a GGX highlight, a Lambert diffuse, image-based light from the map's irradiance and prefiltered cube), with `clearcoat`, `sheenColor` and `ior` and `specularColor` as glTF's extensions add them; `Phong` and `Lambert` are the older, cheaper models; `Unlit` shows its colors as they are. Every model adds the emissive light, discards a texel whose alpha is below `alphaCutoff`, and is fogged by the batch's `fog` unless `fog` is off.

**Colors** are 0xAARRGGBB, sRGB; a texture is decoded or not as its `colorSpace` says (`Auto`: color slots decoded, data slots read as they are). How the base color, its texture and the vertex color are multiplied is `colorSpace`'s: Linear (the default) decodes the first two, reads the vertex color as linear, and multiplies in linear light, as glTF and three.js do; Srgb multiplies the three as stored and decodes the product once, as raylib does. Light, ambient light and the environment are linear. The result is encoded as the target needs (`Batch3D`), so an `Unlit` material with `colorSpace` Srgb, `toneMapped` off and no fog shows its product in an sRGB target as stored: a 0x80 base color over a 0x80 texel gives 0x40, as raylib's does.

**A program's shader** (`shaderValues`) is compiled by `compileShader` (a fragment stage over helix-render's mesh vertex stage) or `compileShaderStages`. One shader draws every kind of mesh: `instanceModel` and `instanceColor` read identity and white where no instances feed them, and skinning and morphing are read from `skinned` and `morphTargetCount`. A fragment stage is cut by `clipPlanes` before it runs, whichever compiled it. The batch fills, by name, what the shader declares; a name the program writes on its values is overwritten.

**The material include.** `#include <helix/render/shaders/material.glsl>` (fragment stage) declares every name of the material below (its colors, values and textures, as loose uniforms in the shader's own loose block) and the mesh vertex stage's outputs as inputs, and includes `lighting.glsl` (with `view.glsl` and `color.glsl`), so the shader declares none of them and shades as the built-in materials do. A shader without it declares the names it reads itself, each with the type listed; one declared with another type stops the build.

```glsl
// The material's surface at this fragment, its maps read at uv (occlusionTexture and lightTexture at texCoord2 when the mesh has a
// second set): the base color, alpha and vertex color multiplied as colorSpace says, metallic and roughness by their map, the normal
// map through the tangent frame (or the face's normal under flatShading), occlusion, the light map as bakedLight, emissive by its
// color, strength and map, and every factor; its normal turned toward the viewer. Discards the fragment when its alpha is below
// alphaCutoff, as the built-in materials do.
Surface readMaterialSurface(vec2 uv);
// The surface shaded as the material's shading says: shadeMetallicRoughness, shadePhong or shadeLambert, or for Unlit its baseColor.
vec3 shadeMaterial(Surface surface);
// The color the built-in materials write: the light plus surface.emissive, faded by the batch's fog where the material's fog is on,
// then writeColor with surface.alpha.
vec4 writeMaterialColor(Surface surface, vec3 light);
```

A shader that only moves its texture coordinates is lit, cut, fogged and written as the built-in materials are:

```glsl
#version 300 es
precision highp float;
#include <helix/render/shaders/material.glsl>
uniform vec2 scrollOffset;
out vec4 fragColor;
void main() {
Surface surface = readMaterialSurface(texCoord + scrollOffset);
fragColor = writeMaterialColor(surface, shadeMaterial(surface));
}
```

A texture scrolled, turned or tiled alike over every map needs no shader: `textureTransform`, written each frame, moves it.

**The mesh vertex stage** passes, read by name in a fragment stage: `worldPosition` (vec3), `normal` (vec3, world space, not yet turned toward the viewer), `tangent` (vec4, world space, w the bitangent's sign), `texCoord` and `texCoord2` (vec2, moved by `textureTransform`) and `color` (vec4, the vertex color as the mesh holds it: as stored when `colorSpace` is Srgb, linear otherwise). A program's own vertex stage (`compileShaderStages`) gets the same by `#include <helix/render/shaders/mesh.glsl>`, which includes `view.glsl` and declares the attributes and the per-draw uniforms below and those six outputs, so the stage declares none of them, and gives `vec4 placeVertex()`: the vertex skinned, morphed and instanced as `skinned`, `morphTargetCount` and the instance attributes say, its clip position returned and the six outputs written. The stage may write any of them again after the call.

Attributes, 0 where the mesh lacks one, but `vertexColor` white:

| Name | Type | What | |---|---|---| | `vertexPosition`, `vertexNormal` | vec3 | The mesh's position and normal. | | `vertexTangent` | vec4 | The tangent, w the bitangent's sign. | | `vertexTexCoord`, `vertexTexCoord2` | vec2 | The texture coordinates, v down the image; the second set. | | `vertexColor` | vec4 | The vertex color, 0 to 1, as the mesh holds it. | | `vertexJoints`, `vertexWeights` | vec4 | Four bones by their index in the skin, as floats, and their weights. | | `instanceModel`, `instanceColor` | mat4, vec4 | An instance's transform and color (`Batch3D.drawMeshInstanced`). |

The material's, as stored: `baseColor` (times the draw's tint), `emissiveColor` (its alpha `emissiveStrength`), `specularColor`, `sheenColor` (vec4); `metallic`, `roughness`, `normalScale`, `alphaCutoff`, `occlusionIntensity`, `lightIntensity`, `environmentIntensity`, `specularIntensity`, `shininess`, `ior`, `clearcoat`, `clearcoatRoughness`, `sheenRoughness` (float); `textureTransform` (mat3); `shading`, `toneMapped`, `fog`, `flatShading`, `vertexColors` (int, 1 for true), `colorSpaceSrgb` (int, 1 when `colorSpace` is Srgb); and its textures by their property's name, white where it has none (a normal map flat).

Per draw:

| Name | Type | What | |---|---|---| | `model`, `normalMatrix`, `modelViewProjection` | mat4 | The draw's transform; its inverse, transposed; it, then the view's `viewProjection`. | | `lightCount` | int | The lights lighting this draw, 0 to 8. | | `receiveShadows` | int | 1 when the draw is darkened by shadows: the batch's and the material's `receiveShadows` both on. | | `lightPositions`, `lightDirections`, `lightColors`, `lightCones` | vec4[8] | Each light's position (w its range, 0 for none); direction (w its kind: 0 directional, 1 point, 2 spot, 3 hemisphere); linear radiance; cone cosines (x inner, y outer) and shadow (z its index in `Lighting`'s, -1 for none). A hemisphere light's ground radiance is its position. | | `clipPlanes`, `clipPlaneCount` | vec4[4], int | `Batch3D.clipPlanes`. | | `morphWeights`, `morphTargetCount` | vec4[16], int | A morphed mesh's weights, four a vec4, and how many. | | `skinned` | int | 1 when the draw is skinned by `boneTexture` (four texels a bone, its skinning matrix's columns, read with `texelFetch`). | | `boneMatrices` | mat4 array | The skin's matrices, as many as declared, for a shader written with an array (raylib's); zero past the skin's bones. | | `boneOffset` | int | The index in `boneTexture` of the draw's first bone; a bone's matrix is at `boneOffset` plus its index. | | `boneTexture`, `morphTexture` | sampler2D | The frame's skins' matrices, every skinned draw's after the last's; the targets' deltas. |

The lights and `receiveShadows` are declared by `lighting.glsl`, not by the shader. With them the view's names (`View3D`) and the lighting block's (`Batch3D`). A shader is given colors as stored but light, which is linear; nothing it writes is encoded after it: `writeMaterialColor`, or `color.glsl`'s `writeColor`, exposes and tone maps where `toneMapped` says and encodes for the target (`View3D` lists its functions).

**Texture coordinates:** `occlusionTexture` and `lightTexture` read the mesh's second set when it has one, the others its first; all are moved by `textureTransform`.

```haxe
var crate = new Material3D();
crate.baseColorTexture = crateTexture;
crate.roughness = .8;
batch.drawMesh(cube, crate, Matrix3D.fromTranslation(0, .5, 0, placement));
```

```haxe
function new()
static macro function compileShader(fragment:String, ?options:haxe.macro.Expr.ExprOf<ShaderOptions>):haxe.macro.Expr.ExprOf<Shader>
static macro function compileShaderStages(vertex:String, fragment:String, ?options:haxe.macro.Expr.ExprOf<ShaderOptions>):haxe.macro.Expr.ExprOf<Shader>
var shading(default, set):Shading3D
var baseColor:Int
var baseColorTexture:Null<Texture2D>
var alphaTexture:Null<Texture2D>
var vertexColors:Bool
var colorSpace:ColorSpace
var metallic(default, set):Float
var roughness(default, set):Float
var metallicRoughnessTexture:Null<Texture2D>
var specularColor:Int
var specularIntensity(default, set):Float
var shininess(default, set):Float
var ior(default, set):Float
var clearcoat(default, set):Float
var clearcoatRoughness(default, set):Float
var sheenColor:Int
var sheenRoughness(default, set):Float
var normalTexture:Null<Texture2D>
var normalScale(default, set):Float
var flatShading:Bool
var occlusionTexture:Null<Texture2D>
var occlusionIntensity(default, set):Float
var lightTexture(default, set):Null<Texture2D>
var lightIntensity(default, set):Float
var emissiveColor(default, set):Int
var emissiveStrength(default, set):Float
var emissiveTexture:Null<Texture2D>
var environmentMap:Null<EnvironmentMap3D>
var environmentIntensity(default, set):Float
final textureTransform:Matrix2D
var alphaCutoff(default, set):Float
var blend:Blend
var colorWrite:ColorChannels
var cull:CullFace
var depthTest:DepthTest
var depthWrite:Bool
var fog:Bool
var toneMapped:Bool
var castShadows:Bool
var receiveShadows:Bool
var shaderValues:Null<ShaderValues>
```

- `new`: Creates a material: white, metallic-roughness, not metallic, roughness 0.5, opaque, culling back faces.
- `compileShader`: Compiles a fragment stage over helix-render's mesh vertex stage, for a `Material3D` (`shaderValues`).
  - `fragment`: The fragment stage's file, relative to the file holding the call.
  - `options`: Optional. Defines, includes and a file to watch, as `Shader.compile` takes them.
  - returns: The shader, for a `ShaderValues` over it.

  It compiles while the program builds, as helix-services' `Shader.compile` compiles one, and returns it as a value in the program: its vertex stage drawn the right way up into a render target whatever it writes (`ShaderOptions.clipScale`) and able to draw one-pixel points (`ShaderOptions.points`), helix-render's includes found (`#include <helix/render/shaders/color.glsl>`). A name the class lists declared with another type stops the build at the call. The fragment stage is GLSL as helix-services' `Shader.compile` takes it: `#version 300 es` or 330 to 440 (GL's form), or `#version 450` (Vulkan's), the mesh vertex stage given in the same form; GLSL ES 100 (raylib's) is not taken, and a layer adapts it first. The vertex stage passes `worldPosition`, `normal`, `tangent`, `texCoord`, `texCoord2` and `color`, as the class says, read by name; `#include <helix/render/shaders/material.glsl>` declares them, with the material's names.
- `compileShaderStages`: Compiles a vertex and a fragment stage, both the program's, for a `Material3D` (`shaderValues`).
  - `vertex`: The vertex stage's file, relative to the file holding the call.
  - `fragment`: The fragment stage's file, relative to the file holding the call.
  - `options`: Optional. Defines, includes and a file to watch.
  - returns: The shader, for a `ShaderValues` over it.

  It compiles while the program builds, as helix-services' `Shader.compile` compiles one, and returns it as a value in the program: its vertex stage drawn the right way up into a render target whatever it writes (`ShaderOptions.clipScale`) and able to draw one-pixel points (`ShaderOptions.points`), helix-render's includes found (`#include <helix/render/shaders/color.glsl>`). A name the class lists declared with another type stops the build at the call. Both stages are GLSL in one form, as helix-services' `Shader.compile` takes it: `#version 300 es` or 330 to 440, or `#version 450`. The vertex stage may place its vertices itself, declaring what it reads, as raylib's GLSL 330 vertex stages do; it then skins, morphs and instances only as it does so itself, and is cut by the clip planes only where it writes `worldPosition`. Placed by `placeVertex()` (`#include <helix/render/shaders/mesh.glsl>`), skinning, morphing and instancing are done and the outputs a fragment stage reads written, `worldPosition` among them, as the class says.
- `shading`: Gets or sets how the batch's lights shade it: MetallicRoughness until set. Setting a lit shading links the lit shaders (`Light3D` says what else does).
- `baseColor`: Gets or sets the base color, multiplied with the base color texture and the vertex color: white until set.
  Its alpha, times the texture's, the vertex color's and `alphaTexture`'s, is the drawn alpha: what `blend` mixes by (Alpha's source alpha), what `alphaCutoff` tests, and what an RGBA target keeps.
- `baseColorTexture`: Gets or sets the base color texture, or null for none (white).
- `alphaTexture`: Gets or sets the texture whose green multiplies the alpha, three.js's alphaMap, or null for none.
- `vertexColors`: Gets or sets a value indicating whether the mesh's vertex colors multiply the base color: true until set.
- `colorSpace`: Gets or sets how the base color, the base color texture and the vertex color are multiplied: Linear until set.
  Linear decodes the base color and the texture (as its `colorSpace` says), reads the vertex colors as linear, as glTF and three.js hold them, and multiplies in linear light. Srgb multiplies the three as stored, whatever the texture's `colorSpace`, and decodes the product once, as raylib does: an `Unlit` material with `toneMapped` off and no fog then shows the product in an sRGB target as stored (`Renderer.createModel`'s `colorSpace` sets it). Auto is read as Linear.
- `metallic`: Gets or sets how metallic the surface is, in MetallicRoughness: 0 until set. Clamped to 0 to 1.
- `roughness`: Gets or sets how rough the surface is, in MetallicRoughness: 0.5 until set. Clamped to 0 to 1.
- `metallicRoughnessTexture`: Gets or sets the texture whose blue is the metalness and green the roughness, multiplying `metallic` and `roughness`; null for none.
- `specularColor`: Gets or sets the highlight's color: in Phong its specular color, in MetallicRoughness glTF's specular color factor (KHR_materials_specular). White until set.
- `specularIntensity`: Gets or sets how strong the highlight is, multiplying `specularColor` in MetallicRoughness (glTF's specular factor): 1 until set. Clamped to 0 to 1.
- `shininess`: Gets or sets how tight Phong's highlight is, its exponent: 30 until set, as three.js has it. Below 0 is clamped to 0.
- `ior`: Gets or sets the index of refraction a dielectric's reflectance follows, in MetallicRoughness (KHR_materials_ior): 1.5 until set. Clamped to 1 to 2.333.
- `clearcoat`: Gets or sets how strong a clear lacquer layer over the surface is, in MetallicRoughness (KHR_materials_clearcoat): 0 until set, none. Clamped to 0 to 1.
- `clearcoatRoughness`: Gets or sets how rough the clear layer is: 0 until set. Clamped to 0 to 1.
- `sheenColor`: Gets or sets the color of a cloth's sheen at grazing angles, in MetallicRoughness (KHR_materials_sheen): black until set, none.
- `sheenRoughness`: Gets or sets how rough the sheen is: 0 until set. Clamped to 0 to 1.
- `normalTexture`: Gets or sets the normal map, in tangent space with green up; null for none. A mesh without tangents ignores it.
- `normalScale`: Gets or sets how strongly the normal map bends the surface: 1 until set, 0 flat. Below 0 is clamped to 0.
- `flatShading`: Gets or sets a value indicating whether each triangle is shaded flat, by its own face's normal: false until set.
- `occlusionTexture`: Gets or sets the occlusion map, its red how much of the ambient and environment light reaches the surface; null for none.
- `occlusionIntensity`: Gets or sets how strongly the occlusion map darkens: 1 until set. Clamped to 0 to 1.
- `lightTexture`: Gets or sets a baked light map, linear light added as the ambient light is, three.js's lightMap; null for none.
- `lightIntensity`: Gets or sets how strongly the light map lights: 1 until set. Below 0 is clamped to 0.
- `emissiveColor`: Gets or sets the light it gives off, lit or not: black until set.
- `emissiveStrength`: Gets or sets how bright its emissive light is, multiplying `emissiveColor`: 1 until set. Below 0 is clamped to 0.
- `emissiveTexture`: Gets or sets the emissive texture, multiplying `emissiveColor`; null for none.
- `environmentMap`: Gets or sets an environment map of its own, in place of the batch's environment's; null until set, for the batch's.
- `environmentIntensity`: Gets or sets how strongly the environment map lights it, three.js's envMapIntensity: 1 until set. Below 0 is clamped to 0.
- `textureTransform`: Gets the matrix its texture coordinates are moved by, before every texture is read: identity until changed, as glTF's KHR_texture_transform and a three.js texture's offset, repeat and rotation give it.
  It is read at each draw, so changing it each frame scrolls, turns or tiles the material's textures with no shader of the program's (`material.textureTransform.makeIdentity().appendTranslation(time * .1, 0, material.textureTransform)`).
- `alphaCutoff`: Gets or sets the alpha below which a texel isn't drawn, for cut-out leaves and fences, in the color and the shadow pass alike: 0 until set, so nothing is cut. Clamped to 0 to 1.
- `blend`: Gets or sets how it is combined with what is behind it: `Blend.OPAQUE` until set; any factors and operations the platform's `Blend` takes, three.js's custom blending among them. A blended surface is drawn where it is in the order, so the program draws it after what is behind it, farthest first.
- `colorWrite`: Gets or sets the color channels it writes: all four until set; none for a depth-only draw, as three.js's `colorWrite` false.
- `cull`: Gets or sets which faces aren't drawn: Back until set; None for a surface seen from both sides; Front for its inside alone (a room's walls seen from out of it, a sky dome). A back face drawn is lit as the side the viewer sees: its normal turned toward the viewer.
- `depthTest`: Gets or sets the depth test: LessEqual until set.
- `depthWrite`: Gets or sets a value indicating whether it writes depth: true until set; false suits a blended surface.
- `fog`: Gets or sets a value indicating whether the batch's fog fades it: true until set.
- `toneMapped`: Gets or sets a value indicating whether its color is exposed and tone mapped into an sRGB target, as lit color is: true until set; false keeps a light's bulb or a sign as bright as its color says. Into an RGBA16F target nothing is tone mapped as it is drawn, and the resolve (`PostProcess`) maps the whole frame, this material's light too.
- `castShadows`: Gets or sets a value indicating whether meshes drawn with it cast shadows, where the batch's `castShadows` is on too: true until set. Off for glass, a light's bulb, a decal.
- `receiveShadows`: Gets or sets a value indicating whether meshes drawn with it are darkened by shadows, where the batch's `receiveShadows` is on too: true until set.
- `shaderValues`: Gets or sets the program's own shader that draws it, as values over it carrying the shader's own uniforms and textures, or null for the batch's default for its `shading`: null until set.
  Its shader is compiled by `compileShader` or `compileShaderStages`, and reads the names the class lists, this material's colors, values and textures among them. Names given by `Shader.withNames` are filled exactly as names declared in the GLSL, and the batch shares `View` and `Lighting` with each draw itself, so the program sets no `ShaderValues.scene` and shares no block. Several materials may share one values, or each have values of its own over a shared base (`ShaderValues.base`).

## MeshState3D

*class* in [`libs/render/src/helix/render/MeshState3D.hx`](../../libs/render/src/helix/render/MeshState3D.hx), `import helix.render.MeshState3D;`

Represents state a mesh draw takes in place of its material's: its blend, depth test, depth write, cull and color channels, each null for the material's own.

`Batch3D.drawMesh` and `drawModel` (and `DrawList3D`'s) take one, read as each draw is made, and change nothing in the material. A layer whose state is global keeps one and updates it as its state changes: helix-raylib keeps one mirroring rlgl's, passed to every mesh draw, while the materials stay as three.js expects them.

```haxe
var rlState = new MeshState3D();
rlState.depthWrite = false; // rlDisableDepthMask
batch.drawModel(model, transform, null, tint, rlState);
```

```haxe
function new()
var blend:Null<Blend>
var depthTest:Null<DepthTest>
var depthWrite:Null<Bool>
var cull:Null<CullFace>
var colorWrite:Null<ColorChannels>
```

- `new`: Creates state that takes nothing from the material: every value null.
- `blend`: Gets or sets how the draw is blended, or null for the material's `blend`: null until set.
- `depthTest`: Gets or sets the draw's depth test, or null for the material's `depthTest`: null until set.
- `depthWrite`: Gets or sets whether the draw writes depth, or null for the material's `depthWrite`: null until set.
- `cull`: Gets or sets which faces the draw leaves out, or null for the material's `cull`: null until set.
- `colorWrite`: Gets or sets the color channels the draw writes, or null for the material's `colorWrite`: null until set.

## PointLight3D

*class* in [`libs/render/src/helix/render/PointLight3D.hx`](../../libs/render/src/helix/render/PointLight3D.hx), `import helix.render.PointLight3D;`, extends `Light3D`

Represents a light from a point, in every direction, falling off with the square of the distance and, given a range, to nothing at it.

Its intensity is three.js's PointLight's with decay 2 (candela, as glTF's KHR_lights_punctual has it): the light falling on a surface facing it at a distance d is its color times intensity / d². A range fades that smoothly to nothing at the range, as glTF's recommended window does: times (1 - (d / range)⁴)², clamped to 0.

```haxe
function new()
final position:Vector3D
var range(default, set):Float
```

- `new`: Creates a white point light of intensity π at the origin, with no range: a white surface facing it 1 unit away shows white.
- `position`: Gets its position, in world units: the origin until changed.
- `range`: Gets or sets its range, in world units, past which it lights nothing: 0 for none, so it only falls off. 0 until set; below 0 is clamped to 0.

## PolygonMode3D

*abstract* in [`libs/render/src/helix/render/PolygonMode3D.hx`](../../libs/render/src/helix/render/PolygonMode3D.hx), `import helix.render.PolygonMode3D;`

Specifies how a `Batch3D` draws the triangles of a mesh or of `drawTriangles`: filled, as their edges, or as their corners.

- `PolygonMode3D.Fill`: Filled: the triangles themselves.
- `PolygonMode3D.Lines`: Each triangle's edges, as one-pixel lines: raylib's wire mode, three.js's `wireframe`.
- `PolygonMode3D.Points`: Each triangle's corners, as points of `Batch3D.pointSize`: raylib's point mode, three.js's `Points`. Points of one pixel are drawn a point an index for an indexed mesh, so a corner shared by triangles is drawn once each, as raylib draws them. A mesh's larger points are drawn once a vertex, each a square made in the vertex stage, and an instanced mesh's a GPU draw for each copy.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Fill, Lines): what Std.string, interpolation and trace show.

## RenderTarget2D

*class* in [`libs/render/src/helix/render/RenderTarget2D.hx`](../../libs/render/src/helix/render/RenderTarget2D.hx), `import helix.render.RenderTarget2D;`, extends `Texture2D`

Represents a texture that draws go into: a pass between `Renderer.beginTarget` and `Renderer.endTarget` draws into it, and it is then drawn or sampled like any texture.

`Renderer.createRenderTarget` makes one. Its format says what it holds: an RGBA8 target sRGB values, as the screen does, an RGBA16F one linear light, which may run past 1 and blends linearly; the batches' own shaders write each its kind (`Batch2D`, `Batch3D`). Drawn or sampled, its texels are what it holds, so an RGBA16F target reaches the screen through `PostProcess.draw`, which exposes, tone maps and encodes it. It is sampled the right way up, as an image is: v 0 at the top of what was drawn into it, on every backend.

A pass into it starts cleared, or keeps what it holds (`Renderer.beginTarget`). Its multisampling is its own (`msaaSampleCount`, the screen's unless `Renderer.createRenderTarget` is given another), whatever its depth, and is resolved at the end of each pass; with `TargetDepth.Texture` its depth can be sampled after it.

**Read, then drawn into again.** A draw reads the target as it is at that point of the frame's recording. A pass begun into it after something read it goes into a fresh copy that takes its place (copy on write, `Renderer.beginTarget`), so a screen draw recorded before shows it as it was, as raylib's frame does. Its `handle` changes then; `sharedTexture` follows.

```haxe
var minimap = renderer.createRenderTarget(256, 256);
renderer.beginTarget(minimap, 0xff000000);
batch.beginCamera(mapCamera);
drawWorld(batch);
batch.end();
renderer.endTarget();
batch.begin();
batch.drawTexture(minimap, 16, 16);
batch.end();
```

```haxe
final format:TextureFormat
final depth:TargetDepth
final msaaSampleCount:Int
final depthTexture:Null<Texture2D>
function resize(width:Int, height:Int):Void
```

- `format`: Gets the texels' format.
- `depth`: Gets the depth it has.
- `msaaSampleCount`: Gets the number of multisampling samples per pixel it is drawn with, 1 for none: what `Renderer.createRenderTarget` was given, or the screen's, as this GPU allows it. It is kept through a copy and a resize.
- `depthTexture`: Gets its depth as a texture, read as a float from 0 (near) to 1 (far) after each pass into it, for effects that read depth; null unless it was made with `TargetDepth.Texture`. It follows the target through a copy and a resize.
- `resize`: Changes its size, as for a window resized: it then holds transparent black, and its depth the farthest.
  - `width`: The width, in texels.
  - `height`: The height, in texels.
  - throws `String`: A size of 0 or less, a size this GPU can't make, a pass into it open, or a disposed target.

  Draws recorded this frame before the call read it as it was; its old texture is freed after the frame. Its `handle` changes, and `sharedTexture` follows.

## Renderer

*class* in [`libs/render/src/helix/render/Renderer.hx`](../../libs/render/src/helix/render/Renderer.hx), `import helix.render.Renderer;`

Provides drawing over the platform's graphics: the textures, meshes and fonts a program draws with, and the frame they are drawn in, pass by pass.

A program constructs one over its `IGraphics`, then a `Batch2D` and a `Batch3D` over it for what it draws, and `DrawList2D`s and `DrawList3D`s for drawing it records once and replays. Each frame it calls `beginFrame`, draws through its batches (and into render targets between `beginTarget` and `endTarget`), and calls `endFrame`, then the platform's `IGraphics.present` itself. The renderer runs no loop and reads no clock.

A frame is recorded as it is drawn and reaches the GPU at `endFrame`: every render target's pass first, in the order they were begun, then the screen's. In each pass, draws are drawn in the order they were called. A draw that reads a target (a sprite of it, a material's texture, a shader's sampler, `PostProcess.draw`) reads it as it is at that point of the recording: the passes into it begun before the draw, and none after. A target drawn into again after something read it is given a fresh texture for the new pass (`beginTarget`), so the earlier draw keeps the old, as raylib's render textures behave.

**Shaders.** The renderer builds every shader its batches, materials and effects draw with on the GPU (helix-services' `ShaderPrograms`, its own), when the frame is drawn at `endFrame`, before the frame's first pass, so a shader drawn for the first time mid-frame is built then; a shader replaced in place (`Shaders.watch`) is built again there too. A program watching shader files calls `Shaders.prepareFrame` before `beginFrame`.

What `createX` makes is the program's, and the program frees it with its `dispose()`. It may be made at any time, outside a frame or in one; made in a frame, it may be drawn in that frame. Nothing is counted or shared: a texture a material names is not owned by the material, and disposing one that a material still names makes that material's draws throw. Something disposed while the frame being recorded holds a draw of it is freed after `endFrame`. `dispose` frees everything still held.

```haxe
var renderer = new Renderer(graphics);
var batch = new Batch2D(renderer);
var ship = renderer.createTexture(shipImage);
// each frame:
renderer.beginFrame(window.framebufferWidth, window.framebufferHeight, 0xff101820);
batch.begin();
batch.drawTexture(ship, 100, 80);
batch.end();
renderer.endFrame();
graphics.present();
```

```haxe
function new(graphics:IGraphics)
final graphics:IGraphics
var viewportWidth(default, null):Int
var viewportHeight(default, null):Int
var inFrame(default, null):Bool
var exposure(default, set):Float
var toneMapping:ToneMapping
function createTexture(image:Image):Texture2D
function createTextureFromImage(image:IDecodedImage):Texture2D
function createTextureMipmapped(image:Image):Texture2D
function createRenderTarget(width:Int, height:Int, ?format:TextureFormat = Rgba8, ?depth:TargetDepth = Buffer, ?msaaSampleCount:Int):RenderTarget2D
function createCubeTexture(faces:Array<Image>):CubeTexture3D
function createCubeTextureMipmapped(faces:Array<Image>):CubeTexture3D
function createMesh(mesh:Mesh3D, ?updatedOften:Bool = false):GpuMesh3D
function createModel(model:Model3D, ?colorSpace:ColorSpace = Auto):GpuModel3D
function createModelMipmapped(model:Model3D, ?colorSpace:ColorSpace = Auto):GpuModel3D
function createEnvironmentMap(bake:EnvironmentBake3D):EnvironmentMap3D
function createFont(font:Font2D):GpuFont2D
function beginFrame(width:Int, height:Int, ?clearColor:Int):Void
function endFrame():Void
function beginTarget(target:RenderTarget2D, ?clearColor:Int):Void
function endTarget():Void
function clearTarget(color:Int):Void
function applyViewport(x:Int, y:Int, width:Int, height:Int):Void
function resetViewport():Void
function applyScissor(x:Int, y:Int, width:Int, height:Int):Void
function resetScissor():Void
function dispose():Void
```

- `new`: Creates a renderer over the graphics.
  - `graphics`: The graphics to draw with.

  It makes only what every batch shares: a white texture, the vertex buffers, and the programs it builds shaders into. Each batch makes its own default shaders when it is constructed, so a program carries the shaders of the batches it uses.
- `graphics`: Gets the graphics it draws with.
- `viewportWidth`: Gets the width of the current pass's viewport, in pixels: the screen's framebuffer pixels or the target's texels. It is what a `Batch2D` without a camera measures in, and what a `Batch3D` takes its aspect from. 0 outside a frame.
- `viewportHeight`: Gets the height of the current pass's viewport, in pixels. 0 outside a frame.
- `inFrame`: Gets a value indicating whether a frame is being recorded: from `beginFrame` until `endFrame`.
- `exposure`: Gets or sets the exposure, in stops: each one doubles linear light before it is tone mapped. 0 until set.
  It and `toneMapping` are the one pair every lit draw is brought to the screen by. Into an sRGB target (RGBA8, the screen), `Batch3D`'s lit shaders apply them as they draw, read at each `Batch3D.begin`; into an RGBA16F target the batch writes linear light and `PostProcess.draw` applies them in its resolve, read at each call. A value that isn't finite is taken as 0.
- `toneMapping`: Gets or sets how exposed linear light is brought into the 0 to 1 an sRGB target holds: Neutral until set. Read as `exposure` is.
- `createTexture`: Uploads an image as a texture, without mipmaps.
  - `image`: The image. Its pixels are copied, so it may be changed or dropped after.
  - returns: The texture, sampled linearly and clamped until its `sampling` is set; `Sampling`'s anisotropy sharpens it at grazing angles. `createTextureMipmapped` makes one that shrinks without shimmering.
  - throws `String`: An image larger than this GPU allows.
- `createTextureFromImage`: Uploads an image decoded for the GPU (helix-services' `Images.decodeForGpu`) as a texture, without mipmaps: in a page the browser's image goes to the GPU as it is, its pixels never held here.
  - `image`: The decoded image. It is left to the caller, who disposes it once uploaded.
  - returns: The texture, sampled linearly and clamped until its `sampling` is set, as `createTexture` gives one.
  - throws `String`: An image larger than this GPU allows.
- `createTextureMipmapped`: Uploads an image as a texture with its mipmaps, made on the CPU (helix-services' `Image.getMipmaps`), so it shrinks without shimmering.
  - `image`: The image. Its pixels are copied, so it may be changed or dropped after.
  - returns: The texture, sampled linearly and clamped until its `sampling` is set, its mipmaps blended (`MipmapFilter.Linear`); `Sampling`'s anisotropy sharpens it at grazing angles.
  - throws `String`: An image larger than this GPU allows.
- `createRenderTarget`: Creates a render target: a texture that draws can go into, between `beginTarget` and `endTarget`.
  - `width`: The width, in texels.
  - `height`: The height, in texels.
  - `format`: Optional. The texels' format: Rgba8, holding sRGB values as the screen does, or Rgba16f, holding linear light, where `IGraphics.canRender` allows it; defaults to Rgba8.
  - `depth`: Optional. Its depth: none, a buffer, or a buffer sampled after the pass; defaults to a buffer.
  - `msaaSampleCount`: Optional. The multisampling samples per pixel it is drawn with, resolved into the texture at the end of each pass, whatever its depth: 1 for none; the screen's (`IGraphics.msaaSampleCount`) when omitted, so its edges are smooth where the screen's are. Clamped to 1 to `IGraphics.maxMsaaSampleCount`, and to 1 where this GPU cannot multisample the format. raylib's render textures are 1, with depth.
  - returns: The render target, holding transparent black until drawn into.
  - throws `String`: A size of 0 or less, or a format this GPU cannot draw into.
- `createCubeTexture`: Uploads six square images as a cube texture, without mipmaps, for a program's own shader to sample by direction (`samplerCube`).
  - `faces`: The faces, in the order +X, -X, +Y, -Y, +Z, -Z, as a cube's faces are seen from inside it, each the same size. Their pixels are copied.
  - returns: The cube texture, sampled linearly. `createCubeTextureMipmapped` makes one with mipmaps.
  - throws `String`: Not six faces, faces not square and alike, or larger than this GPU allows.
- `createCubeTextureMipmapped`: Uploads six square images as a cube texture with each face's mipmaps, made on the CPU, for a program's own shader to sample by direction (`samplerCube`).
  - `faces`: The faces, in the order +X, -X, +Y, -Y, +Z, -Z, as a cube's faces are seen from inside it, each the same size. Their pixels are copied.
  - returns: The cube texture, sampled linearly.
  - throws `String`: Not six faces, faces not square and alike, or larger than this GPU allows.
- `createMesh`: Uploads a mesh's vertices and indices.
  - `mesh`: The mesh: positions, and its normals, texture coordinates, tangents, colors, joints and weights when it has them.
  - `updatedOften`: Optional. Whether it will be updated often, as each frame for vertices moved on the CPU; defaults to false.
  - returns: The uploaded mesh.
  - throws `String`: A mesh without positions, or whose arrays do not match its vertex count.

  The mesh's arrays are copied, so it may be changed or dropped after; `GpuMesh3D.update` sends it again. Its positions are kept on the CPU, and a skinned mesh's joints and weights, with each joint's box of the vertices it moves, for culling and `GpuMesh3D.computeBounds`.
- `createModel`: Uploads a model: each mesh, each image as a texture without mipmaps, as raylib's `LoadModel` makes them, and each material as a `Material3D` over them; `createModelMipmapped` makes its textures with mipmaps.
  - `model`: The model, as helix-services' `Models` reads it.
  - `colorSpace`: Optional. How the file's color factors and vertex colors are taken. `Auto`, the default, as the format says: glTF's are linear, its factors encoded to sRGB for the materials' 0xAARRGGBB colors and its vertex colors read as linear (`Material3D.colorSpace` Linear); an OBJ file's are sRGB. `Srgb` takes them as stored, as raylib does: each factor times 255 into the color unconverted, and the materials' `colorSpace` Srgb, so base color, texture and vertex color are multiplied as stored and an unlit model with `toneMapped` off shows the file's numbers in an sRGB target as raylib does. `Linear` takes every file's as linear.
  - returns: The uploaded model, which owns its meshes and textures.

  An image that is null (one the model couldn't read) gives no texture, and a material naming it draws without it. A mesh without a material in the file is given one more material, white, at the end of `materials`. Each texture's `colorSpace` is set from the slot it fills. Where helix-formats' `GltfMaterial` gives them, its alpha mode, cutoff and double-sidedness become `blend`, `alphaCutoff` and `cull`, its textures' samplers their `sampling`, its texture transform `textureTransform`, and its KHR_materials_clearcoat, sheen, specular, ior and emissive_strength values the material's; otherwise opaque, uncut, back faces culled, linear and repeated, and none of the extensions. An OBJ file's materials are shaded `Phong` from their Ks and Ns. Meshes keep their morph targets.

  Each image goes to the GPU once, taken from the model (`ModelImage3D.takeDecoded`) and disposed once sent: a second GpuModel3D of the same model has no textures. One GpuModel3D is drawn as often as wanted.
- `createModelMipmapped`: Uploads a model as `createModel` does, its textures made with mipmaps (`createTextureMipmapped`, from each image's pixels), as three.js makes them.
  - `model`: The model, as helix-services' `Models` reads it.
  - `colorSpace`: Optional. How the file's color factors and vertex colors are taken, as `createModel` takes it; `Auto` by default.
  - returns: The uploaded model, which owns its meshes and textures.
- `createEnvironmentMap`: Uploads a finished environment bake: its prefiltered and background cubes, and its irradiance.
  - `bake`: The bake, `done`.
  - returns: The environment map.
  - throws `String`: A bake not done, or a GPU that can't sample half floats (`IGraphics.canSample(Rgba16f)`).

  The first also makes the BRDF table every environment map shares.
- `createFont`: Uploads a font's atlas, so its text can be drawn.
  - `font`: The font, as helix-services' `Fonts` makes it.
  - returns: The font, ready to draw and measure with.

  A bitmap font's atlas is sampled nearest, the others' linearly.
- `beginFrame`: Starts recording a frame, with the screen's pass.
  - `width`: The framebuffer's width, in framebuffer pixels (`IWindow.framebufferWidth`).
  - `height`: The framebuffer's height, in framebuffer pixels.
  - `clearColor`: Optional. The color the screen is cleared to, as 0xAARRGGBB; opaque black when omitted.
  - throws `String`: A frame already being recorded, or a size of 0 or less.

  Given a color, the screen is cleared to it and the farthest depth. Omitted, the program clears nothing: the screen starts as the platform starts a frame, opaque black with the farthest depth (`IGraphics.beginFrame` clears every frame, and a swap chain need not keep the last frame's pixels), so a raylib layer's `ClearBackground` is `clearTarget`, and one recorded before any draw of the pass costs nothing past the platform's own clear. The viewport is all of it.

  A frame may draw only into render targets, with nothing in the screen's pass: `endFrame` draws them, and `IGraphics.present`, if the program calls it, shows the screen as cleared, its color or black.
- `endFrame`: Ends the frame and draws it: the shaders it draws with built where they aren't, then each shadow pass, each render target's pass, in the order begun, and the screen's, then `IGraphics.endFrame`.
  - throws `String`: No frame being recorded, a batch still open, a target pass not ended, or a shader the GPU refused, with the compiler's log.

  The frame is then submitted but not shown: the program calls `IGraphics.present`, and may read it back first (`IGraphics.readPixels(0, ...)`, or helix-services' `Screenshots.frameEnded`).
- `beginTarget`: Starts a pass into a render target: the draws after it go into the target, until `endTarget`.
  - `target`: The render target.
  - `clearColor`: Optional. The color it is cleared to, as 0xAARRGGBB; it keeps what it holds when omitted.
  - throws `String`: No frame being recorded, a target pass already open, a batch open, or a disposed target.

  Given a color, the target is cleared to it (decoded to linear light in an RGBA16F target, so it shows as given once resolved without tone mapping), and its depth to the farthest; omitted, the target keeps what it holds, its texels and its depth, as a painting, trails or raylib's render textures do. The viewport is all of it and nothing is clipped. Drawing the target into itself throws.

  **A target read earlier in the frame is copied on write.** When a draw recorded before this call reads the target, the pass goes into a fresh texture of the same size and format, which takes the target's place (`Texture2D.handle` and `sharedTexture` follow it): holding a copy of what the target held when omitted a color, or cleared to the color given. The earlier draw reads the old texture, so a screen draw shows the target as it was when the draw was recorded, as raylib's frame does. The old texture is freed after the frame; a target read and redrawn each frame costs one more texture of its size, and a copy when not cleared.
- `endTarget`: Ends the target pass, going back to the screen's: its viewport and clip as they were before `beginTarget`.
  - throws `String`: No target pass open, or a batch still open.
- `clearTarget`: Clears the current pass to a color: what was drawn into it before is dropped, and its depth is the farthest again.
  - `color`: The color, as 0xAARRGGBB.
  - throws `String`: No frame being recorded.

  It is recorded where it is called, a batch open or not: the draws before it, the open batch's among them, are dropped, and those after it are drawn over the color, as raylib's `ClearBackground` between two draws. An open batch stays open, its draw state unchanged. The whole pass is cleared, whatever the viewport.
- `applyViewport`: Sets the rectangle of the current pass that the following draws fill, until `resetViewport` or the pass's end.
  - `x`: The left edge, in the pass's pixels from its left.
  - `y`: The top edge, in the pass's pixels from its top.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - throws `String`: No frame being recorded, a batch open, or a size of 0 or less.

  A `Batch2D` without a camera then measures from the viewport's top left, and a `Batch3D` takes its aspect from it, so a split screen or a design size fitted to the window (helix-services' `Screen.viewportX` and the rest) is drawn by setting it. It takes effect at the next `begin` of a batch, and setting it while a batch is open throws.
- `resetViewport`: Sets the viewport back to the whole pass.
  - throws `String`: No frame being recorded, or a batch open.
- `applyScissor`: Clips the following draws to a rectangle of the current pass, until `resetScissor` or the pass's end.
  - `x`: The left edge, in the pass's pixels from its left.
  - `y`: The top edge, in the pass's pixels from its top.
  - `width`: The width, in pixels; 0 clips everything.
  - `height`: The height, in pixels; 0 clips everything.
  - throws `String`: No frame being recorded, or a size below 0.

  It may be set while a batch is open; the draws before it are not clipped by it.
- `resetScissor`: Removes the clip that `applyScissor` set.
  - throws `String`: No frame being recorded.
- `dispose`: Frees everything made through it that the program hasn't disposed, then its own textures and buffers.
  It is called before `IGraphics.dispose`, outside a frame.

## Shading3D

*abstract* in [`libs/render/src/helix/render/Shading3D.hx`](../../libs/render/src/helix/render/Shading3D.hx), `import helix.render.Shading3D;`

Specifies how a `Material3D` is shaded by the batch's lights.

- `Shading3D.Unlit`: Not lit: its colors as they are, three.js's MeshBasicMaterial and raylib's default.
- `Shading3D.Lambert`: Diffuse light alone, by the angle to each light: three.js's MeshLambertMaterial.
- `Shading3D.Phong`: Diffuse light and a Blinn-Phong highlight of `specularColor` and `shininess`: three.js's MeshPhongMaterial, and what an OBJ material's Ks and Ns describe.
- `Shading3D.MetallicRoughness`: glTF's metallic-roughness model, with its clearcoat, sheen and specular extensions where set: three.js's MeshStandardMaterial and MeshPhysicalMaterial.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Unlit, Lambert): what Std.string, interpolation and trace show.

## SpotLight3D

*class* in [`libs/render/src/helix/render/SpotLight3D.hx`](../../libs/render/src/helix/render/SpotLight3D.hx), `import helix.render.SpotLight3D;`, extends `Light3D`

Represents a point light shining in a cone: full inside its inner cone, fading to nothing at its outer, falling off with distance as a `PointLight3D` does.

```haxe
function new()
final position:Vector3D
final direction:Vector3D
var range(default, set):Float
var innerCone(default, null):Float
var outerCone(default, null):Float
function setCone(innerCone:Float, outerCone:Float):Bool
```

- `new`: Creates a white spot light of intensity π at the origin shining straight down, with no range and cones of 0.3 and 0.4 radians.
- `position`: Gets its position, in world units: the origin until changed.
- `direction`: Gets the direction it shines in, its cone's axis; it needn't be of length 1. Straight down until changed.
- `range`: Gets or sets its range, in world units, past which it lights nothing: 0 for none. 0 until set; below 0 is clamped to 0.
- `innerCone`: Gets its inner cone, in radians from its axis: full light inside it. 0.3 until set.
- `outerCone`: Gets its outer cone, in radians from its axis: no light past it. 0.4 until set.
- `setCone`: Sets its cones.
  - `innerCone`: The inner cone, in radians from its axis.
  - `outerCone`: The outer cone, in radians from its axis.
  - returns: False, changing nothing, unless 0 <= innerCone <= outerCone < π / 2.

## TargetDepth

*abstract* in [`libs/render/src/helix/render/TargetDepth.hx`](../../libs/render/src/helix/render/TargetDepth.hx), `import helix.render.TargetDepth;`

Specifies the depth a render target has; its multisampling is chosen apart (`Renderer.createRenderTarget`'s `msaaSampleCount`).

- `TargetDepth.None`: No depth: for a pass that draws over the whole target, as a screen effect does, or 2D.
- `TargetDepth.Buffer`: A depth buffer, for 3D drawn into it.
- `TargetDepth.Texture`: A depth buffer that can be sampled after the pass (`RenderTarget2D.depthTexture`), for effects that read depth: fog, depth of field, ambient occlusion, soft particles.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (None, Buffer): what Std.string, interpolation and trace show.

## TextAlign2D

*abstract* in [`libs/render/src/helix/render/TextAlign2D.hx`](../../libs/render/src/helix/render/TextAlign2D.hx), `import helix.render.TextAlign2D;`

Specifies where each line of a `TextLayout2D` sits across its box.

- `TextAlign2D.Left`: Each line starts at the box's left edge.
- `TextAlign2D.Center`: Each line is centered in the box.
- `TextAlign2D.Right`: Each line ends at the box's right edge.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Left, Center): what Std.string, interpolation and trace show.

## TextLayout2D

*class* in [`libs/render/src/helix/render/TextLayout2D.hx`](../../libs/render/src/helix/render/TextLayout2D.hx), `import helix.render.TextLayout2D;`

Represents text laid out in lines: broken at line breaks and, given a width, wrapped between words, each line aligned in its box.

It is made once and kept while its text stays the same, so a paragraph is laid out once, not each frame; assigning a property lays it out again the next time it is measured or drawn. `Batch2D.drawTextLayout` draws it. Lines wrap where a space is, the spaces at the end of a line not counted in its width; a word wider than the box is broken between its characters.

```haxe
var story = new TextLayout2D(font, "A long paragraph...", 18);
story.maxWidth = 300;
story.align = Center;
batch.drawTextLayout(story, 20, 40);
var below = 40 + story.height;
```

```haxe
function new(font:GpuFont2D, ?text:String = "", ?size:Float)
var font(default, set):GpuFont2D
var text(default, set):String
var size(default, set):Float
var maxWidth(default, set):Float
var align(default, set):TextAlign2D
var lineSpacing(default, set):Float
var letterSpacing(default, set):Float
var kerned(default, set):Bool
var width(get, never):Float
var height(get, never):Float
var lineCount(get, never):Int
```

- `new`: Creates a layout of text in a font.
  - `font`: The font.
  - `text`: Optional. The text; defaults to empty.
  - `size`: Optional. The size it is drawn at; the font's own when omitted.
- `font`: Gets or sets the font.
- `text`: Gets or sets the text.
- `size`: Gets or sets the size it is drawn at, as the font's size is measured, in the units it is drawn in.
- `maxWidth`: Gets or sets the width of its box, past which lines wrap: 0 for none, so lines break at line breaks alone. 0 until set; below 0 is clamped to 0.
- `align`: Gets or sets where each line sits across the box: Left until set.
- `lineSpacing`: Gets or sets the distance from one line's top to the next's, as a multiple of the font's line height at `size`: 1 until set.
- `letterSpacing`: Gets or sets the space added after each character, in the units it is drawn in, as `Batch2D.drawText`'s `letterSpacing`: 0 until set.
- `kerned`: Gets or sets a value indicating whether pairs of characters are kerned as the font gives them, as `Batch2D.drawText`'s `kerned`: true until set. raylib's `DrawTextEx` doesn't kern.
- `width`: Gets the width of its widest line, in the units it is drawn in.
- `height`: Gets the height of its lines, from the first's top to the last's bottom.
- `lineCount`: Gets the number of lines, wrapped and broken; 1 for empty text.

## Texture2D

*class* in [`libs/render/src/helix/render/Texture2D.hx`](../../libs/render/src/helix/render/Texture2D.hx), `import helix.render.Texture2D;`

Represents an image on the GPU, drawn as a sprite, read by a material, or bound to a shader.

`Renderer.createTexture` makes one from an `Image`; a `RenderTarget2D` is one that draws go into. The program frees it with `dispose`. Texture coordinates run from 0 at its left and top to 1 at its right and bottom, as its image's rows are stored; a render target's the same way, its top the top of what was drawn into it, on every backend.

A program's own shader reads it through `sharedTexture`:

```haxe
values.shareTexture(shader.getSampler("noise"), noise.sharedTexture);
```

```haxe
var width(default, null):Int
var height(default, null):Int
var sampling(default, set):Sampling
var colorSpace:ColorSpace
final sharedTexture:ShaderSharedTexture
var handle(default, null):Int
var disposed(default, null):Bool
function update(image:Image, ?x:Int = 0, ?y:Int = 0):Void
function writeWhiteTexel(x:Int, y:Int):TextureRegion2D
function dispose():Void
```

- `width`: Gets the width, in texels.
- `height`: Gets the height, in texels.
- `sampling`: Gets or sets how its draws sample it: its filter, and how it wraps past its edges. Linear and clamped until set; `Sampling.NEAREST` suits pixel art. A change applies to the draws after it, a program's shader reading `sharedTexture` among them.
- `colorSpace`: Gets or sets how helix-render's own shaders read its texels: Auto until set, as the slot it fills says (sRGB in a color slot, linear in a data slot). A custom shader is given its texels as they are, whatever this says.
- `sharedTexture`: Gets the texture as helix-services' shared texture, for a program's own shader to read: shared on its values (`ShaderValues.shareTexture`), it reads this texture with its `sampling`.
  helix-render keeps it current: its handle follows the texture through a copy made when a render target is drawn into again (`Renderer.beginTarget`) and through `RenderTarget2D.resize`, and its sampling follows `sampling`. It reads 0, no texture, once the texture is disposed. A draw recorded reads it as it is when the draw is made.
- `handle`: Gets the platform's handle, for what only `IGraphics` does with it (`readPixels`, which reads any texture back); 0 once disposed. A render target's changes when a pass copies it on write (`Renderer.beginTarget`) and when it is resized; read it when it is used, and bind it to a shader through `sharedTexture`.
- `disposed`: Gets a value indicating whether it has been disposed.
- `update`: Replaces a rectangle of its texels with an image's pixels, for the draws after it.
  - `image`: The pixels.
  - `x`: Optional. The left edge of the rectangle replaced, in texels; defaults to 0.
  - `y`: Optional. The top edge, in texels; defaults to 0.
  - throws `String`: A rectangle outside the texture, a render target, or a disposed texture.

  It is applied before the pass it is called in, so that pass's draws and the ones after read the new texels, and the passes before read the old (the platform's `updateTexture` goes between passes). Mipmaps are not made again.
- `writeWhiteTexel`: Makes one of its texels opaque white and returns its region, for `Batch2D.shapeRegion`: shapes then draw from this texture, so they join one GPU draw with the sprites of a sheet or the text of a font's atlas, as raylib's `SetShapesTexture` has them.
  - `x`: The texel's column, from the left.
  - `y`: The texel's row, from the top.
  - returns: The texel's region, one texel square.
  - throws `String`: A texel outside the texture, a render target, or a disposed texture.

  The program names a texel no sprite reads (a corner of the sheet's padding). Shapes read the texel's center alone, at full size, so one texel is enough whatever the sampling, and the mipmaps, which it leaves as they were, are never read for it.
- `dispose`: Frees the texture on the GPU, after the frame being recorded when it holds a draw of it. A second call does nothing.

## TextureRegion2D

*class* in [`libs/render/src/helix/render/TextureRegion2D.hx`](../../libs/render/src/helix/render/TextureRegion2D.hx), `import helix.render.TextureRegion2D;`

Represents a rectangle of a texture drawn as a sprite: a frame of a sprite sheet, an image on an atlas, or the whole texture, with the point it is placed and turned by.

It is a plain value, made once and drawn often (`Batch2D.drawSprite`, `Batch3D.drawBillboard`); it holds the texture without owning it. Its origin is the point `drawSprite` places at the position given and turns about when the call gives none: its top left until given, as a texture is placed by `drawTexture`, so a sheet's frames of one character, which share their feet's place, are given it once.

```haxe
var walk = TextureRegion2D.split(sheet, 32, 48, 0, 0, 6, 16, 46); // six frames, placed by their feet
var coin = TextureRegion2D.fromTexture(coinTexture, 8, 8); // the whole texture, turned about its middle
batch.drawSprite(walk[frame], x, y);
batch.drawSprite(coin, coinX, coinY, spin);
```

```haxe
function new(texture:Texture2D, regionX:Float, regionY:Float, regionWidth:Float, regionHeight:Float, ?originX:Float = 0., ?originY:Float = 0.)
static function split(texture:Texture2D, frameWidth:Float, frameHeight:Float, ?margin:Float = 0., ?spacing:Float = 0., ?frameCount:Int, ?originX:Float = 0., ?originY:Float = 0.):Array<TextureRegion2D>
static function fromTexture(texture:Texture2D, ?originX:Float = 0., ?originY:Float = 0.):TextureRegion2D
final texture:Texture2D
final regionX:Float
final regionY:Float
final regionWidth:Float
final regionHeight:Float
final originX:Float
final originY:Float
```

- `new`: Creates a region of a texture.
  - `texture`: The texture.
  - `regionX`: The left edge, in texels from the texture's left.
  - `regionY`: The top edge, in texels from the texture's top.
  - `regionWidth`: The width, in texels.
  - `regionHeight`: The height, in texels.
  - `originX`: Optional. The origin across, in texels from the region's left; defaults to 0. Half the width centers it.
  - `originY`: Optional. The origin down, in texels from the region's top; defaults to 0.
- `split`: Returns the frames of a sprite sheet laid out in a grid: row by row, left to right, top to bottom.
  - `texture`: The sheet.
  - `frameWidth`: Each frame's width, in texels.
  - `frameHeight`: Each frame's height, in texels.
  - `margin`: Optional. The texels around the grid, at the sheet's edges; defaults to 0.
  - `spacing`: Optional. The texels between two frames; defaults to 0.
  - `frameCount`: Optional. How many frames there are, for a last row not full; every whole frame that fits when omitted.
  - `originX`: Optional. Each frame's origin across, in texels from its left; defaults to 0.
  - `originY`: Optional. Each frame's origin down, in texels from its top; defaults to 0.
  - returns: The frames' regions.
  - throws `String`: A frame size of 0 or less.
- `fromTexture`: Returns a region of a whole texture, placed and turned by a point of it.
  - `texture`: The texture.
  - `originX`: Optional. The origin across, in texels from the texture's left; defaults to 0. Half its width centers it.
  - `originY`: Optional. The origin down, in texels from the texture's top; defaults to 0.
  - returns: The region.
- `texture`: Gets the texture.
- `regionX`: Gets the region's left edge, in texels from the texture's left.
- `regionY`: Gets the region's top edge, in texels from the texture's top.
- `regionWidth`: Gets the region's width, in texels.
- `regionHeight`: Gets the region's height, in texels.
- `originX`: Gets the point it is placed and turned by when a draw gives none, across, in texels from the region's left: 0 until given.
- `originY`: Gets the point it is placed and turned by when a draw gives none, down, in texels from the region's top: 0 until given.

## ToneMapping

*abstract* in [`libs/render/src/helix/render/ToneMapping.hx`](../../libs/render/src/helix/render/ToneMapping.hx), `import helix.render.ToneMapping;`

Specifies how linear light, which can run past 1, is brought into the 0 to 1 an sRGB target holds, after the exposure.

`Renderer.toneMapping` holds the one in use: `Batch3D`'s lit shaders apply it to color drawn straight into an sRGB target, and `PostProcess.draw` when it resolves a linear frame. The curves are three.js's, by the same names.

- `ToneMapping.None`: Neither exposed nor mapped: clamped to 1.
- `ToneMapping.Linear`: Exposed, then clamped to 1.
- `ToneMapping.Reinhard`: Reinhard's curve: x / (1 + x).
- `ToneMapping.Cineon`: The Cineon film curve, as three.js has it.
- `ToneMapping.Aces`: ACES's filmic fit: more contrast, highlights desaturated.
- `ToneMapping.AgX`: AgX: highlights rolled toward white without shifting their hue.
- `ToneMapping.Neutral`: Khronos PBR Neutral: colors as given up to near 1, highlights rolled off.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (None, Linear): what Std.string, interpolation and trace show.

## View3D

*class* in [`libs/render/src/helix/render/View3D.hx`](../../libs/render/src/helix/render/View3D.hx), `import helix.render.View3D;`

Represents one view a `Batch3D` draws through: where the eye is and how it projects, as matrices, and the rectangle of the pass it fills.

`Batch3D.begin(camera)` makes one from a camera. A program gives its own to `Batch3D.beginViews` for what a camera can't say: a projection of its own (an off-center frustum, a view offset, a zoom, rlgl's matrix stack), 2D in pixels (`setFromScreen`), or several views drawn at once, each draw drawn once in each: the two eyes of a headset (WebXR's views, raylib's stereo mode, three.js's ArrayCamera), or split screens that see one scene. `isInView` tests a box against it at any time, so a scene walked before the batch opens is culled by the views it will be drawn through.

```haxe
var left = new View3D(), right = new View3D();
left.viewMatrix.copyFrom(eyeViews[0]);
left.projectionMatrix.copyFrom(eyeProjections[0]);
left.setViewport(0, 0, width >> 1, height);
right.viewMatrix.copyFrom(eyeViews[1]);
right.projectionMatrix.copyFrom(eyeProjections[1]);
right.setViewport(width >> 1, 0, width >> 1, height);
batch.beginViews([left, right]);
```

**In a shader.** Each view is a block a shader reads by `#include <helix/render/shaders/view.glsl>` (block `View`, both stages), written once a view and shared with every draw in it (helix-services' `ShaderScene`), never copied per draw; `Batch2D` writes one for its camera or the viewport. A shader that declares one of its names itself, as raylib's declare `viewProjection`'s kin, is written it per draw instead.

| Name | Type | What | |---|---|---| | `viewMatrix`, `projectionMatrix`, `viewProjection` | mat4 | The view's matrices, and the projection after the view. | | `cameraPosition` | vec4 | The eye, in world units. | | `viewportSize` | vec4 | Its rectangle's width and height in framebuffer pixels, and their inverses. | | `linearTarget` | int | 1 in an RGBA16F target, which holds linear light; 0 in an RGBA8 target or the screen, which hold sRGB. | | `exposure`, `toneMapping` | float, int | `Renderer.exposure` as a multiplier (2 to the stops), and `Renderer.toneMapping`. | | `fogColor`, `fogParams` | vec4 | The fog's color as stored, and its mode, near, far and density. |

**Colors in a shader.** `#include <helix/render/shaders/color.glsl>` (either stage; it includes `view.glsl`) gives the conversions helix-render's own shaders make, and declares `toneMapped` (int: the material's; for a batch draw `Batch3D.toneMapped`; 0 for `Batch2D`'s) for `writeColor`:

```glsl
vec3 decodeSrgb(vec3 color);           // sRGB to linear
vec4 decodeSrgb(vec4 color);           // alpha unchanged
vec3 encodeSrgb(vec3 linear);          // linear to sRGB
vec4 encodeSrgb(vec4 linear);
vec3 applyToneMapping(vec3 linear);    // times exposure, then toneMapping: 0 to 1
vec3 applyFog(vec3 linear, vec3 worldPosition); // toward the fog's color, decoded, by the fog at the eye's distance; unchanged without fog
vec4 encodeColor(vec4 linear);         // for the target: encoded into sRGB, unchanged into linear (linearTarget); never tone mapped
vec4 writeColor(vec4 linear);          // as encodeColor, after applyToneMapping into sRGB where toneMapped is 1
```

The batches' own draws multiply their colors as stored, and write the product as it is into an sRGB target unless fog or tone mapping reaches it (`Batch3D`); a material writes by `writeColor`, through `material.glsl`'s `writeMaterialColor`.

```haxe
function new()
final viewMatrix:Matrix3D
final projectionMatrix:Matrix3D
var viewportX(default, null):Int
var viewportY(default, null):Int
var viewportWidth(default, null):Int
var viewportHeight(default, null):Int
function setFromCamera(camera:Camera3D, aspect:Float):View3D
function setFromScreen(width:Float, height:Float):View3D
function isInView(bounds:Bounds3D):Bool
function setViewport(x:Int, y:Int, width:Int, height:Int):View3D
```

- `new`: Creates a view with identity matrices, filling the renderer's viewport.
- `viewMatrix`: Gets the matrix that puts the world into the eye's space, +y up and looking down -z: changed in place, read at `beginViews`.
- `projectionMatrix`: Gets the matrix that projects the eye's space into GL's clip space (depth -1 to 1), as `Camera3D.computeProjectionMatrix` makes it: changed in place, read at `beginViews`.
- `viewportX`: Gets the left edge of the rectangle it fills, in the pass's pixels from the left of the renderer's viewport: 0 until set.
- `viewportY`: Gets the top edge of the rectangle it fills, in the pass's pixels from the top of the renderer's viewport: 0 until set.
- `viewportWidth`: Gets the width of the rectangle it fills, in pixels: 0 until set, for the whole of the renderer's viewport.
- `viewportHeight`: Gets the height of the rectangle it fills, in pixels: 0 until set, for the whole of the renderer's viewport.
- `setFromCamera`: Sets the matrices to a camera's.
  - `camera`: The camera.
  - `aspect`: The width of what it fills over its height.
  - returns: This view.
- `setFromScreen`: Sets the matrices to draw in pixels: the view identity, and an orthographic projection with x from 0 at the left to `width` at the right and y from 0 at the top to `height` at the bottom, z from 0 (nearest) to -1 (farthest), as raylib's 2D draws without a camera (`rlOrtho(0, width, height, 0, 0, 1)`).
  - `width`: The width it spans, in pixels: the rectangle's, or the renderer's viewport's.
  - `height`: The height it spans, in pixels.
  - returns: This view.

  Sprites, shapes and text drawn by `Batch3D` in their plane (y down the texture) are then upright, a unit a pixel. A 2D camera is its matrix copied into `viewMatrix` after, as raylib's `BeginMode2D` multiplies it in.
- `isInView`: Returns whether a box may be seen through this view: whether it is in the frustum of its matrices as they are now.
  - `bounds`: The box, in world units.
  - returns: True when some of it may be in the frustum; false when all of it is out.

  It may be called at any time, a batch open or not, as a three.js layer culls its scene while walking it before `beginViews`. `Batch3D`'s culling makes the same test against every view it draws through.
- `setViewport`: Sets the rectangle of the renderer's viewport it fills.
  - `x`: The left edge, in pixels from the viewport's left.
  - `y`: The top edge, in pixels from the viewport's top.
  - `width`: The width, in pixels; 0 with a height of 0 for the whole viewport.
  - `height`: The height, in pixels.
  - returns: This view.
