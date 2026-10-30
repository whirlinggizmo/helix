# helix.ray

[Back to the index](README.md)

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

## Material

*class* in [`ray/src/helix/ray/Material.hx`](../../ray/src/helix/ray/Material.hx), `import helix.ray.Material;`

Represents raylib's `Material`: a shader and its maps (`MATERIAL_MAP_*`); the diffuse map's texture and color are what a draw shows.

```haxe
function new(shader:Shader, maps:Array<MaterialMap>, ?params:Array<Float>)
var shader:Shader
var maps:Array<MaterialMap>
var params:Array<Float>
```

- `new`: Creates a material. Materials are made by `Raylib.LoadMaterialDefault` and `Raylib.LoadModel`.
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

Represents raylib's `Mesh`: vertices, and the indices of its triangles when it has them. `Raylib.UploadMesh` sends them to the GPU; `Raylib.LoadModel` and the `GenMesh*` functions do it themselves.

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

- `new`: Creates a model. Models are made by `Raylib.LoadModel` and `Raylib.LoadModelFromMesh`.
  - `meshes`: The meshes.
  - `materials`: The materials.
  - `meshMaterial`: Each mesh's material.
- `transform`: Gets or sets the transform applied before `DrawModel`'s position, rotation and scale.
- `meshCount`: Gets the number of meshes.
- `materialCount`: Gets the number of materials.
- `meshes`: Gets the meshes.
- `materials`: Gets the materials.
- `meshMaterial`: Gets the material of each mesh, by its index in `materials`.

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

A program's loop is raylib's, `while (!WindowShouldClose()) { BeginDrawing(); ...; EndDrawing(); }`; in a page its body runs once a frame. Natively a load reads its file when called, as raylib's does; a page loads before `main` the files its program names, and the `...Async` loads, helix-ray's own, bring in the rest. A file loaded twice is shared, and goes to the GPU when first drawn. `SaveFileText` writes are kept across runs. Shaders are raylib's GLSL, compiled as the program builds, so `LoadShader` names its files with constants. Its members are kept in files by raylib's modules (`helix.ray.raylib`); what raylib has and helix-ray doesn't refuses to compile, naming itself.

