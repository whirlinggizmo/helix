# helix.raylib

Generated from the doc comments by `tools/gen_apidoc.py`.

## Packages

- [`helix.raylib.extras`](extras.md): Audio, Debug, Device, Files, Gui, GuiSkins, Lights, Models, Shaders, Sprites, Text, Textures, Window

## AudioStream

*class* in [`engines/raylib/src/helix/raylib/AudioStream.hx`](../src/helix/raylib/AudioStream.hx), `import helix.raylib.AudioStream;`

Represents raylib's `AudioStream`: samples a program makes as it goes, played as `UpdateAudioStream` gives them, over helix-services' `SampleQueue`.

Holds raylib's double buffer: two buffers of `SetAudioStreamBufferSizeDefault` frames each, 1470 until set (a 30th of a second at 44100 Hz).

Each update fills one buffer while the other plays.

```haxe
var sampleRate(default, null):Int
var sampleSize(default, null):Int
var channels(default, null):Int
```

- `sampleRate`: Gets the sample rate, in frames a second.
- `sampleSize`: Gets the bits a sample takes: 8 (unsigned), 16 (signed) or 32 (float).
- `channels`: Gets the number of channels: 1 is mono, 2 stereo.

## AutomationEvent

*class* in [`engines/raylib/src/helix/raylib/AutomationEvent.hx`](../src/helix/raylib/AutomationEvent.hx), `import helix.raylib.AutomationEvent;`

Represents raylib's `AutomationEvent`: an input or window event recorded in a frame, to be played back later.

```haxe
function new()
var frame:Int
var type:Int
var params:Array<Int>
```

- `new`: Creates an event, its fields zero.
- `frame`: Gets or sets the frame of the event.
- `type`: Gets or sets what happened, by raylib's AutomationEventType number.
  - 1 and 2: a key up and down. - 5 and 6: a mouse button up and down. - 7: the mouse moved. 8: the wheel. - 11 and 12: a gamepad button up and down. 13: a gamepad axis. - 14 and 15: a finger up and down. 16: a finger moved. 17: a gesture. - 18 to 21: the window closed, maximized, minimized and resized. - 22: a screenshot. 23: the target frames a second.
- `params`: Gets or sets the event's four parameters, by its type: a key, a button, a position, a gamepad and its button or axis and value (times 32768), a size.

## AutomationEventList

*class* in [`engines/raylib/src/helix/raylib/AutomationEventList.hx`](../src/helix/raylib/AutomationEventList.hx), `import helix.raylib.AutomationEventList;`

Represents raylib's `AutomationEventList`: the events recorded, or loaded from a file, to be played.

```haxe
function new()
var capacity:Int
var count:Int
var events:Array<AutomationEvent>
```

