# helix.ray

[Back to the index](README.md)

## AudioStream

*class* in [`ray/src/helix/ray/AudioStream.hx`](../../ray/src/helix/ray/AudioStream.hx), `import helix.ray.AudioStream;`

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

*class* in [`ray/src/helix/ray/AutomationEvent.hx`](../../ray/src/helix/ray/AutomationEvent.hx), `import helix.ray.AutomationEvent;`

raylib's `AutomationEvent` (raylib.h): not in helix-ray yet; its fields are raylib's. Automation event.

```haxe
function new()
var frame:Int
var type:Int
var params:Array<Int>
```

- `new`: Creates one, its fields zero, empty or null.
- `frame`: Event frame.
- `type`: Event type (AutomationEventType).
- `params`: Event parameters (if required).

## AutomationEventList

*class* in [`ray/src/helix/ray/AutomationEventList.hx`](../../ray/src/helix/ray/AutomationEventList.hx), `import helix.ray.AutomationEventList;`

raylib's `AutomationEventList` (raylib.h): not in helix-ray yet; its fields are raylib's. Automation event list.

```haxe
function new()
var capacity:Int
var count:Int
var events:Array<AutomationEvent>
```

- `new`: Creates one, its fields zero, empty or null.
- `capacity`: Events max entries (MAX_AUTOMATION_EVENTS).
- `count`: Events entries count.
- `events`: Events entries.

## BoneInfo

*class* in [`ray/src/helix/ray/BoneInfo.hx`](../../ray/src/helix/ray/BoneInfo.hx), `import helix.ray.BoneInfo;`

raylib's `BoneInfo` (raylib.h): not in helix-ray yet; its fields are raylib's. Bone, skeletal animation bone.

```haxe
function new()
var name:String
var parent:Int
```

- `new`: Creates one, its fields zero, empty or null.
- `name`: Bone name.
- `parent`: Bone parent.

## BoundingBox

*class* in [`ray/src/helix/ray/BoundingBox.hx`](../../ray/src/helix/ray/BoundingBox.hx), `import helix.ray.BoundingBox;`

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

*typedef* in [`ray/src/helix/ray/Camera.hx`](../../ray/src/helix/ray/Camera.hx), `import helix.ray.Camera;`

raylib's `Camera`, the same as `Camera3D`.

An alias of `Camera3D`.

## Camera2D

*class* in [`ray/src/helix/ray/Camera2D.hx`](../../ray/src/helix/ray/Camera2D.hx), `import helix.ray.Camera2D;`

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

*class* in [`ray/src/helix/ray/Camera3D.hx`](../../ray/src/helix/ray/Camera3D.hx), `import helix.ray.Camera3D;`

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

*class* in [`ray/src/helix/ray/Color.hx`](../../ray/src/helix/ray/Color.hx), `import helix.ray.Color;`

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

*class* in [`ray/src/helix/ray/FilePathList.hx`](../../ray/src/helix/ray/FilePathList.hx), `import helix.ray.FilePathList;`

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

*class* in [`ray/src/helix/ray/Font.hx`](../../ray/src/helix/ray/Font.hx), `import helix.ray.Font;`

raylib's `Font` (raylib.h): not in helix-ray yet; its fields are raylib's. Font, font texture and GlyphInfo array data.

```haxe
function new()
var baseSize:Int
var glyphCount:Int
var glyphPadding:Int
var texture:Texture2D
var recs:Array<Rectangle>
var glyphs:Array<GlyphInfo>
```

- `new`: Creates one, its fields zero, empty or null.
- `baseSize`: Base size (default chars height).
- `glyphCount`: Number of glyph characters.
- `glyphPadding`: Padding around the glyph characters.
- `texture`: Texture atlas containing the glyphs.
- `recs`: Rectangles in texture for the glyphs.
- `glyphs`: Glyphs info data.

## GlyphInfo

*class* in [`ray/src/helix/ray/GlyphInfo.hx`](../../ray/src/helix/ray/GlyphInfo.hx), `import helix.ray.GlyphInfo;`

raylib's `GlyphInfo` (raylib.h): not in helix-ray yet; its fields are raylib's. GlyphInfo, font characters glyphs info.

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

## Image

*class* in [`ray/src/helix/ray/Image.hx`](../../ray/src/helix/ray/Image.hx), `import helix.ray.Image;`

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

## Material

*class* in [`ray/src/helix/ray/Material.hx`](../../ray/src/helix/ray/Material.hx), `import helix.ray.Material;`

Represents raylib's `Material`: a shader and its maps (`MATERIAL_MAP_*`); the diffuse map's texture and color are what a draw shows.

```haxe
function new(shader:Shader, maps:Array<MaterialMap>, ?params:Array<Float>)
var shader:Shader
var maps:Array<MaterialMap>
var params:Array<Float>
```

- `new`: Creates a material. Materials are made by `Raylib.LoadMaterialDefault` and `Raylib.LoadModelAsync`.
  - `shader`: The shader.
  - `maps`: The maps.
  - `params`: The values.
- `shader`: Gets or sets the shader it draws with.
- `maps`: Gets its maps, `MAX_MATERIAL_MAPS` of them, by `MATERIAL_MAP_*`.
- `params`: Gets four values for a shader's own use.

## MaterialMap

*class* in [`ray/src/helix/ray/MaterialMap.hx`](../../ray/src/helix/ray/MaterialMap.hx), `import helix.ray.MaterialMap;`

Represents raylib's `MaterialMap`: one of a material's maps (`MATERIAL_MAP_*`), a texture with a color and a value.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?texture:Texture2D, ?color:Color, ?value:Float}
```

```haxe
var texture:Texture2D
var color:Color
var value:Float
```

- `texture`: Gets or sets the texture; id 0 for none, drawn as white.
- `color`: Gets or sets the color.
- `value`: Gets or sets the value.

## Matrix

*class* in [`ray/src/helix/ray/Matrix.hx`](../../ray/src/helix/ray/Matrix.hx), `import helix.ray.Matrix;`

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

*class* in [`ray/src/helix/ray/Mesh.hx`](../../ray/src/helix/ray/Mesh.hx), `import helix.ray.Mesh;`

Represents raylib's `Mesh`: vertices, and the indices of its triangles when it has them. `Raylib.UploadMesh` sends them to the GPU; `Raylib.LoadModelAsync` and the `GenMesh*` functions do it themselves.

```haxe
function new()
var vertexCount:Int
var triangleCount:Int
var vertices:Null<Array<Float>>
var texcoords:Null<Array<Float>>
var normals:Null<Array<Float>>
var colors:Null<Array<Int>>
var indices:Null<Array<Int>>
```

- `new`: Creates an empty mesh.
- `vertexCount`: Gets or sets the number of vertices.
- `triangleCount`: Gets or sets the number of triangles.
- `vertices`: Gets or sets the positions, x, y and z a vertex.
- `texcoords`: Gets or sets the texture coordinates, u and v a vertex, or null for none.
- `normals`: Gets or sets the normals, x, y and z a vertex, or null for none.
- `colors`: Gets or sets the colors, r, g, b and a a vertex, 0 to 255, or null for white.
- `indices`: Gets or sets the indices, three a triangle, or null for vertices taken three at a time.

## Model

*class* in [`ray/src/helix/ray/Model.hx`](../../ray/src/helix/ray/Model.hx), `import helix.ray.Model;`

Represents raylib's `Model`: meshes, materials, which material each mesh draws with, and a transform.

```haxe
function new(meshes:Array<Mesh>, materials:Array<Material>, meshMaterial:Array<Int>)
var transform:Matrix
var meshCount:Int
var materialCount:Int
var meshes:Array<Mesh>
var materials:Array<Material>
var meshMaterial:Array<Int>
```

- `new`: Creates a model. Models are made by `Raylib.LoadModelAsync` and `Raylib.LoadModelFromMesh`.
  - `meshes`: The meshes.
  - `materials`: The materials.
  - `meshMaterial`: Each mesh's material.
- `transform`: Gets or sets the transform applied before `DrawModel`'s position, rotation and scale.
- `meshCount`: Gets the number of meshes.
- `materialCount`: Gets the number of materials.
- `meshes`: Gets the meshes.
- `materials`: Gets the materials.
- `meshMaterial`: Gets the material of each mesh, by its index in `materials`.

## ModelAnimation

*class* in [`ray/src/helix/ray/ModelAnimation.hx`](../../ray/src/helix/ray/ModelAnimation.hx), `import helix.ray.ModelAnimation;`

raylib's `ModelAnimation` (raylib.h): not in helix-ray yet; its fields are raylib's. ModelAnimation.

```haxe
function new()
var boneCount:Int
var frameCount:Int
var bones:Array<BoneInfo>
var framePoses:Array<Array<Transform>>
var name:String
```

- `new`: Creates one, its fields zero, empty or null.
- `boneCount`: Number of bones.
- `frameCount`: Number of animation frames.
- `bones`: Bones information (skeleton).
- `framePoses`: Poses array by frame.
- `name`: Animation name.

## Music

*class* in [`ray/src/helix/ray/Music.hx`](../../ray/src/helix/ray/Music.hx), `import helix.ray.Music;`

Represents raylib's `Music`: a sound played as it is read, never held whole, through helix-services' `Audio.stream`.

```haxe
var looping:Bool
var frameCount(get, never):Int
```

- `looping`: Gets or sets whether it starts again from its beginning when it ends; true until set, as raylib's.
- `frameCount`: Gets the number of frames, at 44100 a second; 0 until its length is known (`GetMusicTimeLength`).

## NPatchInfo

*class* in [`ray/src/helix/ray/NPatchInfo.hx`](../../ray/src/helix/ray/NPatchInfo.hx), `import helix.ray.NPatchInfo;`

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

*typedef* in [`ray/src/helix/ray/Quaternion.hx`](../../ray/src/helix/ray/Quaternion.hx), `import helix.ray.Quaternion;`

raylib's `Quaternion`, the same as `Vector4`.

An alias of `Vector4`.

## Ray

*class* in [`ray/src/helix/ray/Ray.hx`](../../ray/src/helix/ray/Ray.hx), `import helix.ray.Ray;`

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

*class* in [`ray/src/helix/ray/RayCollision.hx`](../../ray/src/helix/ray/RayCollision.hx), `import helix.ray.RayCollision;`

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

## Raylib

*class* in [`ray/src/helix/ray/Raylib.hx`](../../ray/src/helix/ray/Raylib.hx), `import helix.ray.Raylib;`

Provides raylib 5.5's API, as `raylib.h` names it, over helix-platform and helix-services: a program writes raylib, and it runs in a page and natively.

A program's loop is raylib's, `while (!WindowShouldClose()) { BeginDrawing(); ...; EndDrawing(); }`; in a page its body runs once a frame. A page can't wait for a file, so on every target files are loaded by helix-ray's own `...Async` loads; raylib's `LoadTexture`, `LoadImage`, `LoadModel`, `LoadSound`, `LoadWave`, `LoadFileData` and `LoadFileText` don't compile, naming the load to use. A file loaded twice is shared, and goes to the GPU when first drawn. `SaveFileText` writes are kept across runs. Shaders are raylib's GLSL, compiled as the program builds, so `LoadShader` names its files with constants. raymath's functions are `Raymath`'s, imported apart as raylib includes `raymath.h`. Its functions are written in files by raylib's modules (`helix.ray.raylib`) and listed here by module; what raylib has and helix-ray doesn't refuses to compile, naming itself.

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
static function SetWindowSize(width:Int, height:Int):Void
static function IsWindowFullscreen():Bool
static function IsWindowHidden():Bool
static function IsWindowMinimized():Bool
static function IsWindowMaximized():Bool
static function MaximizeWindow():Void
static function MinimizeWindow():Void
static function RestoreWindow():Void
static function SetWindowFocused():Void
static function SetWindowIcon(image:Image):Void
static function SetWindowIcons(images:Array<Image>, count:Int):Void
static function SetWindowOpacity(opacity:Float):Void
static function SetWindowMinSize(width:Int, height:Int):Void
static function SetWindowMaxSize(width:Int, height:Int):Void
static function GetMonitorRefreshRate(monitor:Int):Int
static function OpenURL(url:String):Void
static function SetClipboardText(text:String):Void
static function IsWindowFocused():Bool
static function ToggleFullscreen():Void
static function ToggleBorderlessWindowed():Void
static function SetWindowPosition(x:Int, y:Int):Void
static function SetWindowMonitor(monitor:Int):Void
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
static function ClearBackground(color:Color):Void
static function GetRandomValue(min:Int, max:Int):Int
static function SetRandomSeed(seed:Int):Void
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
static function EnableCursor():Void
static function DisableCursor():Void
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
static function SaveFileText(fileName:String, text:String):Bool
static function UnloadFileData(data:Null<haxe.io.Bytes>):Void
static function SaveFileData(fileName:String, data:haxe.io.Bytes, dataSize:Int):Bool
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
static function TakeScreenshot(fileName:String):Void
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
static function GetCameraMatrix(camera:Camera3D):Matrix
static function GetScreenToWorldRay(position:Vector2, camera:Camera3D):Ray
static function GetScreenToWorldRayEx(position:Vector2, camera:Camera3D, width:Int, height:Int):Ray
static function GetMouseRay(position:Vector2, camera:Camera3D):Ray
static function GetWorldToScreen(position:Vector3, camera:Camera3D):Vector2
static function GetWorldToScreenEx(position:Vector3, camera:Camera3D, width:Int, height:Int):Vector2
static function GetMouseDelta():Vector2
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
- `SetWindowSize`: Asks for the window's size. A page's canvas follows the page instead.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
- `IsWindowFullscreen`: Returns whether the window is fullscreen. In a page it tells whether the canvas is.
  - returns: True while it is.
- `IsWindowHidden`: Returns whether the program hid the window (`FLAG_WINDOW_HIDDEN`). In a page it tells whether the canvas is hidden.
  - returns: True while it is.
- `IsWindowMinimized`: Returns whether the player can't see the window: minimized, or in a page its tab in the background.
  - returns: True while it is.
- `IsWindowMaximized`: Returns whether the window is maximized. It is false in a page.
  - returns: True while it is.
- `MaximizeWindow`: Asks for the window maximized. A page's canvas is the page's size, so nothing changes there.
- `MinimizeWindow`: Asks for the window minimized. Nothing changes in a page.
- `RestoreWindow`: Asks for the window back to its size from maximized or minimized.
- `SetWindowFocused`: Asks for the window brought to the front with the keyboard. A window manager may only flash it; in a page the canvas takes the keyboard.
- `SetWindowIcon`: Sets the window's icon; in a page, the page's icon. As raylib's, the image must be `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `image`: The icon.
- `SetWindowIcons`: Sets the window's icon from several sizes: the largest is used, as the desktop scales it. Each must be `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `images`: The icons.
  - `count`: How many of them.