### Constants and colors

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
static inline var MOUSE_BUTTON_LEFT:Int
static inline var MOUSE_BUTTON_RIGHT:Int
static inline var MOUSE_BUTTON_MIDDLE:Int
static inline var MOUSE_BUTTON_SIDE:Int
static inline var MOUSE_BUTTON_EXTRA:Int
static inline var MOUSE_BUTTON_FORWARD:Int
static inline var MOUSE_BUTTON_BACK:Int
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
static inline var GAMEPAD_AXIS_LEFT_X:Int
static inline var GAMEPAD_AXIS_LEFT_Y:Int
static inline var GAMEPAD_AXIS_RIGHT_X:Int
static inline var GAMEPAD_AXIS_RIGHT_Y:Int
static inline var GAMEPAD_AXIS_LEFT_TRIGGER:Int
static inline var GAMEPAD_AXIS_RIGHT_TRIGGER:Int
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
static inline var SHADER_UNIFORM_FLOAT:Int
static inline var SHADER_UNIFORM_VEC2:Int
static inline var SHADER_UNIFORM_VEC3:Int
static inline var SHADER_UNIFORM_VEC4:Int
static inline var SHADER_UNIFORM_INT:Int
static inline var SHADER_UNIFORM_IVEC2:Int
static inline var SHADER_UNIFORM_IVEC3:Int
static inline var SHADER_UNIFORM_IVEC4:Int
static inline var SHADER_UNIFORM_SAMPLER2D:Int
static inline var CAMERA_CUSTOM:Int
static inline var CAMERA_FREE:Int
static inline var CAMERA_ORBITAL:Int
static inline var CAMERA_FIRST_PERSON:Int
static inline var CAMERA_THIRD_PERSON:Int
static inline var CAMERA_PERSPECTIVE:Int
static inline var CAMERA_ORTHOGRAPHIC:Int
static inline var TEXTURE_FILTER_POINT:Int
static inline var TEXTURE_FILTER_BILINEAR:Int
static inline var TEXTURE_FILTER_TRILINEAR:Int
static inline var TEXTURE_FILTER_ANISOTROPIC_4X:Int
static inline var TEXTURE_FILTER_ANISOTROPIC_8X:Int
static inline var TEXTURE_FILTER_ANISOTROPIC_16X:Int
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
- `MOUSE_BUTTON_LEFT`: Mouse button left.
- `MOUSE_BUTTON_RIGHT`: Mouse button right.
- `MOUSE_BUTTON_MIDDLE`: Mouse button middle (pressed wheel).
- `MOUSE_BUTTON_SIDE`: Mouse button side (advanced mouse device).
- `MOUSE_BUTTON_EXTRA`: Mouse button extra (advanced mouse device).
- `MOUSE_BUTTON_FORWARD`: Mouse button forward (advanced mouse device).
- `MOUSE_BUTTON_BACK`: Mouse button back (advanced mouse device).
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
- `GAMEPAD_AXIS_LEFT_X`: Gamepad left stick X axis.
- `GAMEPAD_AXIS_LEFT_Y`: Gamepad left stick Y axis.
- `GAMEPAD_AXIS_RIGHT_X`: Gamepad right stick X axis.
- `GAMEPAD_AXIS_RIGHT_Y`: Gamepad right stick Y axis.
- `GAMEPAD_AXIS_LEFT_TRIGGER`: Gamepad back trigger left, pressure level: [1..-1].
- `GAMEPAD_AXIS_RIGHT_TRIGGER`: Gamepad back trigger right, pressure level: [1..-1].
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
- `SHADER_UNIFORM_FLOAT`: Shader uniform type: float.
- `SHADER_UNIFORM_VEC2`: Shader uniform type: vec2 (2 float).
- `SHADER_UNIFORM_VEC3`: Shader uniform type: vec3 (3 float).
- `SHADER_UNIFORM_VEC4`: Shader uniform type: vec4 (4 float).
- `SHADER_UNIFORM_INT`: Shader uniform type: int.
- `SHADER_UNIFORM_IVEC2`: Shader uniform type: ivec2 (2 int).
- `SHADER_UNIFORM_IVEC3`: Shader uniform type: ivec3 (3 int).
- `SHADER_UNIFORM_IVEC4`: Shader uniform type: ivec4 (4 int).
- `SHADER_UNIFORM_SAMPLER2D`: Shader uniform type: sampler2d.
- `CAMERA_CUSTOM`: Camera custom, controlled by user (UpdateCamera() does nothing).
- `CAMERA_FREE`: Camera free mode.
- `CAMERA_ORBITAL`: Camera orbital, around target, zoom supported.
- `CAMERA_FIRST_PERSON`: Camera first person.
- `CAMERA_THIRD_PERSON`: Camera third person.
- `CAMERA_PERSPECTIVE`: Perspective projection.
- `CAMERA_ORTHOGRAPHIC`: Orthographic projection.
- `TEXTURE_FILTER_POINT`: No filter, just pixel approximation.
- `TEXTURE_FILTER_BILINEAR`: Linear filtering.
- `TEXTURE_FILTER_TRILINEAR`: Trilinear filtering (linear with mipmaps).
- `TEXTURE_FILTER_ANISOTROPIC_4X`: Anisotropic filtering 4x.
- `TEXTURE_FILTER_ANISOTROPIC_8X`: Anisotropic filtering 8x.
- `TEXTURE_FILTER_ANISOTROPIC_16X`: Anisotropic filtering 16x.
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

### rcore: the window and frame, input, files, cameras and shaders

