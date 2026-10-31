# helix.ray

[Back to the index](README.md)

## AudioStream

*class* in [`ray/src/helix/ray/AudioStream.hx`](../../ray/src/helix/ray/AudioStream.hx), `import helix.ray.AudioStream;`

raylib's `AudioStream` (raylib.h): not in helix-ray yet; its fields are raylib's. AudioStream, custom audio stream.

```haxe
function new()
var buffer:Dynamic
var processor:Dynamic
var sampleRate:Int
var sampleSize:Int
var channels:Int
```

- `new`: Creates one, its fields zero, empty or null.
- `buffer`: Pointer to internal data used by the audio system.
- `processor`: Pointer to internal data processor, useful for audio effects.
- `sampleRate`: Frequency (samples per second).
- `sampleSize`: Bit depth (bits per sample): 8, 16, 32 (24 not supported).
- `channels`: Number of channels (1-mono, 2-stereo, ...).

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

raylib's `FilePathList` (raylib.h): not in helix-ray yet; its fields are raylib's. File path list.

```haxe
function new()
var capacity:Int
var count:Int
var paths:Array<String>
```

- `new`: Creates one, its fields zero, empty or null.
- `capacity`: Filepaths max entries.
- `count`: Filepaths entries count.
- `paths`: Filepaths entries.

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

raylib's `Image` (raylib.h): not in helix-ray yet; its fields are raylib's. Image, pixel data stored in CPU memory (RAM).

```haxe
function new()
var data:Dynamic
var width:Int
var height:Int
var mipmaps:Int
var format:Int
```

- `new`: Creates one, its fields zero, empty or null.
- `data`: Image raw data.
- `width`: Image base width.
- `height`: Image base height.
- `mipmaps`: Mipmap levels, 1 by default.
- `format`: Data format (PixelFormat type).

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
var frameCount(default, null):Int
```

- `looping`: Gets or sets whether it starts again from its beginning when it ends; true until set, as raylib's.
- `frameCount`: Gets the number of frames: 0 here, as the stream doesn't tell its length.

## NPatchInfo

*class* in [`ray/src/helix/ray/NPatchInfo.hx`](../../ray/src/helix/ray/NPatchInfo.hx), `import helix.ray.NPatchInfo;`

raylib's `NPatchInfo` (raylib.h): not in helix-ray yet; its fields are raylib's. NPatchInfo, n-patch layout info.

```haxe
function new()
var source:Rectangle
var left:Int
var top:Int
var right:Int
var bottom:Int
var layout:Int
```

- `new`: Creates one, its fields zero, empty or null.
- `source`: Texture source rectangle.
- `left`: Left border offset.
- `top`: Top border offset.
- `right`: Right border offset.
- `bottom`: Bottom border offset.
- `layout`: Layout of the n-patch: 3x3, 1x3 or 3x1.

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

A program's loop is raylib's, `while (!WindowShouldClose()) { BeginDrawing(); ...; EndDrawing(); }`; in a page its body runs once a frame. A page can't wait for a file, so on every target files are loaded by helix-ray's own `...Async` loads; raylib's `LoadTexture`, `LoadModel`, `LoadSound`, `LoadFileData` and `LoadFileText` don't compile, naming the load to use. A file loaded twice is shared, and goes to the GPU when first drawn. `SaveFileText` writes are kept across runs. Shaders are raylib's GLSL, compiled as the program builds, so `LoadShader` names its files with constants. raymath's functions are `Raymath`'s, imported apart as raylib includes `raymath.h`. Its functions are written in files by raylib's modules (`helix.ray.raylib`) and listed here by module; what raylib has and helix-ray doesn't refuses to compile, naming itself.

### Keys (KeyboardKey)

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

### Gamepad axes (GamepadAxis)

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

### Window flags (ConfigFlags)

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

### Gestures (Gesture)

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

### Material maps (MaterialMapIndex)

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

### Shader locations (ShaderLocationIndex)

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

### Shader value types (ShaderUniformDataType)

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

### Camera modes (CameraMode)

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

### Camera projections (CameraProjection)

```haxe
static inline var CAMERA_PERSPECTIVE:Int
static inline var CAMERA_ORTHOGRAPHIC:Int
```

- `CAMERA_PERSPECTIVE`: Perspective projection.
- `CAMERA_ORTHOGRAPHIC`: Orthographic projection.

### Texture filters (TextureFilter)

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

### Log levels (TraceLogLevel)

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
static inline var MATERIAL_MAP_DIFFUSE:Int
static inline var MATERIAL_MAP_SPECULAR:Int
static inline var SHADER_LOC_MAP_DIFFUSE:Int
static inline var SHADER_LOC_MAP_SPECULAR:Int
static inline var MAX_MATERIAL_MAPS:Int
static inline var PIXELFORMAT_UNCOMPRESSED_R8G8B8A8:Int
static inline var PI:Float
static inline var DEG2RAD:Float
static inline var RAD2DEG:Float
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
- `MATERIAL_MAP_DIFFUSE`: The diffuse map, the same as `MATERIAL_MAP_ALBEDO`.
- `MATERIAL_MAP_SPECULAR`: The specular map, the same as `MATERIAL_MAP_METALNESS`.
- `SHADER_LOC_MAP_DIFFUSE`: The diffuse texture's location, the same as `SHADER_LOC_MAP_ALBEDO`.
- `SHADER_LOC_MAP_SPECULAR`: The specular texture's location, the same as `SHADER_LOC_MAP_METALNESS`.
- `MAX_MATERIAL_MAPS`: The number of a material's maps.
- `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`: The pixel format of every texture loaded here: 8-bit red, green, blue and alpha.
- `PI`: Pi.
- `DEG2RAD`: Degrees to radians.
- `RAD2DEG`: Radians to degrees.

### rcore: the window and frame, input, files, cameras and shaders (raylib/RCore.hx)

```haxe
static function InitWindow(width:Int, height:Int, title:String):Void
static function CloseWindow():Void
static function WindowShouldClose():Bool
static function IsWindowReady():Bool
static function IsWindowResized():Bool
static function SetWindowTitle(title:String):Void
static function SetWindowSize(width:Int, height:Int):Void
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
static function GetMouseWheelMove():Float
static function GetTouchPointCount():Int
static function GetTouchPosition(index:Int):Vector2
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
static function SetLoadFileDataCallback(callback:Null<(fileName:String) -> Null<haxe.io.Bytes>>):Void
static function SetSaveFileDataCallback(callback:Null<(fileName:String, data:haxe.io.Bytes, dataSize:Int) -> Bool>):Void
static function SetLoadFileTextCallback(callback:Null<(fileName:String) -> Null<String>>):Void
static function SetSaveFileTextCallback(callback:Null<(fileName:String, text:String) -> Bool>):Void
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
static function LoadShaderDefault():Shader
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
- `GetMousePosition`: Returns the mouse's position, in the screen's pixels; the first finger's while one is down.
  - returns: The position.