- `SetWindowOpacity`: Asks for the window see-through; in a page the canvas fades. A desktop without a compositor leaves it opaque.
  - `opacity`: From 0 (clear) to 1 (opaque).
- `SetWindowMinSize`: Sets the smallest size the player can make the window. A page's canvas is the page's size, so nothing changes there.
  - `width`: The width, in the screen's pixels.
  - `height`: The height.
- `SetWindowMaxSize`: Sets the largest size the player can make the window. Nothing changes in a page.
  - `width`: The width, in the screen's pixels.
  - `height`: The height.
- `GetMonitorRefreshRate`: Returns how many times a second a monitor shows a new picture.
  - `monitor`: The monitor.
  - returns: The refresh rate in hertz, or 0 in a page, which can't tell.
- `OpenURL`: Opens a URL in the system's browser; in a page, a new tab, at the next press when there is no fresh one. As raylib's, a URL with `'` is refused as possibly malicious; helix-ray also opens only http, https and mailto URLs.
  - `url`: The URL.
- `SetClipboardText`: Puts text on the system's clipboard. A page writes it only while it has the keyboard, soon after a press; a refusal is logged.
  - `text`: The text.
- `IsWindowFocused`: Returns whether the window has the keyboard.
  - returns: True while it has.
- `ToggleFullscreen`: Asks for fullscreen, or back to the window, the size and place it had. In a page the browser grants it only soon after a key press, click or tap; without one, it waits for the player's next.
- `ToggleBorderlessWindowed`: Asks for the window to fill the screen without borders, or back to the window: here the same as `ToggleFullscreen`, as a fullscreen window natively is borderless and the size of the desktop.
- `SetWindowPosition`: Asks for the window's place on the desktop. Where the window can't be moved (in a page, or under Wayland), nothing changes.
  - `x`: The left edge, in pixels.
  - `y`: The top edge, in pixels.
- `SetWindowMonitor`: Asks for the window on another monitor.
  - `monitor`: The monitor, 0 to `GetMonitorCount() - 1`.
- `GetWindowPosition`: Returns the window's place on the desktop.
  - returns: Its left and top edges, in pixels.
- `GetWindowScaleDPI`: Returns how many of the display's pixels a pixel drawn takes, across and down: 2 on most phones and high-density displays.
  - returns: The scale.
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
- `IsWindowState`: Returns whether flags are set on the window.
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
- `EndDrawing`: Ends a frame's drawing: shows it, then reads the next frame's input.
- `ClearBackground`: Clears the frame to a color, dropping what was drawn before it.
  - `color`: The color.
- `GetRandomValue`: Returns a random whole number from min to max, both included.
  - `min`: The least.
  - `max`: The most.
  - returns: The number.
- `SetRandomSeed`: Seeds `GetRandomValue`, so its numbers repeat from the same seed.
  - `seed`: The seed.
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
- `SetMousePosition`: Moves the mouse to a place on the screen. In a page the cursor can't be moved, so the position reads there until the mouse moves.
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
- `EnableCursor`: Lets go of the mouse that `DisableCursor` locked, and shows the cursor.
- `DisableCursor`: Locks the mouse to the window and hides the cursor, for looking around: `GetMouseDelta` keeps coming while the position goes on past the window's edges. In a page the browser locks it only soon after a click or key press, so without one it locks at the player's next, and Escape lets it go.
- `IsCursorOnScreen`: Returns whether the mouse is over the window.
  - returns: True from its first move over the window until it leaves.
- `SetMouseCursor`: Sets the cursor's shape: the system's own cursor of each kind.
  - `cursor`: The shape (`MOUSE_CURSOR_*`); `MOUSE_CURSOR_DEFAULT` and `MOUSE_CURSOR_ARROW` are both the arrow.
- `GetMouseWheelMove`: Returns how far the wheel turned this frame, the larger of its two directions; away from the player is positive.
  - returns: The notches.
- `GetTouchPointCount`: Returns the number of fingers down.
  - returns: The count.
- `GetTouchPosition`: Returns a finger's position, in the screen's pixels.
  - `index`: Which finger, 0 for the first down.
  - returns: The position, or (0, 0) when fewer are down.
- `GetTouchPointId`: Returns a finger's id, which stays the same while it is down.
  - `index`: Which finger, 0 for the first down.
  - returns: The id, or -1 when fewer are down.
- `GetTouchX`: Returns the first finger's x, in the screen's pixels.
  - returns: The x.
- `GetTouchY`: Returns the first finger's y, in the screen's pixels.
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
- `SetGamepadVibration`: Shakes a gamepad: its left motor is the heavy one, its right the light one, as raylib's. Shaking lasts at most 2 seconds, as raylib's; a browser without vibration (Firefox) doesn't shake.
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
- `GetGamepadButtonPressed`: Returns the last button held, as raylib polls them: gamepads 0 to 3, each's buttons in the browser's order in a page (the second triggers among them, the middle button never), else GLFW's (the middle button among them, the second triggers never).
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
- `SaveFileText`: Writes a text file: through the program's `SetSaveFileTextCallback` when it has one, else kept across runs (in a page, in its storage; natively, in the program's data directory), kept at the end of the frame.
  - `fileName`: The file.
  - `text`: Its text.
  - returns: True when it was written, or will be.
- `UnloadFileData`: Frees bytes `LoadFileDataAsync` gave. There is nothing to free here.
  - `data`: The bytes.
- `SaveFileData`: Writes a file's bytes: through the program's `SetSaveFileDataCallback` when it has one, else kept across runs as `SaveFileText`'s are.
  - `fileName`: The file.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - returns: True when it was written, or will be.
- `IsFileExtension`: Returns whether a file name ends in one of some extensions, ignoring the case of A to Z.
  - `fileName`: The file name.
  - `ext`: The extensions with their dots, `;` between them: ".png;.jpg".
  - returns: True when its extension, from its last dot, is one of them.
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
- `GetPrevDirectoryPath`: Returns the directory a path is in: up to its last `/` or `\`, keeping a root's ("/", "C:\").
  - `dirPath`: The path.
  - returns: The directory above it; the path itself when it has 3 characters or fewer, and "" when a longer one has no slash.
- `IsFileNameValid`: Returns whether a file name could name a file on any system: none of `< > : " / \ | ? *` or a control character, and not only dots.
  - `fileName`: The file name, without a directory.
  - returns: True when it could; true for null or "", as raylib's is.
- `MakeDirectory`: Makes a directory. There is nothing to make: a directory is there once a file is written under it, so this succeeds.
  - `dirPath`: The directory.
  - returns: 0, success; 1 for null or "", as raylib's.
- `UnloadDirectoryFiles`: Frees a listing `LoadDirectoryFilesAsync` or `LoadDirectoryFilesExAsync` gave. There is nothing to free here, and the list is unchanged.
  - `files`: The listing.
- `IsFileDropped`: Returns whether files were dropped on the window, natively from the desktop and in a page on the canvas. It stays true until `UnloadDroppedFiles`, and a new drop's files replace the last one's, as raylib's do. A dropped file counts once its bytes are read, natively in the frame it is dropped, in a page a frame or so after.
  - returns: True while dropped files are held.