- `new`: Creates an empty list of no capacity.
- `capacity`: Gets or sets the most events the list holds: 16384 (raylib's MAX_AUTOMATION_EVENTS) for a list `LoadAutomationEventList` or `LoadAutomationEventListAsync` made.
- `count`: Gets or sets how many events the list holds.
- `events`: Gets or sets the events, `count` of them.

## BoneInfo

*class* in [`engines/raylib/src/helix/raylib/BoneInfo.hx`](../src/helix/raylib/BoneInfo.hx), `import helix.raylib.BoneInfo;`

Represents raylib's `BoneInfo`: one bone of a skeleton, its name and its parent.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?name:String, ?parent:Int}
```

```haxe
var name:String
var parent:Int
```

- `name`: Gets or sets the name, its node's cut to 31 bytes as raylib's struct holds it.
- `parent`: Gets or sets the parent, by its index in the same bones, or -1 for a root.

## BoundingBox

*class* in [`engines/raylib/src/helix/raylib/BoundingBox.hx`](../src/helix/raylib/BoundingBox.hx), `import helix.raylib.BoundingBox;`

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

*typedef* in [`engines/raylib/src/helix/raylib/Camera.hx`](../src/helix/raylib/Camera.hx), `import helix.raylib.Camera;`

Represents raylib's `Camera`, the same type as `Camera3D`.

An alias of `Camera3D`.

## Camera2D

*class* in [`engines/raylib/src/helix/raylib/Camera2D.hx`](../src/helix/raylib/Camera2D.hx), `import helix.raylib.Camera2D;`

Represents raylib's `Camera2D`: its target, where the target shows on the screen, its rotation and its zoom.

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
- `target`: Gets or sets the camera's target, the point in the world shown at `offset`.
- `rotation`: Gets or sets the rotation, in degrees.
- `zoom`: Gets or sets the zoom, 1 for none.

## Camera3D

*class* in [`engines/raylib/src/helix/raylib/Camera3D.hx`](../src/helix/raylib/Camera3D.hx), `import helix.raylib.Camera3D;`

Represents raylib's `Camera3D`, also its `Camera`: the camera's position, its target and its lens.

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

- `position`: Gets or sets the camera's position.
- `target`: Gets or sets the camera's target, the point in the middle of its view.
- `up`: Gets or sets the camera's up direction.
- `fovy`: Gets or sets the field of view, top to bottom, in degrees, or the height seen in orthographic.
- `projection`: Gets or sets the projection: `CAMERA_PERSPECTIVE` or `CAMERA_ORTHOGRAPHIC`.

## Color

*class* in [`engines/raylib/src/helix/raylib/Color.hx`](../src/helix/raylib/Color.hx), `import helix.raylib.Color;`

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

*class* in [`engines/raylib/src/helix/raylib/FilePathList.hx`](../src/helix/raylib/FilePathList.hx), `import helix.raylib.FilePathList;`

Represents raylib's `FilePathList`: the paths of a directory's listing or of a drop.

```haxe
function new()
var capacity:Int
var count:Int
var paths:Array<String>
```

- `new`: Creates an empty list.
- `capacity`: Gets or sets the list's capacity, as raylib's: 8192 for `LoadDirectoryFilesExAsync`'s, the count for `LoadDirectoryFilesAsync`'s and 0 for `LoadDroppedFiles`'s.
- `count`: Gets or sets how many paths there are.
- `paths`: Gets or sets the paths.

## Font

*class* in [`engines/raylib/src/helix/raylib/Font.hx`](../src/helix/raylib/Font.hx), `import helix.raylib.Font;`

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

- `new`: Creates a font, its fields zero or empty. See `extras.Text.LoadFontExAsync` and the other loads for loading a font, and `Raylib.GetFontDefault` for getting raylib's default font.
- `baseSize`: Gets or sets the size the font was made at, its glyphs' height in pixels.
- `glyphCount`: Gets or sets how many glyphs it has.
- `glyphPadding`: Gets or sets the padding around each glyph on its texture, in pixels.
- `texture`: Gets or sets the texture holding the glyphs.
- `recs`: Gets or sets each glyph's rectangle on the texture.
- `glyphs`: Gets or sets each glyph's character, offsets, advance and image.

## FrameStatsStyle

*class* in [`engines/raylib/src/helix/raylib/FrameStatsStyle.hx`](../src/helix/raylib/FrameStatsStyle.hx), `import helix.raylib.FrameStatsStyle;`

Represents how `DrawFrameStatsEx` (`helix.raylib.extras.Debug`) draws the frame's cost: which stats it shows, and their look.

Every field has a default, so a style sets only what it changes: `{fontSize: 24, triangles: true}`.

Each stat shown is a line of its own.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?fps:Bool, ?frameTime:Bool, ?drawCalls:Bool, ?triangles:Bool, ?stateChanges:Bool, ?gpuTextures:Bool, ?gpuBuffers:Bool, ?memory:Bool, ?targetFps:Int, ?onTargetColor:Color, ?belowTargetColor:Color, ?farBelowTargetColor:Color, ?font:Null<Font>, ?fontSize:Int, ?spacing:Float, ?padding:Int, ?backgroundColor:Color}
```

```haxe
var fps:Bool = true
var frameTime:Bool = true
var drawCalls:Bool = true
var triangles:Bool = false
var stateChanges:Bool = false
var gpuTextures:Bool = false
var gpuBuffers:Bool = false
var memory:Bool = false
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

- `fps`: Gets or sets a value indicating whether the frames a second show. Defaults to true.
- `frameTime`: Gets or sets a value indicating whether the frame time shows: its mean and its slowest 5% (p95) over the last half second, in milliseconds. Defaults to true.
- `drawCalls`: Gets or sets a value indicating whether the last frame's draw calls show: how many draws it sent the GPU. Defaults to true.
- `triangles`: Gets or sets a value indicating whether the last frame's triangles drawn show. Defaults to false.
- `stateChanges`: Gets or sets a value indicating whether the last frame's state changes show: how often its draws switched shader, render state or textures. Defaults to false.
- `gpuTextures`: Gets or sets a value indicating whether the megabytes of textures helix-raylib holds on the GPU show. Defaults to false.
  Counts textures, cubemaps, render textures and the skinning palettes, as their levels' bytes, without the GPU's own padding.
- `gpuBuffers`: Gets or sets a value indicating whether the megabytes of buffers helix-raylib holds on the GPU show. Defaults to false.
  Counts meshes' vertices and indices, the frame's batch and its quad indices, and a frame's instances.
- `memory`: Gets or sets a value indicating whether the megabytes of memory the program holds show, as `ISystem.getMemoryBytes` reports them. Defaults to false.
  Natively, the process's resident memory.

  In a page, the script heap where the browser reports it, and nothing where it doesn't.
- `targetFps`: Gets or sets the frame rate that sets the stats' color, in frames a second. Defaults to 0, for the target `SetTargetFPS` set, or the monitor's refresh rate when none is set.
- `onTargetColor`: Gets or sets the text's color when the frame rate is at or above the target. Defaults to `GREEN`.
- `belowTargetColor`: Gets or sets the text's color when the frame rate is below the target. Defaults to `YELLOW`.
- `farBelowTargetColor`: Gets or sets the text's color when the frame rate is below half the target. Defaults to `RED`.
- `font`: Gets or sets the font. Defaults to null, for raylib's default font.
- `fontSize`: Gets or sets the text's height, in pixels. Defaults to null, which scales the text to the window.
  Null draws at a 36th of the screen's height (20 at 720 lines, as `DrawFPS` draws), so the stats read alike at any window size.

  A size provided is used unchanged. One under 1 is refused.
- `spacing`: Gets or sets the space between letters, in pixels at the font's size, as `DrawTextEx`'s. Defaults to 1.
- `padding`: Gets or sets the space around the text inside its background, in pixels. Defaults to 4.
- `backgroundColor`: Gets or sets the background's color behind the text and its padding. Defaults to `BLANK`, for none.

## GlyphInfo

*class* in [`engines/raylib/src/helix/raylib/GlyphInfo.hx`](../src/helix/raylib/GlyphInfo.hx), `import helix.raylib.GlyphInfo;`

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

*class* in [`engines/raylib/src/helix/raylib/GuiSkin.hx`](../src/helix/raylib/GuiSkin.hx), `import helix.raylib.GuiSkin;`

Represents a skin: how one part of raygui's controls is drawn from a texture, a nine-patch for each state, in place of its style's flat colors.

Made by `GuiSkinFromTexture` and set by `GuiSetSkin`, both in `helix.raylib.extras.GuiSkins`.

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

- `texture`: Gets or sets the texture holding the patches, often one sheet for every skin.
- `normal`: Gets or sets the patch drawn in `STATE_NORMAL`.
- `focused`: Gets or sets the patch drawn in `STATE_FOCUSED`, with the pointer over the control, or null to draw `normal`.
- `pressed`: Gets or sets the patch drawn in `STATE_PRESSED`, or null to draw `focused`, or `normal` when that is null too.
- `disabled`: Gets or sets the patch drawn in `STATE_DISABLED`, or null to draw `normal`.
- `tint`: Gets or sets the tint multiplying the patches, `WHITE` to draw them unchanged.

## GuiStyleProp

*class* in [`engines/raylib/src/helix/raylib/GuiStyleProp.hx`](../src/helix/raylib/GuiStyleProp.hx), `import helix.raylib.GuiStyleProp;`

Represents one property of raygui's style, as raygui's `GuiStyleProp` holds it for a style written as code: the control, the property and its value, as `GuiSetStyle` takes them.

```haxe
function new(?controlId:Int = 0, ?propertyId:Int = 0, ?propertyValue:Int = 0)
var controlId:Int
var propertyId:Int
var propertyValue:Int
```

- `new`: Creates a style property.
  - `controlId`: The control.
  - `propertyId`: The property.
  - `propertyValue`: Its value.
- `controlId`: Gets or sets the control (`DEFAULT`, `BUTTON` and the rest).
- `propertyId`: Gets or sets the property (`BORDER_COLOR_NORMAL`, `TEXT_SIZE` and the rest).
- `propertyValue`: Gets or sets the property's value: a color as 0xRRGGBBAA, a size in pixels, or one of the property's values.

## Image

*class* in [`engines/raylib/src/helix/raylib/Image.hx`](../src/helix/raylib/Image.hx), `import helix.raylib.Image;`

Represents raylib's `Image`: pixels in memory, in one of raylib's pixel formats.

The bytes are laid out as raylib's: rows top first, each pixel `GetPixelDataSize(1, 1, format)` bytes.

16-bit values (the packed formats, the half floats) and 32-bit floats are little-endian.

An image with mipmaps holds its smaller levels after it, each half the size of the last.

The `Image*` functions change an image in place, as raylib's do through its pointer, replacing its fields.

```haxe
function new(?data:haxe.io.Bytes, ?width:Int = 0, ?height:Int = 0, ?mipmaps:Int = 0, ?format:Int = 0)
var data:Null<haxe.io.Bytes>
var width:Int
var height:Int
var mipmaps:Int
var format:Int
```

- `new`: Creates an image's record, its fields zero and its data null unless provided, as raylib's `Image image = { 0 }` is. See the `GenImage*` functions for making an image, and `LoadImageAsync` for loading one.
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

*class* in [`engines/raylib/src/helix/raylib/Light.hx`](../src/helix/raylib/Light.hx), `import helix.raylib.Light;`

Represents rlights' `Light` (raylib's examples' `rlights.h`): one light of a lit shader.

Made by `CreateLight`.

`UpdateLightValues` (`helix.raylib.extras.Lights`) sends a changed field to the shader.

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

- `new`: Creates a light that is off, every field 0, as C's `Light light = { 0 }`. See `CreateLight` for making a light that shines.
- `type`: Gets or sets the light's type: `LIGHT_DIRECTIONAL` or `LIGHT_POINT`.
- `enabled`: Gets or sets a value indicating whether the light shines.
- `position`: Gets or sets the light's position.
- `target`: Gets or sets the target, the point setting a directional light's direction.
- `color`: Gets or sets the light's color.
- `attenuation`: Gets or sets the attenuation, which rlights keeps and its shader ignores.
- `enabledLoc`: Gets or sets the location of `enabled` in the light's shader.
- `typeLoc`: Gets or sets the location of `type`.
- `positionLoc`: Gets or sets the location of `position`.
- `targetLoc`: Gets or sets the location of `target`.
- `colorLoc`: Gets or sets the location of `color`.
- `attenuationLoc`: Gets or sets the location of `attenuation`, which rlights never finds.

## Material

*class* in [`engines/raylib/src/helix/raylib/Material.hx`](../src/helix/raylib/Material.hx), `import helix.raylib.Material;`

Represents raylib's `Material`: a shader and its maps (`MATERIAL_MAP_*`).

A draw shows the diffuse map's texture and color.

Counted. The program holds a material from `new` or `LoadMaterialDefault` until `UnloadMaterial`, and so does each model whose `materials` has the material.

When the last holder lets go, the maps let go of their textures and the material lets go of its shader. Each is freed when nothing else holds it.

```haxe
function new(shader:Shader, maps:Array<MaterialMap>, ?params:Array<Float>)
var shader(default, set):Shader
var maps:Array<MaterialMap>
var params:Array<Float>
var unlit:Bool
```

- `new`: Creates a material. See `Raylib.LoadMaterialDefault` for making raylib's default material, and `extras.Models.LoadModelAsync` for loading a model's materials.
  - `shader`: The shader.
  - `maps`: The maps.
  - `params`: The values.
- `shader`: Gets or sets the material's shader.
  Assigning keeps a copy of the record, counted as one of the shader's holders, and lets go of the shader it replaces.

  A freed material lets go of its shader. The default shader is never freed.
- `maps`: Gets the maps, `MAX_MATERIAL_MAPS` of them, by `MATERIAL_MAP_*`.
- `params`: Gets four values for a shader's own use.
- `unlit`: Gets or sets a value indicating whether the material is unlit (a glTF's `KHR_materials_unlit`), showing its base color lit by nothing.
  `LoadModel` sets it from the file.

  `LoadPbrShader` draws an unlit material through its unlit twin. raylib's own shaders ignore it.

## MaterialMap

*class* in [`engines/raylib/src/helix/raylib/MaterialMap.hx`](../src/helix/raylib/MaterialMap.hx), `import helix.raylib.MaterialMap;`

Represents raylib's `MaterialMap`: one of a material's maps (`MATERIAL_MAP_*`), a texture with a color and a value.

Holds a count on its texture. Assigning a texture keeps a copy of its record, retains it and releases the texture it replaces.

A texture the program unloads after giving it to a map lives until the map lets go of it.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?texture:Texture2D, ?color:Color, ?value:Float}
```

```haxe
var texture(default, set):Texture2D
var color:Color
var value:Float
```

- `texture`: Gets or sets the texture, id 0 for none, which draws as white.
  Assigning keeps a copy of the record, counted as one of the texture's holders, and releases the texture it replaces.

  A freed material releases its maps' textures.
- `color`: Gets or sets the color.
- `value`: Gets or sets the value.

## Matrix

*class* in [`engines/raylib/src/helix/raylib/Matrix.hx`](../src/helix/raylib/Matrix.hx), `import helix.raylib.Matrix;`

Represents raylib's `Matrix`: 4 by 4, named by rows and stored by columns, as raylib's is.

`m0, m4, m8, m12` is the first row.

`m0` to `m3` is the first column, stored first and sent to shaders first.

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

*class* in [`engines/raylib/src/helix/raylib/Mesh.hx`](../src/helix/raylib/Mesh.hx), `import helix.raylib.Mesh;`

Represents raylib's `Mesh`: vertices, and its triangles' indices when it has them.

`Raylib.UploadMesh` sends a mesh to the GPU. `extras.Models.LoadModelAsync` and the `GenMesh*` functions upload theirs themselves.

Counted. The program holds a mesh from `new` or a `GenMesh*` function until `UnloadMesh`, and so does each model whose `meshes` has the mesh.

When the last holder lets go, the mesh's GPU buffers are freed.

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
- `tangents`: Gets or sets the tangents, x, y, z and w a vertex, or null for none.
  w is 1 or -1, the way the bitangent turns.

  `GenMeshTangents` makes them.
- `colors`: Gets or sets the colors, r, g, b and a a vertex, 0 to 255, or null for white.
- `indices`: Gets or sets the indices, three a triangle, or null for vertices taken three at a time.
- `animVertices`: Gets or sets the vertices' positions after `UpdateModelAnimation` last moved them, x, y and z a vertex, or null until it has.
  Worked out on the CPU when first read after a call that moved them, from the pose that call left, as raylib's `UpdateModelAnimation` moves them.

  A draw reads them only for a mesh drawn through the CPU path (see `UpdateModelAnimation`), or in wire or point mode.
- `animNormals`: Gets or sets the vertices' normals after `UpdateModelAnimation` last turned them, or null until it has or for a mesh without normals.
  Each is moved by its bones' matrices inverted and transposed, and not normalized, as raylib's are.

  Worked out on the CPU when first read, as `animVertices` are.
- `boneIds`: Gets or sets the bones each vertex follows, four a vertex, as indices into its model's `bones` (0 to 255), or null for none.
  A shader reads them as floats, in the attribute `vertexBoneIds` (raylib 5.5's name) or `vertexBoneIndices` (6.2's).
- `boneWeights`: Gets or sets how much each of a vertex's four bones moves it, or null for none.
  A shader reads them in the attribute `vertexBoneWeights`.
- `boneMatrices`: Gets or sets the bones' matrices, by bone, each taking a vertex from where the skin was bound to where the bone is now, or null for a mesh without bones.
  `UpdateModelAnimationBones` sets them. Shared by a model's meshes.

  A draw gives them to a shader declaring `uniform mat4 boneMatrices[N]`.

  A shader including `<helix/raylib/shaders/skinning.glsl>` reads the pose the model received at its last `UpdateModelAnimation` or `UpdateModelAnimationBones`, not this array. Giving one model's array to another model's meshes poses nothing, so each model needs its own call.
- `boneCount`: Gets or sets the number of bones, the model's.

## Model

*class* in [`engines/raylib/src/helix/raylib/Model.hx`](../src/helix/raylib/Model.hx), `import helix.raylib.Model;`

Represents raylib's `Model`: meshes, materials, each mesh's material, and a transform.

Holds a count on each of its meshes and materials. Putting one in `meshes` or `materials` retains it. Replacing it or `UnloadModel` releases it.

A mesh or material nothing holds is freed.

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

- `new`: Creates a model holding the meshes and materials. See `extras.Models.LoadModelAsync` for loading a model, and `Raylib.LoadModelFromMesh` for making one of a mesh.
  - `meshes`: The meshes.
  - `materials`: The materials.
  - `meshMaterial`: Each mesh's material.
- `transform`: Gets or sets the transform applied before `DrawModel`'s position, rotation and scale.
- `meshCount`: Gets the number of meshes, set when `meshes` is.
- `materialCount`: Gets the number of materials, set when `materials` is.
- `meshes`: Gets or sets the meshes, each held by the model.
  Setting copies the array, retains its meshes, releases the ones it replaces and sets `meshCount`.
- `materials`: Gets or sets the materials, each held by the model.
  Setting copies the array, retains its materials, releases the ones it replaces and sets `materialCount`.
- `meshMaterial`: Gets the material of each mesh, by its index in `materials`.
- `boneCount`: Gets the number of bones, the joints of the file's first skin, or 0 for a model without one.
- `bones`: Gets the bones, or null without a skin.
  The file's first skin's joints, in its order, each parent the nearest joint above it.
- `bindPose`: Gets each bone's transform in the model as the skin was bound to it, or null without a skin.
  Each is its inverse bind matrix inverted, or its node's at rest for a file that gives none.

## ModelAnimation

*class* in [`engines/raylib/src/helix/raylib/ModelAnimation.hx`](../src/helix/raylib/ModelAnimation.hx), `import helix.raylib.ModelAnimation;`

Represents raylib's `ModelAnimation`: a skeleton's poses, frame by frame.

`extras.Models.LoadModelAnimationsAsync` makes them at 60 frames a second.

`Raylib.UpdateModelAnimation` poses a model by one.

```haxe
function new()
var boneCount:Int
var frameCount:Int
var bones:Null<Array<BoneInfo>>
var framePoses:Null<Array<Array<Transform>>>
var name:String
```

- `new`: Creates an animation of no frames.
- `boneCount`: Gets or sets the number of bones. A model the animation moves has the same number (`Raylib.IsModelAnimationValid`).
- `frameCount`: Gets or sets the number of frames.
- `bones`: Gets or sets the bones, as the model's are.
- `framePoses`: Gets or sets each frame's pose: for each bone, its transform in the model, not relative to its parent (the parent's is already in it).
- `name`: Gets or sets the name, the file's cut to 31 bytes as raylib's holds it, or empty.