- `GetMouseWheelMove`: Returns how far the wheel turned this frame, the larger of its two directions; away from the player is positive.
  - returns: The notches.
- `GetTouchPointCount`: Returns the number of fingers down.
  - returns: The count.
- `GetTouchPosition`: Returns a finger's position, in the screen's pixels.
  - `index`: Which finger, 0 for the first down.
  - returns: The position, or (0, 0) when fewer are down.
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
- `SetLoadFileDataCallback`: Reads files through the program from now on: every load raylib makes of a file (textures, models, sounds, music, data) asks it first, and a file it doesn't have (null) is read as it would be. In a page, a texture's or model's images still decode only asynchronously, so `LoadTextureAsync` and `LoadModelAsync` load those it gives.
  - `callback`: Returns a file's bytes, or null; null for none.
- `SetSaveFileDataCallback`: Writes files through the program from now on (`SaveFileData`).
  - `callback`: Writes a file's bytes, returning whether it did; null for none.
- `SetLoadFileTextCallback`: Reads text files through the program from now on (`LoadFileTextAsync`).
  - `callback`: Returns a file's text, or null; null for none.
- `SetSaveFileTextCallback`: Writes text files through the program from now on (`SaveFileText`).
  - `callback`: Writes a file's text, returning whether it did; null for none.
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
- `LoadShaderDefault`: Returns raylib's default shader.
  - returns: The shader.
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

### rshapes: 2D shapes and collisions (raylib/RShapes.hx)

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

### rtextures: textures, render textures and colors (raylib/RTextures.hx)

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
static function LoadRenderTexture(width:Int, height:Int):RenderTexture2D
static function IsRenderTextureValid(target:RenderTexture2D):Bool
static function UnloadRenderTexture(target:RenderTexture2D):Void
static function BeginTextureMode(target:RenderTexture2D):Void
static function EndTextureMode():Void
static function SetTextureFilter(texture:Texture2D, filter:Int):Void
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
- `SetTextureFilter`: Sets how a texture is sampled when drawn larger or smaller. Textures here are sampled as `TEXTURE_FILTER_POINT`, whatever is set.
  - `texture`: The texture.
  - `filter`: The filter (`TEXTURE_FILTER_*`).

### rtext: text (raylib/RText.hx)

```haxe
static function DrawText(text:String, posX:Int, posY:Int, fontSize:Int, color:Color):Void
static function MeasureText(text:String, fontSize:Int):Int
static function DrawFPS(posX:Int, posY:Int):Void
static function TextFormat(text:String, args:haxe.extern.Rest<Dynamic>):String
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
- `DrawFPS`: Draws the frames a second, as "60 FPS", in green.
  - `posX`: The left edge.
  - `posY`: The top edge.
- `TextFormat`: Formats text as C's `printf` does. It takes `%d` and `%i`, `%u`, `%f` and `%F` (6 places unless a precision is given, as in `%.2f`), `%e`, `%g`, `%x`, `%X`, `%o`, `%c` (a character code), `%s` and `%%`. It also takes C's flags (`-`, `0`, `+`, space, `#`), widths and precisions, as in `%5d`, `%-8s`, `%03i` and `%*d`. C's length modifiers (`l`, `ll`, `h`, `z`) are read and ignored.
  - `text`: The format.
  - `args`: The values, one for each conversion.
  - returns: The text.