- `LoadDroppedFiles`: Returns the paths of the files last dropped. Each is helix-ray's own, `helix-ray-dropped/<n>/<name>`, which every load reads, as `LoadTextureAsync(path)`: the file's name is its last part, a character a path can't hold made `_`. A directory dropped isn't listed.
  - returns: The paths, `count` of them; `capacity` is 0, as raylib's.
- `UnloadDroppedFiles`: Lets go of the files last dropped, so `IsFileDropped` is false until the next drop. A file loaded from one keeps what it loaded.
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
- `DecodeDataBase64`: Returns the bytes of Base64 text. It reads 4 characters at a time up to a zero byte or the end, and a character that isn't Base64's reads as 0, as raylib's does.
  - `data`: The text's bytes.
  - `outputSize`: Its first element is set to how many bytes it gives.
  - returns: The bytes.
- `ComputeCRC32`: Returns the CRC-32 of some bytes, as zlib and PNG compute it.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - returns: Its 32 bits; one above 0x7fffffff is negative.
- `ComputeMD5`: Returns the MD5 hash of some bytes.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - returns: Its 4 words, as raylib gives them: each read from 4 bytes of the hash, the first the lowest, and one above 0x7fffffff is negative.
- `ComputeSHA1`: Returns the SHA-1 hash of some bytes, as raylib 5.5 computes it: its padding holds only the lowest byte of the length in bits, so from 32 bytes on it differs from standard SHA-1.
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
- `TakeScreenshot`: Takes a screenshot of the next frame and hands it to the user as a file, as `ExportImage` writes it by the name's extension (".png", ".qoi" or ".raw"): in a page it is downloaded, as raylib's web build does; natively it is written to the working directory, as raylib writes it there, under the name's file name. raylib's is taken from the frame drawn last, before it is shown; this one is taken as the next frame ends, when its pixels can be read back. Its alpha is opaque, as raylib's is.
  - `fileName`: The file name; a directory before it is dropped, and a name with `'` is refused, as raylib's is.
- `TraceLog`: Writes a message to the log, when its level is at least `SetTraceLogLevel`'s. raylib formats its arguments as printf does; here the text is written as it is (Haxe's string interpolation builds it).
  - `logLevel`: The level (`LOG_*`).
  - `text`: The message.
- `SetTraceLogLevel`: Sets the least level the log writes; `LOG_INFO` until set.
  - `logLevel`: The level (`LOG_*`).
- `SetTraceLogCallback`: Writes the log through the program from now on, helix-ray's own messages among it.
  - `callback`: Receives each message's level and text; null for helix-ray's own log.
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
  - returns: The point.
- `BeginMode3D`: Draws in 3D through a camera until `EndMode3D`, with depth.
  - `camera`: The camera.
- `EndMode3D`: Goes back to drawing in 2D, in the screen's pixels.
- `UpdateCamera`: Moves a camera as one of raylib's modes does: `CAMERA_ORBITAL` turns it about its target, half a radian a second, and the wheel moves it closer; `CAMERA_FREE`, `CAMERA_FIRST_PERSON` and `CAMERA_THIRD_PERSON` move it by WASD, and turn it by the mouse; `CAMERA_CUSTOM` leaves it.
  - `camera`: The camera, changed.
  - `mode`: The mode (`CAMERA_*`).
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
  - returns: The position in the view.
- `GetMouseDelta`: Returns how far the mouse moved since the last frame, in the screen's pixels.
  - returns: The movement.
- `IsShaderValid`: Returns whether a shader was made.
  - `shader`: The shader.
  - returns: True when it was.
- `UnloadShader`: Frees a shader; the default one stays.
  - `shader`: The shader.
- `GetShaderLocation`: Returns the location of a shader's uniform or texture, by its name.
  - `shader`: The shader.
  - `uniformName`: The name.
  - returns: Its location, or -1 when the shader doesn't declare it.
- `GetShaderLocationAttrib`: Returns the location of a shader's attribute, by its name.
  - `shader`: The shader.
  - `attribName`: The name.
  - returns: Its location, or -1 when the shader doesn't declare it.
- `SetShaderValue`: Sets a shader's uniform, for the draws after it.
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
- `SetShaderValueTexture`: Sets a shader's texture, for the draws after it.
  - `shader`: The shader.
  - `locIndex`: The texture's location.
  - `texture`: The texture.
- `BeginShaderMode`: Draws shapes, text and textures with a shader until `EndShaderMode`.
  - `shader`: The shader.
- `EndShaderMode`: Goes back to the default shader.
- `BeginBlendMode`: Blends what is drawn until `EndBlendMode` another way. `BLEND_ALPHA` and `BLEND_ADDITIVE` are here; the others draw as `BLEND_ALPHA` does, and say so once in the log.
  - `mode`: The mode (`BLEND_*`).
- `EndBlendMode`: Goes back to blending by alpha.
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
- `GetShapesTexture`: Returns the texture the filled shapes draw with: a white pixel unless `SetShapesTexture` set another.
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
  - `thick`: The thickness, in pixels.
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
  - `radius`: The radius.
  - `color`: The color.
- `DrawCircleV`: Draws a filled circle.
  - `center`: The center.
  - `radius`: The radius.
  - `color`: The color.
- `DrawCircleSector`: Draws a filled slice of a circle, clockwise from one angle to another.
  - `center`: The center.
  - `radius`: The radius.
  - `startAngle`: The angle it starts at, in degrees from the right.
  - `endAngle`: The angle it ends at.
  - `segments`: How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
  - `color`: The color.
- `DrawCircleSectorLines`: Draws a slice of a circle's outline, one pixel wide, with lines from the center to its ends.
  - `center`: The center.
  - `radius`: The radius.
  - `startAngle`: The angle it starts at, in degrees from the right.
  - `endAngle`: The angle it ends at.
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
  - `outerRadius`: The radius of its edge.
  - `startAngle`: The angle it starts at, in degrees from the right.
  - `endAngle`: The angle it ends at; the same as the start draws nothing.
  - `segments`: How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
  - `color`: The color.
- `DrawRingLines`: Draws a ring's outline, or a slice of one, one pixel wide.
  - `center`: The center.
  - `innerRadius`: The radius of its hole; 0 or less draws a slice of a circle.
  - `outerRadius`: The radius of its edge.
  - `startAngle`: The angle it starts at, in degrees from the right.
  - `endAngle`: The angle it ends at; the same as the start draws nothing.
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
- `DrawRectangleLines`: Draws a rectangle's outline, one pixel wide.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `color`: The color.
- `DrawRectangleLinesEx`: Draws a rectangle's outline, its lines inside it.
  - `rec`: The rectangle.
  - `lineThick`: The lines' thickness.
  - `color`: The color.
- `DrawRectangleRounded`: Draws a filled rectangle with rounded corners.
  - `rec`: The rectangle.
  - `roundness`: How round its corners are: 0 for square, 1 for a radius of half its shorter side.
  - `segments`: How many straight edges make each corner's curve; fewer than 4 picks enough for a smooth curve.
  - `color`: The color.
- `DrawRectangleRoundedLines`: Draws a rounded rectangle's outline, one pixel wide.
  - `rec`: The rectangle.
  - `roundness`: How round its corners are: 0 for square, 1 for a radius of half its shorter side.
  - `segments`: How many straight edges make each corner's curve; fewer than 4 picks enough for a smooth curve.
  - `color`: The color.
- `DrawRectangleRoundedLinesEx`: Draws a rounded rectangle's outline, its lines outside it.
  - `rec`: The rectangle.
  - `roundness`: How round its corners are: 0 for square, 1 for a radius of half its shorter side.
  - `segments`: How many straight edges make each corner's curve; fewer than 4 picks enough for a smooth curve.
  - `lineThick`: The lines' thickness; 1 or less draws them one pixel wide.
  - `color`: The color.
- `DrawTriangle`: Draws a filled triangle; its points go counterclockwise, as raylib's do.
  - `v1`: The first point.
  - `v2`: The second point.
  - `v3`: The third point.
  - `color`: The color.
- `DrawTriangleLines`: Draws a triangle's outline, one pixel wide.
  - `v1`: The first point.
  - `v2`: The second point.
  - `v3`: The third point.
  - `color`: The color.