```haxe
static macro function LoadShader(vsFileName:Null<String>, fsFileName:Null<String>):Shader
static macro function LoadShaderFromMemory(vsCode:Null<String>, fsCode:Null<String>):Shader
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
static function IsGestureDetected(gesture:Int):Bool
static function GetGestureDetected():Int
static function IsGamepadAvailable(gamepad:Int):Bool
static function GetGamepadName(gamepad:Int):String
static function IsGamepadButtonPressed(gamepad:Int, button:Int):Bool
static function IsGamepadButtonDown(gamepad:Int, button:Int):Bool
static function IsGamepadButtonReleased(gamepad:Int, button:Int):Bool
static function IsGamepadButtonUp(gamepad:Int, button:Int):Bool
static function GetGamepadButtonPressed():Int
static function GetGamepadAxisCount(gamepad:Int):Int
static function GetGamepadAxisMovement(gamepad:Int, axis:Int):Float
static function FileExists(fileName:String):Bool
static function LoadFileText(fileName:String):Null<String>
static function UnloadFileText(text:Null<String>):Void
static function SaveFileText(fileName:String, text:String):Bool
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
```

- `LoadShader`: Loads a shader from raylib GLSL files (330, or 100 for the web), either null for raylib's default stage. They are compiled as the program builds, for every target, so their names are constants; the files are found under `-D helix-ray-files` (default `web`), as the program's other files are.
  - `vsFileName`: The vertex stage's file, or null.
  - `fsFileName`: The fragment stage's file, or null.
  - returns: The shader.
- `LoadShaderFromMemory`: Loads a shader from raylib GLSL text, either null for raylib's default stage. It is compiled as the program builds, so the text is a constant.
  - `vsCode`: The vertex stage's text, or null.
  - `fsCode`: The fragment stage's text, or null.
  - returns: The shader.
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
- `SetConfigFlags`: Sets flags for the window before `InitWindow` (`FLAG_*`). The window is resizable here whatever they say.
  - `flags`: The flags, or'd together.
- `SetWindowState`: Sets flags on the open window (`FLAG_*`). A window here is resizable whatever they say, and the others aren't read.
  - `flags`: The flags, or'd together.
- `ClearWindowState`: Clears flags on the open window (`FLAG_*`).
  - `flags`: The flags, or'd together.
- `IsWindowState`: Returns whether flags are set on the window.
  - `flag`: The flags, or'd together.
  - returns: True when all of them are.
- `SetTargetFPS`: Sets the frame rate aimed for. Frames here follow the display's refresh, whatever it is set to.
  - `fps`: The frames a second.
- `GetFPS`: Returns the frames a second, averaged over the last half second or so.
  - returns: The frames a second.
- `GetFrameTime`: Returns the seconds the last frame took.
  - returns: The seconds.
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
- `IsGestureDetected`: Returns whether a gesture happened this frame. Only `GESTURE_TAP` is read here: a finger touching, or the left mouse button pressed, as raylib counts it.
  - `gesture`: The gesture (`GESTURE_*`).
  - returns: True for the frame it happened.
- `GetGestureDetected`: Returns the gesture this frame: `GESTURE_TAP` for a finger touching or the left mouse button pressed, else `GESTURE_NONE`. Only taps are read here.
  - returns: The gesture (`GESTURE_*`).
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
- `GetGamepadButtonPressed`: Returns a button held on any gamepad, as raylib's last button pressed is: set while it is held, not only as it goes down.
  - returns: The button (`GAMEPAD_BUTTON_*`), or `GAMEPAD_BUTTON_UNKNOWN` when none is held.
- `GetGamepadAxisCount`: Returns the number of axes a gamepad has.
  - `gamepad`: The gamepad, 0 to 3.
  - returns: 6 while one is connected, else 0.
- `GetGamepadAxisMovement`: Returns how far a gamepad's axis is pushed, with no dead zone. A stick is -1 to 1, down and right positive; a trigger is -1 released to 1 pulled, as raylib's are.
  - `gamepad`: The gamepad, 0 to 3.
  - `axis`: The axis (`GAMEPAD_AXIS_*`).
  - returns: The value.
- `FileExists`: Returns whether a file exists: one `SaveFileText` wrote, or one of the program's.
  - `fileName`: The file.
  - returns: True when it exists.
