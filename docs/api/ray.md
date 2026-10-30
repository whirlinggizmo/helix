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

A program's loop is raylib's, `while (!WindowShouldClose()) { BeginDrawing(); ...; EndDrawing(); }`; in a page its body runs once a frame. The files under the program's directory are loaded before its `main` runs, so `LoadTexture`, `LoadSound` and `LoadModel` answer at once. `SaveFileText` writes are kept across runs. Shaders are raylib's GLSL, compiled as the program builds, so `LoadShader` names its files with constants. Not here yet: skinned models and animations, fonts other than the default, images on the CPU, and the rest of raylib's less used corners.

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
static macro function LoadShader(vsFileName:Expr, fsFileName:Expr):Void
static macro function LoadShaderFromMemory(vsCode:Expr, fsCode:Expr):Void
static macro function IsWindowFullscreen(args:Array<Expr>):Void
static macro function IsWindowHidden(args:Array<Expr>):Void
static macro function IsWindowMinimized(args:Array<Expr>):Void
static macro function IsWindowMaximized(args:Array<Expr>):Void
static macro function IsWindowFocused(args:Array<Expr>):Void
static macro function ToggleFullscreen(args:Array<Expr>):Void
static macro function ToggleBorderlessWindowed(args:Array<Expr>):Void
static macro function MaximizeWindow(args:Array<Expr>):Void
static macro function MinimizeWindow(args:Array<Expr>):Void
static macro function RestoreWindow(args:Array<Expr>):Void
static macro function SetWindowIcon(args:Array<Expr>):Void
static macro function SetWindowIcons(args:Array<Expr>):Void
static macro function SetWindowPosition(args:Array<Expr>):Void
static macro function SetWindowMonitor(args:Array<Expr>):Void
static macro function SetWindowMinSize(args:Array<Expr>):Void
static macro function SetWindowMaxSize(args:Array<Expr>):Void
static macro function SetWindowOpacity(args:Array<Expr>):Void
static macro function SetWindowFocused(args:Array<Expr>):Void
static macro function GetWindowHandle(args:Array<Expr>):Void
static macro function GetMonitorCount(args:Array<Expr>):Void
static macro function GetCurrentMonitor(args:Array<Expr>):Void
static macro function GetMonitorPosition(args:Array<Expr>):Void
static macro function GetMonitorWidth(args:Array<Expr>):Void
static macro function GetMonitorHeight(args:Array<Expr>):Void
static macro function GetMonitorPhysicalWidth(args:Array<Expr>):Void
static macro function GetMonitorPhysicalHeight(args:Array<Expr>):Void
static macro function GetMonitorRefreshRate(args:Array<Expr>):Void
static macro function GetWindowPosition(args:Array<Expr>):Void
static macro function GetWindowScaleDPI(args:Array<Expr>):Void
static macro function GetMonitorName(args:Array<Expr>):Void
static macro function SetClipboardText(args:Array<Expr>):Void
static macro function GetClipboardText(args:Array<Expr>):Void
static macro function GetClipboardImage(args:Array<Expr>):Void
static macro function EnableEventWaiting(args:Array<Expr>):Void
static macro function DisableEventWaiting(args:Array<Expr>):Void
static macro function ShowCursor(args:Array<Expr>):Void
static macro function HideCursor(args:Array<Expr>):Void
static macro function IsCursorHidden(args:Array<Expr>):Void
static macro function EnableCursor(args:Array<Expr>):Void
static macro function DisableCursor(args:Array<Expr>):Void
static macro function IsCursorOnScreen(args:Array<Expr>):Void
static macro function BeginBlendMode(args:Array<Expr>):Void
static macro function EndBlendMode(args:Array<Expr>):Void
static macro function BeginScissorMode(args:Array<Expr>):Void
static macro function EndScissorMode(args:Array<Expr>):Void
static macro function BeginVrStereoMode(args:Array<Expr>):Void
static macro function EndVrStereoMode(args:Array<Expr>):Void
static macro function LoadVrStereoConfig(args:Array<Expr>):Void
static macro function UnloadVrStereoConfig(args:Array<Expr>):Void
static macro function SwapScreenBuffer(args:Array<Expr>):Void
static macro function PollInputEvents(args:Array<Expr>):Void
static macro function WaitTime(args:Array<Expr>):Void
static macro function LoadRandomSequence(args:Array<Expr>):Void
static macro function UnloadRandomSequence(args:Array<Expr>):Void
static macro function TakeScreenshot(args:Array<Expr>):Void
static macro function OpenURL(args:Array<Expr>):Void
static macro function TraceLog(args:Array<Expr>):Void
static macro function SetTraceLogLevel(args:Array<Expr>):Void
static macro function MemAlloc(args:Array<Expr>):Void
static macro function MemRealloc(args:Array<Expr>):Void
static macro function MemFree(args:Array<Expr>):Void
static macro function SetTraceLogCallback(args:Array<Expr>):Void
static macro function SetLoadFileDataCallback(args:Array<Expr>):Void
static macro function SetSaveFileDataCallback(args:Array<Expr>):Void
static macro function SetLoadFileTextCallback(args:Array<Expr>):Void
static macro function SetSaveFileTextCallback(args:Array<Expr>):Void
static macro function LoadFileData(args:Array<Expr>):Void
static macro function UnloadFileData(args:Array<Expr>):Void
static macro function SaveFileData(args:Array<Expr>):Void
static macro function ExportDataAsCode(args:Array<Expr>):Void
static macro function DirectoryExists(args:Array<Expr>):Void
static macro function IsFileExtension(args:Array<Expr>):Void
static macro function GetFileLength(args:Array<Expr>):Void
static macro function GetFileExtension(args:Array<Expr>):Void
static macro function GetFileName(args:Array<Expr>):Void
static macro function GetFileNameWithoutExt(args:Array<Expr>):Void
static macro function GetDirectoryPath(args:Array<Expr>):Void
static macro function GetPrevDirectoryPath(args:Array<Expr>):Void
static macro function GetWorkingDirectory(args:Array<Expr>):Void
static macro function GetApplicationDirectory(args:Array<Expr>):Void
static macro function MakeDirectory(args:Array<Expr>):Void
static macro function ChangeDirectory(args:Array<Expr>):Void
static macro function IsPathFile(args:Array<Expr>):Void
static macro function IsFileNameValid(args:Array<Expr>):Void
static macro function LoadDirectoryFiles(args:Array<Expr>):Void
static macro function LoadDirectoryFilesEx(args:Array<Expr>):Void
static macro function UnloadDirectoryFiles(args:Array<Expr>):Void
static macro function IsFileDropped(args:Array<Expr>):Void
static macro function LoadDroppedFiles(args:Array<Expr>):Void
static macro function UnloadDroppedFiles(args:Array<Expr>):Void
static macro function GetFileModTime(args:Array<Expr>):Void
static macro function CompressData(args:Array<Expr>):Void
static macro function DecompressData(args:Array<Expr>):Void
static macro function EncodeDataBase64(args:Array<Expr>):Void
static macro function DecodeDataBase64(args:Array<Expr>):Void
static macro function ComputeCRC32(args:Array<Expr>):Void
static macro function ComputeMD5(args:Array<Expr>):Void
static macro function ComputeSHA1(args:Array<Expr>):Void
static macro function LoadAutomationEventList(args:Array<Expr>):Void
static macro function UnloadAutomationEventList(args:Array<Expr>):Void
static macro function ExportAutomationEventList(args:Array<Expr>):Void
static macro function SetAutomationEventList(args:Array<Expr>):Void
static macro function SetAutomationEventBaseFrame(args:Array<Expr>):Void
static macro function StartAutomationEventRecording(args:Array<Expr>):Void
static macro function StopAutomationEventRecording(args:Array<Expr>):Void
static macro function PlayAutomationEvent(args:Array<Expr>):Void
static macro function IsKeyPressedRepeat(args:Array<Expr>):Void
static macro function GetCharPressed(args:Array<Expr>):Void
static macro function SetGamepadMappings(args:Array<Expr>):Void
static macro function SetGamepadVibration(args:Array<Expr>):Void
static macro function SetMousePosition(args:Array<Expr>):Void
static macro function SetMouseOffset(args:Array<Expr>):Void
static macro function SetMouseScale(args:Array<Expr>):Void
static macro function GetMouseWheelMoveV(args:Array<Expr>):Void
static macro function SetMouseCursor(args:Array<Expr>):Void
static macro function GetTouchPointId(args:Array<Expr>):Void
static macro function SetGesturesEnabled(args:Array<Expr>):Void
static macro function GetGestureHoldDuration(args:Array<Expr>):Void
static macro function GetGestureDragVector(args:Array<Expr>):Void
static macro function GetGestureDragAngle(args:Array<Expr>):Void
static macro function GetGesturePinchVector(args:Array<Expr>):Void
static macro function GetGesturePinchAngle(args:Array<Expr>):Void
static macro function UpdateCameraPro(args:Array<Expr>):Void
static macro function SetShapesTexture(args:Array<Expr>):Void
static macro function GetShapesTexture(args:Array<Expr>):Void
static macro function GetShapesTextureRectangle(args:Array<Expr>):Void
static macro function DrawLineStrip(args:Array<Expr>):Void
static macro function DrawLineBezier(args:Array<Expr>):Void
static macro function DrawCircleSector(args:Array<Expr>):Void
static macro function DrawCircleSectorLines(args:Array<Expr>):Void
static macro function DrawCircleGradient(args:Array<Expr>):Void
static macro function DrawEllipse(args:Array<Expr>):Void
static macro function DrawEllipseLines(args:Array<Expr>):Void
static macro function DrawRing(args:Array<Expr>):Void
static macro function DrawRingLines(args:Array<Expr>):Void
static macro function DrawRectanglePro(args:Array<Expr>):Void
static macro function DrawRectangleGradientV(args:Array<Expr>):Void
static macro function DrawRectangleGradientH(args:Array<Expr>):Void
static macro function DrawRectangleGradientEx(args:Array<Expr>):Void
static macro function DrawRectangleRounded(args:Array<Expr>):Void
static macro function DrawRectangleRoundedLines(args:Array<Expr>):Void
static macro function DrawRectangleRoundedLinesEx(args:Array<Expr>):Void
static macro function DrawTriangleLines(args:Array<Expr>):Void
static macro function DrawTriangleFan(args:Array<Expr>):Void
static macro function DrawTriangleStrip(args:Array<Expr>):Void
static macro function DrawPoly(args:Array<Expr>):Void
static macro function DrawPolyLines(args:Array<Expr>):Void
static macro function DrawPolyLinesEx(args:Array<Expr>):Void
static macro function DrawSplineLinear(args:Array<Expr>):Void
static macro function DrawSplineBasis(args:Array<Expr>):Void
static macro function DrawSplineCatmullRom(args:Array<Expr>):Void
static macro function DrawSplineBezierQuadratic(args:Array<Expr>):Void
static macro function DrawSplineBezierCubic(args:Array<Expr>):Void
static macro function DrawSplineSegmentLinear(args:Array<Expr>):Void
static macro function DrawSplineSegmentBasis(args:Array<Expr>):Void
static macro function DrawSplineSegmentCatmullRom(args:Array<Expr>):Void
static macro function DrawSplineSegmentBezierQuadratic(args:Array<Expr>):Void
static macro function DrawSplineSegmentBezierCubic(args:Array<Expr>):Void
static macro function GetSplinePointLinear(args:Array<Expr>):Void
static macro function GetSplinePointBasis(args:Array<Expr>):Void
static macro function GetSplinePointCatmullRom(args:Array<Expr>):Void
static macro function GetSplinePointBezierQuad(args:Array<Expr>):Void
static macro function GetSplinePointBezierCubic(args:Array<Expr>):Void
static macro function CheckCollisionCircleLine(args:Array<Expr>):Void
static macro function CheckCollisionPointTriangle(args:Array<Expr>):Void
static macro function CheckCollisionPointLine(args:Array<Expr>):Void
static macro function CheckCollisionPointPoly(args:Array<Expr>):Void
static macro function CheckCollisionLines(args:Array<Expr>):Void
static macro function GetCollisionRec(args:Array<Expr>):Void
static macro function LoadImage(args:Array<Expr>):Void
static macro function LoadImageRaw(args:Array<Expr>):Void
static macro function LoadImageAnim(args:Array<Expr>):Void
static macro function LoadImageAnimFromMemory(args:Array<Expr>):Void
static macro function LoadImageFromMemory(args:Array<Expr>):Void
static macro function LoadImageFromTexture(args:Array<Expr>):Void
static macro function LoadImageFromScreen(args:Array<Expr>):Void
static macro function IsImageValid(args:Array<Expr>):Void
static macro function UnloadImage(args:Array<Expr>):Void
static macro function ExportImage(args:Array<Expr>):Void
static macro function ExportImageToMemory(args:Array<Expr>):Void
static macro function ExportImageAsCode(args:Array<Expr>):Void
static macro function GenImageColor(args:Array<Expr>):Void
static macro function GenImageGradientLinear(args:Array<Expr>):Void
static macro function GenImageGradientRadial(args:Array<Expr>):Void
static macro function GenImageGradientSquare(args:Array<Expr>):Void
static macro function GenImageChecked(args:Array<Expr>):Void
static macro function GenImageWhiteNoise(args:Array<Expr>):Void
static macro function GenImagePerlinNoise(args:Array<Expr>):Void
static macro function GenImageCellular(args:Array<Expr>):Void
static macro function GenImageText(args:Array<Expr>):Void
static macro function ImageCopy(args:Array<Expr>):Void
static macro function ImageFromImage(args:Array<Expr>):Void
static macro function ImageFromChannel(args:Array<Expr>):Void
static macro function ImageText(args:Array<Expr>):Void
static macro function ImageTextEx(args:Array<Expr>):Void
static macro function ImageFormat(args:Array<Expr>):Void
static macro function ImageToPOT(args:Array<Expr>):Void
static macro function ImageCrop(args:Array<Expr>):Void
static macro function ImageAlphaCrop(args:Array<Expr>):Void
static macro function ImageAlphaClear(args:Array<Expr>):Void
static macro function ImageAlphaMask(args:Array<Expr>):Void
static macro function ImageAlphaPremultiply(args:Array<Expr>):Void
static macro function ImageBlurGaussian(args:Array<Expr>):Void
static macro function ImageKernelConvolution(args:Array<Expr>):Void
static macro function ImageResize(args:Array<Expr>):Void
static macro function ImageResizeNN(args:Array<Expr>):Void
static macro function ImageResizeCanvas(args:Array<Expr>):Void
static macro function ImageMipmaps(args:Array<Expr>):Void
static macro function ImageDither(args:Array<Expr>):Void
static macro function ImageFlipVertical(args:Array<Expr>):Void
static macro function ImageFlipHorizontal(args:Array<Expr>):Void
static macro function ImageRotate(args:Array<Expr>):Void
static macro function ImageRotateCW(args:Array<Expr>):Void
static macro function ImageRotateCCW(args:Array<Expr>):Void
static macro function ImageColorTint(args:Array<Expr>):Void
static macro function ImageColorInvert(args:Array<Expr>):Void
static macro function ImageColorGrayscale(args:Array<Expr>):Void
static macro function ImageColorContrast(args:Array<Expr>):Void
static macro function ImageColorBrightness(args:Array<Expr>):Void
static macro function ImageColorReplace(args:Array<Expr>):Void
static macro function LoadImageColors(args:Array<Expr>):Void
static macro function LoadImagePalette(args:Array<Expr>):Void
static macro function UnloadImageColors(args:Array<Expr>):Void
static macro function UnloadImagePalette(args:Array<Expr>):Void
static macro function GetImageAlphaBorder(args:Array<Expr>):Void
static macro function GetImageColor(args:Array<Expr>):Void
static macro function ImageClearBackground(args:Array<Expr>):Void
static macro function ImageDrawPixel(args:Array<Expr>):Void
static macro function ImageDrawPixelV(args:Array<Expr>):Void
static macro function ImageDrawLine(args:Array<Expr>):Void
static macro function ImageDrawLineV(args:Array<Expr>):Void
static macro function ImageDrawLineEx(args:Array<Expr>):Void
static macro function ImageDrawCircle(args:Array<Expr>):Void
static macro function ImageDrawCircleV(args:Array<Expr>):Void
static macro function ImageDrawCircleLines(args:Array<Expr>):Void
static macro function ImageDrawCircleLinesV(args:Array<Expr>):Void
static macro function ImageDrawRectangle(args:Array<Expr>):Void
static macro function ImageDrawRectangleV(args:Array<Expr>):Void
static macro function ImageDrawRectangleRec(args:Array<Expr>):Void
static macro function ImageDrawRectangleLines(args:Array<Expr>):Void
static macro function ImageDrawTriangle(args:Array<Expr>):Void
static macro function ImageDrawTriangleEx(args:Array<Expr>):Void
static macro function ImageDrawTriangleLines(args:Array<Expr>):Void
static macro function ImageDrawTriangleFan(args:Array<Expr>):Void
static macro function ImageDrawTriangleStrip(args:Array<Expr>):Void
static macro function ImageDraw(args:Array<Expr>):Void
static macro function ImageDrawText(args:Array<Expr>):Void
static macro function ImageDrawTextEx(args:Array<Expr>):Void
static macro function LoadTextureFromImage(args:Array<Expr>):Void
static macro function LoadTextureCubemap(args:Array<Expr>):Void
static macro function UpdateTexture(args:Array<Expr>):Void
static macro function UpdateTextureRec(args:Array<Expr>):Void
static macro function GenTextureMipmaps(args:Array<Expr>):Void
static macro function SetTextureWrap(args:Array<Expr>):Void
static macro function DrawTextureNPatch(args:Array<Expr>):Void
static macro function ColorIsEqual(args:Array<Expr>):Void
static macro function ColorToInt(args:Array<Expr>):Void
static macro function ColorToHSV(args:Array<Expr>):Void
static macro function ColorFromHSV(args:Array<Expr>):Void
static macro function ColorTint(args:Array<Expr>):Void
static macro function ColorBrightness(args:Array<Expr>):Void
static macro function ColorContrast(args:Array<Expr>):Void
static macro function ColorAlphaBlend(args:Array<Expr>):Void
static macro function ColorLerp(args:Array<Expr>):Void
static macro function GetColor(args:Array<Expr>):Void
static macro function GetPixelColor(args:Array<Expr>):Void
static macro function SetPixelColor(args:Array<Expr>):Void
static macro function GetPixelDataSize(args:Array<Expr>):Void
static macro function GetFontDefault(args:Array<Expr>):Void
static macro function LoadFont(args:Array<Expr>):Void
static macro function LoadFontEx(args:Array<Expr>):Void
static macro function LoadFontFromImage(args:Array<Expr>):Void
static macro function LoadFontFromMemory(args:Array<Expr>):Void
static macro function IsFontValid(args:Array<Expr>):Void
static macro function LoadFontData(args:Array<Expr>):Void
static macro function GenImageFontAtlas(args:Array<Expr>):Void
static macro function UnloadFontData(args:Array<Expr>):Void
static macro function UnloadFont(args:Array<Expr>):Void
static macro function ExportFontAsCode(args:Array<Expr>):Void
static macro function DrawTextEx(args:Array<Expr>):Void
static macro function DrawTextPro(args:Array<Expr>):Void
static macro function DrawTextCodepoint(args:Array<Expr>):Void
static macro function DrawTextCodepoints(args:Array<Expr>):Void
static macro function SetTextLineSpacing(args:Array<Expr>):Void
static macro function MeasureTextEx(args:Array<Expr>):Void
static macro function GetGlyphIndex(args:Array<Expr>):Void
static macro function GetGlyphInfo(args:Array<Expr>):Void
static macro function GetGlyphAtlasRec(args:Array<Expr>):Void
static macro function LoadUTF8(args:Array<Expr>):Void
static macro function UnloadUTF8(args:Array<Expr>):Void
static macro function LoadCodepoints(args:Array<Expr>):Void
static macro function UnloadCodepoints(args:Array<Expr>):Void
static macro function GetCodepointCount(args:Array<Expr>):Void
static macro function GetCodepoint(args:Array<Expr>):Void
static macro function GetCodepointNext(args:Array<Expr>):Void
static macro function GetCodepointPrevious(args:Array<Expr>):Void
static macro function CodepointToUTF8(args:Array<Expr>):Void
static macro function TextCopy(args:Array<Expr>):Void
static macro function TextIsEqual(args:Array<Expr>):Void
static macro function TextLength(args:Array<Expr>):Void
static macro function TextFormat(args:Array<Expr>):Void
static macro function TextSubtext(args:Array<Expr>):Void
static macro function TextReplace(args:Array<Expr>):Void
static macro function TextInsert(args:Array<Expr>):Void
static macro function TextJoin(args:Array<Expr>):Void
static macro function TextSplit(args:Array<Expr>):Void
static macro function TextAppend(args:Array<Expr>):Void
static macro function TextFindIndex(args:Array<Expr>):Void
static macro function TextToUpper(args:Array<Expr>):Void
static macro function TextToLower(args:Array<Expr>):Void
static macro function TextToPascal(args:Array<Expr>):Void
static macro function TextToSnake(args:Array<Expr>):Void
static macro function TextToCamel(args:Array<Expr>):Void
static macro function TextToInteger(args:Array<Expr>):Void
static macro function TextToFloat(args:Array<Expr>):Void
static macro function DrawPoint3D(args:Array<Expr>):Void
static macro function DrawCircle3D(args:Array<Expr>):Void
static macro function DrawTriangle3D(args:Array<Expr>):Void
static macro function DrawTriangleStrip3D(args:Array<Expr>):Void
static macro function DrawCylinder(args:Array<Expr>):Void
static macro function DrawCylinderEx(args:Array<Expr>):Void
static macro function DrawCylinderWires(args:Array<Expr>):Void
static macro function DrawCylinderWiresEx(args:Array<Expr>):Void
static macro function DrawCapsule(args:Array<Expr>):Void
static macro function DrawCapsuleWires(args:Array<Expr>):Void
static macro function DrawRay(args:Array<Expr>):Void
static macro function DrawModelWires(args:Array<Expr>):Void
static macro function DrawModelWiresEx(args:Array<Expr>):Void
static macro function DrawModelPoints(args:Array<Expr>):Void
static macro function DrawModelPointsEx(args:Array<Expr>):Void
static macro function DrawBillboard(args:Array<Expr>):Void
static macro function DrawBillboardRec(args:Array<Expr>):Void
static macro function DrawBillboardPro(args:Array<Expr>):Void
static macro function UpdateMeshBuffer(args:Array<Expr>):Void
static macro function DrawMeshInstanced(args:Array<Expr>):Void
static macro function GenMeshTangents(args:Array<Expr>):Void
static macro function ExportMesh(args:Array<Expr>):Void
static macro function ExportMeshAsCode(args:Array<Expr>):Void
static macro function GenMeshPoly(args:Array<Expr>):Void
static macro function GenMeshHemiSphere(args:Array<Expr>):Void
static macro function GenMeshCylinder(args:Array<Expr>):Void
static macro function GenMeshCone(args:Array<Expr>):Void
static macro function GenMeshTorus(args:Array<Expr>):Void
static macro function GenMeshKnot(args:Array<Expr>):Void
static macro function GenMeshHeightmap(args:Array<Expr>):Void
static macro function GenMeshCubicmap(args:Array<Expr>):Void
static macro function LoadMaterials(args:Array<Expr>):Void
static macro function IsMaterialValid(args:Array<Expr>):Void
static macro function UnloadMaterial(args:Array<Expr>):Void
static macro function LoadModelAnimations(args:Array<Expr>):Void
static macro function UpdateModelAnimation(args:Array<Expr>):Void
static macro function UpdateModelAnimationBones(args:Array<Expr>):Void
static macro function UnloadModelAnimation(args:Array<Expr>):Void
static macro function UnloadModelAnimations(args:Array<Expr>):Void
static macro function IsModelAnimationValid(args:Array<Expr>):Void
static macro function GetRayCollisionQuad(args:Array<Expr>):Void
static macro function LoadWave(args:Array<Expr>):Void
static macro function LoadWaveFromMemory(args:Array<Expr>):Void
static macro function IsWaveValid(args:Array<Expr>):Void
static macro function LoadSoundFromWave(args:Array<Expr>):Void
static macro function LoadSoundAlias(args:Array<Expr>):Void
static macro function UpdateSound(args:Array<Expr>):Void
static macro function UnloadWave(args:Array<Expr>):Void
static macro function UnloadSoundAlias(args:Array<Expr>):Void
static macro function ExportWave(args:Array<Expr>):Void
static macro function ExportWaveAsCode(args:Array<Expr>):Void
static macro function PauseSound(args:Array<Expr>):Void
static macro function ResumeSound(args:Array<Expr>):Void
static macro function SetSoundPitch(args:Array<Expr>):Void
static macro function SetSoundPan(args:Array<Expr>):Void
static macro function WaveCopy(args:Array<Expr>):Void
static macro function WaveCrop(args:Array<Expr>):Void
static macro function WaveFormat(args:Array<Expr>):Void
static macro function LoadWaveSamples(args:Array<Expr>):Void
static macro function UnloadWaveSamples(args:Array<Expr>):Void
static macro function LoadMusicStream(args:Array<Expr>):Void
static macro function LoadMusicStreamFromMemory(args:Array<Expr>):Void
static macro function IsMusicValid(args:Array<Expr>):Void
static macro function UnloadMusicStream(args:Array<Expr>):Void
static macro function PlayMusicStream(args:Array<Expr>):Void
static macro function IsMusicStreamPlaying(args:Array<Expr>):Void
static macro function UpdateMusicStream(args:Array<Expr>):Void
static macro function StopMusicStream(args:Array<Expr>):Void
static macro function PauseMusicStream(args:Array<Expr>):Void
static macro function ResumeMusicStream(args:Array<Expr>):Void
static macro function SeekMusicStream(args:Array<Expr>):Void
static macro function SetMusicVolume(args:Array<Expr>):Void
static macro function SetMusicPitch(args:Array<Expr>):Void
static macro function SetMusicPan(args:Array<Expr>):Void
static macro function GetMusicTimeLength(args:Array<Expr>):Void
static macro function GetMusicTimePlayed(args:Array<Expr>):Void
static macro function LoadAudioStream(args:Array<Expr>):Void
static macro function IsAudioStreamValid(args:Array<Expr>):Void
static macro function UnloadAudioStream(args:Array<Expr>):Void
static macro function UpdateAudioStream(args:Array<Expr>):Void
static macro function IsAudioStreamProcessed(args:Array<Expr>):Void
static macro function PlayAudioStream(args:Array<Expr>):Void
static macro function PauseAudioStream(args:Array<Expr>):Void
static macro function ResumeAudioStream(args:Array<Expr>):Void
static macro function IsAudioStreamPlaying(args:Array<Expr>):Void
static macro function StopAudioStream(args:Array<Expr>):Void
static macro function SetAudioStreamVolume(args:Array<Expr>):Void
static macro function SetAudioStreamPitch(args:Array<Expr>):Void
static macro function SetAudioStreamPan(args:Array<Expr>):Void
static macro function SetAudioStreamBufferSizeDefault(args:Array<Expr>):Void
static macro function SetAudioStreamCallback(args:Array<Expr>):Void
static macro function AttachAudioStreamProcessor(args:Array<Expr>):Void
static macro function DetachAudioStreamProcessor(args:Array<Expr>):Void
static macro function AttachAudioMixedProcessor(args:Array<Expr>):Void
static macro function DetachAudioMixedProcessor(args:Array<Expr>):Void
static macro function Normalize(args:Array<Expr>):Void
static macro function Wrap(args:Array<Expr>):Void
static macro function FloatEquals(args:Array<Expr>):Void
static macro function Vector2AddValue(args:Array<Expr>):Void
static macro function Vector2SubtractValue(args:Array<Expr>):Void
static macro function Vector2DotProduct(args:Array<Expr>):Void
static macro function Vector2DistanceSqr(args:Array<Expr>):Void
static macro function Vector2Angle(args:Array<Expr>):Void
static macro function Vector2LineAngle(args:Array<Expr>):Void
static macro function Vector2Negate(args:Array<Expr>):Void
static macro function Vector2Divide(args:Array<Expr>):Void
static macro function Vector2Transform(args:Array<Expr>):Void
static macro function Vector2Reflect(args:Array<Expr>):Void
static macro function Vector2Min(args:Array<Expr>):Void
static macro function Vector2Max(args:Array<Expr>):Void
static macro function Vector2Rotate(args:Array<Expr>):Void
static macro function Vector2MoveTowards(args:Array<Expr>):Void
static macro function Vector2Invert(args:Array<Expr>):Void
static macro function Vector2Clamp(args:Array<Expr>):Void
static macro function Vector2Equals(args:Array<Expr>):Void
static macro function Vector2Refract(args:Array<Expr>):Void
static macro function Vector3AddValue(args:Array<Expr>):Void
static macro function Vector3SubtractValue(args:Array<Expr>):Void
static macro function Vector3Perpendicular(args:Array<Expr>):Void
static macro function Vector3DistanceSqr(args:Array<Expr>):Void
static macro function Vector3Angle(args:Array<Expr>):Void
static macro function Vector3Divide(args:Array<Expr>):Void
static macro function Vector3Project(args:Array<Expr>):Void
static macro function Vector3Reject(args:Array<Expr>):Void
static macro function Vector3OrthoNormalize(args:Array<Expr>):Void
static macro function Vector3RotateByQuaternion(args:Array<Expr>):Void
static macro function Vector3MoveTowards(args:Array<Expr>):Void
static macro function Vector3CubicHermite(args:Array<Expr>):Void
static macro function Vector3Reflect(args:Array<Expr>):Void
static macro function Vector3Min(args:Array<Expr>):Void
static macro function Vector3Max(args:Array<Expr>):Void
static macro function Vector3Barycenter(args:Array<Expr>):Void
static macro function Vector3Unproject(args:Array<Expr>):Void
static macro function Vector3ToFloatV(args:Array<Expr>):Void
static macro function Vector3Invert(args:Array<Expr>):Void
static macro function Vector3Clamp(args:Array<Expr>):Void
static macro function Vector3ClampValue(args:Array<Expr>):Void
static macro function Vector3Equals(args:Array<Expr>):Void
static macro function Vector3Refract(args:Array<Expr>):Void
static macro function Vector4Zero(args:Array<Expr>):Void
static macro function Vector4One(args:Array<Expr>):Void
static macro function Vector4Add(args:Array<Expr>):Void
static macro function Vector4AddValue(args:Array<Expr>):Void
static macro function Vector4Subtract(args:Array<Expr>):Void
static macro function Vector4SubtractValue(args:Array<Expr>):Void
static macro function Vector4Length(args:Array<Expr>):Void
static macro function Vector4LengthSqr(args:Array<Expr>):Void
static macro function Vector4DotProduct(args:Array<Expr>):Void
static macro function Vector4Distance(args:Array<Expr>):Void
static macro function Vector4DistanceSqr(args:Array<Expr>):Void
static macro function Vector4Scale(args:Array<Expr>):Void
static macro function Vector4Multiply(args:Array<Expr>):Void
static macro function Vector4Negate(args:Array<Expr>):Void
static macro function Vector4Divide(args:Array<Expr>):Void
static macro function Vector4Normalize(args:Array<Expr>):Void
static macro function Vector4Min(args:Array<Expr>):Void
static macro function Vector4Max(args:Array<Expr>):Void
static macro function Vector4Lerp(args:Array<Expr>):Void
static macro function Vector4MoveTowards(args:Array<Expr>):Void
static macro function Vector4Invert(args:Array<Expr>):Void
static macro function Vector4Equals(args:Array<Expr>):Void
static macro function MatrixDeterminant(args:Array<Expr>):Void
static macro function MatrixTrace(args:Array<Expr>):Void
static macro function MatrixAdd(args:Array<Expr>):Void
static macro function MatrixSubtract(args:Array<Expr>):Void
static macro function MatrixRotateZYX(args:Array<Expr>):Void
static macro function MatrixFrustum(args:Array<Expr>):Void
static macro function MatrixToFloatV(args:Array<Expr>):Void
static macro function QuaternionAdd(args:Array<Expr>):Void
static macro function QuaternionAddValue(args:Array<Expr>):Void
static macro function QuaternionSubtract(args:Array<Expr>):Void
static macro function QuaternionSubtractValue(args:Array<Expr>):Void
static macro function QuaternionLength(args:Array<Expr>):Void
static macro function QuaternionNormalize(args:Array<Expr>):Void
static macro function QuaternionInvert(args:Array<Expr>):Void
static macro function QuaternionMultiply(args:Array<Expr>):Void
static macro function QuaternionScale(args:Array<Expr>):Void
static macro function QuaternionDivide(args:Array<Expr>):Void
static macro function QuaternionLerp(args:Array<Expr>):Void
static macro function QuaternionNlerp(args:Array<Expr>):Void
static macro function QuaternionSlerp(args:Array<Expr>):Void
static macro function QuaternionCubicHermiteSpline(args:Array<Expr>):Void
static macro function QuaternionFromVector3ToVector3(args:Array<Expr>):Void
static macro function QuaternionFromMatrix(args:Array<Expr>):Void
static macro function QuaternionToAxisAngle(args:Array<Expr>):Void
static macro function QuaternionToEuler(args:Array<Expr>):Void
static macro function QuaternionTransform(args:Array<Expr>):Void
static macro function QuaternionEquals(args:Array<Expr>):Void
static macro function MatrixDecompose(args:Array<Expr>):Void
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
static function LoadTexture(fileName:String):Texture2D
static function UnloadTexture(texture:Texture2D):Void
static function IsTextureValid(texture:Texture2D):Bool
static function DrawTexture(texture:Texture2D, posX:Int, posY:Int, tint:Color):Void
static function DrawTextureV(texture:Texture2D, position:Vector2, tint:Color):Void
static function DrawTextureEx(texture:Texture2D, position:Vector2, rotation:Float, scale:Float, tint:Color):Void
static function DrawTextureRec(texture:Texture2D, source:Rectangle, position:Vector2, tint:Color):Void
static function DrawTexturePro(texture:Texture2D, source:Rectangle, dest:Rectangle, origin:Vector2, rotation:Float, tint:Color):Void
static function DrawText(text:String, posX:Int, posY:Int, fontSize:Int, color:Color):Void
static function MeasureText(text:String, fontSize:Int):Int
static function DrawFPS(posX:Int, posY:Int):Void
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
static function FileExists(fileName:String):Bool
static function LoadFileText(fileName:String):Null<String>
static function UnloadFileText(text:Null<String>):Void
static function SaveFileText(fileName:String, text:String):Bool
static function LoadTextureAsync(fileName:String, loaded:Texture2D -> Void, ?failed:String -> Void):Void
static function LoadModelAsync(fileName:String, loaded:Model -> Void, ?failed:String -> Void):Void
static function LoadSoundAsync(fileName:String, loaded:Sound -> Void, ?failed:String -> Void):Void
static function LoadFileTextAsync(fileName:String, loaded:String -> Void, ?failed:String -> Void):Void
static function ColorNormalize(color:Color):Vector4
static function ColorFromNormalized(normalized:Vector4):Color
static function Fade(color:Color, alpha:Float):Color
static function ColorAlpha(color:Color, alpha:Float):Color
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
static function LoadRenderTexture(width:Int, height:Int):RenderTexture2D
static function IsRenderTextureValid(target:RenderTexture2D):Bool
static function UnloadRenderTexture(target:RenderTexture2D):Void
static function BeginTextureMode(target:RenderTexture2D):Void
static function EndTextureMode():Void
static function SetTextureFilter(texture:Texture2D, filter:Int):Void
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
- `LoadShader`: Loads a shader from raylib GLSL files (330, or 100 for the web), either null for raylib's default stage. They are compiled as the program builds, for every target, so their names are constants; the files are found under `-D helix-ray-files` (default `web`), as the program's other files are.
  - `vsFileName`: The vertex stage's file, or null.
  - `fsFileName`: The fragment stage's file, or null.
  - returns: The shader.