### rmodels: 3D shapes, models, meshes and rays (raylib/RModels.hx)

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

### raudio: sound (raylib/RAudio.hx)

```haxe
static function InitAudioDevice():Void
static function CloseAudioDevice():Void
static function IsAudioDeviceReady():Bool
static function SetMasterVolume(volume:Float):Void
static function GetMasterVolume():Float
static function UnloadSound(sound:Sound):Void
static function IsSoundValid(sound:Sound):Bool
static function PlaySound(sound:Sound):Void
static function StopSound(sound:Sound):Void
static function IsSoundPlaying(sound:Sound):Bool
static function SetSoundVolume(sound:Sound, volume:Float):Void
static function SetSoundPitch(sound:Sound, pitch:Float):Void
static function SetSoundPan(sound:Sound, pan:Float):Void
static function LoadMusicStream(fileName:String):Music
static function IsMusicValid(music:Music):Bool
static function UnloadMusicStream(music:Music):Void
static function PlayMusicStream(music:Music):Void
static function IsMusicStreamPlaying(music:Music):Bool
static function UpdateMusicStream(music:Music):Void
static function StopMusicStream(music:Music):Void
static function PauseMusicStream(music:Music):Void
static function ResumeMusicStream(music:Music):Void
static function SetMusicVolume(music:Music, volume:Float):Void
static function SetMusicPitch(music:Music, pitch:Float):Void
static function SetMusicPan(music:Music, pan:Float):Void
```

- `InitAudioDevice`: Opens the audio output, with helix-services' `Audio` over it. In a page it plays once the player's first press lets it.
- `CloseAudioDevice`: Closes the audio output, stopping and unloading every sound.
- `IsAudioDeviceReady`: Returns whether the audio output is open.
  - returns: True after `InitAudioDevice`, where the platform has an output.
- `SetMasterVolume`: Sets the volume of every sound.
  - `volume`: 0 (silent) to 1.
- `GetMasterVolume`: Returns the volume of every sound.
  - returns: 0 (silent) to 1.
- `UnloadSound`: Frees a sound, stopping it: one load of its file, the decoded sound with the last.
  - `sound`: The sound.
- `IsSoundValid`: Returns whether a sound was loaded.
  - `sound`: The sound.
  - returns: True once it is decoded.
- `PlaySound`: Plays a sound from its start, restarting it when it is already playing.
  - `sound`: The sound.
- `StopSound`: Stops a sound.
  - `sound`: The sound.
- `IsSoundPlaying`: Returns whether a sound is playing.
  - `sound`: The sound.
  - returns: True while it plays.
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
- `IsMusicValid`: Returns whether music was opened, or is still opening.
  - `music`: The music.
  - returns: False once its file couldn't be opened.
- `UnloadMusicStream`: Stops music and closes it.
  - `music`: The music.
- `PlayMusicStream`: Plays music from its start, looping while its `looping` is true.
  - `music`: The music.
- `IsMusicStreamPlaying`: Returns whether music is playing, or will once it opens.
  - `music`: The music.
  - returns: True while it plays, paused or not.
- `UpdateMusicStream`: Keeps music playing. raylib's programs call it each frame; here the stream feeds itself, so it does nothing.
  - `music`: The music.
- `StopMusicStream`: Stops music.
  - `music`: The music.
- `PauseMusicStream`: Pauses music where it is.
  - `music`: The music.
- `ResumeMusicStream`: Resumes paused music.
  - `music`: The music.
- `SetMusicVolume`: Sets music's volume.
  - `music`: The music.
  - `volume`: 0 (silent) to 1.
- `SetMusicPitch`: Sets music's pitch.
  - `music`: The music.
  - `pitch`: 1 for as recorded.
- `SetMusicPan`: Sets where music is heard.
  - `music`: The music.
  - `pan`: 0 for left, 0.5 the middle, 1 for right, as raylib's.

### helix-ray's own: loading in a page (raylib/HelixRay.hx)

