# helix.raylib

[Back to the index](README.md)

## AudioStream

*class* in [`engines/raylib/src/helix/raylib/AudioStream.hx`](../../engines/raylib/src/helix/raylib/AudioStream.hx), `import helix.raylib.AudioStream;`

Represents raylib's `AudioStream`: samples a program makes as it goes, played as they are given (`UpdateAudioStream`), over helix-services' `SampleQueue`.

It holds raylib's double buffer: two buffers of `SetAudioStreamBufferSizeDefault` frames each (1470, a 30th of a second at 44100 Hz, until set), one filled by each update while the other plays.

```haxe
var sampleRate(default, null):Int
var sampleSize(default, null):Int
var channels(default, null):Int
```

- `sampleRate`: Gets the frames a second.
- `sampleSize`: Gets the bits a sample takes: 8 (unsigned), 16 (signed) or 32 (float).
- `channels`: Gets the number of channels: 1 is mono, 2 stereo.

## AutomationEvent

*class* in [`engines/raylib/src/helix/raylib/AutomationEvent.hx`](../../engines/raylib/src/helix/raylib/AutomationEvent.hx), `import helix.raylib.AutomationEvent;`

Represents raylib's `AutomationEvent`: an input or window event, recorded in a frame, to be played later.

```haxe
function new()
var frame:Int
var type:Int
var params:Array<Int>
```

- `new`: Creates one, its fields zero.
- `frame`: Gets or sets the frame it happened in.
- `type`: Gets or sets what happened, as raylib's AutomationEventType numbers it: 1 a key up, 2 a key down, 5 and 6 a mouse button up and down, 7 the mouse moved, 8 the wheel, 11 and 12 a gamepad button up and down, 13 a gamepad axis, 14 and 15 a finger up and down, 16 a finger moved, 17 a gesture, 18 to 21 the window closed, maximized, minimized and resized, 22 a screenshot, 23 the target frames a second.
- `params`: Gets or sets its four parameters, by its type: a key, a button, a position, a gamepad and its button or axis and value (times 32768), a size.

## AutomationEventList

*class* in [`engines/raylib/src/helix/raylib/AutomationEventList.hx`](../../engines/raylib/src/helix/raylib/AutomationEventList.hx), `import helix.raylib.AutomationEventList;`

Represents raylib's `AutomationEventList`: the events recorded, or loaded from a file, to be played.

```haxe
function new()
var capacity:Int
var count:Int
var events:Array<AutomationEvent>
```

- `new`: Creates an empty list, of no capacity.
- `capacity`: Gets or sets the most events it holds: 16384, raylib's MAX_AUTOMATION_EVENTS, for one `LoadAutomationEventList` or `LoadAutomationEventListAsync` made.
- `count`: Gets or sets how many events it holds.
- `events`: Gets or sets the events, `count` of them.

## BoneInfo

*class* in [`engines/raylib/src/helix/raylib/BoneInfo.hx`](../../engines/raylib/src/helix/raylib/BoneInfo.hx), `import helix.raylib.BoneInfo;`

Represents raylib's `BoneInfo`: one bone of a skeleton, its name and its parent.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?name:String, ?parent:Int}
```

```haxe
var name:String
var parent:Int
```

- `name`: Gets or sets the name: its node's, cut to 31 bytes as raylib's holds it.
- `parent`: Gets or sets the parent, by its index in the same bones, or -1 for a root.

## BoundingBox

*class* in [`engines/raylib/src/helix/raylib/BoundingBox.hx`](../../engines/raylib/src/helix/raylib/BoundingBox.hx), `import helix.raylib.BoundingBox;`

Represents raylib's `BoundingBox`: an axis-aligned box by its corners.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?min:Vector3, ?max:Vector3}
```

```haxe
var min:Vector3
var max:Vector3
```

- `min`: Gets or sets the lowest corner.
- `max`: Gets or sets the highest corner.

## Camera

*typedef* in [`engines/raylib/src/helix/raylib/Camera.hx`](../../engines/raylib/src/helix/raylib/Camera.hx), `import helix.raylib.Camera;`

raylib's `Camera`, the same as `Camera3D`.

An alias of `Camera3D`.

## Camera2D

*class* in [`engines/raylib/src/helix/raylib/Camera2D.hx`](../../engines/raylib/src/helix/raylib/Camera2D.hx), `import helix.raylib.Camera2D;`

Represents raylib's `Camera2D`: what it looks at, where that shows on the screen, its rotation and its zoom.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?offset:Vector2, ?target:Vector2, ?rotation:Float, ?zoom:Float}
```

```haxe
var offset:Vector2
var target:Vector2
var rotation:Float
var zoom:Float
```

- `offset`: Gets or sets where the target shows, in the screen's pixels.
- `target`: Gets or sets the point in the world it looks at.
- `rotation`: Gets or sets its rotation, in degrees.
- `zoom`: Gets or sets its zoom, 1 for none.

## Camera3D

*class* in [`engines/raylib/src/helix/raylib/Camera3D.hx`](../../engines/raylib/src/helix/raylib/Camera3D.hx), `import helix.raylib.Camera3D;`

Represents raylib's `Camera3D`, which is also its `Camera`: where it is, what it looks at, and its lens.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?position:Vector3, ?target:Vector3, ?up:Vector3, ?fovy:Float, ?projection:Int}
```

```haxe
var position:Vector3
var target:Vector3
var up:Vector3
var fovy:Float
var projection:Int
```

- `position`: Gets or sets where it is.
- `target`: Gets or sets the point it looks at.
- `up`: Gets or sets its up direction.
- `fovy`: Gets or sets the field of view, top to bottom, in degrees; in orthographic, the height seen.
- `projection`: Gets or sets `CAMERA_PERSPECTIVE` or `CAMERA_ORTHOGRAPHIC`.

## Color

*class* in [`engines/raylib/src/helix/raylib/Color.hx`](../../engines/raylib/src/helix/raylib/Color.hx), `import helix.raylib.Color;`

Represents raylib's `Color`: red, green, blue and alpha, each 0 to 255.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?r:Int, ?g:Int, ?b:Int, ?a:Int}
```

```haxe
var r:Int
var g:Int
var b:Int
var a:Int
```

- `r`: Gets or sets the red, 0 to 255.
- `g`: Gets or sets the green, 0 to 255.
- `b`: Gets or sets the blue, 0 to 255.
- `a`: Gets or sets the alpha, 0 (clear) to 255 (opaque).

## FilePathList

*class* in [`engines/raylib/src/helix/raylib/FilePathList.hx`](../../engines/raylib/src/helix/raylib/FilePathList.hx), `import helix.raylib.FilePathList;`

Represents raylib's `FilePathList`: paths, as a directory listing or a drop gives them.

```haxe
function new()
var capacity:Int
var count:Int
var paths:Array<String>
```

- `new`: Creates an empty list.
- `capacity`: Gets or sets how many paths the list was made for: 8192 for `LoadDirectoryFilesExAsync`'s, the count for `LoadDirectoryFilesAsync`'s, and 0 for `LoadDroppedFiles`'s, as raylib's.
- `count`: Gets or sets how many paths there are.
- `paths`: Gets or sets the paths.

## Font

*class* in [`engines/raylib/src/helix/raylib/Font.hx`](../../engines/raylib/src/helix/raylib/Font.hx), `import helix.raylib.Font;`

Represents raylib's `Font`: its glyphs, their places on its texture, and the texture.

```haxe
function new()
var baseSize:Int
var glyphCount:Int
var glyphPadding:Int
var texture:Texture2D
var recs:Array<Rectangle>
var glyphs:Array<GlyphInfo>
```

- `new`: Creates a font, its fields zero or empty. Fonts are made by `Raylib.GetFontDefault`, `extras.Text.LoadFontExAsync` and the other loads.
- `baseSize`: Gets or sets the size it was made at: its glyphs' height, in pixels.
- `glyphCount`: Gets or sets how many glyphs it has.
- `glyphPadding`: Gets or sets the padding around each glyph on its texture, in pixels.
- `texture`: Gets or sets the texture its glyphs are drawn from.
- `recs`: Gets or sets each glyph's rectangle on the texture.
- `glyphs`: Gets or sets each glyph's character, offsets, advance and image.

## FrameStatsStyle

*class* in [`engines/raylib/src/helix/raylib/FrameStatsStyle.hx`](../../engines/raylib/src/helix/raylib/FrameStatsStyle.hx), `import helix.raylib.FrameStatsStyle;`

Represents how DrawFrameStatsEx (helix.raylib.extras.Debug) draws the frame's cost: which stats, and in what look. Every field has a default, so a style sets only what it changes: `{fontSize: 24, triangles: true}`. Each stat shown is a line of its own.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?fps:Bool, ?frameTime:Bool, ?drawCalls:Bool, ?triangles:Bool, ?stateChanges:Bool, ?gpuTextures:Bool, ?gpuBuffers:Bool, ?targetFps:Int, ?onTargetColor:Color, ?belowTargetColor:Color, ?farBelowTargetColor:Color, ?font:Null<Font>, ?fontSize:Int, ?spacing:Float, ?padding:Int, ?backgroundColor:Color}
```

```haxe
var fps:Bool = true
var frameTime:Bool = true
var drawCalls:Bool = true
var triangles:Bool = false
var stateChanges:Bool = false
var gpuTextures:Bool = false
var gpuBuffers:Bool = false
var targetFps:Int = 0
var onTargetColor:Color = GREEN
var belowTargetColor:Color = YELLOW
var farBelowTargetColor:Color = RED
var font:Null<Font> = null
var fontSize:Null<Int> = null
var spacing:Float = 1
var padding:Int = 4
var backgroundColor:Color = BLANK
```

- `fps`: Whether it shows the frames a second. On by default.
- `frameTime`: Whether it shows the frame time's mean and its slowest 5% (p95) over the last half second, in milliseconds. On by default.
- `drawCalls`: Whether it shows the last frame's draw calls: how many draws it sent the GPU. On by default.
- `triangles`: Whether it shows the last frame's triangles drawn. Off by default.
- `stateChanges`: Whether it shows the last frame's state changes: how often its draws switched shader, render state or textures. Off by default.
- `gpuTextures`: Whether it shows the megabytes of textures helix-raylib holds on the GPU: textures, cubemaps, render textures and the skinning palettes, as their levels' bytes, without the GPU's own padding. Off by default.
- `gpuBuffers`: Whether it shows the megabytes of buffers helix-raylib holds on the GPU: meshes' vertices and indices, the frame's batch and its quad indices, a frame's instances. Off by default.
- `targetFps`: The frame rate the stats are judged against, frames a second: 0 by default, for the target SetTargetFPS set, or the monitor's refresh rate when none is set.
- `onTargetColor`: The text's color when the frame rate is at or above the target. GREEN by default.
- `belowTargetColor`: The text's color when the frame rate is below the target. YELLOW by default.
- `farBelowTargetColor`: The text's color when the frame rate is below half the target. RED by default.
- `font`: The font, or null by default for raylib's default font.
- `fontSize`: The text's height, in pixels, or null by default to scale it to the window: a 36th of the screen's height (20 at 720 lines, as DrawFPS draws), so the stats read alike at any window size. A size given is used as it is; one under 1 is refused.
- `spacing`: The space between letters, in pixels at the font's size, as DrawTextEx's. 1 by default.
- `padding`: The space around the text inside its background, in pixels. 4 by default.
- `backgroundColor`: The background's color behind the text and its padding. BLANK by default, for none.

## GlyphInfo

*class* in [`engines/raylib/src/helix/raylib/GlyphInfo.hx`](../../engines/raylib/src/helix/raylib/GlyphInfo.hx), `import helix.raylib.GlyphInfo;`

raylib's `GlyphInfo` (raylib.h): not in helix-raylib yet; its fields are raylib's. GlyphInfo, font characters glyphs info.

```haxe
function new()
var value:Int
var offsetX:Int
var offsetY:Int
var advanceX:Int
var image:Image
```

- `new`: Creates one, its fields zero, empty or null.
- `value`: Character value (Unicode).
- `offsetX`: Character offset X when drawing.
- `offsetY`: Character offset Y when drawing.
- `advanceX`: Character advance position X.
- `image`: Character image data.

## GuiSkin

*class* in [`engines/raylib/src/helix/raylib/GuiSkin.hx`](../../engines/raylib/src/helix/raylib/GuiSkin.hx), `import helix.raylib.GuiSkin;`

Represents a skin: how a part of raygui's controls is drawn from a texture, a nine-patch for each state, in place of its style's flat colors. Made by `GuiSkinFromTexture` and set by `GuiSetSkin` (`helix.raylib.extras.GuiSkins`).

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{texture:Texture2D, normal:NPatchInfo, focused:Null<NPatchInfo>, pressed:Null<NPatchInfo>, disabled:Null<NPatchInfo>, tint:Color}
```

```haxe
var texture:Texture2D
var normal:NPatchInfo
var focused:Null<NPatchInfo>
var pressed:Null<NPatchInfo>
var disabled:Null<NPatchInfo>
var tint:Color
```

- `texture`: Gets or sets the texture the patches are cut from, often one sheet for every skin.
- `normal`: Gets or sets the patch drawn in `STATE_NORMAL`.
- `focused`: Gets or sets the patch drawn in `STATE_FOCUSED`, with the pointer over the control, or null to draw `normal`.
- `pressed`: Gets or sets the patch drawn in `STATE_PRESSED`, or null to draw `focused`, or `normal` when that is null too.
- `disabled`: Gets or sets the patch drawn in `STATE_DISABLED`, or null to draw `normal`.
- `tint`: Gets or sets the color the patches are multiplied by, `WHITE` to draw them as they are.

## GuiStyleProp

*class* in [`engines/raylib/src/helix/raylib/GuiStyleProp.hx`](../../engines/raylib/src/helix/raylib/GuiStyleProp.hx), `import helix.raylib.GuiStyleProp;`

One property of raygui's style, as raygui's `GuiStyleProp` holds it for a style written as code: the control, the property and its value, as `GuiSetStyle` takes them.

```haxe
function new(?controlId:Int = 0, ?propertyId:Int = 0, ?propertyValue:Int = 0)
var controlId:Int
var propertyId:Int
var propertyValue:Int
```

- `new`: Makes one.
  - `controlId`: The control.
  - `propertyId`: The property.
  - `propertyValue`: Its value.
- `controlId`: The control (`DEFAULT`, `BUTTON` and the rest).
- `propertyId`: The property (`BORDER_COLOR_NORMAL`, `TEXT_SIZE` and the rest).
- `propertyValue`: Its value: a color as 0xRRGGBBAA, a size in pixels, or one of the property's values.

## Image

*class* in [`engines/raylib/src/helix/raylib/Image.hx`](../../engines/raylib/src/helix/raylib/Image.hx), `import helix.raylib.Image;`

Represents raylib's `Image`: pixels in memory, in one of raylib's pixel formats.

The bytes are laid out as raylib's are: rows top first, each pixel `GetPixelDataSize(1, 1, format)` bytes; 16-bit values (the packed formats, the half floats) and 32-bit floats little-endian. An image with mipmaps holds its smaller levels after it, each half the size of the last. The `Image*` functions change an image in place, as raylib's do through its pointer: its fields are replaced.

```haxe
function new(?data:haxe.io.Bytes, ?width:Int = 0, ?height:Int = 0, ?mipmaps:Int = 0, ?format:Int = 0)
var data:Null<haxe.io.Bytes>
var width:Int
var height:Int
var mipmaps:Int
var format:Int
```

- `new`: Creates an image's record. Its fields are zero and its data null unless given, as raylib's `Image image = { 0 }` is; images are made by the `GenImage*` functions and loaded by `LoadImageAsync`.
  - `data`: Optional. The pixels.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `mipmaps`: The number of mipmap levels.
  - `format`: The pixel format (`PIXELFORMAT_*`).
- `data`: Gets or sets the pixels, or null for none.
- `width`: Gets or sets the width, in pixels.
- `height`: Gets or sets the height, in pixels.
- `mipmaps`: Gets or sets the number of mipmap levels, 1 for the image alone.
- `format`: Gets or sets the pixel format (`PIXELFORMAT_*`).

## Light

*class* in [`engines/raylib/src/helix/raylib/Light.hx`](../../engines/raylib/src/helix/raylib/Light.hx), `import helix.raylib.Light;`

Represents rlights' `Light` (raylib's examples' `rlights.h`): a light of a lit shader, made by `CreateLight` and set again by `UpdateLightValues` (`helix.raylib.extras.Lights`) after a field changes.

```haxe
function new()
var type:Int
var enabled:Bool
var position:Vector3
var target:Vector3
var color:Color
var attenuation:Float
var enabledLoc:Int
var typeLoc:Int
var positionLoc:Int
var targetLoc:Int
var colorLoc:Int
var attenuationLoc:Int
```

- `new`: Creates a light that is off, every field 0, as C's `Light light = { 0 }`. Lights are made by `CreateLight`.
- `type`: Gets or sets its type: `LIGHT_DIRECTIONAL` or `LIGHT_POINT`.
- `enabled`: Gets or sets a value indicating whether it shines.
- `position`: Gets or sets where it is.
- `target`: Gets or sets where it points, for a directional light.
- `color`: Gets or sets its color.
- `attenuation`: Gets or sets its attenuation, which rlights keeps and its shader doesn't read.
- `enabledLoc`: Gets or sets the location of its `enabled` in its shader.
- `typeLoc`: Gets or sets the location of its `type`.
- `positionLoc`: Gets or sets the location of its `position`.
- `targetLoc`: Gets or sets the location of its `target`.
- `colorLoc`: Gets or sets the location of its `color`.
- `attenuationLoc`: Gets or sets the location of its `attenuation`, which rlights never finds.

## Material

*class* in [`engines/raylib/src/helix/raylib/Material.hx`](../../engines/raylib/src/helix/raylib/Material.hx), `import helix.raylib.Material;`

Represents raylib's `Material`: a shader and its maps (`MATERIAL_MAP_*`); the diffuse map's texture and color are what a draw shows.

It is counted (docs/DECISIONS.md 25): the program holds it from `LoadMaterialDefault` until `UnloadMaterial`, and each model whose `materials` holds it holds it too. When the last lets go, its maps let go of their textures and it of its shader, each freed when nothing else holds it.

```haxe
function new(shader:Shader, maps:Array<MaterialMap>, ?params:Array<Float>)
var shader(default, set):Shader
var maps:Array<MaterialMap>
var params:Array<Float>
```

- `new`: Creates a material. Materials are made by `Raylib.LoadMaterialDefault` and `extras.Models.LoadModelAsync`.
  - `shader`: The shader.
  - `maps`: The maps.
  - `params`: The values.
- `shader`: Gets or sets the shader it draws with. Assigning keeps a copy of the record, counted as one of the shader's holders, and lets go of the shader it replaces; the material lets go of it when it is freed. The default shader is never freed.
- `maps`: Gets its maps, `MAX_MATERIAL_MAPS` of them, by `MATERIAL_MAP_*`.
- `params`: Gets four values for a shader's own use.

## MaterialMap

*class* in [`engines/raylib/src/helix/raylib/MaterialMap.hx`](../../engines/raylib/src/helix/raylib/MaterialMap.hx), `import helix.raylib.MaterialMap;`

Represents raylib's `MaterialMap`: one of a material's maps (`MATERIAL_MAP_*`), a texture with a color and a value.

The map holds a count on its texture (docs/DECISIONS.md 25): assigning one keeps a copy of its record, retains it and releases the texture it replaces, so a texture the program unloads after giving it to a map lives until the map lets go of it.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?texture:Texture2D, ?color:Color, ?value:Float}
```

```haxe
var texture(default, set):Texture2D
var color:Color
var value:Float
```

- `texture`: Gets or sets the texture; id 0 for none, drawn as white. Assigning keeps a copy of the record, counted as one of the texture's holders, and releases the texture it replaces; the material releases it when it is freed.
- `color`: Gets or sets the color.
- `value`: Gets or sets the value.

## Matrix

*class* in [`engines/raylib/src/helix/raylib/Matrix.hx`](../../engines/raylib/src/helix/raylib/Matrix.hx), `import helix.raylib.Matrix;`

Represents raylib's `Matrix`: 4 x 4, named by rows (`m0, m4, m8, m12` the first), stored and sent to shaders by columns (`m0` to `m3` the first), as raylib's is.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?m0:Float, ?m4:Float, ?m8:Float, ?m12:Float, ?m1:Float, ?m5:Float, ?m9:Float, ?m13:Float, ?m2:Float, ?m6:Float, ?m10:Float, ?m14:Float, ?m3:Float, ?m7:Float, ?m11:Float, ?m15:Float}
```

```haxe
var m0:Float
var m4:Float
var m8:Float
var m12:Float
var m1:Float
var m5:Float
var m9:Float
var m13:Float
var m2:Float
var m6:Float
var m10:Float
var m14:Float
var m3:Float
var m7:Float
var m11:Float
var m15:Float
```

- `m0`: Gets or sets row 1, column 1.
- `m4`: Gets or sets row 1, column 2.
- `m8`: Gets or sets row 1, column 3.
- `m12`: Gets or sets row 1, column 4.
- `m1`: Gets or sets row 2, column 1.
- `m5`: Gets or sets row 2, column 2.
- `m9`: Gets or sets row 2, column 3.
- `m13`: Gets or sets row 2, column 4.
- `m2`: Gets or sets row 3, column 1.
- `m6`: Gets or sets row 3, column 2.
- `m10`: Gets or sets row 3, column 3.
- `m14`: Gets or sets row 3, column 4.
- `m3`: Gets or sets row 4, column 1.
- `m7`: Gets or sets row 4, column 2.
- `m11`: Gets or sets row 4, column 3.
- `m15`: Gets or sets row 4, column 4.

## Mesh

*class* in [`engines/raylib/src/helix/raylib/Mesh.hx`](../../engines/raylib/src/helix/raylib/Mesh.hx), `import helix.raylib.Mesh;`

Represents raylib's `Mesh`: vertices, and the indices of its triangles when it has them. `Raylib.UploadMesh` sends them to the GPU; `extras.Models.LoadModelAsync` and the `GenMesh*` functions do it themselves.

It is counted (docs/DECISIONS.md 25): the program holds it from `new` or a `GenMesh*` function until `UnloadMesh`, and each model whose `meshes` holds it holds it too. When the last lets go, its GPU buffers are freed.

```haxe
function new()
var vertexCount:Int
var triangleCount:Int
var vertices:Null<Array<Float>>
var texcoords:Null<Array<Float>>
var texcoords2:Null<Array<Float>>
var normals:Null<Array<Float>>
var tangents:Null<Array<Float>>
var colors:Null<Array<Int>>
var indices:Null<Array<Int>>
var animVertices(get, default):Null<Array<Float>>
var animNormals(get, default):Null<Array<Float>>
var boneIds:Null<Array<Int>>
var boneWeights:Null<Array<Float>>
var boneMatrices:Null<Array<Matrix>>
var boneCount:Int
```

- `new`: Creates an empty mesh.
- `vertexCount`: Gets or sets the number of vertices.
- `triangleCount`: Gets or sets the number of triangles.
- `vertices`: Gets or sets the positions, x, y and z a vertex.
- `texcoords`: Gets or sets the texture coordinates, u and v a vertex, or null for none.
- `texcoords2`: Gets or sets the second texture coordinates, u and v a vertex, or null for none.
- `normals`: Gets or sets the normals, x, y and z a vertex, or null for none.
- `tangents`: Gets or sets the tangents, x, y, z and w a vertex (w is 1 or -1, the way the bitangent turns), or null for none. `GenMeshTangents` makes them.
- `colors`: Gets or sets the colors, r, g, b and a a vertex, 0 to 255, or null for white.
- `indices`: Gets or sets the indices, three a triangle, or null for vertices taken three at a time.
- `animVertices`: Gets or sets the positions `UpdateModelAnimation` last moved its vertices to, x, y and z a vertex, or null until it has.
  They are worked out on the CPU when first read after a call that moved them, from the pose that call left, as raylib's `UpdateModelAnimation` moves them; a draw doesn't read them, but for a mesh drawn through the CPU path (see `UpdateModelAnimation`), or in wire or point mode.
- `animNormals`: Gets or sets the normals `UpdateModelAnimation` last turned its vertices' to, or null until it has (or for a mesh without normals). Each is moved by its bones' matrices inverted and transposed, and not normalized, as raylib's; like `animVertices`, they are worked out when first read.
- `boneIds`: Gets or sets the bones each vertex follows, four a vertex, as indices into its model's `bones` (0 to 255), or null for none. A shader reads them as the attribute `vertexBoneIds` (raylib 5.5's name) or `vertexBoneIndices` (6.2's), floats.
- `boneWeights`: Gets or sets how much each of a vertex's four bones moves it, or null for none: the attribute `vertexBoneWeights`.
- `boneMatrices`: Gets or sets the bones' matrices, by bone, each taking a vertex from where the skin was bound to where the bone is now: `UpdateModelAnimationBones` sets them, and a shader declaring `uniform mat4 boneMatrices[N]` is given them as the mesh is drawn. Shared by a model's meshes; null for a mesh without bones.
- `boneCount`: Gets or sets the number of bones, its model's.

## Model

*class* in [`engines/raylib/src/helix/raylib/Model.hx`](../../engines/raylib/src/helix/raylib/Model.hx), `import helix.raylib.Model;`

Represents raylib's `Model`: meshes, materials, which material each mesh draws with, and a transform.

A model holds a count on each of its meshes and materials (docs/DECISIONS.md 25): putting one in `meshes` or `materials` retains it, replacing or `UnloadModel` releases it, and what no one holds any more is freed.

```haxe
function new(meshes:Array<Mesh>, materials:Array<Material>, meshMaterial:Array<Int>)
var transform:Matrix
var meshCount:Int
var materialCount:Int
var meshes(default, set):ModelMeshes
var materials(default, set):ModelMaterials
var meshMaterial:Array<Int>
var boneCount:Int
var bones:Null<Array<BoneInfo>>
var bindPose:Null<Array<Transform>>
```

- `new`: Creates a model, holding its meshes and materials. Models are made by `extras.Models.LoadModelAsync` and `Raylib.LoadModelFromMesh`.
  - `meshes`: The meshes.
  - `materials`: The materials.
  - `meshMaterial`: Each mesh's material.
- `transform`: Gets or sets the transform applied before `DrawModel`'s position, rotation and scale.
- `meshCount`: Gets the number of meshes, set when `meshes` is.
- `materialCount`: Gets the number of materials, set when `materials` is.
- `meshes`: Gets or sets the meshes, each held by the model. Setting copies the array, retains its meshes, releases the ones it replaces and sets `meshCount`.
- `materials`: Gets or sets the materials, each held by the model. Setting copies the array, retains its materials, releases the ones it replaces and sets `materialCount`.
- `meshMaterial`: Gets the material of each mesh, by its index in `materials`.
- `boneCount`: Gets the number of bones: the joints of the file's first skin, 0 for a model without one.
- `bones`: Gets the bones, the file's first skin's joints in its order, each parent the nearest joint above it; null without a skin.
- `bindPose`: Gets each bone's transform in the model as the skin was bound to it: its inverse bind matrix inverted, or, for a file that gives none, its node's at rest; null without a skin.

## ModelAnimation

*class* in [`engines/raylib/src/helix/raylib/ModelAnimation.hx`](../../engines/raylib/src/helix/raylib/ModelAnimation.hx), `import helix.raylib.ModelAnimation;`

Represents raylib's `ModelAnimation`: a skeleton's poses, frame by frame. `extras.Models.LoadModelAnimationsAsync` makes them, 60 frames a second; `Raylib.UpdateModelAnimation` poses a model by one.

```haxe
function new()
var boneCount:Int
var frameCount:Int
var bones:Null<Array<BoneInfo>>
var framePoses:Null<Array<Array<Transform>>>
var name:String
```

- `new`: Creates an animation of no frames.
- `boneCount`: Gets or sets the number of bones, which a model it moves has too (`Raylib.IsModelAnimationValid`).
- `frameCount`: Gets or sets the number of frames.
- `bones`: Gets or sets the bones, as the model's are.
- `framePoses`: Gets or sets each frame's pose: for each bone, its transform in the model, not its parent's (a parent's already in it).
- `name`: Gets or sets the name: the file's, cut to 31 bytes as raylib's holds it, or empty.

## ModelMaterials

*abstract* in [`engines/raylib/src/helix/raylib/ModelMaterials.hx`](../../engines/raylib/src/helix/raylib/ModelMaterials.hx), `import helix.raylib.ModelMaterials;`

Represents a model's materials, raylib's `model.materials`: read and written by index (`model.materials[0] = material`), iterated, and with a `length`.

The model holds a count on each material here (docs/DECISIONS.md 25): writing one retains the new material and releases the one it replaces, and `UnloadModel` releases them all. An array assigned to `Model.materials` is copied, so changing it afterwards changes nothing here.

## ModelMeshes

*abstract* in [`engines/raylib/src/helix/raylib/ModelMeshes.hx`](../../engines/raylib/src/helix/raylib/ModelMeshes.hx), `import helix.raylib.ModelMeshes;`

Represents a model's meshes, raylib's `model.meshes`: read and written by index (`model.meshes[0] = mesh`), iterated, and with a `length`.

The model holds a count on each mesh here (docs/DECISIONS.md 25): writing one retains the new mesh and releases the one it replaces, and `UnloadModel` releases them all. An array assigned to `Model.meshes` is copied, so changing it afterwards changes nothing here.

## Music

*class* in [`engines/raylib/src/helix/raylib/Music.hx`](../../engines/raylib/src/helix/raylib/Music.hx), `import helix.raylib.Music;`

Represents raylib's `Music`: a sound played as it is read, never held whole, through helix-services' `Audio.stream`.

```haxe
var looping:Bool
var frameCount(get, never):Int
```

- `looping`: Gets or sets whether it starts again from its beginning when it ends; true until set, as raylib's.
- `frameCount`: Gets the number of frames, at 44100 a second; 0 until its length is known (`GetMusicTimeLength`).

## NPatchInfo

*class* in [`engines/raylib/src/helix/raylib/NPatchInfo.hx`](../../engines/raylib/src/helix/raylib/NPatchInfo.hx), `import helix.raylib.NPatchInfo;`

Represents raylib's `NPatchInfo`: how `DrawTextureNPatch` cuts a texture into a nine-patch or a three-patch.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?source:Rectangle, ?left:Int, ?top:Int, ?right:Int, ?bottom:Int, ?layout:Int}
```

```haxe
var source:Rectangle
var left:Int
var top:Int
var right:Int
var bottom:Int
var layout:Int
```

- `source`: Gets or sets the patch's rectangle on the texture, in texels.
- `left`: Gets or sets the left border's width, in texels.
- `top`: Gets or sets the top border's height, in texels.
- `right`: Gets or sets the right border's width, in texels.
- `bottom`: Gets or sets the bottom border's height, in texels.
- `layout`: Gets or sets the layout (`NPATCH_*`): nine patches, or three across or down.

## Quaternion

*typedef* in [`engines/raylib/src/helix/raylib/Quaternion.hx`](../../engines/raylib/src/helix/raylib/Quaternion.hx), `import helix.raylib.Quaternion;`

raylib's `Quaternion`, the same as `Vector4`.

An alias of `Vector4`.

## Ray

*class* in [`engines/raylib/src/helix/raylib/Ray.hx`](../../engines/raylib/src/helix/raylib/Ray.hx), `import helix.raylib.Ray;`

Represents raylib's `Ray`: an origin and a direction.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?position:Vector3, ?direction:Vector3}
```

```haxe
var position:Vector3
var direction:Vector3
```

- `position`: Gets or sets the origin.
- `direction`: Gets or sets the direction, of length 1.

## RayCollision

*class* in [`engines/raylib/src/helix/raylib/RayCollision.hx`](../../engines/raylib/src/helix/raylib/RayCollision.hx), `import helix.raylib.RayCollision;`

Represents raylib's `RayCollision`: whether and where a ray hit.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?hit:Bool, ?distance:Float, ?point:Vector3, ?normal:Vector3}
```

```haxe
var hit:Bool
var distance:Float
var point:Vector3
var normal:Vector3
```

- `hit`: Gets or sets whether it hit.
- `distance`: Gets or sets the distance to the hit.
- `point`: Gets or sets the point hit.
- `normal`: Gets or sets the surface's normal there.

## Raygui

*class* in [`engines/raylib/src/helix/raylib/Raygui.hx`](../../engines/raylib/src/helix/raylib/Raygui.hx), `import helix.raylib.Raygui;`

Provides raygui's API, raylib's immediate-mode GUI, as raylib 5.5's `raygui.h` (raygui 4.5-dev) names it: its controls (`GuiButton`, `GuiSlider`, `GuiTextBox`, `GuiListView`, `GuiColorPicker` and the rest), drawn and read each frame between `BeginDrawing` and `EndDrawing`, its style (`GuiSetStyle`, `GuiGetStyle`, `GuiLoadStyleDefault`), font, state, alpha, tooltips and icons. As in raylib, where raygui is a header of its own, it is apart from `Raylib`, so a program that uses it imports it too:

```haxe
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
```

A value a control changes is passed in a one-element array, as raygui takes a pointer: `GuiCheckBox(bounds, "On", checked)` with `var checked = [false];`, `GuiSlider(bounds, null, null, value, 0, 100)` with `var value = [50.];`, `GuiTextBox(bounds, text, 64, editing)` with `var text = ["name"];`. A struct a control changes (`Color`, `Vector2`, `Rectangle`, `Vector3`) is changed in place. A style file loads with `GuiLoadStyleAsync` and an icon file with `GuiLoadIconsAsync`, in `helix.raylib.extras.Gui`.

### Gui control state (GuiState)

```haxe
static inline var STATE_NORMAL:Int
static inline var STATE_FOCUSED:Int
static inline var STATE_PRESSED:Int
static inline var STATE_DISABLED:Int
```

- `STATE_NORMAL`: Gui control state: `STATE_NORMAL`.
- `STATE_FOCUSED`: Gui control state: `STATE_FOCUSED`.
- `STATE_PRESSED`: Gui control state: `STATE_PRESSED`.
- `STATE_DISABLED`: Gui control state: `STATE_DISABLED`.

### Gui control text alignment (GuiTextAlignment)

```haxe
static inline var TEXT_ALIGN_LEFT:Int
static inline var TEXT_ALIGN_CENTER:Int
static inline var TEXT_ALIGN_RIGHT:Int
```

- `TEXT_ALIGN_LEFT`: Gui control text alignment: `TEXT_ALIGN_LEFT`.
- `TEXT_ALIGN_CENTER`: Gui control text alignment: `TEXT_ALIGN_CENTER`.
- `TEXT_ALIGN_RIGHT`: Gui control text alignment: `TEXT_ALIGN_RIGHT`.

### Gui control text alignment vertical (GuiTextAlignmentVertical)

```haxe
static inline var TEXT_ALIGN_TOP:Int
static inline var TEXT_ALIGN_MIDDLE:Int
static inline var TEXT_ALIGN_BOTTOM:Int
```

- `TEXT_ALIGN_TOP`: Gui control text alignment vertical: `TEXT_ALIGN_TOP`.
- `TEXT_ALIGN_MIDDLE`: Gui control text alignment vertical: `TEXT_ALIGN_MIDDLE`.
- `TEXT_ALIGN_BOTTOM`: Gui control text alignment vertical: `TEXT_ALIGN_BOTTOM`.

### Gui control text wrap mode (GuiTextWrapMode)

```haxe
static inline var TEXT_WRAP_NONE:Int
static inline var TEXT_WRAP_CHAR:Int
static inline var TEXT_WRAP_WORD:Int
```

- `TEXT_WRAP_NONE`: Gui control text wrap mode: `TEXT_WRAP_NONE`.
- `TEXT_WRAP_CHAR`: Gui control text wrap mode: `TEXT_WRAP_CHAR`.
- `TEXT_WRAP_WORD`: Gui control text wrap mode: `TEXT_WRAP_WORD`.

### Gui controls (GuiControl)

```haxe
static inline var DEFAULT:Int
static inline var LABEL:Int
static inline var BUTTON:Int
static inline var TOGGLE:Int
static inline var SLIDER:Int
static inline var PROGRESSBAR:Int
static inline var CHECKBOX:Int
static inline var COMBOBOX:Int
static inline var DROPDOWNBOX:Int
static inline var TEXTBOX:Int
static inline var VALUEBOX:Int
static inline var SPINNER:Int
static inline var LISTVIEW:Int
static inline var COLORPICKER:Int
static inline var SCROLLBAR:Int
static inline var STATUSBAR:Int
```

- `DEFAULT`: Gui controls: `DEFAULT`.
- `LABEL`: Used also for: LABELBUTTON.
- `BUTTON`: Gui controls: `BUTTON`.
- `TOGGLE`: Used also for: TOGGLEGROUP.
- `SLIDER`: Used also for: SLIDERBAR, TOGGLESLIDER.
- `PROGRESSBAR`: Gui controls: `PROGRESSBAR`.
- `CHECKBOX`: Gui controls: `CHECKBOX`.
- `COMBOBOX`: Gui controls: `COMBOBOX`.
- `DROPDOWNBOX`: Gui controls: `DROPDOWNBOX`.
- `TEXTBOX`: Used also for: TEXTBOXMULTI.
- `VALUEBOX`: Gui controls: `VALUEBOX`.
- `SPINNER`: Uses: BUTTON, VALUEBOX.
- `LISTVIEW`: Gui controls: `LISTVIEW`.
- `COLORPICKER`: Gui controls: `COLORPICKER`.
- `SCROLLBAR`: Gui controls: `SCROLLBAR`.
- `STATUSBAR`: Gui controls: `STATUSBAR`.

### Gui base properties for every control (GuiControlProperty)

```haxe
static inline var BORDER_COLOR_NORMAL:Int
static inline var BASE_COLOR_NORMAL:Int
static inline var TEXT_COLOR_NORMAL:Int
static inline var BORDER_COLOR_FOCUSED:Int
static inline var BASE_COLOR_FOCUSED:Int
static inline var TEXT_COLOR_FOCUSED:Int
static inline var BORDER_COLOR_PRESSED:Int
static inline var BASE_COLOR_PRESSED:Int
static inline var TEXT_COLOR_PRESSED:Int
static inline var BORDER_COLOR_DISABLED:Int
static inline var BASE_COLOR_DISABLED:Int
static inline var TEXT_COLOR_DISABLED:Int
static inline var BORDER_WIDTH:Int
static inline var TEXT_PADDING:Int
static inline var TEXT_ALIGNMENT:Int
```

- `BORDER_COLOR_NORMAL`: Control border color in STATE_NORMAL.
- `BASE_COLOR_NORMAL`: Control base color in STATE_NORMAL.
- `TEXT_COLOR_NORMAL`: Control text color in STATE_NORMAL.
- `BORDER_COLOR_FOCUSED`: Control border color in STATE_FOCUSED.
- `BASE_COLOR_FOCUSED`: Control base color in STATE_FOCUSED.
- `TEXT_COLOR_FOCUSED`: Control text color in STATE_FOCUSED.
- `BORDER_COLOR_PRESSED`: Control border color in STATE_PRESSED.
- `BASE_COLOR_PRESSED`: Control base color in STATE_PRESSED.
- `TEXT_COLOR_PRESSED`: Control text color in STATE_PRESSED.
- `BORDER_COLOR_DISABLED`: Control border color in STATE_DISABLED.
- `BASE_COLOR_DISABLED`: Control base color in STATE_DISABLED.
- `TEXT_COLOR_DISABLED`: Control text color in STATE_DISABLED.
- `BORDER_WIDTH`: Control border size, 0 for no border.
- `TEXT_PADDING`: Control text padding, not considering border.
- `TEXT_ALIGNMENT`: Control text horizontal alignment inside control text bound (after border and padding).

### DEFAULT extended properties (GuiDefaultProperty)

```haxe
static inline var TEXT_SIZE:Int
static inline var TEXT_SPACING:Int
static inline var LINE_COLOR:Int
static inline var BACKGROUND_COLOR:Int
static inline var TEXT_LINE_SPACING:Int
static inline var TEXT_ALIGNMENT_VERTICAL:Int
static inline var TEXT_WRAP_MODE:Int
```

- `TEXT_SIZE`: Text size (glyphs max height).
- `TEXT_SPACING`: Text spacing between glyphs.
- `LINE_COLOR`: Line control color.
- `BACKGROUND_COLOR`: Background color.
- `TEXT_LINE_SPACING`: Text spacing between lines.
- `TEXT_ALIGNMENT_VERTICAL`: Text vertical alignment inside text bounds (after border and padding).
- `TEXT_WRAP_MODE`: Text wrap-mode inside text bounds.

### Toggle/ToggleGroup (GuiToggleProperty)

```haxe
static inline var GROUP_PADDING:Int
```

- `GROUP_PADDING`: ToggleGroup separation between toggles.

### Slider/SliderBar (GuiSliderProperty)

```haxe
static inline var SLIDER_WIDTH:Int
static inline var SLIDER_PADDING:Int
```

- `SLIDER_WIDTH`: Slider size of internal bar.
- `SLIDER_PADDING`: Slider/SliderBar internal bar padding.

### ProgressBar (GuiProgressBarProperty)

```haxe
static inline var PROGRESS_PADDING:Int
```

- `PROGRESS_PADDING`: ProgressBar internal padding.

### ScrollBar (GuiScrollBarProperty)

```haxe
static inline var ARROWS_SIZE:Int
static inline var ARROWS_VISIBLE:Int
static inline var SCROLL_SLIDER_PADDING:Int
static inline var SCROLL_SLIDER_SIZE:Int
static inline var SCROLL_PADDING:Int
static inline var SCROLL_SPEED:Int
```

- `ARROWS_SIZE`: ScrollBar arrows size.
- `ARROWS_VISIBLE`: ScrollBar arrows visible.
- `SCROLL_SLIDER_PADDING`: ScrollBar slider internal padding.
- `SCROLL_SLIDER_SIZE`: ScrollBar slider size.
- `SCROLL_PADDING`: ScrollBar scroll padding from arrows.
- `SCROLL_SPEED`: ScrollBar scrolling speed.

### CheckBox (GuiCheckBoxProperty)

```haxe
static inline var CHECK_PADDING:Int
```

- `CHECK_PADDING`: CheckBox internal check padding.

### ComboBox (GuiComboBoxProperty)

```haxe
static inline var COMBO_BUTTON_WIDTH:Int
static inline var COMBO_BUTTON_SPACING:Int
```

- `COMBO_BUTTON_WIDTH`: ComboBox right button width.
- `COMBO_BUTTON_SPACING`: ComboBox button separation.

### DropdownBox (GuiDropdownBoxProperty)

```haxe
static inline var ARROW_PADDING:Int
static inline var DROPDOWN_ITEMS_SPACING:Int
static inline var DROPDOWN_ARROW_HIDDEN:Int
static inline var DROPDOWN_ROLL_UP:Int
```

- `ARROW_PADDING`: DropdownBox arrow separation from border and items.
- `DROPDOWN_ITEMS_SPACING`: DropdownBox items separation.
- `DROPDOWN_ARROW_HIDDEN`: DropdownBox arrow hidden.
- `DROPDOWN_ROLL_UP`: DropdownBox roll up flag (default rolls down).

### TextBox/TextBoxMulti/ValueBox/Spinner (GuiTextBoxProperty)

```haxe
static inline var TEXT_READONLY:Int
```

- `TEXT_READONLY`: TextBox in read-only mode: 0-text editable, 1-text no-editable.

### Spinner (GuiSpinnerProperty)

```haxe
static inline var SPIN_BUTTON_WIDTH:Int
static inline var SPIN_BUTTON_SPACING:Int
```

- `SPIN_BUTTON_WIDTH`: Spinner left/right buttons width.
- `SPIN_BUTTON_SPACING`: Spinner buttons separation.

### ListView (GuiListViewProperty)

```haxe
static inline var LIST_ITEMS_HEIGHT:Int
static inline var LIST_ITEMS_SPACING:Int
static inline var SCROLLBAR_WIDTH:Int
static inline var SCROLLBAR_SIDE:Int
static inline var LIST_ITEMS_BORDER_WIDTH:Int
```

- `LIST_ITEMS_HEIGHT`: ListView items height.
- `LIST_ITEMS_SPACING`: ListView items separation.
- `SCROLLBAR_WIDTH`: ListView scrollbar size (usually width).
- `SCROLLBAR_SIDE`: ListView scrollbar side (0-SCROLLBAR_LEFT_SIDE, 1-SCROLLBAR_RIGHT_SIDE).
- `LIST_ITEMS_BORDER_WIDTH`: ListView items border width.

### ColorPicker (GuiColorPickerProperty)

```haxe
static inline var COLOR_SELECTOR_SIZE:Int
static inline var HUEBAR_WIDTH:Int
static inline var HUEBAR_PADDING:Int
static inline var HUEBAR_SELECTOR_HEIGHT:Int
static inline var HUEBAR_SELECTOR_OVERFLOW:Int
```

- `COLOR_SELECTOR_SIZE`: ColorPicker: `COLOR_SELECTOR_SIZE`.
- `HUEBAR_WIDTH`: ColorPicker right hue bar width.
- `HUEBAR_PADDING`: ColorPicker right hue bar separation from panel.
- `HUEBAR_SELECTOR_HEIGHT`: ColorPicker right hue bar selector height.
- `HUEBAR_SELECTOR_OVERFLOW`: ColorPicker right hue bar selector overflow.

###  (GuiIconName)

```haxe
static inline var ICON_NONE:Int
static inline var ICON_FOLDER_FILE_OPEN:Int
static inline var ICON_FILE_SAVE_CLASSIC:Int
static inline var ICON_FOLDER_OPEN:Int
static inline var ICON_FOLDER_SAVE:Int
static inline var ICON_FILE_OPEN:Int
static inline var ICON_FILE_SAVE:Int
static inline var ICON_FILE_EXPORT:Int
static inline var ICON_FILE_ADD:Int
static inline var ICON_FILE_DELETE:Int
static inline var ICON_FILETYPE_TEXT:Int
static inline var ICON_FILETYPE_AUDIO:Int
static inline var ICON_FILETYPE_IMAGE:Int
static inline var ICON_FILETYPE_PLAY:Int
static inline var ICON_FILETYPE_VIDEO:Int
static inline var ICON_FILETYPE_INFO:Int
static inline var ICON_FILE_COPY:Int
static inline var ICON_FILE_CUT:Int
static inline var ICON_FILE_PASTE:Int
static inline var ICON_CURSOR_HAND:Int
static inline var ICON_CURSOR_POINTER:Int
static inline var ICON_CURSOR_CLASSIC:Int
static inline var ICON_PENCIL:Int
static inline var ICON_PENCIL_BIG:Int
static inline var ICON_BRUSH_CLASSIC:Int
static inline var ICON_BRUSH_PAINTER:Int
static inline var ICON_WATER_DROP:Int
static inline var ICON_COLOR_PICKER:Int
static inline var ICON_RUBBER:Int
static inline var ICON_COLOR_BUCKET:Int
static inline var ICON_TEXT_T:Int
static inline var ICON_TEXT_A:Int
static inline var ICON_SCALE:Int
static inline var ICON_RESIZE:Int
static inline var ICON_FILTER_POINT:Int
static inline var ICON_FILTER_BILINEAR:Int
static inline var ICON_CROP:Int
static inline var ICON_CROP_ALPHA:Int
static inline var ICON_SQUARE_TOGGLE:Int
static inline var ICON_SYMMETRY:Int
static inline var ICON_SYMMETRY_HORIZONTAL:Int
static inline var ICON_SYMMETRY_VERTICAL:Int
static inline var ICON_LENS:Int
static inline var ICON_LENS_BIG:Int
static inline var ICON_EYE_ON:Int
static inline var ICON_EYE_OFF:Int
static inline var ICON_FILTER_TOP:Int
static inline var ICON_FILTER:Int
static inline var ICON_TARGET_POINT:Int
static inline var ICON_TARGET_SMALL:Int
static inline var ICON_TARGET_BIG:Int
static inline var ICON_TARGET_MOVE:Int
static inline var ICON_CURSOR_MOVE:Int
static inline var ICON_CURSOR_SCALE:Int
static inline var ICON_CURSOR_SCALE_RIGHT:Int
static inline var ICON_CURSOR_SCALE_LEFT:Int
static inline var ICON_UNDO:Int
static inline var ICON_REDO:Int
static inline var ICON_REREDO:Int
static inline var ICON_MUTATE:Int
static inline var ICON_ROTATE:Int
static inline var ICON_REPEAT:Int
static inline var ICON_SHUFFLE:Int
static inline var ICON_EMPTYBOX:Int
static inline var ICON_TARGET:Int
static inline var ICON_TARGET_SMALL_FILL:Int
static inline var ICON_TARGET_BIG_FILL:Int
static inline var ICON_TARGET_MOVE_FILL:Int
static inline var ICON_CURSOR_MOVE_FILL:Int
static inline var ICON_CURSOR_SCALE_FILL:Int
static inline var ICON_CURSOR_SCALE_RIGHT_FILL:Int
static inline var ICON_CURSOR_SCALE_LEFT_FILL:Int
static inline var ICON_UNDO_FILL:Int
static inline var ICON_REDO_FILL:Int
static inline var ICON_REREDO_FILL:Int
static inline var ICON_MUTATE_FILL:Int
static inline var ICON_ROTATE_FILL:Int
static inline var ICON_REPEAT_FILL:Int
static inline var ICON_SHUFFLE_FILL:Int
static inline var ICON_EMPTYBOX_SMALL:Int
static inline var ICON_BOX:Int
static inline var ICON_BOX_TOP:Int
static inline var ICON_BOX_TOP_RIGHT:Int
static inline var ICON_BOX_RIGHT:Int
static inline var ICON_BOX_BOTTOM_RIGHT:Int
static inline var ICON_BOX_BOTTOM:Int
static inline var ICON_BOX_BOTTOM_LEFT:Int
static inline var ICON_BOX_LEFT:Int
static inline var ICON_BOX_TOP_LEFT:Int
static inline var ICON_BOX_CENTER:Int
static inline var ICON_BOX_CIRCLE_MASK:Int
static inline var ICON_POT:Int
static inline var ICON_ALPHA_MULTIPLY:Int
static inline var ICON_ALPHA_CLEAR:Int
static inline var ICON_DITHERING:Int
static inline var ICON_MIPMAPS:Int
static inline var ICON_BOX_GRID:Int
static inline var ICON_GRID:Int
static inline var ICON_BOX_CORNERS_SMALL:Int
static inline var ICON_BOX_CORNERS_BIG:Int
static inline var ICON_FOUR_BOXES:Int
static inline var ICON_GRID_FILL:Int
static inline var ICON_BOX_MULTISIZE:Int
static inline var ICON_ZOOM_SMALL:Int
static inline var ICON_ZOOM_MEDIUM:Int
static inline var ICON_ZOOM_BIG:Int
static inline var ICON_ZOOM_ALL:Int
static inline var ICON_ZOOM_CENTER:Int
static inline var ICON_BOX_DOTS_SMALL:Int
static inline var ICON_BOX_DOTS_BIG:Int
static inline var ICON_BOX_CONCENTRIC:Int
static inline var ICON_BOX_GRID_BIG:Int
static inline var ICON_OK_TICK:Int
static inline var ICON_CROSS:Int
static inline var ICON_ARROW_LEFT:Int
static inline var ICON_ARROW_RIGHT:Int
static inline var ICON_ARROW_DOWN:Int
static inline var ICON_ARROW_UP:Int
static inline var ICON_ARROW_LEFT_FILL:Int
static inline var ICON_ARROW_RIGHT_FILL:Int
static inline var ICON_ARROW_DOWN_FILL:Int
static inline var ICON_ARROW_UP_FILL:Int
static inline var ICON_AUDIO:Int
static inline var ICON_FX:Int
static inline var ICON_WAVE:Int
static inline var ICON_WAVE_SINUS:Int
static inline var ICON_WAVE_SQUARE:Int
static inline var ICON_WAVE_TRIANGULAR:Int
static inline var ICON_CROSS_SMALL:Int
static inline var ICON_PLAYER_PREVIOUS:Int
static inline var ICON_PLAYER_PLAY_BACK:Int
static inline var ICON_PLAYER_PLAY:Int
static inline var ICON_PLAYER_PAUSE:Int
static inline var ICON_PLAYER_STOP:Int
static inline var ICON_PLAYER_NEXT:Int
static inline var ICON_PLAYER_RECORD:Int
static inline var ICON_MAGNET:Int
static inline var ICON_LOCK_CLOSE:Int
static inline var ICON_LOCK_OPEN:Int
static inline var ICON_CLOCK:Int
static inline var ICON_TOOLS:Int
static inline var ICON_GEAR:Int
static inline var ICON_GEAR_BIG:Int
static inline var ICON_BIN:Int
static inline var ICON_HAND_POINTER:Int
static inline var ICON_LASER:Int
static inline var ICON_COIN:Int
static inline var ICON_EXPLOSION:Int
static inline var ICON_1UP:Int
static inline var ICON_PLAYER:Int
static inline var ICON_PLAYER_JUMP:Int
static inline var ICON_KEY:Int
static inline var ICON_DEMON:Int
static inline var ICON_TEXT_POPUP:Int
static inline var ICON_GEAR_EX:Int
static inline var ICON_CRACK:Int
static inline var ICON_CRACK_POINTS:Int
static inline var ICON_STAR:Int
static inline var ICON_DOOR:Int
static inline var ICON_EXIT:Int
static inline var ICON_MODE_2D:Int
static inline var ICON_MODE_3D:Int
static inline var ICON_CUBE:Int
static inline var ICON_CUBE_FACE_TOP:Int
static inline var ICON_CUBE_FACE_LEFT:Int
static inline var ICON_CUBE_FACE_FRONT:Int
static inline var ICON_CUBE_FACE_BOTTOM:Int
static inline var ICON_CUBE_FACE_RIGHT:Int
static inline var ICON_CUBE_FACE_BACK:Int
static inline var ICON_CAMERA:Int
static inline var ICON_SPECIAL:Int
static inline var ICON_LINK_NET:Int
static inline var ICON_LINK_BOXES:Int
static inline var ICON_LINK_MULTI:Int
static inline var ICON_LINK:Int
static inline var ICON_LINK_BROKE:Int
static inline var ICON_TEXT_NOTES:Int
static inline var ICON_NOTEBOOK:Int
static inline var ICON_SUITCASE:Int
static inline var ICON_SUITCASE_ZIP:Int
static inline var ICON_MAILBOX:Int
static inline var ICON_MONITOR:Int
static inline var ICON_PRINTER:Int
static inline var ICON_PHOTO_CAMERA:Int
static inline var ICON_PHOTO_CAMERA_FLASH:Int
static inline var ICON_HOUSE:Int
static inline var ICON_HEART:Int
static inline var ICON_CORNER:Int
static inline var ICON_VERTICAL_BARS:Int
static inline var ICON_VERTICAL_BARS_FILL:Int
static inline var ICON_LIFE_BARS:Int
static inline var ICON_INFO:Int
static inline var ICON_CROSSLINE:Int
static inline var ICON_HELP:Int
static inline var ICON_FILETYPE_ALPHA:Int
static inline var ICON_FILETYPE_HOME:Int
static inline var ICON_LAYERS_VISIBLE:Int
static inline var ICON_LAYERS:Int
static inline var ICON_WINDOW:Int
static inline var ICON_HIDPI:Int
static inline var ICON_FILETYPE_BINARY:Int
static inline var ICON_HEX:Int
static inline var ICON_SHIELD:Int
static inline var ICON_FILE_NEW:Int
static inline var ICON_FOLDER_ADD:Int
static inline var ICON_ALARM:Int
static inline var ICON_CPU:Int
static inline var ICON_ROM:Int
static inline var ICON_STEP_OVER:Int
static inline var ICON_STEP_INTO:Int
static inline var ICON_STEP_OUT:Int
static inline var ICON_RESTART:Int
static inline var ICON_BREAKPOINT_ON:Int
static inline var ICON_BREAKPOINT_OFF:Int
static inline var ICON_BURGER_MENU:Int
static inline var ICON_CASE_SENSITIVE:Int
static inline var ICON_REG_EXP:Int
static inline var ICON_FOLDER:Int
static inline var ICON_FILE:Int
static inline var ICON_SAND_TIMER:Int
static inline var ICON_WARNING:Int
static inline var ICON_HELP_BOX:Int
static inline var ICON_INFO_BOX:Int
static inline var ICON_PRIORITY:Int
static inline var ICON_LAYERS_ISO:Int
static inline var ICON_LAYERS2:Int
static inline var ICON_MLAYERS:Int
static inline var ICON_MAPS:Int
static inline var ICON_HOT:Int
static inline var ICON_229:Int
static inline var ICON_230:Int
static inline var ICON_231:Int
static inline var ICON_232:Int
static inline var ICON_233:Int
static inline var ICON_234:Int
static inline var ICON_235:Int
static inline var ICON_236:Int
static inline var ICON_237:Int
static inline var ICON_238:Int
static inline var ICON_239:Int
static inline var ICON_240:Int
static inline var ICON_241:Int
static inline var ICON_242:Int
static inline var ICON_243:Int
static inline var ICON_244:Int
static inline var ICON_245:Int
static inline var ICON_246:Int
static inline var ICON_247:Int
static inline var ICON_248:Int
static inline var ICON_249:Int
static inline var ICON_250:Int
static inline var ICON_251:Int
static inline var ICON_252:Int
static inline var ICON_253:Int
static inline var ICON_254:Int
static inline var ICON_255:Int
```

- `ICON_NONE`: raygui.h's `ICON_NONE`.
- `ICON_FOLDER_FILE_OPEN`: raygui.h's `ICON_FOLDER_FILE_OPEN`.
- `ICON_FILE_SAVE_CLASSIC`: raygui.h's `ICON_FILE_SAVE_CLASSIC`.
- `ICON_FOLDER_OPEN`: raygui.h's `ICON_FOLDER_OPEN`.
- `ICON_FOLDER_SAVE`: raygui.h's `ICON_FOLDER_SAVE`.
- `ICON_FILE_OPEN`: raygui.h's `ICON_FILE_OPEN`.
- `ICON_FILE_SAVE`: raygui.h's `ICON_FILE_SAVE`.
- `ICON_FILE_EXPORT`: raygui.h's `ICON_FILE_EXPORT`.
- `ICON_FILE_ADD`: raygui.h's `ICON_FILE_ADD`.
- `ICON_FILE_DELETE`: raygui.h's `ICON_FILE_DELETE`.
- `ICON_FILETYPE_TEXT`: raygui.h's `ICON_FILETYPE_TEXT`.
- `ICON_FILETYPE_AUDIO`: raygui.h's `ICON_FILETYPE_AUDIO`.
- `ICON_FILETYPE_IMAGE`: raygui.h's `ICON_FILETYPE_IMAGE`.
- `ICON_FILETYPE_PLAY`: raygui.h's `ICON_FILETYPE_PLAY`.
- `ICON_FILETYPE_VIDEO`: raygui.h's `ICON_FILETYPE_VIDEO`.
- `ICON_FILETYPE_INFO`: raygui.h's `ICON_FILETYPE_INFO`.
- `ICON_FILE_COPY`: raygui.h's `ICON_FILE_COPY`.
- `ICON_FILE_CUT`: raygui.h's `ICON_FILE_CUT`.
- `ICON_FILE_PASTE`: raygui.h's `ICON_FILE_PASTE`.
- `ICON_CURSOR_HAND`: raygui.h's `ICON_CURSOR_HAND`.
- `ICON_CURSOR_POINTER`: raygui.h's `ICON_CURSOR_POINTER`.
- `ICON_CURSOR_CLASSIC`: raygui.h's `ICON_CURSOR_CLASSIC`.
- `ICON_PENCIL`: raygui.h's `ICON_PENCIL`.
- `ICON_PENCIL_BIG`: raygui.h's `ICON_PENCIL_BIG`.
- `ICON_BRUSH_CLASSIC`: raygui.h's `ICON_BRUSH_CLASSIC`.
- `ICON_BRUSH_PAINTER`: raygui.h's `ICON_BRUSH_PAINTER`.
- `ICON_WATER_DROP`: raygui.h's `ICON_WATER_DROP`.
- `ICON_COLOR_PICKER`: raygui.h's `ICON_COLOR_PICKER`.
- `ICON_RUBBER`: raygui.h's `ICON_RUBBER`.
- `ICON_COLOR_BUCKET`: raygui.h's `ICON_COLOR_BUCKET`.
- `ICON_TEXT_T`: raygui.h's `ICON_TEXT_T`.
- `ICON_TEXT_A`: raygui.h's `ICON_TEXT_A`.
- `ICON_SCALE`: raygui.h's `ICON_SCALE`.
- `ICON_RESIZE`: raygui.h's `ICON_RESIZE`.
- `ICON_FILTER_POINT`: raygui.h's `ICON_FILTER_POINT`.
- `ICON_FILTER_BILINEAR`: raygui.h's `ICON_FILTER_BILINEAR`.
- `ICON_CROP`: raygui.h's `ICON_CROP`.
- `ICON_CROP_ALPHA`: raygui.h's `ICON_CROP_ALPHA`.
- `ICON_SQUARE_TOGGLE`: raygui.h's `ICON_SQUARE_TOGGLE`.
- `ICON_SYMMETRY`: raygui.h's `ICON_SYMMETRY`.
- `ICON_SYMMETRY_HORIZONTAL`: raygui.h's `ICON_SYMMETRY_HORIZONTAL`.
- `ICON_SYMMETRY_VERTICAL`: raygui.h's `ICON_SYMMETRY_VERTICAL`.
- `ICON_LENS`: raygui.h's `ICON_LENS`.
- `ICON_LENS_BIG`: raygui.h's `ICON_LENS_BIG`.
- `ICON_EYE_ON`: raygui.h's `ICON_EYE_ON`.
- `ICON_EYE_OFF`: raygui.h's `ICON_EYE_OFF`.
- `ICON_FILTER_TOP`: raygui.h's `ICON_FILTER_TOP`.
- `ICON_FILTER`: raygui.h's `ICON_FILTER`.
- `ICON_TARGET_POINT`: raygui.h's `ICON_TARGET_POINT`.
- `ICON_TARGET_SMALL`: raygui.h's `ICON_TARGET_SMALL`.
- `ICON_TARGET_BIG`: raygui.h's `ICON_TARGET_BIG`.
- `ICON_TARGET_MOVE`: raygui.h's `ICON_TARGET_MOVE`.
- `ICON_CURSOR_MOVE`: raygui.h's `ICON_CURSOR_MOVE`.
- `ICON_CURSOR_SCALE`: raygui.h's `ICON_CURSOR_SCALE`.
- `ICON_CURSOR_SCALE_RIGHT`: raygui.h's `ICON_CURSOR_SCALE_RIGHT`.
- `ICON_CURSOR_SCALE_LEFT`: raygui.h's `ICON_CURSOR_SCALE_LEFT`.
- `ICON_UNDO`: raygui.h's `ICON_UNDO`.
- `ICON_REDO`: raygui.h's `ICON_REDO`.
- `ICON_REREDO`: raygui.h's `ICON_REREDO`.
- `ICON_MUTATE`: raygui.h's `ICON_MUTATE`.
- `ICON_ROTATE`: raygui.h's `ICON_ROTATE`.
- `ICON_REPEAT`: raygui.h's `ICON_REPEAT`.
- `ICON_SHUFFLE`: raygui.h's `ICON_SHUFFLE`.
- `ICON_EMPTYBOX`: raygui.h's `ICON_EMPTYBOX`.
- `ICON_TARGET`: raygui.h's `ICON_TARGET`.
- `ICON_TARGET_SMALL_FILL`: raygui.h's `ICON_TARGET_SMALL_FILL`.
- `ICON_TARGET_BIG_FILL`: raygui.h's `ICON_TARGET_BIG_FILL`.
- `ICON_TARGET_MOVE_FILL`: raygui.h's `ICON_TARGET_MOVE_FILL`.
- `ICON_CURSOR_MOVE_FILL`: raygui.h's `ICON_CURSOR_MOVE_FILL`.
- `ICON_CURSOR_SCALE_FILL`: raygui.h's `ICON_CURSOR_SCALE_FILL`.
- `ICON_CURSOR_SCALE_RIGHT_FILL`: raygui.h's `ICON_CURSOR_SCALE_RIGHT_FILL`.
- `ICON_CURSOR_SCALE_LEFT_FILL`: raygui.h's `ICON_CURSOR_SCALE_LEFT_FILL`.
- `ICON_UNDO_FILL`: raygui.h's `ICON_UNDO_FILL`.
- `ICON_REDO_FILL`: raygui.h's `ICON_REDO_FILL`.
- `ICON_REREDO_FILL`: raygui.h's `ICON_REREDO_FILL`.
- `ICON_MUTATE_FILL`: raygui.h's `ICON_MUTATE_FILL`.
- `ICON_ROTATE_FILL`: raygui.h's `ICON_ROTATE_FILL`.
- `ICON_REPEAT_FILL`: raygui.h's `ICON_REPEAT_FILL`.
- `ICON_SHUFFLE_FILL`: raygui.h's `ICON_SHUFFLE_FILL`.
- `ICON_EMPTYBOX_SMALL`: raygui.h's `ICON_EMPTYBOX_SMALL`.
- `ICON_BOX`: raygui.h's `ICON_BOX`.
- `ICON_BOX_TOP`: raygui.h's `ICON_BOX_TOP`.
- `ICON_BOX_TOP_RIGHT`: raygui.h's `ICON_BOX_TOP_RIGHT`.
- `ICON_BOX_RIGHT`: raygui.h's `ICON_BOX_RIGHT`.
- `ICON_BOX_BOTTOM_RIGHT`: raygui.h's `ICON_BOX_BOTTOM_RIGHT`.
- `ICON_BOX_BOTTOM`: raygui.h's `ICON_BOX_BOTTOM`.
- `ICON_BOX_BOTTOM_LEFT`: raygui.h's `ICON_BOX_BOTTOM_LEFT`.
- `ICON_BOX_LEFT`: raygui.h's `ICON_BOX_LEFT`.
- `ICON_BOX_TOP_LEFT`: raygui.h's `ICON_BOX_TOP_LEFT`.
- `ICON_BOX_CENTER`: raygui.h's `ICON_BOX_CENTER`.
- `ICON_BOX_CIRCLE_MASK`: raygui.h's `ICON_BOX_CIRCLE_MASK`.
- `ICON_POT`: raygui.h's `ICON_POT`.
- `ICON_ALPHA_MULTIPLY`: raygui.h's `ICON_ALPHA_MULTIPLY`.
- `ICON_ALPHA_CLEAR`: raygui.h's `ICON_ALPHA_CLEAR`.
- `ICON_DITHERING`: raygui.h's `ICON_DITHERING`.
- `ICON_MIPMAPS`: raygui.h's `ICON_MIPMAPS`.
- `ICON_BOX_GRID`: raygui.h's `ICON_BOX_GRID`.
- `ICON_GRID`: raygui.h's `ICON_GRID`.
- `ICON_BOX_CORNERS_SMALL`: raygui.h's `ICON_BOX_CORNERS_SMALL`.
- `ICON_BOX_CORNERS_BIG`: raygui.h's `ICON_BOX_CORNERS_BIG`.
- `ICON_FOUR_BOXES`: raygui.h's `ICON_FOUR_BOXES`.
- `ICON_GRID_FILL`: raygui.h's `ICON_GRID_FILL`.
- `ICON_BOX_MULTISIZE`: raygui.h's `ICON_BOX_MULTISIZE`.
- `ICON_ZOOM_SMALL`: raygui.h's `ICON_ZOOM_SMALL`.
- `ICON_ZOOM_MEDIUM`: raygui.h's `ICON_ZOOM_MEDIUM`.
- `ICON_ZOOM_BIG`: raygui.h's `ICON_ZOOM_BIG`.
- `ICON_ZOOM_ALL`: raygui.h's `ICON_ZOOM_ALL`.
- `ICON_ZOOM_CENTER`: raygui.h's `ICON_ZOOM_CENTER`.
- `ICON_BOX_DOTS_SMALL`: raygui.h's `ICON_BOX_DOTS_SMALL`.
- `ICON_BOX_DOTS_BIG`: raygui.h's `ICON_BOX_DOTS_BIG`.
- `ICON_BOX_CONCENTRIC`: raygui.h's `ICON_BOX_CONCENTRIC`.
- `ICON_BOX_GRID_BIG`: raygui.h's `ICON_BOX_GRID_BIG`.
- `ICON_OK_TICK`: raygui.h's `ICON_OK_TICK`.
- `ICON_CROSS`: raygui.h's `ICON_CROSS`.
- `ICON_ARROW_LEFT`: raygui.h's `ICON_ARROW_LEFT`.
- `ICON_ARROW_RIGHT`: raygui.h's `ICON_ARROW_RIGHT`.
- `ICON_ARROW_DOWN`: raygui.h's `ICON_ARROW_DOWN`.
- `ICON_ARROW_UP`: raygui.h's `ICON_ARROW_UP`.
- `ICON_ARROW_LEFT_FILL`: raygui.h's `ICON_ARROW_LEFT_FILL`.
- `ICON_ARROW_RIGHT_FILL`: raygui.h's `ICON_ARROW_RIGHT_FILL`.
- `ICON_ARROW_DOWN_FILL`: raygui.h's `ICON_ARROW_DOWN_FILL`.
- `ICON_ARROW_UP_FILL`: raygui.h's `ICON_ARROW_UP_FILL`.
- `ICON_AUDIO`: raygui.h's `ICON_AUDIO`.
- `ICON_FX`: raygui.h's `ICON_FX`.
- `ICON_WAVE`: raygui.h's `ICON_WAVE`.
- `ICON_WAVE_SINUS`: raygui.h's `ICON_WAVE_SINUS`.
- `ICON_WAVE_SQUARE`: raygui.h's `ICON_WAVE_SQUARE`.
- `ICON_WAVE_TRIANGULAR`: raygui.h's `ICON_WAVE_TRIANGULAR`.
- `ICON_CROSS_SMALL`: raygui.h's `ICON_CROSS_SMALL`.
- `ICON_PLAYER_PREVIOUS`: raygui.h's `ICON_PLAYER_PREVIOUS`.
- `ICON_PLAYER_PLAY_BACK`: raygui.h's `ICON_PLAYER_PLAY_BACK`.
- `ICON_PLAYER_PLAY`: raygui.h's `ICON_PLAYER_PLAY`.
- `ICON_PLAYER_PAUSE`: raygui.h's `ICON_PLAYER_PAUSE`.
- `ICON_PLAYER_STOP`: raygui.h's `ICON_PLAYER_STOP`.
- `ICON_PLAYER_NEXT`: raygui.h's `ICON_PLAYER_NEXT`.
- `ICON_PLAYER_RECORD`: raygui.h's `ICON_PLAYER_RECORD`.
- `ICON_MAGNET`: raygui.h's `ICON_MAGNET`.
- `ICON_LOCK_CLOSE`: raygui.h's `ICON_LOCK_CLOSE`.
- `ICON_LOCK_OPEN`: raygui.h's `ICON_LOCK_OPEN`.
- `ICON_CLOCK`: raygui.h's `ICON_CLOCK`.
- `ICON_TOOLS`: raygui.h's `ICON_TOOLS`.
- `ICON_GEAR`: raygui.h's `ICON_GEAR`.
- `ICON_GEAR_BIG`: raygui.h's `ICON_GEAR_BIG`.
- `ICON_BIN`: raygui.h's `ICON_BIN`.
- `ICON_HAND_POINTER`: raygui.h's `ICON_HAND_POINTER`.
- `ICON_LASER`: raygui.h's `ICON_LASER`.
- `ICON_COIN`: raygui.h's `ICON_COIN`.
- `ICON_EXPLOSION`: raygui.h's `ICON_EXPLOSION`.
- `ICON_1UP`: raygui.h's `ICON_1UP`.
- `ICON_PLAYER`: raygui.h's `ICON_PLAYER`.
- `ICON_PLAYER_JUMP`: raygui.h's `ICON_PLAYER_JUMP`.
- `ICON_KEY`: raygui.h's `ICON_KEY`.
- `ICON_DEMON`: raygui.h's `ICON_DEMON`.
- `ICON_TEXT_POPUP`: raygui.h's `ICON_TEXT_POPUP`.
- `ICON_GEAR_EX`: raygui.h's `ICON_GEAR_EX`.
- `ICON_CRACK`: raygui.h's `ICON_CRACK`.
- `ICON_CRACK_POINTS`: raygui.h's `ICON_CRACK_POINTS`.
- `ICON_STAR`: raygui.h's `ICON_STAR`.
- `ICON_DOOR`: raygui.h's `ICON_DOOR`.
- `ICON_EXIT`: raygui.h's `ICON_EXIT`.
- `ICON_MODE_2D`: raygui.h's `ICON_MODE_2D`.
- `ICON_MODE_3D`: raygui.h's `ICON_MODE_3D`.
- `ICON_CUBE`: raygui.h's `ICON_CUBE`.
- `ICON_CUBE_FACE_TOP`: raygui.h's `ICON_CUBE_FACE_TOP`.
- `ICON_CUBE_FACE_LEFT`: raygui.h's `ICON_CUBE_FACE_LEFT`.
- `ICON_CUBE_FACE_FRONT`: raygui.h's `ICON_CUBE_FACE_FRONT`.
- `ICON_CUBE_FACE_BOTTOM`: raygui.h's `ICON_CUBE_FACE_BOTTOM`.
- `ICON_CUBE_FACE_RIGHT`: raygui.h's `ICON_CUBE_FACE_RIGHT`.
- `ICON_CUBE_FACE_BACK`: raygui.h's `ICON_CUBE_FACE_BACK`.
- `ICON_CAMERA`: raygui.h's `ICON_CAMERA`.
- `ICON_SPECIAL`: raygui.h's `ICON_SPECIAL`.
- `ICON_LINK_NET`: raygui.h's `ICON_LINK_NET`.
- `ICON_LINK_BOXES`: raygui.h's `ICON_LINK_BOXES`.
- `ICON_LINK_MULTI`: raygui.h's `ICON_LINK_MULTI`.
- `ICON_LINK`: raygui.h's `ICON_LINK`.
- `ICON_LINK_BROKE`: raygui.h's `ICON_LINK_BROKE`.
- `ICON_TEXT_NOTES`: raygui.h's `ICON_TEXT_NOTES`.
- `ICON_NOTEBOOK`: raygui.h's `ICON_NOTEBOOK`.
- `ICON_SUITCASE`: raygui.h's `ICON_SUITCASE`.
- `ICON_SUITCASE_ZIP`: raygui.h's `ICON_SUITCASE_ZIP`.
- `ICON_MAILBOX`: raygui.h's `ICON_MAILBOX`.
- `ICON_MONITOR`: raygui.h's `ICON_MONITOR`.
- `ICON_PRINTER`: raygui.h's `ICON_PRINTER`.
- `ICON_PHOTO_CAMERA`: raygui.h's `ICON_PHOTO_CAMERA`.
- `ICON_PHOTO_CAMERA_FLASH`: raygui.h's `ICON_PHOTO_CAMERA_FLASH`.
- `ICON_HOUSE`: raygui.h's `ICON_HOUSE`.
- `ICON_HEART`: raygui.h's `ICON_HEART`.
- `ICON_CORNER`: raygui.h's `ICON_CORNER`.
- `ICON_VERTICAL_BARS`: raygui.h's `ICON_VERTICAL_BARS`.
- `ICON_VERTICAL_BARS_FILL`: raygui.h's `ICON_VERTICAL_BARS_FILL`.
- `ICON_LIFE_BARS`: raygui.h's `ICON_LIFE_BARS`.
- `ICON_INFO`: raygui.h's `ICON_INFO`.
- `ICON_CROSSLINE`: raygui.h's `ICON_CROSSLINE`.
- `ICON_HELP`: raygui.h's `ICON_HELP`.
- `ICON_FILETYPE_ALPHA`: raygui.h's `ICON_FILETYPE_ALPHA`.
- `ICON_FILETYPE_HOME`: raygui.h's `ICON_FILETYPE_HOME`.
- `ICON_LAYERS_VISIBLE`: raygui.h's `ICON_LAYERS_VISIBLE`.
- `ICON_LAYERS`: raygui.h's `ICON_LAYERS`.
- `ICON_WINDOW`: raygui.h's `ICON_WINDOW`.
- `ICON_HIDPI`: raygui.h's `ICON_HIDPI`.
- `ICON_FILETYPE_BINARY`: raygui.h's `ICON_FILETYPE_BINARY`.
- `ICON_HEX`: raygui.h's `ICON_HEX`.
- `ICON_SHIELD`: raygui.h's `ICON_SHIELD`.
- `ICON_FILE_NEW`: raygui.h's `ICON_FILE_NEW`.
- `ICON_FOLDER_ADD`: raygui.h's `ICON_FOLDER_ADD`.
- `ICON_ALARM`: raygui.h's `ICON_ALARM`.
- `ICON_CPU`: raygui.h's `ICON_CPU`.
- `ICON_ROM`: raygui.h's `ICON_ROM`.
- `ICON_STEP_OVER`: raygui.h's `ICON_STEP_OVER`.
- `ICON_STEP_INTO`: raygui.h's `ICON_STEP_INTO`.
- `ICON_STEP_OUT`: raygui.h's `ICON_STEP_OUT`.
- `ICON_RESTART`: raygui.h's `ICON_RESTART`.
- `ICON_BREAKPOINT_ON`: raygui.h's `ICON_BREAKPOINT_ON`.
- `ICON_BREAKPOINT_OFF`: raygui.h's `ICON_BREAKPOINT_OFF`.
- `ICON_BURGER_MENU`: raygui.h's `ICON_BURGER_MENU`.
- `ICON_CASE_SENSITIVE`: raygui.h's `ICON_CASE_SENSITIVE`.
- `ICON_REG_EXP`: raygui.h's `ICON_REG_EXP`.
- `ICON_FOLDER`: raygui.h's `ICON_FOLDER`.
- `ICON_FILE`: raygui.h's `ICON_FILE`.
- `ICON_SAND_TIMER`: raygui.h's `ICON_SAND_TIMER`.
- `ICON_WARNING`: raygui.h's `ICON_WARNING`.
- `ICON_HELP_BOX`: raygui.h's `ICON_HELP_BOX`.
- `ICON_INFO_BOX`: raygui.h's `ICON_INFO_BOX`.
- `ICON_PRIORITY`: raygui.h's `ICON_PRIORITY`.
- `ICON_LAYERS_ISO`: raygui.h's `ICON_LAYERS_ISO`.
- `ICON_LAYERS2`: raygui.h's `ICON_LAYERS2`.
- `ICON_MLAYERS`: raygui.h's `ICON_MLAYERS`.
- `ICON_MAPS`: raygui.h's `ICON_MAPS`.
- `ICON_HOT`: raygui.h's `ICON_HOT`.
- `ICON_229`: raygui.h's `ICON_229`.
- `ICON_230`: raygui.h's `ICON_230`.
- `ICON_231`: raygui.h's `ICON_231`.
- `ICON_232`: raygui.h's `ICON_232`.
- `ICON_233`: raygui.h's `ICON_233`.
- `ICON_234`: raygui.h's `ICON_234`.
- `ICON_235`: raygui.h's `ICON_235`.
- `ICON_236`: raygui.h's `ICON_236`.
- `ICON_237`: raygui.h's `ICON_237`.
- `ICON_238`: raygui.h's `ICON_238`.
- `ICON_239`: raygui.h's `ICON_239`.
- `ICON_240`: raygui.h's `ICON_240`.
- `ICON_241`: raygui.h's `ICON_241`.
- `ICON_242`: raygui.h's `ICON_242`.
- `ICON_243`: raygui.h's `ICON_243`.
- `ICON_244`: raygui.h's `ICON_244`.
- `ICON_245`: raygui.h's `ICON_245`.
- `ICON_246`: raygui.h's `ICON_246`.
- `ICON_247`: raygui.h's `ICON_247`.
- `ICON_248`: raygui.h's `ICON_248`.
- `ICON_249`: raygui.h's `ICON_249`.
- `ICON_250`: raygui.h's `ICON_250`.
- `ICON_251`: raygui.h's `ICON_251`.
- `ICON_252`: raygui.h's `ICON_252`.
- `ICON_253`: raygui.h's `ICON_253`.
- `ICON_254`: raygui.h's `ICON_254`.
- `ICON_255`: raygui.h's `ICON_255`.

### raygui.h's defines

```haxe
static inline var RAYGUI_VERSION_MAJOR:Int
static inline var RAYGUI_VERSION_MINOR:Int
static inline var RAYGUI_VERSION_PATCH:Int
static inline var SCROLLBAR_LEFT_SIDE:Int
static inline var SCROLLBAR_RIGHT_SIDE:Int
```

- `RAYGUI_VERSION_MAJOR`: raygui.h's `RAYGUI_VERSION_MAJOR`.
- `RAYGUI_VERSION_MINOR`: raygui.h's `RAYGUI_VERSION_MINOR`.
- `RAYGUI_VERSION_PATCH`: raygui.h's `RAYGUI_VERSION_PATCH`.
- `SCROLLBAR_LEFT_SIDE`: raygui.h's `SCROLLBAR_LEFT_SIDE`.
- `SCROLLBAR_RIGHT_SIDE`: raygui.h's `SCROLLBAR_RIGHT_SIDE`.

### raygui: its state, style, icons and tooltips

```haxe
static function GuiEnable():Void
static function GuiDisable():Void
static function GuiLock():Void
static function GuiUnlock():Void
static function GuiIsLocked():Bool
static function GuiSetAlpha(alpha:Float):Void
static function GuiSetState(state:Int):Void
static function GuiGetState():Int
static function GuiSetFont(font:Font):Void
static function GuiGetFont():Font
static function GuiSetStyle(control:Int, property:Int, value:Int):Void
static function GuiGetStyle(control:Int, property:Int):Int
static function GuiLoadStyleDefault():Void
static function GuiEnableTooltip():Void
static function GuiDisableTooltip():Void
static function GuiSetTooltip(tooltip:String):Void
static function GuiIconText(iconId:Int, text:String):String
static function GuiSetIconScale(scale:Int):Void
static function GuiGetIcons():Array<Int>
static function GuiDrawIcon(iconId:Int, posX:Int, posY:Int, pixelSize:Int, color:Color):Void
```

- `GuiEnable`: Enables the controls again, after `GuiDisable`. A state other than disabled, set with `GuiSetState`, is left as it is.
- `GuiDisable`: Disables the controls: they are drawn disabled and take no input. A state other than normal, set with `GuiSetState`, is left as it is.
- `GuiLock`: Locks the controls: they are drawn as they are and take no input, until `GuiUnlock`.
- `GuiUnlock`: Unlocks the controls, after `GuiLock`.
- `GuiIsLocked`: Returns whether the controls are locked.
  - returns: True between `GuiLock` and `GuiUnlock`.
- `GuiSetAlpha`: Sets how opaque the controls are drawn.
  - `alpha`: 0 for clear to 1 for opaque, held to that range.
- `GuiSetState`: Sets the state every control is drawn in: normal controls follow the mouse, any other state is forced on them all.
  - `state`: The state (`STATE_NORMAL`, `STATE_FOCUSED`, `STATE_PRESSED` or `STATE_DISABLED`).
- `GuiGetState`: Returns the state set with `GuiSetState`.
  - returns: The state (`STATE_*`).
- `GuiSetFont`: Sets the font the controls draw their text in. A font with no texture is ignored. The default style is loaded first if it isn't yet, so loading it later doesn't undo this.
  - `font`: The font.
- `GuiGetFont`: Returns the font the controls draw their text in: raylib's default font once the style is loaded, or another set with `GuiSetFont`. Before anything is drawn or styled it is an empty font.
  - returns: The font.
- `GuiSetStyle`: Sets one property of a control's style. A base property of `DEFAULT` (below 16) is set for every control.
  - `control`: The control (`DEFAULT`, `LABEL`, `BUTTON` and the rest).
  - `property`: The property (`BORDER_COLOR_NORMAL`, `TEXT_SIZE`, `SLIDER_WIDTH` and the rest).
  - `value`: Its value: a color as 0xRRGGBBAA, a size in pixels, or one of the property's values.
- `GuiGetStyle`: Returns one property of a control's style.
  - `control`: The control (`DEFAULT`, `LABEL`, `BUTTON` and the rest).
  - `property`: The property (`BORDER_COLOR_NORMAL`, `TEXT_SIZE`, `SLIDER_WIDTH` and the rest).
  - returns: Its value: a color as 0xRRGGBBAA, a size in pixels, or one of the property's values.
- `GuiLoadStyleDefault`: Loads raygui's default style, its light theme, over the style: every control's colors, borders, text and sizes. The font goes back to raylib's default font, the font set before unloaded, and raylib's shapes are drawn from the font's white glyph, as raygui does, so text and shapes share one texture.
- `GuiEnableTooltip`: Turns tooltips on: a control the mouse is over draws the text set with `GuiSetTooltip` below it.
- `GuiDisableTooltip`: Turns tooltips off, after `GuiEnableTooltip`.
- `GuiSetTooltip`: Sets the tooltip the next controls show while tooltips are on, until it is set again.
  - `tooltip`: The text, or null for none.
- `GuiIconText`: Returns a control's text with an icon before it, as raygui writes one: "#" and the icon's number in three digits, then "#".
  - `iconId`: The icon (`ICON_*`).
  - `text`: The text, or null for the icon alone.
  - returns: The text, as "#012#text".
- `GuiSetIconScale`: Sets the size icons are drawn at in text, a whole multiple of their 16 pixels.
  - `scale`: The scale, 1 or more; less is ignored.
- `GuiGetIcons`: Returns the icons' bits, which a program may change: eight 32-bit words an icon, `ICON_*` times 8, two 16-pixel rows a word, bit 0 the leftmost pixel of the first.
  - returns: The icons, 2048 words.
- `GuiDrawIcon`: Draws an icon, each of its pixels a square, faded by `GuiSetAlpha`.
  - `iconId`: The icon (`ICON_*`).
  - `posX`: Its left edge, in pixels.
  - `posY`: Its top edge, in pixels.
  - `pixelSize`: The size of each of its pixels.
  - `color`: The color.

### raygui: its controls

```haxe
static function GuiWindowBox(bounds:Rectangle, title:String):Int
static function GuiGroupBox(bounds:Rectangle, text:String):Int
static function GuiLine(bounds:Rectangle, text:String):Int
static function GuiPanel(bounds:Rectangle, text:String):Int
static function GuiTabBar(bounds:Rectangle, text:Array<String>, count:Int, active:Array<Int>):Int
static function GuiScrollPanel(bounds:Rectangle, text:String, content:Rectangle, scroll:Vector2, view:Rectangle):Int
static function GuiLabel(bounds:Rectangle, text:String):Int
static function GuiButton(bounds:Rectangle, text:String):Int
static function GuiLabelButton(bounds:Rectangle, text:String):Int
static function GuiToggle(bounds:Rectangle, text:String, active:Array<Bool>):Int
static function GuiToggleGroup(bounds:Rectangle, text:String, active:Array<Int>):Int
static function GuiToggleSlider(bounds:Rectangle, text:String, active:Array<Int>):Int
static function GuiCheckBox(bounds:Rectangle, text:String, checked:Array<Bool>):Int
static function GuiComboBox(bounds:Rectangle, text:String, active:Array<Int>):Int
static function GuiDropdownBox(bounds:Rectangle, text:String, active:Array<Int>, editMode:Bool):Int
static function GuiTextBox(bounds:Rectangle, text:Array<String>, textSize:Int, editMode:Bool):Int
static function GuiSpinner(bounds:Rectangle, text:String, value:Array<Int>, minValue:Int, maxValue:Int, editMode:Bool):Int
static function GuiValueBox(bounds:Rectangle, text:String, value:Array<Int>, minValue:Int, maxValue:Int, editMode:Bool):Int
static function GuiValueBoxFloat(bounds:Rectangle, text:String, textValue:Array<String>, value:Array<Float>, editMode:Bool):Int
static function GuiSlider(bounds:Rectangle, textLeft:String, textRight:String, value:Array<Float>, minValue:Float, maxValue:Float):Int
static function GuiSliderBar(bounds:Rectangle, textLeft:String, textRight:String, value:Array<Float>, minValue:Float, maxValue:Float):Int
static function GuiProgressBar(bounds:Rectangle, textLeft:String, textRight:String, value:Array<Float>, minValue:Float, maxValue:Float):Int
static function GuiStatusBar(bounds:Rectangle, text:String):Int
static function GuiDummyRec(bounds:Rectangle, text:String):Int
static function GuiGrid(bounds:Rectangle, text:String, spacing:Float, subdivs:Int, mouseCell:Vector2):Int
static function GuiListView(bounds:Rectangle, text:String, scrollIndex:Array<Int>, active:Array<Int>):Int
static function GuiListViewEx(bounds:Rectangle, text:Array<String>, count:Int, scrollIndex:Array<Int>, active:Array<Int>, focus:Array<Int>):Int
static function GuiMessageBox(bounds:Rectangle, title:String, message:String, buttons:String):Int
static function GuiTextInputBox(bounds:Rectangle, title:String, message:String, buttons:String, text:Array<String>, textMaxSize:Int, secretViewActive:Array<Bool>):Int
static function GuiColorPicker(bounds:Rectangle, text:String, color:Color):Int
static function GuiColorPanel(bounds:Rectangle, text:String, color:Color):Int
static function GuiColorBarAlpha(bounds:Rectangle, text:String, alpha:Array<Float>):Int
static function GuiColorBarHue(bounds:Rectangle, text:String, value:Array<Float>):Int
static function GuiColorPickerHSV(bounds:Rectangle, text:String, colorHsv:Vector3):Int
static function GuiColorPanelHSV(bounds:Rectangle, text:String, colorHsv:Vector3):Int
```

- `GuiWindowBox`: Draws a window: a title bar with a close button, over a panel.
  - `bounds`: The window, its title bar 24 pixels high; it is at least 48.
  - `title`: The title, or null.
  - returns: 1 when the close button is clicked, else 0.
- `GuiGroupBox`: Draws a group box: a frame with its name in its top line.
  - `bounds`: The box.
  - `text`: Its name, or null.
  - returns: 0.
- `GuiLine`: Draws a line across its bounds' middle, with text in it when given ("--- text ------").
  - `bounds`: The line's bounds.
  - `text`: The text, or null for a plain line.
  - returns: 0.
- `GuiPanel`: Draws a panel, with a header bar when it has text.
  - `bounds`: The panel; with a header it is at least 48 pixels high.
  - `text`: The header's text, or null for none.
  - returns: 0.
- `GuiTabBar`: Draws a bar of tabs, each a toggle 160 pixels wide with a close button, scrolled so the active tab shows.
  - `bounds`: The bar; its height is the tabs'.
  - `text`: The tabs' names.
  - `count`: How many tabs.
  - `active`: The active tab, in `active[0]`, held to the tabs; a tab clicked becomes it.
  - returns: The tab whose close button was clicked or that the middle button pressed, else -1.
- `GuiScrollPanel`: Draws a scroll panel: a view of content larger than it, with scroll bars where the content is wider or taller, scrolled by the bars and the mouse wheel (across with Shift or Control held).
  - `bounds`: The panel; with a header it is at least 48 pixels high.
  - `text`: The header's text, or null for none.
  - `content`: The content's size (its x and y aren't read).
  - `scroll`: The content's offset, changed as it scrolls (0 to minus how much is hidden), or null.
  - `view`: Receives the area the content shows in, inside the bars, or null.
  - returns: 0.
- `GuiLabel`: Draws a label: text in its bounds, aligned as the label style says.
  - `bounds`: The label.
  - `text`: The text, or null.
  - returns: 0.
- `GuiButton`: Draws a button, focused under the mouse and pressed while the left button is held over it.
  - `bounds`: The button.
  - `text`: Its text, or null.
  - returns: 1 when the left button is released over it, else 0.
- `GuiLabelButton`: Draws a label that works as a button, at least as wide as its text.
  - `bounds`: The label.
  - `text`: Its text, or null.
  - returns: 1 when the left button is released over it, else 0.
- `GuiToggle`: Draws a toggle button, drawn pressed while it is on; a click turns it over.
  - `bounds`: The button.
  - `text`: Its text, or null.
  - `active`: Whether it is on, in `active[0]`, or null.
  - returns: 0.
- `GuiToggleGroup`: Draws a group of toggles, one on at a time: a toggle for each of the text's items ("One;Two;Three"), a new row at each '\n'.
  - `bounds`: The first toggle; each is this size.
  - `text`: The items, split at ';' and '\n'.
  - `active`: The item on, in `active[0]`, or null; a click on another makes it on.
  - returns: 0.
- `GuiToggleSlider`: Draws a toggle slider: its items ("Off;On") side by side, the active one under a slider; a click moves it to the next.
  - `bounds`: The slider.
  - `text`: The items, split at ';'.
  - `active`: The active item, in `active[0]`, or null; past the last it goes back to the first.
  - returns: 1 when it was clicked, else 0.
- `GuiCheckBox`: Draws a check box, its text beside it; a click on either turns it over.
  - `bounds`: The box.
  - `text`: Its text, or null.
  - `checked`: Whether it is checked, in `checked[0]`, or null.
  - returns: 1 when it was clicked, else 0.
- `GuiComboBox`: Draws a combo box: its active item, and a button showing which of how many; a press on either moves to the next, after the last the first.
  - `bounds`: The box, its button included.
  - `text`: The items, split at ';'.
  - `active`: The active item, in `active[0]`, or null; held to the items.
  - returns: 0.
- `GuiDropdownBox`: Draws a dropdown box: its active item, and in edit mode its items listed below it (above with `DROPDOWN_ROLL_UP`), the one under the mouse focused. The program turns edit mode on and off with the result.
  - `bounds`: The box; each item is its size.
  - `text`: The items, split at ';'.
  - `active`: The active item, in `active[0]`, or null; an item clicked in edit mode becomes it.
  - `editMode`: Whether it is open.
  - returns: 1 when it was pressed closed, or an item was chosen or a press fell outside it open, else 0.
- `GuiTextBox`: Draws a text box; in edit mode it takes typed text and the keys that move its cursor and delete (Home, End, Delete, Backspace, Control-Backspace for a word, the arrows, held to repeat), and a click places the cursor. The program turns edit mode on and off with the result.
  - `bounds`: The box.
  - `text`: The text, in `text[0]`, edited in place.
  - `textSize`: The most bytes the text may take, its UTF-8 bytes and one more, as raygui's buffer holds them.
  - `editMode`: Whether it is being edited.
  - returns: 1 when it was clicked out of edit mode, or Enter or a click outside ended editing, else 0.
- `GuiSpinner`: Draws a spinner: a value box between buttons that step its value down and up. In edit mode the value box takes typed digits.
  - `bounds`: The spinner, its buttons included.
  - `text`: Its label, beside it, or null.
  - `value`: The value, in `value[0]`; out of edit mode it is held to the range.
  - `minValue`: The least.
  - `maxValue`: The most.
  - `editMode`: Whether its value box is being edited.
  - returns: The value box's result: 1 when it was clicked into or out of edit mode, else 0.
- `GuiValueBox`: Draws a value box: a whole number, centered; in edit mode it takes typed digits and Backspace, and Enter or a click outside ends editing, holding the value to the range. The program turns edit mode on and off with the result.
  - `bounds`: The box.
  - `text`: Its label, beside it, or null.
  - `value`: The value, in `value[0]`.
  - `minValue`: The least.
  - `maxValue`: The most.
  - `editMode`: Whether it is being edited.
  - returns: 1 when it was clicked into edit mode, or editing ended, else 0.
- `GuiValueBoxFloat`: Draws a value box for a number with a fraction: its text, kept by the program, is shown and edited (digits, '.', and a sign first), and the value read from it.
  - `bounds`: The box.
  - `text`: Its label, beside it, or null.
  - `textValue`: The number's text, in `textValue[0]`, edited in place.
  - `value`: The value, in `value[0]`, read from the text as it changes.
  - `editMode`: Whether it is being edited.
  - returns: 1 when it was clicked into edit mode, or Enter or a click outside ended editing, else 0.
- `GuiSlider`: Draws a slider: a handle along a bar, dragged with the left button (the drag goes on outside the bar until it is released).
  - `bounds`: The slider.
  - `textLeft`: The text left of it, or null.
  - `textRight`: The text right of it, or null.
  - `value`: The value, in `value[0]`, held to the range.
  - `minValue`: The value at the left end.
  - `maxValue`: The value at the right end.
  - returns: 1 when the value changed, else 0.
- `GuiSliderBar`: Draws a slider bar: a bar filled from the left to the value, dragged with the left button.
  - `bounds`: The bar.
  - `textLeft`: The text left of it, or null.
  - `textRight`: The text right of it, or null.
  - `value`: The value, in `value[0]`, held to the range.
  - `minValue`: The value at the left end.
  - `maxValue`: The value at the right end.
  - returns: 1 when the value changed, else 0.
- `GuiProgressBar`: Draws a progress bar, filled from the left to the value; its border is colored as far as the value reaches.
  - `bounds`: The bar.
  - `textLeft`: The text left of it, or null.
  - `textRight`: The text right of it, or null.
  - `value`: The value, in `value[0]`, or null; held to the most.
  - `minValue`: The least.
  - `maxValue`: The most.
  - returns: 0.
- `GuiStatusBar`: Draws a status bar: a bordered bar with text, as a window's title.
  - `bounds`: The bar.
  - `text`: The text, or null.
  - returns: 0.
- `GuiDummyRec`: Draws a placeholder: a filled rectangle with centered text.
  - `bounds`: The rectangle.
  - `text`: The text, or null.
  - returns: 0.
- `GuiGrid`: Draws a grid: lines every spacing divided by subdivs, every subdivs-th line stronger.
  - `bounds`: The grid.
  - `text`: Not drawn.
  - `spacing`: The space between the strong lines, in pixels.
  - `subdivs`: How many cells between strong lines; 0 draws no lines.
  - `mouseCell`: Receives the cell under the mouse, counted in spacings from the grid's corner, or -1, -1 when it isn't over it; or null.
  - returns: 0.
- `GuiListView`: Draws a list view of the text's items ("One;Two;Three"), scrolled by a bar and the mouse wheel when they don't fit.
  - `bounds`: The list.
  - `text`: The items, split at ';'.
  - `scrollIndex`: The first item shown, in `scrollIndex[0]`, or null.
  - `active`: The item chosen, in `active[0]`, -1 for none, or null; a click chooses one, and again unchooses it.
  - returns: 0.
- `GuiListViewEx`: Draws a list view of items, scrolled by a bar and the mouse wheel when they don't fit, the item under the mouse focused.
  - `bounds`: The list.
  - `text`: The items.
  - `count`: How many items.
  - `scrollIndex`: The first item shown, in `scrollIndex[0]`, or null.
  - `active`: The item chosen, in `active[0]`, -1 for none, or null; a click chooses one, and again unchooses it.
  - `focus`: Receives the item under the mouse, in `focus[0]`, -1 for none, or null.
  - returns: 0.
- `GuiMessageBox`: Draws a message box: a window with a centered message and a row of buttons.
  - `bounds`: The window.
  - `title`: Its title, or null.
  - `message`: The message.
  - `buttons`: The buttons' texts, split at ';' ("Ok;Cancel").
  - returns: The button clicked, from 1, 0 for the close button, else -1.
- `GuiTextInputBox`: Draws a text input box: a window with a message, a text box and a row of buttons; a click on the text box edits it, and with `secretViewActive` a toggle beside it shows the text or hides it behind stars. One may be open at a time.
  - `bounds`: The window.
  - `title`: Its title, or null.
  - `message`: The message above the text box, or null.
  - `buttons`: The buttons' texts, split at ';' ("Ok;Cancel").
  - `text`: The text, in `text[0]`, edited in place.
  - `textMaxSize`: The most bytes the text may take, as `GuiTextBox`'s textSize.
  - `secretViewActive`: Whether the text shows, in `secretViewActive[0]`, or null for a box that always shows it.
  - returns: The button clicked, from 1, 0 for the close button, else -1.
- `GuiColorPicker`: Draws a color picker: a saturation and value panel and a hue bar beside it, both dragged with the left button. The color goes through HSV each call, so its hue may shift where red, green and blue are close.
  - `bounds`: The panel; the hue bar is beside it.
  - `text`: Not drawn.
  - `color`: The color, changed in place, or null; its alpha is kept.
  - returns: 0.
- `GuiColorPanel`: Draws a color panel: saturation across and value down at the color's hue, dragged with the left button.
  - `bounds`: The panel.
  - `text`: Not drawn.
  - `color`: The color, changed in place when the panel changes it; its alpha is kept.
  - returns: 0.
- `GuiColorBarAlpha`: Draws an alpha bar: clear to opaque across, over a checked background, its selector dragged with the left button.
  - `bounds`: The bar.
  - `text`: Not drawn.
  - `alpha`: The alpha, 0 to 1, in `alpha[0]`.
  - returns: 0.
- `GuiColorBarHue`: Draws a hue bar: the hues from red at the top round to red at the bottom, its selector dragged with the left button.
  - `bounds`: The bar.
  - `text`: Not drawn.
  - `value`: The hue, in degrees from 0 to 359, in `value[0]`.
  - returns: 0.
- `GuiColorPickerHSV`: Draws a color picker that keeps its color as HSV, so its hue never shifts: a saturation and value panel and a hue bar beside it.
  - `bounds`: The panel; the hue bar is beside it.
  - `text`: Not drawn.
  - `colorHsv`: The color, hue in degrees (x), saturation (y) and value (z) 0 to 1, changed in place; or null.
  - returns: 0.
- `GuiColorPanelHSV`: Draws a color panel for an HSV color: saturation across and value down at its hue, dragged with the left button.
  - `bounds`: The panel.
  - `text`: Not drawn.
  - `colorHsv`: The color, hue in degrees (x), saturation (y) and value (z) 0 to 1; saturation and value change in place.
  - returns: 0.

### Not supported in helix-raylib

Each of these is raylib's name (or emscripten's, which raylib's web programs call), and a call to it doesn't compile, saying why and what to use instead.

`GuiLoadStyle`, `GuiLoadIcons`.

## Raylib

*class* in [`engines/raylib/src/helix/raylib/Raylib.hx`](../../engines/raylib/src/helix/raylib/Raylib.hx), `import helix.raylib.Raylib;`

Provides raylib 5.5's API, as `raylib.h` names it, over helix-platform and helix-services: a program writes raylib, and it runs in a page and natively.

A program's loop is raylib's, `while (!WindowShouldClose()) { BeginDrawing(); ...; EndDrawing(); }`: any `while` or `do`-`while` in the main class that calls `WindowShouldClose()`, in its condition or its body, a statement of a function's own block. In a page its body runs once a frame; one elsewhere doesn't compile. A page can't wait for a file, so on every target files are loaded by helix-raylib's own `...Async` loads, in the package `helix.raylib.extras` with the rest of what helix-raylib adds, a module for each of raylib's (`import helix.raylib.extras.Textures.*;`); raylib's `LoadTexture`, `LoadImage`, `LoadModel`, `LoadSound`, `LoadWave`, `LoadFileData` and `LoadFileText` don't compile, naming the load to use. A file loaded twice is shared, and goes to the GPU when first drawn. `SaveFileTextAsync` writes are kept across runs. Shaders are raylib's GLSL, compiled as the program builds, so `LoadShader` names its files with constants. raymath's functions are `Raymath`'s, imported apart as raylib includes `raymath.h`. Its functions are written in files by raylib's modules (`helix.raylib.modules`) and listed here by module; what raylib has and helix-raylib doesn't refuses to compile, naming itself.

### Keyboard keys (US keyboard layout) (KeyboardKey)

```haxe
static inline var KEY_NULL:Int
static inline var KEY_APOSTROPHE:Int
static inline var KEY_COMMA:Int
static inline var KEY_MINUS:Int
static inline var KEY_PERIOD:Int
static inline var KEY_SLASH:Int
static inline var KEY_ZERO:Int
static inline var KEY_ONE:Int
static inline var KEY_TWO:Int
static inline var KEY_THREE:Int
static inline var KEY_FOUR:Int
static inline var KEY_FIVE:Int
static inline var KEY_SIX:Int
static inline var KEY_SEVEN:Int
static inline var KEY_EIGHT:Int
static inline var KEY_NINE:Int
static inline var KEY_SEMICOLON:Int
static inline var KEY_EQUAL:Int
static inline var KEY_A:Int
static inline var KEY_B:Int
static inline var KEY_C:Int
static inline var KEY_D:Int
static inline var KEY_E:Int
static inline var KEY_F:Int
static inline var KEY_G:Int
static inline var KEY_H:Int
static inline var KEY_I:Int
static inline var KEY_J:Int
static inline var KEY_K:Int
static inline var KEY_L:Int
static inline var KEY_M:Int
static inline var KEY_N:Int
static inline var KEY_O:Int
static inline var KEY_P:Int
static inline var KEY_Q:Int
static inline var KEY_R:Int
static inline var KEY_S:Int
static inline var KEY_T:Int
static inline var KEY_U:Int
static inline var KEY_V:Int
static inline var KEY_W:Int
static inline var KEY_X:Int
static inline var KEY_Y:Int
static inline var KEY_Z:Int
static inline var KEY_LEFT_BRACKET:Int
static inline var KEY_BACKSLASH:Int
static inline var KEY_RIGHT_BRACKET:Int
static inline var KEY_GRAVE:Int
static inline var KEY_SPACE:Int
static inline var KEY_ESCAPE:Int
static inline var KEY_ENTER:Int
static inline var KEY_TAB:Int
static inline var KEY_BACKSPACE:Int
static inline var KEY_INSERT:Int
static inline var KEY_DELETE:Int
static inline var KEY_RIGHT:Int
static inline var KEY_LEFT:Int
static inline var KEY_DOWN:Int
static inline var KEY_UP:Int
static inline var KEY_PAGE_UP:Int
static inline var KEY_PAGE_DOWN:Int
static inline var KEY_HOME:Int
static inline var KEY_END:Int
static inline var KEY_CAPS_LOCK:Int
static inline var KEY_SCROLL_LOCK:Int
static inline var KEY_NUM_LOCK:Int
static inline var KEY_PRINT_SCREEN:Int
static inline var KEY_PAUSE:Int
static inline var KEY_F1:Int
static inline var KEY_F2:Int
static inline var KEY_F3:Int
static inline var KEY_F4:Int
static inline var KEY_F5:Int
static inline var KEY_F6:Int
static inline var KEY_F7:Int
static inline var KEY_F8:Int
static inline var KEY_F9:Int
static inline var KEY_F10:Int
static inline var KEY_F11:Int
static inline var KEY_F12:Int
static inline var KEY_LEFT_SHIFT:Int
static inline var KEY_LEFT_CONTROL:Int
static inline var KEY_LEFT_ALT:Int
static inline var KEY_LEFT_SUPER:Int
static inline var KEY_RIGHT_SHIFT:Int
static inline var KEY_RIGHT_CONTROL:Int
static inline var KEY_RIGHT_ALT:Int
static inline var KEY_RIGHT_SUPER:Int
static inline var KEY_KB_MENU:Int
static inline var KEY_KP_0:Int
static inline var KEY_KP_1:Int
static inline var KEY_KP_2:Int
static inline var KEY_KP_3:Int
static inline var KEY_KP_4:Int
static inline var KEY_KP_5:Int
static inline var KEY_KP_6:Int
static inline var KEY_KP_7:Int
static inline var KEY_KP_8:Int
static inline var KEY_KP_9:Int
static inline var KEY_KP_DECIMAL:Int
static inline var KEY_KP_DIVIDE:Int
static inline var KEY_KP_MULTIPLY:Int
static inline var KEY_KP_SUBTRACT:Int
static inline var KEY_KP_ADD:Int
static inline var KEY_KP_ENTER:Int
static inline var KEY_KP_EQUAL:Int
static inline var KEY_BACK:Int
static inline var KEY_MENU:Int
static inline var KEY_VOLUME_UP:Int
static inline var KEY_VOLUME_DOWN:Int
```

- `KEY_NULL`: Key: NULL, used for no key pressed.
- `KEY_APOSTROPHE`: Key: '.
- `KEY_COMMA`: Key: ,.
- `KEY_MINUS`: Key: -.
- `KEY_PERIOD`: Key: .
- `KEY_SLASH`: Key: /.
- `KEY_ZERO`: Key: 0.
- `KEY_ONE`: Key: 1.
- `KEY_TWO`: Key: 2.
- `KEY_THREE`: Key: 3.
- `KEY_FOUR`: Key: 4.
- `KEY_FIVE`: Key: 5.
- `KEY_SIX`: Key: 6.
- `KEY_SEVEN`: Key: 7.
- `KEY_EIGHT`: Key: 8.
- `KEY_NINE`: Key: 9.
- `KEY_SEMICOLON`: Key: ;.
- `KEY_EQUAL`: Key: =.
- `KEY_A`: Key: A | a.
- `KEY_B`: Key: B | b.
- `KEY_C`: Key: C | c.
- `KEY_D`: Key: D | d.
- `KEY_E`: Key: E | e.
- `KEY_F`: Key: F | f.
- `KEY_G`: Key: G | g.
- `KEY_H`: Key: H | h.
- `KEY_I`: Key: I | i.
- `KEY_J`: Key: J | j.
- `KEY_K`: Key: K | k.
- `KEY_L`: Key: L | l.
- `KEY_M`: Key: M | m.
- `KEY_N`: Key: N | n.
- `KEY_O`: Key: O | o.
- `KEY_P`: Key: P | p.
- `KEY_Q`: Key: Q | q.
- `KEY_R`: Key: R | r.
- `KEY_S`: Key: S | s.
- `KEY_T`: Key: T | t.
- `KEY_U`: Key: U | u.
- `KEY_V`: Key: V | v.
- `KEY_W`: Key: W | w.
- `KEY_X`: Key: X | x.
- `KEY_Y`: Key: Y | y.
- `KEY_Z`: Key: Z | z.
- `KEY_LEFT_BRACKET`: Key: [.
- `KEY_BACKSLASH`: Key: '\'.
- `KEY_RIGHT_BRACKET`: Key: ].
- `KEY_GRAVE`: Key: `.
- `KEY_SPACE`: Key: Space.
- `KEY_ESCAPE`: Key: Esc.
- `KEY_ENTER`: Key: Enter.
- `KEY_TAB`: Key: Tab.
- `KEY_BACKSPACE`: Key: Backspace.
- `KEY_INSERT`: Key: Ins.
- `KEY_DELETE`: Key: Del.
- `KEY_RIGHT`: Key: Cursor right.
- `KEY_LEFT`: Key: Cursor left.
- `KEY_DOWN`: Key: Cursor down.
- `KEY_UP`: Key: Cursor up.
- `KEY_PAGE_UP`: Key: Page up.
- `KEY_PAGE_DOWN`: Key: Page down.
- `KEY_HOME`: Key: Home.
- `KEY_END`: Key: End.
- `KEY_CAPS_LOCK`: Key: Caps lock.
- `KEY_SCROLL_LOCK`: Key: Scroll down.
- `KEY_NUM_LOCK`: Key: Num lock.
- `KEY_PRINT_SCREEN`: Key: Print screen.
- `KEY_PAUSE`: Key: Pause.
- `KEY_F1`: Key: F1.
- `KEY_F2`: Key: F2.
- `KEY_F3`: Key: F3.
- `KEY_F4`: Key: F4.
- `KEY_F5`: Key: F5.
- `KEY_F6`: Key: F6.
- `KEY_F7`: Key: F7.
- `KEY_F8`: Key: F8.
- `KEY_F9`: Key: F9.
- `KEY_F10`: Key: F10.
- `KEY_F11`: Key: F11.
- `KEY_F12`: Key: F12.
- `KEY_LEFT_SHIFT`: Key: Shift left.
- `KEY_LEFT_CONTROL`: Key: Control left.
- `KEY_LEFT_ALT`: Key: Alt left.
- `KEY_LEFT_SUPER`: Key: Super left.
- `KEY_RIGHT_SHIFT`: Key: Shift right.
- `KEY_RIGHT_CONTROL`: Key: Control right.
- `KEY_RIGHT_ALT`: Key: Alt right.
- `KEY_RIGHT_SUPER`: Key: Super right.
- `KEY_KB_MENU`: Key: KB menu.
- `KEY_KP_0`: Key: Keypad 0.
- `KEY_KP_1`: Key: Keypad 1.
- `KEY_KP_2`: Key: Keypad 2.
- `KEY_KP_3`: Key: Keypad 3.
- `KEY_KP_4`: Key: Keypad 4.
- `KEY_KP_5`: Key: Keypad 5.
- `KEY_KP_6`: Key: Keypad 6.
- `KEY_KP_7`: Key: Keypad 7.
- `KEY_KP_8`: Key: Keypad 8.
- `KEY_KP_9`: Key: Keypad 9.
- `KEY_KP_DECIMAL`: Key: Keypad .
- `KEY_KP_DIVIDE`: Key: Keypad /.
- `KEY_KP_MULTIPLY`: Key: Keypad *.
- `KEY_KP_SUBTRACT`: Key: Keypad -.
- `KEY_KP_ADD`: Key: Keypad +.
- `KEY_KP_ENTER`: Key: Keypad Enter.
- `KEY_KP_EQUAL`: Key: Keypad =.
- `KEY_BACK`: Key: Android back button.
- `KEY_MENU`: Key: Android menu button.
- `KEY_VOLUME_UP`: Key: Android volume up button.
- `KEY_VOLUME_DOWN`: Key: Android volume down button.

### Mouse buttons (MouseButton)

```haxe
static inline var MOUSE_BUTTON_LEFT:Int
static inline var MOUSE_BUTTON_RIGHT:Int
static inline var MOUSE_BUTTON_MIDDLE:Int
static inline var MOUSE_BUTTON_SIDE:Int
static inline var MOUSE_BUTTON_EXTRA:Int
static inline var MOUSE_BUTTON_FORWARD:Int
static inline var MOUSE_BUTTON_BACK:Int
```

- `MOUSE_BUTTON_LEFT`: Mouse button left.
- `MOUSE_BUTTON_RIGHT`: Mouse button right.
- `MOUSE_BUTTON_MIDDLE`: Mouse button middle (pressed wheel).
- `MOUSE_BUTTON_SIDE`: Mouse button side (advanced mouse device).
- `MOUSE_BUTTON_EXTRA`: Mouse button extra (advanced mouse device).
- `MOUSE_BUTTON_FORWARD`: Mouse button forward (advanced mouse device).
- `MOUSE_BUTTON_BACK`: Mouse button back (advanced mouse device).

### Gamepad buttons (GamepadButton)

```haxe
static inline var GAMEPAD_BUTTON_UNKNOWN:Int
static inline var GAMEPAD_BUTTON_LEFT_FACE_UP:Int
static inline var GAMEPAD_BUTTON_LEFT_FACE_RIGHT:Int
static inline var GAMEPAD_BUTTON_LEFT_FACE_DOWN:Int
static inline var GAMEPAD_BUTTON_LEFT_FACE_LEFT:Int
static inline var GAMEPAD_BUTTON_RIGHT_FACE_UP:Int
static inline var GAMEPAD_BUTTON_RIGHT_FACE_RIGHT:Int
static inline var GAMEPAD_BUTTON_RIGHT_FACE_DOWN:Int
static inline var GAMEPAD_BUTTON_RIGHT_FACE_LEFT:Int
static inline var GAMEPAD_BUTTON_LEFT_TRIGGER_1:Int
static inline var GAMEPAD_BUTTON_LEFT_TRIGGER_2:Int
static inline var GAMEPAD_BUTTON_RIGHT_TRIGGER_1:Int
static inline var GAMEPAD_BUTTON_RIGHT_TRIGGER_2:Int
static inline var GAMEPAD_BUTTON_MIDDLE_LEFT:Int
static inline var GAMEPAD_BUTTON_MIDDLE:Int
static inline var GAMEPAD_BUTTON_MIDDLE_RIGHT:Int
static inline var GAMEPAD_BUTTON_LEFT_THUMB:Int
static inline var GAMEPAD_BUTTON_RIGHT_THUMB:Int
```

- `GAMEPAD_BUTTON_UNKNOWN`: Unknown button, just for error checking.
- `GAMEPAD_BUTTON_LEFT_FACE_UP`: Gamepad left DPAD up button.
- `GAMEPAD_BUTTON_LEFT_FACE_RIGHT`: Gamepad left DPAD right button.
- `GAMEPAD_BUTTON_LEFT_FACE_DOWN`: Gamepad left DPAD down button.
- `GAMEPAD_BUTTON_LEFT_FACE_LEFT`: Gamepad left DPAD left button.
- `GAMEPAD_BUTTON_RIGHT_FACE_UP`: Gamepad right button up (i.e. PS3: Triangle, Xbox: Y).
- `GAMEPAD_BUTTON_RIGHT_FACE_RIGHT`: Gamepad right button right (i.e. PS3: Circle, Xbox: B).
- `GAMEPAD_BUTTON_RIGHT_FACE_DOWN`: Gamepad right button down (i.e. PS3: Cross, Xbox: A).
- `GAMEPAD_BUTTON_RIGHT_FACE_LEFT`: Gamepad right button left (i.e. PS3: Square, Xbox: X).
- `GAMEPAD_BUTTON_LEFT_TRIGGER_1`: Gamepad top/back trigger left (first), it could be a trailing button.
- `GAMEPAD_BUTTON_LEFT_TRIGGER_2`: Gamepad top/back trigger left (second), it could be a trailing button.
- `GAMEPAD_BUTTON_RIGHT_TRIGGER_1`: Gamepad top/back trigger right (first), it could be a trailing button.
- `GAMEPAD_BUTTON_RIGHT_TRIGGER_2`: Gamepad top/back trigger right (second), it could be a trailing button.
- `GAMEPAD_BUTTON_MIDDLE_LEFT`: Gamepad center buttons, left one (i.e. PS3: Select).
- `GAMEPAD_BUTTON_MIDDLE`: Gamepad center buttons, middle one (i.e. PS3: PS, Xbox: XBOX).
- `GAMEPAD_BUTTON_MIDDLE_RIGHT`: Gamepad center buttons, right one (i.e. PS3: Start).
- `GAMEPAD_BUTTON_LEFT_THUMB`: Gamepad joystick pressed button left.
- `GAMEPAD_BUTTON_RIGHT_THUMB`: Gamepad joystick pressed button right.

### Gamepad axis (GamepadAxis)

```haxe
static inline var GAMEPAD_AXIS_LEFT_X:Int
static inline var GAMEPAD_AXIS_LEFT_Y:Int
static inline var GAMEPAD_AXIS_RIGHT_X:Int
static inline var GAMEPAD_AXIS_RIGHT_Y:Int
static inline var GAMEPAD_AXIS_LEFT_TRIGGER:Int
static inline var GAMEPAD_AXIS_RIGHT_TRIGGER:Int
```

- `GAMEPAD_AXIS_LEFT_X`: Gamepad left stick X axis.
- `GAMEPAD_AXIS_LEFT_Y`: Gamepad left stick Y axis.
- `GAMEPAD_AXIS_RIGHT_X`: Gamepad right stick X axis.
- `GAMEPAD_AXIS_RIGHT_Y`: Gamepad right stick Y axis.
- `GAMEPAD_AXIS_LEFT_TRIGGER`: Gamepad back trigger left, pressure level: [1..-1].
- `GAMEPAD_AXIS_RIGHT_TRIGGER`: Gamepad back trigger right, pressure level: [1..-1].

### System/Window config flags (ConfigFlags)

```haxe
static inline var FLAG_VSYNC_HINT:Int
static inline var FLAG_FULLSCREEN_MODE:Int
static inline var FLAG_WINDOW_RESIZABLE:Int
static inline var FLAG_WINDOW_UNDECORATED:Int
static inline var FLAG_WINDOW_HIDDEN:Int
static inline var FLAG_WINDOW_MINIMIZED:Int
static inline var FLAG_WINDOW_MAXIMIZED:Int
static inline var FLAG_WINDOW_UNFOCUSED:Int
static inline var FLAG_WINDOW_TOPMOST:Int
static inline var FLAG_WINDOW_ALWAYS_RUN:Int
static inline var FLAG_WINDOW_TRANSPARENT:Int
static inline var FLAG_WINDOW_HIGHDPI:Int
static inline var FLAG_WINDOW_MOUSE_PASSTHROUGH:Int
static inline var FLAG_BORDERLESS_WINDOWED_MODE:Int
static inline var FLAG_MSAA_4X_HINT:Int
static inline var FLAG_INTERLACED_HINT:Int
```

- `FLAG_VSYNC_HINT`: Set to try enabling V-Sync on GPU.
- `FLAG_FULLSCREEN_MODE`: Set to run program in fullscreen.
- `FLAG_WINDOW_RESIZABLE`: Set to allow resizable window.
- `FLAG_WINDOW_UNDECORATED`: Set to disable window decoration (frame and buttons).
- `FLAG_WINDOW_HIDDEN`: Set to hide window.
- `FLAG_WINDOW_MINIMIZED`: Set to minimize window (iconify).
- `FLAG_WINDOW_MAXIMIZED`: Set to maximize window (expanded to monitor).
- `FLAG_WINDOW_UNFOCUSED`: Set to window non focused.
- `FLAG_WINDOW_TOPMOST`: Set to window always on top.
- `FLAG_WINDOW_ALWAYS_RUN`: Set to allow windows running while minimized.
- `FLAG_WINDOW_TRANSPARENT`: Set to allow transparent framebuffer.
- `FLAG_WINDOW_HIGHDPI`: Set to support HighDPI.
- `FLAG_WINDOW_MOUSE_PASSTHROUGH`: Set to support mouse passthrough, only supported when FLAG_WINDOW_UNDECORATED.
- `FLAG_BORDERLESS_WINDOWED_MODE`: Set to run program in borderless windowed mode.
- `FLAG_MSAA_4X_HINT`: Set to try enabling MSAA 4X.
- `FLAG_INTERLACED_HINT`: Set to try enabling interlaced video format (for V3D).

### Gesture (Gesture)

```haxe
static inline var GESTURE_NONE:Int
static inline var GESTURE_TAP:Int
static inline var GESTURE_DOUBLETAP:Int
static inline var GESTURE_HOLD:Int
static inline var GESTURE_DRAG:Int
static inline var GESTURE_SWIPE_RIGHT:Int
static inline var GESTURE_SWIPE_LEFT:Int
static inline var GESTURE_SWIPE_UP:Int
static inline var GESTURE_SWIPE_DOWN:Int
static inline var GESTURE_PINCH_IN:Int
static inline var GESTURE_PINCH_OUT:Int
```

- `GESTURE_NONE`: No gesture.
- `GESTURE_TAP`: Tap gesture.
- `GESTURE_DOUBLETAP`: Double tap gesture.
- `GESTURE_HOLD`: Hold gesture.
- `GESTURE_DRAG`: Drag gesture.
- `GESTURE_SWIPE_RIGHT`: Swipe right gesture.
- `GESTURE_SWIPE_LEFT`: Swipe left gesture.
- `GESTURE_SWIPE_UP`: Swipe up gesture.
- `GESTURE_SWIPE_DOWN`: Swipe down gesture.
- `GESTURE_PINCH_IN`: Pinch in gesture.
- `GESTURE_PINCH_OUT`: Pinch out gesture.

### Material map index (MaterialMapIndex)

```haxe
static inline var MATERIAL_MAP_ALBEDO:Int
static inline var MATERIAL_MAP_METALNESS:Int
static inline var MATERIAL_MAP_NORMAL:Int
static inline var MATERIAL_MAP_ROUGHNESS:Int
static inline var MATERIAL_MAP_OCCLUSION:Int
static inline var MATERIAL_MAP_EMISSION:Int
static inline var MATERIAL_MAP_HEIGHT:Int
static inline var MATERIAL_MAP_CUBEMAP:Int
static inline var MATERIAL_MAP_IRRADIANCE:Int
static inline var MATERIAL_MAP_PREFILTER:Int
static inline var MATERIAL_MAP_BRDF:Int
```

- `MATERIAL_MAP_ALBEDO`: Albedo material (same as: MATERIAL_MAP_DIFFUSE).
- `MATERIAL_MAP_METALNESS`: Metalness material (same as: MATERIAL_MAP_SPECULAR).
- `MATERIAL_MAP_NORMAL`: Normal material.
- `MATERIAL_MAP_ROUGHNESS`: Roughness material.
- `MATERIAL_MAP_OCCLUSION`: Ambient occlusion material.
- `MATERIAL_MAP_EMISSION`: Emission material.
- `MATERIAL_MAP_HEIGHT`: Heightmap material.
- `MATERIAL_MAP_CUBEMAP`: Cubemap material (NOTE: Uses GL_TEXTURE_CUBE_MAP).
- `MATERIAL_MAP_IRRADIANCE`: Irradiance material (NOTE: Uses GL_TEXTURE_CUBE_MAP).
- `MATERIAL_MAP_PREFILTER`: Prefilter material (NOTE: Uses GL_TEXTURE_CUBE_MAP).
- `MATERIAL_MAP_BRDF`: Brdf material.

### Shader location index (ShaderLocationIndex)

```haxe
static inline var SHADER_LOC_VERTEX_POSITION:Int
static inline var SHADER_LOC_VERTEX_TEXCOORD01:Int
static inline var SHADER_LOC_VERTEX_TEXCOORD02:Int
static inline var SHADER_LOC_VERTEX_NORMAL:Int
static inline var SHADER_LOC_VERTEX_TANGENT:Int
static inline var SHADER_LOC_VERTEX_COLOR:Int
static inline var SHADER_LOC_MATRIX_MVP:Int
static inline var SHADER_LOC_MATRIX_VIEW:Int
static inline var SHADER_LOC_MATRIX_PROJECTION:Int
static inline var SHADER_LOC_MATRIX_MODEL:Int
static inline var SHADER_LOC_MATRIX_NORMAL:Int
static inline var SHADER_LOC_VECTOR_VIEW:Int
static inline var SHADER_LOC_COLOR_DIFFUSE:Int
static inline var SHADER_LOC_COLOR_SPECULAR:Int
static inline var SHADER_LOC_COLOR_AMBIENT:Int
static inline var SHADER_LOC_MAP_ALBEDO:Int
static inline var SHADER_LOC_MAP_METALNESS:Int
static inline var SHADER_LOC_MAP_NORMAL:Int
static inline var SHADER_LOC_MAP_ROUGHNESS:Int
static inline var SHADER_LOC_MAP_OCCLUSION:Int
static inline var SHADER_LOC_MAP_EMISSION:Int
static inline var SHADER_LOC_MAP_HEIGHT:Int
static inline var SHADER_LOC_MAP_CUBEMAP:Int
static inline var SHADER_LOC_MAP_IRRADIANCE:Int
static inline var SHADER_LOC_MAP_PREFILTER:Int
static inline var SHADER_LOC_MAP_BRDF:Int
static inline var SHADER_LOC_VERTEX_BONEIDS:Int
static inline var SHADER_LOC_VERTEX_BONEWEIGHTS:Int
static inline var SHADER_LOC_BONE_MATRICES:Int
```

- `SHADER_LOC_VERTEX_POSITION`: Shader location: vertex attribute: position.
- `SHADER_LOC_VERTEX_TEXCOORD01`: Shader location: vertex attribute: texcoord01.
- `SHADER_LOC_VERTEX_TEXCOORD02`: Shader location: vertex attribute: texcoord02.
- `SHADER_LOC_VERTEX_NORMAL`: Shader location: vertex attribute: normal.
- `SHADER_LOC_VERTEX_TANGENT`: Shader location: vertex attribute: tangent.
- `SHADER_LOC_VERTEX_COLOR`: Shader location: vertex attribute: color.
- `SHADER_LOC_MATRIX_MVP`: Shader location: matrix uniform: model-view-projection.
- `SHADER_LOC_MATRIX_VIEW`: Shader location: matrix uniform: view (camera transform).
- `SHADER_LOC_MATRIX_PROJECTION`: Shader location: matrix uniform: projection.
- `SHADER_LOC_MATRIX_MODEL`: Shader location: matrix uniform: model (transform).
- `SHADER_LOC_MATRIX_NORMAL`: Shader location: matrix uniform: normal.
- `SHADER_LOC_VECTOR_VIEW`: Shader location: vector uniform: view.
- `SHADER_LOC_COLOR_DIFFUSE`: Shader location: vector uniform: diffuse color.
- `SHADER_LOC_COLOR_SPECULAR`: Shader location: vector uniform: specular color.
- `SHADER_LOC_COLOR_AMBIENT`: Shader location: vector uniform: ambient color.
- `SHADER_LOC_MAP_ALBEDO`: Shader location: sampler2d texture: albedo (same as: SHADER_LOC_MAP_DIFFUSE).
- `SHADER_LOC_MAP_METALNESS`: Shader location: sampler2d texture: metalness (same as: SHADER_LOC_MAP_SPECULAR).
- `SHADER_LOC_MAP_NORMAL`: Shader location: sampler2d texture: normal.
- `SHADER_LOC_MAP_ROUGHNESS`: Shader location: sampler2d texture: roughness.
- `SHADER_LOC_MAP_OCCLUSION`: Shader location: sampler2d texture: occlusion.
- `SHADER_LOC_MAP_EMISSION`: Shader location: sampler2d texture: emission.
- `SHADER_LOC_MAP_HEIGHT`: Shader location: sampler2d texture: height.
- `SHADER_LOC_MAP_CUBEMAP`: Shader location: samplerCube texture: cubemap.
- `SHADER_LOC_MAP_IRRADIANCE`: Shader location: samplerCube texture: irradiance.
- `SHADER_LOC_MAP_PREFILTER`: Shader location: samplerCube texture: prefilter.
- `SHADER_LOC_MAP_BRDF`: Shader location: sampler2d texture: brdf.
- `SHADER_LOC_VERTEX_BONEIDS`: Shader location: vertex attribute: boneIds.
- `SHADER_LOC_VERTEX_BONEWEIGHTS`: Shader location: vertex attribute: boneWeights.
- `SHADER_LOC_BONE_MATRICES`: Shader location: array of matrices uniform: boneMatrices.

### Shader uniform data type (ShaderUniformDataType)

```haxe
static inline var SHADER_UNIFORM_FLOAT:Int
static inline var SHADER_UNIFORM_VEC2:Int
static inline var SHADER_UNIFORM_VEC3:Int
static inline var SHADER_UNIFORM_VEC4:Int
static inline var SHADER_UNIFORM_INT:Int
static inline var SHADER_UNIFORM_IVEC2:Int
static inline var SHADER_UNIFORM_IVEC3:Int
static inline var SHADER_UNIFORM_IVEC4:Int
static inline var SHADER_UNIFORM_SAMPLER2D:Int
```

- `SHADER_UNIFORM_FLOAT`: Shader uniform type: float.
- `SHADER_UNIFORM_VEC2`: Shader uniform type: vec2 (2 float).
- `SHADER_UNIFORM_VEC3`: Shader uniform type: vec3 (3 float).
- `SHADER_UNIFORM_VEC4`: Shader uniform type: vec4 (4 float).
- `SHADER_UNIFORM_INT`: Shader uniform type: int.
- `SHADER_UNIFORM_IVEC2`: Shader uniform type: ivec2 (2 int).
- `SHADER_UNIFORM_IVEC3`: Shader uniform type: ivec3 (3 int).
- `SHADER_UNIFORM_IVEC4`: Shader uniform type: ivec4 (4 int).
- `SHADER_UNIFORM_SAMPLER2D`: Shader uniform type: sampler2d.

### Camera system modes (CameraMode)

```haxe
static inline var CAMERA_CUSTOM:Int
static inline var CAMERA_FREE:Int
static inline var CAMERA_ORBITAL:Int
static inline var CAMERA_FIRST_PERSON:Int
static inline var CAMERA_THIRD_PERSON:Int
```

- `CAMERA_CUSTOM`: Camera custom, controlled by user (UpdateCamera() does nothing).
- `CAMERA_FREE`: Camera free mode.
- `CAMERA_ORBITAL`: Camera orbital, around target, zoom supported.
- `CAMERA_FIRST_PERSON`: Camera first person.
- `CAMERA_THIRD_PERSON`: Camera third person.

### Camera projection (CameraProjection)

```haxe
static inline var CAMERA_PERSPECTIVE:Int
static inline var CAMERA_ORTHOGRAPHIC:Int
```

- `CAMERA_PERSPECTIVE`: Perspective projection.
- `CAMERA_ORTHOGRAPHIC`: Orthographic projection.

### Texture parameters: filter mode (TextureFilter)

```haxe
static inline var TEXTURE_FILTER_POINT:Int
static inline var TEXTURE_FILTER_BILINEAR:Int
static inline var TEXTURE_FILTER_TRILINEAR:Int
static inline var TEXTURE_FILTER_ANISOTROPIC_4X:Int
static inline var TEXTURE_FILTER_ANISOTROPIC_8X:Int
static inline var TEXTURE_FILTER_ANISOTROPIC_16X:Int
```

- `TEXTURE_FILTER_POINT`: No filter, just pixel approximation.
- `TEXTURE_FILTER_BILINEAR`: Linear filtering.
- `TEXTURE_FILTER_TRILINEAR`: Trilinear filtering (linear with mipmaps).
- `TEXTURE_FILTER_ANISOTROPIC_4X`: Anisotropic filtering 4x.
- `TEXTURE_FILTER_ANISOTROPIC_8X`: Anisotropic filtering 8x.
- `TEXTURE_FILTER_ANISOTROPIC_16X`: Anisotropic filtering 16x.

### Trace log level (TraceLogLevel)

```haxe
static inline var LOG_ALL:Int
static inline var LOG_TRACE:Int
static inline var LOG_DEBUG:Int
static inline var LOG_INFO:Int
static inline var LOG_WARNING:Int
static inline var LOG_ERROR:Int
static inline var LOG_FATAL:Int
static inline var LOG_NONE:Int
```

- `LOG_ALL`: Display all logs.
- `LOG_TRACE`: Trace logging, intended for internal use only.
- `LOG_DEBUG`: Debug logging, used for internal debugging.
- `LOG_INFO`: Info logging, used for program execution info.
- `LOG_WARNING`: Warning logging, used on recoverable failures.
- `LOG_ERROR`: Error logging, used on unrecoverable failures.
- `LOG_FATAL`: Fatal logging, used to abort the program.
- `LOG_NONE`: Disable logging.

### Colors

```haxe
static final LIGHTGRAY(default, null):Color
static final GRAY(default, null):Color
static final DARKGRAY(default, null):Color
static final YELLOW(default, null):Color
static final GOLD(default, null):Color
static final ORANGE(default, null):Color
static final PINK(default, null):Color
static final RED(default, null):Color
static final MAROON(default, null):Color
static final GREEN(default, null):Color
static final LIME(default, null):Color
static final DARKGREEN(default, null):Color
static final SKYBLUE(default, null):Color
static final BLUE(default, null):Color
static final DARKBLUE(default, null):Color
static final PURPLE(default, null):Color
static final VIOLET(default, null):Color
static final DARKPURPLE(default, null):Color
static final BEIGE(default, null):Color
static final BROWN(default, null):Color
static final DARKBROWN(default, null):Color
static final WHITE(default, null):Color
static final BLACK(default, null):Color
static final BLANK(default, null):Color
static final MAGENTA(default, null):Color
static final RAYWHITE(default, null):Color
```

- `LIGHTGRAY`: Light Gray.
- `GRAY`: Gray.
- `DARKGRAY`: Dark Gray.
- `YELLOW`: Yellow.
- `GOLD`: Gold.
- `ORANGE`: Orange.
- `PINK`: Pink.
- `RED`: Red.
- `MAROON`: Maroon.
- `GREEN`: Green.
- `LIME`: Lime.
- `DARKGREEN`: Dark Green.
- `SKYBLUE`: Sky Blue.
- `BLUE`: Blue.
- `DARKBLUE`: Dark Blue.
- `PURPLE`: Purple.
- `VIOLET`: Violet.
- `DARKPURPLE`: Dark Purple.
- `BEIGE`: Beige.
- `BROWN`: Brown.
- `DARKBROWN`: Dark Brown.
- `WHITE`: White.
- `BLACK`: Black.
- `BLANK`: Blank (Transparent).
- `MAGENTA`: Magenta.
- `RAYWHITE`: My own White (raylib logo).

```haxe
static inline var MATERIAL_MAP_DIFFUSE:Int
static inline var MATERIAL_MAP_SPECULAR:Int
static inline var SHADER_LOC_MAP_DIFFUSE:Int
static inline var SHADER_LOC_MAP_SPECULAR:Int
static inline var MAX_MATERIAL_MAPS:Int
```

- `MATERIAL_MAP_DIFFUSE`: The diffuse map, the same as `MATERIAL_MAP_ALBEDO`.
- `MATERIAL_MAP_SPECULAR`: The specular map, the same as `MATERIAL_MAP_METALNESS`.
- `SHADER_LOC_MAP_DIFFUSE`: The diffuse texture's location, the same as `SHADER_LOC_MAP_ALBEDO`.
- `SHADER_LOC_MAP_SPECULAR`: The specular texture's location, the same as `SHADER_LOC_MAP_METALNESS`.
- `MAX_MATERIAL_MAPS`: The number of a material's maps.

### Pixel formats (PixelFormat)

```haxe
static inline var PIXELFORMAT_UNCOMPRESSED_R8G8B8A8:Int
static inline var PIXELFORMAT_UNCOMPRESSED_GRAYSCALE:Int
static inline var PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA:Int
static inline var PIXELFORMAT_UNCOMPRESSED_R5G6B5:Int
static inline var PIXELFORMAT_UNCOMPRESSED_R8G8B8:Int
static inline var PIXELFORMAT_UNCOMPRESSED_R5G5B5A1:Int
static inline var PIXELFORMAT_UNCOMPRESSED_R4G4B4A4:Int
static inline var PIXELFORMAT_UNCOMPRESSED_R32:Int
static inline var PIXELFORMAT_UNCOMPRESSED_R32G32B32:Int
static inline var PIXELFORMAT_UNCOMPRESSED_R32G32B32A32:Int
static inline var PIXELFORMAT_UNCOMPRESSED_R16:Int
static inline var PIXELFORMAT_UNCOMPRESSED_R16G16B16:Int
static inline var PIXELFORMAT_UNCOMPRESSED_R16G16B16A16:Int
static inline var PIXELFORMAT_COMPRESSED_DXT1_RGB:Int
static inline var PIXELFORMAT_COMPRESSED_DXT1_RGBA:Int
static inline var PIXELFORMAT_COMPRESSED_DXT3_RGBA:Int
static inline var PIXELFORMAT_COMPRESSED_DXT5_RGBA:Int
static inline var PIXELFORMAT_COMPRESSED_ETC1_RGB:Int
static inline var PIXELFORMAT_COMPRESSED_ETC2_RGB:Int
static inline var PIXELFORMAT_COMPRESSED_ETC2_EAC_RGBA:Int
static inline var PIXELFORMAT_COMPRESSED_PVRT_RGB:Int
static inline var PIXELFORMAT_COMPRESSED_PVRT_RGBA:Int
static inline var PIXELFORMAT_COMPRESSED_ASTC_4x4_RGBA:Int
static inline var PIXELFORMAT_COMPRESSED_ASTC_8x8_RGBA:Int
```

- `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`: The pixel format of every texture loaded here: 8-bit red, green, blue and alpha.
- `PIXELFORMAT_UNCOMPRESSED_GRAYSCALE`: 8 bit per pixel (no alpha).
- `PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA`: 8*2 bpp (2 channels).
- `PIXELFORMAT_UNCOMPRESSED_R5G6B5`: 16 bpp.
- `PIXELFORMAT_UNCOMPRESSED_R8G8B8`: 24 bpp.
- `PIXELFORMAT_UNCOMPRESSED_R5G5B5A1`: 16 bpp (1 bit alpha).
- `PIXELFORMAT_UNCOMPRESSED_R4G4B4A4`: 16 bpp (4 bit alpha).
- `PIXELFORMAT_UNCOMPRESSED_R32`: 32 bpp (1 channel - float).
- `PIXELFORMAT_UNCOMPRESSED_R32G32B32`: 32*3 bpp (3 channels - float).
- `PIXELFORMAT_UNCOMPRESSED_R32G32B32A32`: 32*4 bpp (4 channels - float).
- `PIXELFORMAT_UNCOMPRESSED_R16`: 16 bpp (1 channel - half float).
- `PIXELFORMAT_UNCOMPRESSED_R16G16B16`: 16*3 bpp (3 channels - half float).
- `PIXELFORMAT_UNCOMPRESSED_R16G16B16A16`: 16*4 bpp (4 channels - half float).
- `PIXELFORMAT_COMPRESSED_DXT1_RGB`: 4 bpp (no alpha).
- `PIXELFORMAT_COMPRESSED_DXT1_RGBA`: 4 bpp (1 bit alpha).
- `PIXELFORMAT_COMPRESSED_DXT3_RGBA`: 8 bpp.
- `PIXELFORMAT_COMPRESSED_DXT5_RGBA`: 8 bpp.
- `PIXELFORMAT_COMPRESSED_ETC1_RGB`: 4 bpp.
- `PIXELFORMAT_COMPRESSED_ETC2_RGB`: 4 bpp.
- `PIXELFORMAT_COMPRESSED_ETC2_EAC_RGBA`: 8 bpp.
- `PIXELFORMAT_COMPRESSED_PVRT_RGB`: 4 bpp.
- `PIXELFORMAT_COMPRESSED_PVRT_RGBA`: 4 bpp.
- `PIXELFORMAT_COMPRESSED_ASTC_4x4_RGBA`: 8 bpp.
- `PIXELFORMAT_COMPRESSED_ASTC_8x8_RGBA`: 2 bpp.

### raylib.h's defines

```haxe
static inline var PI:Float
static inline var DEG2RAD:Float
static inline var RAD2DEG:Float
static inline var RAYLIB_VERSION_MAJOR:Int
static inline var RAYLIB_VERSION_MINOR:Int
static inline var RAYLIB_VERSION_PATCH:Int
```

- `PI`: Pi.
- `DEG2RAD`: Degrees to radians.
- `RAD2DEG`: Radians to degrees.
- `RAYLIB_VERSION_MAJOR`: raylib.h's `RAYLIB_VERSION_MAJOR`.
- `RAYLIB_VERSION_MINOR`: raylib.h's `RAYLIB_VERSION_MINOR`.
- `RAYLIB_VERSION_PATCH`: raylib.h's `RAYLIB_VERSION_PATCH`.

### Mouse cursor (MouseCursor)

```haxe
static inline var MOUSE_CURSOR_DEFAULT:Int
static inline var MOUSE_CURSOR_ARROW:Int
static inline var MOUSE_CURSOR_IBEAM:Int
static inline var MOUSE_CURSOR_CROSSHAIR:Int
static inline var MOUSE_CURSOR_POINTING_HAND:Int
static inline var MOUSE_CURSOR_RESIZE_EW:Int
static inline var MOUSE_CURSOR_RESIZE_NS:Int
static inline var MOUSE_CURSOR_RESIZE_NWSE:Int
static inline var MOUSE_CURSOR_RESIZE_NESW:Int
static inline var MOUSE_CURSOR_RESIZE_ALL:Int
static inline var MOUSE_CURSOR_NOT_ALLOWED:Int
```

- `MOUSE_CURSOR_DEFAULT`: Default pointer shape.
- `MOUSE_CURSOR_ARROW`: Arrow shape.
- `MOUSE_CURSOR_IBEAM`: Text writing cursor shape.
- `MOUSE_CURSOR_CROSSHAIR`: Cross shape.
- `MOUSE_CURSOR_POINTING_HAND`: Pointing hand cursor.
- `MOUSE_CURSOR_RESIZE_EW`: Horizontal resize/move arrow shape.
- `MOUSE_CURSOR_RESIZE_NS`: Vertical resize/move arrow shape.
- `MOUSE_CURSOR_RESIZE_NWSE`: Top-left to bottom-right diagonal resize/move arrow shape.
- `MOUSE_CURSOR_RESIZE_NESW`: The top-right to bottom-left diagonal resize/move arrow shape.
- `MOUSE_CURSOR_RESIZE_ALL`: The omnidirectional resize/move cursor shape.
- `MOUSE_CURSOR_NOT_ALLOWED`: The operation-not-allowed shape.

### Shader attribute data types (ShaderAttributeDataType)

```haxe
static inline var SHADER_ATTRIB_FLOAT:Int
static inline var SHADER_ATTRIB_VEC2:Int
static inline var SHADER_ATTRIB_VEC3:Int
static inline var SHADER_ATTRIB_VEC4:Int
```

- `SHADER_ATTRIB_FLOAT`: Shader attribute type: float.
- `SHADER_ATTRIB_VEC2`: Shader attribute type: vec2 (2 float).
- `SHADER_ATTRIB_VEC3`: Shader attribute type: vec3 (3 float).
- `SHADER_ATTRIB_VEC4`: Shader attribute type: vec4 (4 float).

### Texture parameters: wrap mode (TextureWrap)

```haxe
static inline var TEXTURE_WRAP_REPEAT:Int
static inline var TEXTURE_WRAP_CLAMP:Int
static inline var TEXTURE_WRAP_MIRROR_REPEAT:Int
static inline var TEXTURE_WRAP_MIRROR_CLAMP:Int
```

- `TEXTURE_WRAP_REPEAT`: Repeats texture in tiled mode.
- `TEXTURE_WRAP_CLAMP`: Clamps texture to edge pixel in tiled mode.
- `TEXTURE_WRAP_MIRROR_REPEAT`: Mirrors and repeats the texture in tiled mode.
- `TEXTURE_WRAP_MIRROR_CLAMP`: Mirrors and clamps to border the texture in tiled mode.

### Cubemap layouts (CubemapLayout)

```haxe
static inline var CUBEMAP_LAYOUT_AUTO_DETECT:Int
static inline var CUBEMAP_LAYOUT_LINE_VERTICAL:Int
static inline var CUBEMAP_LAYOUT_LINE_HORIZONTAL:Int
static inline var CUBEMAP_LAYOUT_CROSS_THREE_BY_FOUR:Int
static inline var CUBEMAP_LAYOUT_CROSS_FOUR_BY_THREE:Int
```

- `CUBEMAP_LAYOUT_AUTO_DETECT`: Automatically detect layout type.
- `CUBEMAP_LAYOUT_LINE_VERTICAL`: Layout is defined by a vertical line with faces.
- `CUBEMAP_LAYOUT_LINE_HORIZONTAL`: Layout is defined by a horizontal line with faces.
- `CUBEMAP_LAYOUT_CROSS_THREE_BY_FOUR`: Layout is defined by a 3x4 cross with cubemap faces.
- `CUBEMAP_LAYOUT_CROSS_FOUR_BY_THREE`: Layout is defined by a 4x3 cross with cubemap faces.

### Font type, defines generation method (FontType)

```haxe
static inline var FONT_DEFAULT:Int
static inline var FONT_BITMAP:Int
static inline var FONT_SDF:Int
```

- `FONT_DEFAULT`: Default font generation, anti-aliased.
- `FONT_BITMAP`: Bitmap font generation, no anti-aliasing.
- `FONT_SDF`: SDF font generation, requires external shader.

### Color blending modes (pre-defined) (BlendMode)

```haxe
static inline var BLEND_ALPHA:Int
static inline var BLEND_ADDITIVE:Int
static inline var BLEND_MULTIPLIED:Int
static inline var BLEND_ADD_COLORS:Int
static inline var BLEND_SUBTRACT_COLORS:Int
static inline var BLEND_ALPHA_PREMULTIPLY:Int
static inline var BLEND_CUSTOM:Int
static inline var BLEND_CUSTOM_SEPARATE:Int
```

- `BLEND_ALPHA`: Blend textures considering alpha (default).
- `BLEND_ADDITIVE`: Blend textures adding colors.
- `BLEND_MULTIPLIED`: Blend textures multiplying colors.
- `BLEND_ADD_COLORS`: Blend textures adding colors (alternative).
- `BLEND_SUBTRACT_COLORS`: Blend textures subtracting colors (alternative).
- `BLEND_ALPHA_PREMULTIPLY`: Blend premultiplied textures considering alpha.
- `BLEND_CUSTOM`: Blend textures using custom src/dst factors (use rlSetBlendFactors()).
- `BLEND_CUSTOM_SEPARATE`: Blend textures using custom rgb/alpha separate src/dst factors (use rlSetBlendFactorsSeparate()).

### N-patch layout (NPatchLayout)

```haxe
static inline var NPATCH_NINE_PATCH:Int
static inline var NPATCH_THREE_PATCH_VERTICAL:Int
static inline var NPATCH_THREE_PATCH_HORIZONTAL:Int
```

- `NPATCH_NINE_PATCH`: Npatch layout: 3x3 tiles.
- `NPATCH_THREE_PATCH_VERTICAL`: Npatch layout: 1x3 tiles.
- `NPATCH_THREE_PATCH_HORIZONTAL`: Npatch layout: 3x1 tiles.

### rcore: the window and frame, input, files, cameras and shaders

```haxe
static function InitWindow(width:Int, height:Int, title:String):Void
static function CloseWindow():Void
static function WindowShouldClose():Bool
static function IsWindowReady():Bool
static function IsWindowResized():Bool
static function SetWindowTitle(title:String):Void
static function IsWindowFullscreen():Bool
static function IsWindowHidden():Bool
static function IsWindowMinimized():Bool
static function IsWindowMaximized():Bool
static function SetWindowIcon(image:Image):Void
static function SetWindowIcons(images:Array<Image>, count:Int):Void
static function GetMonitorRefreshRate(monitor:Int):Int
static function OpenURL(url:String):Void
static function IsWindowFocused():Bool
static function GetWindowPosition():Vector2
static function GetWindowScaleDPI():Vector2
static function GetMonitorCount():Int
static function GetCurrentMonitor():Int
static function GetMonitorPosition(monitor:Int):Vector2
static function GetMonitorWidth(monitor:Int):Int
static function GetMonitorHeight(monitor:Int):Int
static function GetMonitorName(monitor:Int):String
static function GetScreenWidth():Int
static function GetScreenHeight():Int
static function GetRenderWidth():Int
static function GetRenderHeight():Int
static function SetConfigFlags(flags:Int):Void
static function SetWindowState(flags:Int):Void
static function ClearWindowState(flags:Int):Void
static function IsWindowState(flag:Int):Bool
static function SetTargetFPS(fps:Int):Void
static function GetFPS():Int
static function GetFrameTime():Float
static function WaitTime(seconds:Float):Void
static function GetTime():Float
static function SetExitKey(key:Int):Void
static function BeginDrawing():Void
static function EndDrawing():Void
static function SwapScreenBuffer():Void
static function PollInputEvents():Void
static function EnableEventWaiting():Void
static function DisableEventWaiting():Void
static function ClearBackground(color:Color):Void
static function GetRandomValue(min:Int, max:Int):Int
static function SetRandomSeed(seed:Int):Void
static function LoadRandomSequence(count:Int, min:Int, max:Int):Null<Array<Int>>
static function UnloadRandomSequence(sequence:Null<Array<Int>>):Void
static function IsKeyPressed(key:Int):Bool
static function IsKeyDown(key:Int):Bool
static function IsKeyReleased(key:Int):Bool
static function IsKeyUp(key:Int):Bool
static function GetKeyPressed():Int
static function IsKeyPressedRepeat(key:Int):Bool
static function GetCharPressed():Int
static function IsMouseButtonPressed(button:Int):Bool
static function IsMouseButtonDown(button:Int):Bool
static function IsMouseButtonReleased(button:Int):Bool
static function IsMouseButtonUp(button:Int):Bool
static function GetMouseX():Int
static function GetMouseY():Int
static function GetMousePosition():Vector2
static function SetMousePosition(x:Int, y:Int):Void
static function SetMouseOffset(offsetX:Int, offsetY:Int):Void
static function SetMouseScale(scaleX:Float, scaleY:Float):Void
static function GetMouseWheelMoveV():Vector2
static function ShowCursor():Void
static function HideCursor():Void
static function IsCursorHidden():Bool
static function IsCursorOnScreen():Bool
static function SetMouseCursor(cursor:Int):Void
static function GetMouseWheelMove():Float
static function GetTouchPointCount():Int
static function GetTouchPosition(index:Int):Vector2
static function GetTouchPointId(index:Int):Int
static function GetTouchX():Int
static function GetTouchY():Int
static function SetGesturesEnabled(flags:Int):Void
static function IsGestureDetected(gesture:Int):Bool
static function GetGestureDetected():Int
static function GetGestureHoldDuration():Float
static function GetGestureDragVector():Vector2
static function GetGestureDragAngle():Float
static function GetGesturePinchVector():Vector2
static function GetGesturePinchAngle():Float
static function SetGamepadVibration(gamepad:Int, leftMotor:Float, rightMotor:Float, duration:Float):Void
static function SetGamepadMappings(mappings:String):Int
static function IsGamepadAvailable(gamepad:Int):Bool
static function GetGamepadName(gamepad:Int):String
static function IsGamepadButtonPressed(gamepad:Int, button:Int):Bool
static function IsGamepadButtonDown(gamepad:Int, button:Int):Bool
static function IsGamepadButtonReleased(gamepad:Int, button:Int):Bool
static function IsGamepadButtonUp(gamepad:Int, button:Int):Bool
static function GetGamepadButtonPressed():Int
static function GetGamepadAxisCount(gamepad:Int):Int
static function GetGamepadAxisMovement(gamepad:Int, axis:Int):Float
static function UnloadFileText(text:Null<String>):Void
static function UnloadFileData(data:Null<haxe.io.Bytes>):Void
static function GetWorkingDirectory():String
static function GetApplicationDirectory():String
static function ChangeDirectory(dir:String):Bool
static function IsFileExtension(fileName:String, ext:String):Bool
static function GetFileExtension(fileName:String):String
static function GetFileName(filePath:String):String
static function GetFileNameWithoutExt(filePath:String):String
static function GetDirectoryPath(filePath:String):String
static function GetPrevDirectoryPath(dirPath:String):String
static function IsFileNameValid(fileName:String):Bool
static function MakeDirectory(dirPath:String):Int
static function UnloadDirectoryFiles(files:FilePathList):Void
static function IsFileDropped():Bool
static function LoadDroppedFiles():FilePathList
static function UnloadDroppedFiles(files:FilePathList):Void
static function CompressData(data:haxe.io.Bytes, dataSize:Int, compDataSize:Array<Int>):haxe.io.Bytes
static function DecompressData(compData:haxe.io.Bytes, compDataSize:Int, dataSize:Array<Int>):haxe.io.Bytes
static function EncodeDataBase64(data:haxe.io.Bytes, dataSize:Int, outputSize:Array<Int>):String
static function DecodeDataBase64(data:haxe.io.Bytes, outputSize:Array<Int>):haxe.io.Bytes
static function ComputeCRC32(data:haxe.io.Bytes, dataSize:Int):Int
static function ComputeMD5(data:haxe.io.Bytes, dataSize:Int):Array<Int>
static function ComputeSHA1(data:haxe.io.Bytes, dataSize:Int):Array<Int>
static function SetLoadFileDataCallback(callback:Null<(fileName:String) -> Null<haxe.io.Bytes>>):Void
static function SetSaveFileDataCallback(callback:Null<(fileName:String, data:haxe.io.Bytes, dataSize:Int) -> Bool>):Void
static function SetLoadFileTextCallback(callback:Null<(fileName:String) -> Null<String>>):Void
static function SetSaveFileTextCallback(callback:Null<(fileName:String, text:String) -> Bool>):Void
static function UnloadAutomationEventList(list:AutomationEventList):Void
static function SetAutomationEventList(list:AutomationEventList):Void
static function SetAutomationEventBaseFrame(frame:Int):Void
static function StartAutomationEventRecording():Void
static function StopAutomationEventRecording():Void
static function PlayAutomationEvent(event:AutomationEvent):Void
static function TraceLog(logLevel:Int, text:String):Void
static function SetTraceLogLevel(logLevel:Int):Void
static function SetTraceLogCallback(callback:Null<(logLevel:Int, text:String) -> Void>):Void
static function BeginMode2D(camera:Camera2D):Void
static function EndMode2D():Void
static function GetCameraMatrix2D(camera:Camera2D):Matrix
static function GetWorldToScreen2D(position:Vector2, camera:Camera2D):Vector2
static function GetScreenToWorld2D(position:Vector2, camera:Camera2D):Vector2
static function BeginMode3D(camera:Camera3D):Void
static function EndMode3D():Void
static function UpdateCamera(camera:Camera3D, mode:Int):Void
static function UpdateCameraPro(camera:Camera, movement:Vector3, rotation:Vector3, zoom:Float):Void
static function GetCameraMatrix(camera:Camera3D):Matrix
static function GetScreenToWorldRay(position:Vector2, camera:Camera3D):Ray
static function GetScreenToWorldRayEx(position:Vector2, camera:Camera3D, width:Int, height:Int):Ray
static function GetMouseRay(position:Vector2, camera:Camera3D):Ray
static function GetWorldToScreen(position:Vector3, camera:Camera3D):Vector2
static function GetWorldToScreenEx(position:Vector3, camera:Camera3D, width:Int, height:Int):Vector2
static function GetMouseDelta():Vector2
static function BeginVrStereoMode(config:VrStereoConfig):Void
static function EndVrStereoMode():Void
static function LoadVrStereoConfig(device:VrDeviceInfo):VrStereoConfig
static function UnloadVrStereoConfig(config:VrStereoConfig):Void
static function IsShaderValid(shader:Shader):Bool
static function UnloadShader(shader:Shader):Void
static function GetShaderLocation(shader:Shader, uniformName:String):Int
static function GetShaderLocationAttrib(shader:Shader, attribName:String):Int
static function SetShaderValue(shader:Shader, locIndex:Int, value:Dynamic, uniformType:Int):Void
static function SetShaderValueV(shader:Shader, locIndex:Int, value:Dynamic, uniformType:Int, count:Int):Void
static function SetShaderValueMatrix(shader:Shader, locIndex:Int, mat:Matrix):Void
static function SetShaderValueTexture(shader:Shader, locIndex:Int, texture:Texture2D):Void
static function BeginShaderMode(shader:Shader):Void
static function EndShaderMode():Void
static function BeginBlendMode(mode:Int):Void
static function EndBlendMode():Void
static function BeginScissorMode(x:Int, y:Int, width:Int, height:Int):Void
static function EndScissorMode():Void
```

- `InitWindow`: Opens the window and its graphics. In a page the canvas fills the page, and width and height are ignored.
  - `width`: The window's width, in pixels.
  - `height`: The window's height, in pixels.
  - `title`: The window's title.
- `CloseWindow`: Closes the window, after keeping what `SaveFileText` wrote.
- `WindowShouldClose`: Returns whether the window should close: the exit key was pressed (Escape unless `SetExitKey` changed it) or it was asked to close. In a page it is always false; the loop that reads it runs once a frame there.
  - returns: True once the window should close.
- `IsWindowReady`: Returns whether the window is open.
  - returns: True after `InitWindow`.
- `IsWindowResized`: Returns whether the window changed size since the last frame.
  - returns: True for the frame after a resize.
- `SetWindowTitle`: Sets the window's title.
  - `title`: The title.
- `IsWindowFullscreen`: Returns whether the window is fullscreen, not a borderless window (`ToggleBorderlessWindowedAsync`), as raylib tells them apart. In a page it tells whether the canvas is.
  - returns: True while it is.
- `IsWindowHidden`: Returns whether the program hid the window (`FLAG_WINDOW_HIDDEN`). In a page it tells whether the canvas is hidden.
  - returns: True while it is.
- `IsWindowMinimized`: Returns whether the player can't see the window: minimized, or in a page its tab in the background.
  - returns: True while it is.
- `IsWindowMaximized`: Returns whether the window is maximized. It is false in a page.
  - returns: True while it is.
- `SetWindowIcon`: Sets the window's icon; in a page, the page's icon. As raylib's, the image must be `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `image`: The icon.
- `SetWindowIcons`: Sets the window's icon from several sizes: the largest is used, as the desktop scales it. Each must be `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `images`: The icons.
  - `count`: How many of them.
- `GetMonitorRefreshRate`: Returns how many times a second a monitor shows a new picture.
  - `monitor`: The monitor.
  - returns: The refresh rate in hertz, or 0 in a page, which can't tell.
- `OpenURL`: Opens a URL in the system's browser; in a page, a new tab, at the next press when there is no fresh one. As raylib 6.2's, a URL with `'` or `"` is refused as possibly malicious. helix-raylib opens only http, https and mailto URLs, where raylib 5.5 opens any and 6.2 only http and https.
  - `url`: The URL.
- `IsWindowFocused`: Returns whether the window has the keyboard.
  - returns: True while it has.
- `GetWindowPosition`: Returns the window's place on the desktop.
  - returns: Its left and top edges, in pixels.
- `GetWindowScaleDPI`: Returns how many of the display's pixels a pixel drawn takes, across and down: 2 on most phones and high-density displays.
  - returns: The scale.

  It is the display's scale whatever the flags, as raylib 5.5's desktop build has it and 6.2's web build; raylib 6.2's desktop build gives 1 unless `FLAG_WINDOW_HIGHDPI` is set and the window isn't fullscreen, and 5.5's web build always 1.
- `GetMonitorCount`: Returns the number of monitors. A page sees one.
  - returns: The count, at least 1.
- `GetCurrentMonitor`: Returns the monitor holding the window.
  - returns: Its index.
- `GetMonitorPosition`: Returns a monitor's top-left corner on the desktop.
  - `monitor`: The monitor.
  - returns: The corner, in pixels.
- `GetMonitorWidth`: Returns a monitor's width.
  - `monitor`: The monitor.
  - returns: The width, in pixels.
- `GetMonitorHeight`: Returns a monitor's height.
  - `monitor`: The monitor.
  - returns: The height, in pixels.
- `GetMonitorName`: Returns a monitor's name.
  - `monitor`: The monitor.
  - returns: The name.
- `GetScreenWidth`: Returns the screen's width, in the pixels drawing is in.
  - returns: The width.
- `GetScreenHeight`: Returns the screen's height, in the pixels drawing is in.
  - returns: The height.
- `GetRenderWidth`: Returns the framebuffer's width, in the display's pixels.
  - returns: The width.
- `GetRenderHeight`: Returns the framebuffer's height, in the display's pixels.
  - returns: The height.
- `SetConfigFlags`: Sets flags for the window before `InitWindow` (`FLAG_*`). `FLAG_MSAA_4X_HINT` asks for 4 samples a pixel, and `FLAG_VSYNC_HINT` for frames shown at the display's refresh; without it, frames natively show as soon as they are drawn, as raylib's do, while a page's always follow the display. The window is resizable here whatever they say.
  - `flags`: The flags, or'd together.
- `SetWindowState`: Sets flags on the open window (`FLAG_*`). A window here is resizable whatever they say, and the others aren't read.
  - `flags`: The flags, or'd together.
- `ClearWindowState`: Clears flags on the open window (`FLAG_*`).
  - `flags`: The flags, or'd together.
- `IsWindowState`: Returns whether flags are set on the window. `FLAG_FULLSCREEN_MODE` and `FLAG_BORDERLESS_WINDOWED_MODE` say what the window is now, as `IsWindowFullscreen` does.
  - `flag`: The flags, or'd together.
  - returns: True when all of them are.
- `SetTargetFPS`: Sets the most frames a second, as raylib's `EndDrawing` waits out the rest of each frame. Natively it waits; in a page, where frames follow the display's refresh, a frame is skipped until it is time, so a rate above the display's changes nothing.
  - `fps`: The frames a second, or 0 for no limit.
- `GetFPS`: Returns the frames a second, averaged over the last half second or so.
  - returns: The frames a second.
- `GetFrameTime`: Returns the seconds the last frame took.
  - returns: The seconds.
- `WaitTime`: Stops the program for a time, drawing nothing and reading no input until it ends. In a page it spins, as raylib's web build does, so the page doesn't respond meanwhile.
  - `seconds`: How long.
- `GetTime`: Returns the seconds since `InitWindow`.
  - returns: The seconds.
- `SetExitKey`: Sets the key that closes the window natively, or `KEY_NULL` for none. It is Escape until set.
  - `key`: The key.
- `BeginDrawing`: Begins a frame's drawing.
- `EndDrawing`: Ends a frame's drawing: shows it, waits out the rest of the frame natively (`SetTargetFPS`), then reads the next frame's input. Built with `-D helix-raylib-custom-frame-control`, raylib's `SUPPORT_CUSTOM_FRAME_CONTROL`, it only ends the drawing: `SwapScreenBuffer` shows the frame, `WaitTime` waits and `PollInputEvents` reads the input, as the program calls them.
- `SwapScreenBuffer`: Shows the frame `EndDrawing` ended, for a program built with `-D helix-raylib-custom-frame-control`, raylib's `SUPPORT_CUSTOM_FRAME_CONTROL`. Without it, `EndDrawing` has shown the frame already and this does nothing. A frame not shown by the next `EndDrawing` is shown then. In a page the browser shows a frame when the loop's body returns, as raylib's web build has it, so the frame shows then however this is called.
- `PollInputEvents`: Reads the input that came since the last read: each key's, button's and finger's state, and the window's events. `EndDrawing` reads it already unless the program is built with `-D helix-raylib-custom-frame-control`, raylib's `SUPPORT_CUSTOM_FRAME_CONTROL`; a second read, as raylib's, starts a new frame of input, so what was pressed before it reads as held. With `EnableEventWaiting`, it waits for an event natively first.
- `EnableEventWaiting`: Makes each frame natively wait for an event before the next is read, as raylib's: a key, a mouse button, the mouse moved, the window changed, from a device the program reads. The program draws nothing meanwhile and uses little time; the platform and helix-raylib's async loads are still served, so a load answers while it waits and is drawn after the next event. In a page it changes nothing, as raylib's web build doesn't wait: the browser runs each frame.
- `DisableEventWaiting`: Makes each frame read the events there are and go on, as it does until `EnableEventWaiting`.
- `ClearBackground`: Clears the frame to a color, dropping what was drawn before it.
  - `color`: The color.
- `GetRandomValue`: Returns a random whole number from min to max, both included, from raylib's generator (xoshiro128**, helix-math's `Random`), so a seed gives the numbers raylib's gives.
  - `min`: The least.
  - `max`: The most.
  - returns: The number.
- `SetRandomSeed`: Seeds `GetRandomValue` and `LoadRandomSequence`, as raylib's: helix-math's `Random` is raylib's generator, so the numbers repeat from the same seed and are raylib's.
  - `seed`: The seed, read as unsigned.
- `LoadRandomSequence`: Returns numbers from min to max, both included, none twice, from `GetRandomValue`'s generator, as raylib's: the same numbers raylib's gives for a seed. As raylib's, min and max aren't swapped: when min is more, the numbers run from min up by the range's size.
  - `count`: How many.
  - `min`: The least.
  - `max`: The most.
  - returns: The numbers, or null when there are fewer than count in the range.
- `UnloadRandomSequence`: Frees numbers `LoadRandomSequence` gave. There is nothing to free here.
  - `sequence`: The numbers.
- `IsKeyPressed`: Returns whether a key went down this frame.
  - `key`: The key (`KEY_*`).
  - returns: True for that frame alone.
- `IsKeyDown`: Returns whether a key is held.
  - `key`: The key (`KEY_*`).
  - returns: True while it is down.
- `IsKeyReleased`: Returns whether a key went up this frame.
  - `key`: The key (`KEY_*`).
  - returns: True for that frame alone.
- `IsKeyUp`: Returns whether a key isn't held.
  - `key`: The key (`KEY_*`).
  - returns: True while it is up.
- `GetKeyPressed`: Returns the next key pressed this frame, each once; call it until it returns `KEY_NULL`.
  - returns: The key (`KEY_*`), or `KEY_NULL` when no more were pressed.
- `IsKeyPressedRepeat`: Returns whether the OS repeated a held key this frame, as it does after a moment, at its own rate.
  - `key`: The key (`KEY_*`).
  - returns: True for the frames it repeated.
- `GetCharPressed`: Returns the next character typed this frame, each once; call it until it returns 0. Typed text is read from the first call on, so on a phone its keyboard shows from then.
  - returns: The character's codepoint, or 0 when no more were typed.
- `IsMouseButtonPressed`: Returns whether a mouse button went down this frame. A finger touching counts as the left button, as in raylib.
  - `button`: The button (`MOUSE_BUTTON_*`).
  - returns: True for that frame alone.
- `IsMouseButtonDown`: Returns whether a mouse button is held. A finger down counts as the left button.
  - `button`: The button (`MOUSE_BUTTON_*`).
  - returns: True while it is down.
- `IsMouseButtonReleased`: Returns whether a mouse button went up this frame. The last finger lifting counts as the left button.
  - `button`: The button (`MOUSE_BUTTON_*`).
  - returns: True for that frame alone.
- `IsMouseButtonUp`: Returns whether a mouse button isn't held.
  - `button`: The button (`MOUSE_BUTTON_*`).
  - returns: True while it is up.
- `GetMouseX`: Returns the mouse's x, in the screen's pixels; the first finger's while one is down.
  - returns: The x.
- `GetMouseY`: Returns the mouse's y, in the screen's pixels; the first finger's while one is down.
  - returns: The y.
- `GetMousePosition`: Returns the mouse's position, in the screen's pixels, `SetMouseOffset`'s offset added and `SetMouseScale`'s scale applied; the first finger's while one is down.
  - returns: The position.
- `SetMousePosition`: Moves the mouse to a place on the screen. As raylib 6.2's, where the mouse was isn't forgotten: `GetMouseDelta` this frame includes the move. Where the cursor can't be moved (always in a page, and natively where the system refuses, as Wayland does), the position reads there until the mouse moves, and a warning says why, once a run for each reason.
  - `x`: The place across, in the screen's pixels.
  - `y`: The place down.
- `SetMouseOffset`: Sets what `GetMousePosition` adds to the mouse's position, before its scale.
  - `offsetX`: Added across.
  - `offsetY`: Added down.
- `SetMouseScale`: Sets what `GetMousePosition` multiplies the mouse's position by, after its offset.
  - `scaleX`: The scale across.
  - `scaleY`: The scale down.
- `GetMouseWheelMoveV`: Returns how far the wheel turned this frame, in both directions: right and away from the player are positive.
  - returns: The notches.
- `ShowCursor`: Shows the cursor.
- `HideCursor`: Hides the cursor over the window.
- `IsCursorHidden`: Returns whether the cursor is hidden, by `HideCursor` or `DisableCursor`.
  - returns: True while it is.
- `IsCursorOnScreen`: Returns whether the mouse is over the window.
  - returns: True from its first move over the window until it leaves.
- `SetMouseCursor`: Sets the cursor's shape: the system's own cursor of each kind.
  - `cursor`: The shape (`MOUSE_CURSOR_*`); `MOUSE_CURSOR_DEFAULT` and `MOUSE_CURSOR_ARROW` are both the arrow.
- `GetMouseWheelMove`: Returns how far the wheel turned this frame, the larger of its two directions; away from the player is positive.
  - returns: The notches.
- `GetTouchPointCount`: Returns the number of fingers down.
  - returns: The count.
- `GetTouchPosition`: Returns a finger's position, in the screen's pixels. While no finger is down, the first is where the mouse is, as raylib's.
  - `index`: Which finger, 0 for the first down.
  - returns: The position, or (0, 0) when fewer are down.
- `GetTouchPointId`: Returns a finger's id, which stays the same while it is down.
  - `index`: Which finger, 0 for the first down.
  - returns: The id, or -1 when fewer are down.
- `GetTouchX`: Returns the first finger's x, in the screen's pixels: the mouse's while no finger is down.
  - returns: The x.
- `GetTouchY`: Returns the first finger's y, in the screen's pixels: the mouse's while no finger is down.
  - returns: The y.
- `SetGesturesEnabled`: Sets which gestures are detected; all of them until it is called.
  - `flags`: The gestures (`GESTURE_*`), or'd together.
- `IsGestureDetected`: Returns whether a gesture is the one detected now. A mouse button counts as a finger, as in raylib. A tap or double tap lasts a frame, then becomes a hold; a swipe lasts a frame.
  - `gesture`: The gesture (`GESTURE_*`).
  - returns: True while it is the gesture, and enabled.
- `GetGestureDetected`: Returns the gesture detected now.
  - returns: The gesture (`GESTURE_*`), or `GESTURE_NONE` when it isn't enabled.
- `GetGestureHoldDuration`: Returns how long the hold has lasted.
  - returns: The seconds, or 0 when the gesture isn't `GESTURE_HOLD`.
- `GetGestureDragVector`: Returns the drag, from where the finger landed to where it is, in fractions of the screen.
  - returns: The vector.
- `GetGestureDragAngle`: Returns the last swipe's angle.
  - returns: The degrees, counterclockwise from right.
- `GetGesturePinchVector`: Returns the pinch, from the first finger to the second, in fractions of the screen.
  - returns: The vector.
- `GetGesturePinchAngle`: Returns the pinch's angle.
  - returns: The degrees, counterclockwise from right.
- `SetGamepadVibration`: Shakes a gamepad: its left motor is the heavy one, its right the light one, as raylib's. Shaking lasts at most 2 seconds, as raylib's. An empty slot is passed over, as raylib's. A pad that can't shake (one without motors, or any in a browser without vibration, as Firefox) doesn't, and a warning says so, once a run.
  - `gamepad`: The gamepad, 0 to 3.
  - `leftMotor`: The heavy motor's strength, 0 to 1.
  - `rightMotor`: The light motor's strength, 0 to 1.
  - `duration`: How long, in seconds.
- `SetGamepadMappings`: Adds mappings for pads the system doesn't know, in SDL's controller database format, as raylib's.
  - `mappings`: The mappings, one a line.
  - returns: How many were added or updated; 0 in a page, whose browser maps pads itself.
- `IsGamepadAvailable`: Returns whether a gamepad is connected.
  - `gamepad`: The gamepad, 0 to 3.
  - returns: True while one is connected there.
- `GetGamepadName`: Returns a gamepad's name.
  - `gamepad`: The gamepad, 0 to 3.
  - returns: Its name, or "" when none is connected.
- `IsGamepadButtonPressed`: Returns whether a gamepad's button went down this frame.
  - `gamepad`: The gamepad, 0 to 3.
  - `button`: The button (`GAMEPAD_BUTTON_*`).
  - returns: True for that frame alone.
- `IsGamepadButtonDown`: Returns whether a gamepad's button is held.
  - `gamepad`: The gamepad, 0 to 3.
  - `button`: The button (`GAMEPAD_BUTTON_*`).
  - returns: True while it is down.
- `IsGamepadButtonReleased`: Returns whether a gamepad's button went up this frame.
  - `gamepad`: The gamepad, 0 to 3.
  - `button`: The button (`GAMEPAD_BUTTON_*`).
  - returns: True for that frame alone.
- `IsGamepadButtonUp`: Returns whether a gamepad's button isn't held.
  - `gamepad`: The gamepad, 0 to 3.
  - `button`: The button (`GAMEPAD_BUTTON_*`).
  - returns: True while it is up.
- `GetGamepadButtonPressed`: Returns the last button held, as raylib polls them: gamepads 0 to 3, each's buttons in the browser's order in a page (the second triggers among them, the middle button never), else GLFW's (the middle button among them), then, as raylib 6.2's, the left second trigger and the right while its axis (`GetGamepadAxisMovement`) is over 0.1.
  - returns: The button (`GAMEPAD_BUTTON_*`), or `GAMEPAD_BUTTON_UNKNOWN` when none is held.
- `GetGamepadAxisCount`: Returns the number of axes a gamepad has.
  - `gamepad`: The gamepad, 0 to 3.
  - returns: 6 while one is connected, else 0.
- `GetGamepadAxisMovement`: Returns how far a gamepad's axis is pushed, with no dead zone. A stick is -1 to 1, down and right positive; a trigger is -1 released to 1 pulled, as raylib's are.
  - `gamepad`: The gamepad, 0 to 3.
  - `axis`: The axis (`GAMEPAD_AXIS_*`).
  - returns: The value.
- `UnloadFileText`: Frees text `LoadFileTextAsync` gave. There is nothing to free here.
  - `text`: The text.
- `UnloadFileData`: Frees bytes `LoadFileDataAsync` gave. There is nothing to free here.
  - `data`: The bytes.
- `GetWorkingDirectory`: Returns the working directory: natively the process's, where `TakeScreenshot` writes; in a page ".", the page's own directory. helix-raylib's loads don't read from it: a file's name is under the program's files wherever it is (`GetApplicationDirectory`).
  - returns: The directory, without a slash at its end.
- `GetApplicationDirectory`: Returns the directory the program's files are read from, as raylib programs name a file from their application's directory: natively `-D helix-raylib-native-root` from the executable's directory (`../web` unless set), in a page "./", the page's own. A load given a path in it reads the file it names, so `GetApplicationDirectory() + "resources/a.png"` loads "resources/a.png".
  - returns: The directory, with a slash at its end.
- `ChangeDirectory`: Changes the working directory, natively the process's, as raylib's: `TakeScreenshot` writes to it from then on. helix-raylib's loads are unchanged, reading the program's files wherever it is. A page has no working directory of its own: there, only "." or the page's directory (`GetApplicationDirectory`) succeeds, changing nothing. A failure is logged, as raylib's is.
  - `dir`: The directory.
  - returns: True when the working directory is it now.
- `IsFileExtension`: Returns whether a file name ends in one of some extensions, ignoring the case of A to Z, as raylib 6.2's.
  - `fileName`: The file name.
  - `ext`: The extensions, `;` between them: ".png;.jpg".
  - returns: True when its extension, from its last dot, is one of them.

  Up to 15 characters of the file's extension are compared, and the list's first 32 extensions. An extension in the list without its dot matches as well ("png" as ".png").
- `GetFileExtension`: Returns a file name's extension, from its last dot: "file.tar.gz" gives ".gz".
  - `fileName`: The file name, or a path.
  - returns: The extension with its dot, or null when there is no dot or the name starts with its only one.
- `GetFileName`: Returns a path's file name: what follows its last `/` or `\`.
  - `filePath`: The path.
  - returns: The file name with its extension; the path itself when it has no slash.
- `GetFileNameWithoutExt`: Returns a path's file name without its extension: up to its last dot, unless that dot is its first character.
  - `filePath`: The path.
  - returns: The file name; "" for null.
- `GetDirectoryPath`: Returns the directory of a path: up to its last `/` or `\`. A relative path's starts "./", as raylib's does: "dir/file.png" gives "./dir", "file.png" gives "./", and "/file.png" gives "/".
  - `filePath`: The path.
  - returns: The directory, without a slash at its end.
- `GetPrevDirectoryPath`: Returns the directory a path is in, as raylib 6.2's: up to its last `/` or `\` but one at its end, keeping a root's ("/", "C:\").
  - `dirPath`: The path.
  - returns: The directory above it; "" when there is none.

  "/a/b/" gives "/a", "/a" gives "/" and "abc" gives "". raylib 6.2 also takes a path naming a file to its directory's parent; a file can't be looked for without waiting here, so every path is taken as a directory's.
- `IsFileNameValid`: Returns whether a file name could name a file on any system: none of `< > : " / \ | ? *` or a control character, and not only dots.
  - `fileName`: The file name, without a directory.
  - returns: True when it could; true for null or "", as raylib's is.
- `MakeDirectory`: Makes a directory. There is nothing to make: a directory is there once a file is written under it, so this succeeds for any path that could name one.
  - `dirPath`: The directory.
  - returns: 0, success; 1 for null or "", as raylib 5.5's; -1, as raylib 6.2's for a directory not made, for a path that can't name one.
- `UnloadDirectoryFiles`: Frees a listing `LoadDirectoryFilesAsync` or `LoadDirectoryFilesExAsync` gave. There is nothing to free here, and the list is unchanged.
  - `files`: The listing.
- `IsFileDropped`: Returns whether files were dropped on the window, natively from the desktop and in a page on the canvas. It stays true until `UnloadDroppedFiles`, and a new drop's files replace the last one's, as raylib's do. A dropped file counts once its bytes are read, natively in the frame after it is dropped, in a page a frame or so after.
  - returns: True while dropped files are held.
- `LoadDroppedFiles`: Returns the paths of the files last dropped. Each is helix-raylib's own, `helix-raylib-dropped/<n>/<name>`, which every load reads, as `LoadTextureAsync(path)`: the file's name is its last part, a character a path can't hold made `_`. A directory dropped isn't listed.
  - returns: The paths, `count` of them; `capacity` is 0, as raylib's.
- `UnloadDroppedFiles`: Lets go of the list of files last dropped, so `IsFileDropped` is false until the next drop. The files stay, as a dropped file stays on raylib's disk: a load of one of their paths, started before or after, reads it until the next drop's files replace them.
  - `files`: The list `LoadDroppedFiles` gave; one of no files does nothing, as raylib's.
- `CompressData`: Compresses bytes as raylib's `CompressData` does, byte for byte: raw DEFLATE (no zlib header), sdefl's level 8.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - `compDataSize`: Its first element is set to the compressed size.
  - returns: The compressed bytes.
- `DecompressData`: Returns DEFLATE data decompressed: a raw stream with no zlib header, as raylib's `CompressData` makes. Like raylib's, it gives at most 64 MB.
  - `compData`: The compressed bytes.
  - `compDataSize`: How many of them.
  - `dataSize`: Its first element is set to how many bytes it gives.
  - returns: The bytes. Data that isn't DEFLATE, or stops short, gives what was read before it, perhaps nothing, and a warning.
- `EncodeDataBase64`: Returns some bytes as Base64 text, padded with `=` to a multiple of 4 characters.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - `outputSize`: Its first element is set to the text's length.
  - returns: The text.
- `DecodeDataBase64`: Returns the bytes of Base64 text, as raylib 6.2 decodes it: the text runs to a zero byte or the end, and is read 4 characters at a time, a character that isn't Base64's reading as 0. Text whose length isn't a multiple of 4 warns and is read up to its last 4 characters.
  - `data`: The text's bytes.
  - `outputSize`: Its first element is set to how many bytes it gives: 3 for every 4 characters, less one for each `=` at the end.
  - returns: The bytes.
- `ComputeCRC32`: Returns the CRC-32 of some bytes, as zlib and PNG compute it.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - returns: Its 32 bits; one above 0x7fffffff is negative.
- `ComputeMD5`: Returns the MD5 hash of some bytes.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - returns: Its 4 words, as raylib gives them: each read from 4 bytes of the hash, the first the lowest, and one above 0x7fffffff is negative.
- `ComputeSHA1`: Returns the SHA-1 hash of some bytes, as raylib 6.2 computes it: standard SHA-1 (raylib 5.5's padding held only the lowest byte of the length in bits, so from 32 bytes on it wasn't).
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - returns: Its 5 words, the first the hash's first 4 bytes, the highest first; one above 0x7fffffff is negative.
- `SetLoadFileDataCallback`: Reads files through the program from now on: every load raylib makes of a file (textures, models, sounds, music, data) asks it first, and a file it doesn't have (null) is read as it would be. In a page, a texture's or model's images still decode only asynchronously, so `LoadTextureAsync` and `LoadModelAsync` load those it gives.
  - `callback`: Returns a file's bytes, or null; null for none.
- `SetSaveFileDataCallback`: Writes files through the program from now on (`SaveFileData`).
  - `callback`: Writes a file's bytes, returning whether it did; null for none.
- `SetLoadFileTextCallback`: Reads text files through the program from now on (`LoadFileTextAsync`).
  - `callback`: Returns a file's text, or null; null for none.
- `SetSaveFileTextCallback`: Writes text files through the program from now on (`SaveFileText`).
  - `callback`: Writes a file's text, returning whether it did; null for none.
- `UnloadAutomationEventList`: Frees a list's events. There is nothing to free here, and the list is unchanged.
  - `list`: The list.
- `SetAutomationEventList`: Sets the list `StartAutomationEventRecording` records into. From the first call, the input functions read the input as automation keeps it, so an event `PlayAutomationEvent` plays reads as real input.
  - `list`: The list, made by `LoadAutomationEventList(null)` or `LoadAutomationEventListAsync`.
- `SetAutomationEventBaseFrame`: Sets the frame the next event recorded is stamped with; each frame after counts up from it. Until set, it is the frames since `InitWindow`.
  - `frame`: The frame.
- `StartAutomationEventRecording`: Starts recording into the list `SetAutomationEventList` set: as each frame ends, before the next frame's input is read, every key, mouse button and finger held, the mouse's moves, the wheel's and, as raylib 6.2's, the fingers', gamepads' buttons held and axes off rest, and the gesture, as raylib records them, each logged. A full list (16384 events) records no more.
- `StopAutomationEventRecording`: Stops recording.
- `PlayAutomationEvent`: Plays an event, as raylib's: input becomes the input the functions read now, as it would from the devices, and stays until they change it or another event does; a window event or an action is done (`WINDOW_CLOSE` makes `WindowShouldClose` true). Nothing is played while recording. As raylib's, the program plays each event in its frame, after the frame's input is read: a key held is an event every frame, so a frame's events are played together.
  - `event`: The event.
- `TraceLog`: Writes a message to the log, when its level is at least `SetTraceLogLevel`'s. raylib formats its arguments as printf does; here the text is written as it is (Haxe's string interpolation builds it).
  - `logLevel`: The level (`LOG_*`).
  - `text`: The message.
- `SetTraceLogLevel`: Sets the least level the log writes; `LOG_INFO` until set.
  - `logLevel`: The level (`LOG_*`).
- `SetTraceLogCallback`: Writes the log through the program from now on, helix-raylib's own messages among it.
  - `callback`: Receives each message's level and text; null for helix-raylib's own log.
- `BeginMode2D`: Draws through a 2D camera until `EndMode2D`.
  - `camera`: The camera.
- `EndMode2D`: Goes back to drawing in the screen's pixels.
- `GetCameraMatrix2D`: Returns a 2D camera's transform, from the world to the screen.
  - `camera`: The camera.
  - returns: The matrix.
- `GetWorldToScreen2D`: Returns where a point in a 2D camera's world is on the screen.
  - `position`: The point.
  - `camera`: The camera.
  - returns: The screen position.
- `GetScreenToWorld2D`: Returns where a screen position is in a 2D camera's world.
  - `position`: The screen position.
  - `camera`: The camera.
  - returns: The point; NaN at zoom 0, as raylib's inverse of a matrix with none gives.
- `BeginMode3D`: Draws in 3D through a camera until `EndMode3D`, testing depth (rlgl's `rlEnableDepthTest`).
  - `camera`: The camera.
- `EndMode3D`: Goes back to drawing in 2D, in the screen's pixels, without testing depth.
- `UpdateCamera`: Moves a camera as one of raylib's modes does, by the keyboard, the mouse and the first gamepad, as rcamera's `UpdateCamera`.
  - `camera`: The camera, changed.
  - `mode`: The mode (`CAMERA_*`).

  `CAMERA_ORBITAL` turns it about its target, half a radian a second. `CAMERA_FREE`, `CAMERA_FIRST_PERSON` and `CAMERA_THIRD_PERSON` turn it by the mouse, the right stick and the arrow keys (Q and E roll it), its look stopping short of straight up and down, and move it by WASD and the left stick, 5.4 units a second; first and third person along the ground, third person turning about its target. `CAMERA_FREE` also moves up and down by space and left control, and pans while the middle button is held. `CAMERA_FREE`, `CAMERA_ORBITAL` and `CAMERA_THIRD_PERSON` move toward the target by the wheel and the keypad's plus and minus. `CAMERA_CUSTOM` leaves it.
- `UpdateCameraPro`: Moves and turns a camera by amounts, as raylib's rcamera does: it pitches (looking no further up or down than straight), yaws and rolls about its own position, then moves forward and right along the ground and up along its up direction, then toward its target, the distance kept above 0.
  - `camera`: The camera, changed.
  - `movement`: The distances it moves: forward (x), right (y) and up (z), in world units.
  - `rotation`: The angles it turns: yaw to the right (x), pitch down (y) and roll (z), in degrees.
  - `zoom`: How much further from its target it moves, in world units; a negative zoom moves it closer.
- `GetCameraMatrix`: Returns a camera's view, as `BeginMode3D` uses it.
  - `camera`: The camera.
  - returns: The matrix.
- `GetScreenToWorldRay`: Returns the ray from a camera through a screen position, as raylib's picking uses it.
  - `position`: The screen position.
  - `camera`: The camera.
  - returns: The ray.
- `GetScreenToWorldRayEx`: Returns the ray from a camera through a position in a view of a size, such as a render texture's.
  - `position`: The position in the view.
  - `camera`: The camera.
  - `width`: The view's width.
  - `height`: The view's height.
  - returns: The ray.
- `GetMouseRay`: Returns the ray from a camera through a screen position: raylib's old name for `GetScreenToWorldRay`.
  - `position`: The screen position.
  - `camera`: The camera.
  - returns: The ray.
- `GetWorldToScreen`: Returns where a point in the world is on the screen.
  - `position`: The point.
  - `camera`: The camera.
  - returns: The screen position.
- `GetWorldToScreenEx`: Returns where a point in the world is in a view of a size.
  - `position`: The point.
  - `camera`: The camera.
  - `width`: The view's width.
  - `height`: The view's height.
  - returns: The position in the view; infinite or NaN for a point level with a perspective camera's position, as raylib's is.
- `GetMouseDelta`: Returns how far the mouse moved since the last frame, in the screen's pixels times the mouse's scale (`SetMouseScale`), as raylib 6.2's. A `SetMousePosition` this frame is part of it.
  - returns: The movement.
- `BeginVrStereoMode`: Starts drawing for both eyes of a head-mounted display: stereo rendering on (`rlEnableStereoRender`) with the config's projections and view offsets. Until `EndVrStereoMode`, each flush of the batch and each mesh is drawn twice, the left half of what is drawn into for the first eye and the right half for the second; `BeginMode3D`'s projection is replaced by each eye's. raylib's VR simulator draws the eyes into a render texture, then draws it to the screen through a distortion shader.
  - `config`: The config, from `LoadVrStereoConfig`.
- `EndVrStereoMode`: Stops drawing for both eyes (`rlDisableStereoRender`), for the next flush of the batch and the next mesh drawn: shapes drawn in stereo and not flushed yet (`EndMode3D` flushes them) are drawn once.
- `LoadVrStereoConfig`: Returns the stereo config of a head-mounted display, as raylib 5.5 computes it: each eye's projection, from the field of view the lenses' distortion widens, shifted by the lenses' offset from the eyes' halves of the screen, between the clip planes (`rlSetClipPlanes`); each eye's view offset, half the interpupillary distance to its side, 0.075 up and 0.045 forward; and the lens and screen centers and scales a distortion shader reads (raylib's `distortion330.fs`).
  - `device`: The display's parameters.
  - returns: The config.
- `UnloadVrStereoConfig`: Frees a stereo config, which holds nothing to free, as raylib's: it logs that, as raylib 5.5 does.
  - `config`: The config.
- `IsShaderValid`: Returns whether a shader was made.
  - `shader`: The shader.
  - returns: True when it was.
- `UnloadShader`: Lets go of the program's hold on a shader (docs/DECISIONS.md 25), its id set to 0: the shader is freed when no material holds it too, else when the last material holding it lets go. Given a material's shader (`material.shader`), it lets go of one hold and leaves the material drawing with it while anything holds it. The default shader stays.
  - `shader`: The shader.
- `GetShaderLocation`: Returns the location of a shader's uniform or texture, by its name.
  - `shader`: The shader.
  - `uniformName`: The name.
  - returns: Its location, or -1 when the shader doesn't declare it.
- `GetShaderLocationAttrib`: Returns the location of a shader's attribute, by its name.
  - `shader`: The shader.
  - `attribName`: The name.
  - returns: Its location, or -1 when the shader doesn't declare it.
- `SetShaderValue`: Sets a shader's uniform, for the models drawn after it and the shapes in rlgl's batch when it is next drawn, as raylib's: shapes drawn before it but not yet flushed (`BeginShaderMode`, `EndShaderMode`, a mode changing, `rlDrawRenderBatchActive`) take it too. A texture's location takes the texture unit its sampler reads, as GL's: `DrawMesh` binds there the material's map of that index (raylib's skybox sets its `samplerCube` to `MATERIAL_MAP_CUBEMAP`).
  - `shader`: The shader.
  - `locIndex`: The uniform's location.
  - `value`: The value: a number, an array of numbers, or a `Vector2`, `Vector3`, `Vector4` or `Color`.
  - `uniformType`: Its type (`SHADER_UNIFORM_*`).
- `SetShaderValueV`: Sets elements of a shader's array uniform, for the draws after it.
  - `shader`: The shader.
  - `locIndex`: The uniform's location.
  - `value`: The values, in order.
  - `uniformType`: Each element's type (`SHADER_UNIFORM_*`).
  - `count`: The elements set.
- `SetShaderValueMatrix`: Sets a shader's matrix uniform, for the draws after it.
  - `shader`: The shader.
  - `locIndex`: The uniform's location.
  - `mat`: The matrix.
- `SetShaderValueTexture`: Sets a shader's texture, for the draws after it: a `Texture2D` at a `sampler2D`, or a cubemap (`LoadTextureCubemap`) at a `samplerCube`. A texture at a sampler of the other kind binds nothing. raylib 5.5's binds every texture it is given as a 2D texture, so a cubemap given it reads as black there; here it is bound.
  - `shader`: The shader.
  - `locIndex`: The texture's location.
  - `texture`: The texture.
- `BeginShaderMode`: Draws shapes, text and textures with a shader until `EndShaderMode`.
  - `shader`: The shader.
- `EndShaderMode`: Goes back to the default shader.
- `BeginBlendMode`: Blends what is drawn until `EndBlendMode` another way, as rlgl sets GL's blending: `BLEND_ALPHA` (alpha blended by the same factors as the color), `BLEND_ADDITIVE`, `BLEND_MULTIPLIED`, `BLEND_ADD_COLORS`, `BLEND_SUBTRACT_COLORS` and `BLEND_ALPHA_PREMULTIPLY`; `BLEND_CUSTOM` and `BLEND_CUSTOM_SEPARATE` take the factors `rlSetBlendFactors` and `rlSetBlendFactorsSeparate` last set. The batch is drawn first when the mode changes, or when a custom mode is set again after its factors changed; otherwise nothing happens. A mode raylib doesn't have changes nothing but the mode remembered.
  - `mode`: The mode (`BLEND_*`).
- `EndBlendMode`: Goes back to blending by alpha, as `BeginBlendMode(BLEND_ALPHA)` does.
- `BeginScissorMode`: Draws only within a rectangle of the screen, or of the render texture drawn into, until `EndScissorMode`.
  - `x`: The left edge, in pixels.
  - `y`: The top edge, in pixels.
  - `width`: The width.
  - `height`: The height.
- `EndScissorMode`: Draws everywhere again.

### rshapes: 2D shapes and collisions

```haxe
static function SetShapesTexture(texture:Texture2D, source:Rectangle):Void
static function GetShapesTexture():Texture2D
static function GetShapesTextureRectangle():Rectangle
static function DrawPixel(posX:Int, posY:Int, color:Color):Void
static function DrawPixelV(position:Vector2, color:Color):Void
static function DrawLine(startPosX:Int, startPosY:Int, endPosX:Int, endPosY:Int, color:Color):Void
static function DrawLineV(startPos:Vector2, endPos:Vector2, color:Color):Void
static function DrawLineEx(startPos:Vector2, endPos:Vector2, thick:Float, color:Color):Void
static function DrawLineStrip(points:Array<Vector2>, pointCount:Int, color:Color):Void
static function DrawLineBezier(startPos:Vector2, endPos:Vector2, thick:Float, color:Color):Void
static function DrawCircle(centerX:Int, centerY:Int, radius:Float, color:Color):Void
static function DrawCircleV(center:Vector2, radius:Float, color:Color):Void
static function DrawCircleSector(center:Vector2, radius:Float, startAngle:Float, endAngle:Float, segments:Int, color:Color):Void
static function DrawCircleSectorLines(center:Vector2, radius:Float, startAngle:Float, endAngle:Float, segments:Int, color:Color):Void
static function DrawCircleGradient(centerX:Int, centerY:Int, radius:Float, inner:Color, outer:Color):Void
static function DrawCircleLines(centerX:Int, centerY:Int, radius:Float, color:Color):Void
static function DrawCircleLinesV(center:Vector2, radius:Float, color:Color):Void
static function DrawEllipse(centerX:Int, centerY:Int, radiusH:Float, radiusV:Float, color:Color):Void
static function DrawEllipseLines(centerX:Int, centerY:Int, radiusH:Float, radiusV:Float, color:Color):Void
static function DrawRing(center:Vector2, innerRadius:Float, outerRadius:Float, startAngle:Float, endAngle:Float, segments:Int, color:Color):Void
static function DrawRingLines(center:Vector2, innerRadius:Float, outerRadius:Float, startAngle:Float, endAngle:Float, segments:Int, color:Color):Void
static function DrawRectangle(posX:Int, posY:Int, width:Int, height:Int, color:Color):Void
static function DrawRectangleV(position:Vector2, size:Vector2, color:Color):Void
static function DrawRectangleRec(rec:Rectangle, color:Color):Void
static function DrawRectanglePro(rec:Rectangle, origin:Vector2, rotation:Float, color:Color):Void
static function DrawRectangleGradientV(posX:Int, posY:Int, width:Int, height:Int, top:Color, bottom:Color):Void
static function DrawRectangleGradientH(posX:Int, posY:Int, width:Int, height:Int, left:Color, right:Color):Void
static function DrawRectangleGradientEx(rec:Rectangle, topLeft:Color, bottomLeft:Color, topRight:Color, bottomRight:Color):Void
static function DrawRectangleLines(posX:Int, posY:Int, width:Int, height:Int, color:Color):Void
static function DrawRectangleLinesEx(rec:Rectangle, lineThick:Float, color:Color):Void
static function DrawRectangleRounded(rec:Rectangle, roundness:Float, segments:Int, color:Color):Void
static function DrawRectangleRoundedLines(rec:Rectangle, roundness:Float, segments:Int, color:Color):Void
static function DrawRectangleRoundedLinesEx(rec:Rectangle, roundness:Float, segments:Int, lineThick:Float, color:Color):Void
static function DrawTriangle(v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void
static function DrawTriangleLines(v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void
static function DrawTriangleFan(points:Array<Vector2>, pointCount:Int, color:Color):Void
static function DrawTriangleStrip(points:Array<Vector2>, pointCount:Int, color:Color):Void
static function DrawPoly(center:Vector2, sides:Int, radius:Float, rotation:Float, color:Color):Void
static function DrawPolyLines(center:Vector2, sides:Int, radius:Float, rotation:Float, color:Color):Void
static function DrawPolyLinesEx(center:Vector2, sides:Int, radius:Float, rotation:Float, lineThick:Float, color:Color):Void
static function DrawSplineLinear(points:Array<Vector2>, pointCount:Int, thick:Float, color:Color):Void
static function DrawSplineBasis(points:Array<Vector2>, pointCount:Int, thick:Float, color:Color):Void
static function DrawSplineCatmullRom(points:Array<Vector2>, pointCount:Int, thick:Float, color:Color):Void
static function DrawSplineBezierQuadratic(points:Array<Vector2>, pointCount:Int, thick:Float, color:Color):Void
static function DrawSplineBezierCubic(points:Array<Vector2>, pointCount:Int, thick:Float, color:Color):Void
static function DrawSplineSegmentLinear(p1:Vector2, p2:Vector2, thick:Float, color:Color):Void
static function DrawSplineSegmentBasis(p1:Vector2, p2:Vector2, p3:Vector2, p4:Vector2, thick:Float, color:Color):Void
static function DrawSplineSegmentCatmullRom(p1:Vector2, p2:Vector2, p3:Vector2, p4:Vector2, thick:Float, color:Color):Void
static function DrawSplineSegmentBezierQuadratic(p1:Vector2, c2:Vector2, p3:Vector2, thick:Float, color:Color):Void
static function DrawSplineSegmentBezierCubic(p1:Vector2, c2:Vector2, c3:Vector2, p4:Vector2, thick:Float, color:Color):Void
static function GetSplinePointLinear(startPos:Vector2, endPos:Vector2, t:Float):Vector2
static function GetSplinePointBasis(p1:Vector2, p2:Vector2, p3:Vector2, p4:Vector2, t:Float):Vector2
static function GetSplinePointCatmullRom(p1:Vector2, p2:Vector2, p3:Vector2, p4:Vector2, t:Float):Vector2
static function GetSplinePointBezierQuad(p1:Vector2, c2:Vector2, p3:Vector2, t:Float):Vector2
static function GetSplinePointBezierCubic(p1:Vector2, c2:Vector2, c3:Vector2, p4:Vector2, t:Float):Vector2
static function CheckCollisionRecs(rec1:Rectangle, rec2:Rectangle):Bool
static function CheckCollisionCircles(center1:Vector2, radius1:Float, center2:Vector2, radius2:Float):Bool
static function CheckCollisionCircleRec(center:Vector2, radius:Float, rec:Rectangle):Bool
static function CheckCollisionCircleLine(center:Vector2, radius:Float, p1:Vector2, p2:Vector2):Bool
static function CheckCollisionPointRec(point:Vector2, rec:Rectangle):Bool
static function CheckCollisionPointCircle(point:Vector2, center:Vector2, radius:Float):Bool
static function CheckCollisionPointTriangle(point:Vector2, p1:Vector2, p2:Vector2, p3:Vector2):Bool
static function CheckCollisionPointLine(point:Vector2, p1:Vector2, p2:Vector2, threshold:Int):Bool
static function CheckCollisionPointPoly(point:Vector2, points:Array<Vector2>, pointCount:Int):Bool
static function CheckCollisionLines(startPos1:Vector2, endPos1:Vector2, startPos2:Vector2, endPos2:Vector2, collisionPoint:Vector2):Bool
static function GetCollisionRec(rec1:Rectangle, rec2:Rectangle):Rectangle
```

- `SetShapesTexture`: Sets the texture and the part of it the filled shapes draw with, as one white pixel of a font's texture lets shapes and text share a draw. A texture with no id, or an empty rectangle, goes back to the white pixel shapes draw with at first.
  - `texture`: The texture.
  - `source`: The part of it, in pixels.
- `GetShapesTexture`: Returns the texture the filled shapes draw with: raylib's default texture, a white pixel, unless `SetShapesTexture` set another.
  - returns: The texture.
- `GetShapesTextureRectangle`: Returns the part of the shapes texture the filled shapes draw with.
  - returns: The rectangle, in pixels.
- `DrawPixel`: Draws one pixel.
  - `posX`: The x.
  - `posY`: The y.
  - `color`: The color.
- `DrawPixelV`: Draws one pixel.
  - `position`: The position.
  - `color`: The color.
- `DrawLine`: Draws a line one pixel wide.
  - `startPosX`: The start's x.
  - `startPosY`: The start's y.
  - `endPosX`: The end's x.
  - `endPosY`: The end's y.
  - `color`: The color.
- `DrawLineV`: Draws a line one pixel wide.
  - `startPos`: The start.
  - `endPos`: The end.
  - `color`: The color.
- `DrawLineEx`: Draws a line of a thickness.
  - `startPos`: The start.
  - `endPos`: The end.
  - `thick`: The thickness, in pixels; 0 or less draws nothing.
  - `color`: The color.
- `DrawLineStrip`: Draws lines one pixel wide from each point to the next.
  - `points`: The points.
  - `pointCount`: How many of them to draw through, 2 or more.
  - `color`: The color.
- `DrawLineBezier`: Draws a line of a thickness that eases in and out from start to end, as an S.
  - `startPos`: The start.
  - `endPos`: The end.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawCircle`: Draws a filled circle.
  - `centerX`: The center's x.
  - `centerY`: The center's y.
  - `radius`: The radius; 0 or less draws nothing.
  - `color`: The color.
- `DrawCircleV`: Draws a filled circle.
  - `center`: The center.
  - `radius`: The radius; 0 or less draws nothing.
  - `color`: The color.
- `DrawCircleSector`: Draws a filled slice of a circle, clockwise from one angle to another.
  - `center`: The center.
  - `radius`: The radius; 0 or less draws nothing.
  - `startAngle`: The angle it starts at, in degrees from the right.
  - `endAngle`: The angle it ends at; the same as the start draws nothing, and more than a turn past it draws one turn.
  - `segments`: How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
  - `color`: The color.
- `DrawCircleSectorLines`: Draws a slice of a circle's outline, one pixel wide, with lines from the center to its ends; a whole turn has none.
  - `center`: The center.
  - `radius`: The radius; 0 or less draws nothing.
  - `startAngle`: The angle it starts at, in degrees from the right.
  - `endAngle`: The angle it ends at; the same as the start draws nothing, and more than a turn past it draws one turn.
  - `segments`: How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
  - `color`: The color.
- `DrawCircleGradient`: Draws a filled circle that blends from one color at its center to another at its edge.
  - `centerX`: The center's x.
  - `centerY`: The center's y.
  - `radius`: The radius.
  - `inner`: The color at the center.
  - `outer`: The color at the edge.
- `DrawCircleLines`: Draws a circle's outline, one pixel wide.
  - `centerX`: The center's x.
  - `centerY`: The center's y.
  - `radius`: The radius.
  - `color`: The color.
- `DrawCircleLinesV`: Draws a circle's outline, one pixel wide.
  - `center`: The center.
  - `radius`: The radius.
  - `color`: The color.
- `DrawEllipse`: Draws a filled ellipse.
  - `centerX`: The center's x.
  - `centerY`: The center's y.
  - `radiusH`: The radius across.
  - `radiusV`: The radius up and down.
  - `color`: The color.
- `DrawEllipseLines`: Draws an ellipse's outline, one pixel wide.
  - `centerX`: The center's x.
  - `centerY`: The center's y.
  - `radiusH`: The radius across.
  - `radiusV`: The radius up and down.
  - `color`: The color.
- `DrawRing`: Draws a filled ring, or a slice of one, clockwise from one angle to another.
  - `center`: The center.
  - `innerRadius`: The radius of its hole; 0 or less draws a slice of a circle.
  - `outerRadius`: The radius of its edge; the larger of the two is taken as the edge, and an edge of 0 or less draws nothing.
  - `startAngle`: The angle it starts at, in degrees from the right.
  - `endAngle`: The angle it ends at; the same as the start draws nothing, and more than a turn past it draws one turn.
  - `segments`: How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
  - `color`: The color.
- `DrawRingLines`: Draws a ring's outline, or a slice of one, one pixel wide, with lines across its ends; a whole turn has none.
  - `center`: The center.
  - `innerRadius`: The radius of its hole; 0 or less draws a slice of a circle.
  - `outerRadius`: The radius of its edge; the larger of the two is taken as the edge, and an edge of 0 or less draws nothing.
  - `startAngle`: The angle it starts at, in degrees from the right.
  - `endAngle`: The angle it ends at; the same as the start draws nothing, and more than a turn past it draws one turn.
  - `segments`: How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
  - `color`: The color.
- `DrawRectangle`: Draws a filled rectangle.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `color`: The color.
- `DrawRectangleV`: Draws a filled rectangle.
  - `position`: The top-left corner.
  - `size`: The width and height.
  - `color`: The color.
- `DrawRectangleRec`: Draws a filled rectangle.
  - `rec`: The rectangle.
  - `color`: The color.
- `DrawRectanglePro`: Draws a filled rectangle turned about a point of it.
  - `rec`: The rectangle; its x and y are where the point is drawn.
  - `origin`: The point it turns about, from its top-left corner.
  - `rotation`: The turn, in degrees clockwise.
  - `color`: The color.
- `DrawRectangleGradientV`: Draws a filled rectangle that blends from one color at its top to another at its bottom.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `top`: The color at the top.
  - `bottom`: The color at the bottom.
- `DrawRectangleGradientH`: Draws a filled rectangle that blends from one color at its left to another at its right.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `left`: The color at the left.
  - `right`: The color at the right.
- `DrawRectangleGradientEx`: Draws a filled rectangle that blends between a color at each corner. As in raylib 5.5, `topRight` colors the bottom-right corner and `bottomRight` the top-right one.
  - `rec`: The rectangle.
  - `topLeft`: The top-left corner's color.
  - `bottomLeft`: The bottom-left corner's color.
  - `topRight`: The bottom-right corner's color.
  - `bottomRight`: The top-right corner's color.
- `DrawRectangleLines`: Draws a rectangle's outline, one pixel wide, its lines through the centers of its edge pixels.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `color`: The color.

  The lines are half a pixel inside the edges, by the matrix `rlPushMatrix` and its kin set (`rlGetMatrixTransform`); a 2D camera's zoom isn't counted, so under a camera they are half a unit inside.
- `DrawRectangleLinesEx`: Draws a rectangle's outline of a thickness, inside it, or outside it for a negative thickness.
  - `rec`: The rectangle.
  - `lineThick`: The lines' thickness; more than half the rectangle's width or height is half its shorter side, and 0 or less draws the outline that thick outside the rectangle (bars of no width, for 0).
  - `color`: The color.
- `DrawRectangleRounded`: Draws a filled rectangle with rounded corners.
  - `rec`: The rectangle.
  - `roundness`: How round its corners are: 0 for square, 1 for a radius of half its shorter side.
  - `segments`: How many straight edges make each corner's curve; fewer than 1 picks enough for a smooth curve.
  - `color`: The color.
- `DrawRectangleRoundedLines`: Draws a rounded rectangle's outline, one pixel wide, its lines through the centers of its edge pixels.
  - `rec`: The rectangle.
  - `roundness`: How round its corners are: 0 or less for square (`DrawRectangleLines`, the rectangle cut to whole pixels), 1 for a radius of half its shorter side.
  - `segments`: How many straight edges make each corner's curve; fewer than 1 picks enough for a smooth curve.
  - `color`: The color.
- `DrawRectangleRoundedLinesEx`: Draws a rounded rectangle's outline, its lines outside it.
  - `rec`: The rectangle.
  - `roundness`: How round its corners are: 0 for square, 1 for a radius of half its shorter side.
  - `segments`: How many straight edges make each corner's curve; fewer than 4 picks enough for a smooth curve.
  - `lineThick`: The lines' thickness; 1 or less draws them one pixel wide.
  - `color`: The color.
- `DrawTriangle`: Draws a filled triangle.
  - `v1`: The first point.
  - `v2`: The second point.
  - `v3`: The third point.
  - `color`: The color.

  Its points must go counterclockwise on the screen, as raylib's must: a triangle whose points go clockwise faces away, and isn't drawn while back faces are culled (`rlEnableBackfaceCulling`, the default).
- `DrawTriangleLines`: Draws a triangle's outline, one pixel wide.
  - `v1`: The first point.
  - `v2`: The second point.
  - `v3`: The third point.
  - `color`: The color.
- `DrawTriangleFan`: Draws filled triangles that all share the first point, each from it to the next two points.
  - `points`: The points, the shared one first.
  - `pointCount`: How many of them to draw, 3 or more.
  - `color`: The color.

  The points after the first must go counterclockwise on the screen, as `DrawTriangle`'s must.
- `DrawTriangleStrip`: Draws filled triangles, each from a point to the two before it.
  - `points`: The points.
  - `pointCount`: How many of them to draw, 3 or more.
  - `color`: The color.
- `DrawPoly`: Draws a filled regular polygon.
  - `center`: The center.
  - `sides`: How many sides it has, 3 or more.
  - `radius`: The distance from the center to each corner.
  - `rotation`: The turn of its first corner from the right, in degrees clockwise.
  - `color`: The color.
- `DrawPolyLines`: Draws a regular polygon's outline, one pixel wide.
  - `center`: The center.
  - `sides`: How many sides it has, 3 or more.
  - `radius`: The distance from the center to each corner.
  - `rotation`: The turn of its first corner from the right, in degrees clockwise.
  - `color`: The color.
- `DrawPolyLinesEx`: Draws a regular polygon's outline of a thickness, inside it, or outside it for a negative thickness.
  - `center`: The center.
  - `sides`: How many sides it has, 3 or more.
  - `radius`: The distance from the center to each corner.
  - `rotation`: The turn of its first corner from the right, in degrees clockwise.
  - `lineThick`: The lines' thickness, measured across each side; past the center it fills the polygon, and a negative thickness draws the outline that thick outside it.
  - `color`: The color.
- `DrawSplineLinear`: Draws straight lines of a thickness from each point to the next.
  - `points`: The points.
  - `pointCount`: How many of them to draw through, 2 or more.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawSplineBasis`: Draws a B-spline of a thickness through points, with round ends; it passes near the points rather than through them.
  - `points`: The points.
  - `pointCount`: How many of them to draw through, 4 or more.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawSplineCatmullRom`: Draws a Catmull-Rom spline of a thickness through points, with round ends; it passes through all but the first and last, which only steer it.
  - `points`: The points.
  - `pointCount`: How many of them to draw through, 4 or more.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawSplineBezierQuadratic`: Draws quadratic Bezier curves of a thickness, one after another: points, then a control point between each two.
  - `points`: The points: start, control, end, then a control and an end for each further curve.
  - `pointCount`: How many of them to draw through, 3 or more.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawSplineBezierCubic`: Draws cubic Bezier curves of a thickness, one after another: points, then two control points between each two.
  - `points`: The points: start, two controls, end, then two controls and an end for each further curve.
  - `pointCount`: How many of them to draw through, 4 or more.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawSplineSegmentLinear`: Draws a straight line of a thickness.
  - `p1`: The start.
  - `p2`: The end.
  - `thick`: The thickness, in pixels; 0 or less draws nothing.
  - `color`: The color.
- `DrawSplineSegmentBasis`: Draws one piece of a B-spline of a thickness, between the middle two of four points.
  - `p1`: The first point.
  - `p2`: The second.
  - `p3`: The third.
  - `p4`: The fourth.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawSplineSegmentCatmullRom`: Draws one piece of a Catmull-Rom spline of a thickness, through the middle two of four points.
  - `p1`: The first point, which steers it.
  - `p2`: The start.
  - `p3`: The end.
  - `p4`: The fourth point, which steers it.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawSplineSegmentBezierQuadratic`: Draws a quadratic Bezier curve of a thickness.
  - `p1`: The start.
  - `c2`: The control point.
  - `p3`: The end.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawSplineSegmentBezierCubic`: Draws a cubic Bezier curve of a thickness.
  - `p1`: The start.
  - `c2`: The start's control point.
  - `c3`: The end's control point.
  - `p4`: The end.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `GetSplinePointLinear`: Returns a point on a straight line.
  - `startPos`: The start.
  - `endPos`: The end.
  - `t`: How far along, 0 at the start to 1 at the end.
  - returns: The point.
- `GetSplinePointBasis`: Returns a point on one piece of a B-spline, between the middle two of four points.
  - `p1`: The first point.
  - `p2`: The second.
  - `p3`: The third.
  - `p4`: The fourth.
  - `t`: How far along, 0 at the start to 1 at the end.
  - returns: The point.
- `GetSplinePointCatmullRom`: Returns a point on one piece of a Catmull-Rom spline, through the middle two of four points.
  - `p1`: The first point, which steers it.
  - `p2`: The start.
  - `p3`: The end.
  - `p4`: The fourth point, which steers it.
  - `t`: How far along, 0 at the start to 1 at the end.
  - returns: The point.
- `GetSplinePointBezierQuad`: Returns a point on a quadratic Bezier curve.
  - `p1`: The start.
  - `c2`: The control point.
  - `p3`: The end.
  - `t`: How far along, 0 at the start to 1 at the end.
  - returns: The point.
- `GetSplinePointBezierCubic`: Returns a point on a cubic Bezier curve.
  - `p1`: The start.
  - `c2`: The start's control point.
  - `c3`: The end's control point.
  - `p4`: The end.
  - `t`: How far along, 0 at the start to 1 at the end.
  - returns: The point.
- `CheckCollisionRecs`: Returns whether two rectangles overlap.
  - `rec1`: One rectangle.
  - `rec2`: The other.
  - returns: True when they overlap.
- `CheckCollisionCircles`: Returns whether two circles overlap.
  - `center1`: One circle's center.
  - `radius1`: Its radius.
  - `center2`: The other's center.
  - `radius2`: Its radius.
  - returns: True when they overlap.
- `CheckCollisionCircleRec`: Returns whether a circle and a rectangle overlap.
  - `center`: The circle's center.
  - `radius`: Its radius.
  - `rec`: The rectangle.
  - returns: True when they overlap.
- `CheckCollisionCircleLine`: Returns whether a circle and a line between two points touch.
  - `center`: The circle's center.
  - `radius`: Its radius.
  - `p1`: The line's start.
  - `p2`: Its end.
  - returns: True when they touch.
- `CheckCollisionPointRec`: Returns whether a point is inside a rectangle.
  - `point`: The point.
  - `rec`: The rectangle.
  - returns: True when it is inside.
- `CheckCollisionPointCircle`: Returns whether a point is inside a circle.
  - `point`: The point.
  - `center`: The circle's center.
  - `radius`: Its radius.
  - returns: True when it is inside.
- `CheckCollisionPointTriangle`: Returns whether a point is inside a triangle; a point on its edge isn't.
  - `point`: The point.
  - `p1`: The triangle's first point.
  - `p2`: Its second.
  - `p3`: Its third.
  - returns: True when it is inside.
- `CheckCollisionPointLine`: Returns whether a point is on a line between two points, within a margin.
  - `point`: The point.
  - `p1`: The line's start.
  - `p2`: Its end.
  - `threshold`: How far from the line the point may be, in pixels.
  - returns: True when it is on it.
- `CheckCollisionPointPoly`: Returns whether a point is inside a polygon.
  - `point`: The point.
  - `points`: The polygon's corners, in order.
  - `pointCount`: How many of them it has, 3 or more.
  - returns: True when it is inside.
- `CheckCollisionLines`: Returns whether two lines, each between two points, cross, and where.
  - `startPos1`: One line's start.
  - `endPos1`: Its end.
  - `startPos2`: The other's start.
  - `endPos2`: Its end.
  - `collisionPoint`: Set to where they cross, when they do; null leaves it out.
  - returns: True when they cross.
- `GetCollisionRec`: Returns where two rectangles overlap.
  - `rec1`: One rectangle.
  - `rec2`: The other.
  - returns: The overlap, or an empty rectangle at 0, 0 when they don't.

### rtextures: textures, render textures and colors

```haxe
static function UnloadTexture(texture:Texture2D):Void
static function IsTextureValid(texture:Texture2D):Bool
static function DrawTexture(texture:Texture2D, posX:Int, posY:Int, tint:Color):Void
static function DrawTextureV(texture:Texture2D, position:Vector2, tint:Color):Void
static function DrawTextureEx(texture:Texture2D, position:Vector2, rotation:Float, scale:Float, tint:Color):Void
static function DrawTextureRec(texture:Texture2D, source:Rectangle, position:Vector2, tint:Color):Void
static function DrawTexturePro(texture:Texture2D, source:Rectangle, dest:Rectangle, origin:Vector2, rotation:Float, tint:Color):Void
static function ColorNormalize(color:Color):Vector4
static function ColorFromNormalized(normalized:Vector4):Color
static function Fade(color:Color, alpha:Float):Color
static function ColorAlpha(color:Color, alpha:Float):Color
static function ColorIsEqual(col1:Color, col2:Color):Bool
static function ColorToInt(color:Color):Int
static function ColorToHSV(color:Color):Vector3
static function ColorFromHSV(hue:Float, saturation:Float, value:Float):Color
static function ColorTint(color:Color, tint:Color):Color
static function ColorBrightness(color:Color, factor:Float):Color
static function ColorContrast(color:Color, contrast:Float):Color
static function ColorAlphaBlend(dst:Color, src:Color, tint:Color):Color
static function ColorLerp(color1:Color, color2:Color, factor:Float):Color
static function GetColor(hexValue:Int):Color
static function GetPixelDataSize(width:Int, height:Int, format:Int):Int
static function LoadRenderTexture(width:Int, height:Int):RenderTexture2D
static function IsRenderTextureValid(target:RenderTexture2D):Bool
static function UnloadRenderTexture(target:RenderTexture2D):Void
static function BeginTextureMode(target:RenderTexture2D):Void
static function EndTextureMode():Void
static function SetTextureFilter(texture:Texture2D, filter:Int):Void
static function GenTextureMipmaps(texture:Texture2D):Void
static function IsImageValid(image:Image):Bool
static function UnloadImage(image:Image):Void
static function ExportImageToMemory(image:Image, fileType:String, fileSize:Array<Int>):haxe.io.Bytes
static function GenImageColor(width:Int, height:Int, color:Color):Image
static function GenImageGradientLinear(width:Int, height:Int, direction:Int, start:Color, end:Color):Image
static function GenImageGradientRadial(width:Int, height:Int, density:Float, inner:Color, outer:Color):Image
static function GenImageGradientSquare(width:Int, height:Int, density:Float, inner:Color, outer:Color):Image
static function GenImageChecked(width:Int, height:Int, checksX:Int, checksY:Int, col1:Color, col2:Color):Image
static function GenImageWhiteNoise(width:Int, height:Int, factor:Float):Image
static function GenImagePerlinNoise(width:Int, height:Int, offsetX:Int, offsetY:Int, scale:Float):Image
static function GenImageCellular(width:Int, height:Int, tileSize:Int):Image
static function GenImageText(width:Int, height:Int, text:String):Image
static function ImageCopy(image:Image):Image
static function ImageFromImage(image:Image, rec:Rectangle):Image
static function ImageFromChannel(image:Image, selectedChannel:Int):Image
static function ImageText(text:String, fontSize:Int, color:Color):Image
static function ImageTextEx(font:Font, text:String, fontSize:Float, spacing:Float, tint:Color):Image
static function ImageFormat(image:Image, newFormat:Int):Void
static function ImageToPOT(image:Image, fill:Color):Void
static function ImageCrop(image:Image, crop:Rectangle):Void
static function ImageAlphaCrop(image:Image, threshold:Float):Void
static function ImageAlphaClear(image:Image, color:Color, threshold:Float):Void
static function ImageAlphaMask(image:Image, alphaMask:Image):Void
static function ImageAlphaPremultiply(image:Image):Void
static function ImageBlurGaussian(image:Image, blurSize:Int):Void
static function ImageKernelConvolution(image:Image, kernel:Array<Float>, kernelSize:Int):Void
static function ImageResize(image:Image, newWidth:Int, newHeight:Int):Void
static function ImageResizeNN(image:Image, newWidth:Int, newHeight:Int):Void
static function ImageResizeCanvas(image:Image, newWidth:Int, newHeight:Int, offsetX:Int, offsetY:Int, fill:Color):Void
static function ImageMipmaps(image:Image):Void
static function ImageDither(image:Image, rBpp:Int, gBpp:Int, bBpp:Int, aBpp:Int):Void
static function ImageFlipVertical(image:Image):Void
static function ImageFlipHorizontal(image:Image):Void
static function ImageRotate(image:Image, degrees:Int):Void
static function ImageRotateCW(image:Image):Void
static function ImageRotateCCW(image:Image):Void
static function ImageColorTint(image:Image, color:Color):Void
static function ImageColorInvert(image:Image):Void
static function ImageColorGrayscale(image:Image):Void
static function ImageColorContrast(image:Image, contrast:Float):Void
static function ImageColorBrightness(image:Image, brightness:Int):Void
static function ImageColorReplace(image:Image, color:Color, replace:Color):Void
static function LoadImageColors(image:Image):Array<Color>
static function LoadImagePalette(image:Image, maxPaletteSize:Int, colorCount:Array<Int>):Array<Color>
static function UnloadImageColors(colors:Array<Color>):Void
static function UnloadImagePalette(colors:Array<Color>):Void
static function GetImageAlphaBorder(image:Image, threshold:Float):Rectangle
static function GetImageColor(image:Image, x:Int, y:Int):Color
static function ImageClearBackground(dst:Image, color:Color):Void
static function ImageDrawPixel(dst:Image, posX:Int, posY:Int, color:Color):Void
static function ImageDrawPixelV(dst:Image, position:Vector2, color:Color):Void
static function ImageDrawLine(dst:Image, startPosX:Int, startPosY:Int, endPosX:Int, endPosY:Int, color:Color):Void
static function ImageDrawLineV(dst:Image, start:Vector2, end:Vector2, color:Color):Void
static function ImageDrawLineEx(dst:Image, start:Vector2, end:Vector2, thick:Int, color:Color):Void
static function ImageDrawCircle(dst:Image, centerX:Int, centerY:Int, radius:Int, color:Color):Void
static function ImageDrawCircleV(dst:Image, center:Vector2, radius:Int, color:Color):Void
static function ImageDrawCircleLines(dst:Image, centerX:Int, centerY:Int, radius:Int, color:Color):Void
static function ImageDrawCircleLinesV(dst:Image, center:Vector2, radius:Int, color:Color):Void
static function ImageDrawRectangle(dst:Image, posX:Int, posY:Int, width:Int, height:Int, color:Color):Void
static function ImageDrawRectangleV(dst:Image, position:Vector2, size:Vector2, color:Color):Void
static function ImageDrawRectangleRec(dst:Image, rec:Rectangle, color:Color):Void
static function ImageDrawRectangleLines(dst:Image, rec:Rectangle, thick:Int, color:Color):Void
static function ImageDrawTriangle(dst:Image, v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void
static function ImageDrawTriangleEx(dst:Image, v1:Vector2, v2:Vector2, v3:Vector2, c1:Color, c2:Color, c3:Color):Void
static function ImageDrawTriangleLines(dst:Image, v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void
static function ImageDrawTriangleFan(dst:Image, points:Array<Vector2>, pointCount:Int, color:Color):Void
static function ImageDrawTriangleStrip(dst:Image, points:Array<Vector2>, pointCount:Int, color:Color):Void
static function ImageDraw(dst:Image, src:Image, srcRec:Rectangle, dstRec:Rectangle, tint:Color):Void
static function ImageDrawText(dst:Image, text:String, posX:Int, posY:Int, fontSize:Int, color:Color):Void
static function ImageDrawTextEx(dst:Image, font:Font, text:String, position:Vector2, fontSize:Float, spacing:Float, tint:Color):Void
static function LoadTextureFromImage(image:Image):Texture2D
static function LoadTextureCubemap(image:Image, layout:Int):TextureCubemap
static function UpdateTexture(texture:Texture2D, pixels:Dynamic):Void
static function UpdateTextureRec(texture:Texture2D, rec:Rectangle, pixels:Dynamic):Void
static function SetTextureWrap(texture:Texture2D, wrap:Int):Void
static function DrawTextureNPatch(texture:Texture2D, nPatchInfo:NPatchInfo, dest:Rectangle, origin:Vector2, rotation:Float, tint:Color):Void
static function GetPixelColor(srcPtr:haxe.io.Bytes, format:Int, ?offset:Int = 0):Color
static function SetPixelColor(dstPtr:haxe.io.Bytes, color:Color, format:Int, ?offset:Int = 0):Void
```

- `UnloadTexture`: Lets go of a texture (docs/DECISIONS.md 25): the program's hold from its load, its id set to 0. The texture is freed, the GPU's copy with it, when nothing else holds it: another load of its file, or a material map given it, keeps it until that lets go. Given a map's texture (`map.texture`), as `UnloadTexture(model.materials[0].maps[0].texture)` frees one a program gave a map without keeping it, it lets go of one hold and leaves the map's id: the map draws it while anything holds it, and lets go in turn when its material is freed.
  - `texture`: The texture.
- `IsTextureValid`: Returns whether a texture was loaded.
  - `texture`: The texture.
  - returns: True when it holds an image.
- `DrawTexture`: Draws a texture, its top-left corner at a point.
  - `texture`: The texture.
  - `posX`: The x.
  - `posY`: The y.
  - `tint`: The color it is multiplied by; `WHITE` keeps it as it is.
- `DrawTextureV`: Draws a texture, its top-left corner at a point.
  - `texture`: The texture.
  - `position`: The point.
  - `tint`: The color it is multiplied by.
- `DrawTextureEx`: Draws a texture turned about its top-left corner and scaled.
  - `texture`: The texture.
  - `position`: The top-left corner.
  - `rotation`: Clockwise, in degrees.
  - `scale`: The scale.
  - `tint`: The color it is multiplied by.
- `DrawTextureRec`: Draws part of a texture. A negative source width or height flips it.
  - `texture`: The texture.
  - `source`: The part, in the texture's pixels.
  - `position`: Where its top-left corner goes.
  - `tint`: The color it is multiplied by.
- `DrawTexturePro`: Draws part of a texture into a rectangle, turned about an origin. A negative source width or height flips it.
  - `texture`: The texture.
  - `source`: The part, in the texture's pixels.
  - `dest`: Where it goes; its x and y are where the origin lands.
  - `origin`: The point it turns about, from dest's top-left corner.
  - `rotation`: Clockwise, in degrees.
  - `tint`: The color it is multiplied by.
- `ColorNormalize`: Returns a color as four numbers, 0 to 1 each.
  - `color`: The color.
  - returns: Red, green, blue and alpha as x, y, z and w.
- `ColorFromNormalized`: Returns a color from four numbers, 0 to 1 each.
  - `normalized`: Red, green, blue and alpha as x, y, z and w.
  - returns: The color.
- `Fade`: Returns a color with its alpha scaled.
  - `color`: The color.
  - `alpha`: 0 (clear) to 1 (as it is).
  - returns: The new color.
- `ColorAlpha`: Returns a color with an alpha.
  - `color`: The color.
  - `alpha`: 0 (clear) to 1 (opaque).
  - returns: The new color.
- `ColorIsEqual`: Returns whether two colors are the same, alpha too.
  - `col1`: One color.
  - `col2`: The other.
  - returns: True when red, green, blue and alpha are each equal.
- `ColorToInt`: Returns a color as one number, 0xRRGGBBAA.
  - `color`: The color.
  - returns: Red in the top byte, alpha in the bottom; a red of 128 or more makes it negative.
- `ColorToHSV`: Returns a color's hue, saturation and value.
  - `color`: The color; its alpha is ignored.
  - returns: The hue in degrees, 0 to 360, as x; the saturation and value, 0 to 1 each, as y and z. A gray's hue and saturation are 0.
- `ColorFromHSV`: Returns the color of a hue, saturation and value; its alpha is 255.
  - `hue`: The hue, in degrees, 0 to 360.
  - `saturation`: 0 (gray) to 1.
  - `value`: 0 (black) to 1.
  - returns: The color.
- `ColorTint`: Returns a color multiplied by another, channel by channel.
  - `color`: The color.
  - `tint`: The color it is multiplied by; `WHITE` keeps it as it is.
  - returns: The new color.
- `ColorBrightness`: Returns a color made darker or lighter; its alpha is kept.
  - `color`: The color.
  - `factor`: -1 (black) to 1 (white); 0 keeps it as it is.
  - returns: The new color.
- `ColorContrast`: Returns a color with more or less contrast about the middle gray; its alpha is kept.
  - `color`: The color.
  - `contrast`: -1 (all middle gray) to 1; 0 keeps it as it is.
  - returns: The new color.
- `ColorAlphaBlend`: Returns a color drawn over another: the source, multiplied by a tint, blended into the destination by its alpha.
  - `dst`: The color underneath.
  - `src`: The color drawn over it.
  - `tint`: The color the source is multiplied by; `WHITE` keeps it as it is.
  - returns: The blend.
- `ColorLerp`: Returns a color part way from one color to another.
  - `color1`: The color at 0.
  - `color2`: The color at 1.
  - `factor`: How far, 0 to 1.
  - returns: The color between them.
- `GetColor`: Returns the color of one number, 0xRRGGBBAA.
  - `hexValue`: Red in the top byte, alpha in the bottom.
  - returns: The color.
- `GetPixelDataSize`: Returns how many bytes an image's pixels take in a format.
  - `width`: The width, in pixels.
  - `height`: The height.
  - `format`: The format (`PIXELFORMAT_*`).
  - returns: The bytes; a compressed format smaller than 4 by 4 pixels takes a whole block, 8 or 16 bytes. An unknown format, a width or height of 0 or less, and a size of 2 GB or more (with a warning) give 0.
- `LoadRenderTexture`: Makes a texture to draw into, with depth, 8-bit RGBA.
  - `width`: Its width, in pixels.
  - `height`: Its height.
  - returns: The render texture.
- `IsRenderTextureValid`: Returns whether a render texture was made.
  - `target`: The render texture.
  - returns: True when it was.
- `UnloadRenderTexture`: Frees a render texture.
  - `target`: The render texture.
- `BeginTextureMode`: Draws into a render texture until `EndTextureMode`, over what it holds: what was drawn into it before, in this frame or an earlier one, stays until `ClearBackground` clears it, as raylib's does. A render texture never drawn into holds transparent black.
  - `target`: The render texture.
- `EndTextureMode`: Goes back to drawing on the screen.
- `SetTextureFilter`: Sets how a texture is sampled when drawn larger or smaller, as raylib's GL does, by whether the texture has mipmaps (`texture.mipmaps`, as this copy of it says): `TEXTURE_FILTER_POINT`, raylib's default, takes the nearest texel (of the nearest mipmap); `TEXTURE_FILTER_BILINEAR` blends the nearest four (of the nearest mipmap); `TEXTURE_FILTER_TRILINEAR` blends the nearest four of the two nearest mipmaps, or, without mipmaps, is `TEXTURE_FILTER_BILINEAR`, with a warning. `TEXTURE_FILTER_ANISOTROPIC_4X`, `8X` and `16X` read up to that many texels along a surface seen at a slant, leaving the filter as it was; the GPU uses it only with `TEXTURE_FILTER_TRILINEAR` on a mipmapped texture. A cubemap (`LoadTextureCubemap`) is left unchanged: raylib's binds it as a 2D texture, which GL refuses.
  - `texture`: The texture.
  - `filter`: The filter (`TEXTURE_FILTER_*`).
- `GenTextureMipmaps`: Makes a texture's mipmaps, down to 1 by 1, as raylib's does with GL's `glGenerateMipmap`: each level the rounded average of the 2 by 2 above it, made on the CPU, so the same on every target. `texture.mipmaps` becomes their count. The texture's filter is left as it was: `SetTextureFilter` after it reads them. A texture already drawn gets them from its pixels read back from the GPU, and draws asked for before it this frame don't; a render texture's and a cubemap's can't be made, with a warning.
  - `texture`: The texture.
- `IsImageValid`: Returns whether an image holds pixels: data, a size, a format and a mipmap level.
  - `image`: The image.
  - returns: True when it does.
- `UnloadImage`: Frees an image's pixels.
  - `image`: The image.
- `ExportImageToMemory`: Returns an image encoded as a file in memory: ".png" alone, as raylib's. Like raylib's, an image's bytes are read as 8-bit gray, gray and alpha, RGB or RGBA by its format, and as RGBA for any other format, which a 16-bit format has too few of: those it lacks read as 0.
  - `image`: The image.
  - `fileType`: ".png" or ".PNG".
  - `fileSize`: Its first element is set to the file's size, 0 for none.
  - returns: The file, or null for another type or an empty image.
- `GenImageColor`: Returns an image of one color, RGBA.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `color`: The color.
  - returns: The image.
- `GenImageGradientLinear`: Returns a gradient from one color to another, RGBA.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `direction`: The direction, in degrees: 0 top to bottom, 90 left to right.
  - `start`: The color it starts from.
  - `end`: The color it ends at.
  - returns: The image.
- `GenImageGradientRadial`: Returns a round gradient out from the middle, RGBA.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `density`: How far the inner color holds, 0 (the middle alone) to 1 (out to the nearer edge).
  - `inner`: The color in the middle.
  - `outer`: The color at the edge and beyond.
  - returns: The image.
- `GenImageGradientSquare`: Returns a square gradient out from the middle, RGBA.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `density`: How far the inner color holds, 0 (the middle alone) to 1 (out to the edges).
  - `inner`: The color in the middle.
  - `outer`: The color at the edges.
  - returns: The image.
- `GenImageChecked`: Returns a checkerboard of two colors, RGBA. A square size under 1 is taken as 1, where raylib's divides by zero.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `checksX`: Each square's width, in pixels.
  - `checksY`: Each square's height, in pixels.
  - `col1`: The top-left square's color.
  - `col2`: The color of the squares beside it.
  - returns: The image.
- `GenImageWhiteNoise`: Returns white noise, RGBA: each pixel white or black, drawn from `GetRandomValue`, one number a pixel, so `SetRandomSeed` repeats it.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `factor`: The chance of white, 0 to 1.
  - returns: The image.
- `GenImagePerlinNoise`: Returns Perlin noise in gray, RGBA: stb_perlin's fractal noise, 6 octaves.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `offsetX`: How far it is moved left, in pixels.
  - `offsetY`: How far it is moved up, in pixels.
  - `scale`: How much of the noise it shows: larger is finer.
  - returns: The image.
- `GenImageCellular`: Returns cellular noise in gray, RGBA: each pixel's distance to the nearest of points scattered one a tile, drawn from `GetRandomValue`, so `SetRandomSeed` repeats it. A tile size under 1 is taken as 1, where raylib's divides by zero.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `tileSize`: The tiles' size, in pixels: bigger is bigger cells.
  - returns: The image.
- `GenImageText`: Returns an image of text's bytes, grayscale: its UTF-8, a byte a pixel, rows top first, the rest black.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `text`: The text; null gives a black image.
  - returns: The image.
- `ImageCopy`: Returns a copy of an image, its mipmaps too.
  - `image`: The image.
  - returns: The copy.
- `ImageFromImage`: Returns a rectangle of an image, in its format. A rectangle not wholly inside the image, of no size, or of a compressed image gives an empty image, with a warning.
  - `image`: The image.
  - `rec`: The rectangle, in pixels, cut to whole pixels.
  - returns: The image.
- `ImageFromChannel`: Returns one channel of an image as grayscale: 0 red, 1 green, 2 blue, 3 alpha. A channel the format lacks is taken as raylib takes it, with its warning: a one-channel format's only channel, gray and alpha's alpha, an RGB format's red.
  - `image`: The image.
  - `selectedChannel`: The channel.
  - returns: The image.
- `ImageText`: Returns text in raylib's default font, as an image, RGBA. A size under 10 is drawn at 10, letters a tenth of the size apart.
  - `text`: The text.
  - `fontSize`: The height of a line, in pixels.
  - `color`: The color.
  - returns: The image.
- `ImageTextEx`: Returns text in a font, as an image, RGBA, laid out as raylib's: at the font's size, each glyph's image drawn tinted, then scaled to the size, nearest for the default font. A newline starts a line one and a half of the font's size down, though the image's height counts each line as the size and `SetTextLineSpacing`'s spacing, as raylib's does. Another font is scaled by `ImageResize`, which isn't raylib's.
  - `font`: The font, its glyphs' images drawn.
  - `text`: The text; null gives an empty image.
  - `fontSize`: The height of a line, in pixels.
  - `spacing`: The space between letters, at the font's size.
  - `tint`: The color the glyphs are multiplied by.
  - returns: The image.
- `ImageFormat`: Converts an image to another pixel format, through floats as raylib's does: to grayscale by luminance (0.299 red, 0.587 green, 0.114 blue), R32 and R16 to their luminance, 16-bit channels rounded. An image with mipmaps has them made again.
  - `image`: The image.
  - `newFormat`: The format (`PIXELFORMAT_UNCOMPRESSED_*`); a compressed one is refused, with a warning.
- `ImageToPOT`: Puts an image on the smallest canvas whose sides are powers of two, at its top-left.
  - `image`: The image.
  - `fill`: The color of the canvas around it.
- `ImageCrop`: Crops an image to a rectangle, cut to the image; one whose corner is past the image's right or bottom edge leaves it unchanged, with a warning. Its mipmaps are dropped, as raylib's are, though its mipmap count is kept.
  - `image`: The image.
  - `crop`: The rectangle, in pixels.
- `ImageAlphaCrop`: Crops an image to the pixels whose alpha is over a threshold, when any is.
  - `image`: The image.
  - `threshold`: The threshold, 0 to 1.
- `ImageAlphaClear`: Sets every pixel whose alpha is at or under a threshold to a color, as raylib's does for its formats with alpha: gray and alpha, R5G5B5A1 (the alpha bit against a threshold of 0.5; the color's channels, unscaled, are cut to 5 bits), R4G4B4A4 (likewise to 4 bits), RGBA and its 32-bit and 16-bit float forms. Another format is unchanged.
  - `image`: The image.
  - `color`: The color.
  - `threshold`: The threshold, 0 to 1.
- `ImageAlphaMask`: Sets an image's alpha from another image of the same size, its grayscale: a grayscale image becomes gray and alpha, any other RGBA. A mask of another size changes nothing, with a warning.
  - `image`: The image.
  - `alphaMask`: The mask.
- `ImageAlphaPremultiply`: Multiplies each pixel's red, green and blue by its alpha, rounding down; the image keeps its format.
  - `image`: The image.
- `ImageBlurGaussian`: Blurs an image, as raylib's does: an approximate Gaussian, four passes of a box blur across and down, over premultiplied alpha, each channel taken back from it no higher than 255. A box reaching past the image's last pixel reads 0 there, where raylib's reads past its pixels.
  - `image`: The image.
  - `blurSize`: How far each box reaches either side of a pixel, in pixels.
- `ImageKernelConvolution`: Applies a square kernel to an image, as raylib's does: each channel, alpha too, the sum of the pixels around it as fractions times the weights, clamped to 0 to 1. A pixel past an edge is taken from the edge. A count that isn't square changes nothing, with a warning.
  - `image`: The image.
  - `kernel`: The weights, rows top first.
  - `kernelSize`: How many: 9 for 3 by 3, 25 for 5 by 5.
- `ImageResize`: Resizes an image. Unlike raylib's, whose `stb_image_resize2` this library doesn't have, it is helix-services' `Bicubic` (Catmull-Rom, alpha-weighted), so the pixels aren't raylib's; an 8-bit format is resized in its channels, any other through RGBA, as raylib's.
  - `image`: The image.
  - `newWidth`: The width, in pixels.
  - `newHeight`: The height, in pixels.
- `ImageResizeNN`: Resizes an image to the nearest pixels, as raylib's does, through RGBA; it keeps its format.
  - `image`: The image.
  - `newWidth`: The width, in pixels.
  - `newHeight`: The height, in pixels.
- `ImageResizeCanvas`: Puts an image on a canvas of another size, in its format: the canvas filled with a color as `SetPixelColor` writes it (a float format's canvas stays zero), the image at an offset, what falls outside cropped. A canvas the image's size leaves it unchanged.
  - `image`: The image.
  - `newWidth`: The canvas's width, in pixels.
  - `newHeight`: The canvas's height, in pixels.
  - `offsetX`: Where the image's left edge goes; negative crops its left.
  - `offsetY`: Where its top edge goes.
  - `fill`: The canvas's color.
- `ImageMipmaps`: Makes an image's mipmaps, down to 1 by 1, after its pixels, in its format; levels it has are kept. Each is made by `ImageResize` from the last, so they aren't raylib's.
  - `image`: The image.
- `ImageDither`: Dithers an image to 16 bits a pixel or fewer (Floyd-Steinberg), as raylib's does: R5G6B5, R5G5B5A1 or R4G4B4A4 when the bits are one of those, else format 0 with the bits packed in 16, and a warning. More than 16 bits changes nothing, with a warning.
  - `image`: The image.
  - `rBpp`: Red's bits.
  - `gBpp`: Green's bits.
  - `bBpp`: Blue's bits.
  - `aBpp`: Alpha's bits.
- `ImageFlipVertical`: Turns an image upside down, in its format. Its mipmaps are dropped, as raylib's are, though its mipmap count is kept.
  - `image`: The image.
- `ImageFlipHorizontal`: Mirrors an image left to right, in its format. Its mipmaps are dropped, as raylib's are, though its mipmap count is kept.
  - `image`: The image.
- `ImageRotate`: Turns an image by an angle, on a canvas big enough to hold it, clear around it: each byte of a pixel blends the four it falls between, as raylib's does in every format.
  - `image`: The image.
  - `degrees`: The angle, in degrees clockwise.
- `ImageRotateCW`: Turns an image a quarter turn clockwise, in its format.
  - `image`: The image.
- `ImageRotateCCW`: Turns an image a quarter turn counterclockwise, in its format.
  - `image`: The image.
- `ImageColorTint`: Multiplies each pixel by a color, channel by channel, alpha too; the image keeps its format.
  - `image`: The image.
  - `color`: The color; `WHITE` keeps it unchanged.
- `ImageColorInvert`: Inverts each pixel's red, green and blue; the image keeps its format.
  - `image`: The image.
- `ImageColorGrayscale`: Makes an image grayscale, as raylib's does: it becomes `PIXELFORMAT_UNCOMPRESSED_GRAYSCALE`, its alpha dropped.
  - `image`: The image.
- `ImageColorContrast`: Changes an image's contrast; the image keeps its format.
  - `image`: The image.
  - `contrast`: -100 (all mid-gray) to 100; 0 leaves it unchanged.
- `ImageColorBrightness`: Changes an image's brightness, adding to red, green and blue; the image keeps its format. A channel taken below 0 becomes 1, as raylib's does.
  - `image`: The image.
  - `brightness`: -255 to 255.
- `ImageColorReplace`: Changes every pixel of one color to another; the image keeps its format.
  - `image`: The image.
  - `color`: The color changed, alpha too.
  - `replace`: The color it becomes.
- `LoadImageColors`: Returns an image's pixels as colors, as raylib's reads each format: a 5-bit channel times 8, a 6-bit times 4, a 4-bit times 17; R32 and R16 as red alone.
  - `image`: The image.
  - returns: The colors, rows top first, or null for an image 0 wide or high.
- `LoadImagePalette`: Returns an image's colors, each once, in the order first met; clear pixels are skipped.
  - `image`: The image.
  - `maxPaletteSize`: The most colors.
  - `colorCount`: Its first element is set to how many colors were found.
  - returns: `maxPaletteSize` colors, those found first, the rest `BLANK`; null for an image 0 wide or high.
- `UnloadImageColors`: Frees colors `LoadImageColors` gave. There is nothing to free here.
  - `colors`: The colors.
- `UnloadImagePalette`: Frees colors `LoadImagePalette` gave. There is nothing to free here.
  - `colors`: The colors.
- `GetImageAlphaBorder`: Returns the smallest rectangle holding every pixel whose alpha is over a threshold.
  - `image`: The image.
  - `threshold`: The threshold, 0 to 1.
  - returns: The rectangle, in pixels; all zero when no pixel is over it.
- `GetImageColor`: Returns a pixel's color, as `LoadImageColors` reads it. A pixel outside the image is clear black, with a warning.
  - `image`: The image.
  - `x`: The pixel's column.
  - `y`: Its row.
  - returns: The color.
- `ImageClearBackground`: Fills an image with a color, in its format, as `ImageDrawPixel` writes it.
  - `dst`: The image.
  - `color`: The color.
- `ImageDrawPixel`: Sets a pixel, in the image's format: grayscale by luminance, a 16-bit format's channels rounded, R5G5B5A1's alpha bit set over an alpha of 50. One outside the image is skipped.
  - `dst`: The image.
  - `posX`: The pixel's column.
  - `posY`: Its row.
  - `color`: The color.
- `ImageDrawPixelV`: Sets a pixel, as `ImageDrawPixel` does, its position cut to whole pixels.
  - `dst`: The image.
  - `position`: The pixel.
  - `color`: The color.
- `ImageDrawLine`: Draws a line one pixel wide, from its start to its end, both drawn.
  - `dst`: The image.
  - `startPosX`: The start's column.
  - `startPosY`: The start's row.
  - `endPosX`: The end's column.
  - `endPosY`: The end's row.
  - `color`: The color.
- `ImageDrawLineV`: Draws a line one pixel wide, its ends rounded to whole pixels.
  - `dst`: The image.
  - `start`: The start.
  - `end`: The end.
  - `color`: The color.
- `ImageDrawLineEx`: Draws a line of a thickness: as many lines as it is thick, side by side, below and above the line for a line more across than down, right and left of it otherwise (the odd one out below or right). Its ends are rounded to whole pixels; a line from a pixel to itself draws nothing.
  - `dst`: The image.
  - `start`: The start.
  - `end`: The end.
  - `thick`: The thickness, in pixels; less than 1 draws the line alone.
  - `color`: The color.
- `ImageDrawCircle`: Fills a circle, each row as wide either side of the middle.
  - `dst`: The image.
  - `centerX`: The middle's column.
  - `centerY`: The middle's row.
  - `radius`: The radius, in pixels.
  - `color`: The color.
- `ImageDrawCircleV`: Fills a circle, its middle cut to whole pixels.
  - `dst`: The image.
  - `center`: The middle.
  - `radius`: The radius, in pixels.
  - `color`: The color.
- `ImageDrawCircleLines`: Outlines a circle, one pixel wide.
  - `dst`: The image.
  - `centerX`: The middle's column.
  - `centerY`: The middle's row.
  - `radius`: The radius, in pixels.
  - `color`: The color.
- `ImageDrawCircleLinesV`: Outlines a circle, one pixel wide, its middle cut to whole pixels.
  - `dst`: The image.
  - `center`: The middle.
  - `radius`: The radius, in pixels.
  - `color`: The color.
- `ImageDrawRectangle`: Fills a rectangle; what falls outside the image is skipped.
  - `dst`: The image.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `color`: The color.
- `ImageDrawRectangleV`: Fills a rectangle, its corner and size cut to whole pixels.
  - `dst`: The image.
  - `position`: The top-left corner.
  - `size`: The width and height.
  - `color`: The color.
- `ImageDrawRectangleRec`: Fills a rectangle, as raylib's does: cut to the image, then to whole pixels; one 0 wide still sets its top-left pixel.
  - `dst`: The image.
  - `rec`: The rectangle, in pixels.
  - `color`: The color.
- `ImageDrawRectangleLines`: Outlines a rectangle, the outline inside it: its top and bottom across its whole width, its sides between them.
  - `dst`: The image.
  - `rec`: The rectangle, in pixels, cut to whole pixels.
  - `thick`: The outline's thickness, in pixels.
  - `color`: The color.
- `ImageDrawTriangle`: Fills a triangle; its corners may go either way round.
  - `dst`: The image.
  - `v1`: The first corner.
  - `v2`: The second corner.
  - `v3`: The third corner.
  - `color`: The color.
- `ImageDrawTriangleEx`: Fills a triangle, each corner its own color, blended across it as raylib's does: each channel by the pixel's weights, each rounded down, so three corners of one color may not give it exactly.
  - `dst`: The image.
  - `v1`: The first corner.
  - `v2`: The second corner.
  - `v3`: The third corner.
  - `c1`: The first corner's color.
  - `c2`: The second corner's color.
  - `c3`: The third corner's color.
- `ImageDrawTriangleLines`: Outlines a triangle with three `ImageDrawLine`s, its corners cut to whole pixels.
  - `dst`: The image.
  - `v1`: The first corner.
  - `v2`: The second corner.
  - `v3`: The third corner.
  - `color`: The color.
- `ImageDrawTriangleFan`: Fills a fan of triangles, each from the first point to the next two.
  - `dst`: The image.
  - `points`: The points, the first the fan's middle.
  - `pointCount`: How many; under 3 draws nothing.
  - `color`: The color.
- `ImageDrawTriangleStrip`: Fills a strip of triangles, each of three points in a row.
  - `dst`: The image.
  - `points`: The points.
  - `pointCount`: How many; under 3 draws nothing.
  - `color`: The color.
- `ImageDraw`: Draws a rectangle of one image into a rectangle of another, tinted, blended over (raylib's `ColorAlphaBlend`), in their formats. A source with no alpha under an opaque tint is copied, the tint's color ignored, as raylib's is; a float destination is unchanged, as `SetPixelColor` writes none. A source rectangle of another whole-pixel size than the destination's is first resized by `ImageResize`, which isn't raylib's. Their mipmaps are drawn too, when both have them.
  - `dst`: The image drawn into.
  - `src`: The image drawn from.
  - `srcRec`: The source rectangle, in its pixels, cut to it.
  - `dstRec`: The destination rectangle.
  - `tint`: The color the source is multiplied by; `WHITE` keeps it unchanged.
- `ImageDrawText`: Draws text in raylib's default font into an image, letters 1 pixel apart, as `ImageDrawTextEx` draws it.
  - `dst`: The image.
  - `text`: The text.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `fontSize`: The height of a line, in pixels.
  - `color`: The color.
- `ImageDrawTextEx`: Draws text in a font into an image: `ImageTextEx`'s image, drawn at a point.
  - `dst`: The image.
  - `font`: The font.
  - `text`: The text.
  - `position`: The top-left corner.
  - `fontSize`: The height of a line, in pixels.
  - `spacing`: The space between letters, at the font's size.
  - `tint`: The color.
- `LoadTextureFromImage`: Makes a texture of an image, in any uncompressed format: its pixels go to the GPU as RGBA when first drawn, its mipmaps too when it has them (`ImageMipmaps`), filtered through them, trilinear, as raylib sets it. Its format is the image's, as raylib's is, so a grayscale image's texture says `PIXELFORMAT_UNCOMPRESSED_GRAYSCALE`. A compressed format gives no texture, with a warning.
  - `image`: The image.
  - returns: The texture.
- `LoadTextureCubemap`: Makes a cubemap of an image, its six faces laid out as raylib's layouts lay them: `CUBEMAP_LAYOUT_LINE_VERTICAL` (a column, +X, -X, +Y, -Y, +Z, -Z from the top), `CUBEMAP_LAYOUT_LINE_HORIZONTAL` (a row, in that order from the left), `CUBEMAP_LAYOUT_CROSS_THREE_BY_FOUR` (3 faces wide, 4 high: +Y, +X, -Y and -X down the middle column, +Z left of +X and -Z right of it) or `CUBEMAP_LAYOUT_CROSS_FOUR_BY_THREE` (4 wide, 3 high: +Y at the top of the second column, then -X, +Z, +X, -Z across, then -Y below +Z), each face's rows top first as GL's cube faces take them; `CUBEMAP_LAYOUT_AUTO_DETECT` takes the layout from the image's shape. A face is the image's height over 6 (a column), its width over 6 (a row), over 3 (3 by 4) or over 4 (4 by 3).
  - `image`: The image.
  - `layout`: The layout (`CUBEMAP_LAYOUT_*`).
  - returns: The cubemap; id 0 for none.

  As raylib's: a column is read as it is, the face size squared times 6 pixels from the image's first, row after row, so an image not 1 face by 6 is read across its rows; the other layouts draw each face onto magenta (`ImageDraw`), a translucent pixel blended over it, a face partly past the image's edge its part inside stretched to the face, and one wholly past it left magenta (raylib's divides by zero). A shape `CUBEMAP_LAYOUT_AUTO_DETECT` doesn't know gives no cubemap, with a warning. Its format is the image's, its pixels RGBA on the GPU, sampled linearly as rlgl's cubemaps are. An image with mipmaps gives a cubemap with mipmaps, sampled through them: a column's from the image's levels, read as its first is; the other layouts' made from each face, as GL's `glGenerateMipmap` makes them, where raylib 6.2's are magenta (5.5's are magenta whatever the image). Where raylib's differs, it makes an empty GL cubemap: a face size of 0 (an image too small for its layout, or a layout raylib doesn't have) gives none here, as do a compressed format and an image too small for the column it is read as, with a warning.

  The cubemap is a `Texture2D`'s record: a material's `MATERIAL_MAP_CUBEMAP`, `MATERIAL_MAP_IRRADIANCE` or `MATERIAL_MAP_PREFILTER` binds it to a shader's `samplerCube` (`DrawMesh`), as does `SetShaderValueTexture`; drawn as a 2D texture, it draws nothing. `UnloadTexture` lets go of it, and it is counted as any texture is (docs/DECISIONS.md 25).
- `UpdateTexture`: Replaces a texture's pixels, as raylib's does on the GPU. The pixels are in the texture's format (`texture.format`), rows top first, its width by its height. Draws asked for before it this frame in a render texture drawn into since, or on the screen, show the new pixels too, as rlgl's batch drawn after it does; those in render textures drawn into before it keep the old. A render texture's, a cubemap's, a compressed format's and pixels too few for the texture change nothing (raylib's reads past them), with a warning.
  - `texture`: The texture.
  - `pixels`: The pixels: their bytes (`haxe.io.Bytes`), or an array of `Color` (R8G8B8A8's bytes, as raylib's `Color *` is).
- `UpdateTextureRec`: Replaces a rectangle of a texture's pixels, as `UpdateTexture` does the whole. A rectangle not inside the texture changes nothing, as GL refuses it.
  - `texture`: The texture.
  - `rec`: The rectangle, in pixels from the texture's top-left corner; its numbers are cut to whole pixels.
  - `pixels`: The rectangle's pixels, rows top first, in the texture's format: bytes, or an array of `Color`.
- `SetTextureWrap`: Sets how a texture wraps past its edges: `TEXTURE_WRAP_REPEAT` (raylib's default), `TEXTURE_WRAP_CLAMP` or `TEXTURE_WRAP_MIRROR_REPEAT`. `TEXTURE_WRAP_MIRROR_CLAMP` isn't here, and leaves it unchanged, with a warning. A cubemap is left unchanged.
  - `texture`: The texture.
  - `wrap`: The wrap (`TEXTURE_WRAP_*`).
- `DrawTextureNPatch`: Draws a texture as a nine-patch (or a three-patch) into a rectangle, turned about an origin, as raylib's does: its corners kept, its edges and middle stretched; a rectangle smaller than the borders shrinks them and drops the middle.
  - `texture`: The texture.
  - `nPatchInfo`: The patch: its rectangle on the texture, its borders and its layout (`NPATCH_*`).
  - `dest`: Where it goes; its x and y are where the origin lands.
  - `origin`: The point it turns about, from dest's top-left corner.
  - `rotation`: Clockwise, in degrees.
  - `tint`: The color it is multiplied by.
- `GetPixelColor`: Returns one pixel's color from pixels in a format, as raylib's does: 16-bit channels widened by integers, floats times 255. raylib takes a pointer to the pixel; here it is the pixels and the pixel's first byte.
  - `srcPtr`: The pixels.
  - `format`: Their format (`PIXELFORMAT_UNCOMPRESSED_*`).
  - `offset`: Optional. The pixel's first byte; 0 when omitted.
  - returns: The color; clear black for a compressed format.
- `SetPixelColor`: Writes one pixel's color into pixels in a format, as raylib's does: grayscale by luminance, 16-bit channels rounded; a float format is left unchanged. raylib takes a pointer to the pixel; here it is the pixels and the pixel's first byte.
  - `dstPtr`: The pixels.
  - `color`: The color.
  - `format`: Their format (`PIXELFORMAT_UNCOMPRESSED_*`).
  - `offset`: Optional. The pixel's first byte; 0 when omitted.

### rtext: text

```haxe
static function DrawText(text:String, posX:Int, posY:Int, fontSize:Int, color:Color):Void
static function MeasureText(text:String, fontSize:Int):Int
static function DrawTextEx(font:Font, text:String, position:Vector2, fontSize:Float, spacing:Float, tint:Color):Void
static function DrawTextPro(font:Font, text:String, position:Vector2, origin:Vector2, rotation:Float, fontSize:Float, spacing:Float, tint:Color):Void
static function DrawTextCodepoint(font:Font, codepoint:Int, position:Vector2, fontSize:Float, tint:Color):Void
static function DrawTextCodepoints(font:Font, codepoints:Array<Int>, codepointCount:Int, position:Vector2, fontSize:Float, spacing:Float, tint:Color):Void
static function SetTextLineSpacing(spacing:Int):Void
static function MeasureTextEx(font:Font, text:String, fontSize:Float, spacing:Float):Vector2
static function GetGlyphIndex(font:Font, codepoint:Int):Int
static function GetGlyphInfo(font:Font, codepoint:Int):GlyphInfo
static function GetGlyphAtlasRec(font:Font, codepoint:Int):Rectangle
static function GetFontDefault():Font
static function IsFontValid(font:Font):Bool
static function UnloadFont(font:Font):Void
static function UnloadFontData(glyphs:Array<GlyphInfo>, glyphCount:Int):Void
static function GenImageFontAtlas(glyphs:Array<GlyphInfo>, glyphRecs:Array<Rectangle>, glyphCount:Int, fontSize:Int, padding:Int, packMethod:Int):Image
static function LoadFontFromImage(image:Image, key:Color, firstChar:Int):Font
static function DrawFPS(posX:Int, posY:Int):Void
static function TextFormat(text:String, args:haxe.extern.Rest<Dynamic>):String
static function TextIsEqual(text1:String, text2:String):Bool
static function TextLength(text:String):Int
static function TextSubtext(text:String, position:Int, length:Int):String
static function TextReplace(text:String, replace:String, by:String):String
static function TextInsert(text:String, insert:String, position:Int):String
static function TextJoin(textList:Array<String>, count:Int, delimiter:String):String
static function TextSplit(text:String, delimiter:Int, count:Array<Int>):Array<String>
static function TextFindIndex(text:String, find:String):Int
static function TextToUpper(text:String):String
static function TextToLower(text:String):String
static function TextToPascal(text:String):String
static function TextToSnake(text:String):String
static function TextToCamel(text:String):String
static function TextToInteger(text:String):Int
static function TextToFloat(text:String):Float
static function LoadUTF8(codepoints:Array<Int>, length:Int):String
static function UnloadUTF8(text:String):Void
static function LoadCodepoints(text:String, count:Array<Int>):Array<Int>
static function UnloadCodepoints(codepoints:Array<Int>):Void
static function GetCodepointCount(text:String):Int
static function GetCodepoint(text:String, codepointSize:Array<Int>):Int
static function GetCodepointNext(text:String, codepointSize:Array<Int>):Int
static function GetCodepointPrevious(text:String, codepointSize:Array<Int>):Int
static function CodepointToUTF8(codepoint:Int, utf8Size:Array<Int>):String
```

- `DrawText`: Draws text in raylib's default font. A size under 10 is drawn at 10, and letters are a tenth of the size apart.
  - `text`: The text; "\n" starts a line.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `fontSize`: The height of a line, in pixels.
  - `color`: The color.
- `MeasureText`: Returns the width text is drawn at by `DrawText`, its widest line's.
  - `text`: The text.
  - `fontSize`: The height of a line, in pixels.
  - returns: The width, in pixels.
- `DrawTextEx`: Draws text in a font.
  - `font`: The font; one with no texture draws as the default font.
  - `text`: The text; "\n" starts a line.
  - `position`: The top-left corner.
  - `fontSize`: The height of a line, in pixels; the font is scaled from its size to it.
  - `spacing`: The space between letters, in pixels.
  - `tint`: The color.
- `DrawTextPro`: Draws text in a font, turned about a point.
  - `font`: The font.
  - `text`: The text.
  - `position`: Where the point goes.
  - `origin`: The point turned about, from the text's top-left corner.
  - `rotation`: The turn, in degrees, clockwise on the screen.
  - `fontSize`: The height of a line, in pixels.
  - `spacing`: The space between letters, in pixels.
  - `tint`: The color.
- `DrawTextCodepoint`: Draws one character in a font.
  - `font`: The font.
  - `codepoint`: The character.
  - `position`: The top-left corner of its line.
  - `fontSize`: The height of a line, in pixels.
  - `tint`: The color.
- `DrawTextCodepoints`: Draws characters in a font, as `DrawTextEx` draws text.
  - `font`: The font.
  - `codepoints`: The characters.
  - `codepointCount`: How many of them.
  - `position`: The top-left corner.
  - `fontSize`: The height of a line, in pixels.
  - `spacing`: The space between letters, in pixels.
  - `tint`: The color.
- `SetTextLineSpacing`: Sets the space between lines that "\n" adds to the size, 2 pixels until set.
  - `spacing`: The space, in pixels.
- `MeasureTextEx`: Returns the size text is drawn at by `DrawTextEx`: its widest line's width, and its lines' height.
  - `font`: The font.
  - `text`: The text.
  - `fontSize`: The height of a line, in pixels.
  - `spacing`: The space between letters, in pixels.
  - returns: The size, in pixels; 0 by 0 for no text or a font with no texture.
- `GetGlyphIndex`: Returns where a character is in a font's glyphs: its own, else the question mark's, else the first.
  - `font`: The font.
  - `codepoint`: The character.
  - returns: The index; 0 for a font that isn't valid (`IsFontValid`).
- `GetGlyphInfo`: Returns a character's glyph in a font, as `GetGlyphIndex` finds it.
  - `font`: The font.
  - `codepoint`: The character.
  - returns: The glyph.
- `GetGlyphAtlasRec`: Returns where a character's glyph is on its font's texture, as `GetGlyphIndex` finds it.
  - `font`: The font.
  - `codepoint`: The character.
  - returns: The rectangle, in texels.
- `GetFontDefault`: Returns raylib's default font: 224 glyphs, Latin-1 from the space, 10 pixels high, made at its first use as raylib makes it, each glyph's image its part of the font's image (`PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA`, white), so `ImageText` draws with it. Its texture goes to the GPU when first drawn.
  - returns: The font.
- `IsFontValid`: Returns whether a font holds glyphs: a size, glyphs, and their places on its texture.
  - `font`: The font.
  - returns: True when it does.
- `UnloadFont`: Frees a font: its texture and its glyphs' images. The default font is never freed.
  - `font`: The font.
- `UnloadFontData`: Frees glyphs' images.
  - `glyphs`: The glyphs.
  - `glyphCount`: How many of them.
- `GenImageFontAtlas`: Packs glyphs' images into one image, a font's texture once loaded, as raylib does: its glyphs' places go into `glyphRecs`, the image is white with the glyphs' coverage as alpha (`PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA`), and its bottom-right 3 by 3 texels are opaque white.
  - `glyphs`: The glyphs, their images 8-bit grayscale.
  - `glyphRecs`: Receives each glyph's place, replacing what it held.
  - `glyphCount`: How many glyphs; 0 for 95.
  - `fontSize`: The font's size, a row's height.
  - `padding`: The empty texels around each glyph.
  - `packMethod`: 0 packs rows in order; 1 packs by height, as raylib's skyline packer.
  - returns: The image.

  Its size is estimated from the glyphs' widths, a power of two wide; when packing rows in order (`packMethod` 0) runs out of rows, it is made twice as high, as many times as it needs, so every glyph has its place. The skyline packer (1) leaves a glyph that doesn't fit out, with a warning, placed at 2147483648 across and down, as raylib's.
- `LoadFontFromImage`: Makes a font from an image of glyphs, as raylib's does: the glyphs in rows on a key color, the key's border before the first glyph giving the space between glyphs and between rows; each glyph a run of pixels that aren't the key, numbered from a first character. The key becomes clear on the font's texture. An image with no such border gives the default font. A glyph's height ends at the image's bottom and its width at its right edge, as raylib's scan has them. At most 256 glyphs are read, where raylib's writes past its 256.
  - `image`: The image, in any uncompressed format.
  - `key`: The color around the glyphs.
  - `firstChar`: The first glyph's character.
  - returns: The font.
- `DrawFPS`: Draws the frames a second, as "60 FPS", in green.
  - `posX`: The left edge.
  - `posY`: The top edge.
- `TextFormat`: Formats text as C's `printf` does. It takes `%d` and `%i`, `%u`, `%f` and `%F` (6 places unless a precision is given, as in `%.2f`), `%e`, `%g`, `%x`, `%X`, `%o`, `%c` (a character code), `%s` and `%%`. It also takes C's flags (`-`, `0`, `+`, space, `#`), widths and precisions, as in `%5d`, `%-8s`, `%03i` and `%*d`. C's length modifiers (`l`, `ll`, `h`, `z`) are read and ignored.
  - `text`: The format.
  - `args`: The values, one for each conversion.
  - returns: The text; empty for a null format.

  As raylib's, the text is at most 1023 UTF-8 bytes: longer, it is cut to its first 1020 and "..." ends it.
- `TextIsEqual`: Returns whether two texts are the same.
  - `text1`: The first text.
  - `text2`: The second text.
  - returns: True when they are; false when either is null.
- `TextLength`: Returns the length of text in UTF-8 bytes, as raylib counts it: "héllo" is 6. The text functions' positions and lengths are all in these bytes, where `String.length` counts otherwise, and not alike on every target.
  - `text`: The text.
  - returns: The length, in bytes; 0 for null text.
- `TextSubtext`: Returns a piece of text, by its place in UTF-8 bytes. The piece ends with the text, and is at most 1023 bytes, as raylib's.
  - `text`: The text.
  - `position`: Where the piece starts, in bytes from the start.
  - `length`: How long it is, in bytes.
  - returns: The piece; empty for null text, a position below 0 or at or past the end, or a length below 1.

  A character the piece cuts through is a "?" for each of its bytes taken, as raylib draws it.
- `TextReplace`: Returns text with every piece of it that matches replaced, from the start, each match after the one before.
  - `text`: The text.
  - `replace`: The text replaced.
  - `by`: The text put in its place.
  - returns: The new text; null when any is null or `replace` is empty.
- `TextInsert`: Returns text with other text put in at a place in UTF-8 bytes. As raylib's, the result is at most 1022 bytes.
  - `text`: The text.
  - `insert`: The text put in.
  - `position`: Where, in bytes from the start, clamped to the end.
  - returns: The new text; empty when either is null, the position is below 0, or the result is too long.

  A character the place cuts through is a "?" for each of its bytes, as raylib draws it.
- `TextJoin`: Returns texts joined into one, a delimiter between each two.
  - `textList`: The texts; a null one is empty.
  - `count`: How many of them.
  - `delimiter`: The text between them; null for none.
  - returns: The joined text.

  As raylib's, the result is at most 1023 UTF-8 bytes: a text that would take it past them, with its delimiter, is left out, and the texts after it are still joined.
- `TextSplit`: Returns the pieces of text between a delimiter: one more than the delimiters it holds, an empty one between two together.
  - `text`: The text.
  - `delimiter`: The byte between pieces, such as `",".code`.
  - `count`: Receives how many pieces there are, at its index 0; 0 for null text.
  - returns: The pieces; none for null text.

  As raylib's, the delimiter is one byte (its low 8 bits), only the text's first 1023 UTF-8 bytes are read, and there are at most 128 pieces, the last of them empty when the text holds more. A character a piece cuts through is a "?" for each of its bytes.
- `TextFindIndex`: Returns where text is first found in other text, in UTF-8 bytes from the start, as `TextSubtext` takes it.
  - `text`: The text searched.
  - `find`: The text found; empty text is found at 0.
  - returns: The position, in bytes; -1 when it isn't there or either is null.
- `TextToUpper`: Returns text with its letters a to z made capitals, as raylib makes them. Other letters, as "é", are unchanged.
  - `text`: The text.
  - returns: The new text; empty for null text.
- `TextToLower`: Returns text with its capitals A to Z made lower case, as raylib makes them. Other letters, as "É", are unchanged.
  - `text`: The text.
  - returns: The new text; empty for null text.
- `TextToPascal`: Returns snake-case text in Pascal case: "hello_world" is "HelloWorld". Each run of underscores is dropped, and the first letter and the one after each run are made capitals if they are a to z. As raylib's, the result is at most 1023 UTF-8 bytes.
  - `text`: The text.
  - returns: The new text; empty for null text.
- `TextToSnake`: Returns Pascal- or camel-case text, or words, in snake case: "helloWorld" and "Hello World" are "hello_world", "HTTPServer" is "http_server". Each capital A to Z is made lower case, an underscore before it when it follows a letter a to z, or a capital with a letter a to z after it; a space is an underscore. No underscore is added where the text so far ends in one, nor at its start.
  - `text`: The text.
  - returns: The new text; empty for null text.

  As raylib's, the result is at most 1023 UTF-8 bytes.
- `TextToCamel`: Returns snake-case text in camel case: "hello_world" is "helloWorld". Each run of underscores is dropped, the letter after it made a capital if it is a to z, and the first letter made lower case if it is A to Z. As raylib's, the result is at most 1023 UTF-8 bytes.
  - `text`: The text.
  - returns: The new text; empty for null text.
- `TextToInteger`: Returns the whole number text starts with, as raylib reads it: an optional "+" or "-", then the digits up to the first that isn't one. Nothing else is skipped, spaces neither; a number past 32 bits wraps.
  - `text`: The text.
  - returns: The number; 0 when it starts with none, or for null text.
- `TextToFloat`: Returns the number text starts with, as raylib reads it: an optional "+" or "-", digits, then a "." and more digits. An exponent, as in "1e3", isn't read, and nothing is skipped.
  - `text`: The text.
  - returns: The number; 0 when it starts with none, or for null text.

  It is worked out in 32-bit floats, digit by digit, as raylib works it, so the result is the float raylib returns: "0.1" is 0.100000001490116.
- `LoadUTF8`: Returns the text of characters.
  - `codepoints`: The characters' codes.
  - `length`: How many of them.
  - returns: The text; a code past 0x10FFFF adds nothing.
- `UnloadUTF8`: Does nothing: text from `LoadUTF8` is freed by the garbage collector.
  - `text`: The text.
- `LoadCodepoints`: Returns the codes of text's characters.
  - `text`: The text.
  - `count`: Receives how many there are, at its index 0; 0 for null text.
  - returns: The codes; null for null text.
- `UnloadCodepoints`: Does nothing: codes from `LoadCodepoints` are freed by the garbage collector.
  - `codepoints`: The codes.
- `GetCodepointCount`: Returns how many characters text holds: "héllo→" holds 6, in 9 bytes.
  - `text`: The text.
  - returns: The count; 0 for null text.
- `GetCodepoint`: Returns the code of text's first character, checked as RFC 3629 has UTF-8, as raylib checks it.
  - `text`: The text.
  - `codepointSize`: Receives the character's length in UTF-8 bytes, at its index 0: what to move past it by; 1 for empty or null text.
  - returns: The code; 0 for empty text, '?' (0x3F) for null text.
- `GetCodepointNext`: Returns the code of text's first character.
  - `text`: The text.
  - `codepointSize`: Receives the character's length in UTF-8 bytes, at its index 0: what to move past it by, as in `TextSubtext(text, codepointSize[0], TextLength(text))`; 1 for empty or null text.
  - returns: The code; 0 for empty text, '?' (0x3F) for null text.
- `GetCodepointPrevious`: Returns the code of text's last character: the one before where it ends, as raylib's finds the one before a place in text.
  - `text`: The text; `TextSubtext(text, 0, position)` gives the character before a position.
  - `codepointSize`: Receives the character's length in UTF-8 bytes, at its index 0: what to move back by; 1 for empty or null text.
  - returns: The code; '?' (0x3F) for empty or null text.
- `CodepointToUTF8`: Returns a character as text.
  - `codepoint`: The character's code.
  - `utf8Size`: Receives its length in UTF-8 bytes, at its index 0; 0 for a code past 0x10FFFF.
  - returns: The text; empty for a code past 0x10FFFF.

### rmodels: 3D shapes, models, meshes and rays

```haxe
static function DrawLine3D(startPos:Vector3, endPos:Vector3, color:Color):Void
static function DrawPoint3D(position:Vector3, color:Color):Void
static function DrawCircle3D(center:Vector3, radius:Float, rotationAxis:Vector3, rotationAngle:Float, color:Color):Void
static function DrawTriangle3D(v1:Vector3, v2:Vector3, v3:Vector3, color:Color):Void
static function DrawTriangleStrip3D(points:Array<Vector3>, pointCount:Int, color:Color):Void
static function DrawCube(position:Vector3, width:Float, height:Float, length:Float, color:Color):Void
static function DrawCubeV(position:Vector3, size:Vector3, color:Color):Void
static function DrawCubeWires(position:Vector3, width:Float, height:Float, length:Float, color:Color):Void
static function DrawCubeWiresV(position:Vector3, size:Vector3, color:Color):Void
static function DrawSphere(centerPos:Vector3, radius:Float, color:Color):Void
static function DrawSphereEx(centerPos:Vector3, radius:Float, rings:Int, slices:Int, color:Color):Void
static function DrawSphereWires(centerPos:Vector3, radius:Float, rings:Int, slices:Int, color:Color):Void
static function DrawCylinder(position:Vector3, radiusTop:Float, radiusBottom:Float, height:Float, sides:Int, color:Color):Void
static function DrawCylinderEx(startPos:Vector3, endPos:Vector3, startRadius:Float, endRadius:Float, sides:Int, color:Color):Void
static function DrawCylinderWires(position:Vector3, radiusTop:Float, radiusBottom:Float, height:Float, sides:Int, color:Color):Void
static function DrawCylinderWiresEx(startPos:Vector3, endPos:Vector3, startRadius:Float, endRadius:Float, sides:Int, color:Color):Void
static function DrawCapsule(startPos:Vector3, endPos:Vector3, radius:Float, slices:Int, rings:Int, color:Color):Void
static function DrawCapsuleWires(startPos:Vector3, endPos:Vector3, radius:Float, slices:Int, rings:Int, color:Color):Void
static function DrawPlane(centerPos:Vector3, size:Vector2, color:Color):Void
static function DrawRay(ray:Ray, color:Color):Void
static function DrawGrid(slices:Int, spacing:Float):Void
static function DrawBoundingBox(box:BoundingBox, color:Color):Void
static function DrawBillboard(camera:Camera, texture:Texture2D, position:Vector3, scale:Float, tint:Color):Void
static function DrawBillboardRec(camera:Camera, texture:Texture2D, source:Rectangle, position:Vector3, size:Vector2, tint:Color):Void
static function DrawBillboardPro(camera:Camera, texture:Texture2D, source:Rectangle, position:Vector3, up:Vector3, size:Vector2, origin:Vector2, rotation:Float, tint:Color):Void
static function LoadModelFromMesh(mesh:Mesh):Model
static function IsModelValid(model:Model):Bool
static function UnloadModel(model:Model):Void
static function DrawModel(model:Model, position:Vector3, scale:Float, tint:Color):Void
static function DrawModelEx(model:Model, position:Vector3, rotationAxis:Vector3, rotationAngle:Float, scale:Vector3, tint:Color):Void
static function DrawModelWires(model:Model, position:Vector3, scale:Float, tint:Color):Void
static function DrawModelWiresEx(model:Model, position:Vector3, rotationAxis:Vector3, rotationAngle:Float, scale:Vector3, tint:Color):Void
static function DrawModelPoints(model:Model, position:Vector3, scale:Float, tint:Color):Void
static function DrawModelPointsEx(model:Model, position:Vector3, rotationAxis:Vector3, rotationAngle:Float, scale:Vector3, tint:Color):Void
static function DrawMesh(mesh:Mesh, material:Material, transform:Matrix):Void
static function DrawMeshInstanced(mesh:Mesh, material:Material, transforms:Array<Matrix>, instances:Int):Void
static function UploadMesh(mesh:Mesh, isDynamic:Bool):Void
static function UpdateMeshBuffer(mesh:Mesh, index:Int, data:Dynamic, dataSize:Int, offset:Int):Void
static function UnloadMesh(mesh:Mesh):Void
static function GenMeshPoly(sides:Int, radius:Float):Mesh
static function GenMeshPlane(width:Float, length:Float, resX:Int, resZ:Int):Mesh
static function GenMeshCube(width:Float, height:Float, length:Float):Mesh
static function GenMeshSphere(radius:Float, rings:Int, slices:Int):Mesh
static function GenMeshHemiSphere(radius:Float, rings:Int, slices:Int):Mesh
static function GenMeshCylinder(radius:Float, height:Float, slices:Int):Mesh
static function GenMeshCone(radius:Float, height:Float, slices:Int):Mesh
static function GenMeshTorus(radius:Float, size:Float, radSeg:Int, sides:Int):Mesh
static function GenMeshKnot(radius:Float, size:Float, radSeg:Int, sides:Int):Mesh
static function GenMeshHeightmap(heightmap:Image, size:Vector3):Mesh
static function GenMeshCubicmap(cubicmap:Image, cubeSize:Vector3):Mesh
static function GenMeshTangents(mesh:Mesh):Void
static function UpdateModelAnimationBones(model:Model, anim:ModelAnimation, frame:Float):Void
static function UpdateModelAnimation(model:Model, anim:ModelAnimation, frame:Float):Void
static function UpdateModelAnimationEx(model:Model, animA:ModelAnimation, frameA:Float, animB:ModelAnimation, frameB:Float, blend:Float):Void
static function UnloadModelAnimation(anim:ModelAnimation):Void
static function UnloadModelAnimations(animations:Array<ModelAnimation>, animCount:Int):Void
static function IsModelAnimationValid(model:Model, anim:ModelAnimation):Bool
static function LoadMaterialDefault():Material
static function IsMaterialValid(material:Material):Bool
static function UnloadMaterial(material:Material):Void
static function SetMaterialTexture(material:Material, mapType:Int, texture:Texture2D):Void
static function SetModelMeshMaterial(model:Model, meshId:Int, materialId:Int):Void
static function GetMeshBoundingBox(mesh:Mesh):BoundingBox
static function GetModelBoundingBox(model:Model):BoundingBox
static function CheckCollisionBoxes(box1:BoundingBox, box2:BoundingBox):Bool
static function CheckCollisionSpheres(center1:Vector3, radius1:Float, center2:Vector3, radius2:Float):Bool
static function CheckCollisionBoxSphere(box:BoundingBox, center:Vector3, radius:Float):Bool
static function GetRayCollisionSphere(ray:Ray, center:Vector3, radius:Float):RayCollision
static function GetRayCollisionBox(ray:Ray, box:BoundingBox):RayCollision
static function GetRayCollisionMesh(ray:Ray, mesh:Mesh, transform:Matrix):RayCollision
static function GetRayCollisionTriangle(ray:Ray, p1:Vector3, p2:Vector3, p3:Vector3):RayCollision
static function GetRayCollisionQuad(ray:Ray, p1:Vector3, p2:Vector3, p3:Vector3, p4:Vector3):RayCollision
```

- `DrawLine3D`: Draws a line in 3D.
  - `startPos`: The start.
  - `endPos`: The end.
  - `color`: The color.
- `DrawPoint3D`: Draws a point in 3D, as raylib does: a line 0.1 long toward +z.
  - `position`: The point.
  - `color`: The color.
- `DrawCircle3D`: Draws a circle's outline in 3D, 36 lines, on the XY plane turned about an axis.
  - `center`: Its center.
  - `radius`: Its radius.
  - `rotationAxis`: The axis it is turned about.
  - `rotationAngle`: The angle, in degrees.
  - `color`: The color.
- `DrawTriangle3D`: Draws a filled triangle in 3D, its corners counterclockwise from the side it faces.
  - `v1`: A corner.
  - `v2`: The next.
  - `v3`: The last.
  - `color`: The color.
- `DrawTriangleStrip3D`: Draws a strip of triangles in 3D: each point after the second makes a triangle with the two before it.
  - `points`: The points.
  - `pointCount`: How many of them; fewer than 3 draws nothing.
  - `color`: The color.
- `DrawCube`: Draws a filled box, each face with its normal.
  - `position`: Its center.
  - `width`: Its size along x.
  - `height`: Along y.
  - `length`: Along z.
  - `color`: The color.
- `DrawCubeV`: Draws a filled box.
  - `position`: Its center.
  - `size`: Its size.
  - `color`: The color.
- `DrawCubeWires`: Draws a box's edges.
  - `position`: Its center.
  - `width`: Its size along x.
  - `height`: Along y.
  - `length`: Along z.
  - `color`: The color.
- `DrawCubeWiresV`: Draws a box's edges.
  - `position`: Its center.
  - `size`: Its size.
  - `color`: The color.
- `DrawSphere`: Draws a filled sphere, 16 rings and 16 slices.
  - `centerPos`: Its center.
  - `radius`: Its radius.
  - `color`: The color.
- `DrawSphereEx`: Draws a filled sphere: rings bands of slices, from the top, each vertex with its normal.
  - `centerPos`: Its center.
  - `radius`: Its radius.
  - `rings`: Bands top to bottom.
  - `slices`: Slices around.
  - `color`: The color.
- `DrawSphereWires`: Draws a sphere's wires: rings bands of slices, from the top, each face's longitude, latitude and diagonal lines.
  - `centerPos`: Its center.
  - `radius`: Its radius.
  - `rings`: Bands top to bottom.
  - `slices`: Slices around.
  - `color`: The color.
- `DrawCylinder`: Draws a filled cylinder standing on the XZ plane, or a cone when its top's radius is 0.
  - `position`: Its base's center.
  - `radiusTop`: Its top's radius.
  - `radiusBottom`: Its base's.
  - `height`: Its height.
  - `sides`: Its sides, at least 3.
  - `color`: The color.
- `DrawCylinderEx`: Draws a filled cylinder from one point to another, or a cone when a radius is 0.
  - `startPos`: Its base's center.
  - `endPos`: Its top's.
  - `startRadius`: Its base's radius.
  - `endRadius`: Its top's.
  - `sides`: Its sides, at least 3.
  - `color`: The color.
- `DrawCylinderWires`: Draws a cylinder's wires standing on the XZ plane, or a cone's when its top's radius is 0.
  - `position`: Its base's center.
  - `radiusTop`: Its top's radius.
  - `radiusBottom`: Its base's.
  - `height`: Its height.
  - `sides`: Its sides, at least 3.
  - `color`: The color.
- `DrawCylinderWiresEx`: Draws a cylinder's wires from one point to another, or a cone's when a radius is 0.
  - `startPos`: Its base's center.
  - `endPos`: Its top's.
  - `startRadius`: Its base's radius.
  - `endRadius`: Its top's.
  - `sides`: Its sides, at least 3.
  - `color`: The color.
- `DrawCapsule`: Draws a filled capsule: a cylinder with half a sphere on each end, their centers the two points.
  - `startPos`: One end's center.
  - `endPos`: The other's.
  - `radius`: Its radius.
  - `slices`: Slices around, at least 3.
  - `rings`: Rings in each half sphere, at least 1.
  - `color`: The color.
- `DrawCapsuleWires`: Draws a capsule's wires: a cylinder with half a sphere on each end, their centers the two points.
  - `startPos`: One end's center.
  - `endPos`: The other's.
  - `radius`: Its radius.
  - `slices`: Slices around, at least 3.
  - `rings`: Rings in each half sphere, at least 1.
  - `color`: The color.
- `DrawPlane`: Draws a flat rectangle on the XZ plane, facing up.
  - `centerPos`: Its center.
  - `size`: Its size along x and z.
  - `color`: The color.
- `DrawRay`: Draws a ray as a line 10000 long.
  - `ray`: The ray.
  - `color`: The color.
- `DrawGrid`: Draws a grid on the XZ plane, centered on the origin, its center lines darker, as raylib's.
  - `slices`: The lines each way.
  - `spacing`: The space between them.
- `DrawBoundingBox`: Draws a bounding box's edges.
  - `box`: The box.
  - `color`: The color.
- `DrawBillboard`: Draws a texture facing the camera, turning about y alone, at a height of scale and its own proportions.
  - `camera`: The camera.
  - `texture`: The texture.
  - `position`: Its center.
  - `scale`: Its height.
  - `tint`: The tint.
- `DrawBillboardRec`: Draws part of a texture facing the camera, turning about y alone.
  - `camera`: The camera.
  - `texture`: The texture.
  - `source`: The part, in its pixels.
  - `position`: Its center.
  - `size`: Its size; a negative one flips it.
  - `tint`: The tint.
- `DrawBillboardPro`: Draws part of a texture facing the camera's right and an up of its own, turned about the way it faces.
  - `camera`: The camera.
  - `texture`: The texture.
  - `source`: The part, in its pixels.
  - `position`: Where its origin is.
  - `up`: Its up.
  - `size`: Its size; a negative one flips it.
  - `origin`: The point of it at the position, from its bottom left, in the size's units.
  - `rotation`: How far it turns about its origin, in degrees.
  - `tint`: The tint.
- `LoadModelFromMesh`: Makes a model of one mesh, with the default material. The model takes over the program's hold on the mesh, as a raylib program doesn't unload a mesh it gave a model: `UnloadModel` frees it, and a later `UnloadMesh` does nothing.
  - `mesh`: The mesh.
  - returns: The model.
- `IsModelValid`: Returns whether a model has meshes.
  - `model`: The model.
  - returns: True when it has.
- `UnloadModel`: Frees a model: it lets go of its meshes and materials, and what no one else holds is freed with it (docs/DECISIONS.md 25): a mesh's GPU buffers, a material's maps' textures and its shader, each when nothing else holds it (another load of its file, another model, the program); the default shader and texture stay. The model is left empty, so unloading it again does nothing.
  - `model`: The model.

  raylib's frees only the meshes, and leaves the textures and shaders to the program. Where helix-raylib's differs: a texture or shader copied out of a material (`var t = map.texture`) and used after the model is unloaded is freed, where raylib's leaks it; and a material or mesh shared between models works, where raylib's C frees it twice.
- `DrawModel`: Draws a model at a position and a scale, its materials' colors times a tint.
  - `model`: The model.
  - `position`: Where.
  - `scale`: The scale, the same on each axis.
  - `tint`: The tint.
- `DrawModelEx`: Draws a model scaled, turned about an axis and moved, after its own transform.
  - `model`: The model.
  - `position`: Where.
  - `rotationAxis`: The axis.
  - `rotationAngle`: The angle, in degrees.
  - `scale`: The scale on each axis.
  - `tint`: The tint.
- `DrawModelWires`: Draws a model's triangles as their edges, as `DrawModel` places it, through rlgl's wire mode.
  - `model`: The model.
  - `position`: Where.
  - `scale`: The scale, the same on each axis.
  - `tint`: The tint.
- `DrawModelWiresEx`: Draws a model's triangles as their edges, as `DrawModelEx` places it, through rlgl's wire mode.
  - `model`: The model.
  - `position`: Where.
  - `rotationAxis`: The axis.
  - `rotationAngle`: The angle, in degrees.
  - `scale`: The scale on each axis.
  - `tint`: The tint.
- `DrawModelPoints`: Draws a model's triangles as their corners, one pixel each, as `DrawModel` places it, through rlgl's point mode with culling off.
  - `model`: The model.
  - `position`: Where.
  - `scale`: The scale, the same on each axis.
  - `tint`: The tint.

  Each index of a mesh's triangles is a point, or each vertex of its whole triangles when it has no indices (a cloud of points is a mesh of vertices alone). Culling is on after it, as raylib leaves it.
- `DrawModelPointsEx`: Draws a model's triangles as their corners, one pixel each, as `DrawModelEx` places it, through rlgl's point mode with culling off.
  - `model`: The model.
  - `position`: Where.
  - `rotationAxis`: The axis.
  - `rotationAngle`: The angle, in degrees.
  - `scale`: The scale on each axis.
  - `tint`: The tint.

  Each index of a mesh's triangles is a point, or each vertex of its whole triangles when it has no indices. Culling is on after it, as raylib leaves it.
- `DrawMesh`: Draws a mesh with a material and a transform.
  - `mesh`: The mesh.
  - `material`: The material.
  - `transform`: The transform.

  The material's maps bind as raylib's: the first three at `texture0` to `texture2`, and each other map with a texture at the sampler `shader.locs[SHADER_LOC_MAP_DIFFUSE + index]` names, or at a sampler set to its index with `SetShaderValue` (raylib's skybox sets its `samplerCube` to `MATERIAL_MAP_CUBEMAP`). `MATERIAL_MAP_CUBEMAP`, `MATERIAL_MAP_IRRADIANCE` and `MATERIAL_MAP_PREFILTER` bind a cubemap (`LoadTextureCubemap`) to a `samplerCube`, the rest a 2D texture to a `sampler2D`; a texture of the other kind binds nothing.
- `DrawMeshInstanced`: Draws a mesh many times in one draw, as raylib 5.5's does: each instance is placed by its own transform, which the material's shader takes as a `mat4` attribute at `shader.locs[SHADER_LOC_MATRIX_MODEL]` and applies itself (raylib's instancing example sets it with `GetShaderLocationAttrib(shader, "instanceTransform")`). `mvp` is the camera's alone, and `matNormal` the identity. A shader without a `mat4` attribute there draws nothing, with a warning. The mesh's attributes and the transforms are a buffer each, eight at most, so a shader reading every one of raylib's attributes besides the transforms can't be drawn.
  - `mesh`: The mesh.
  - `material`: Its material: the shader, the diffuse color and the textures.
  - `transforms`: The instances' transforms.
  - `instances`: How many instances, at most the transforms given.
- `UploadMesh`: Sends a mesh's vertices to the GPU, so it can be drawn. A mesh not sent goes when it is first drawn, as `LoadModelAsync`'s and the `GenMesh*` functions' do.
  - `mesh`: The mesh.
  - `isDynamic`: Whether it will change (raylib names it `dynamic`, a Haxe keyword); any mesh here can be changed by `UpdateMeshBuffer`, so it is ignored.

  An attribute the mesh has no array for reads a default in a shader: texture coordinates 0, 0, normals 0, 0, 1, colors white, tangents 1, 0, 0, 1, second texture coordinates, bone ids and bone weights 0.
- `UpdateMeshBuffer`: Changes part of one of a mesh's buffers on the GPU, as raylib's: the mesh's own arrays stay as they were. Draws asked for before it keep what was there; those after see the change.
  - `mesh`: The mesh, uploaded (`UploadMesh`, or drawn once); one that isn't changes nothing.
  - `index`: The buffer: 0 positions, 1 texture coordinates, 2 normals, 3 colors, 4 tangents, 5 second texture coordinates, 6 indices. One the mesh has no array for changes nothing.
  - `data`: The new values: raylib's bytes (`haxe.io.Bytes`: 32-bit floats, colors a byte each, indices 16-bit), or an array of the numbers (colors 0 to 255).
  - `dataSize`: How many bytes they are, as raylib counts them.
  - `offset`: Where they go in the buffer, in raylib's bytes.
- `UnloadMesh`: Lets go of the program's hold on a mesh, freeing its GPU buffers unless a model still holds it (docs/DECISIONS.md 25). A mesh given to `LoadModelFromMesh`, or already freed, is left: the model frees it.
  - `mesh`: The mesh.
- `GenMeshPoly`: Makes a flat regular polygon on the XZ plane, facing up, centered on the origin: a triangle a side, with no indices, its texture coordinates 0.
  - `sides`: Its sides; fewer than 3 make an empty mesh.
  - `radius`: Its corners' distance from the center.
  - returns: The mesh.
- `GenMeshPlane`: Makes a flat mesh on the XZ plane, facing up, centered on the origin: a grid of vertices shared by its cells' triangles.
  - `width`: Along x.
  - `length`: Along z.
  - `resX`: Cells along x.
  - `resZ`: Cells along z.
  - returns: The mesh.
- `GenMeshCube`: Makes a box mesh, centered on the origin: four vertices a face, each face's texture its whole.
  - `width`: Along x.
  - `height`: Along y.
  - `length`: Along z.
  - returns: The mesh.
- `GenMeshSphere`: Makes a sphere mesh, centered on the origin, its poles on z, three vertices a triangle with no indices, as raylib's (par_shapes').
  - `radius`: Its radius.
  - `rings`: Rings pole to pole, at least 3.
  - `slices`: Slices around, at least 3.
  - returns: The mesh; empty for fewer rings or slices.
- `GenMeshHemiSphere`: Makes half a sphere, open at its base, on the side of +y from the origin, three vertices a triangle with no indices.
  - `radius`: Its radius; a negative one is 0.
  - `rings`: Rings from the pole, at least 3.
  - `slices`: Slices around, at least 3.
  - returns: The mesh; empty for fewer rings or slices.
- `GenMeshCylinder`: Makes a closed cylinder standing on the XZ plane from the origin, three vertices a triangle with no indices.
  - `radius`: Its radius.
  - `height`: Its height.
  - `slices`: Slices around, at least 3.
  - returns: The mesh; empty for fewer slices.
- `GenMeshCone`: Makes a closed cone standing on the XZ plane from the origin, three vertices a triangle with no indices.
  - `radius`: Its base's radius.
  - `height`: Its height.
  - `slices`: Slices around, at least 3.
  - returns: The mesh; empty for fewer slices.
- `GenMeshTorus`: Makes a torus on the XY plane, centered on the origin, three vertices a triangle with no indices.
  - `radius`: The tube's radius against the ring's, 0.1 to 1 (others are clamped to it).
  - `size`: The torus's width, out to the ring's middle on each side.
  - `radSeg`: Slices around the ring, at least 3.
  - `sides`: Slices around the tube, at least 3.
  - returns: The mesh; empty for fewer slices.
- `GenMeshKnot`: Makes a trefoil knot, centered on the origin, three vertices a triangle with no indices.
  - `radius`: The tube's radius, in tenths, 0.5 to 3 (others are clamped to it).
  - `size`: The knot's scale.
  - `radSeg`: Slices along the knot, at least 3.
  - `sides`: Slices around the tube, at least 3.
  - returns: The mesh; empty for fewer slices.
- `GenMeshHeightmap`: Makes terrain from an image: a vertex a pixel, from the origin along +x and +z, each the height of its pixel's gray (red, green and blue averaged), two triangles a cell with a flat normal each, three vertices a triangle with no indices.
  - `heightmap`: The image.
  - `size`: The terrain's size: x and z across the image, y the height of white.
  - returns: The mesh.
- `GenMeshCubicmap`: Makes a maze of cubes from an image, a cube a pixel centered on it from the origin: a white pixel a wall, its faces where its neighbors are black or the map ends, and its top and bottom; a black pixel a floor and a ceiling, facing in. The texture is split in four: walls from its top left (right, front) and top right (left, back), tops from its bottom left and bottoms from its bottom right. Three vertices a triangle, with no indices.
  - `cubicmap`: The image.
  - `cubeSize`: A cube's size: x along the image's width, z along its height, y the walls' height.
  - returns: The mesh.
- `GenMeshTangents`: Computes a mesh's tangents from its positions, texture coordinates and normals: each triangle's direction of u, by its indices when it has them, summed at each of its vertices, made square to the vertex's normal and of length 1, w the side the summed direction of v is on.
  - `mesh`: The mesh; one without positions, texture coordinates or normals is unchanged.

  A vertex whose tangent comes out of length near 0, or along its normal, takes one square to the normal: x when the normal is mostly z, else (-y, x, 0) of the normal, w 1.
- `UpdateModelAnimationBones`: Poses a model's bones by a frame of an animation, as raylib 6.2's: the frame's whole part and the next mixed by its fraction (a 5.5 program's whole frames work as they did), each wrapped to the animation's frames; each bone's matrix then its bind pose's inverse and the pose, in each mesh's `boneMatrices`. Its vertices don't move: a skinning shader moves them as they are drawn, or `UpdateModelAnimation` on the CPU. Nothing for a model without bones or an animation without frames.
  - `model`: The model.
  - `anim`: The animation, of the model's skeleton (`IsModelAnimationValid`).
  - `frame`: The frame, from 0.
- `UpdateModelAnimation`: Poses a model by a frame of an animation, as raylib 6.2's: its bones as `UpdateModelAnimationBones` poses them, and each skinned mesh drawn in that pose until the next call. Draws asked for before keep the pose they were asked with, so one model can be posed and drawn many times in a frame.
  - `model`: The model.
  - `anim`: The animation, of the model's skeleton.
  - `frame`: The frame, from 0, fractional.

  How a mesh is moved depends on its material's shader. Under raylib's default shader it is moved on the GPU, by a skinned version of that shader. Under a shader of the program's own that declares the bone inputs, as raylib's `skinning.vs` does (`vertexBoneIds`, `vertexBoneWeights` and `uniform mat4 boneMatrices[N]`), or that includes `<helix/raylib/shaders/skinning.glsl>`, it is moved on the GPU by that shader. Under a shader of the program's own without them it is moved on the CPU, every vertex each call, which is slow for many vertices or many models: an animated model under a lighting shader of the program's own draws fastest when that shader declares `skinning.vs`'s inputs or includes `skinning.glsl`.

  `animVertices` and `animNormals` hold the moved positions and normals (each normal by its bones' matrices inverted and transposed, not normalized), worked out on the CPU when first read; a mesh whose shader moves it itself is left as raylib leaves it.
- `UpdateModelAnimationEx`: Poses a model by two animations mixed, raylib 6.2's own: each at its frame as `UpdateModelAnimation` takes one, then the two mixed by the blend, the bones and the vertices as it moves them, on the GPU or the CPU as `UpdateModelAnimation` says. Note that, as raylib's, a frame is wrapped to its animation's frames before its fraction is taken, so past the last frame it holds the frame it wrapped to. Nothing for a blend outside 0 to 1.
  - `model`: The model.
  - `animA`: The first animation.
  - `frameA`: Its frame, fractional.
  - `animB`: The second animation.
  - `frameB`: Its frame, fractional.
  - `blend`: How much of the second: 0 the first alone, 1 the second alone.
- `UnloadModelAnimation`: Frees an animation's frames: its poses and bones are let go, its counts 0.
  - `anim`: The animation.
- `UnloadModelAnimations`: Frees animations' frames, each as `UnloadModelAnimation` frees one.
  - `animations`: The animations.
  - `animCount`: How many of them.
- `IsModelAnimationValid`: Returns whether an animation moves a model's skeleton, as raylib 6.2 checks it: whether they have as many bones.
  - `model`: The model.
  - `anim`: The animation.
  - returns: True when their bone counts match.
- `LoadMaterialDefault`: Returns raylib's default material: the default shader, the diffuse map raylib's default texture (a 1x1 white pixel), the diffuse and specular colors white, and the other maps empty. The program holds it until `UnloadMaterial`; a model it is put in holds it too.
  - returns: The material.
- `IsMaterialValid`: Returns whether a material can draw: whether it has maps and a shader.
  - `material`: The material.
  - returns: True when its maps aren't null and its shader's id is above 0.
- `UnloadMaterial`: Lets go of a material (docs/DECISIONS.md 25): the program's hold from `LoadMaterialDefault`, or, for a model's material, the model's. When no one else holds it, its shader is unloaded unless it is the default one, and its maps let go of their textures: each texture is freed when nothing else holds it (a texture the program still holds, or another load of a file shares, stays). Releasing it again does nothing.
  - `material`: The material.
- `SetMaterialTexture`: Sets a texture on a material's map, which holds it from then on (`MaterialMap.texture`).
  - `material`: The material.
  - `mapType`: The map (`MATERIAL_MAP_*`).
  - `texture`: The texture.
- `SetModelMeshMaterial`: Sets the material a model's mesh draws with.
  - `model`: The model.
  - `meshId`: The mesh.
  - `materialId`: The material.
- `GetMeshBoundingBox`: Returns a mesh's bounds: the least and the most of its positions; 0 for a mesh without them.
  - `mesh`: The mesh.
  - returns: The box.
- `GetModelBoundingBox`: Returns a model's bounds: its meshes' together, its least and most corners then moved by its transform, as raylib's (a turned model's box is not its bounds; transform its eight corners for those).
  - `model`: The model.
  - returns: The box.
- `CheckCollisionBoxes`: Returns whether two boxes overlap, touching included.
  - `box1`: One.
  - `box2`: The other.
  - returns: True when they overlap.
- `CheckCollisionSpheres`: Returns whether two spheres overlap, touching included.
  - `center1`: One's center.
  - `radius1`: Its radius.
  - `center2`: The other's center.
  - `radius2`: Its radius.
  - returns: True when they overlap.
- `CheckCollisionBoxSphere`: Returns whether a box and a sphere overlap, touching included.
  - `box`: The box.
  - `center`: The sphere's center.
  - `radius`: Its radius.
  - returns: True when they overlap.
- `GetRayCollisionSphere`: Returns where a ray meets a sphere: the near side from outside, the far side from inside (its normal then pointing in).
  - `ray`: The ray.
  - `center`: The sphere's center.
  - `radius`: Its radius.
  - returns: The hit.

  A sphere wholly behind the ray is missed. On a miss the point, normal and distance are 0. The ray's direction should be of length 1.
- `GetRayCollisionBox`: Returns where a ray meets a box, as raylib's: from inside, the way out, its distance negative and its normal pointing in; its point, distance and normal are set even when it misses.
  - `ray`: The ray.
  - `box`: The box.
  - returns: The hit.
- `GetRayCollisionMesh`: Returns where a ray first meets a mesh moved by a transform: the nearest of its triangles it meets.
  - `ray`: The ray.
  - `mesh`: The mesh, with its positions.
  - `transform`: The transform.
  - returns: The hit.
- `GetRayCollisionTriangle`: Returns where a ray meets a triangle from either side (Möller and Trumbore's test, as raylib's), its normal that of the corners taken counterclockwise.
  - `ray`: The ray.
  - `p1`: A corner.
  - `p2`: The next.
  - `p3`: The last.
  - returns: The hit.
- `GetRayCollisionQuad`: Returns where a ray meets a quad, as two triangles: p1, p2 and p4, then p2, p3 and p4.
  - `ray`: The ray.
  - `p1`: A corner.
  - `p2`: The next, counterclockwise.
  - `p3`: The next.
  - `p4`: The last.
  - returns: The hit.

### raudio: sound

```haxe
static function InitAudioDevice():Void
static function CloseAudioDevice():Void
static function IsAudioDeviceReady():Bool
static function SetMasterVolume(volume:Float):Void
static function GetMasterVolume():Float
static function IsWaveValid(wave:Wave):Bool
static function UnloadWave(wave:Wave):Void
static function WaveCopy(wave:Wave):Wave
static function WaveCrop(wave:Wave, initFrame:Int, finalFrame:Int):Void
static function WaveFormat(wave:Wave, sampleRate:Int, sampleSize:Int, channels:Int):Void
static function LoadWaveSamples(wave:Wave):Array<Float>
static function UnloadWaveSamples(samples:Array<Float>):Void
static function LoadSoundFromWave(wave:Wave):Sound
static function LoadSoundAlias(source:Sound):Sound
static function UnloadSound(sound:Sound):Void
static function UnloadSoundAlias(alias:Sound):Void
static function IsSoundValid(sound:Sound):Bool
static function UpdateSound(sound:Sound, data:haxe.io.Bytes, sampleCount:Int):Void
static function PlaySound(sound:Sound):Void
static function StopSound(sound:Sound):Void
static function PauseSound(sound:Sound):Void
static function ResumeSound(sound:Sound):Void
static function IsSoundPlaying(sound:Sound):Bool
static function SetSoundVolume(sound:Sound, volume:Float):Void
static function SetSoundPitch(sound:Sound, pitch:Float):Void
static function SetSoundPan(sound:Sound, pan:Float):Void
static function LoadMusicStreamFromMemory(fileType:String, data:haxe.io.Bytes, dataSize:Int):Music
static function IsMusicValid(music:Music):Bool
static function UnloadMusicStream(music:Music):Void
static function PlayMusicStream(music:Music):Void
static function IsMusicStreamPlaying(music:Music):Bool
static function UpdateMusicStream(music:Music):Void
static function StopMusicStream(music:Music):Void
static function PauseMusicStream(music:Music):Void
static function ResumeMusicStream(music:Music):Void
static function SeekMusicStream(music:Music, position:Float):Void
static function SetMusicVolume(music:Music, volume:Float):Void
static function SetMusicPitch(music:Music, pitch:Float):Void
static function SetMusicPan(music:Music, pan:Float):Void
static function GetMusicTimeLength(music:Music):Float
static function GetMusicTimePlayed(music:Music):Float
static function LoadAudioStream(sampleRate:Int, sampleSize:Int, channels:Int):AudioStream
static function IsAudioStreamValid(stream:AudioStream):Bool
static function UnloadAudioStream(stream:AudioStream):Void
static function UpdateAudioStream(stream:AudioStream, data:haxe.io.Bytes, frameCount:Int):Void
static function IsAudioStreamProcessed(stream:AudioStream):Bool
static function PlayAudioStream(stream:AudioStream):Void
static function PauseAudioStream(stream:AudioStream):Void
static function ResumeAudioStream(stream:AudioStream):Void
static function IsAudioStreamPlaying(stream:AudioStream):Bool
static function StopAudioStream(stream:AudioStream):Void
static function SetAudioStreamVolume(stream:AudioStream, volume:Float):Void
static function SetAudioStreamPitch(stream:AudioStream, pitch:Float):Void
static function SetAudioStreamPan(stream:AudioStream, pan:Float):Void
static function SetAudioStreamBufferSizeDefault(size:Int):Void
static function SetAudioStreamCallback(stream:AudioStream, callback:Null<(bufferData:haxe.io.Bytes, frames:Int) -> Void>):Void
```

- `InitAudioDevice`: Opens the audio output, with helix-services' `Audio` over it. In a page it plays once the player's first press lets it.
- `CloseAudioDevice`: Closes the audio output, stopping and unloading every sound.
- `IsAudioDeviceReady`: Returns whether the audio output is open.
  - returns: True after `InitAudioDevice`, where the platform has an output.
- `SetMasterVolume`: Sets the volume of every sound.
  - `volume`: 0 (silent) to 1.
- `GetMasterVolume`: Returns the volume of every sound.
  - returns: 0 (silent) to 1.
- `IsWaveValid`: Returns whether a wave holds samples.
  - `wave`: The wave.
  - returns: True when it has data, frames, a rate, a sample size and channels.
- `UnloadWave`: Frees a wave's samples: its data is null after.
  - `wave`: The wave.
- `WaveCopy`: Returns a copy of a wave, its samples its own.
  - `wave`: The wave.
  - returns: The copy.
- `WaveCrop`: Crops a wave to a range of its frames, as raylib's: from `initFrame` up to `finalFrame`, not including it. A range outside the wave, or empty, changes nothing and warns.
  - `wave`: The wave, changed in place.
  - `initFrame`: The first frame kept.
  - `finalFrame`: The frame after the last one kept, at most `frameCount`.
- `WaveFormat`: Converts a wave's samples to another rate, sample size and channels, as raylib's does through miniaudio: integers to floats and back without dithering, channels mixed by miniaudio's standard speaker layouts, and the rate changed by its linear resampler, low-pass filtered. A wave it can't convert is unchanged, with a warning.
  - `wave`: The wave, changed in place.
  - `sampleRate`: The frames a second.
  - `sampleSize`: The bits a sample takes: 8, 16 or 32.
  - `channels`: The number of channels.
- `LoadWaveSamples`: Returns a wave's samples as numbers from -1 to 1, as raylib's: 8-bit ones less 128 over 128, 16-bit ones over 32768, 32-bit ones as they are; other sizes give 0.
  - `wave`: The wave.
  - returns: `frameCount * channels` samples, interleaved.
- `UnloadWaveSamples`: Frees samples `LoadWaveSamples` gave. There is nothing to free here.
  - `samples`: The samples.
- `LoadSoundFromWave`: Makes a sound from a wave, to play at once: its samples converted to 32-bit floats at 44100 Hz, as raylib converts them to the output's format, its channels kept when 1 or 2 and more mixed to 2 (raylib makes every sound stereo). `InitAudioDevice` comes first.
  - `wave`: The wave; it is unchanged, and may be unloaded after.
  - returns: The sound, or one that isn't valid (`IsSoundValid`) when the wave has no samples or can't be converted.
- `LoadSoundAlias`: Makes a sound that plays another's samples with its own volume, pitch, pan and voice, as raylib's alias does. It needs none of its own memory; once its source is unloaded, it plays nothing.
  - `source`: The sound whose samples it plays.
  - returns: The alias, or one that isn't valid when the source isn't loaded.
- `UnloadSound`: Frees a sound, stopping it: one load of its file, the decoded sound with the last; a sound made from a wave, its samples. Its aliases play nothing after. An alias is freed as `UnloadSoundAlias` frees it.
  - `sound`: The sound.
- `UnloadSoundAlias`: Frees an alias, stopping it; its source's samples are kept.
  - `alias`: The alias.
- `IsSoundValid`: Returns whether a sound was loaded.
  - `sound`: The sound.
  - returns: True once it is decoded or made, until it is unloaded.
- `UpdateSound`: Writes new samples over the start of a sound, stopping it, as raylib's does; its length is unchanged. Its aliases play the new samples.
  - `sound`: The sound, or one of its aliases.
  - `data`: 32-bit float samples at 44100 Hz in the sound's channels (a wave's channels, when 1 or 2), interleaved.
  - `sampleCount`: How many frames to write, at most the sound's `frameCount`. The frames after them keep their samples; for a sound loaded from a file, whose samples aren't held, they are silent.
- `PlaySound`: Plays a sound from its start, restarting it when it is already playing.
  - `sound`: The sound.
- `StopSound`: Stops a sound.
  - `sound`: The sound.
- `PauseSound`: Pauses a sound where it is.
  - `sound`: The sound.
- `ResumeSound`: Resumes a paused sound.
  - `sound`: The sound.
- `IsSoundPlaying`: Returns whether a sound is playing.
  - `sound`: The sound.
  - returns: True while it plays; false while it is paused, as raylib's.
- `SetSoundVolume`: Sets a sound's volume, for its next play and the one playing.
  - `sound`: The sound.
  - `volume`: 0 (silent) to 1.
- `SetSoundPitch`: Sets a sound's pitch, for its next play and the one playing: the pitch given, whatever was set before, so 1 sets it back to as recorded. It speeds or slows the sound with it, and is clamped to 0.25 to 4, the platform's range.
  - `sound`: The sound.
  - `pitch`: 1 for as recorded, 2 an octave up.
- `SetSoundPan`: Sets where a sound is heard, for its next play and the one playing.
  - `sound`: The sound.
  - `pan`: 0 for left, 0.5 the middle, 1 for right.

  The range is raylib 5.5's, 0 to 1 with 0.5 the middle, and 1 is the right, as later releases' +1 is; raylib 5.5's own mixer put 1 on the left.
- `LoadMusicStreamFromMemory`: Opens music from a file's bytes, to be played as it is read, as `LoadMusicStreamAsync` plays a file: in a page from a Blob's URL, natively from a copy written to the program's cache directory, deleted when the music is unloaded. `InitAudioDevice` comes first.
  - `fileType`: The file's extension, such as ".ogg": Ogg Vorbis, MP3 or WAV. FLAC (".flac" or ".FLAC") isn't opened, as raylib 5.5's default build leaves it out ("STREAM: Data format not supported"): the music is invalid.
  - `data`: The file's bytes; they are kept until the music is unloaded.
  - `dataSize`: How many of them.
  - returns: The music.
- `IsMusicValid`: Returns whether music was opened, or is still opening.
  - `music`: The music.
  - returns: False once its file couldn't be opened.
- `UnloadMusicStream`: Stops music and closes it.
  - `music`: The music.
- `PlayMusicStream`: Plays music from its start, looping while its `looping` is true; from where `SeekMusicStream` put it, when it was moved before.
  - `music`: The music.
- `IsMusicStreamPlaying`: Returns whether music is playing, or will once it opens.
  - `music`: The music.
  - returns: True while it plays; false while it is paused, as raylib's.
- `UpdateMusicStream`: Keeps music playing. raylib's programs call it each frame; here the stream feeds itself, so it does nothing. Music that doesn't loop is heard to its last sample, and stops then.
  - `music`: The music.
- `StopMusicStream`: Stops music, so its next play starts from its beginning.
  - `music`: The music.
- `PauseMusicStream`: Pauses music where it is.
  - `music`: The music.
- `ResumeMusicStream`: Resumes paused music.
  - `music`: The music.
- `SeekMusicStream`: Moves music to a position. Music not playing starts there when next played. In a page, a server's file moves only within what its server lets the media element ask for (range requests).
  - `music`: The music.
  - `position`: The position, in seconds from its start.
- `SetMusicVolume`: Sets music's volume.
  - `music`: The music.
  - `volume`: 0 (silent) to 1.
- `SetMusicPitch`: Sets music's pitch: the pitch given, whatever was set before, clamped to 0.25 to 4, as `SetSoundPitch` sets a sound's.
  - `music`: The music.
  - `pitch`: 1 for as recorded.
- `SetMusicPan`: Sets where music is heard, in `SetSoundPan`'s range: 1 is the right.
  - `music`: The music.
  - `pan`: 0 for left, 0.5 the middle, 1 for right.
- `GetMusicTimeLength`: Returns music's length (helix-services' `Sound.duration`): known once it opens from a file natively or in a page; a server's file natively once its start and its last 64 KiB have arrived. 0 while it isn't known.
  - `music`: The music.
  - returns: The length, in seconds.
- `GetMusicTimePlayed`: Returns how far music has played, back to 0 at each loop, as raylib's. Paused, it holds; stopped, or played to its end without looping, it is 0; played again, it starts from 0.
  - `music`: The music.
  - returns: The position, in seconds from its start.
- `LoadAudioStream`: Opens a stream for samples the program makes as it goes, played as they are given (`UpdateAudioStream`) through helix-services' `SampleQueue`, which the platform resamples. `InitAudioDevice` comes first.
  - `sampleRate`: The frames a second, 8000 to 96000.
  - `sampleSize`: The bits a sample takes: 8 (unsigned), 16 (signed) or 32 (float).
  - `channels`: The number of channels, 1 or 2.
  - returns: The stream, or one that isn't valid (`IsAudioStreamValid`) when it can't be made.
- `IsAudioStreamValid`: Returns whether a stream was opened.
  - `stream`: The stream.
  - returns: True when it has its queue, a rate, a sample size and channels.
- `UnloadAudioStream`: Closes a stream, stopping it.
  - `stream`: The stream.
- `UpdateAudioStream`: Gives a stream its next buffer of samples, as raylib's: once a buffer has been heard (`IsAudioStreamProcessed`), and at most a buffer's frames (`SetAudioStreamBufferSizeDefault`), the rest of the buffer silent. Otherwise nothing is taken, with a warning.
  - `stream`: The stream.
  - `data`: The samples in the stream's sample size and channels, interleaved.
  - `frameCount`: How many frames.
- `IsAudioStreamProcessed`: Returns whether a stream has room for another buffer: true while it holds no more than one buffer not yet heard, as raylib's double buffer has one free.
  - `stream`: The stream.
  - returns: True when `UpdateAudioStream` would take samples.
- `PlayAudioStream`: Plays a stream: what it holds, and what it is given after. A stream with a callback is filled by it at once.
  - `stream`: The stream.
- `PauseAudioStream`: Pauses a stream where it is.
  - `stream`: The stream.
- `ResumeAudioStream`: Resumes a paused stream.
  - `stream`: The stream.
- `IsAudioStreamPlaying`: Returns whether a stream is playing.
  - `stream`: The stream.
  - returns: True while it plays, even when it has run out of samples; false while it is paused, as raylib's.
- `StopAudioStream`: Stops a stream, dropping the samples it hadn't played.
  - `stream`: The stream.
- `SetAudioStreamVolume`: Sets a stream's volume.
  - `stream`: The stream.
  - `volume`: 0 (silent) to 1.
- `SetAudioStreamPitch`: Sets a stream's pitch: the pitch given, whatever was set before, clamped to 0.25 to 4, as `SetSoundPitch` sets a sound's.
  - `stream`: The stream.
  - `pitch`: 1 for as given.
- `SetAudioStreamPan`: Sets where a stream is heard, in `SetSoundPan`'s range: 1 is the right.
  - `stream`: The stream.
  - `pan`: 0 for left, 0.5 the middle, 1 for right.
- `SetAudioStreamBufferSizeDefault`: Sets the frames in each of a stream's two buffers, for the streams opened after; 0 for raylib's default, a 30th of a second at 44100 Hz (1470 frames).
  - `size`: The frames.
- `SetAudioStreamCallback`: Has a stream ask the program for its samples: while it plays, the callback is called with a buffer's frames to fill until the stream holds two buffers ahead of what is heard. raylib calls it on its audio thread as the mixer needs frames; a page can't run Haxe there, so here it is called on the main thread as each frame ends (`EndDrawing`'s poll), and once as the stream starts to play. A frame long enough to empty both buffers is heard as a gap.
  - `stream`: The stream.
  - `callback`: Receives a buffer to fill, in the stream's sample size and channels, and its frames; null for none.

### Macros, run as the program builds

```haxe
static macro function LoadShader(vsFileName:Null<String>, fsFileName:Null<String>):Shader
static macro function LoadShaderFromMemory(vsCode:Null<String>, fsCode:Null<String>):Shader
static macro function LoadAutomationEventList(fileName:Null<String>):AutomationEventList
```

- `LoadShader`: Loads a shader from raylib GLSL files (330, or 100 for the web), either null for raylib's default stage. They are compiled as the program builds, for every target, so their names are constants; the files are found under `-D helix-raylib-files` (default `web`), as the program's other files are. The program holds it until `UnloadShader`, and each material given it holds it too (docs/DECISIONS.md 25). A uniform given an initializer in the GLSL (`uniform vec2 scale = vec2(0.25, 0.45);`) starts at it, as GL sets it.
  - `vsFileName`: The vertex stage's file, or null.
  - `fsFileName`: The fragment stage's file, or null.
  - returns: The shader.
- `LoadShaderFromMemory`: Loads a shader from raylib GLSL text, either null for raylib's default stage. It is compiled as the program builds, so the text is a constant. The program holds it until `UnloadShader`, and each material given it holds it too (docs/DECISIONS.md 25). A uniform given an initializer in the GLSL starts at it, as GL sets it.
  - `vsCode`: The vertex stage's text, or null.
  - `fsCode`: The fragment stage's text, or null.
  - returns: The shader.
- `LoadAutomationEventList`: Returns an empty automation events list to record into, its capacity raylib's 16384, as raylib's `LoadAutomationEventList(NULL)`. Given a file instead, a call doesn't compile: a page can't wait for a file, so `LoadAutomationEventListAsync` reads one.
  - `fileName`: Null (or 0, as raylib's examples write it).
  - returns: The list.

### Not supported in helix-raylib

Each of these is raylib's name (or emscripten's, which raylib's web programs call), and a call to it doesn't compile, saying why and what to use instead.

`SetWindowSize`, `MaximizeWindow`, `MinimizeWindow`, `RestoreWindow`, `SetWindowFocused`, `SetWindowOpacity`, `SetWindowMinSize`, `SetWindowMaxSize`, `SetClipboardText`, `GetClipboardText`, `GetClipboardImage`, `GetWindowHandle`, `GetMonitorPhysicalWidth`, `GetMonitorPhysicalHeight`, `ToggleFullscreen`, `ToggleBorderlessWindowed`, `SetWindowPosition`, `SetWindowMonitor`, `EnableCursor`, `DisableCursor`, `FileExists`, `LoadFileText`, `SaveFileText`, `LoadFileData`, `SaveFileData`, `ExportDataAsCode`, `DirectoryExists`, `GetFileLength`, `IsPathFile`, `LoadDirectoryFiles`, `LoadDirectoryFilesEx`, `GetFileModTime`, `ExportAutomationEventList`, `MemAlloc`, `MemRealloc`, `MemFree`, `TakeScreenshot`, `emscripten_set_main_loop`, `emscripten_set_main_loop_arg`, `emscripten_cancel_main_loop`, `emscripten_run_script`, `emscripten_run_script_int`, `emscripten_run_script_string`, `emscripten_get_now`, `emscripten_sleep`, `LoadTexture`, `LoadImage`, `LoadImageRaw`, `LoadImageFromMemory`, `LoadImageAnim`, `LoadImageAnimFromMemory`, `LoadImageFromTexture`, `LoadImageFromScreen`, `ExportImage`, `ExportImageAsCode`, `ExportFontAsCode`, `LoadFont`, `LoadFontEx`, `LoadFontFromMemory`, `LoadFontData`, `TextCopy`, `TextAppend`, `LoadModel`, `LoadMaterials`, `ExportMesh`, `ExportMeshAsCode`, `LoadModelAnimations`, `LoadWave`, `LoadWaveFromMemory`, `ExportWave`, `ExportWaveAsCode`, `LoadSound`, `LoadMusicStream`, `AttachAudioStreamProcessor`, `DetachAudioStreamProcessor`, `AttachAudioMixedProcessor`, `DetachAudioMixedProcessor`.

## Raymath

*class* in [`engines/raylib/src/helix/raylib/Raymath.hx`](../../engines/raylib/src/helix/raylib/Raymath.hx), `import helix.raylib.Raymath;`

Provides raymath's API, as raylib 5.5's `raymath.h` names it: vectors, matrices and quaternions, and `Clamp`, `Lerp` and the like. As in raylib, it is apart from `Raylib`, so a program that uses it imports it too:

```haxe
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
```

What raymath has and helix-raylib doesn't refuses to compile, naming itself.

### raymath.h's defines

```haxe
static inline var PI:Float
static inline var DEG2RAD:Float
static inline var RAD2DEG:Float
static inline var EPSILON:Float
```

- `PI`: Pi, as raymath defines it when raylib hasn't.
- `DEG2RAD`: Degrees to radians: multiply by it.
- `RAD2DEG`: Radians to degrees: multiply by it.
- `EPSILON`: The difference under which raymath's `...Equals` functions take two values as equal.

### raymath: vectors, matrices and quaternions

```haxe
static function Clamp(value:Float, min:Float, max:Float):Float
static function Lerp(start:Float, end:Float, amount:Float):Float
static function Normalize(value:Float, start:Float, end:Float):Float
static function Remap(value:Float, inputStart:Float, inputEnd:Float, outputStart:Float, outputEnd:Float):Float
static function Wrap(value:Float, min:Float, max:Float):Float
static function FloatEquals(x:Float, y:Float):Int
static function Vector2Zero():Vector2
static function Vector2One():Vector2
static function Vector2Add(v1:Vector2, v2:Vector2):Vector2
static function Vector2AddValue(v:Vector2, add:Float):Vector2
static function Vector2Subtract(v1:Vector2, v2:Vector2):Vector2
static function Vector2SubtractValue(v:Vector2, sub:Float):Vector2
static function Vector2Length(v:Vector2):Float
static function Vector2LengthSqr(v:Vector2):Float
static function Vector2DotProduct(v1:Vector2, v2:Vector2):Float
static function Vector2Distance(v1:Vector2, v2:Vector2):Float
static function Vector2DistanceSqr(v1:Vector2, v2:Vector2):Float
static function Vector2Angle(v1:Vector2, v2:Vector2):Float
static function Vector2LineAngle(start:Vector2, end:Vector2):Float
static function Vector2Scale(v:Vector2, scale:Float):Vector2
static function Vector2Multiply(v1:Vector2, v2:Vector2):Vector2
static function Vector2Negate(v:Vector2):Vector2
static function Vector2Divide(v1:Vector2, v2:Vector2):Vector2
static function Vector2Normalize(v:Vector2):Vector2
static function Vector2Transform(v:Vector2, mat:Matrix):Vector2
static function Vector2Lerp(v1:Vector2, v2:Vector2, amount:Float):Vector2
static function Vector2Reflect(v:Vector2, normal:Vector2):Vector2
static function Vector2Min(v1:Vector2, v2:Vector2):Vector2
static function Vector2Max(v1:Vector2, v2:Vector2):Vector2
static function Vector2Rotate(v:Vector2, angle:Float):Vector2
static function Vector2MoveTowards(v:Vector2, target:Vector2, maxDistance:Float):Vector2
static function Vector2Invert(v:Vector2):Vector2
static function Vector2Clamp(v:Vector2, min:Vector2, max:Vector2):Vector2
static function Vector2ClampValue(v:Vector2, min:Float, max:Float):Vector2
static function Vector2Equals(p:Vector2, q:Vector2):Int
static function Vector2Refract(v:Vector2, n:Vector2, r:Float):Vector2
static function Vector3Zero():Vector3
static function Vector3One():Vector3
static function Vector3Add(v1:Vector3, v2:Vector3):Vector3
static function Vector3AddValue(v:Vector3, add:Float):Vector3
static function Vector3Subtract(v1:Vector3, v2:Vector3):Vector3
static function Vector3SubtractValue(v:Vector3, sub:Float):Vector3
static function Vector3Scale(v:Vector3, scalar:Float):Vector3
static function Vector3Multiply(v1:Vector3, v2:Vector3):Vector3
static function Vector3CrossProduct(v1:Vector3, v2:Vector3):Vector3
static function Vector3Perpendicular(v:Vector3):Vector3
static function Vector3Length(v:Vector3):Float
static function Vector3LengthSqr(v:Vector3):Float
static function Vector3DotProduct(v1:Vector3, v2:Vector3):Float
static function Vector3Distance(v1:Vector3, v2:Vector3):Float
static function Vector3DistanceSqr(v1:Vector3, v2:Vector3):Float
static function Vector3Angle(v1:Vector3, v2:Vector3):Float
static function Vector3Negate(v:Vector3):Vector3
static function Vector3Divide(v1:Vector3, v2:Vector3):Vector3
static function Vector3Normalize(v:Vector3):Vector3
static function Vector3Project(v1:Vector3, v2:Vector3):Vector3
static function Vector3Reject(v1:Vector3, v2:Vector3):Vector3
static function Vector3OrthoNormalize(v1:Vector3, v2:Vector3):Void
static function Vector3Transform(v:Vector3, mat:Matrix):Vector3
static function Vector3RotateByQuaternion(v:Vector3, q:Quaternion):Vector3
static function Vector3RotateByAxisAngle(v:Vector3, axis:Vector3, angle:Float):Vector3
static function Vector3MoveTowards(v:Vector3, target:Vector3, maxDistance:Float):Vector3
static function Vector3Lerp(v1:Vector3, v2:Vector3, amount:Float):Vector3
static function Vector3CubicHermite(v1:Vector3, tangent1:Vector3, v2:Vector3, tangent2:Vector3, amount:Float):Vector3
static function Vector3Reflect(v:Vector3, normal:Vector3):Vector3
static function Vector3Min(v1:Vector3, v2:Vector3):Vector3
static function Vector3Max(v1:Vector3, v2:Vector3):Vector3
static function Vector3Barycenter(p:Vector3, a:Vector3, b:Vector3, c:Vector3):Vector3
static function Vector3Unproject(source:Vector3, projection:Matrix, view:Matrix):Vector3
static function Vector3ToFloatV(v:Vector3):Array<Float>
static function Vector3Invert(v:Vector3):Vector3
static function Vector3Clamp(v:Vector3, min:Vector3, max:Vector3):Vector3
static function Vector3ClampValue(v:Vector3, min:Float, max:Float):Vector3
static function Vector3Equals(p:Vector3, q:Vector3):Int
static function Vector3Refract(v:Vector3, n:Vector3, r:Float):Vector3
static function Vector4Zero():Vector4
static function Vector4One():Vector4
static function Vector4Add(v1:Vector4, v2:Vector4):Vector4
static function Vector4AddValue(v:Vector4, add:Float):Vector4
static function Vector4Subtract(v1:Vector4, v2:Vector4):Vector4
static function Vector4SubtractValue(v:Vector4, add:Float):Vector4
static function Vector4Length(v:Vector4):Float
static function Vector4LengthSqr(v:Vector4):Float
static function Vector4DotProduct(v1:Vector4, v2:Vector4):Float
static function Vector4Distance(v1:Vector4, v2:Vector4):Float
static function Vector4DistanceSqr(v1:Vector4, v2:Vector4):Float
static function Vector4Scale(v:Vector4, scale:Float):Vector4
static function Vector4Multiply(v1:Vector4, v2:Vector4):Vector4
static function Vector4Negate(v:Vector4):Vector4
static function Vector4Divide(v1:Vector4, v2:Vector4):Vector4
static function Vector4Normalize(v:Vector4):Vector4
static function Vector4Min(v1:Vector4, v2:Vector4):Vector4
static function Vector4Max(v1:Vector4, v2:Vector4):Vector4
static function Vector4Lerp(v1:Vector4, v2:Vector4, amount:Float):Vector4
static function Vector4MoveTowards(v:Vector4, target:Vector4, maxDistance:Float):Vector4
static function Vector4Invert(v:Vector4):Vector4
static function Vector4Equals(p:Vector4, q:Vector4):Int
static function MatrixDeterminant(mat:Matrix):Float
static function MatrixTrace(mat:Matrix):Float
static function MatrixTranspose(mat:Matrix):Matrix
static function MatrixInvert(mat:Matrix):Matrix
static function MatrixIdentity():Matrix
static function MatrixAdd(left:Matrix, right:Matrix):Matrix
static function MatrixSubtract(left:Matrix, right:Matrix):Matrix
static function MatrixMultiply(left:Matrix, right:Matrix):Matrix
static function MatrixTranslate(x:Float, y:Float, z:Float):Matrix
static function MatrixRotate(axis:Vector3, angle:Float):Matrix
static function MatrixRotateX(angle:Float):Matrix
static function MatrixRotateY(angle:Float):Matrix
static function MatrixRotateZ(angle:Float):Matrix
static function MatrixRotateXYZ(angle:Vector3):Matrix
static function MatrixRotateZYX(angle:Vector3):Matrix
static function MatrixScale(x:Float, y:Float, z:Float):Matrix
static function MatrixFrustum(left:Float, right:Float, bottom:Float, top:Float, nearPlane:Float, farPlane:Float):Matrix
static function MatrixPerspective(fovY:Float, aspect:Float, nearPlane:Float, farPlane:Float):Matrix
static function MatrixOrtho(left:Float, right:Float, bottom:Float, top:Float, nearPlane:Float, farPlane:Float):Matrix
static function MatrixLookAt(eye:Vector3, target:Vector3, up:Vector3):Matrix
static function MatrixToFloatV(mat:Matrix):Array<Float>
static function QuaternionAdd(q1:Quaternion, q2:Quaternion):Quaternion
static function QuaternionAddValue(q:Quaternion, add:Float):Quaternion
static function QuaternionSubtract(q1:Quaternion, q2:Quaternion):Quaternion
static function QuaternionSubtractValue(q:Quaternion, sub:Float):Quaternion
static function QuaternionIdentity():Quaternion
static function QuaternionLength(q:Quaternion):Float
static function QuaternionNormalize(q:Quaternion):Quaternion
static function QuaternionInvert(q:Quaternion):Quaternion
static function QuaternionMultiply(q1:Quaternion, q2:Quaternion):Quaternion
static function QuaternionScale(q:Quaternion, mul:Float):Quaternion
static function QuaternionDivide(q1:Quaternion, q2:Quaternion):Quaternion
static function QuaternionLerp(q1:Quaternion, q2:Quaternion, amount:Float):Quaternion
static function QuaternionNlerp(q1:Quaternion, q2:Quaternion, amount:Float):Quaternion
static function QuaternionSlerp(q1:Quaternion, q2:Quaternion, amount:Float):Quaternion
static function QuaternionCubicHermiteSpline(q1:Quaternion, outTangent1:Quaternion, q2:Quaternion, inTangent2:Quaternion, t:Float):Quaternion
static function QuaternionFromVector3ToVector3(from:Vector3, to:Vector3):Quaternion
static function QuaternionFromMatrix(mat:Matrix):Quaternion
static function QuaternionToMatrix(q:Quaternion):Matrix
static function QuaternionFromAxisAngle(axis:Vector3, angle:Float):Quaternion
static function QuaternionToAxisAngle(q:Quaternion, outAxis:Array<Vector3>, outAngle:Array<Float>):Void
static function QuaternionFromEuler(pitch:Float, yaw:Float, roll:Float):Quaternion
static function QuaternionToEuler(q:Quaternion):Vector3
static function QuaternionTransform(q:Quaternion, mat:Matrix):Quaternion
static function QuaternionEquals(p:Quaternion, q:Quaternion):Int
static function MatrixDecompose(mat:Matrix, translation:Vector3, rotation:Quaternion, scale:Vector3):Void
```

- `Clamp`: Returns a value kept between two others.
  - `value`: The value.
  - `min`: The least.
  - `max`: The most.
  - returns: The value, at least min and at most max.
- `Lerp`: Returns a value part of the way from one to another.
  - `start`: The start.
  - `end`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The value.
- `Normalize`: Returns where a value falls from one to another: 0 at the start, 1 at the end.
  - `value`: The value.
  - `start`: The start.
  - `end`: The end.
  - returns: The fraction.
- `Remap`: Returns a value moved from one range to another.
  - `value`: The value.
  - `inputStart`: The first range's start.
  - `inputEnd`: Its end.
  - `outputStart`: The second range's start.
  - `outputEnd`: Its end.
  - returns: The value in the second range.
- `Wrap`: Returns a value wrapped around into a range, as an angle wraps around a turn.
  - `value`: The value.
  - `min`: The range's start.
  - `max`: Its end.
  - returns: The value in the range.
- `FloatEquals`: Returns whether two values are equal but for rounding: no further apart than `EPSILON`, times the larger when it is over 1.
  - `x`: One.
  - `y`: The other.
  - returns: 1 if they are, 0 if not.
- `Vector2Zero`: Returns (0, 0).
  - returns: The vector.
- `Vector2One`: Returns (1, 1).
  - returns: The vector.
- `Vector2Add`: Returns the sum of two vectors.
  - `v1`: One.
  - `v2`: The other.
  - returns: The sum.
- `Vector2AddValue`: Returns a vector with a value added to each component.
  - `v`: The vector.
  - `add`: The value.
  - returns: The sum.
- `Vector2Subtract`: Returns one vector less another.
  - `v1`: The first.
  - `v2`: The one taken from it.
  - returns: The difference.
- `Vector2SubtractValue`: Returns a vector with a value taken from each component.
  - `v`: The vector.
  - `sub`: The value.
  - returns: The difference.
- `Vector2Length`: Returns a vector's length.
  - `v`: The vector.
  - returns: The length.
- `Vector2LengthSqr`: Returns a vector's length squared.
  - `v`: The vector.
  - returns: The length squared.
- `Vector2DotProduct`: Returns the dot product.
  - `v1`: One.
  - `v2`: The other.
  - returns: The product.
- `Vector2Distance`: Returns the distance between two points.
  - `v1`: One.
  - `v2`: The other.
  - returns: The distance.
- `Vector2DistanceSqr`: Returns the distance between two points, squared.
  - `v1`: One.
  - `v2`: The other.
  - returns: The distance squared.
- `Vector2Angle`: Returns the angle from one vector to another, from -pi to pi: positive turning from x toward y.
  - `v1`: The first.
  - `v2`: The second.
  - returns: The angle, in radians.
- `Vector2LineAngle`: Returns the angle of the line from one point to another, from the x axis: positive turning from x toward -y.
  - `start`: The line's start.
  - `end`: Its end.
  - returns: The angle, in radians.
- `Vector2Scale`: Returns a vector scaled.
  - `v`: The vector.
  - `scale`: The scale.
  - returns: The scaled vector.
- `Vector2Multiply`: Returns two vectors multiplied component by component.
  - `v1`: One.
  - `v2`: The other.
  - returns: The product.
- `Vector2Negate`: Returns a vector pointing the other way.
  - `v`: The vector.
  - returns: The negated vector.
- `Vector2Divide`: Returns one vector divided by another, component by component.
  - `v1`: The one divided.
  - `v2`: The one dividing it.
  - returns: The quotient.
- `Vector2Normalize`: Returns a vector of length 1 in the same direction, or (0, 0) for (0, 0).
  - `v`: The vector.
  - returns: The direction.
- `Vector2Transform`: Returns a point transformed by a matrix, the point at z 0.
  - `v`: The point.
  - `mat`: The matrix.
  - returns: The transformed point's x and y.
- `Vector2Lerp`: Returns a point part of the way from one to another.
  - `v1`: The start.
  - `v2`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The point.
- `Vector2Reflect`: Returns a direction reflected off a surface.
  - `v`: The direction.
  - `normal`: The surface's normal, of length 1.
  - returns: The reflected direction.
- `Vector2Min`: Returns the least of two vectors' components, each on its own.
  - `v1`: One.
  - `v2`: The other.
  - returns: The vector of the least.
- `Vector2Max`: Returns the most of two vectors' components, each on its own.
  - `v1`: One.
  - `v2`: The other.
  - returns: The vector of the most.
- `Vector2Rotate`: Returns a vector turned by an angle, from x toward y.
  - `v`: The vector.
  - `angle`: The angle, in radians.
  - returns: The turned vector.
- `Vector2MoveTowards`: Returns a point moved toward a target by at most a distance; the target when it is that near.
  - `v`: The point.
  - `target`: The target.
  - `maxDistance`: The most it moves.
  - returns: The moved point.
- `Vector2Invert`: Returns 1 divided by each of a vector's components.
  - `v`: The vector.
  - returns: The inverted vector.
- `Vector2Clamp`: Returns a vector with each component kept between two others'.
  - `v`: The vector.
  - `min`: The least components.
  - `max`: The most.
  - returns: The vector.
- `Vector2ClampValue`: Returns a vector with its length kept between two values.
  - `v`: The vector.
  - `min`: The least length.
  - `max`: The most length.
  - returns: The vector.
- `Vector2Equals`: Returns whether two vectors are equal but for rounding, each component as `FloatEquals` compares it.
  - `p`: One.
  - `q`: The other.
  - returns: 1 if they are, 0 if not.
- `Vector2Refract`: Returns a direction bent passing into a surface, or (0, 0) when it is wholly reflected instead.
  - `v`: The direction, of length 1.
  - `n`: The surface's normal, of length 1.
  - `r`: The ratio of the refractive indices, the one it leaves over the one it enters.
  - returns: The bent direction.
- `Vector3Zero`: Returns (0, 0, 0).
  - returns: The vector.
- `Vector3One`: Returns (1, 1, 1).
  - returns: The vector.
- `Vector3Add`: Returns the sum of two vectors.
  - `v1`: One.
  - `v2`: The other.
  - returns: The sum.
- `Vector3AddValue`: Returns a vector with a value added to each component.
  - `v`: The vector.
  - `add`: The value.
  - returns: The sum.
- `Vector3Subtract`: Returns one vector less another.
  - `v1`: The first.
  - `v2`: The one taken from it.
  - returns: The difference.
- `Vector3SubtractValue`: Returns a vector with a value taken from each component.
  - `v`: The vector.
  - `sub`: The value.
  - returns: The difference.
- `Vector3Scale`: Returns a vector scaled.
  - `v`: The vector.
  - `scalar`: The scale.
  - returns: The scaled vector.
- `Vector3Multiply`: Returns two vectors multiplied component by component.
  - `v1`: One.
  - `v2`: The other.
  - returns: The product.
- `Vector3CrossProduct`: Returns the cross product.
  - `v1`: One.
  - `v2`: The other.
  - returns: The product.
- `Vector3Perpendicular`: Returns a vector perpendicular to another: its cross product with the axis the vector is least along.
  - `v`: The vector.
  - returns: The perpendicular vector.
- `Vector3Length`: Returns a vector's length.
  - `v`: The vector.
  - returns: The length.
- `Vector3LengthSqr`: Returns a vector's length squared.
  - `v`: The vector.
  - returns: The length squared.
- `Vector3DotProduct`: Returns the dot product.
  - `v1`: One.
  - `v2`: The other.
  - returns: The product.
- `Vector3Distance`: Returns the distance between two points.
  - `v1`: One.
  - `v2`: The other.
  - returns: The distance.
- `Vector3DistanceSqr`: Returns the distance between two points, squared.
  - `v1`: One.
  - `v2`: The other.
  - returns: The distance squared.
- `Vector3Angle`: Returns the angle between two vectors, from 0 to pi.
  - `v1`: One.
  - `v2`: The other.
  - returns: The angle, in radians.
- `Vector3Negate`: Returns a vector pointing the other way.
  - `v`: The vector.
  - returns: The negated vector.
- `Vector3Divide`: Returns one vector divided by another, component by component.
  - `v1`: The one divided.
  - `v2`: The one dividing it.
  - returns: The quotient.
- `Vector3Normalize`: Returns a vector of length 1 in the same direction, or the vector itself when its length is 0.
  - `v`: The vector.
  - returns: The direction.
- `Vector3Project`: Returns the part of one vector along another.
  - `v1`: The vector.
  - `v2`: The direction it is projected onto.
  - returns: The projection.
- `Vector3Reject`: Returns the part of one vector across another: the vector less its projection.
  - `v1`: The vector.
  - `v2`: The direction taken out of it.
  - returns: The rejection.
- `Vector3OrthoNormalize`: Makes two vectors of length 1 and at right angles to each other, the first keeping its direction (Gram-Schmidt).
  - `v1`: The first, set to its direction.
  - `v2`: The second, set at right angles to the first, in the plane the two were in and on its own side.
- `Vector3Transform`: Returns a point transformed by a matrix.
  - `v`: The point.
  - `mat`: The matrix.
  - returns: The transformed point.
- `Vector3RotateByQuaternion`: Returns a vector turned by a quaternion.
  - `v`: The vector.
  - `q`: The quaternion.
  - returns: The turned vector.
- `Vector3RotateByAxisAngle`: Returns a vector turned about an axis.
  - `v`: The vector.
  - `axis`: The axis.
  - `angle`: The angle, in radians.
  - returns: The turned vector.
- `Vector3MoveTowards`: Returns a point moved toward a target by at most a distance; the target when it is that near.
  - `v`: The point.
  - `target`: The target.
  - `maxDistance`: The most it moves.
  - returns: The moved point.
- `Vector3Lerp`: Returns a point part of the way from one to another.
  - `v1`: The start.
  - `v2`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The point.
- `Vector3CubicHermite`: Returns a point part of the way along a cubic Hermite curve, from one point to another, leaving and arriving along tangents.
  - `v1`: The start.
  - `tangent1`: The tangent leaving it.
  - `v2`: The end.
  - `tangent2`: The tangent arriving at it.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The point.
- `Vector3Reflect`: Returns a direction reflected off a surface.
  - `v`: The direction.
  - `normal`: The surface's normal, of length 1.
  - returns: The reflected direction.
- `Vector3Min`: Returns the least of two vectors' components, each on its own.
  - `v1`: One.
  - `v2`: The other.
  - returns: The vector of the least.
- `Vector3Max`: Returns the most of two vectors' components, each on its own.
  - `v1`: One.
  - `v2`: The other.
  - returns: The vector of the most.
- `Vector3Barycenter`: Returns a point's barycentric coordinates in a triangle: how much of each corner it is made of.
  - `p`: The point.
  - `a`: The first corner.
  - `b`: The second.
  - `c`: The third.
  - returns: How much of a (x), b (y) and c (z).
- `Vector3Unproject`: Returns a point in normalized device coordinates (each from -1 to 1) taken back into the world, through a view and a projection.
  - `source`: The point.
  - `projection`: The projection.
  - `view`: The view.
  - returns: The point in the world.
- `Vector3ToFloatV`: Returns a vector's components as an array: x, y, z.
  - `v`: The vector.
  - returns: The array.
- `Vector3Invert`: Returns 1 divided by each of a vector's components.
  - `v`: The vector.
  - returns: The inverted vector.
- `Vector3Clamp`: Returns a vector with each component kept between two others'.
  - `v`: The vector.
  - `min`: The least components.
  - `max`: The most.
  - returns: The vector.
- `Vector3ClampValue`: Returns a vector with its length kept between two values.
  - `v`: The vector.
  - `min`: The least length.
  - `max`: The most length.
  - returns: The vector.
- `Vector3Equals`: Returns whether two vectors are equal but for rounding, each component as `FloatEquals` compares it.
  - `p`: One.
  - `q`: The other.
  - returns: 1 if they are, 0 if not.
- `Vector3Refract`: Returns a direction bent passing into a surface, or (0, 0, 0) when it is wholly reflected instead.
  - `v`: The direction, of length 1.
  - `n`: The surface's normal, of length 1.
  - `r`: The ratio of the refractive indices, the one it leaves over the one it enters.
  - returns: The bent direction.
- `Vector4Zero`: Returns (0, 0, 0, 0).
  - returns: The vector.
- `Vector4One`: Returns (1, 1, 1, 1).
  - returns: The vector.
- `Vector4Add`: Returns the sum of two vectors.
  - `v1`: One.
  - `v2`: The other.
  - returns: The sum.
- `Vector4AddValue`: Returns a vector with a value added to each component.
  - `v`: The vector.
  - `add`: The value.
  - returns: The sum.
- `Vector4Subtract`: Returns one vector less another.
  - `v1`: The first.
  - `v2`: The one taken from it.
  - returns: The difference.
- `Vector4SubtractValue`: Returns a vector with a value taken from each component.
  - `v`: The vector.
  - `add`: The value.
  - returns: The difference.
- `Vector4Length`: Returns a vector's length.
  - `v`: The vector.
  - returns: The length.
- `Vector4LengthSqr`: Returns a vector's length squared.
  - `v`: The vector.
  - returns: The length squared.
- `Vector4DotProduct`: Returns the dot product.
  - `v1`: One.
  - `v2`: The other.
  - returns: The product.
- `Vector4Distance`: Returns the distance between two points.
  - `v1`: One.
  - `v2`: The other.
  - returns: The distance.
- `Vector4DistanceSqr`: Returns the distance between two points, squared.
  - `v1`: One.
  - `v2`: The other.
  - returns: The distance squared.
- `Vector4Scale`: Returns a vector scaled.
  - `v`: The vector.
  - `scale`: The scale.
  - returns: The scaled vector.
- `Vector4Multiply`: Returns two vectors multiplied component by component.
  - `v1`: One.
  - `v2`: The other.
  - returns: The product.
- `Vector4Negate`: Returns a vector pointing the other way.
  - `v`: The vector.
  - returns: The negated vector.
- `Vector4Divide`: Returns one vector divided by another, component by component.
  - `v1`: The one divided.
  - `v2`: The one dividing it.
  - returns: The quotient.
- `Vector4Normalize`: Returns a vector of length 1 in the same direction, or (0, 0, 0, 0) for (0, 0, 0, 0).
  - `v`: The vector.
  - returns: The direction.
- `Vector4Min`: Returns the least of two vectors' components, each on its own.
  - `v1`: One.
  - `v2`: The other.
  - returns: The vector of the least.
- `Vector4Max`: Returns the most of two vectors' components, each on its own.
  - `v1`: One.
  - `v2`: The other.
  - returns: The vector of the most.
- `Vector4Lerp`: Returns a point part of the way from one to another.
  - `v1`: The start.
  - `v2`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The point.
- `Vector4MoveTowards`: Returns a point moved toward a target by at most a distance; the target when it is that near.
  - `v`: The point.
  - `target`: The target.
  - `maxDistance`: The most it moves.
  - returns: The moved point.
- `Vector4Invert`: Returns 1 divided by each of a vector's components.
  - `v`: The vector.
  - returns: The inverted vector.
- `Vector4Equals`: Returns whether two vectors are equal but for rounding, each component as `FloatEquals` compares it.
  - `p`: One.
  - `q`: The other.
  - returns: 1 if they are, 0 if not.
- `MatrixDeterminant`: Returns a matrix's determinant.
  - `mat`: The matrix.
  - returns: The determinant.
- `MatrixTrace`: Returns a matrix's trace: the sum of its diagonal.
  - `mat`: The matrix.
  - returns: The trace.
- `MatrixTranspose`: Returns a matrix transposed.
  - `mat`: The matrix.
  - returns: Its transpose.
- `MatrixInvert`: Returns a matrix inverted, by raymath's own steps: a singular matrix's inverse divides by a determinant of 0, so it is infinite or NaN, as raylib's is.
  - `mat`: The matrix.
  - returns: Its inverse.
- `MatrixIdentity`: Returns the identity matrix.
  - returns: The matrix.
- `MatrixAdd`: Returns the sum of two matrices.
  - `left`: One.
  - `right`: The other.
  - returns: The sum.
- `MatrixSubtract`: Returns one matrix less another.
  - `left`: The first.
  - `right`: The one taken from it.
  - returns: The difference.
- `MatrixMultiply`: Returns two matrices multiplied: left, then right.
  - `left`: The first.
  - `right`: The second.
  - returns: The product.
- `MatrixTranslate`: Returns a translation.
  - `x`: Along x.
  - `y`: Along y.
  - `z`: Along z.
  - returns: The matrix.
- `MatrixRotate`: Returns a rotation about an axis.
  - `axis`: The axis.
  - `angle`: The angle, in radians.
  - returns: The matrix.
- `MatrixRotateX`: Returns a rotation about x.
  - `angle`: The angle, in radians.
  - returns: The matrix.
- `MatrixRotateY`: Returns a rotation about y.
  - `angle`: The angle, in radians.
  - returns: The matrix.
- `MatrixRotateZ`: Returns a rotation about z.
  - `angle`: The angle, in radians.
  - returns: The matrix.
- `MatrixRotateXYZ`: Returns raymath's xyz rotation, by its own steps: built from the negated angles and laid out as raylib's is, which turns a point about z, then y, then x (the reverse of `MatrixRotateZYX`'s order).
  - `angle`: The angles, in radians.
  - returns: The matrix.
- `MatrixRotateZYX`: Returns rotations about z, then y, then x.
  - `angle`: The angles, in radians.
  - returns: The matrix.
- `MatrixScale`: Returns a scale.
  - `x`: Along x.
  - `y`: Along y.
  - `z`: Along z.
  - returns: The matrix.
- `MatrixFrustum`: Returns a perspective projection by its near plane's edges.
  - `left`: The near plane's left.
  - `right`: Its right.
  - `bottom`: Its bottom.
  - `top`: Its top.
  - `nearPlane`: The near plane.
  - `farPlane`: The far plane.
  - returns: The matrix.
- `MatrixPerspective`: Returns a perspective projection.
  - `fovY`: The field of view, top to bottom, in radians.
  - `aspect`: Width over height.
  - `nearPlane`: The near plane.
  - `farPlane`: The far plane.
  - returns: The matrix.
- `MatrixOrtho`: Returns an orthographic projection.
  - `left`: Left.
  - `right`: Right.
  - `bottom`: Bottom.
  - `top`: Top.
  - `nearPlane`: The near plane.
  - `farPlane`: The far plane.
  - returns: The matrix.
- `MatrixLookAt`: Returns a view looking from eye at target.
  - `eye`: Where from.
  - `target`: What at.
  - `up`: Up.
  - returns: The matrix.
- `MatrixToFloatV`: Returns a matrix's values as an array, by columns: m0 to m15, as a shader takes them.
  - `mat`: The matrix.
  - returns: The array.
- `QuaternionAdd`: Returns the sum of two quaternions.
  - `q1`: One.
  - `q2`: The other.
  - returns: The sum.
- `QuaternionAddValue`: Returns a quaternion with a value added to each component.
  - `q`: The quaternion.
  - `add`: The value.
  - returns: The sum.
- `QuaternionSubtract`: Returns one quaternion less another.
  - `q1`: The first.
  - `q2`: The one taken from it.
  - returns: The difference.
- `QuaternionSubtractValue`: Returns a quaternion with a value taken from each component.
  - `q`: The quaternion.
  - `sub`: The value.
  - returns: The difference.
- `QuaternionIdentity`: Returns the identity quaternion.
  - returns: The quaternion.
- `QuaternionLength`: Returns a quaternion's length.
  - `q`: The quaternion.
  - returns: The length.
- `QuaternionNormalize`: Returns a quaternion of length 1 in the same direction, or the quaternion itself when its length is 0.
  - `q`: The quaternion.
  - returns: The normalized quaternion.
- `QuaternionInvert`: Returns a quaternion's inverse: the rotation back, for one of length 1; the quaternion itself when its length is 0.
  - `q`: The quaternion.
  - returns: Its inverse.
- `QuaternionMultiply`: Returns two quaternions multiplied: the rotation q2, then q1.
  - `q1`: The first.
  - `q2`: The second.
  - returns: The product.
- `QuaternionScale`: Returns a quaternion scaled.
  - `q`: The quaternion.
  - `mul`: The scale.
  - returns: The scaled quaternion.
- `QuaternionDivide`: Returns one quaternion divided by another, component by component.
  - `q1`: The one divided.
  - `q2`: The one dividing it.
  - returns: The quotient.
- `QuaternionLerp`: Returns a quaternion part of the way from one to another, component by component.
  - `q1`: The start.
  - `q2`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The quaternion.
- `QuaternionNlerp`: Returns a quaternion part of the way from one to another, component by component, then normalized.
  - `q1`: The start.
  - `q2`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The quaternion.
- `QuaternionSlerp`: Returns a rotation part of the way from one to another at a steady turn, the short way round (spherical linear interpolation).
  - `q1`: The start.
  - `q2`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The quaternion.
- `QuaternionCubicHermiteSpline`: Returns a rotation part of the way along a cubic Hermite curve, from one quaternion to another, leaving and arriving along tangents, normalized.
  - `q1`: The start.
  - `outTangent1`: The tangent leaving it.
  - `q2`: The end.
  - `inTangent2`: The tangent arriving at it.
  - `t`: 0 for the start, 1 for the end.
  - returns: The quaternion.
- `QuaternionFromVector3ToVector3`: Returns the rotation turning one direction to another, as raylib 6.2's: the directions may be of any length, and opposite ones give half a turn about a direction square to the first.
  - `from`: The direction turned from.
  - `to`: The direction turned to.
  - returns: The quaternion, of length 1; all 0 when either direction is.
- `QuaternionFromMatrix`: Returns a rotation matrix's rotation as a quaternion.
  - `mat`: The matrix.
  - returns: The quaternion.
- `QuaternionToMatrix`: Returns a quaternion's rotation as a matrix.
  - `q`: The quaternion.
  - returns: The matrix.
- `QuaternionFromAxisAngle`: Returns the rotation about an axis as a quaternion, normalized; the identity for an axis of no length.
  - `axis`: The axis.
  - `angle`: The angle, in radians.
  - returns: The quaternion.
- `QuaternionToAxisAngle`: Gives a quaternion's rotation as an axis and an angle about it; the axis is x when the angle is 0.
  - `q`: The quaternion, normalized first when its w is over 1 either way.
  - `outAxis`: Its first element is set to the axis, of length 1.
  - `outAngle`: Its first element is set to the angle, in radians.
- `QuaternionFromEuler`: Returns a rotation by Euler angles as a quaternion.
  - `pitch`: About x, in radians.
  - `yaw`: About y.
  - `roll`: About z.
  - returns: The quaternion.
- `QuaternionToEuler`: Returns a quaternion's rotation as Euler angles: about x (pitch), y (yaw) and z (roll), as `QuaternionFromEuler` takes them.
  - `q`: The quaternion.
  - returns: The angles, in radians.
- `QuaternionTransform`: Returns a quaternion's four components transformed by a matrix, as a point with w.
  - `q`: The quaternion.
  - `mat`: The matrix.
  - returns: The transformed quaternion.
- `QuaternionEquals`: Returns whether two quaternions are the same rotation but for rounding: equal as `FloatEquals` compares each component, or one the other negated.
  - `p`: One.
  - `q`: The other.
  - returns: 1 if they are, 0 if not.
- `MatrixDecompose`: Splits a transform matrix into its translation, rotation and scale, as raylib 6.2's (5.5's took the scale from the rows, wrong for a turned matrix scaled unevenly): the columns, made orthonormal one after another (the shear between them dropped), are the rotation, their lengths the scale, all three negated when the matrix mirrors.
  - `mat`: The matrix.
  - `translation`: Set to its translation.
  - `rotation`: Set to its rotation.
  - `scale`: Set to its scale.

## Rectangle

*class* in [`engines/raylib/src/helix/raylib/Rectangle.hx`](../../engines/raylib/src/helix/raylib/Rectangle.hx), `import helix.raylib.Rectangle;`

Represents raylib's `Rectangle`: its top-left corner and its size.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?x:Float, ?y:Float, ?width:Float, ?height:Float}
```

```haxe
var x:Float
var y:Float
var width:Float
var height:Float
```

- `x`: Gets or sets the left edge.
- `y`: Gets or sets the top edge.
- `width`: Gets or sets the width.
- `height`: Gets or sets the height.

## RenderTexture

*class* in [`engines/raylib/src/helix/raylib/RenderTexture.hx`](../../engines/raylib/src/helix/raylib/RenderTexture.hx), `import helix.raylib.RenderTexture;`

Represents raylib's `RenderTexture`, which is also its `RenderTexture2D`: a texture drawn into between `BeginTextureMode` and `EndTextureMode`. As in raylib, its texture is upside down: draw it with a negative source height to show it the right way up.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?id:Int, ?texture:Texture2D, ?depth:Texture2D}
```

```haxe
var id:Int
var texture:Texture2D
var depth:Texture2D
```

- `id`: Gets the render target's handle, 0 for none.
- `texture`: Gets the color it is drawn into.
- `depth`: Gets the depth it is drawn with; it can't be sampled here, so its id is 0.

## RenderTexture2D

*typedef* in [`engines/raylib/src/helix/raylib/RenderTexture2D.hx`](../../engines/raylib/src/helix/raylib/RenderTexture2D.hx), `import helix.raylib.RenderTexture2D;`

raylib's `RenderTexture2D`, the same as `RenderTexture`.

An alias of `RenderTexture`.

## Rlgl

*class* in [`engines/raylib/src/helix/raylib/Rlgl.hx`](../../engines/raylib/src/helix/raylib/Rlgl.hx), `import helix.raylib.Rlgl;`

Provides rlgl's API, as raylib 5.5's `rlgl.h` names it: the matrix stack, immediate drawing (`rlBegin`, `rlVertex3f`, `rlEnd`) and render state. As in raylib, it is apart from `Raylib`, so a program that uses it imports it too:

```haxe
import helix.raylib.Raylib.*;
import helix.raylib.Rlgl.*;
```

rlgl's GPU objects (vertex arrays and buffers, framebuffers, GL ids) aren't here: helix-raylib draws through helix-platform, which has no GL. What rlgl has and helix-raylib doesn't refuses to compile, naming itself.

### OpenGL version (rlGlVersion)

```haxe
static inline var RL_OPENGL_11:Int
static inline var RL_OPENGL_21:Int
static inline var RL_OPENGL_33:Int
static inline var RL_OPENGL_43:Int
static inline var RL_OPENGL_ES_20:Int
static inline var RL_OPENGL_ES_30:Int
```

- `RL_OPENGL_11`: OpenGL 1.1.
- `RL_OPENGL_21`: OpenGL 2.1 (GLSL 120).
- `RL_OPENGL_33`: OpenGL 3.3 (GLSL 330).
- `RL_OPENGL_43`: OpenGL 4.3 (using GLSL 330).
- `RL_OPENGL_ES_20`: OpenGL ES 2.0 (GLSL 100).
- `RL_OPENGL_ES_30`: OpenGL ES 3.0 (GLSL 300 es).

### Trace log level (rlTraceLogLevel)

```haxe
static inline var RL_LOG_ALL:Int
static inline var RL_LOG_TRACE:Int
static inline var RL_LOG_DEBUG:Int
static inline var RL_LOG_INFO:Int
static inline var RL_LOG_WARNING:Int
static inline var RL_LOG_ERROR:Int
static inline var RL_LOG_FATAL:Int
static inline var RL_LOG_NONE:Int
```

- `RL_LOG_ALL`: Display all logs.
- `RL_LOG_TRACE`: Trace logging, intended for internal use only.
- `RL_LOG_DEBUG`: Debug logging, used for internal debugging, it should be disabled on release builds.
- `RL_LOG_INFO`: Info logging, used for program execution info.
- `RL_LOG_WARNING`: Warning logging, used on recoverable failures.
- `RL_LOG_ERROR`: Error logging, used on unrecoverable failures.
- `RL_LOG_FATAL`: Fatal logging, used to abort program: exit(EXIT_FAILURE).
- `RL_LOG_NONE`: Disable logging.

### Texture pixel formats (rlPixelFormat)

```haxe
static inline var RL_PIXELFORMAT_UNCOMPRESSED_GRAYSCALE:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R5G6B5:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R8G8B8:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R5G5B5A1:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R4G4B4A4:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R8G8B8A8:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R32:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R32G32B32:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R32G32B32A32:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R16:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R16G16B16:Int
static inline var RL_PIXELFORMAT_UNCOMPRESSED_R16G16B16A16:Int
static inline var RL_PIXELFORMAT_COMPRESSED_DXT1_RGB:Int
static inline var RL_PIXELFORMAT_COMPRESSED_DXT1_RGBA:Int
static inline var RL_PIXELFORMAT_COMPRESSED_DXT3_RGBA:Int
static inline var RL_PIXELFORMAT_COMPRESSED_DXT5_RGBA:Int
static inline var RL_PIXELFORMAT_COMPRESSED_ETC1_RGB:Int
static inline var RL_PIXELFORMAT_COMPRESSED_ETC2_RGB:Int
static inline var RL_PIXELFORMAT_COMPRESSED_ETC2_EAC_RGBA:Int
static inline var RL_PIXELFORMAT_COMPRESSED_PVRT_RGB:Int
static inline var RL_PIXELFORMAT_COMPRESSED_PVRT_RGBA:Int
static inline var RL_PIXELFORMAT_COMPRESSED_ASTC_4x4_RGBA:Int
static inline var RL_PIXELFORMAT_COMPRESSED_ASTC_8x8_RGBA:Int
```

- `RL_PIXELFORMAT_UNCOMPRESSED_GRAYSCALE`: 8 bit per pixel (no alpha).
- `RL_PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA`: 8*2 bpp (2 channels).
- `RL_PIXELFORMAT_UNCOMPRESSED_R5G6B5`: 16 bpp.
- `RL_PIXELFORMAT_UNCOMPRESSED_R8G8B8`: 24 bpp.
- `RL_PIXELFORMAT_UNCOMPRESSED_R5G5B5A1`: 16 bpp (1 bit alpha).
- `RL_PIXELFORMAT_UNCOMPRESSED_R4G4B4A4`: 16 bpp (4 bit alpha).
- `RL_PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`: 32 bpp.
- `RL_PIXELFORMAT_UNCOMPRESSED_R32`: 32 bpp (1 channel - float).
- `RL_PIXELFORMAT_UNCOMPRESSED_R32G32B32`: 32*3 bpp (3 channels - float).
- `RL_PIXELFORMAT_UNCOMPRESSED_R32G32B32A32`: 32*4 bpp (4 channels - float).
- `RL_PIXELFORMAT_UNCOMPRESSED_R16`: 16 bpp (1 channel - half float).
- `RL_PIXELFORMAT_UNCOMPRESSED_R16G16B16`: 16*3 bpp (3 channels - half float).
- `RL_PIXELFORMAT_UNCOMPRESSED_R16G16B16A16`: 16*4 bpp (4 channels - half float).
- `RL_PIXELFORMAT_COMPRESSED_DXT1_RGB`: 4 bpp (no alpha).
- `RL_PIXELFORMAT_COMPRESSED_DXT1_RGBA`: 4 bpp (1 bit alpha).
- `RL_PIXELFORMAT_COMPRESSED_DXT3_RGBA`: 8 bpp.
- `RL_PIXELFORMAT_COMPRESSED_DXT5_RGBA`: 8 bpp.
- `RL_PIXELFORMAT_COMPRESSED_ETC1_RGB`: 4 bpp.
- `RL_PIXELFORMAT_COMPRESSED_ETC2_RGB`: 4 bpp.
- `RL_PIXELFORMAT_COMPRESSED_ETC2_EAC_RGBA`: 8 bpp.
- `RL_PIXELFORMAT_COMPRESSED_PVRT_RGB`: 4 bpp.
- `RL_PIXELFORMAT_COMPRESSED_PVRT_RGBA`: 4 bpp.
- `RL_PIXELFORMAT_COMPRESSED_ASTC_4x4_RGBA`: 8 bpp.
- `RL_PIXELFORMAT_COMPRESSED_ASTC_8x8_RGBA`: 2 bpp.

### Texture parameters: filter mode (rlTextureFilter)

```haxe
static inline var RL_TEXTURE_FILTER_POINT:Int
static inline var RL_TEXTURE_FILTER_BILINEAR:Int
static inline var RL_TEXTURE_FILTER_TRILINEAR:Int
static inline var RL_TEXTURE_FILTER_ANISOTROPIC_4X:Int
static inline var RL_TEXTURE_FILTER_ANISOTROPIC_8X:Int
static inline var RL_TEXTURE_FILTER_ANISOTROPIC_16X:Int
```

- `RL_TEXTURE_FILTER_POINT`: No filter, just pixel approximation.
- `RL_TEXTURE_FILTER_BILINEAR`: Linear filtering.
- `RL_TEXTURE_FILTER_TRILINEAR`: Trilinear filtering (linear with mipmaps).
- `RL_TEXTURE_FILTER_ANISOTROPIC_4X`: Anisotropic filtering 4x.
- `RL_TEXTURE_FILTER_ANISOTROPIC_8X`: Anisotropic filtering 8x.
- `RL_TEXTURE_FILTER_ANISOTROPIC_16X`: Anisotropic filtering 16x.

### Color blending modes (pre-defined) (rlBlendMode)

```haxe
static inline var RL_BLEND_ALPHA:Int
static inline var RL_BLEND_ADDITIVE:Int
static inline var RL_BLEND_MULTIPLIED:Int
static inline var RL_BLEND_ADD_COLORS:Int
static inline var RL_BLEND_SUBTRACT_COLORS:Int
static inline var RL_BLEND_ALPHA_PREMULTIPLY:Int
static inline var RL_BLEND_CUSTOM:Int
static inline var RL_BLEND_CUSTOM_SEPARATE:Int
```

- `RL_BLEND_ALPHA`: Blend textures considering alpha (default).
- `RL_BLEND_ADDITIVE`: Blend textures adding colors.
- `RL_BLEND_MULTIPLIED`: Blend textures multiplying colors.
- `RL_BLEND_ADD_COLORS`: Blend textures adding colors (alternative).
- `RL_BLEND_SUBTRACT_COLORS`: Blend textures subtracting colors (alternative).
- `RL_BLEND_ALPHA_PREMULTIPLY`: Blend premultiplied textures considering alpha.
- `RL_BLEND_CUSTOM`: Blend textures using custom src/dst factors (use rlSetBlendFactors()).
- `RL_BLEND_CUSTOM_SEPARATE`: Blend textures using custom src/dst factors (use rlSetBlendFactorsSeparate()).

### Shader location point type (rlShaderLocationIndex)

```haxe
static inline var RL_SHADER_LOC_VERTEX_POSITION:Int
static inline var RL_SHADER_LOC_VERTEX_TEXCOORD01:Int
static inline var RL_SHADER_LOC_VERTEX_TEXCOORD02:Int
static inline var RL_SHADER_LOC_VERTEX_NORMAL:Int
static inline var RL_SHADER_LOC_VERTEX_TANGENT:Int
static inline var RL_SHADER_LOC_VERTEX_COLOR:Int
static inline var RL_SHADER_LOC_MATRIX_MVP:Int
static inline var RL_SHADER_LOC_MATRIX_VIEW:Int
static inline var RL_SHADER_LOC_MATRIX_PROJECTION:Int
static inline var RL_SHADER_LOC_MATRIX_MODEL:Int
static inline var RL_SHADER_LOC_MATRIX_NORMAL:Int
static inline var RL_SHADER_LOC_VECTOR_VIEW:Int
static inline var RL_SHADER_LOC_COLOR_DIFFUSE:Int
static inline var RL_SHADER_LOC_COLOR_SPECULAR:Int
static inline var RL_SHADER_LOC_COLOR_AMBIENT:Int
static inline var RL_SHADER_LOC_MAP_ALBEDO:Int
static inline var RL_SHADER_LOC_MAP_METALNESS:Int
static inline var RL_SHADER_LOC_MAP_NORMAL:Int
static inline var RL_SHADER_LOC_MAP_ROUGHNESS:Int
static inline var RL_SHADER_LOC_MAP_OCCLUSION:Int
static inline var RL_SHADER_LOC_MAP_EMISSION:Int
static inline var RL_SHADER_LOC_MAP_HEIGHT:Int
static inline var RL_SHADER_LOC_MAP_CUBEMAP:Int
static inline var RL_SHADER_LOC_MAP_IRRADIANCE:Int
static inline var RL_SHADER_LOC_MAP_PREFILTER:Int
static inline var RL_SHADER_LOC_MAP_BRDF:Int
```

- `RL_SHADER_LOC_VERTEX_POSITION`: Shader location: vertex attribute: position.
- `RL_SHADER_LOC_VERTEX_TEXCOORD01`: Shader location: vertex attribute: texcoord01.
- `RL_SHADER_LOC_VERTEX_TEXCOORD02`: Shader location: vertex attribute: texcoord02.
- `RL_SHADER_LOC_VERTEX_NORMAL`: Shader location: vertex attribute: normal.
- `RL_SHADER_LOC_VERTEX_TANGENT`: Shader location: vertex attribute: tangent.
- `RL_SHADER_LOC_VERTEX_COLOR`: Shader location: vertex attribute: color.
- `RL_SHADER_LOC_MATRIX_MVP`: Shader location: matrix uniform: model-view-projection.
- `RL_SHADER_LOC_MATRIX_VIEW`: Shader location: matrix uniform: view (camera transform).
- `RL_SHADER_LOC_MATRIX_PROJECTION`: Shader location: matrix uniform: projection.
- `RL_SHADER_LOC_MATRIX_MODEL`: Shader location: matrix uniform: model (transform).
- `RL_SHADER_LOC_MATRIX_NORMAL`: Shader location: matrix uniform: normal.
- `RL_SHADER_LOC_VECTOR_VIEW`: Shader location: vector uniform: view.
- `RL_SHADER_LOC_COLOR_DIFFUSE`: Shader location: vector uniform: diffuse color.
- `RL_SHADER_LOC_COLOR_SPECULAR`: Shader location: vector uniform: specular color.
- `RL_SHADER_LOC_COLOR_AMBIENT`: Shader location: vector uniform: ambient color.
- `RL_SHADER_LOC_MAP_ALBEDO`: Shader location: sampler2d texture: albedo (same as: RL_SHADER_LOC_MAP_DIFFUSE).
- `RL_SHADER_LOC_MAP_METALNESS`: Shader location: sampler2d texture: metalness (same as: RL_SHADER_LOC_MAP_SPECULAR).
- `RL_SHADER_LOC_MAP_NORMAL`: Shader location: sampler2d texture: normal.
- `RL_SHADER_LOC_MAP_ROUGHNESS`: Shader location: sampler2d texture: roughness.
- `RL_SHADER_LOC_MAP_OCCLUSION`: Shader location: sampler2d texture: occlusion.
- `RL_SHADER_LOC_MAP_EMISSION`: Shader location: sampler2d texture: emission.
- `RL_SHADER_LOC_MAP_HEIGHT`: Shader location: sampler2d texture: height.
- `RL_SHADER_LOC_MAP_CUBEMAP`: Shader location: samplerCube texture: cubemap.
- `RL_SHADER_LOC_MAP_IRRADIANCE`: Shader location: samplerCube texture: irradiance.
- `RL_SHADER_LOC_MAP_PREFILTER`: Shader location: samplerCube texture: prefilter.
- `RL_SHADER_LOC_MAP_BRDF`: Shader location: sampler2d texture: brdf.

### Shader uniform data type (rlShaderUniformDataType)

```haxe
static inline var RL_SHADER_UNIFORM_FLOAT:Int
static inline var RL_SHADER_UNIFORM_VEC2:Int
static inline var RL_SHADER_UNIFORM_VEC3:Int
static inline var RL_SHADER_UNIFORM_VEC4:Int
static inline var RL_SHADER_UNIFORM_INT:Int
static inline var RL_SHADER_UNIFORM_IVEC2:Int
static inline var RL_SHADER_UNIFORM_IVEC3:Int
static inline var RL_SHADER_UNIFORM_IVEC4:Int
static inline var RL_SHADER_UNIFORM_UINT:Int
static inline var RL_SHADER_UNIFORM_UIVEC2:Int
static inline var RL_SHADER_UNIFORM_UIVEC3:Int
static inline var RL_SHADER_UNIFORM_UIVEC4:Int
static inline var RL_SHADER_UNIFORM_SAMPLER2D:Int
```

- `RL_SHADER_UNIFORM_FLOAT`: Shader uniform type: float.
- `RL_SHADER_UNIFORM_VEC2`: Shader uniform type: vec2 (2 float).
- `RL_SHADER_UNIFORM_VEC3`: Shader uniform type: vec3 (3 float).
- `RL_SHADER_UNIFORM_VEC4`: Shader uniform type: vec4 (4 float).
- `RL_SHADER_UNIFORM_INT`: Shader uniform type: int.
- `RL_SHADER_UNIFORM_IVEC2`: Shader uniform type: ivec2 (2 int).
- `RL_SHADER_UNIFORM_IVEC3`: Shader uniform type: ivec3 (3 int).
- `RL_SHADER_UNIFORM_IVEC4`: Shader uniform type: ivec4 (4 int).
- `RL_SHADER_UNIFORM_UINT`: Shader uniform type: unsigned int.
- `RL_SHADER_UNIFORM_UIVEC2`: Shader uniform type: uivec2 (2 unsigned int).
- `RL_SHADER_UNIFORM_UIVEC3`: Shader uniform type: uivec3 (3 unsigned int).
- `RL_SHADER_UNIFORM_UIVEC4`: Shader uniform type: uivec4 (4 unsigned int).
- `RL_SHADER_UNIFORM_SAMPLER2D`: Shader uniform type: sampler2d.

### Shader attribute data types (rlShaderAttributeDataType)

```haxe
static inline var RL_SHADER_ATTRIB_FLOAT:Int
static inline var RL_SHADER_ATTRIB_VEC2:Int
static inline var RL_SHADER_ATTRIB_VEC3:Int
static inline var RL_SHADER_ATTRIB_VEC4:Int
```

- `RL_SHADER_ATTRIB_FLOAT`: Shader attribute type: float.
- `RL_SHADER_ATTRIB_VEC2`: Shader attribute type: vec2 (2 float).
- `RL_SHADER_ATTRIB_VEC3`: Shader attribute type: vec3 (3 float).
- `RL_SHADER_ATTRIB_VEC4`: Shader attribute type: vec4 (4 float).

### Framebuffer attachment type (rlFramebufferAttachType)

```haxe
static inline var RL_ATTACHMENT_COLOR_CHANNEL0:Int
static inline var RL_ATTACHMENT_COLOR_CHANNEL1:Int
static inline var RL_ATTACHMENT_COLOR_CHANNEL2:Int
static inline var RL_ATTACHMENT_COLOR_CHANNEL3:Int
static inline var RL_ATTACHMENT_COLOR_CHANNEL4:Int
static inline var RL_ATTACHMENT_COLOR_CHANNEL5:Int
static inline var RL_ATTACHMENT_COLOR_CHANNEL6:Int
static inline var RL_ATTACHMENT_COLOR_CHANNEL7:Int
static inline var RL_ATTACHMENT_DEPTH:Int
static inline var RL_ATTACHMENT_STENCIL:Int
```

- `RL_ATTACHMENT_COLOR_CHANNEL0`: Framebuffer attachment type: color 0.
- `RL_ATTACHMENT_COLOR_CHANNEL1`: Framebuffer attachment type: color 1.
- `RL_ATTACHMENT_COLOR_CHANNEL2`: Framebuffer attachment type: color 2.
- `RL_ATTACHMENT_COLOR_CHANNEL3`: Framebuffer attachment type: color 3.
- `RL_ATTACHMENT_COLOR_CHANNEL4`: Framebuffer attachment type: color 4.
- `RL_ATTACHMENT_COLOR_CHANNEL5`: Framebuffer attachment type: color 5.
- `RL_ATTACHMENT_COLOR_CHANNEL6`: Framebuffer attachment type: color 6.
- `RL_ATTACHMENT_COLOR_CHANNEL7`: Framebuffer attachment type: color 7.
- `RL_ATTACHMENT_DEPTH`: Framebuffer attachment type: depth.
- `RL_ATTACHMENT_STENCIL`: Framebuffer attachment type: stencil.

### Framebuffer texture attachment type (rlFramebufferAttachTextureType)

```haxe
static inline var RL_ATTACHMENT_CUBEMAP_POSITIVE_X:Int
static inline var RL_ATTACHMENT_CUBEMAP_NEGATIVE_X:Int
static inline var RL_ATTACHMENT_CUBEMAP_POSITIVE_Y:Int
static inline var RL_ATTACHMENT_CUBEMAP_NEGATIVE_Y:Int
static inline var RL_ATTACHMENT_CUBEMAP_POSITIVE_Z:Int
static inline var RL_ATTACHMENT_CUBEMAP_NEGATIVE_Z:Int
static inline var RL_ATTACHMENT_TEXTURE2D:Int
static inline var RL_ATTACHMENT_RENDERBUFFER:Int
```

- `RL_ATTACHMENT_CUBEMAP_POSITIVE_X`: Framebuffer texture attachment type: cubemap, +X side.
- `RL_ATTACHMENT_CUBEMAP_NEGATIVE_X`: Framebuffer texture attachment type: cubemap, -X side.
- `RL_ATTACHMENT_CUBEMAP_POSITIVE_Y`: Framebuffer texture attachment type: cubemap, +Y side.
- `RL_ATTACHMENT_CUBEMAP_NEGATIVE_Y`: Framebuffer texture attachment type: cubemap, -Y side.
- `RL_ATTACHMENT_CUBEMAP_POSITIVE_Z`: Framebuffer texture attachment type: cubemap, +Z side.
- `RL_ATTACHMENT_CUBEMAP_NEGATIVE_Z`: Framebuffer texture attachment type: cubemap, -Z side.
- `RL_ATTACHMENT_TEXTURE2D`: Framebuffer texture attachment type: texture2d.
- `RL_ATTACHMENT_RENDERBUFFER`: Framebuffer texture attachment type: renderbuffer.

### Face culling mode (rlCullMode)

```haxe
static inline var RL_CULL_FACE_FRONT:Int
static inline var RL_CULL_FACE_BACK:Int
```

- `RL_CULL_FACE_FRONT`: Face culling mode: `RL_CULL_FACE_FRONT`.
- `RL_CULL_FACE_BACK`: Face culling mode: `RL_CULL_FACE_BACK`.

### rlgl.h's defines

```haxe
static inline var RL_DEFAULT_BATCH_BUFFER_ELEMENTS:Int
static inline var RL_DEFAULT_BATCH_BUFFERS:Int
static inline var RL_DEFAULT_BATCH_DRAWCALLS:Int
static inline var RL_DEFAULT_BATCH_MAX_TEXTURE_UNITS:Int
static inline var RL_MAX_MATRIX_STACK_SIZE:Int
static inline var RL_MAX_SHADER_LOCATIONS:Int
static inline var RL_CULL_DISTANCE_NEAR:Float
static inline var RL_CULL_DISTANCE_FAR:Float
static inline var RL_TEXTURE_WRAP_S:Int
static inline var RL_TEXTURE_WRAP_T:Int
static inline var RL_TEXTURE_MAG_FILTER:Int
static inline var RL_TEXTURE_MIN_FILTER:Int
static inline var RL_TEXTURE_FILTER_NEAREST:Int
static inline var RL_TEXTURE_FILTER_LINEAR:Int
static inline var RL_TEXTURE_FILTER_MIP_NEAREST:Int
static inline var RL_TEXTURE_FILTER_NEAREST_MIP_LINEAR:Int
static inline var RL_TEXTURE_FILTER_LINEAR_MIP_NEAREST:Int
static inline var RL_TEXTURE_FILTER_MIP_LINEAR:Int
static inline var RL_TEXTURE_FILTER_ANISOTROPIC:Int
static inline var RL_TEXTURE_MIPMAP_BIAS_RATIO:Int
static inline var RL_TEXTURE_WRAP_REPEAT:Int
static inline var RL_TEXTURE_WRAP_CLAMP:Int
static inline var RL_TEXTURE_WRAP_MIRROR_REPEAT:Int
static inline var RL_TEXTURE_WRAP_MIRROR_CLAMP:Int
static inline var RL_MODELVIEW:Int
static inline var RL_PROJECTION:Int
static inline var RL_TEXTURE:Int
static inline var RL_LINES:Int
static inline var RL_TRIANGLES:Int
static inline var RL_QUADS:Int
static inline var RL_UNSIGNED_BYTE:Int
static inline var RL_FLOAT:Int
static inline var RL_STREAM_DRAW:Int
static inline var RL_STREAM_READ:Int
static inline var RL_STREAM_COPY:Int
static inline var RL_STATIC_DRAW:Int
static inline var RL_STATIC_READ:Int
static inline var RL_STATIC_COPY:Int
static inline var RL_DYNAMIC_DRAW:Int
static inline var RL_DYNAMIC_READ:Int
static inline var RL_DYNAMIC_COPY:Int
static inline var RL_FRAGMENT_SHADER:Int
static inline var RL_VERTEX_SHADER:Int
static inline var RL_COMPUTE_SHADER:Int
static inline var RL_ZERO:Int
static inline var RL_ONE:Int
static inline var RL_SRC_COLOR:Int
static inline var RL_ONE_MINUS_SRC_COLOR:Int
static inline var RL_SRC_ALPHA:Int
static inline var RL_ONE_MINUS_SRC_ALPHA:Int
static inline var RL_DST_ALPHA:Int
static inline var RL_ONE_MINUS_DST_ALPHA:Int
static inline var RL_DST_COLOR:Int
static inline var RL_ONE_MINUS_DST_COLOR:Int
static inline var RL_SRC_ALPHA_SATURATE:Int
static inline var RL_CONSTANT_COLOR:Int
static inline var RL_ONE_MINUS_CONSTANT_COLOR:Int
static inline var RL_CONSTANT_ALPHA:Int
static inline var RL_ONE_MINUS_CONSTANT_ALPHA:Int
static inline var RL_FUNC_ADD:Int
static inline var RL_MIN:Int
static inline var RL_MAX:Int
static inline var RL_FUNC_SUBTRACT:Int
static inline var RL_FUNC_REVERSE_SUBTRACT:Int
static inline var RL_BLEND_EQUATION:Int
static inline var RL_BLEND_EQUATION_RGB:Int
static inline var RL_BLEND_EQUATION_ALPHA:Int
static inline var RL_BLEND_DST_RGB:Int
static inline var RL_BLEND_SRC_RGB:Int
static inline var RL_BLEND_DST_ALPHA:Int
static inline var RL_BLEND_SRC_ALPHA:Int
static inline var RL_BLEND_COLOR:Int
static inline var RL_READ_FRAMEBUFFER:Int
static inline var RL_DRAW_FRAMEBUFFER:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_POSITION:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_NORMAL:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_COLOR:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_TANGENT:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD2:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_INDICES:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_BONEIDS:Int
static inline var RL_DEFAULT_SHADER_ATTRIB_LOCATION_BONEWEIGHTS:Int
static inline var PI:Float
```

- `RL_DEFAULT_BATCH_BUFFER_ELEMENTS`: rlgl.h's `RL_DEFAULT_BATCH_BUFFER_ELEMENTS`.
- `RL_DEFAULT_BATCH_BUFFERS`: Default number of batch buffers (multi-buffering).
- `RL_DEFAULT_BATCH_DRAWCALLS`: Default number of batch draw calls (by state changes: mode, texture).
- `RL_DEFAULT_BATCH_MAX_TEXTURE_UNITS`: Maximum number of textures units that can be activated on batch drawing (SetShaderValueTexture()).
- `RL_MAX_MATRIX_STACK_SIZE`: Maximum size of Matrix stack.
- `RL_MAX_SHADER_LOCATIONS`: Maximum number of shader locations supported.
- `RL_CULL_DISTANCE_NEAR`: Default near cull distance.
- `RL_CULL_DISTANCE_FAR`: Default far cull distance.
- `RL_TEXTURE_WRAP_S`: GL_TEXTURE_WRAP_S.
- `RL_TEXTURE_WRAP_T`: GL_TEXTURE_WRAP_T.
- `RL_TEXTURE_MAG_FILTER`: GL_TEXTURE_MAG_FILTER.
- `RL_TEXTURE_MIN_FILTER`: GL_TEXTURE_MIN_FILTER.
- `RL_TEXTURE_FILTER_NEAREST`: GL_NEAREST.
- `RL_TEXTURE_FILTER_LINEAR`: GL_LINEAR.
- `RL_TEXTURE_FILTER_MIP_NEAREST`: GL_NEAREST_MIPMAP_NEAREST.
- `RL_TEXTURE_FILTER_NEAREST_MIP_LINEAR`: GL_NEAREST_MIPMAP_LINEAR.
- `RL_TEXTURE_FILTER_LINEAR_MIP_NEAREST`: GL_LINEAR_MIPMAP_NEAREST.
- `RL_TEXTURE_FILTER_MIP_LINEAR`: GL_LINEAR_MIPMAP_LINEAR.
- `RL_TEXTURE_FILTER_ANISOTROPIC`: Anisotropic filter (custom identifier).
- `RL_TEXTURE_MIPMAP_BIAS_RATIO`: Texture mipmap bias, percentage ratio (custom identifier).
- `RL_TEXTURE_WRAP_REPEAT`: GL_REPEAT.
- `RL_TEXTURE_WRAP_CLAMP`: GL_CLAMP_TO_EDGE.
- `RL_TEXTURE_WRAP_MIRROR_REPEAT`: GL_MIRRORED_REPEAT.
- `RL_TEXTURE_WRAP_MIRROR_CLAMP`: GL_MIRROR_CLAMP_EXT.
- `RL_MODELVIEW`: GL_MODELVIEW.
- `RL_PROJECTION`: GL_PROJECTION.
- `RL_TEXTURE`: GL_TEXTURE.
- `RL_LINES`: GL_LINES.
- `RL_TRIANGLES`: GL_TRIANGLES.
- `RL_QUADS`: GL_QUADS.
- `RL_UNSIGNED_BYTE`: GL_UNSIGNED_BYTE.
- `RL_FLOAT`: GL_FLOAT.
- `RL_STREAM_DRAW`: GL_STREAM_DRAW.
- `RL_STREAM_READ`: GL_STREAM_READ.
- `RL_STREAM_COPY`: GL_STREAM_COPY.
- `RL_STATIC_DRAW`: GL_STATIC_DRAW.
- `RL_STATIC_READ`: GL_STATIC_READ.
- `RL_STATIC_COPY`: GL_STATIC_COPY.
- `RL_DYNAMIC_DRAW`: GL_DYNAMIC_DRAW.
- `RL_DYNAMIC_READ`: GL_DYNAMIC_READ.
- `RL_DYNAMIC_COPY`: GL_DYNAMIC_COPY.
- `RL_FRAGMENT_SHADER`: GL_FRAGMENT_SHADER.
- `RL_VERTEX_SHADER`: GL_VERTEX_SHADER.
- `RL_COMPUTE_SHADER`: GL_COMPUTE_SHADER.
- `RL_ZERO`: GL_ZERO.
- `RL_ONE`: GL_ONE.
- `RL_SRC_COLOR`: GL_SRC_COLOR.
- `RL_ONE_MINUS_SRC_COLOR`: GL_ONE_MINUS_SRC_COLOR.
- `RL_SRC_ALPHA`: GL_SRC_ALPHA.
- `RL_ONE_MINUS_SRC_ALPHA`: GL_ONE_MINUS_SRC_ALPHA.
- `RL_DST_ALPHA`: GL_DST_ALPHA.
- `RL_ONE_MINUS_DST_ALPHA`: GL_ONE_MINUS_DST_ALPHA.
- `RL_DST_COLOR`: GL_DST_COLOR.
- `RL_ONE_MINUS_DST_COLOR`: GL_ONE_MINUS_DST_COLOR.
- `RL_SRC_ALPHA_SATURATE`: GL_SRC_ALPHA_SATURATE.
- `RL_CONSTANT_COLOR`: GL_CONSTANT_COLOR.
- `RL_ONE_MINUS_CONSTANT_COLOR`: GL_ONE_MINUS_CONSTANT_COLOR.
- `RL_CONSTANT_ALPHA`: GL_CONSTANT_ALPHA.
- `RL_ONE_MINUS_CONSTANT_ALPHA`: GL_ONE_MINUS_CONSTANT_ALPHA.
- `RL_FUNC_ADD`: GL_FUNC_ADD.
- `RL_MIN`: GL_MIN.
- `RL_MAX`: GL_MAX.
- `RL_FUNC_SUBTRACT`: GL_FUNC_SUBTRACT.
- `RL_FUNC_REVERSE_SUBTRACT`: GL_FUNC_REVERSE_SUBTRACT.
- `RL_BLEND_EQUATION`: GL_BLEND_EQUATION.
- `RL_BLEND_EQUATION_RGB`: GL_BLEND_EQUATION_RGB   // (Same as BLEND_EQUATION).
- `RL_BLEND_EQUATION_ALPHA`: GL_BLEND_EQUATION_ALPHA.
- `RL_BLEND_DST_RGB`: GL_BLEND_DST_RGB.
- `RL_BLEND_SRC_RGB`: GL_BLEND_SRC_RGB.
- `RL_BLEND_DST_ALPHA`: GL_BLEND_DST_ALPHA.
- `RL_BLEND_SRC_ALPHA`: GL_BLEND_SRC_ALPHA.
- `RL_BLEND_COLOR`: GL_BLEND_COLOR.
- `RL_READ_FRAMEBUFFER`: GL_READ_FRAMEBUFFER.
- `RL_DRAW_FRAMEBUFFER`: GL_DRAW_FRAMEBUFFER.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_POSITION`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_POSITION`.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD`.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_NORMAL`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_NORMAL`.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_COLOR`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_COLOR`.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_TANGENT`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_TANGENT`.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD2`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD2`.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_INDICES`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_INDICES`.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_BONEIDS`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_BONEIDS`.
- `RL_DEFAULT_SHADER_ATTRIB_LOCATION_BONEWEIGHTS`: rlgl.h's `RL_DEFAULT_SHADER_ATTRIB_LOCATION_BONEWEIGHTS`.
- `PI`: rlgl.h's `PI`.

### rlgl: the matrix stack, immediate drawing and render state

```haxe
static function rlMatrixMode(mode:Int):Void
static function rlPushMatrix():Void
static function rlPopMatrix():Void
static function rlLoadIdentity():Void
static function rlTranslatef(x:Float, y:Float, z:Float):Void
static function rlRotatef(angle:Float, x:Float, y:Float, z:Float):Void
static function rlScalef(x:Float, y:Float, z:Float):Void
static function rlMultMatrixf(matf:Array<Float>):Void
static function rlOrtho(left:Float, right:Float, bottom:Float, top:Float, znear:Float, zfar:Float):Void
static function rlFrustum(left:Float, right:Float, bottom:Float, top:Float, znear:Float, zfar:Float):Void
static function rlGetMatrixModelview():Matrix
static function rlGetMatrixProjection():Matrix
static function rlGetMatrixTransform():Matrix
static function rlSetMatrixModelview(view:Matrix):Void
static function rlSetMatrixProjection(proj:Matrix):Void
static function rlGetCullDistanceNear():Float
static function rlGetCullDistanceFar():Float
static function rlBegin(mode:Int):Void
static function rlEnd():Void
static function rlVertex2i(x:Int, y:Int):Void
static function rlVertex2f(x:Float, y:Float):Void
static function rlVertex3f(x:Float, y:Float, z:Float):Void
static function rlTexCoord2f(x:Float, y:Float):Void
static function rlNormal3f(x:Float, y:Float, z:Float):Void
static function rlColor4ub(r:Int, g:Int, b:Int, a:Int):Void
static function rlColor3f(x:Float, y:Float, z:Float):Void
static function rlColor4f(x:Float, y:Float, z:Float, w:Float):Void
static function rlSetTexture(id:Int):Void
static function rlSetBlendMode(mode:Int):Void
static function rlSetBlendFactors(glSrcFactor:Int, glDstFactor:Int, glEquation:Int):Void
static function rlSetBlendFactorsSeparate(glSrcRGB:Int, glDstRGB:Int, glSrcAlpha:Int, glDstAlpha:Int, glEqRGB:Int, glEqAlpha:Int):Void
static function rlColorMask(r:Bool, g:Bool, b:Bool, a:Bool):Void
static function rlDrawRenderBatchActive():Void
static function rlCheckRenderBatchLimit(vCount:Int):Bool
static function rlEnableColorBlend():Void
static function rlDisableColorBlend():Void
static function rlEnableDepthTest():Void
static function rlDisableDepthTest():Void
static function rlEnableDepthMask():Void
static function rlDisableDepthMask():Void
static function rlEnableBackfaceCulling():Void
static function rlDisableBackfaceCulling():Void
static function rlSetCullFace(mode:Int):Void
static function rlEnableWireMode():Void
static function rlEnablePointMode():Void
static function rlDisableWireMode():Void
static function rlEnableScissorTest():Void
static function rlDisableScissorTest():Void
static function rlScissor(x:Int, y:Int, width:Int, height:Int):Void
static function rlViewport(x:Int, y:Int, width:Int, height:Int):Void
static function rlSetClipPlanes(nearPlane:Float, farPlane:Float):Void
static function rlClearColor(r:Int, g:Int, b:Int, a:Int):Void
static function rlClearScreenBuffers():Void
static function rlSetLineWidth(width:Float):Void
static function rlGetLineWidth():Float
static function rlEnableSmoothLines():Void
static function rlDisableSmoothLines():Void
static function rlSetFramebufferWidth(width:Int):Void
static function rlGetFramebufferWidth():Int
static function rlSetFramebufferHeight(height:Int):Void
static function rlGetFramebufferHeight():Int
static function rlGetPixelFormatName(format:Int):String
static function rlEnableStereoRender():Void
static function rlDisableStereoRender():Void
static function rlIsStereoRenderEnabled():Bool
static function rlGetMatrixProjectionStereo(eye:Int):Matrix
static function rlGetMatrixViewOffsetStereo(eye:Int):Matrix
static function rlSetMatrixProjectionStereo(right:Matrix, left:Matrix):Void
static function rlSetMatrixViewOffsetStereo(right:Matrix, left:Matrix):Void
```

- `rlMatrixMode`: Chooses the matrix the next matrix calls change: `RL_MODELVIEW`, the view (or, between `rlPushMatrix` and `rlPopMatrix`, the transform the next vertices are moved by), or `RL_PROJECTION`.
  - `mode`: The matrix (`RL_MODELVIEW` or `RL_PROJECTION`; `RL_TEXTURE` changes nothing).
- `rlPushMatrix`: Saves the current matrix, to go back to with `rlPopMatrix`. In `RL_MODELVIEW`, the matrix calls until then move the vertices drawn after them.
  At most 32 are saved at once, as rlgl allows: past them it saves nothing and changes nothing, logging an error.
- `rlPopMatrix`: Goes back to the matrix last saved by `rlPushMatrix`.
- `rlLoadIdentity`: Makes the current matrix the identity.
- `rlTranslatef`: Moves by an offset before the current matrix.
  - `x`: The x offset.
  - `y`: The y offset.
  - `z`: The z offset.
- `rlRotatef`: Turns about an axis before the current matrix.
  - `angle`: The angle, in degrees.
  - `x`: The axis's x.
  - `y`: Its y.
  - `z`: Its z.
- `rlScalef`: Scales before the current matrix.
  - `x`: The x scale.
  - `y`: The y scale.
  - `z`: The z scale.
- `rlMultMatrixf`: Applies a matrix before the current one.
  - `matf`: The matrix's 16 numbers, by columns, as raylib's `MatrixToFloat` gives them.
- `rlOrtho`: Applies an orthographic projection before the current matrix.
  - `left`: The left plane.
  - `right`: The right plane.
  - `bottom`: The bottom plane.
  - `top`: The top plane.
  - `znear`: The near plane.
  - `zfar`: The far plane.
- `rlFrustum`: Applies a perspective projection before the current matrix, by its near plane's edges.
  - `left`: The near plane's left edge.
  - `right`: Its right edge.
  - `bottom`: Its bottom edge.
  - `top`: Its top edge.
  - `znear`: The near plane.
  - `zfar`: The far plane.
- `rlGetMatrixModelview`: Returns the view: the screen's, `BeginMode2D`'s or `BeginMode3D`'s.
  - returns: The matrix.
- `rlGetMatrixProjection`: Returns the projection.
  - returns: The matrix.
- `rlGetMatrixTransform`: Returns the transform `rlPushMatrix` started: the identity when none is pushed.
  - returns: The matrix.
- `rlSetMatrixModelview`: Sets the view.
  - `view`: The matrix.
- `rlSetMatrixProjection`: Sets the projection.
  - `proj`: The matrix.
- `rlGetCullDistanceNear`: Returns the near distance cameras see from, 0.01 until `rlSetClipPlanes` sets it.
  - returns: The distance.
- `rlGetCullDistanceFar`: Returns the far distance cameras see to, 1000 until `rlSetClipPlanes` sets it.
  - returns: The distance.
- `rlBegin`: Starts vertices: each 2 a line, 3 a triangle or 4 a quad, until `rlEnd`.
  - `mode`: `RL_LINES`, `RL_TRIANGLES` or `RL_QUADS`.

  A mode other than the last one's starts a new draw call: it takes the texture `rlSetTexture` last set, and the white texture is set for the next, so a second change of mode without another `rlSetTexture` draws untextured. The same mode again keeps the draw call and its texture.
- `rlEnd`: Ends the vertices `rlBegin` started; a shape left short of its vertices isn't drawn.
- `rlVertex2i`: Adds a vertex, with the color, texture coordinate and normal set last.
  - `x`: The x.
  - `y`: The y.
- `rlVertex2f`: Adds a vertex, with the color, texture coordinate and normal set last.
  - `x`: The x.
  - `y`: The y.
- `rlVertex3f`: Adds a vertex, with the color, texture coordinate and normal set last.
  - `x`: The x.
  - `y`: The y.
  - `z`: The z.
- `rlTexCoord2f`: Sets the next vertices' texture coordinate.
  - `x`: The u.
  - `y`: The v.
- `rlNormal3f`: Sets the next vertices' normal: turned by the transform `rlPushMatrix` started, when there is one, and made length 1, as rlgl does.
  - `x`: The x.
  - `y`: The y.
  - `z`: The z.
- `rlColor4ub`: Sets the next vertices' color.
  - `r`: The red, 0 to 255.
  - `g`: The green.
  - `b`: The blue.
  - `a`: The alpha.
- `rlColor3f`: Sets the next vertices' color, opaque.
  - `x`: The red, 0 to 1.
  - `y`: The green.
  - `z`: The blue.
- `rlColor4f`: Sets the next vertices' color.
  - `x`: The red, 0 to 1.
  - `y`: The green.
  - `z`: The blue.
  - `w`: The alpha.
- `rlSetTexture`: Sets the texture the next vertices draw with, as rlgl's: the vertices after it draw with it, and so does the draw call the next change of mode (`rlBegin`) starts. 0 leaves the vertices after it with the texture they have, and has the next change of mode start with the white texture.
  - `id`: The texture's id (`Texture2D.id`), or 0 for none.
- `rlSetBlendMode`: Sets how the next draws blend, as `BeginBlendMode` does.
  - `mode`: The mode (`RL_BLEND_*`, the same as `BLEND_*`).
- `rlSetBlendFactors`: Sets the GL factors and equation `RL_BLEND_CUSTOM` blends by, red, green, blue and alpha alike, as `glBlendFunc` and `glBlendEquation` take them. They take effect at the next `rlSetBlendMode(RL_BLEND_CUSTOM)`, even in that mode already. A value GL doesn't have leaves the factors (or the equation) as they were, as GL refuses it. raylib sets no blend color, so `RL_CONSTANT_COLOR` and `RL_CONSTANT_ALPHA` are 0 and their `RL_ONE_MINUS_` forms 1.
  - `glSrcFactor`: The source's factor (`RL_ZERO`, `RL_ONE`, `RL_SRC_COLOR`, ...).
  - `glDstFactor`: The destination's factor.
  - `glEquation`: How they combine (`RL_FUNC_ADD`, `RL_FUNC_SUBTRACT`, `RL_FUNC_REVERSE_SUBTRACT`, `RL_MIN`, `RL_MAX`).
- `rlSetBlendFactorsSeparate`: Sets the GL factors and equations `RL_BLEND_CUSTOM_SEPARATE` blends by, for red, green and blue apart from alpha, as `glBlendFuncSeparate` and `glBlendEquationSeparate` take them. They take effect at the next `rlSetBlendMode(RL_BLEND_CUSTOM_SEPARATE)`, as `rlSetBlendFactors`' do.
  - `glSrcRGB`: The source color's factor.
  - `glDstRGB`: The destination color's factor.
  - `glSrcAlpha`: The source alpha's factor.
  - `glDstAlpha`: The destination alpha's factor.
  - `glEqRGB`: How the colors combine.
  - `glEqAlpha`: How the alphas combine.
- `rlColorMask`: Sets which color channels the next draws write, as `glColorMask` does. The batch isn't drawn first, so the vertices waiting in it are masked too. `ClearBackground` clears every channel whatever this says, where raylib's clears only those written.
  - `r`: Whether red is written.
  - `g`: Whether green is written.
  - `b`: Whether blue is written.
  - `a`: Whether alpha is written.
- `rlDrawRenderBatchActive`: Draws the vertices waiting in rlgl's batch now, with the state as it is (rlgl's state calls don't, so a program calls this before and after changing one for the shapes between); a mode, a shader, blending, scissor or a pass changing does it too.
- `rlCheckRenderBatchLimit`: Returns whether the next vertices would overflow rlgl's batch, which it then draws first. The batch here has no such limit, so it is drawn only as it is flushed (`rlDrawRenderBatchActive`).
  - `vCount`: The vertices.
  - returns: False.
- `rlEnableColorBlend`: Blends the next draws as the blend mode says, as raylib starts.
- `rlDisableColorBlend`: Draws the next draws over what is there, without blending.
- `rlEnableDepthTest`: Tests the next draws' depth, keeping only what is as near as or nearer than what is drawn there. `BeginMode3D` does it.
- `rlDisableDepthTest`: Stops testing the next draws' depth, as raylib starts and `EndMode3D` does.
- `rlEnableDepthMask`: Lets the next draws that test depth write it, as raylib starts.
- `rlDisableDepthMask`: Stops the next draws writing depth, so what is drawn after isn't hidden by them, as for something see-through.
- `rlEnableBackfaceCulling`: Leaves out the next triangles' backs (or fronts, by `rlSetCullFace`), as raylib starts: a triangle's front is the side its corners are counterclockwise from.
- `rlDisableBackfaceCulling`: Draws both sides of the next triangles.
- `rlSetCullFace`: Chooses which side of triangles culling leaves out.
  - `mode`: `RL_CULL_FACE_BACK`, as raylib starts, or `RL_CULL_FACE_FRONT`.
- `rlEnableWireMode`: Draws triangles as their edges from now: a model drawn after it at once, and the shapes in rlgl's batch when it is next drawn (`rlDrawRenderBatchActive`), as GL's line mode does, which a page's WebGL hasn't, done here as lines. Culling still leaves out the triangles it would, by their facing on the screen as GL finds it; a shader that moves the vertices isn't seen in that. It ends point mode (`rlEnablePointMode`).
- `rlEnablePointMode`: Draws triangles as their corners from now, one pixel each: a model drawn after it at once (each index of its triangles, or each vertex of its whole triangles without indices), and the triangles in rlgl's batch when it is next drawn, as desktop GL's point mode does, which a page's WebGL hasn't, done here as points on every backend. Lines are drawn as lines. Culling still leaves out the triangles it would, by their facing on the screen as GL finds it. A shader's own `gl_PointSize` is ignored: every point is one pixel, the size every backend draws. `rlDisableWireMode` ends it, and `rlEnableWireMode` replaces it.
- `rlDisableWireMode`: Draws the next triangles filled, as raylib starts, ending wire mode or point mode.
- `rlEnableScissorTest`: Clips the next draws to the rectangle `rlScissor` last set: the whole pass until it is set.
- `rlDisableScissorTest`: Stops clipping the next draws, as `EndScissorMode` does.
- `rlScissor`: Sets the rectangle the next draws are clipped to while the scissor test is on, as GL takes it: in the framebuffer's pixels, from its bottom left. `BeginScissorMode` takes one from the top left in the screen's pixels.
  - `x`: Its left edge.
  - `y`: Its bottom edge, from the bottom.
  - `width`: Its width.
  - `height`: Its height.
- `rlViewport`: Sets the rectangle the next draws fill, as GL takes it, until the next pass begins (`BeginDrawing`, `BeginTextureMode`, `EndTextureMode`), which fills the whole of it again; the projection is unchanged, so what is drawn is squeezed into it.
  - `x`: Its left edge, in framebuffer pixels.
  - `y`: Its bottom edge, from the bottom.
  - `width`: Its width.
  - `height`: Its height.
- `rlSetClipPlanes`: Sets the near and far distances `BeginMode3D`'s cameras see between, and the rays and projections of cameras after it use.
  - `nearPlane`: The near distance, 0.01 until set.
  - `farPlane`: The far distance, 1000 until set.
- `rlClearColor`: Sets the color `rlClearScreenBuffers` clears to.
  - `r`: Red, 0 to 255.
  - `g`: Green.
  - `b`: Blue.
  - `a`: Alpha.
- `rlClearScreenBuffers`: Clears what is drawn into, its colors to `rlClearColor`'s (black until set) and its depth, as `ClearBackground` does.
- `rlSetLineWidth`: Sets the width lines are drawn at. GL 3.3's core profile and WebGL draw only 1, as raylib's lines are there, so lines stay 1 pixel wide; the width is kept for `rlGetLineWidth`.
  - `width`: The width, in pixels.
- `rlGetLineWidth`: Returns the width `rlSetLineWidth` last set, 1 until then.
  - returns: The width.
- `rlEnableSmoothLines`: Asks for smoothed lines. GL 3.3's core profile and WebGL don't smooth them, so this changes nothing; `FLAG_MSAA_4X_HINT` smooths every edge.
- `rlDisableSmoothLines`: Stops asking for smoothed lines, which changes nothing here (`rlEnableSmoothLines`).
- `rlSetFramebufferWidth`: Sets the width rlgl takes the framebuffer drawn into to have, until the next pass begins, as `BeginTextureMode` and `EndTextureMode` set it. Drawing here doesn't read it; `rlGetFramebufferWidth` gives it back.
  - `width`: The width, in pixels.
- `rlGetFramebufferWidth`: Returns the width of what is drawn into: the render texture's in `BeginTextureMode`, the screen's in framebuffer pixels otherwise, or `rlSetFramebufferWidth`'s since this pass began.
  - returns: The width.
- `rlSetFramebufferHeight`: Sets the height rlgl takes the framebuffer drawn into to have, until the next pass begins (`rlSetFramebufferWidth`).
  - `height`: The height, in pixels.
- `rlGetFramebufferHeight`: Returns the height of what is drawn into, as `rlGetFramebufferWidth` gives its width.
  - returns: The height.
- `rlGetPixelFormatName`: Returns a pixel format's name, as rlgl writes it in its log: "R8G8B8A8" for `RL_PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `format`: The format (`RL_PIXELFORMAT_*`).
  - returns: Its name; "UNKNOWN" for another number.
- `rlEnableStereoRender`: Turns stereo rendering on: from the next flush of the batch, its vertices waiting among them, and the next mesh drawn, each is drawn twice, in the left half of what is drawn into through the first eye's view offset and projection, then in the right half through the second's (`rlSetMatrixViewOffsetStereo`, `rlSetMatrixProjectionStereo`). After the batch the viewport is the whole again; after a mesh it is left the right half, as rlgl leaves it. `BeginVrStereoMode` turns it on with a config's matrices.
- `rlDisableStereoRender`: Turns stereo rendering off, for the next flush of the batch and the next mesh drawn.
- `rlIsStereoRenderEnabled`: Returns whether stereo rendering is on (`rlEnableStereoRender`).
  - returns: True when it is.
- `rlGetMatrixProjectionStereo`: Returns an eye's projection in stereo rendering, as `rlSetMatrixProjectionStereo` set it: zero until then, and for any other eye (raylib reads past its two).
  - `eye`: The eye: 0, drawn in the left half, or 1.
  - returns: The matrix.
- `rlGetMatrixViewOffsetStereo`: Returns an eye's view offset in stereo rendering, as `rlSetMatrixViewOffsetStereo` set it: zero until then, and for any other eye (raylib reads past its two).
  - `eye`: The eye: 0, drawn in the left half, or 1.
  - returns: The matrix.
- `rlSetMatrixProjectionStereo`: Sets each eye's projection in stereo rendering, in place of the projection, for the batch's next flush; a mesh's mvp takes it, its `matProjection` left the projection.
  - `right`: Eye 0's projection, drawn in the left half (raylib names it the right).
  - `left`: Eye 1's, drawn in the right half.
- `rlSetMatrixViewOffsetStereo`: Sets each eye's view offset in stereo rendering, applied after the view for the batch's next flush and a mesh's mvp.
  - `right`: Eye 0's offset, drawn in the left half (raylib names it the right).
  - `left`: Eye 1's, drawn in the right half.

### Not supported in helix-raylib

Each of these is raylib's name (or emscripten's, which raylib's web programs call), and a call to it doesn't compile, saying why and what to use instead.

`rlEnableVertexArray`, `rlDisableVertexArray`, `rlEnableVertexBuffer`, `rlDisableVertexBuffer`, `rlEnableVertexBufferElement`, `rlDisableVertexBufferElement`, `rlEnableVertexAttribute`, `rlDisableVertexAttribute`, `rlEnableStatePointer`, `rlDisableStatePointer`, `rlActiveTextureSlot`, `rlEnableTexture`, `rlDisableTexture`, `rlEnableTextureCubemap`, `rlDisableTextureCubemap`, `rlTextureParameters`, `rlCubemapParameters`, `rlEnableShader`, `rlDisableShader`, `rlEnableFramebuffer`, `rlDisableFramebuffer`, `rlGetActiveFramebuffer`, `rlActiveDrawBuffers`, `rlBlitFramebuffer`, `rlBindFramebuffer`, `rlCheckErrors`, `rlglInit`, `rlglClose`, `rlLoadExtensions`, `rlGetVersion`, `rlGetTextureIdDefault`, `rlGetShaderIdDefault`, `rlGetShaderLocsDefault`, `rlLoadRenderBatch`, `rlUnloadRenderBatch`, `rlDrawRenderBatch`, `rlSetRenderBatchActive`, `rlLoadVertexArray`, `rlLoadVertexBuffer`, `rlLoadVertexBufferElement`, `rlUpdateVertexBuffer`, `rlUpdateVertexBufferElements`, `rlUnloadVertexArray`, `rlUnloadVertexBuffer`, `rlSetVertexAttribute`, `rlSetVertexAttributeDivisor`, `rlSetVertexAttributeDefault`, `rlDrawVertexArray`, `rlDrawVertexArrayElements`, `rlDrawVertexArrayInstanced`, `rlDrawVertexArrayElementsInstanced`, `rlLoadTexture`, `rlLoadTextureDepth`, `rlLoadTextureCubemap`, `rlUpdateTexture`, `rlGetGlTextureFormats`, `rlUnloadTexture`, `rlGenTextureMipmaps`, `rlReadTexturePixels`, `rlReadScreenPixels`, `rlLoadFramebuffer`, `rlFramebufferAttach`, `rlFramebufferComplete`, `rlUnloadFramebuffer`, `rlLoadShaderCode`, `rlCompileShader`, `rlLoadShaderProgram`, `rlUnloadShaderProgram`, `rlGetLocationUniform`, `rlGetLocationAttrib`, `rlSetUniform`, `rlSetUniformMatrix`, `rlSetUniformMatrices`, `rlSetUniformSampler`, `rlSetShader`, `rlLoadComputeShaderProgram`, `rlComputeShaderDispatch`, `rlLoadShaderBuffer`, `rlUnloadShaderBuffer`, `rlUpdateShaderBuffer`, `rlBindShaderBuffer`, `rlReadShaderBuffer`, `rlCopyShaderBuffer`, `rlGetShaderBufferSize`, `rlBindImageTexture`, `rlLoadDrawCube`, `rlLoadDrawQuad`.

## Shader

*class* in [`engines/raylib/src/helix/raylib/Shader.hx`](../../engines/raylib/src/helix/raylib/Shader.hx), `import helix.raylib.Shader;`

Represents raylib's `Shader`: a program, made by `Raylib.LoadShader` or `Raylib.LoadShaderFromMemory`, and the locations of what it declares.

```haxe
var id(default, null):Int
var locs(default, null):Array<Int>
```

- `id`: Gets the program's handle, 0 for none.
- `locs`: Gets the locations of the values raylib sets itself, by `SHADER_LOC_*`, -1 for each it doesn't declare. A program may set them, as raylib's do; values are found by name here, so they change nothing.

## Sound

*class* in [`engines/raylib/src/helix/raylib/Sound.hx`](../../engines/raylib/src/helix/raylib/Sound.hx), `import helix.raylib.Sound;`

Represents raylib's `Sound`: a sound held whole, played by `Raylib.PlaySound`, over helix-services' `Audio`.

```haxe
var frameCount(default, null):Int
```

- `frameCount`: Gets the number of frames, at 44100 a second; 0 until the sound is loaded.

## Texture

*typedef* in [`engines/raylib/src/helix/raylib/Texture.hx`](../../engines/raylib/src/helix/raylib/Texture.hx), `import helix.raylib.Texture;`

raylib's `Texture`, the same as `Texture2D`.

An alias of `Texture2D`.

## Texture2D

*class* in [`engines/raylib/src/helix/raylib/Texture2D.hx`](../../engines/raylib/src/helix/raylib/Texture2D.hx), `import helix.raylib.Texture2D;`

Represents raylib's `Texture2D`: an image on the GPU.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?id:Int, ?width:Int, ?height:Int, ?mipmaps:Int, ?format:Int}
```

```haxe
var id:Int
var width:Int
var height:Int
var mipmaps:Int
var format:Int
```

- `id`: Gets the texture's handle, 0 for none.
- `width`: Gets the width, in pixels.
- `height`: Gets the height, in pixels.
- `mipmaps`: Gets the number of mipmap levels, 1 for none.
- `format`: Gets the pixel format: the image's for a texture made of one (`LoadTextureFromImage`; a glTF model's roughness and metalness maps are `PIXELFORMAT_UNCOMPRESSED_GRAYSCALE`), `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8` for the rest. Its pixels are RGBA on the GPU either way.

## TextureCubemap

*typedef* in [`engines/raylib/src/helix/raylib/TextureCubemap.hx`](../../engines/raylib/src/helix/raylib/TextureCubemap.hx), `import helix.raylib.TextureCubemap;`

raylib's `TextureCubemap`, the same as `Texture`: a cubemap's record, made by `Raylib.LoadTextureCubemap`.

An alias of `Texture`.

## Transform

*class* in [`engines/raylib/src/helix/raylib/Transform.hx`](../../engines/raylib/src/helix/raylib/Transform.hx), `import helix.raylib.Transform;`

Represents raylib's `Transform`: a translation, a rotation and a scale, as a bone's pose holds them.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?translation:Vector3, ?rotation:Quaternion, ?scale:Vector3}
```

```haxe
var translation:Vector3
var rotation:Quaternion
var scale:Vector3
```

- `translation`: Gets or sets the translation.
- `rotation`: Gets or sets the rotation, a quaternion.
- `scale`: Gets or sets the scale on each axis.

## Vector2

*class* in [`engines/raylib/src/helix/raylib/Vector2.hx`](../../engines/raylib/src/helix/raylib/Vector2.hx), `import helix.raylib.Vector2;`

Represents raylib's `Vector2`: a point or a direction in two dimensions.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?x:Float, ?y:Float}
```

```haxe
var x:Float
var y:Float
```

- `x`: Gets or sets the x component.
- `y`: Gets or sets the y component.

## Vector3

*class* in [`engines/raylib/src/helix/raylib/Vector3.hx`](../../engines/raylib/src/helix/raylib/Vector3.hx), `import helix.raylib.Vector3;`

Represents raylib's `Vector3`: a point or a direction in three dimensions.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?x:Float, ?y:Float, ?z:Float}
```

```haxe
var x:Float
var y:Float
var z:Float
```

- `x`: Gets or sets the x component.
- `y`: Gets or sets the y component.
- `z`: Gets or sets the z component.

## Vector4

*class* in [`engines/raylib/src/helix/raylib/Vector4.hx`](../../engines/raylib/src/helix/raylib/Vector4.hx), `import helix.raylib.Vector4;`

Represents raylib's `Vector4`, which is also its `Quaternion`.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?x:Float, ?y:Float, ?z:Float, ?w:Float}
```

```haxe
var x:Float
var y:Float
var z:Float
var w:Float
```

- `x`: Gets or sets the x component.
- `y`: Gets or sets the y component.
- `z`: Gets or sets the z component.
- `w`: Gets or sets the w component.

## VrDeviceInfo

*class* in [`engines/raylib/src/helix/raylib/VrDeviceInfo.hx`](../../engines/raylib/src/helix/raylib/VrDeviceInfo.hx), `import helix.raylib.VrDeviceInfo;`

Represents raylib's `VrDeviceInfo`: a head-mounted display's parameters, which `LoadVrStereoConfig` makes a stereo config of.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?hResolution:Int, ?vResolution:Int, ?hScreenSize:Float, ?vScreenSize:Float, ?eyeToScreenDistance:Float, ?lensSeparationDistance:Float, ?interpupillaryDistance:Float, ?lensDistortionValues:Array<Float>, ?chromaAbCorrection:Array<Float>}
```

```haxe
var hResolution:Int
var vResolution:Int
var hScreenSize:Float
var vScreenSize:Float
var eyeToScreenDistance:Float
var lensSeparationDistance:Float
var interpupillaryDistance:Float
var lensDistortionValues:Array<Float>
var chromaAbCorrection:Array<Float>
```

- `hResolution`: Gets or sets the horizontal resolution, in pixels.
- `vResolution`: Gets or sets the vertical resolution, in pixels.
- `hScreenSize`: Gets or sets the screen's horizontal size, in meters.
- `vScreenSize`: Gets or sets the screen's vertical size, in meters.
- `eyeToScreenDistance`: Gets or sets the distance from the eyes to the screen, in meters.
- `lensSeparationDistance`: Gets or sets the distance between the lenses' centers, in meters.
- `interpupillaryDistance`: Gets or sets the distance between the pupils, in meters.
- `lensDistortionValues`: Gets or sets the lenses' four distortion constants.
- `chromaAbCorrection`: Gets or sets the four chromatic aberration correction parameters.

## VrStereoConfig

*class* in [`engines/raylib/src/helix/raylib/VrStereoConfig.hx`](../../engines/raylib/src/helix/raylib/VrStereoConfig.hx), `import helix.raylib.VrStereoConfig;`

Represents raylib's `VrStereoConfig`: what `BeginVrStereoMode` draws each eye with, and what a distortion shader reads, as `LoadVrStereoConfig` computes them from a display's parameters.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?projection:Array<Matrix>, ?viewOffset:Array<Matrix>, ?leftLensCenter:Array<Float>, ?rightLensCenter:Array<Float>, ?leftScreenCenter:Array<Float>, ?rightScreenCenter:Array<Float>, ?scale:Array<Float>, ?scaleIn:Array<Float>}
```

```haxe
var projection:Array<Matrix>
var viewOffset:Array<Matrix>
var leftLensCenter:Array<Float>
var rightLensCenter:Array<Float>
var leftScreenCenter:Array<Float>
var rightScreenCenter:Array<Float>
var scale:Array<Float>
var scaleIn:Array<Float>
```

- `projection`: Gets or sets each eye's projection: the first drawn in the left half.
- `viewOffset`: Gets or sets each eye's view offset, applied after the view.
- `leftLensCenter`: Gets or sets the left lens's center, x and y, 0 to 1 across what is drawn into.
- `rightLensCenter`: Gets or sets the right lens's center.
- `leftScreenCenter`: Gets or sets the left screen half's center.
- `rightScreenCenter`: Gets or sets the right screen half's center.
- `scale`: Gets or sets the distortion's scale, x and y.
- `scaleIn`: Gets or sets the distortion's scale in, x and y.

## Wave

*class* in [`engines/raylib/src/helix/raylib/Wave.hx`](../../engines/raylib/src/helix/raylib/Wave.hx), `import helix.raylib.Wave;`

Represents raylib's `Wave`: sound samples in memory, as `LoadWaveAsync` reads them and `LoadSoundFromWave` plays them.

The samples are interleaved, a frame a sample for each channel, left first: 8-bit unsigned, 16-bit signed or 32-bit float, little-endian. The `Wave*` functions change a wave in place, as raylib's do through its pointer: its fields are replaced.

```haxe
function new(?frameCount:Int = 0, ?sampleRate:Int = 0, ?sampleSize:Int = 0, ?channels:Int = 0, ?data:haxe.io.Bytes)
var frameCount:Int
var sampleRate:Int
var sampleSize:Int
var channels:Int
var data:Null<haxe.io.Bytes>
```

- `new`: Creates a wave's record. Its fields are zero and its data null unless given, as raylib's `Wave wave = { 0 }` is.
  - `frameCount`: The number of frames.
  - `sampleRate`: The frames a second.
  - `sampleSize`: The bits a sample takes.
  - `channels`: The number of channels.
  - `data`: Optional. The samples.
- `frameCount`: Gets or sets the number of frames, a sample for each channel.
- `sampleRate`: Gets or sets the frames a second.
- `sampleSize`: Gets or sets the bits a sample takes: 8, 16 or 32.
- `channels`: Gets or sets the number of channels: 1 is mono, 2 stereo.
- `data`: Gets or sets the samples, or null for none.

## Defines

Set in a build's hxml, as `-D helix-raylib-native-root=../assets`. `haxe --help-user-defines` lists them too, and an editor completes them in an hxml file.

- `helix-raylib-files=<directory>`: Where the program's files are as it builds, relative to the build's directory: LoadShader compiles the shaders it names from there. Defaults to web.
- `helix-raylib-native-root=<directory>`: Where a native program finds its files, relative to its own directory. Defaults to ../web.
- `helix-raylib-host-warnings`: Warns where the program's own code reaches the page or the host (the URL's query, Sys.getEnv, matchMedia, maxTouchPoints, screen.orientation, the safe area's insets, deviceorientation, localStorage, the page's fullscreen) for what helix.raylib.extras or Raylib answers on every target, naming the call. Off by default.
- `helix-raylib-custom-frame-control`: raylib's SUPPORT_CUSTOM_FRAME_CONTROL: EndDrawing only draws, and the program calls SwapScreenBuffer, WaitTime and PollInputEvents itself.