- `DrawTriangleFan`: Draws filled triangles that all share the first point, each from it to the next two points; they go counterclockwise.
  - `points`: The points, the shared one first.
  - `pointCount`: How many of them to draw, 3 or more.
  - `color`: The color.
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
- `DrawPolyLinesEx`: Draws a regular polygon's outline, its lines inside it.
  - `center`: The center.
  - `sides`: How many sides it has, 3 or more.
  - `radius`: The distance from the center to each corner.
  - `rotation`: The turn of its first corner from the right, in degrees clockwise.
  - `lineThick`: The lines' thickness.
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
  - `thick`: The thickness, in pixels.
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
static function IsImageValid(image:Image):Bool
static function UnloadImage(image:Image):Void
static function ExportImage(image:Image, fileName:String):Bool
static function ExportImageToMemory(image:Image, fileType:String, fileSize:Array<Int>):haxe.io.Bytes
static function ExportImageAsCode(image:Image, fileName:String):Bool
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
static function SetTextureWrap(texture:Texture2D, wrap:Int):Void
static function DrawTextureNPatch(texture:Texture2D, nPatchInfo:NPatchInfo, dest:Rectangle, origin:Vector2, rotation:Float, tint:Color):Void
static function GetPixelColor(srcPtr:haxe.io.Bytes, format:Int, ?offset:Int = 0):Color
static function SetPixelColor(dstPtr:haxe.io.Bytes, color:Color, format:Int, ?offset:Int = 0):Void
```

- `UnloadTexture`: Frees a texture: one load of its file, the GPU's copy with the last.
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
  - returns: The bytes; a compressed format smaller than 4 by 4 pixels takes a whole block, 8 or 16 bytes, and an unknown format 0.
- `LoadRenderTexture`: Makes a texture to draw into, with depth.
  - `width`: Its width, in pixels.
  - `height`: Its height.
  - returns: The render texture.
- `IsRenderTextureValid`: Returns whether a render texture was made.
  - `target`: The render texture.
  - returns: True when it was.
- `UnloadRenderTexture`: Frees a render texture.
  - `target`: The render texture.
- `BeginTextureMode`: Draws into a render texture until `EndTextureMode`. Unlike raylib's, what was drawn into it in an earlier frame isn't kept: each frame's drawing into it starts cleared, to clear black unless `ClearBackground` gives a color.
  - `target`: The render texture.
- `EndTextureMode`: Goes back to drawing on the screen.
- `SetTextureFilter`: Sets how a texture is sampled when drawn larger or smaller: `TEXTURE_FILTER_POINT`, raylib's default, takes the nearest texel, and the others blend the nearest four, as `TEXTURE_FILTER_BILINEAR` does (there are no mipmaps here).
  - `texture`: The texture.
  - `filter`: The filter (`TEXTURE_FILTER_*`).
- `IsImageValid`: Returns whether an image holds pixels: data, a size, a format and a mipmap level.
  - `image`: The image.
  - returns: True when it does.
- `UnloadImage`: Frees an image's pixels.
  - `image`: The image.
- `ExportImage`: Writes an image to a file through `SaveFileData`, as raylib's default build writes it: ".png" (any uncompressed format; a format other than 8-bit grayscale, grayscale and alpha, RGB or RGBA is written as RGBA), ".qoi" (RGB or RGBA alone) or ".raw" (the pixels as they are). The file is kept as `SaveFileData` keeps it; `TakeScreenshot` writes a real file.
  - `image`: The image.
  - `fileName`: The file; its extension chooses the format.
  - returns: True when it was written.
- `ExportImageToMemory`: Returns an image encoded as a file in memory: ".png" alone, as raylib's. Like raylib's, an image's bytes are read as 8-bit gray, gray and alpha, RGB or RGBA by its format, and as RGBA for any other format, which a 16-bit format has too few of: those it lacks read as 0.
  - `image`: The image.
  - `fileType`: ".png" or ".PNG".
  - `fileSize`: Its first element is set to the file's size, 0 for none.
  - returns: The file, or null for another type or an empty image.
- `ExportImageAsCode`: Writes an image as a C header through `SaveFileText`, as raylib's does: its size and format as defines, and its pixels (the first level's) as an array of bytes, 20 a line.
  - `image`: The image.
  - `fileName`: The file; its name, upper case, names the defines and the array.
  - returns: True when it was written.
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
  - `text`: The text.
  - returns: The image.
- `ImageCopy`: Returns a copy of an image, its mipmaps too.
  - `image`: The image.
  - returns: The copy.
- `ImageFromImage`: Returns a rectangle of an image, in its format. A row reaching past the image's right edge reads on into the next row, as raylib's does; what lies past the image's pixels reads as zeros, where raylib's reads past them.
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
  - `text`: The text.
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
- `ImageBlurGaussian`: Blurs an image, as raylib's does: an approximate Gaussian, four passes of a box blur across and down, over premultiplied alpha. A box reaching past the image's last pixel reads 0 there, where raylib's reads past its pixels.
  - `image`: The image.
  - `blurSize`: How far each box reaches either side of a pixel, in pixels.
- `ImageKernelConvolution`: Applies a square kernel to an image, as raylib's does: each channel, alpha too, the sum of the pixels around it as fractions times the weights; red, green and blue clamped to 0 to 1, alpha not. A pixel past the left or right edge is taken from the row beside, one past the top or bottom is 0. A count that isn't square changes nothing, with a warning.
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
- `GetImageColor`: Returns a pixel's color, as `LoadImageColors` reads it but for raylib's R32G32B32A32 and R16G16B16A16, whose channels are each read from red. A pixel outside the image is clear black, with a warning.
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
- `ImageDrawLine`: Draws a line one pixel wide, from its start up to its end; the end pixel isn't drawn.
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
- `ImageDrawLineEx`: Draws a line of a thickness: the line, and copies of it above and below for a line more across than down, left and right otherwise. Its ends are rounded to whole pixels.
  - `dst`: The image.
  - `start`: The start.
  - `end`: The end.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `ImageDrawCircle`: Fills a circle.
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
- `ImageDrawRectangleLines`: Outlines a rectangle, the outline inside it.
  - `dst`: The image.
  - `rec`: The rectangle, in pixels.
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
- `LoadTextureFromImage`: Makes a texture of an image, in any uncompressed format: its pixels go to the GPU as RGBA when first drawn, so the texture's format is `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8` and it has one level. A compressed format gives no texture, with a warning.
  - `image`: The image.
  - returns: The texture.
- `SetTextureWrap`: Sets how a texture wraps past its edges: `TEXTURE_WRAP_REPEAT`, `TEXTURE_WRAP_CLAMP` (raylib's default) or `TEXTURE_WRAP_MIRROR_REPEAT`. `TEXTURE_WRAP_MIRROR_CLAMP` isn't here, and leaves it unchanged, with a warning.
  - `texture`: The texture.
  - `wrap`: The wrap (`TEXTURE_WRAP_*`).
- `DrawTextureNPatch`: Draws a texture as a nine-patch (or a three-patch) into a rectangle, turned about an origin, as raylib's does: its corners kept, its edges and middle stretched; a rectangle smaller than the borders shrinks them and drops the middle.
  - `texture`: The texture.
  - `nPatchInfo`: The patch: its rectangle on the texture, its borders and its layout (`NPATCH_*`).
  - `dest`: Where it goes; its x and y are where the origin lands.
  - `origin`: The point it turns about, from dest's top-left corner.
  - `rotation`: Clockwise, in degrees.
  - `tint`: The color it is multiplied by.
- `GetPixelColor`: Returns one pixel's color from pixels in a format, as raylib's does: 16-bit channels widened by integers, floats times 255. raylib's R5G5B5A1 blue takes in the alpha bit, as it does here. raylib takes a pointer to the pixel; here it is the pixels and the pixel's first byte.
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
  - returns: The index.
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
- `LoadFontFromImage`: Makes a font from an image of glyphs, as raylib's does: the glyphs in rows on a key color, the key's border before the first glyph giving the space between glyphs and between rows; each glyph a run of pixels that aren't the key, numbered from a first character. The key becomes clear on the font's texture. An image with no such border gives the default font. At most 256 glyphs are read, and a pixel past the image reads as the key, where raylib's reads past its pixels.
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
  - returns: The text.
- `TextIsEqual`: Returns whether two texts are the same.
  - `text1`: The first text.
  - `text2`: The second text.
  - returns: True when they are; false when either is null.
- `TextLength`: Returns the length of text in UTF-8 bytes, as raylib counts it: "héllo" is 6. The text functions' positions and lengths are all in these bytes, where `String.length` counts otherwise, and not alike on every target.
  - `text`: The text.
  - returns: The length, in bytes; 0 for null text.
- `TextSubtext`: Returns a piece of text, by its place in UTF-8 bytes. A position at or past the end gives no text, and the piece ends with the text.
  - `text`: The text.
  - `position`: Where the piece starts, in bytes from the start.
  - `length`: How long it is, in bytes.
  - returns: The piece.

  A character the piece cuts through is a "?" for each of its bytes taken, as raylib draws it.
- `TextReplace`: Returns text with every piece of it that matches replaced, from the start, each match after the one before.
  - `text`: The text.
  - `replace`: The text replaced.
  - `by`: The text put in its place.
  - returns: The new text; null when any is null or `replace` is empty.
- `TextInsert`: Returns text with other text put in at a place in UTF-8 bytes.
  - `text`: The text.
  - `insert`: The text put in.
  - `position`: Where, in bytes from the start, clamped to the end.
  - returns: The new text; empty when either is null or the position is below 0.

  A character the place cuts through is a "?" for each of its bytes, as raylib draws it.
- `TextJoin`: Returns texts joined into one, a delimiter between each two.
  - `textList`: The texts; a null one is empty.
  - `count`: How many of them.
  - `delimiter`: The text between them; null for none.
  - returns: The joined text.
- `TextSplit`: Returns the pieces of text between a delimiter: one more than the delimiters it holds, an empty one between two together.
  - `text`: The text.
  - `delimiter`: The character between pieces.
  - `count`: Receives how many pieces there are, at its index 0; 0 for null text.
  - returns: The pieces; none for null text.

  The delimiter is a character, so a character outside ASCII splits text as an ASCII one does; raylib's is one byte. There is no limit to the pieces, where raylib's stops at 128.
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
- `TextToPascal`: Returns snake-case text in Pascal case: "hello_world" is "HelloWorld". Each run of underscores is dropped, and the first letter and the one after each run are made capitals if they are a to z.
  - `text`: The text.
  - returns: The new text; empty for null text.
- `TextToSnake`: Returns Pascal- or camel-case text in snake case: "helloWorld" is "hello_world". Each capital A to Z is made lower case, an underscore before it unless it starts the text.
  - `text`: The text.
  - returns: The new text; empty for null text.
- `TextToCamel`: Returns snake-case text in camel case: "hello_world" is "helloWorld". Each run of underscores is dropped, the letter after it made a capital if it is a to z, and the first letter made lower case if it is A to Z.
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
  - `count`: Receives how many there are, at its index 0.
  - returns: The codes; none for null text.
- `UnloadCodepoints`: Does nothing: codes from `LoadCodepoints` are freed by the garbage collector.
  - `codepoints`: The codes.
- `GetCodepointCount`: Returns how many characters text holds: "héllo→" holds 6, in 9 bytes.
  - `text`: The text.
  - returns: The count; 0 for null text.
- `GetCodepoint`: Returns the code of text's first character, checked as RFC 3629 has UTF-8, as raylib checks it.
  - `text`: The text.
  - `codepointSize`: Receives the character's length in UTF-8 bytes, at its index 0: what to move past it by.
  - returns: The code; 0 for empty text.
- `GetCodepointNext`: Returns the code of text's first character.
  - `text`: The text.
  - `codepointSize`: Receives the character's length in UTF-8 bytes, at its index 0: what to move past it by, as in `TextSubtext(text, codepointSize[0], TextLength(text))`.
  - returns: The code; 0 for empty text.
- `GetCodepointPrevious`: Returns the code of text's last character: the one before where it ends, as raylib's finds the one before a place in text.
  - `text`: The text; `TextSubtext(text, 0, position)` gives the character before a position.
  - `codepointSize`: Receives the character's length in UTF-8 bytes, at its index 0: what to move back by; 0 for empty text.
  - returns: The code; '?' (0x3F) for empty text.
- `CodepointToUTF8`: Returns a character as text.
  - `codepoint`: The character's code.
  - `utf8Size`: Receives its length in UTF-8 bytes, at its index 0; 0 for a code past 0x10FFFF.
  - returns: The text; empty for a code past 0x10FFFF.

### rmodels: 3D shapes, models, meshes and rays

```haxe
static function DrawLine3D(startPos:Vector3, endPos:Vector3, color:Color):Void
static function DrawCube(position:Vector3, width:Float, height:Float, length:Float, color:Color):Void
static function DrawCubeV(position:Vector3, size:Vector3, color:Color):Void
static function DrawCubeWires(position:Vector3, width:Float, height:Float, length:Float, color:Color):Void
static function DrawCubeWiresV(position:Vector3, size:Vector3, color:Color):Void
static function DrawBoundingBox(box:BoundingBox, color:Color):Void
static function DrawSphere(centerPos:Vector3, radius:Float, color:Color):Void
static function DrawSphereEx(centerPos:Vector3, radius:Float, rings:Int, slices:Int, color:Color):Void
static function DrawSphereWires(centerPos:Vector3, radius:Float, rings:Int, slices:Int, color:Color):Void
static function DrawPlane(centerPos:Vector3, size:Vector2, color:Color):Void
static function DrawGrid(slices:Int, spacing:Float):Void
static function LoadModelFromMesh(mesh:Mesh):Model
static function IsModelValid(model:Model):Bool
static function UnloadModel(model:Model):Void
static function DrawModel(model:Model, position:Vector3, scale:Float, tint:Color):Void
static function DrawModelEx(model:Model, position:Vector3, rotationAxis:Vector3, rotationAngle:Float, scale:Vector3, tint:Color):Void
static function DrawMesh(mesh:Mesh, material:Material, transform:Matrix):Void
static function UploadMesh(mesh:Mesh, isDynamic:Bool):Void
static function UnloadMesh(mesh:Mesh):Void
static function GenMeshCube(width:Float, height:Float, length:Float):Mesh
static function GenMeshPlane(width:Float, length:Float, resX:Int, resZ:Int):Mesh
static function GenMeshSphere(radius:Float, rings:Int, slices:Int):Mesh
static function LoadMaterialDefault():Material
static function SetMaterialTexture(material:Material, mapType:Int, texture:Texture2D):Void
static function SetModelMeshMaterial(model:Model, meshId:Int, materialId:Int):Void
static function GetMeshBoundingBox(mesh:Mesh):BoundingBox
static function GetModelBoundingBox(model:Model):BoundingBox
static function CheckCollisionBoxes(box1:BoundingBox, box2:BoundingBox):Bool
static function CheckCollisionSpheres(center1:Vector3, radius1:Float, center2:Vector3, radius2:Float):Bool
static function CheckCollisionBoxSphere(box:BoundingBox, center:Vector3, radius:Float):Bool
static function GetRayCollisionSphere(ray:Ray, center:Vector3, radius:Float):RayCollision
static function GetRayCollisionBox(ray:Ray, box:BoundingBox):RayCollision
static function GetRayCollisionTriangle(ray:Ray, p1:Vector3, p2:Vector3, p3:Vector3):RayCollision
static function GetRayCollisionMesh(ray:Ray, mesh:Mesh, transform:Matrix):RayCollision
```

- `DrawLine3D`: Draws a line in 3D.
  - `startPos`: The start.
  - `endPos`: The end.
  - `color`: The color.
- `DrawCube`: Draws a filled box.
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
- `DrawBoundingBox`: Draws a bounding box's edges.
  - `box`: The box.
  - `color`: The color.
- `DrawSphere`: Draws a filled sphere, 16 rings and 16 slices.
  - `centerPos`: Its center.
  - `radius`: Its radius.
  - `color`: The color.
- `DrawSphereEx`: Draws a filled sphere.
  - `centerPos`: Its center.
  - `radius`: Its radius.
  - `rings`: Rings top to bottom.
  - `slices`: Slices around.
  - `color`: The color.
- `DrawSphereWires`: Draws a sphere's wires.
  - `centerPos`: Its center.
  - `radius`: Its radius.
  - `rings`: Rings top to bottom.
  - `slices`: Slices around.
  - `color`: The color.
- `DrawPlane`: Draws a flat rectangle on the XZ plane, facing up.
  - `centerPos`: Its center.
  - `size`: Its size along x and z.
  - `color`: The color.
- `DrawGrid`: Draws a grid on the XZ plane, centered on the origin: its center lines darker, as raylib's.
  - `slices`: The lines each way.
  - `spacing`: The space between them.
- `LoadModelFromMesh`: Makes a model of one mesh, with the default material.
  - `mesh`: The mesh.
  - returns: The model.
- `IsModelValid`: Returns whether a model has meshes.
  - `model`: The model.
  - returns: True when it has.
- `UnloadModel`: Frees a model: one load of its file, its meshes and textures with the last; a model of a mesh, its meshes and its materials' textures at once.
  - `model`: The model.
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
- `DrawMesh`: Draws a mesh with a material and a transform.
  - `mesh`: The mesh.
  - `material`: The material.
  - `transform`: The transform.
- `UploadMesh`: Sends a mesh's vertices to the GPU, so it can be drawn. The `GenMesh*` functions and `LoadModelAsync` do it themselves.
  - `mesh`: The mesh.
  - `isDynamic`: Whether it will change (raylib names it `dynamic`, a Haxe keyword); meshes here can't, so it is ignored.
- `UnloadMesh`: Frees a mesh's GPU buffers.
  - `mesh`: The mesh.
- `GenMeshCube`: Makes a box mesh, centered on the origin.
  - `width`: Along x.
  - `height`: Along y.
  - `length`: Along z.
  - returns: The mesh.
- `GenMeshPlane`: Makes a flat mesh on the XZ plane, facing up.
  - `width`: Along x.
  - `length`: Along z.
  - `resX`: Divisions along x.
  - `resZ`: Divisions along z.
  - returns: The mesh.
- `GenMeshSphere`: Makes a sphere mesh, centered on the origin.
  - `radius`: Its radius.
  - `rings`: Rings top to bottom.
  - `slices`: Slices around.
  - returns: The mesh.
- `LoadMaterialDefault`: Returns raylib's default material: the default shader, white.
  - returns: The material.
- `SetMaterialTexture`: Sets a texture on a material's map.
  - `material`: The material.
  - `mapType`: The map (`MATERIAL_MAP_*`).
  - `texture`: The texture.
- `SetModelMeshMaterial`: Sets the material a model's mesh draws with.
  - `model`: The model.
  - `meshId`: The mesh.
  - `materialId`: The material.
- `GetMeshBoundingBox`: Returns a mesh's bounds.
  - `mesh`: The mesh.
  - returns: The box.
- `GetModelBoundingBox`: Returns a model's bounds, its transform applied.
  - `model`: The model.
  - returns: The box.
- `CheckCollisionBoxes`: Returns whether two boxes overlap.
  - `box1`: One.
  - `box2`: The other.
  - returns: True when they overlap.
- `CheckCollisionSpheres`: Returns whether two spheres overlap.
  - `center1`: One's center.
  - `radius1`: Its radius.
  - `center2`: The other's center.
  - `radius2`: Its radius.
  - returns: True when they overlap.
- `CheckCollisionBoxSphere`: Returns whether a box and a sphere overlap.
  - `box`: The box.
  - `center`: The sphere's center.
  - `radius`: Its radius.
  - returns: True when they overlap.
- `GetRayCollisionSphere`: Returns where a ray hits a sphere.
  - `ray`: The ray.
  - `center`: The sphere's center.
  - `radius`: Its radius.
  - returns: The hit.
- `GetRayCollisionBox`: Returns where a ray hits a box.
  - `ray`: The ray.
  - `box`: The box.
  - returns: The hit.
- `GetRayCollisionTriangle`: Returns where a ray hits a triangle.
  - `ray`: The ray.
  - `p1`: A corner.
  - `p2`: A corner.
  - `p3`: A corner.
  - returns: The hit.
- `GetRayCollisionMesh`: Returns where a ray hits a mesh drawn with a transform: its nearest triangle.
  - `ray`: The ray.
  - `mesh`: The mesh.
  - `transform`: The transform.
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
static function ExportWave(wave:Wave, fileName:String):Bool
static function ExportWaveAsCode(wave:Wave, fileName:String):Bool
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
static function LoadMusicStream(fileName:String):Music
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
- `ExportWave`: Writes a wave to a file through `SaveFileData`: ".wav" (8, 16 and 24 bits as integers, 32 as floats, as raylib's dr_wav writes them) or ".raw" (the samples as they are). raylib's ".qoa" isn't written here. The file is kept as `SaveFileData` keeps it.
  - `wave`: The wave.
  - `fileName`: The file; its extension chooses the format.
  - returns: True when it was written.
- `ExportWaveAsCode`: Writes a wave as a C header through `SaveFileText`, as raylib's does: its frames, rate, sample size and channels as defines, and its samples as an array: floats with 4 places for 32-bit samples, else bytes, 20 a line.
  - `wave`: The wave.
  - `fileName`: The file; its name, upper case, names the defines and the array.
  - returns: True when it was written.
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
- `SetSoundPitch`: Sets a sound's pitch, for its next play and the one playing.
  - `sound`: The sound.
  - `pitch`: 1 for as recorded, 2 an octave up.
- `SetSoundPan`: Sets where a sound is heard, for its next play and the one playing.
  - `sound`: The sound.
  - `pan`: 0 for left, 0.5 the middle, 1 for right, as raylib's.
- `LoadMusicStream`: Opens a music file, to be played as it is read (helix-services' `Audio.stream`): natively from its file, in a page from the download as it arrives, never loaded whole. It may be played at once; it starts once it opens.
  - `fileName`: The file, as the program names it, such as "assets/theme.ogg".
  - returns: The music.
- `LoadMusicStreamFromMemory`: Opens music from a file's bytes, to be played as it is read, as `LoadMusicStream` plays a file: in a page from a Blob's URL, natively from a copy written to the program's cache directory, deleted when the music is unloaded. `InitAudioDevice` comes first.
  - `fileType`: The file's extension, such as ".ogg": Ogg Vorbis, MP3, WAV or FLAC.
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
- `UpdateMusicStream`: Keeps music playing. raylib's programs call it each frame; here the stream feeds itself, so it does nothing.
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
- `SetMusicPitch`: Sets music's pitch.
  - `music`: The music.
  - `pitch`: 1 for as recorded.
- `SetMusicPan`: Sets where music is heard.
  - `music`: The music.
  - `pan`: 0 for left, 0.5 the middle, 1 for right, as raylib's.
- `GetMusicTimeLength`: Returns music's length (helix-services' `Sound.duration`): known once it opens from a file natively or in a page; a server's file natively once its start and its last 64 KiB have arrived. 0 while it isn't known.
  - `music`: The music.
  - returns: The length, in seconds.
- `GetMusicTimePlayed`: Returns how far music has played, back to 0 at each loop, as raylib's. Paused, it holds; stopped, it is 0.
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
- `SetAudioStreamPitch`: Sets a stream's pitch.
  - `stream`: The stream.
  - `pitch`: 1 for as given.
- `SetAudioStreamPan`: Sets where a stream is heard.
  - `stream`: The stream.
  - `pan`: 0 for left, 0.5 the middle, 1 for right, as raylib's.
- `SetAudioStreamBufferSizeDefault`: Sets the frames in each of a stream's two buffers, for the streams opened after; 0 for raylib's default, a 30th of a second at 44100 Hz (1470 frames).
  - `size`: The frames.
- `SetAudioStreamCallback`: Has a stream ask the program for its samples: while it plays, the callback is called with a buffer's frames to fill until the stream holds two buffers ahead of what is heard. raylib calls it on its audio thread as the mixer needs frames; a page can't run Haxe there, so here it is called on the main thread as each frame ends (`EndDrawing`'s poll), and once as the stream starts to play. A frame long enough to empty both buffers is heard as a gap.
  - `stream`: The stream.
  - `callback`: Receives a buffer to fill, in the stream's sample size and channels, and its frames; null for none.

### the async loads, helix-ray's own in place of raylib's that wait for a file

```haxe
static function LoadTextureAsync(fileName:String, loaded:Texture2D -> Void, ?failed:String -> Void):Void
static function LoadModelAsync(fileName:String, loaded:Model -> Void, ?failed:String -> Void):Void
static function LoadSoundAsync(fileName:String, loaded:Sound -> Void, ?failed:String -> Void):Void
static function LoadWaveAsync(fileName:String, loaded:Wave -> Void, ?failed:String -> Void):Void
static function LoadWaveFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, loaded:Wave -> Void, ?failed:String -> Void):Void
static function LoadFileTextAsync(fileName:String, loaded:String -> Void, ?failed:String -> Void):Void
static function LoadFileDataAsync(fileName:String, loaded:haxe.io.Bytes -> Void, ?failed:String -> Void):Void
static function FileExistsAsync(fileName:String, answer:Bool -> Void):Void
static function GetFileLengthAsync(fileName:String, answer:Int -> Void):Void
static function GetFileModTimeAsync(fileName:String, answer:Int -> Void):Void
static function IsPathFileAsync(path:String, answer:Bool -> Void):Void
static function DirectoryExistsAsync(dirPath:String, answer:Bool -> Void):Void
static function LoadDirectoryFilesAsync(dirPath:String, loaded:FilePathList -> Void):Void
static function LoadDirectoryFilesExAsync(basePath:String, filter:String, scanSubdirs:Bool, loaded:FilePathList -> Void):Void
static function LoadFontAsync(fileName:String, loaded:Font -> Void, ?failed:String -> Void):Void
static function LoadFontExAsync(fileName:String, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, loaded:Font -> Void, ?failed:String -> Void):Void
static function LoadFontFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, loaded:Font -> Void, ?failed:String -> Void):Void
static function LoadFontDataAsync(fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, type:Int, loaded:Array<GlyphInfo> -> Void, ?failed:String -> Void):Void
static function LoadImageAsync(fileName:String, loaded:Image -> Void, ?failed:String -> Void):Void
static function LoadImageRawAsync(fileName:String, width:Int, height:Int, format:Int, headerSize:Int, loaded:Image -> Void, ?failed:String -> Void):Void
static function LoadImageFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, loaded:Image -> Void, ?failed:String -> Void):Void
static function LoadImageFromTextureAsync(texture:Texture2D, loaded:Image -> Void, ?failed:String -> Void):Void
static function LoadImageFromScreenAsync(loaded:Image -> Void, ?failed:String -> Void):Void
static function GetClipboardTextAsync(read:String -> Void, ?failed:String -> Void):Void
static function GetClipboardImageAsync(loaded:Image -> Void, ?failed:String -> Void):Void
```

- `LoadTextureAsync`: Loads an image file as a texture, answering when it is ready: helix-ray's own, in place of raylib's `LoadTexture`, as a page can't wait for a file. A file loaded again shares its first load's texture, and the image goes to the GPU when first drawn. The answer comes at a later frame, never during the call.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the texture.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.
- `LoadModelAsync`: Loads a model from a glTF or GLB file, with its images and the files it points to, answering when it is ready: helix-ray's own, in place of raylib's `LoadModel`. A file loaded again shares its first load's meshes and textures, with materials of its own.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the model.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.
- `LoadSoundAsync`: Loads a sound file and decodes it, answering when it is ready to play at once: helix-ray's own, in place of raylib's `LoadSound`. A file loaded again shares its first load's decoded sound. `InitAudioDevice` comes first.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the sound.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.
- `LoadWaveAsync`: Loads a sound file's samples, answering when they are read: helix-ray's own, in place of raylib's `LoadWave`. The formats are `LoadWaveFromMemoryAsync`'s, by the file's extension.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the wave, its samples its own.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.
- `LoadWaveFromMemoryAsync`: Reads a sound file's samples from its bytes, answering when they are read: helix-ray's own, in place of raylib's `LoadWaveFromMemory`, as files other than WAV are decoded off the main thread.
  - `fileType`: The file's extension with its dot: ".wav", ".ogg", ".mp3" or ".flac", or the same in upper case.
  - `fileData`: The file's bytes.
  - `dataSize`: How many of them.
  - `loaded`: Receives the wave, its samples its own.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  A ".wav" file is read as raylib's dr_wav reads it, as 16-bit samples at the file's rate and channels (ADPCM and other compressed WAV encodings aren't read). An ".ogg", ".mp3" or ".flac" file is decoded by the platform, as 32-bit float samples at 44100 Hz in the file's channels, where raylib keeps the file's rate (and gives Ogg 16-bit samples); a file of more than 2 channels is mixed to stereo. FLAC is read here, which raylib's default build leaves out; QOA isn't. As raylib's, the extension is lower or upper case. The answer comes at a later frame.
- `LoadFileTextAsync`: Reads a text file, answering when it is read: helix-ray's own, in place of raylib's `LoadFileText`. The program's `SetLoadFileTextCallback` answers first, then what `SaveFileText` wrote, then the program's files.
  - `fileName`: The file.
  - `loaded`: Receives its text.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.
- `LoadFileDataAsync`: Reads a file's bytes, answering when they are read: helix-ray's own, in place of raylib's `LoadFileData`. The program's `SetLoadFileDataCallback` answers first, then what `SaveFileData` wrote, then the program's files.
  - `fileName`: The file.
  - `loaded`: Receives its bytes.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.
- `FileExistsAsync`: Answers whether a file exists: helix-ray's own, in place of raylib's `FileExists`. One `SaveFileText` or `SaveFileData` wrote exists, as does one of the program's; finding one of the program's reads it, so a load of it after answers at once. The answer comes at a later frame, never during the call.
  - `fileName`: The file.
  - `answer`: Receives true when it exists.
- `GetFileLengthAsync`: Answers a file's size: helix-ray's own, in place of raylib's `GetFileLength`. A file `SaveFileText` or `SaveFileData` wrote, or the program's `SetLoadFileDataCallback` gives, is its bytes' size; a dropped file's is its own. Natively a file of the program's is its size on disk; in a page it is read from the server to be measured, so a load of it after answers at once. The answer comes at a later frame, never during the call.
  - `fileName`: The file.
  - `answer`: Receives its size in bytes; 0 when there is no file, as raylib's.
- `GetFileModTimeAsync`: Answers when a file was last written: helix-ray's own, in place of raylib's `GetFileModTime`. Natively a file of the program's answers its time on disk; a file `SaveFileText` or `SaveFileData` wrote, when it was saved. A page's own files are on its server, and a dropped file or one the program's load callback gives has no time kept, so each answers 0. The answer comes at a later frame, never during the call.
  - `fileName`: The file.
  - `answer`: Receives the time, in whole seconds since the Unix epoch; 0 when there is no file or no time, as raylib's.
- `IsPathFileAsync`: Answers whether a path is a file, not a directory: helix-ray's own, in place of raylib's `IsPathFile`. A file `SaveFileText` or `SaveFileData` wrote, a dropped file, and a file the program has, as `FileExistsAsync` finds them, are files. The answer comes at a later frame, never during the call.
  - `path`: The path.
  - `answer`: Receives true for a file; false for a directory or nothing there.
- `DirectoryExistsAsync`: Answers whether a directory exists: helix-ray's own, in place of raylib's `DirectoryExists`. Natively it is a directory of the program's files; `helix-ray-dropped` and the directories under it hold the dropped files. A page's own files are on its server, which can't be listed, so there only its root ("", "." or "./") and the dropped files' directories exist. The answer comes at a later frame, never during the call.
  - `dirPath`: The directory.
  - `answer`: Receives true when it exists.
- `LoadDirectoryFilesAsync`: Lists a directory's files and subdirectories: helix-ray's own, in place of raylib's `LoadDirectoryFiles`. Each path is the directory's followed by `/` and the name (`dirPath` "levels" gives "levels/1.json"), sorted by name, a subdirectory's without a slash at its end. The directories are `DirectoryExistsAsync`'s; a page lists only the dropped files. Files `SaveFileText` and `SaveFileData` wrote aren't listed. The answer comes at a later frame, never during the call.
  - `dirPath`: The directory.
  - `loaded`: Receives the list, its `capacity` its `count`; empty, with a warning, when the directory can't be listed, as raylib's.
- `LoadDirectoryFilesExAsync`: Lists a directory's files, those with some extensions, and with `scanSubdirs` its subdirectories' too: helix-ray's own, in place of raylib's `LoadDirectoryFilesEx`. The paths are `LoadDirectoryFilesAsync`'s, a subdirectory's files right after it. As raylib's: a null filter keeps every file, and without `scanSubdirs` every subdirectory too; a filter is `IsFileExtension`'s list, and "DIR" in it keeps the subdirectories; at most 8192 paths are listed (`MAX_FILEPATH_CAPACITY`), with a warning when there are more. The answer comes at a later frame, never during the call.
  - `basePath`: The directory.
  - `filter`: The extensions kept, such as ".png;.jpg;DIR", or null for every file.
  - `scanSubdirs`: Whether the subdirectories' files are listed too.
  - `loaded`: Receives the list, its `capacity` 8192; a directory that can't be listed adds nothing, with a warning.
- `LoadFontAsync`: Loads a font file, answering when its glyphs are ready: helix-ray's own, in place of raylib's `LoadFont`. A TrueType or OpenType file gives its printable ASCII at 32 pixels; a BMFont (.fnt, the text format) its characters and pages, the pages stacked onto one texture, as raylib's; an image (PNG, JPEG, BMP, TGA or QOI) its glyphs on a `MAGENTA` key from the space on, as `LoadFontFromImage` reads them; each drawn with `TEXTURE_FILTER_POINT`.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the font.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.
- `LoadFontExAsync`: Loads a TrueType or OpenType font file at a size, answering when its glyphs are ready: helix-ray's own, in place of raylib's `LoadFontEx`.
  - `fileName`: The file, as the program names it.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95, the printable ASCII when `codepoints` is null.
  - `loaded`: Receives the font.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.
- `LoadFontFromMemoryAsync`: Makes a font from a TrueType or OpenType file's bytes, answering when its glyphs are ready: helix-ray's own, in place of raylib's `LoadFontFromMemory`, as the glyphs are rasterized off the main thread.
  - `fileType`: The file's extension, ".ttf" or ".otf".
  - `fileData`: The file's bytes.
  - `dataSize`: How many of them.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95.
  - `loaded`: Receives the font.
  - `failed`: Optional. Receives why it couldn't be made; when omitted, it is logged.
- `LoadFontDataAsync`: Rasterizes a TrueType or OpenType font's glyphs, answering when they are ready: helix-ray's own, in place of raylib's `LoadFontData`. Each glyph has its own image, 8-bit grayscale, for `GenImageFontAtlas`; `FONT_SDF` makes them signed distances, with 4 texels of padding, 128 on the outline and 64 a texel.
  - `fileData`: The font file's bytes.
  - `dataSize`: How many of them.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95.
  - `type`: `FONT_DEFAULT` for antialiased glyphs, `FONT_BITMAP` for glyphs with no gray, `FONT_SDF` for signed distances.
  - `loaded`: Receives the glyphs.
  - `failed`: Optional. Receives why the font couldn't be read; when omitted, it is logged.
- `LoadImageAsync`: Loads an image file, answering when it is decoded: helix-ray's own, in place of raylib's `LoadImage`, as a page can't wait for a file. A PNG, JPEG, BMP or TGA file is decoded by the platform, so it gives `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8` whatever its channels, where raylib's gives a grayscale file grayscale; a QOI file gives its own channels, RGB or RGBA, as raylib's. The answer comes at a later frame, never during the call.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the image, its pixels its own.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.
- `LoadImageRawAsync`: Loads an image's raw pixels from a file, answering when they are read: helix-ray's own, in place of raylib's `LoadImageRaw`. The file holds the pixels in a format, after a header of some bytes; a file too small for them fails.
  - `fileName`: The file.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `format`: The pixel format (`PIXELFORMAT_*`).
  - `headerSize`: The bytes before the pixels, skipped when the file holds them and the pixels.
  - `loaded`: Receives the image.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.
- `LoadImageFromMemoryAsync`: Decodes an image file's bytes, answering when it is decoded: helix-ray's own, in place of raylib's `LoadImageFromMemory`, as images are decoded asynchronously. The formats and channels are `LoadImageAsync`'s.
  - `fileType`: The file's extension: ".png", ".jpg", ".jpeg", ".bmp", ".tga" or ".qoi".
  - `fileData`: The file's bytes.
  - `dataSize`: How many of them.
  - `loaded`: Receives the image.
  - `failed`: Optional. Receives why it couldn't be decoded; when omitted, it is logged.
- `LoadImageFromTextureAsync`: Reads a texture's pixels, answering when they are read: helix-ray's own, in place of raylib's `LoadImageFromTexture`, as the GPU answers later. A render texture's are read back from the GPU after the frame it was drawn in, rows bottom first as raylib's are, so it reads upside down as raylib's does. Another texture's pixels are what went to the GPU, while they are in memory: before it is first drawn, or when it was loaded from a file; once only on the GPU they can't be read here, and it fails.
  - `texture`: The texture.
  - `loaded`: Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.
- `LoadImageFromScreenAsync`: Reads the screen, answering as the next frame ends: helix-ray's own, in place of raylib's `LoadImageFromScreen`, as the GPU answers later. The image is the framebuffer's size, rows top first, its alpha opaque, as raylib's.
  - `loaded`: Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.
- `GetClipboardTextAsync`: Reads the clipboard's text, answering at a later poll: helix-ray's own, in place of raylib's `GetClipboardText`, as a page's clipboard answers later. A page reads it only with the player's permission, which the browser may ask for.
  - `read`: Receives the text; "" when the clipboard holds none.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.
- `GetClipboardImageAsync`: Reads the clipboard's image, answering at a later poll once it is decoded: helix-ray's own, in place of raylib's `GetClipboardImage`. A page reads it only with the player's permission.
  - `loaded`: Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `failed`: Optional. Receives why there is none, or why it couldn't be read; when omitted, it is logged.

### Macros, run as the program builds

```haxe
static macro function LoadShader(vsFileName:Null<String>, fsFileName:Null<String>):Shader
static macro function LoadShaderFromMemory(vsCode:Null<String>, fsCode:Null<String>):Shader
```

- `LoadShader`: Loads a shader from raylib GLSL files (330, or 100 for the web), either null for raylib's default stage. They are compiled as the program builds, for every target, so their names are constants; the files are found under `-D helix-ray-files` (default `web`), as the program's other files are.
  - `vsFileName`: The vertex stage's file, or null.
  - `fsFileName`: The fragment stage's file, or null.
  - returns: The shader.
- `LoadShaderFromMemory`: Loads a shader from raylib GLSL text, either null for raylib's default stage. It is compiled as the program builds, so the text is a constant.
  - `vsCode`: The vertex stage's text, or null.
  - `fsCode`: The fragment stage's text, or null.
  - returns: The shader.

### Not supported in helix-ray

Each of these is raylib's name, and a call to it doesn't compile, saying why and what to use instead.

`GetClipboardText`, `GetClipboardImage`, `GetWindowHandle`, `GetMonitorPhysicalWidth`, `GetMonitorPhysicalHeight`, `FileExists`, `LoadFileText`, `LoadFileData`, `DirectoryExists`, `GetFileLength`, `IsPathFile`, `LoadDirectoryFiles`, `LoadDirectoryFilesEx`, `GetFileModTime`, `LoadTexture`, `LoadImage`, `LoadImageRaw`, `LoadImageFromMemory`, `LoadImageFromTexture`, `LoadImageFromScreen`, `LoadFont`, `LoadFontEx`, `LoadFontFromMemory`, `LoadFontData`, `TextCopy`, `TextAppend`, `LoadModel`, `LoadWave`, `LoadWaveFromMemory`, `LoadSound`, `AttachAudioStreamProcessor`, `DetachAudioStreamProcessor`, `AttachAudioMixedProcessor`, `DetachAudioMixedProcessor`.

### Not in helix-ray yet

Each of these is raylib's name, and a call to it doesn't compile, saying so.

`EnableEventWaiting`, `DisableEventWaiting`, `BeginVrStereoMode`, `EndVrStereoMode`, `LoadVrStereoConfig`, `UnloadVrStereoConfig`, `SwapScreenBuffer`, `PollInputEvents`, `LoadRandomSequence`, `UnloadRandomSequence`, `MemAlloc`, `MemRealloc`, `MemFree`, `ExportDataAsCode`, `GetWorkingDirectory`, `GetApplicationDirectory`, `ChangeDirectory`, `LoadAutomationEventList`, `UnloadAutomationEventList`, `ExportAutomationEventList`, `SetAutomationEventList`, `SetAutomationEventBaseFrame`, `StartAutomationEventRecording`, `StopAutomationEventRecording`, `PlayAutomationEvent`, `UpdateCameraPro`, `LoadImageAnim`, `LoadImageAnimFromMemory`, `LoadTextureCubemap`, `UpdateTexture`, `UpdateTextureRec`, `GenTextureMipmaps`, `ExportFontAsCode`, `DrawPoint3D`, `DrawCircle3D`, `DrawTriangle3D`, `DrawTriangleStrip3D`, `DrawCylinder`, `DrawCylinderEx`, `DrawCylinderWires`, `DrawCylinderWiresEx`, `DrawCapsule`, `DrawCapsuleWires`, `DrawRay`, `DrawModelWires`, `DrawModelWiresEx`, `DrawModelPoints`, `DrawModelPointsEx`, `DrawBillboard`, `DrawBillboardRec`, `DrawBillboardPro`, `UpdateMeshBuffer`, `DrawMeshInstanced`, `GenMeshTangents`, `ExportMesh`, `ExportMeshAsCode`, `GenMeshPoly`, `GenMeshHemiSphere`, `GenMeshCylinder`, `GenMeshCone`, `GenMeshTorus`, `GenMeshKnot`, `GenMeshHeightmap`, `GenMeshCubicmap`, `LoadMaterials`, `IsMaterialValid`, `UnloadMaterial`, `LoadModelAnimations`, `UpdateModelAnimation`, `UpdateModelAnimationBones`, `UnloadModelAnimation`, `UnloadModelAnimations`, `IsModelAnimationValid`, `GetRayCollisionQuad`.

## Raymath

*class* in [`ray/src/helix/ray/Raymath.hx`](../../ray/src/helix/ray/Raymath.hx), `import helix.ray.Raymath;`

Provides raymath's API, as raylib 5.5's `raymath.h` names it: vectors, matrices and quaternions, and `Clamp`, `Lerp` and the like. As in raylib, it is apart from `Raylib`, so a program that uses it imports it too:

```haxe
import helix.ray.Raylib.*;
import helix.ray.Raymath.*;
```

What raymath has and helix-ray doesn't refuses to compile, naming itself.

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
- `MatrixInvert`: Returns a matrix inverted.
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
- `MatrixRotateXYZ`: Returns rotations about x, then y, then z.
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
- `QuaternionFromVector3ToVector3`: Returns the rotation turning one direction to another.
  - `from`: The direction turned from, of length 1.
  - `to`: The direction turned to, of length 1.
  - returns: The quaternion.
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
- `MatrixDecompose`: Splits a transform matrix into its translation, rotation and scale; the scale negated when the matrix mirrors, the rotation the identity when it flattens.
  - `mat`: The matrix.
  - `translation`: Set to its translation.
  - `rotation`: Set to its rotation.
  - `scale`: Set to its scale.

## Rectangle

*class* in [`ray/src/helix/ray/Rectangle.hx`](../../ray/src/helix/ray/Rectangle.hx), `import helix.ray.Rectangle;`

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

*class* in [`ray/src/helix/ray/RenderTexture.hx`](../../ray/src/helix/ray/RenderTexture.hx), `import helix.ray.RenderTexture;`

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

*typedef* in [`ray/src/helix/ray/RenderTexture2D.hx`](../../ray/src/helix/ray/RenderTexture2D.hx), `import helix.ray.RenderTexture2D;`

raylib's `RenderTexture2D`, the same as `RenderTexture`.

An alias of `RenderTexture`.

## Rlgl

*class* in [`ray/src/helix/ray/Rlgl.hx`](../../ray/src/helix/ray/Rlgl.hx), `import helix.ray.Rlgl;`

Provides rlgl's API, as raylib 5.5's `rlgl.h` names it: the matrix stack, immediate drawing (`rlBegin`, `rlVertex3f`, `rlEnd`) and render state. As in raylib, it is apart from `Raylib`, so a program that uses it imports it too:

```haxe
import helix.ray.Raylib.*;
import helix.ray.Rlgl.*;
```

rlgl's GPU objects (vertex arrays and buffers, framebuffers, GL ids) aren't here: helix-ray draws through helix-platform, which has no GL. What rlgl has and helix-ray doesn't refuses to compile, naming itself.

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
static function rlDrawRenderBatchActive():Void
static function rlCheckRenderBatchLimit(vCount:Int):Bool
```