## ModelMaterials

*abstract* in [`engines/raylib/src/helix/raylib/ModelMaterials.hx`](../src/helix/raylib/ModelMaterials.hx), `import helix.raylib.ModelMaterials;`

Represents a model's materials, raylib's `model.materials`: read and written by index (`model.materials[0] = material`), iterated, and with a `length`.

The model holds a count on each material here. Writing one retains the new material and releases the one it replaces. `UnloadModel` releases them all.

An array assigned to `Model.materials` is copied, so changing the array afterwards changes nothing here.

## ModelMeshes

*abstract* in [`engines/raylib/src/helix/raylib/ModelMeshes.hx`](../src/helix/raylib/ModelMeshes.hx), `import helix.raylib.ModelMeshes;`

Represents a model's meshes, raylib's `model.meshes`: read and written by index (`model.meshes[0] = mesh`), iterated, and with a `length`.

The model holds a count on each mesh here. Writing one retains the new mesh and releases the one it replaces. `UnloadModel` releases them all.

An array assigned to `Model.meshes` is copied, so changing the array afterwards changes nothing here.

## Music

*class* in [`engines/raylib/src/helix/raylib/Music.hx`](../src/helix/raylib/Music.hx), `import helix.raylib.Music;`

Represents raylib's `Music`: a sound played as it is read, never held whole, through helix-services' `Audio.stream`.