- `LoadShaderFromMemory`: Loads a shader from raylib GLSL text, either null for raylib's default stage. It is compiled as the program builds, so the text is a constant.
  - `vsCode`: The vertex stage's text, or null.
  - `fsCode`: The fragment stage's text, or null.
  - returns: The shader.
- `IsWindowFullscreen`: raylib's `IsWindowFullscreen` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsWindowHidden`: raylib's `IsWindowHidden` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsWindowMinimized`: raylib's `IsWindowMinimized` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsWindowMaximized`: raylib's `IsWindowMaximized` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsWindowFocused`: raylib's `IsWindowFocused` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ToggleFullscreen`: raylib's `ToggleFullscreen` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ToggleBorderlessWindowed`: raylib's `ToggleBorderlessWindowed` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `MaximizeWindow`: raylib's `MaximizeWindow` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `MinimizeWindow`: raylib's `MinimizeWindow` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `RestoreWindow`: raylib's `RestoreWindow` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetWindowIcon`: raylib's `SetWindowIcon` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetWindowIcons`: raylib's `SetWindowIcons` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetWindowPosition`: raylib's `SetWindowPosition` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetWindowMonitor`: raylib's `SetWindowMonitor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetWindowMinSize`: raylib's `SetWindowMinSize` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetWindowMaxSize`: raylib's `SetWindowMaxSize` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetWindowOpacity`: raylib's `SetWindowOpacity` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetWindowFocused`: raylib's `SetWindowFocused` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetWindowHandle`: raylib's `GetWindowHandle` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetMonitorCount`: raylib's `GetMonitorCount` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetCurrentMonitor`: raylib's `GetCurrentMonitor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetMonitorPosition`: raylib's `GetMonitorPosition` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetMonitorWidth`: raylib's `GetMonitorWidth` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetMonitorHeight`: raylib's `GetMonitorHeight` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetMonitorPhysicalWidth`: raylib's `GetMonitorPhysicalWidth` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetMonitorPhysicalHeight`: raylib's `GetMonitorPhysicalHeight` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetMonitorRefreshRate`: raylib's `GetMonitorRefreshRate` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetWindowPosition`: raylib's `GetWindowPosition` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetWindowScaleDPI`: raylib's `GetWindowScaleDPI` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetMonitorName`: raylib's `GetMonitorName` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetClipboardText`: raylib's `SetClipboardText` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetClipboardText`: raylib's `GetClipboardText` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetClipboardImage`: raylib's `GetClipboardImage` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `EnableEventWaiting`: raylib's `EnableEventWaiting` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DisableEventWaiting`: raylib's `DisableEventWaiting` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ShowCursor`: raylib's `ShowCursor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `HideCursor`: raylib's `HideCursor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsCursorHidden`: raylib's `IsCursorHidden` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `EnableCursor`: raylib's `EnableCursor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DisableCursor`: raylib's `DisableCursor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsCursorOnScreen`: raylib's `IsCursorOnScreen` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `BeginBlendMode`: raylib's `BeginBlendMode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `EndBlendMode`: raylib's `EndBlendMode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `BeginScissorMode`: raylib's `BeginScissorMode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `EndScissorMode`: raylib's `EndScissorMode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `BeginVrStereoMode`: raylib's `BeginVrStereoMode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `EndVrStereoMode`: raylib's `EndVrStereoMode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadVrStereoConfig`: raylib's `LoadVrStereoConfig` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadVrStereoConfig`: raylib's `UnloadVrStereoConfig` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SwapScreenBuffer`: raylib's `SwapScreenBuffer` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `PollInputEvents`: raylib's `PollInputEvents` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `WaitTime`: raylib's `WaitTime` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadRandomSequence`: raylib's `LoadRandomSequence` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadRandomSequence`: raylib's `UnloadRandomSequence` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TakeScreenshot`: raylib's `TakeScreenshot` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `OpenURL`: raylib's `OpenURL` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TraceLog`: raylib's `TraceLog` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetTraceLogLevel`: raylib's `SetTraceLogLevel` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `MemAlloc`: raylib's `MemAlloc` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `MemRealloc`: raylib's `MemRealloc` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `MemFree`: raylib's `MemFree` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetTraceLogCallback`: raylib's `SetTraceLogCallback` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetLoadFileDataCallback`: raylib's `SetLoadFileDataCallback` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetSaveFileDataCallback`: raylib's `SetSaveFileDataCallback` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetLoadFileTextCallback`: raylib's `SetLoadFileTextCallback` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetSaveFileTextCallback`: raylib's `SetSaveFileTextCallback` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadFileData`: raylib's `LoadFileData` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadFileData`: raylib's `UnloadFileData` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SaveFileData`: raylib's `SaveFileData` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ExportDataAsCode`: raylib's `ExportDataAsCode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DirectoryExists`: raylib's `DirectoryExists` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsFileExtension`: raylib's `IsFileExtension` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetFileLength`: raylib's `GetFileLength` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetFileExtension`: raylib's `GetFileExtension` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetFileName`: raylib's `GetFileName` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetFileNameWithoutExt`: raylib's `GetFileNameWithoutExt` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetDirectoryPath`: raylib's `GetDirectoryPath` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetPrevDirectoryPath`: raylib's `GetPrevDirectoryPath` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetWorkingDirectory`: raylib's `GetWorkingDirectory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetApplicationDirectory`: raylib's `GetApplicationDirectory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `MakeDirectory`: raylib's `MakeDirectory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ChangeDirectory`: raylib's `ChangeDirectory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsPathFile`: raylib's `IsPathFile` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsFileNameValid`: raylib's `IsFileNameValid` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadDirectoryFiles`: raylib's `LoadDirectoryFiles` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadDirectoryFilesEx`: raylib's `LoadDirectoryFilesEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadDirectoryFiles`: raylib's `UnloadDirectoryFiles` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsFileDropped`: raylib's `IsFileDropped` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadDroppedFiles`: raylib's `LoadDroppedFiles` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadDroppedFiles`: raylib's `UnloadDroppedFiles` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetFileModTime`: raylib's `GetFileModTime` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `CompressData`: raylib's `CompressData` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DecompressData`: raylib's `DecompressData` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `EncodeDataBase64`: raylib's `EncodeDataBase64` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DecodeDataBase64`: raylib's `DecodeDataBase64` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ComputeCRC32`: raylib's `ComputeCRC32` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ComputeMD5`: raylib's `ComputeMD5` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ComputeSHA1`: raylib's `ComputeSHA1` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadAutomationEventList`: raylib's `LoadAutomationEventList` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadAutomationEventList`: raylib's `UnloadAutomationEventList` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ExportAutomationEventList`: raylib's `ExportAutomationEventList` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetAutomationEventList`: raylib's `SetAutomationEventList` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetAutomationEventBaseFrame`: raylib's `SetAutomationEventBaseFrame` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `StartAutomationEventRecording`: raylib's `StartAutomationEventRecording` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `StopAutomationEventRecording`: raylib's `StopAutomationEventRecording` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `PlayAutomationEvent`: raylib's `PlayAutomationEvent` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsKeyPressedRepeat`: raylib's `IsKeyPressedRepeat` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetCharPressed`: raylib's `GetCharPressed` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetGamepadMappings`: raylib's `SetGamepadMappings` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetGamepadVibration`: raylib's `SetGamepadVibration` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetMousePosition`: raylib's `SetMousePosition` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetMouseOffset`: raylib's `SetMouseOffset` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetMouseScale`: raylib's `SetMouseScale` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetMouseWheelMoveV`: raylib's `GetMouseWheelMoveV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetMouseCursor`: raylib's `SetMouseCursor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetTouchPointId`: raylib's `GetTouchPointId` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetGesturesEnabled`: raylib's `SetGesturesEnabled` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetGestureHoldDuration`: raylib's `GetGestureHoldDuration` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetGestureDragVector`: raylib's `GetGestureDragVector` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetGestureDragAngle`: raylib's `GetGestureDragAngle` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetGesturePinchVector`: raylib's `GetGesturePinchVector` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetGesturePinchAngle`: raylib's `GetGesturePinchAngle` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UpdateCameraPro`: raylib's `UpdateCameraPro` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetShapesTexture`: raylib's `SetShapesTexture` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetShapesTexture`: raylib's `GetShapesTexture` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetShapesTextureRectangle`: raylib's `GetShapesTextureRectangle` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawLineStrip`: raylib's `DrawLineStrip` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawLineBezier`: raylib's `DrawLineBezier` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawCircleSector`: raylib's `DrawCircleSector` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawCircleSectorLines`: raylib's `DrawCircleSectorLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawCircleGradient`: raylib's `DrawCircleGradient` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawEllipse`: raylib's `DrawEllipse` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawEllipseLines`: raylib's `DrawEllipseLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawRing`: raylib's `DrawRing` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawRingLines`: raylib's `DrawRingLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawRectanglePro`: raylib's `DrawRectanglePro` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawRectangleGradientV`: raylib's `DrawRectangleGradientV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawRectangleGradientH`: raylib's `DrawRectangleGradientH` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawRectangleGradientEx`: raylib's `DrawRectangleGradientEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawRectangleRounded`: raylib's `DrawRectangleRounded` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawRectangleRoundedLines`: raylib's `DrawRectangleRoundedLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawRectangleRoundedLinesEx`: raylib's `DrawRectangleRoundedLinesEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawTriangleLines`: raylib's `DrawTriangleLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawTriangleFan`: raylib's `DrawTriangleFan` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawTriangleStrip`: raylib's `DrawTriangleStrip` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawPoly`: raylib's `DrawPoly` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawPolyLines`: raylib's `DrawPolyLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawPolyLinesEx`: raylib's `DrawPolyLinesEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawSplineLinear`: raylib's `DrawSplineLinear` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawSplineBasis`: raylib's `DrawSplineBasis` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawSplineCatmullRom`: raylib's `DrawSplineCatmullRom` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawSplineBezierQuadratic`: raylib's `DrawSplineBezierQuadratic` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawSplineBezierCubic`: raylib's `DrawSplineBezierCubic` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawSplineSegmentLinear`: raylib's `DrawSplineSegmentLinear` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawSplineSegmentBasis`: raylib's `DrawSplineSegmentBasis` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawSplineSegmentCatmullRom`: raylib's `DrawSplineSegmentCatmullRom` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawSplineSegmentBezierQuadratic`: raylib's `DrawSplineSegmentBezierQuadratic` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawSplineSegmentBezierCubic`: raylib's `DrawSplineSegmentBezierCubic` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetSplinePointLinear`: raylib's `GetSplinePointLinear` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetSplinePointBasis`: raylib's `GetSplinePointBasis` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetSplinePointCatmullRom`: raylib's `GetSplinePointCatmullRom` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetSplinePointBezierQuad`: raylib's `GetSplinePointBezierQuad` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetSplinePointBezierCubic`: raylib's `GetSplinePointBezierCubic` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `CheckCollisionCircleLine`: raylib's `CheckCollisionCircleLine` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `CheckCollisionPointTriangle`: raylib's `CheckCollisionPointTriangle` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `CheckCollisionPointLine`: raylib's `CheckCollisionPointLine` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `CheckCollisionPointPoly`: raylib's `CheckCollisionPointPoly` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `CheckCollisionLines`: raylib's `CheckCollisionLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetCollisionRec`: raylib's `GetCollisionRec` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadImage`: raylib's `LoadImage` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadImageRaw`: raylib's `LoadImageRaw` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadImageAnim`: raylib's `LoadImageAnim` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadImageAnimFromMemory`: raylib's `LoadImageAnimFromMemory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadImageFromMemory`: raylib's `LoadImageFromMemory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadImageFromTexture`: raylib's `LoadImageFromTexture` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadImageFromScreen`: raylib's `LoadImageFromScreen` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsImageValid`: raylib's `IsImageValid` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadImage`: raylib's `UnloadImage` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ExportImage`: raylib's `ExportImage` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ExportImageToMemory`: raylib's `ExportImageToMemory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ExportImageAsCode`: raylib's `ExportImageAsCode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenImageColor`: raylib's `GenImageColor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenImageGradientLinear`: raylib's `GenImageGradientLinear` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenImageGradientRadial`: raylib's `GenImageGradientRadial` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenImageGradientSquare`: raylib's `GenImageGradientSquare` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenImageChecked`: raylib's `GenImageChecked` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenImageWhiteNoise`: raylib's `GenImageWhiteNoise` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenImagePerlinNoise`: raylib's `GenImagePerlinNoise` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenImageCellular`: raylib's `GenImageCellular` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenImageText`: raylib's `GenImageText` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageCopy`: raylib's `ImageCopy` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageFromImage`: raylib's `ImageFromImage` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageFromChannel`: raylib's `ImageFromChannel` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageText`: raylib's `ImageText` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageTextEx`: raylib's `ImageTextEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageFormat`: raylib's `ImageFormat` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageToPOT`: raylib's `ImageToPOT` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageCrop`: raylib's `ImageCrop` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageAlphaCrop`: raylib's `ImageAlphaCrop` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageAlphaClear`: raylib's `ImageAlphaClear` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageAlphaMask`: raylib's `ImageAlphaMask` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageAlphaPremultiply`: raylib's `ImageAlphaPremultiply` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageBlurGaussian`: raylib's `ImageBlurGaussian` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageKernelConvolution`: raylib's `ImageKernelConvolution` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageResize`: raylib's `ImageResize` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageResizeNN`: raylib's `ImageResizeNN` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageResizeCanvas`: raylib's `ImageResizeCanvas` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageMipmaps`: raylib's `ImageMipmaps` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDither`: raylib's `ImageDither` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageFlipVertical`: raylib's `ImageFlipVertical` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageFlipHorizontal`: raylib's `ImageFlipHorizontal` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageRotate`: raylib's `ImageRotate` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageRotateCW`: raylib's `ImageRotateCW` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageRotateCCW`: raylib's `ImageRotateCCW` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageColorTint`: raylib's `ImageColorTint` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageColorInvert`: raylib's `ImageColorInvert` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageColorGrayscale`: raylib's `ImageColorGrayscale` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageColorContrast`: raylib's `ImageColorContrast` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageColorBrightness`: raylib's `ImageColorBrightness` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageColorReplace`: raylib's `ImageColorReplace` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadImageColors`: raylib's `LoadImageColors` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadImagePalette`: raylib's `LoadImagePalette` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadImageColors`: raylib's `UnloadImageColors` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadImagePalette`: raylib's `UnloadImagePalette` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetImageAlphaBorder`: raylib's `GetImageAlphaBorder` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetImageColor`: raylib's `GetImageColor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageClearBackground`: raylib's `ImageClearBackground` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawPixel`: raylib's `ImageDrawPixel` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawPixelV`: raylib's `ImageDrawPixelV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawLine`: raylib's `ImageDrawLine` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawLineV`: raylib's `ImageDrawLineV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawLineEx`: raylib's `ImageDrawLineEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawCircle`: raylib's `ImageDrawCircle` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawCircleV`: raylib's `ImageDrawCircleV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawCircleLines`: raylib's `ImageDrawCircleLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawCircleLinesV`: raylib's `ImageDrawCircleLinesV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawRectangle`: raylib's `ImageDrawRectangle` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawRectangleV`: raylib's `ImageDrawRectangleV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawRectangleRec`: raylib's `ImageDrawRectangleRec` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawRectangleLines`: raylib's `ImageDrawRectangleLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawTriangle`: raylib's `ImageDrawTriangle` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawTriangleEx`: raylib's `ImageDrawTriangleEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawTriangleLines`: raylib's `ImageDrawTriangleLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawTriangleFan`: raylib's `ImageDrawTriangleFan` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawTriangleStrip`: raylib's `ImageDrawTriangleStrip` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDraw`: raylib's `ImageDraw` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawText`: raylib's `ImageDrawText` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ImageDrawTextEx`: raylib's `ImageDrawTextEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadTextureFromImage`: raylib's `LoadTextureFromImage` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadTextureCubemap`: raylib's `LoadTextureCubemap` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UpdateTexture`: raylib's `UpdateTexture` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UpdateTextureRec`: raylib's `UpdateTextureRec` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenTextureMipmaps`: raylib's `GenTextureMipmaps` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetTextureWrap`: raylib's `SetTextureWrap` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawTextureNPatch`: raylib's `DrawTextureNPatch` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ColorIsEqual`: raylib's `ColorIsEqual` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ColorToInt`: raylib's `ColorToInt` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ColorToHSV`: raylib's `ColorToHSV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ColorFromHSV`: raylib's `ColorFromHSV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ColorTint`: raylib's `ColorTint` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ColorBrightness`: raylib's `ColorBrightness` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ColorContrast`: raylib's `ColorContrast` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ColorAlphaBlend`: raylib's `ColorAlphaBlend` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ColorLerp`: raylib's `ColorLerp` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetColor`: raylib's `GetColor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetPixelColor`: raylib's `GetPixelColor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetPixelColor`: raylib's `SetPixelColor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetPixelDataSize`: raylib's `GetPixelDataSize` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetFontDefault`: raylib's `GetFontDefault` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadFont`: raylib's `LoadFont` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadFontEx`: raylib's `LoadFontEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadFontFromImage`: raylib's `LoadFontFromImage` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadFontFromMemory`: raylib's `LoadFontFromMemory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsFontValid`: raylib's `IsFontValid` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadFontData`: raylib's `LoadFontData` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenImageFontAtlas`: raylib's `GenImageFontAtlas` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadFontData`: raylib's `UnloadFontData` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadFont`: raylib's `UnloadFont` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ExportFontAsCode`: raylib's `ExportFontAsCode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawTextEx`: raylib's `DrawTextEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawTextPro`: raylib's `DrawTextPro` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawTextCodepoint`: raylib's `DrawTextCodepoint` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawTextCodepoints`: raylib's `DrawTextCodepoints` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetTextLineSpacing`: raylib's `SetTextLineSpacing` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `MeasureTextEx`: raylib's `MeasureTextEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetGlyphIndex`: raylib's `GetGlyphIndex` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetGlyphInfo`: raylib's `GetGlyphInfo` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetGlyphAtlasRec`: raylib's `GetGlyphAtlasRec` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadUTF8`: raylib's `LoadUTF8` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadUTF8`: raylib's `UnloadUTF8` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadCodepoints`: raylib's `LoadCodepoints` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadCodepoints`: raylib's `UnloadCodepoints` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetCodepointCount`: raylib's `GetCodepointCount` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetCodepoint`: raylib's `GetCodepoint` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetCodepointNext`: raylib's `GetCodepointNext` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetCodepointPrevious`: raylib's `GetCodepointPrevious` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `CodepointToUTF8`: raylib's `CodepointToUTF8` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextCopy`: raylib's `TextCopy` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextIsEqual`: raylib's `TextIsEqual` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextLength`: raylib's `TextLength` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextFormat`: raylib's `TextFormat` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextSubtext`: raylib's `TextSubtext` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextReplace`: raylib's `TextReplace` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextInsert`: raylib's `TextInsert` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextJoin`: raylib's `TextJoin` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextSplit`: raylib's `TextSplit` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextAppend`: raylib's `TextAppend` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextFindIndex`: raylib's `TextFindIndex` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextToUpper`: raylib's `TextToUpper` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextToLower`: raylib's `TextToLower` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextToPascal`: raylib's `TextToPascal` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextToSnake`: raylib's `TextToSnake` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextToCamel`: raylib's `TextToCamel` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextToInteger`: raylib's `TextToInteger` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `TextToFloat`: raylib's `TextToFloat` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawPoint3D`: raylib's `DrawPoint3D` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawCircle3D`: raylib's `DrawCircle3D` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawTriangle3D`: raylib's `DrawTriangle3D` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawTriangleStrip3D`: raylib's `DrawTriangleStrip3D` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawCylinder`: raylib's `DrawCylinder` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawCylinderEx`: raylib's `DrawCylinderEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawCylinderWires`: raylib's `DrawCylinderWires` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawCylinderWiresEx`: raylib's `DrawCylinderWiresEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawCapsule`: raylib's `DrawCapsule` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawCapsuleWires`: raylib's `DrawCapsuleWires` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawRay`: raylib's `DrawRay` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawModelWires`: raylib's `DrawModelWires` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawModelWiresEx`: raylib's `DrawModelWiresEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawModelPoints`: raylib's `DrawModelPoints` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawModelPointsEx`: raylib's `DrawModelPointsEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawBillboard`: raylib's `DrawBillboard` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawBillboardRec`: raylib's `DrawBillboardRec` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawBillboardPro`: raylib's `DrawBillboardPro` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UpdateMeshBuffer`: raylib's `UpdateMeshBuffer` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DrawMeshInstanced`: raylib's `DrawMeshInstanced` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenMeshTangents`: raylib's `GenMeshTangents` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ExportMesh`: raylib's `ExportMesh` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ExportMeshAsCode`: raylib's `ExportMeshAsCode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenMeshPoly`: raylib's `GenMeshPoly` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenMeshHemiSphere`: raylib's `GenMeshHemiSphere` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenMeshCylinder`: raylib's `GenMeshCylinder` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenMeshCone`: raylib's `GenMeshCone` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenMeshTorus`: raylib's `GenMeshTorus` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenMeshKnot`: raylib's `GenMeshKnot` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenMeshHeightmap`: raylib's `GenMeshHeightmap` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GenMeshCubicmap`: raylib's `GenMeshCubicmap` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadMaterials`: raylib's `LoadMaterials` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsMaterialValid`: raylib's `IsMaterialValid` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadMaterial`: raylib's `UnloadMaterial` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadModelAnimations`: raylib's `LoadModelAnimations` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UpdateModelAnimation`: raylib's `UpdateModelAnimation` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UpdateModelAnimationBones`: raylib's `UpdateModelAnimationBones` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadModelAnimation`: raylib's `UnloadModelAnimation` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadModelAnimations`: raylib's `UnloadModelAnimations` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsModelAnimationValid`: raylib's `IsModelAnimationValid` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetRayCollisionQuad`: raylib's `GetRayCollisionQuad` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadWave`: raylib's `LoadWave` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadWaveFromMemory`: raylib's `LoadWaveFromMemory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsWaveValid`: raylib's `IsWaveValid` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadSoundFromWave`: raylib's `LoadSoundFromWave` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadSoundAlias`: raylib's `LoadSoundAlias` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UpdateSound`: raylib's `UpdateSound` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadWave`: raylib's `UnloadWave` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadSoundAlias`: raylib's `UnloadSoundAlias` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ExportWave`: raylib's `ExportWave` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ExportWaveAsCode`: raylib's `ExportWaveAsCode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `PauseSound`: raylib's `PauseSound` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ResumeSound`: raylib's `ResumeSound` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetSoundPitch`: raylib's `SetSoundPitch` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetSoundPan`: raylib's `SetSoundPan` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `WaveCopy`: raylib's `WaveCopy` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `WaveCrop`: raylib's `WaveCrop` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `WaveFormat`: raylib's `WaveFormat` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadWaveSamples`: raylib's `LoadWaveSamples` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadWaveSamples`: raylib's `UnloadWaveSamples` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadMusicStream`: raylib's `LoadMusicStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadMusicStreamFromMemory`: raylib's `LoadMusicStreamFromMemory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsMusicValid`: raylib's `IsMusicValid` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadMusicStream`: raylib's `UnloadMusicStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `PlayMusicStream`: raylib's `PlayMusicStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsMusicStreamPlaying`: raylib's `IsMusicStreamPlaying` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UpdateMusicStream`: raylib's `UpdateMusicStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `StopMusicStream`: raylib's `StopMusicStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `PauseMusicStream`: raylib's `PauseMusicStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ResumeMusicStream`: raylib's `ResumeMusicStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SeekMusicStream`: raylib's `SeekMusicStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetMusicVolume`: raylib's `SetMusicVolume` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetMusicPitch`: raylib's `SetMusicPitch` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetMusicPan`: raylib's `SetMusicPan` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetMusicTimeLength`: raylib's `GetMusicTimeLength` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `GetMusicTimePlayed`: raylib's `GetMusicTimePlayed` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `LoadAudioStream`: raylib's `LoadAudioStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsAudioStreamValid`: raylib's `IsAudioStreamValid` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UnloadAudioStream`: raylib's `UnloadAudioStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `UpdateAudioStream`: raylib's `UpdateAudioStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsAudioStreamProcessed`: raylib's `IsAudioStreamProcessed` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `PlayAudioStream`: raylib's `PlayAudioStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `PauseAudioStream`: raylib's `PauseAudioStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `ResumeAudioStream`: raylib's `ResumeAudioStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `IsAudioStreamPlaying`: raylib's `IsAudioStreamPlaying` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `StopAudioStream`: raylib's `StopAudioStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetAudioStreamVolume`: raylib's `SetAudioStreamVolume` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetAudioStreamPitch`: raylib's `SetAudioStreamPitch` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetAudioStreamPan`: raylib's `SetAudioStreamPan` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetAudioStreamBufferSizeDefault`: raylib's `SetAudioStreamBufferSizeDefault` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `SetAudioStreamCallback`: raylib's `SetAudioStreamCallback` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `AttachAudioStreamProcessor`: raylib's `AttachAudioStreamProcessor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DetachAudioStreamProcessor`: raylib's `DetachAudioStreamProcessor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `AttachAudioMixedProcessor`: raylib's `AttachAudioMixedProcessor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `DetachAudioMixedProcessor`: raylib's `DetachAudioMixedProcessor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile.
- `Normalize`: raylib's `Normalize` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Wrap`: raylib's `Wrap` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `FloatEquals`: raylib's `FloatEquals` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2AddValue`: raylib's `Vector2AddValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2SubtractValue`: raylib's `Vector2SubtractValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2DotProduct`: raylib's `Vector2DotProduct` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2DistanceSqr`: raylib's `Vector2DistanceSqr` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2Angle`: raylib's `Vector2Angle` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2LineAngle`: raylib's `Vector2LineAngle` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2Negate`: raylib's `Vector2Negate` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2Divide`: raylib's `Vector2Divide` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2Transform`: raylib's `Vector2Transform` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2Reflect`: raylib's `Vector2Reflect` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2Min`: raylib's `Vector2Min` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2Max`: raylib's `Vector2Max` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2Rotate`: raylib's `Vector2Rotate` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2MoveTowards`: raylib's `Vector2MoveTowards` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2Invert`: raylib's `Vector2Invert` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2Clamp`: raylib's `Vector2Clamp` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2Equals`: raylib's `Vector2Equals` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector2Refract`: raylib's `Vector2Refract` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3AddValue`: raylib's `Vector3AddValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3SubtractValue`: raylib's `Vector3SubtractValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3Perpendicular`: raylib's `Vector3Perpendicular` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3DistanceSqr`: raylib's `Vector3DistanceSqr` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3Angle`: raylib's `Vector3Angle` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3Divide`: raylib's `Vector3Divide` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3Project`: raylib's `Vector3Project` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3Reject`: raylib's `Vector3Reject` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3OrthoNormalize`: raylib's `Vector3OrthoNormalize` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3RotateByQuaternion`: raylib's `Vector3RotateByQuaternion` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3MoveTowards`: raylib's `Vector3MoveTowards` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3CubicHermite`: raylib's `Vector3CubicHermite` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3Reflect`: raylib's `Vector3Reflect` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3Min`: raylib's `Vector3Min` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3Max`: raylib's `Vector3Max` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3Barycenter`: raylib's `Vector3Barycenter` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3Unproject`: raylib's `Vector3Unproject` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3ToFloatV`: raylib's `Vector3ToFloatV` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3Invert`: raylib's `Vector3Invert` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3Clamp`: raylib's `Vector3Clamp` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3ClampValue`: raylib's `Vector3ClampValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3Equals`: raylib's `Vector3Equals` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector3Refract`: raylib's `Vector3Refract` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4Zero`: raylib's `Vector4Zero` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4One`: raylib's `Vector4One` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4Add`: raylib's `Vector4Add` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4AddValue`: raylib's `Vector4AddValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4Subtract`: raylib's `Vector4Subtract` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4SubtractValue`: raylib's `Vector4SubtractValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4Length`: raylib's `Vector4Length` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4LengthSqr`: raylib's `Vector4LengthSqr` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4DotProduct`: raylib's `Vector4DotProduct` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4Distance`: raylib's `Vector4Distance` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4DistanceSqr`: raylib's `Vector4DistanceSqr` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4Scale`: raylib's `Vector4Scale` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4Multiply`: raylib's `Vector4Multiply` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4Negate`: raylib's `Vector4Negate` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4Divide`: raylib's `Vector4Divide` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4Normalize`: raylib's `Vector4Normalize` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4Min`: raylib's `Vector4Min` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4Max`: raylib's `Vector4Max` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4Lerp`: raylib's `Vector4Lerp` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4MoveTowards`: raylib's `Vector4MoveTowards` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4Invert`: raylib's `Vector4Invert` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `Vector4Equals`: raylib's `Vector4Equals` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `MatrixDeterminant`: raylib's `MatrixDeterminant` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `MatrixTrace`: raylib's `MatrixTrace` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `MatrixAdd`: raylib's `MatrixAdd` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `MatrixSubtract`: raylib's `MatrixSubtract` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `MatrixRotateZYX`: raylib's `MatrixRotateZYX` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `MatrixFrustum`: raylib's `MatrixFrustum` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `MatrixToFloatV`: raylib's `MatrixToFloatV` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionAdd`: raylib's `QuaternionAdd` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionAddValue`: raylib's `QuaternionAddValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionSubtract`: raylib's `QuaternionSubtract` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionSubtractValue`: raylib's `QuaternionSubtractValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionLength`: raylib's `QuaternionLength` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionNormalize`: raylib's `QuaternionNormalize` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionInvert`: raylib's `QuaternionInvert` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionMultiply`: raylib's `QuaternionMultiply` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionScale`: raylib's `QuaternionScale` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionDivide`: raylib's `QuaternionDivide` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionLerp`: raylib's `QuaternionLerp` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionNlerp`: raylib's `QuaternionNlerp` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionSlerp`: raylib's `QuaternionSlerp` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionCubicHermiteSpline`: raylib's `QuaternionCubicHermiteSpline` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionFromVector3ToVector3`: raylib's `QuaternionFromVector3ToVector3` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionFromMatrix`: raylib's `QuaternionFromMatrix` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionToAxisAngle`: raylib's `QuaternionToAxisAngle` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionToEuler`: raylib's `QuaternionToEuler` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionTransform`: raylib's `QuaternionTransform` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `QuaternionEquals`: raylib's `QuaternionEquals` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
- `MatrixDecompose`: raylib's `MatrixDecompose` (raymath.h): not in helix-ray yet, so a call to it doesn't compile.
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