```haxe
static function LoadTextureAsync(fileName:String, loaded:Texture2D -> Void, ?failed:String -> Void):Void
static function LoadModelAsync(fileName:String, loaded:Model -> Void, ?failed:String -> Void):Void
static function LoadSoundAsync(fileName:String, loaded:Sound -> Void, ?failed:String -> Void):Void
static function LoadFileTextAsync(fileName:String, loaded:String -> Void, ?failed:String -> Void):Void
static function LoadFileDataAsync(fileName:String, loaded:haxe.io.Bytes -> Void, ?failed:String -> Void):Void
static function FileExistsAsync(fileName:String, answer:Bool -> Void):Void
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

### raylib's loads, which wait for a file: each refuses to compile, naming the load to use

```haxe
static macro function FileExists(fileName:String):Bool
static macro function LoadFileText(fileName:String):ExprOf<Null<String>>
static macro function LoadFileData(fileName:String):ExprOf<Null<haxe.io.Bytes>>
static macro function LoadTexture(fileName:String):Texture2D
static macro function LoadModel(fileName:String):Model
static macro function LoadSound(fileName:String):Sound
```

- `FileExists`: raylib's check for a file, which waits for the answer. A page can't wait, so a call doesn't compile on any target: `FileExistsAsync` answers it.
- `LoadFileText`: raylib's text file read, which waits for the file. A page can't wait, so a call doesn't compile on any target: `LoadFileTextAsync` reads it.
- `LoadFileData`: raylib's file read, which waits for the file. A page can't wait, so a call doesn't compile on any target: `LoadFileDataAsync` reads it.
- `LoadTexture`: raylib's texture load, which waits for the file. A page can't wait, so a call doesn't compile on any target: `LoadTextureAsync` loads it.
- `LoadModel`: raylib's model load, which waits for the file. A page can't wait, so a call doesn't compile on any target: `LoadModelAsync` loads it.
- `LoadSound`: raylib's sound load, which waits for the file. A page can't wait, so a call doesn't compile on any target: `LoadSoundAsync` loads it.

### Mouse cursor (MouseCursor), not written by hand

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

### Shader attribute data types (ShaderAttributeDataType), not written by hand

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

### Pixel formats (PixelFormat), not written by hand

```haxe
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

### Texture parameters: wrap mode (TextureWrap), not written by hand

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

### Cubemap layouts (CubemapLayout), not written by hand

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

### Font type, defines generation method (FontType), not written by hand

```haxe
static inline var FONT_DEFAULT:Int
static inline var FONT_BITMAP:Int
static inline var FONT_SDF:Int
```

- `FONT_DEFAULT`: Default font generation, anti-aliased.
- `FONT_BITMAP`: Bitmap font generation, no anti-aliasing.
- `FONT_SDF`: SDF font generation, requires external shader.

### Color blending modes (pre-defined) (BlendMode), not written by hand

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

### N-patch layout (NPatchLayout), not written by hand

```haxe
static inline var NPATCH_NINE_PATCH:Int
static inline var NPATCH_THREE_PATCH_VERTICAL:Int
static inline var NPATCH_THREE_PATCH_HORIZONTAL:Int
```

- `NPATCH_NINE_PATCH`: Npatch layout: 3x3 tiles.
- `NPATCH_THREE_PATCH_VERTICAL`: Npatch layout: 1x3 tiles.
- `NPATCH_THREE_PATCH_HORIZONTAL`: Npatch layout: 3x1 tiles.

### Shaders, compiled as the program builds

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

### Not in helix-ray yet

Each of these is raylib's name, and a call to it doesn't compile, saying so.