- `LoadFileText`: Reads a text file: one `SaveFileText` wrote, or one of the program's.
  - `fileName`: The file.
  - returns: Its text, or null when it doesn't exist.
- `UnloadFileText`: Frees text `LoadFileText` returned. There is nothing to free here.
  - `text`: The text.
- `SaveFileText`: Writes a text file, kept across runs: in a page, in the page's storage; natively, in the program's data directory. It is kept at the end of the frame.
  - `fileName`: The file.
  - `text`: Its text.
  - returns: True.
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

### rshapes: 2D shapes and collisions

```haxe
static function DrawPixel(posX:Int, posY:Int, color:Color):Void
static function DrawPixelV(position:Vector2, color:Color):Void
static function DrawLine(startPosX:Int, startPosY:Int, endPosX:Int, endPosY:Int, color:Color):Void
static function DrawLineV(startPos:Vector2, endPos:Vector2, color:Color):Void
static function DrawLineEx(startPos:Vector2, endPos:Vector2, thick:Float, color:Color):Void
static function DrawCircle(centerX:Int, centerY:Int, radius:Float, color:Color):Void
static function DrawCircleV(center:Vector2, radius:Float, color:Color):Void
static function DrawCircleLines(centerX:Int, centerY:Int, radius:Float, color:Color):Void
static function DrawCircleLinesV(center:Vector2, radius:Float, color:Color):Void
static function DrawRectangle(posX:Int, posY:Int, width:Int, height:Int, color:Color):Void
static function DrawRectangleV(position:Vector2, size:Vector2, color:Color):Void
static function DrawRectangleRec(rec:Rectangle, color:Color):Void
static function DrawRectangleLines(posX:Int, posY:Int, width:Int, height:Int, color:Color):Void
static function DrawRectangleLinesEx(rec:Rectangle, lineThick:Float, color:Color):Void
static function DrawTriangle(v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void
static function CheckCollisionRecs(rec1:Rectangle, rec2:Rectangle):Bool
static function CheckCollisionCircles(center1:Vector2, radius1:Float, center2:Vector2, radius2:Float):Bool
static function CheckCollisionCircleRec(center:Vector2, radius:Float, rec:Rectangle):Bool
static function CheckCollisionPointRec(point:Vector2, rec:Rectangle):Bool
static function CheckCollisionPointCircle(point:Vector2, center:Vector2, radius:Float):Bool
```

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
- `DrawCircle`: Draws a filled circle.
  - `centerX`: The center's x.
  - `centerY`: The center's y.
  - `radius`: The radius.
  - `color`: The color.
- `DrawCircleV`: Draws a filled circle.
  - `center`: The center.
  - `radius`: The radius.
  - `color`: The color.
- `DrawCircleLines`: Draws a circle's outline, one pixel wide.
  - `centerX`: The center's x.
  - `centerY`: The center's y.
  - `radius`: The radius.
  - `color`: The color.
- `DrawCircleLinesV`: Draws a circle's outline, one pixel wide.
  - `center`: The center.
  - `radius`: The radius.
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
- `DrawTriangle`: Draws a filled triangle; its points go counterclockwise, as raylib's do.
  - `v1`: The first point.
  - `v2`: The second point.
  - `v3`: The third point.
  - `color`: The color.
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
- `CheckCollisionPointRec`: Returns whether a point is inside a rectangle.
  - `point`: The point.
  - `rec`: The rectangle.
  - returns: True when it is inside.
- `CheckCollisionPointCircle`: Returns whether a point is inside a circle.
  - `point`: The point.
  - `center`: The circle's center.
  - `radius`: Its radius.
  - returns: True when it is inside.

### rtextures: textures, render textures and colors