- `rlMatrixMode`: Chooses the matrix the next matrix calls change: `RL_MODELVIEW`, the view (or, between `rlPushMatrix` and `rlPopMatrix`, the transform the next vertices are moved by), or `RL_PROJECTION`.
  - `mode`: The matrix (`RL_MODELVIEW` or `RL_PROJECTION`; `RL_TEXTURE` changes nothing).
- `rlPushMatrix`: Saves the current matrix, to go back to with `rlPopMatrix`. In `RL_MODELVIEW`, the matrix calls until then move the vertices drawn after them.
  - throws `String`: More than 32 saved at once, as rlgl allows.
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
- `rlGetCullDistanceNear`: Returns the near plane rlgl's cameras use, 0.01.
  - returns: The distance.
- `rlGetCullDistanceFar`: Returns the far plane rlgl's cameras use, 1000.
  - returns: The distance.
- `rlBegin`: Starts vertices: each 2 a line, 3 a triangle or 4 a quad, until `rlEnd`.
  - `mode`: `RL_LINES`, `RL_TRIANGLES` or `RL_QUADS`.
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
- `rlNormal3f`: Sets the next vertices' normal.
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
- `rlSetTexture`: Sets the texture the next vertices draw with.
  - `id`: The texture's id (`Texture2D.id`), or 0 for none.