```haxe
var looping:Bool
var frameCount(get, never):Int
```

- `looping`: Gets or sets a value indicating whether the music starts again from its beginning when it ends. Defaults to true, as raylib's.
- `frameCount`: Gets the number of frames, at 44100 a second, or 0 until the length is known (`GetMusicTimeLength`).

## NPatchInfo

*class* in [`engines/raylib/src/helix/raylib/NPatchInfo.hx`](../src/helix/raylib/NPatchInfo.hx), `import helix.raylib.NPatchInfo;`

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

*typedef* in [`engines/raylib/src/helix/raylib/Quaternion.hx`](../src/helix/raylib/Quaternion.hx), `import helix.raylib.Quaternion;`

Represents raylib's `Quaternion`, the same type as `Vector4`.

An alias of `Vector4`.

## Ray

*class* in [`engines/raylib/src/helix/raylib/Ray.hx`](../src/helix/raylib/Ray.hx), `import helix.raylib.Ray;`

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

*class* in [`engines/raylib/src/helix/raylib/RayCollision.hx`](../src/helix/raylib/RayCollision.hx), `import helix.raylib.RayCollision;`

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

- `hit`: Gets or sets a value indicating whether the ray hit.
- `distance`: Gets or sets the distance to the hit.
- `point`: Gets or sets the point hit.
- `normal`: Gets or sets the surface's normal there.