```haxe
static function LoadTexture(fileName:String):Texture2D
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

- `LoadTexture`: Loads an image file as a texture: in a page from the files loaded before `main`, natively read now. A file loaded again shares its first load's texture, and the image goes to the GPU when first drawn.
  - `fileName`: The file, as the program names it, such as "assets/player.png".
  - returns: The texture; its `id` is 0 when the file couldn't be read.
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

### rtext: text

```haxe
static function DrawText(text:String, posX:Int, posY:Int, fontSize:Int, color:Color):Void
static function MeasureText(text:String, fontSize:Int):Int
static function DrawFPS(posX:Int, posY:Int):Void
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
static function LoadModel(fileName:String):Model
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
- `LoadModel`: Loads a model from a glTF or GLB file: its meshes, their materials and its images; in a page from the files loaded before `main`, natively read now. A file loaded again shares its first load's meshes and textures, with materials of its own; meshes go to the GPU when first drawn.
  - `fileName`: The file, as the program names it, such as "assets/trophy.glb".
  - returns: The model; with no meshes when the file couldn't be read.
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
- `UploadMesh`: Sends a mesh's vertices to the GPU, so it can be drawn. The `GenMesh*` functions and `LoadModel` do it themselves.
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
static function LoadSound(fileName:String):Sound
static function UnloadSound(sound:Sound):Void
static function IsSoundValid(sound:Sound):Bool
static function PlaySound(sound:Sound):Void
static function StopSound(sound:Sound):Void
static function IsSoundPlaying(sound:Sound):Bool
static function SetSoundVolume(sound:Sound, volume:Float):Void
```

- `InitAudioDevice`: Opens the audio output, with helix-services' `Audio` over it. In a page it plays once the player's first press lets it.
- `CloseAudioDevice`: Closes the audio output, stopping and unloading every sound.
- `IsAudioDeviceReady`: Returns whether the audio output is open.
  - returns: True after `InitAudioDevice`, where the platform has an output.
- `SetMasterVolume`: Sets the volume of every sound.
  - `volume`: 0 (silent) to 1.
- `GetMasterVolume`: Returns the volume of every sound.
  - returns: 0 (silent) to 1.
- `LoadSound`: Loads a sound file whole. It decodes in the background; played before then, it starts once decoded. A file loaded again shares its first load's decoded sound.
  - `fileName`: The file, as the program names it, such as "assets/coin.wav".
  - returns: The sound.
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

### raymath: vectors, matrices and quaternions

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

### helix-ray's own: loading in a page

```haxe
static function LoadTextureAsync(fileName:String, loaded:Texture2D -> Void, ?failed:String -> Void):Void
static function LoadModelAsync(fileName:String, loaded:Model -> Void, ?failed:String -> Void):Void
static function LoadSoundAsync(fileName:String, loaded:Sound -> Void, ?failed:String -> Void):Void
static function LoadFileTextAsync(fileName:String, loaded:String -> Void, ?failed:String -> Void):Void
```

- `LoadTextureAsync`: Loads an image file as a texture, answering when it is ready: helix-ray's own, for a page, where `LoadTexture` answers only for a file already loaded (one the program names, so it was loaded before `main`, or one loaded this way). Natively the file is read at once. Either way the answer comes at a later frame, never during the call, and `LoadTexture` of the file answers at once after.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the texture.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.
- `LoadModelAsync`: Loads a model from a glTF or GLB file, with its images and the files it points to, answering when it is ready: helix-ray's own, as `LoadTextureAsync` is for textures.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the model.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.
- `LoadSoundAsync`: Loads a sound file and decodes it, answering when it is ready to play at once: helix-ray's own, as `LoadTextureAsync` is for textures. `InitAudioDevice` comes first.
  - `fileName`: The file, as the program names it.
  - `loaded`: Receives the sound.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.
- `LoadFileTextAsync`: Reads a text file, answering when it is read: helix-ray's own, as `LoadTextureAsync` is for textures. A file `SaveFileText` wrote is answered from the saves.
  - `fileName`: The file.
  - `loaded`: Receives its text.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

### Not in helix-ray yet

Each of these is raylib's name, and a call to it doesn't compile, saying so.

From `raylib.h`: `IsWindowFullscreen`, `IsWindowHidden`, `IsWindowMinimized`, `IsWindowMaximized`, `IsWindowFocused`, `ToggleFullscreen`, `ToggleBorderlessWindowed`, `MaximizeWindow`, `MinimizeWindow`, `RestoreWindow`, `SetWindowIcon`, `SetWindowIcons`, `SetWindowPosition`, `SetWindowMonitor`, `SetWindowMinSize`, `SetWindowMaxSize`, `SetWindowOpacity`, `SetWindowFocused`, `GetWindowHandle`, `GetMonitorCount`, `GetCurrentMonitor`, `GetMonitorPosition`, `GetMonitorWidth`, `GetMonitorHeight`, `GetMonitorPhysicalWidth`, `GetMonitorPhysicalHeight`, `GetMonitorRefreshRate`, `GetWindowPosition`, `GetWindowScaleDPI`, `GetMonitorName`, `SetClipboardText`, `GetClipboardText`, `GetClipboardImage`, `EnableEventWaiting`, `DisableEventWaiting`, `ShowCursor`, `HideCursor`, `IsCursorHidden`, `EnableCursor`, `DisableCursor`, `IsCursorOnScreen`, `BeginBlendMode`, `EndBlendMode`, `BeginScissorMode`, `EndScissorMode`, `BeginVrStereoMode`, `EndVrStereoMode`, `LoadVrStereoConfig`, `UnloadVrStereoConfig`, `SwapScreenBuffer`, `PollInputEvents`, `WaitTime`, `LoadRandomSequence`, `UnloadRandomSequence`, `TakeScreenshot`, `OpenURL`, `TraceLog`, `SetTraceLogLevel`, `MemAlloc`, `MemRealloc`, `MemFree`, `SetTraceLogCallback`, `SetLoadFileDataCallback`, `SetSaveFileDataCallback`, `SetLoadFileTextCallback`, `SetSaveFileTextCallback`, `LoadFileData`, `UnloadFileData`, `SaveFileData`, `ExportDataAsCode`, `DirectoryExists`, `IsFileExtension`, `GetFileLength`, `GetFileExtension`, `GetFileName`, `GetFileNameWithoutExt`, `GetDirectoryPath`, `GetPrevDirectoryPath`, `GetWorkingDirectory`, `GetApplicationDirectory`, `MakeDirectory`, `ChangeDirectory`, `IsPathFile`, `IsFileNameValid`, `LoadDirectoryFiles`, `LoadDirectoryFilesEx`, `UnloadDirectoryFiles`, `IsFileDropped`, `LoadDroppedFiles`, `UnloadDroppedFiles`, `GetFileModTime`, `CompressData`, `DecompressData`, `EncodeDataBase64`, `DecodeDataBase64`, `ComputeCRC32`, `ComputeMD5`, `ComputeSHA1`, `LoadAutomationEventList`, `UnloadAutomationEventList`, `ExportAutomationEventList`, `SetAutomationEventList`, `SetAutomationEventBaseFrame`, `StartAutomationEventRecording`, `StopAutomationEventRecording`, `PlayAutomationEvent`, `IsKeyPressedRepeat`, `GetCharPressed`, `SetGamepadMappings`, `SetGamepadVibration`, `SetMousePosition`, `SetMouseOffset`, `SetMouseScale`, `GetMouseWheelMoveV`, `SetMouseCursor`, `GetTouchPointId`, `SetGesturesEnabled`, `GetGestureHoldDuration`, `GetGestureDragVector`, `GetGestureDragAngle`, `GetGesturePinchVector`, `GetGesturePinchAngle`, `UpdateCameraPro`, `SetShapesTexture`, `GetShapesTexture`, `GetShapesTextureRectangle`, `DrawLineStrip`, `DrawLineBezier`, `DrawCircleSector`, `DrawCircleSectorLines`, `DrawCircleGradient`, `DrawEllipse`, `DrawEllipseLines`, `DrawRing`, `DrawRingLines`, `DrawRectanglePro`, `DrawRectangleGradientV`, `DrawRectangleGradientH`, `DrawRectangleGradientEx`, `DrawRectangleRounded`, `DrawRectangleRoundedLines`, `DrawRectangleRoundedLinesEx`, `DrawTriangleLines`, `DrawTriangleFan`, `DrawTriangleStrip`, `DrawPoly`, `DrawPolyLines`, `DrawPolyLinesEx`, `DrawSplineLinear`, `DrawSplineBasis`, `DrawSplineCatmullRom`, `DrawSplineBezierQuadratic`, `DrawSplineBezierCubic`, `DrawSplineSegmentLinear`, `DrawSplineSegmentBasis`, `DrawSplineSegmentCatmullRom`, `DrawSplineSegmentBezierQuadratic`, `DrawSplineSegmentBezierCubic`, `GetSplinePointLinear`, `GetSplinePointBasis`, `GetSplinePointCatmullRom`, `GetSplinePointBezierQuad`, `GetSplinePointBezierCubic`, `CheckCollisionCircleLine`, `CheckCollisionPointTriangle`, `CheckCollisionPointLine`, `CheckCollisionPointPoly`, `CheckCollisionLines`, `GetCollisionRec`, `LoadImage`, `LoadImageRaw`, `LoadImageAnim`, `LoadImageAnimFromMemory`, `LoadImageFromMemory`, `LoadImageFromTexture`, `LoadImageFromScreen`, `IsImageValid`, `UnloadImage`, `ExportImage`, `ExportImageToMemory`, `ExportImageAsCode`, `GenImageColor`, `GenImageGradientLinear`, `GenImageGradientRadial`, `GenImageGradientSquare`, `GenImageChecked`, `GenImageWhiteNoise`, `GenImagePerlinNoise`, `GenImageCellular`, `GenImageText`, `ImageCopy`, `ImageFromImage`, `ImageFromChannel`, `ImageText`, `ImageTextEx`, `ImageFormat`, `ImageToPOT`, `ImageCrop`, `ImageAlphaCrop`, `ImageAlphaClear`, `ImageAlphaMask`, `ImageAlphaPremultiply`, `ImageBlurGaussian`, `ImageKernelConvolution`, `ImageResize`, `ImageResizeNN`, `ImageResizeCanvas`, `ImageMipmaps`, `ImageDither`, `ImageFlipVertical`, `ImageFlipHorizontal`, `ImageRotate`, `ImageRotateCW`, `ImageRotateCCW`, `ImageColorTint`, `ImageColorInvert`, `ImageColorGrayscale`, `ImageColorContrast`, `ImageColorBrightness`, `ImageColorReplace`, `LoadImageColors`, `LoadImagePalette`, `UnloadImageColors`, `UnloadImagePalette`, `GetImageAlphaBorder`, `GetImageColor`, `ImageClearBackground`, `ImageDrawPixel`, `ImageDrawPixelV`, `ImageDrawLine`, `ImageDrawLineV`, `ImageDrawLineEx`, `ImageDrawCircle`, `ImageDrawCircleV`, `ImageDrawCircleLines`, `ImageDrawCircleLinesV`, `ImageDrawRectangle`, `ImageDrawRectangleV`, `ImageDrawRectangleRec`, `ImageDrawRectangleLines`, `ImageDrawTriangle`, `ImageDrawTriangleEx`, `ImageDrawTriangleLines`, `ImageDrawTriangleFan`, `ImageDrawTriangleStrip`, `ImageDraw`, `ImageDrawText`, `ImageDrawTextEx`, `LoadTextureFromImage`, `LoadTextureCubemap`, `UpdateTexture`, `UpdateTextureRec`, `GenTextureMipmaps`, `SetTextureWrap`, `DrawTextureNPatch`, `ColorIsEqual`, `ColorToInt`, `ColorToHSV`, `ColorFromHSV`, `ColorTint`, `ColorBrightness`, `ColorContrast`, `ColorAlphaBlend`, `ColorLerp`, `GetColor`, `GetPixelColor`, `SetPixelColor`, `GetPixelDataSize`, `GetFontDefault`, `LoadFont`, `LoadFontEx`, `LoadFontFromImage`, `LoadFontFromMemory`, `IsFontValid`, `LoadFontData`, `GenImageFontAtlas`, `UnloadFontData`, `UnloadFont`, `ExportFontAsCode`, `DrawTextEx`, `DrawTextPro`, `DrawTextCodepoint`, `DrawTextCodepoints`, `SetTextLineSpacing`, `MeasureTextEx`, `GetGlyphIndex`, `GetGlyphInfo`, `GetGlyphAtlasRec`, `LoadUTF8`, `UnloadUTF8`, `LoadCodepoints`, `UnloadCodepoints`, `GetCodepointCount`, `GetCodepoint`, `GetCodepointNext`, `GetCodepointPrevious`, `CodepointToUTF8`, `TextCopy`, `TextIsEqual`, `TextLength`, `TextFormat`, `TextSubtext`, `TextReplace`, `TextInsert`, `TextJoin`, `TextSplit`, `TextAppend`, `TextFindIndex`, `TextToUpper`, `TextToLower`, `TextToPascal`, `TextToSnake`, `TextToCamel`, `TextToInteger`, `TextToFloat`, `DrawPoint3D`, `DrawCircle3D`, `DrawTriangle3D`, `DrawTriangleStrip3D`, `DrawCylinder`, `DrawCylinderEx`, `DrawCylinderWires`, `DrawCylinderWiresEx`, `DrawCapsule`, `DrawCapsuleWires`, `DrawRay`, `DrawModelWires`, `DrawModelWiresEx`, `DrawModelPoints`, `DrawModelPointsEx`, `DrawBillboard`, `DrawBillboardRec`, `DrawBillboardPro`, `UpdateMeshBuffer`, `DrawMeshInstanced`, `GenMeshTangents`, `ExportMesh`, `ExportMeshAsCode`, `GenMeshPoly`, `GenMeshHemiSphere`, `GenMeshCylinder`, `GenMeshCone`, `GenMeshTorus`, `GenMeshKnot`, `GenMeshHeightmap`, `GenMeshCubicmap`, `LoadMaterials`, `IsMaterialValid`, `UnloadMaterial`, `LoadModelAnimations`, `UpdateModelAnimation`, `UpdateModelAnimationBones`, `UnloadModelAnimation`, `UnloadModelAnimations`, `IsModelAnimationValid`, `GetRayCollisionQuad`, `LoadWave`, `LoadWaveFromMemory`, `IsWaveValid`, `LoadSoundFromWave`, `LoadSoundAlias`, `UpdateSound`, `UnloadWave`, `UnloadSoundAlias`, `ExportWave`, `ExportWaveAsCode`, `PauseSound`, `ResumeSound`, `SetSoundPitch`, `SetSoundPan`, `WaveCopy`, `WaveCrop`, `WaveFormat`, `LoadWaveSamples`, `UnloadWaveSamples`, `LoadMusicStream`, `LoadMusicStreamFromMemory`, `IsMusicValid`, `UnloadMusicStream`, `PlayMusicStream`, `IsMusicStreamPlaying`, `UpdateMusicStream`, `StopMusicStream`, `PauseMusicStream`, `ResumeMusicStream`, `SeekMusicStream`, `SetMusicVolume`, `SetMusicPitch`, `SetMusicPan`, `GetMusicTimeLength`, `GetMusicTimePlayed`, `LoadAudioStream`, `IsAudioStreamValid`, `UnloadAudioStream`, `UpdateAudioStream`, `IsAudioStreamProcessed`, `PlayAudioStream`, `PauseAudioStream`, `ResumeAudioStream`, `IsAudioStreamPlaying`, `StopAudioStream`, `SetAudioStreamVolume`, `SetAudioStreamPitch`, `SetAudioStreamPan`, `SetAudioStreamBufferSizeDefault`, `SetAudioStreamCallback`, `AttachAudioStreamProcessor`, `DetachAudioStreamProcessor`, `AttachAudioMixedProcessor`, `DetachAudioMixedProcessor`.

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