- `rlSetBlendMode`: Sets how the next draws blend, as `BeginBlendMode` does.
  - `mode`: The mode (`RL_BLEND_*`, the same as `BLEND_*`).
- `rlDrawRenderBatchActive`: Draws what is drawn so far before what comes next. Draws here are kept in the order they are asked for, so it changes nothing that is seen.
- `rlCheckRenderBatchLimit`: Returns whether the next vertices would overflow rlgl's batch, which it then draws first. Draws here have no such limit.
  - `vCount`: The vertices.
  - returns: False.

### Not supported in helix-ray

Each of these is raylib's name, and a call to it doesn't compile, saying why and what to use instead.

`rlEnableVertexArray`, `rlDisableVertexArray`, `rlEnableVertexBuffer`, `rlDisableVertexBuffer`, `rlEnableVertexBufferElement`, `rlDisableVertexBufferElement`, `rlEnableVertexAttribute`, `rlDisableVertexAttribute`, `rlEnableStatePointer`, `rlDisableStatePointer`, `rlActiveTextureSlot`, `rlEnableTexture`, `rlDisableTexture`, `rlEnableTextureCubemap`, `rlDisableTextureCubemap`, `rlTextureParameters`, `rlCubemapParameters`, `rlEnableShader`, `rlDisableShader`, `rlEnableFramebuffer`, `rlDisableFramebuffer`, `rlGetActiveFramebuffer`, `rlActiveDrawBuffers`, `rlBlitFramebuffer`, `rlBindFramebuffer`, `rlCheckErrors`, `rlLoadExtensions`, `rlGetVersion`, `rlGetTextureIdDefault`, `rlGetShaderIdDefault`, `rlGetShaderLocsDefault`, `rlLoadRenderBatch`, `rlUnloadRenderBatch`, `rlDrawRenderBatch`, `rlSetRenderBatchActive`, `rlLoadVertexArray`, `rlLoadVertexBuffer`, `rlLoadVertexBufferElement`, `rlUpdateVertexBuffer`, `rlUpdateVertexBufferElements`, `rlUnloadVertexArray`, `rlUnloadVertexBuffer`, `rlSetVertexAttribute`, `rlSetVertexAttributeDivisor`, `rlSetVertexAttributeDefault`, `rlDrawVertexArray`, `rlDrawVertexArrayElements`, `rlDrawVertexArrayInstanced`, `rlDrawVertexArrayElementsInstanced`, `rlLoadTexture`, `rlLoadTextureDepth`, `rlLoadTextureCubemap`, `rlUpdateTexture`, `rlGetGlTextureFormats`, `rlUnloadTexture`, `rlGenTextureMipmaps`, `rlReadTexturePixels`, `rlReadScreenPixels`, `rlLoadFramebuffer`, `rlFramebufferAttach`, `rlFramebufferComplete`, `rlUnloadFramebuffer`, `rlLoadShaderCode`, `rlCompileShader`, `rlLoadShaderProgram`, `rlUnloadShaderProgram`, `rlGetLocationUniform`, `rlGetLocationAttrib`, `rlSetUniform`, `rlSetUniformMatrix`, `rlSetUniformMatrices`, `rlSetUniformSampler`, `rlSetShader`, `rlLoadComputeShaderProgram`, `rlComputeShaderDispatch`, `rlLoadShaderBuffer`, `rlUnloadShaderBuffer`, `rlUpdateShaderBuffer`, `rlBindShaderBuffer`, `rlReadShaderBuffer`, `rlCopyShaderBuffer`, `rlGetShaderBufferSize`, `rlBindImageTexture`, `rlLoadDrawCube`, `rlLoadDrawQuad`.