## Raygui

*class* in [`engines/raylib/src/helix/raylib/Raygui.hx`](../src/helix/raylib/Raygui.hx), `import helix.raylib.Raygui;`

Provides raygui's API, raylib's immediate-mode GUI, as raylib 5.5's `raygui.h` (raygui 4.5-dev) names it: its controls (`GuiButton`, `GuiSlider`, `GuiTextBox`, `GuiListView`, `GuiColorPicker` and the rest), drawn and read each frame between `BeginDrawing` and `EndDrawing`, its style (`GuiSetStyle`, `GuiGetStyle`, `GuiLoadStyleDefault`), font, state, alpha, tooltips and icons. As in raylib, where raygui is a header of its own, it is apart from `Raylib`, so a program that uses it imports it too:

```haxe
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
```

A value a control changes is passed in a one-element array, as raygui takes a pointer: `GuiCheckBox(bounds, "On", checked)` with `var checked = [false];`, `GuiSlider(bounds, null, null, value, 0, 100)` with `var value = [50.];`, `GuiTextBox(bounds, text, 64, editing)` with `var text = ["name"];`. A struct a control changes (`Color`, `Vector2`, `Rectangle`, `Vector3`) is changed in place. A style file loads with `GuiLoadStyleAsync` and an icon file with `GuiLoadIconsAsync`, in `helix.raylib.extras.Gui`.