From `raylib.h`: `IsWindowFullscreen`, `IsWindowHidden`, `IsWindowMinimized`, `IsWindowMaximized`, `IsWindowFocused`, `ToggleFullscreen`, `ToggleBorderlessWindowed`, `MaximizeWindow`, `MinimizeWindow`, `RestoreWindow`, `SetWindowIcon`, `SetWindowIcons`, `SetWindowPosition`, `SetWindowMonitor`, `SetWindowMinSize`, `SetWindowMaxSize`, `SetWindowOpacity`, `SetWindowFocused`, `GetWindowHandle`, `GetMonitorCount`, `GetCurrentMonitor`, `GetMonitorPosition`, `GetMonitorWidth`, `GetMonitorHeight`, `GetMonitorPhysicalWidth`, `GetMonitorPhysicalHeight`, `GetMonitorRefreshRate`, `GetWindowPosition`, `GetWindowScaleDPI`, `GetMonitorName`, `SetClipboardText`, `GetClipboardText`, `GetClipboardImage`, `EnableEventWaiting`, `DisableEventWaiting`, `ShowCursor`, `HideCursor`, `IsCursorHidden`, `EnableCursor`, `DisableCursor`, `IsCursorOnScreen`, `BeginVrStereoMode`, `EndVrStereoMode`, `LoadVrStereoConfig`, `UnloadVrStereoConfig`, `SwapScreenBuffer`, `PollInputEvents`, `LoadRandomSequence`, `UnloadRandomSequence`, `TakeScreenshot`, `OpenURL`, `MemAlloc`, `MemRealloc`, `MemFree`, `ExportDataAsCode`, `DirectoryExists`, `IsFileExtension`, `GetFileLength`, `GetFileExtension`, `GetFileName`, `GetFileNameWithoutExt`, `GetDirectoryPath`, `GetPrevDirectoryPath`, `GetWorkingDirectory`, `GetApplicationDirectory`, `MakeDirectory`, `ChangeDirectory`, `IsPathFile`, `IsFileNameValid`, `LoadDirectoryFiles`, `LoadDirectoryFilesEx`, `UnloadDirectoryFiles`, `IsFileDropped`, `LoadDroppedFiles`, `UnloadDroppedFiles`, `GetFileModTime`, `CompressData`, `DecompressData`, `EncodeDataBase64`, `DecodeDataBase64`, `ComputeCRC32`, `ComputeMD5`, `ComputeSHA1`, `LoadAutomationEventList`, `UnloadAutomationEventList`, `ExportAutomationEventList`, `SetAutomationEventList`, `SetAutomationEventBaseFrame`, `StartAutomationEventRecording`, `StopAutomationEventRecording`, `PlayAutomationEvent`, `SetGamepadMappings`, `SetGamepadVibration`, `SetMousePosition`, `SetMouseOffset`, `SetMouseScale`, `GetMouseWheelMoveV`, `SetMouseCursor`, `GetTouchPointId`, `UpdateCameraPro`, `LoadImage`, `LoadImageRaw`, `LoadImageAnim`, `LoadImageAnimFromMemory`, `LoadImageFromMemory`, `LoadImageFromTexture`, `LoadImageFromScreen`, `IsImageValid`, `UnloadImage`, `ExportImage`, `ExportImageToMemory`, `ExportImageAsCode`, `GenImageColor`, `GenImageGradientLinear`, `GenImageGradientRadial`, `GenImageGradientSquare`, `GenImageChecked`, `GenImageWhiteNoise`, `GenImagePerlinNoise`, `GenImageCellular`, `GenImageText`, `ImageCopy`, `ImageFromImage`, `ImageFromChannel`, `ImageText`, `ImageTextEx`, `ImageFormat`, `ImageToPOT`, `ImageCrop`, `ImageAlphaCrop`, `ImageAlphaClear`, `ImageAlphaMask`, `ImageAlphaPremultiply`, `ImageBlurGaussian`, `ImageKernelConvolution`, `ImageResize`, `ImageResizeNN`, `ImageResizeCanvas`, `ImageMipmaps`, `ImageDither`, `ImageFlipVertical`, `ImageFlipHorizontal`, `ImageRotate`, `ImageRotateCW`, `ImageRotateCCW`, `ImageColorTint`, `ImageColorInvert`, `ImageColorGrayscale`, `ImageColorContrast`, `ImageColorBrightness`, `ImageColorReplace`, `LoadImageColors`, `LoadImagePalette`, `UnloadImageColors`, `UnloadImagePalette`, `GetImageAlphaBorder`, `GetImageColor`, `ImageClearBackground`, `ImageDrawPixel`, `ImageDrawPixelV`, `ImageDrawLine`, `ImageDrawLineV`, `ImageDrawLineEx`, `ImageDrawCircle`, `ImageDrawCircleV`, `ImageDrawCircleLines`, `ImageDrawCircleLinesV`, `ImageDrawRectangle`, `ImageDrawRectangleV`, `ImageDrawRectangleRec`, `ImageDrawRectangleLines`, `ImageDrawTriangle`, `ImageDrawTriangleEx`, `ImageDrawTriangleLines`, `ImageDrawTriangleFan`, `ImageDrawTriangleStrip`, `ImageDraw`, `ImageDrawText`, `ImageDrawTextEx`, `LoadTextureFromImage`, `LoadTextureCubemap`, `UpdateTexture`, `UpdateTextureRec`, `GenTextureMipmaps`, `SetTextureWrap`, `DrawTextureNPatch`, `ColorIsEqual`, `ColorToInt`, `ColorToHSV`, `ColorFromHSV`, `ColorTint`, `ColorBrightness`, `ColorContrast`, `ColorAlphaBlend`, `ColorLerp`, `GetColor`, `GetPixelColor`, `SetPixelColor`, `GetPixelDataSize`, `GetFontDefault`, `LoadFont`, `LoadFontEx`, `LoadFontFromImage`, `LoadFontFromMemory`, `IsFontValid`, `LoadFontData`, `GenImageFontAtlas`, `UnloadFontData`, `UnloadFont`, `ExportFontAsCode`, `DrawTextEx`, `DrawTextPro`, `DrawTextCodepoint`, `DrawTextCodepoints`, `SetTextLineSpacing`, `MeasureTextEx`, `GetGlyphIndex`, `GetGlyphInfo`, `GetGlyphAtlasRec`, `LoadUTF8`, `UnloadUTF8`, `LoadCodepoints`, `UnloadCodepoints`, `GetCodepointCount`, `GetCodepoint`, `GetCodepointNext`, `GetCodepointPrevious`, `CodepointToUTF8`, `TextCopy`, `TextIsEqual`, `TextLength`, `TextSubtext`, `TextReplace`, `TextInsert`, `TextJoin`, `TextSplit`, `TextAppend`, `TextFindIndex`, `TextToUpper`, `TextToLower`, `TextToPascal`, `TextToSnake`, `TextToCamel`, `TextToInteger`, `TextToFloat`, `DrawPoint3D`, `DrawCircle3D`, `DrawTriangle3D`, `DrawTriangleStrip3D`, `DrawCylinder`, `DrawCylinderEx`, `DrawCylinderWires`, `DrawCylinderWiresEx`, `DrawCapsule`, `DrawCapsuleWires`, `DrawRay`, `DrawModelWires`, `DrawModelWiresEx`, `DrawModelPoints`, `DrawModelPointsEx`, `DrawBillboard`, `DrawBillboardRec`, `DrawBillboardPro`, `UpdateMeshBuffer`, `DrawMeshInstanced`, `GenMeshTangents`, `ExportMesh`, `ExportMeshAsCode`, `GenMeshPoly`, `GenMeshHemiSphere`, `GenMeshCylinder`, `GenMeshCone`, `GenMeshTorus`, `GenMeshKnot`, `GenMeshHeightmap`, `GenMeshCubicmap`, `LoadMaterials`, `IsMaterialValid`, `UnloadMaterial`, `LoadModelAnimations`, `UpdateModelAnimation`, `UpdateModelAnimationBones`, `UnloadModelAnimation`, `UnloadModelAnimations`, `IsModelAnimationValid`, `GetRayCollisionQuad`, `LoadWave`, `LoadWaveFromMemory`, `IsWaveValid`, `LoadSoundFromWave`, `LoadSoundAlias`, `UpdateSound`, `UnloadWave`, `UnloadSoundAlias`, `ExportWave`, `ExportWaveAsCode`, `PauseSound`, `ResumeSound`, `WaveCopy`, `WaveCrop`, `WaveFormat`, `LoadWaveSamples`, `UnloadWaveSamples`, `LoadMusicStreamFromMemory`, `SeekMusicStream`, `GetMusicTimeLength`, `GetMusicTimePlayed`, `LoadAudioStream`, `IsAudioStreamValid`, `UnloadAudioStream`, `UpdateAudioStream`, `IsAudioStreamProcessed`, `PlayAudioStream`, `PauseAudioStream`, `ResumeAudioStream`, `IsAudioStreamPlaying`, `StopAudioStream`, `SetAudioStreamVolume`, `SetAudioStreamPitch`, `SetAudioStreamPan`, `SetAudioStreamBufferSizeDefault`, `SetAudioStreamCallback`, `AttachAudioStreamProcessor`, `DetachAudioStreamProcessor`, `AttachAudioMixedProcessor`, `DetachAudioMixedProcessor`.