### Not in helix-ray yet

Each of these is raylib's name, and a call to it doesn't compile, saying so.

`rlViewport`, `rlSetClipPlanes`, `rlEnableColorBlend`, `rlDisableColorBlend`, `rlEnableDepthTest`, `rlDisableDepthTest`, `rlEnableDepthMask`, `rlDisableDepthMask`, `rlEnableBackfaceCulling`, `rlDisableBackfaceCulling`, `rlColorMask`, `rlSetCullFace`, `rlEnableScissorTest`, `rlDisableScissorTest`, `rlScissor`, `rlEnableWireMode`, `rlEnablePointMode`, `rlDisableWireMode`, `rlSetLineWidth`, `rlGetLineWidth`, `rlEnableSmoothLines`, `rlDisableSmoothLines`, `rlEnableStereoRender`, `rlDisableStereoRender`, `rlIsStereoRenderEnabled`, `rlClearColor`, `rlClearScreenBuffers`, `rlSetBlendFactors`, `rlSetBlendFactorsSeparate`, `rlglInit`, `rlglClose`, `rlSetFramebufferWidth`, `rlGetFramebufferWidth`, `rlSetFramebufferHeight`, `rlGetFramebufferHeight`, `rlGetPixelFormatName`, `rlGetMatrixProjectionStereo`, `rlGetMatrixViewOffsetStereo`, `rlSetMatrixProjectionStereo`, `rlSetMatrixViewOffsetStereo`.