Its members are on their own page: [raygui.md](raygui.md).

### Not supported in helix-raylib

Each of these is raylib's name (or emscripten's, which raylib's web programs call), and a call to it doesn't compile, saying why and what to use instead.

`GuiLoadStyle`, `GuiLoadIcons`.

## Raylib

*class* in [`engines/raylib/src/helix/raylib/Raylib.hx`](../src/helix/raylib/Raylib.hx), `import helix.raylib.Raylib;`

Provides raylib 5.5's API, as `raylib.h` names it, over helix-platform and helix-services: a program writes raylib, and it runs in a page and natively.

A program's loop is raylib's, `while (!WindowShouldClose()) { BeginDrawing(); ...; EndDrawing(); }`: any `while` or `do`-`while` in the main class that calls `WindowShouldClose()`, in its condition or its body, a statement of a function's own block. In a page its body runs once a frame; one elsewhere doesn't compile. A page can't wait for a file, so on every target files are loaded by helix-raylib's own `...Async` loads, in the package `helix.raylib.extras` with the rest of what helix-raylib adds, a module for each of raylib's (`import helix.raylib.extras.Textures.*;`); raylib's `LoadTexture`, `LoadImage`, `LoadModel`, `LoadSound`, `LoadWave`, `LoadFileData` and `LoadFileText` don't compile, naming the load to use. A file loaded twice is shared, and goes to the GPU when first drawn. `SaveFileTextAsync` writes are kept across runs. Shaders are raylib's GLSL, compiled as the program builds, so `LoadShader` names its files with constants. raymath's functions are `Raymath`'s, imported apart as raylib includes `raymath.h`. Its functions are written in files by raylib's modules (`helix.raylib.modules`) and listed here by module; what raylib has and helix-raylib doesn't refuses to compile, naming itself.

Its members are on their own pages:

- [constants.md](constants.md): Raylib's constants
- [core.md](core.md): rcore: the window and frame, input, files, cameras and shaders
- [shapes.md](shapes.md): rshapes: 2D shapes and collisions
- [textures.md](textures.md): rtextures: textures, render textures and colors
- [text.md](text.md): rtext: text
- [models.md](models.md): rmodels: 3D shapes, models, meshes and rays
- [audio.md](audio.md): raudio: sound

### Not supported in helix-raylib

Each of these is raylib's name (or emscripten's, which raylib's web programs call), and a call to it doesn't compile, saying why and what to use instead.

`SetWindowSize`, `MaximizeWindow`, `MinimizeWindow`, `RestoreWindow`, `SetWindowFocused`, `SetWindowOpacity`, `SetWindowMinSize`, `SetWindowMaxSize`, `SetClipboardText`, `GetClipboardText`, `GetClipboardImage`, `GetWindowHandle`, `GetMonitorPhysicalWidth`, `GetMonitorPhysicalHeight`, `ToggleFullscreen`, `ToggleBorderlessWindowed`, `SetWindowPosition`, `SetWindowMonitor`, `EnableCursor`, `DisableCursor`, `FileExists`, `LoadFileText`, `SaveFileText`, `LoadFileData`, `SaveFileData`, `ExportDataAsCode`, `DirectoryExists`, `GetFileLength`, `IsPathFile`, `LoadDirectoryFiles`, `LoadDirectoryFilesEx`, `GetFileModTime`, `ExportAutomationEventList`, `MemAlloc`, `MemRealloc`, `MemFree`, `TakeScreenshot`, `emscripten_set_main_loop`, `emscripten_set_main_loop_arg`, `emscripten_cancel_main_loop`, `emscripten_run_script`, `emscripten_run_script_int`, `emscripten_run_script_string`, `emscripten_get_now`, `emscripten_sleep`, `LoadShader`, `LoadShaderFromMemory`, `LoadTexture`, `LoadImage`, `LoadImageRaw`, `LoadImageFromMemory`, `LoadImageAnim`, `LoadImageAnimFromMemory`, `LoadImageFromTexture`, `LoadImageFromScreen`, `ExportImage`, `ExportImageAsCode`, `ExportFontAsCode`, `LoadFont`, `LoadFontEx`, `LoadFontFromMemory`, `LoadFontData`, `TextCopy`, `TextAppend`, `LoadModel`, `LoadMaterials`, `ExportMesh`, `ExportMeshAsCode`, `LoadModelAnimations`, `LoadWave`, `LoadWaveFromMemory`, `ExportWave`, `ExportWaveAsCode`, `LoadSound`, `LoadMusicStream`, `AttachAudioStreamProcessor`, `DetachAudioStreamProcessor`, `AttachAudioMixedProcessor`, `DetachAudioMixedProcessor`.

## Raymath

*class* in [`engines/raylib/src/helix/raylib/Raymath.hx`](../src/helix/raylib/Raymath.hx), `import helix.raylib.Raymath;`

Provides raymath's API, as raylib 5.5's `raymath.h` names it: vectors, matrices and quaternions, and `Clamp`, `Lerp` and the like. As in raylib, it is apart from `Raylib`, so a program that uses it imports it too:

```haxe
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
```

What raymath has and helix-raylib doesn't refuses to compile, naming itself.

Its members are on their own page: [raymath.md](raymath.md).

## Rectangle