## Raymath

*class* in [`ray/src/helix/ray/Raymath.hx`](../../ray/src/helix/ray/Raymath.hx), `import helix.ray.Raymath;`

Provides raymath's API, as raylib 5.5's `raymath.h` names it: vectors, matrices and quaternions, and `Clamp`, `Lerp` and the like. As in raylib, it is apart from `Raylib`, so a program that uses it imports it too:

```haxe
import helix.ray.Raylib.*;
import helix.ray.Raymath.*;
```

What raymath has and helix-ray doesn't refuses to compile, naming itself.

### Constants

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

### raymath: vectors, matrices and quaternions (raylib/RMath.hx)

```haxe
static function Clamp(value:Float, min:Float, max:Float):Float
static function Lerp(start:Float, end:Float, amount:Float):Float
static function Remap(value:Float, inputStart:Float, inputEnd:Float, outputStart:Float, outputEnd:Float):Float
static function Vector2Zero():Vector2
static function Vector2One():Vector2
static function Vector2Add(v1:Vector2, v2:Vector2):Vector2
static function Vector2Subtract(v1:Vector2, v2:Vector2):Vector2
static function Vector2Scale(v:Vector2, scale:Float):Vector2
static function Vector2Multiply(v1:Vector2, v2:Vector2):Vector2
static function Vector2Length(v:Vector2):Float
static function Vector2LengthSqr(v:Vector2):Float
static function Vector2Distance(v1:Vector2, v2:Vector2):Float
static function Vector2Normalize(v:Vector2):Vector2
static function Vector2Lerp(v1:Vector2, v2:Vector2, amount:Float):Vector2
static function Vector2ClampValue(v:Vector2, min:Float, max:Float):Vector2
static function Vector3Zero():Vector3
static function Vector3One():Vector3
static function Vector3Add(v1:Vector3, v2:Vector3):Vector3
static function Vector3Subtract(v1:Vector3, v2:Vector3):Vector3
static function Vector3Scale(v:Vector3, scalar:Float):Vector3
static function Vector3Multiply(v1:Vector3, v2:Vector3):Vector3
static function Vector3CrossProduct(v1:Vector3, v2:Vector3):Vector3
static function Vector3DotProduct(v1:Vector3, v2:Vector3):Float
static function Vector3Length(v:Vector3):Float
static function Vector3LengthSqr(v:Vector3):Float
static function Vector3Distance(v1:Vector3, v2:Vector3):Float
static function Vector3Normalize(v:Vector3):Vector3
static function Vector3Negate(v:Vector3):Vector3
static function Vector3Lerp(v1:Vector3, v2:Vector3, amount:Float):Vector3
static function Vector3Transform(v:Vector3, mat:Matrix):Vector3
static function Vector3RotateByAxisAngle(v:Vector3, axis:Vector3, angle:Float):Vector3
static function MatrixIdentity():Matrix
static function MatrixMultiply(left:Matrix, right:Matrix):Matrix
static function MatrixTranslate(x:Float, y:Float, z:Float):Matrix
static function MatrixScale(x:Float, y:Float, z:Float):Matrix
static function MatrixRotate(axis:Vector3, angle:Float):Matrix
static function MatrixRotateX(angle:Float):Matrix
static function MatrixRotateY(angle:Float):Matrix
static function MatrixRotateZ(angle:Float):Matrix
static function MatrixRotateXYZ(angle:Vector3):Matrix
static function MatrixInvert(mat:Matrix):Matrix
static function MatrixTranspose(mat:Matrix):Matrix
static function MatrixLookAt(eye:Vector3, target:Vector3, up:Vector3):Matrix
static function MatrixPerspective(fovY:Float, aspect:Float, nearPlane:Float, farPlane:Float):Matrix
static function MatrixOrtho(left:Float, right:Float, bottom:Float, top:Float, nearPlane:Float, farPlane:Float):Matrix
static function QuaternionIdentity():Quaternion
static function QuaternionFromAxisAngle(axis:Vector3, angle:Float):Quaternion
static function QuaternionFromEuler(pitch:Float, yaw:Float, roll:Float):Quaternion
static function QuaternionToMatrix(q:Quaternion):Matrix
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
- `Remap`: Returns a value moved from one range to another.
  - `value`: The value.
  - `inputStart`: The first range's start.
  - `inputEnd`: Its end.
  - `outputStart`: The second range's start.
  - `outputEnd`: Its end.
  - returns: The value in the second range.
- `Vector2Zero`: Returns (0, 0).
  - returns: The vector.
- `Vector2One`: Returns (1, 1).
  - returns: The vector.
- `Vector2Add`: Returns the sum of two vectors.
  - `v1`: One.
  - `v2`: The other.
  - returns: The sum.
- `Vector2Subtract`: Returns one vector less another.
  - `v1`: The first.
  - `v2`: The one taken from it.
  - returns: The difference.
- `Vector2Scale`: Returns a vector scaled.
  - `v`: The vector.
  - `scale`: The scale.
  - returns: The scaled vector.
- `Vector2Multiply`: Returns two vectors multiplied component by component.
  - `v1`: One.
  - `v2`: The other.
  - returns: The product.
- `Vector2Length`: Returns a vector's length.
  - `v`: The vector.
  - returns: The length.
- `Vector2LengthSqr`: Returns a vector's length squared.
  - `v`: The vector.
  - returns: The length squared.
- `Vector2Distance`: Returns the distance between two points.
  - `v1`: One.
  - `v2`: The other.
  - returns: The distance.
- `Vector2Normalize`: Returns a vector of length 1 in the same direction, or (0, 0) for (0, 0).
  - `v`: The vector.
  - returns: The direction.
- `Vector2Lerp`: Returns a point part of the way from one to another.
  - `v1`: The start.
  - `v2`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The point.
- `Vector2ClampValue`: Returns a vector with its length kept between two values.
  - `v`: The vector.
  - `min`: The least length.
  - `max`: The most length.
  - returns: The vector.
- `Vector3Zero`: Returns (0, 0, 0).
  - returns: The vector.
- `Vector3One`: Returns (1, 1, 1).
  - returns: The vector.
- `Vector3Add`: Returns the sum of two vectors.
  - `v1`: One.
  - `v2`: The other.
  - returns: The sum.
- `Vector3Subtract`: Returns one vector less another.
  - `v1`: The first.
  - `v2`: The one taken from it.
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
- `Vector3DotProduct`: Returns the dot product.
  - `v1`: One.
  - `v2`: The other.
  - returns: The product.
- `Vector3Length`: Returns a vector's length.
  - `v`: The vector.
  - returns: The length.
- `Vector3LengthSqr`: Returns a vector's length squared.
  - `v`: The vector.
  - returns: The length squared.
- `Vector3Distance`: Returns the distance between two points.
  - `v1`: One.
  - `v2`: The other.
  - returns: The distance.
- `Vector3Normalize`: Returns a vector of length 1 in the same direction, or the vector itself when its length is 0.
  - `v`: The vector.
  - returns: The direction.
- `Vector3Negate`: Returns a vector pointing the other way.
  - `v`: The vector.
  - returns: The negated vector.
- `Vector3Lerp`: Returns a point part of the way from one to another.
  - `v1`: The start.
  - `v2`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The point.
- `Vector3Transform`: Returns a point transformed by a matrix.
  - `v`: The point.
  - `mat`: The matrix.
  - returns: The transformed point.
- `Vector3RotateByAxisAngle`: Returns a vector turned about an axis.
  - `v`: The vector.
  - `axis`: The axis.
  - `angle`: The angle, in radians.
  - returns: The turned vector.
- `MatrixIdentity`: Returns the identity matrix.
  - returns: The matrix.
- `MatrixMultiply`: Returns two matrices multiplied: left, then right.
  - `left`: The first.
  - `right`: The second.
  - returns: The product.
- `MatrixTranslate`: Returns a translation.
  - `x`: Along x.
  - `y`: Along y.
  - `z`: Along z.
  - returns: The matrix.
- `MatrixScale`: Returns a scale.
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
- `MatrixInvert`: Returns a matrix inverted.
  - `mat`: The matrix.
  - returns: Its inverse.
- `MatrixTranspose`: Returns a matrix transposed.
  - `mat`: The matrix.
  - returns: Its transpose.
- `MatrixLookAt`: Returns a view looking from eye at target.
  - `eye`: Where from.
  - `target`: What at.
  - `up`: Up.
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
- `QuaternionIdentity`: Returns the identity quaternion.
  - returns: The quaternion.
- `QuaternionFromAxisAngle`: Returns the rotation about an axis as a quaternion.
  - `axis`: The axis.
  - `angle`: The angle, in radians.
  - returns: The quaternion.
- `QuaternionFromEuler`: Returns a rotation by Euler angles as a quaternion.
  - `pitch`: About x, in radians.
  - `yaw`: About y.
  - `roll`: About z.
  - returns: The quaternion.
- `QuaternionToMatrix`: Returns a quaternion's rotation as a matrix.
  - `q`: The quaternion.
  - returns: The matrix.

### Not in helix-ray yet

Each of these is raylib's name, and a call to it doesn't compile, saying so.

From `raymath.h`: `Normalize`, `Wrap`, `FloatEquals`, `Vector2AddValue`, `Vector2SubtractValue`, `Vector2DotProduct`, `Vector2DistanceSqr`, `Vector2Angle`, `Vector2LineAngle`, `Vector2Negate`, `Vector2Divide`, `Vector2Transform`, `Vector2Reflect`, `Vector2Min`, `Vector2Max`, `Vector2Rotate`, `Vector2MoveTowards`, `Vector2Invert`, `Vector2Clamp`, `Vector2Equals`, `Vector2Refract`, `Vector3AddValue`, `Vector3SubtractValue`, `Vector3Perpendicular`, `Vector3DistanceSqr`, `Vector3Angle`, `Vector3Divide`, `Vector3Project`, `Vector3Reject`, `Vector3OrthoNormalize`, `Vector3RotateByQuaternion`, `Vector3MoveTowards`, `Vector3CubicHermite`, `Vector3Reflect`, `Vector3Min`, `Vector3Max`, `Vector3Barycenter`, `Vector3Unproject`, `Vector3ToFloatV`, `Vector3Invert`, `Vector3Clamp`, `Vector3ClampValue`, `Vector3Equals`, `Vector3Refract`, `Vector4Zero`, `Vector4One`, `Vector4Add`, `Vector4AddValue`, `Vector4Subtract`, `Vector4SubtractValue`, `Vector4Length`, `Vector4LengthSqr`, `Vector4DotProduct`, `Vector4Distance`, `Vector4DistanceSqr`, `Vector4Scale`, `Vector4Multiply`, `Vector4Negate`, `Vector4Divide`, `Vector4Normalize`, `Vector4Min`, `Vector4Max`, `Vector4Lerp`, `Vector4MoveTowards`, `Vector4Invert`, `Vector4Equals`, `MatrixDeterminant`, `MatrixTrace`, `MatrixAdd`, `MatrixSubtract`, `MatrixRotateZYX`, `MatrixFrustum`, `MatrixToFloatV`, `QuaternionAdd`, `QuaternionAddValue`, `QuaternionSubtract`, `QuaternionSubtractValue`, `QuaternionLength`, `QuaternionNormalize`, `QuaternionInvert`, `QuaternionMultiply`, `QuaternionScale`, `QuaternionDivide`, `QuaternionLerp`, `QuaternionNlerp`, `QuaternionSlerp`, `QuaternionCubicHermiteSpline`, `QuaternionFromVector3ToVector3`, `QuaternionFromMatrix`, `QuaternionToAxisAngle`, `QuaternionToEuler`, `QuaternionTransform`, `QuaternionEquals`, `MatrixDecompose`.

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

raylib's `Wave` (raylib.h): not in helix-ray yet; its fields are raylib's. Wave, audio wave data.

```haxe
function new()
var frameCount:Int
var sampleRate:Int
var sampleSize:Int
var channels:Int
var data:Dynamic
```

- `new`: Creates one, its fields zero, empty or null.
- `frameCount`: Total number of frames (considering channels).
- `sampleRate`: Frequency (samples per second).
- `sampleSize`: Bit depth (bits per sample): 8, 16, 32 (24 not supported).
- `channels`: Number of channels (1-mono, 2-stereo, ...).
- `data`: Buffer data pointer.