## Shader

*class* in [`ray/src/helix/ray/Shader.hx`](../../ray/src/helix/ray/Shader.hx), `import helix.ray.Shader;`

Represents raylib's `Shader`: a program, made by `Raylib.LoadShader` or `Raylib.LoadShaderFromMemory`, and the locations of what it declares.

```haxe
var id(default, null):Int
var locs(default, null):Array<Int>
```

- `id`: Gets the program's handle, 0 for none.
- `locs`: Gets the locations of the values raylib sets itself, by `SHADER_LOC_*`, -1 for each it doesn't declare. A program may set them, as raylib's do; values are found by name here, so they change nothing.

## Sound

*class* in [`ray/src/helix/ray/Sound.hx`](../../ray/src/helix/ray/Sound.hx), `import helix.ray.Sound;`

Represents raylib's `Sound`: a sound held whole, played by `Raylib.PlaySound`, over helix-services' `Audio`.

```haxe
var frameCount(default, null):Int
```

- `frameCount`: Gets the number of frames, at 44100 a second; 0 until the sound is loaded.

## Texture

*typedef* in [`ray/src/helix/ray/Texture.hx`](../../ray/src/helix/ray/Texture.hx), `import helix.ray.Texture;`

raylib's `Texture`, the same as `Texture2D`.

An alias of `Texture2D`.

## Texture2D

*class* in [`ray/src/helix/ray/Texture2D.hx`](../../ray/src/helix/ray/Texture2D.hx), `import helix.ray.Texture2D;`

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
- `format`: Gets the pixel format, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8` for every texture loaded here.

## TextureCubemap

*typedef* in [`ray/src/helix/ray/TextureCubemap.hx`](../../ray/src/helix/ray/TextureCubemap.hx), `import helix.ray.TextureCubemap;`

raylib's `TextureCubemap` (raylib.h): TextureCubemap, same as Texture.

An alias of `Texture`.

## Transform

*class* in [`ray/src/helix/ray/Transform.hx`](../../ray/src/helix/ray/Transform.hx), `import helix.ray.Transform;`

raylib's `Transform` (raylib.h): not in helix-ray yet; its fields are raylib's. Transform, vertex transformation data.

```haxe
function new()
var translation:Vector3
var rotation:Quaternion
var scale:Vector3
```

- `new`: Creates one, its fields zero, empty or null.
- `translation`: Translation.
- `rotation`: Rotation.
- `scale`: Scale.

## Vector2

*class* in [`ray/src/helix/ray/Vector2.hx`](../../ray/src/helix/ray/Vector2.hx), `import helix.ray.Vector2;`

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

*class* in [`ray/src/helix/ray/Vector3.hx`](../../ray/src/helix/ray/Vector3.hx), `import helix.ray.Vector3;`

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

*class* in [`ray/src/helix/ray/Vector4.hx`](../../ray/src/helix/ray/Vector4.hx), `import helix.ray.Vector4;`

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

*class* in [`ray/src/helix/ray/VrDeviceInfo.hx`](../../ray/src/helix/ray/VrDeviceInfo.hx), `import helix.ray.VrDeviceInfo;`

raylib's `VrDeviceInfo` (raylib.h): not in helix-ray yet; its fields are raylib's. VrDeviceInfo, Head-Mounted-Display device parameters.

```haxe
function new()
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

- `new`: Creates one, its fields zero, empty or null.
- `hResolution`: Horizontal resolution in pixels.
- `vResolution`: Vertical resolution in pixels.
- `hScreenSize`: Horizontal size in meters.
- `vScreenSize`: Vertical size in meters.
- `eyeToScreenDistance`: Distance between eye and display in meters.
- `lensSeparationDistance`: Lens separation distance in meters.
- `interpupillaryDistance`: IPD (distance between pupils) in meters.
- `lensDistortionValues`: Lens distortion constant parameters.
- `chromaAbCorrection`: Chromatic aberration correction parameters.

## VrStereoConfig

*class* in [`ray/src/helix/ray/VrStereoConfig.hx`](../../ray/src/helix/ray/VrStereoConfig.hx), `import helix.ray.VrStereoConfig;`

raylib's `VrStereoConfig` (raylib.h): not in helix-ray yet; its fields are raylib's. VrStereoConfig, VR stereo rendering configuration for simulator.

```haxe
function new()
var projection:Array<Matrix>
var viewOffset:Array<Matrix>
var leftLensCenter:Array<Float>
var rightLensCenter:Array<Float>
var leftScreenCenter:Array<Float>
var rightScreenCenter:Array<Float>
var scale:Array<Float>
var scaleIn:Array<Float>
```

- `new`: Creates one, its fields zero, empty or null.
- `projection`: VR projection matrices (per eye).
- `viewOffset`: VR view offset matrices (per eye).
- `leftLensCenter`: VR left lens center.
- `rightLensCenter`: VR right lens center.
- `leftScreenCenter`: VR left screen center.
- `rightScreenCenter`: VR right screen center.
- `scale`: VR distortion scale.
- `scaleIn`: VR distortion scale in.

## Wave

*class* in [`ray/src/helix/ray/Wave.hx`](../../ray/src/helix/ray/Wave.hx), `import helix.ray.Wave;`

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