*class* in [`engines/raylib/src/helix/raylib/Rectangle.hx`](../src/helix/raylib/Rectangle.hx), `import helix.raylib.Rectangle;`

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

*class* in [`engines/raylib/src/helix/raylib/RenderTexture.hx`](../src/helix/raylib/RenderTexture.hx), `import helix.raylib.RenderTexture;`

Represents raylib's `RenderTexture`, also its `RenderTexture2D`: a texture drawn into between `BeginTextureMode` and `EndTextureMode`.

The texture is upside down, as in raylib. Drawing it with a negative source height shows it the right way up.

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
- `texture`: Gets the color the render texture holds.
- `depth`: Gets the depth the render texture is drawn with, which can't be sampled, so its id is 0.

## RenderTexture2D

*typedef* in [`engines/raylib/src/helix/raylib/RenderTexture2D.hx`](../src/helix/raylib/RenderTexture2D.hx), `import helix.raylib.RenderTexture2D;`

Represents raylib's `RenderTexture2D`, the same type as `RenderTexture`.

An alias of `RenderTexture`.

## Rlgl

*class* in [`engines/raylib/src/helix/raylib/Rlgl.hx`](../src/helix/raylib/Rlgl.hx), `import helix.raylib.Rlgl;`

Provides rlgl's API, as raylib 5.5's `rlgl.h` names it: the matrix stack, immediate drawing (`rlBegin`, `rlVertex3f`, `rlEnd`) and render state. As in raylib, it is apart from `Raylib`, so a program that uses it imports it too:

```haxe
import helix.raylib.Raylib.*;
import helix.raylib.Rlgl.*;
```

rlgl's GPU objects (vertex arrays and buffers, framebuffers, GL ids) aren't here: helix-raylib draws through helix-platform, which has no GL. What rlgl has and helix-raylib doesn't refuses to compile, naming itself.

Its members are on their own page: [rlgl.md](rlgl.md).

### Not supported in helix-raylib

Each of these is raylib's name (or emscripten's, which raylib's web programs call), and a call to it doesn't compile, saying why and what to use instead.

`rlEnableVertexArray`, `rlDisableVertexArray`, `rlEnableVertexBuffer`, `rlDisableVertexBuffer`, `rlEnableVertexBufferElement`, `rlDisableVertexBufferElement`, `rlEnableVertexAttribute`, `rlDisableVertexAttribute`, `rlEnableStatePointer`, `rlDisableStatePointer`, `rlActiveTextureSlot`, `rlEnableTexture`, `rlDisableTexture`, `rlEnableTextureCubemap`, `rlDisableTextureCubemap`, `rlTextureParameters`, `rlCubemapParameters`, `rlEnableShader`, `rlDisableShader`, `rlEnableFramebuffer`, `rlDisableFramebuffer`, `rlGetActiveFramebuffer`, `rlActiveDrawBuffers`, `rlBlitFramebuffer`, `rlBindFramebuffer`, `rlCheckErrors`, `rlglInit`, `rlglClose`, `rlLoadExtensions`, `rlGetVersion`, `rlGetTextureIdDefault`, `rlGetShaderIdDefault`, `rlGetShaderLocsDefault`, `rlLoadRenderBatch`, `rlUnloadRenderBatch`, `rlDrawRenderBatch`, `rlSetRenderBatchActive`, `rlLoadVertexArray`, `rlLoadVertexBuffer`, `rlLoadVertexBufferElement`, `rlUpdateVertexBuffer`, `rlUpdateVertexBufferElements`, `rlUnloadVertexArray`, `rlUnloadVertexBuffer`, `rlSetVertexAttribute`, `rlSetVertexAttributeDivisor`, `rlSetVertexAttributeDefault`, `rlDrawVertexArray`, `rlDrawVertexArrayElements`, `rlDrawVertexArrayInstanced`, `rlDrawVertexArrayElementsInstanced`, `rlLoadTexture`, `rlLoadTextureDepth`, `rlLoadTextureCubemap`, `rlUpdateTexture`, `rlGetGlTextureFormats`, `rlUnloadTexture`, `rlGenTextureMipmaps`, `rlReadTexturePixels`, `rlReadScreenPixels`, `rlLoadFramebuffer`, `rlFramebufferAttach`, `rlFramebufferComplete`, `rlUnloadFramebuffer`, `rlLoadShaderCode`, `rlCompileShader`, `rlLoadShaderProgram`, `rlUnloadShaderProgram`, `rlGetLocationUniform`, `rlGetLocationAttrib`, `rlSetUniform`, `rlSetUniformMatrix`, `rlSetUniformMatrices`, `rlSetUniformSampler`, `rlSetShader`, `rlLoadComputeShaderProgram`, `rlComputeShaderDispatch`, `rlLoadShaderBuffer`, `rlUnloadShaderBuffer`, `rlUpdateShaderBuffer`, `rlBindShaderBuffer`, `rlReadShaderBuffer`, `rlCopyShaderBuffer`, `rlGetShaderBufferSize`, `rlBindImageTexture`, `rlLoadDrawCube`, `rlLoadDrawQuad`.

## Shader

*class* in [`engines/raylib/src/helix/raylib/Shader.hx`](../src/helix/raylib/Shader.hx), `import helix.raylib.Shader;`

Represents raylib's `Shader`: a program and the locations of what it declares.

Made by `LoadCompiledShaderAsync` or `LoadCompiledShaderFromData` (`helix.raylib.extras.Shaders`), or by helix-raylib's own, such as `LoadPbrShader`.

```haxe
var id(default, null):Int
var locs(default, null):Array<Int>
```

- `id`: Gets the program's handle, 0 for none.
- `locs`: Gets the locations of the values raylib sets itself, by `SHADER_LOC_*`, -1 for each the shader doesn't declare.
  A program may set them, as raylib's programs do. Values are found by name here, so setting them changes nothing.

## Sound

*class* in [`engines/raylib/src/helix/raylib/Sound.hx`](../src/helix/raylib/Sound.hx), `import helix.raylib.Sound;`

Represents raylib's `Sound`: a sound held whole, played by `Raylib.PlaySound`, over helix-services' `Audio`.

```haxe
var frameCount(default, null):Int
```

- `frameCount`: Gets the number of frames, at 44100 a second, or 0 until the sound is loaded.

## Texture

*typedef* in [`engines/raylib/src/helix/raylib/Texture.hx`](../src/helix/raylib/Texture.hx), `import helix.raylib.Texture;`

Represents raylib's `Texture`, the same type as `Texture2D`.

An alias of `Texture2D`.

## Texture2D

*class* in [`engines/raylib/src/helix/raylib/Texture2D.hx`](../src/helix/raylib/Texture2D.hx), `import helix.raylib.Texture2D;`

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
- `format`: Gets the pixel format: the image's for a texture made of one (`LoadTextureFromImage`), or `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8` for the rest.
  A glTF model's roughness and metalness maps are `PIXELFORMAT_UNCOMPRESSED_GRAYSCALE`.

  The pixels are RGBA on the GPU whatever the format.

## TextureCubemap

*typedef* in [`engines/raylib/src/helix/raylib/TextureCubemap.hx`](../src/helix/raylib/TextureCubemap.hx), `import helix.raylib.TextureCubemap;`

Represents raylib's `TextureCubemap`, the same type as `Texture`: a cubemap's record.

Made by `Raylib.LoadTextureCubemap`.

An alias of `Texture`.

## Transform

*class* in [`engines/raylib/src/helix/raylib/Transform.hx`](../src/helix/raylib/Transform.hx), `import helix.raylib.Transform;`

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

*class* in [`engines/raylib/src/helix/raylib/Vector2.hx`](../src/helix/raylib/Vector2.hx), `import helix.raylib.Vector2;`

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

*class* in [`engines/raylib/src/helix/raylib/Vector3.hx`](../src/helix/raylib/Vector3.hx), `import helix.raylib.Vector3;`

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

*class* in [`engines/raylib/src/helix/raylib/Vector4.hx`](../src/helix/raylib/Vector4.hx), `import helix.raylib.Vector4;`

Represents raylib's `Vector4`, also its `Quaternion`: four components.

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

*class* in [`engines/raylib/src/helix/raylib/VrDeviceInfo.hx`](../src/helix/raylib/VrDeviceInfo.hx), `import helix.raylib.VrDeviceInfo;`

Represents raylib's `VrDeviceInfo`: a head-mounted display's parameters.

`LoadVrStereoConfig` makes a stereo config from them.

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

*class* in [`engines/raylib/src/helix/raylib/VrStereoConfig.hx`](../src/helix/raylib/VrStereoConfig.hx), `import helix.raylib.VrStereoConfig;`

Represents raylib's `VrStereoConfig`: each eye's projection and view offset for `BeginVrStereoMode`, and the values a distortion shader reads.

`LoadVrStereoConfig` computes them from a `VrDeviceInfo`.

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

- `projection`: Gets or sets each eye's projection, the first drawn in the left half.
- `viewOffset`: Gets or sets each eye's view offset, applied after the view.
- `leftLensCenter`: Gets or sets the left lens's center, x and y, 0 to 1 across the render target.
- `rightLensCenter`: Gets or sets the right lens's center.
- `leftScreenCenter`: Gets or sets the left screen half's center.
- `rightScreenCenter`: Gets or sets the right screen half's center.
- `scale`: Gets or sets the distortion's scale, x and y.
- `scaleIn`: Gets or sets the distortion's input scale, x and y.

## Wave

*class* in [`engines/raylib/src/helix/raylib/Wave.hx`](../src/helix/raylib/Wave.hx), `import helix.raylib.Wave;`

Represents raylib's `Wave`: sound samples in memory, as `LoadWaveAsync` reads them and `LoadSoundFromWave` plays them.

The samples are interleaved, a frame a sample for each channel, left first.

A sample is 8-bit unsigned, 16-bit signed or 32-bit float, little-endian.

The `Wave*` functions change a wave in place, as raylib's do through its pointer, replacing its fields.

```haxe
function new(?frameCount:Int = 0, ?sampleRate:Int = 0, ?sampleSize:Int = 0, ?channels:Int = 0, ?data:haxe.io.Bytes)
var frameCount:Int
var sampleRate:Int
var sampleSize:Int
var channels:Int
var data:Null<haxe.io.Bytes>
```

- `new`: Creates a wave's record, its fields zero and its data null unless provided, as raylib's `Wave wave = { 0 }` is.
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

- `helix-raylib-native-root=<directory>`: Where a native program finds its files, relative to its own directory. Defaults to ../web.
- `helix-raylib-host-warnings`: Warns where the program's own code reaches the page or the host (the URL's query, Sys.getEnv, matchMedia, maxTouchPoints, screen.orientation, the safe area's insets, deviceorientation, localStorage, the page's fullscreen) for what helix.raylib.extras or Raylib answers on every target, naming the call. Off by default.
- `helix-raylib-custom-frame-control`: raylib's SUPPORT_CUSTOM_FRAME_CONTROL: EndDrawing only draws, and the program calls SwapScreenBuffer, WaitTime and PollInputEvents itself.
