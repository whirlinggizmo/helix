# helix.raylib.extras

[Back to the library](README.md)

## Lighting

*class* in [`engines/raylib/src/helix/raylib/extras/Lighting.hx`](../src/helix/raylib/extras/Lighting.hx), `import helix.raylib.extras.Lighting;`

Provides lit shaders, built in, that rlights' lights light (`helix.raylib.Rlights`): `LoadLightingShader`, raylib's lighting examples' `lighting.vs` and `lighting.fs`, which shine every material alike, and `LoadPbrShader`, which draws a glTF's materials as authored, metallic-roughness. Imported apart: `import helix.raylib.extras.Lighting.*;`.

```haxe
var shader = LoadLightingShader();
SetShaderValue(shader, GetShaderLocation(shader, "ambient"), [0.1, 0.1, 0.1, 1.0], SHADER_UNIFORM_VEC4);
var light = CreateLight(LIGHT_POINT, new Vector3(-2, 1, -2), Vector3Zero(), YELLOW, shader);
model.materials[0].shader = shader;
// each frame
SetShaderValue(shader, shader.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z],
SHADER_UNIFORM_VEC3);
UpdateLightValues(shader, light);
```

A model posed by `UpdateModelAnimation` under either is skinned on the GPU. A program's own shader lights as the lit one does by including `<helix/raylib/shaders/lights.glsl>`: rlights' uniforms and `vec4 helixLight(vec4 texelColor, vec4 tint, vec3 fragPosition, vec3 fragNormal)`, called as `helixLight(texture(texture0, fragTexCoord), colDiffuse*fragColor, fragPosition, fragNormal)`; and as the PBR one does by including `<helix/raylib/shaders/pbr.glsl>`, `vec4 helixPbr(vec4 baseColor, float metallic, float roughness, float occlusion, vec3 emissive, vec3 fragPosition, vec3 normal)`. A program that calls none of this links none of it.

### lighting: the lit and PBR shaders rlights' lights light

```haxe
static function LoadLightingShader():Shader
static function LoadPbrShader():Shader
```

- `LoadLightingShader`: Returns raylib's examples' lighting shader (`lighting.vs` and `lighting.fs`), built in. It shines every material alike, one Phong highlight whatever the material says. See `LoadPbrShader` for drawing a glTF's materials as authored.
  - returns: The shader, the program's until `UnloadShader`.

  Set up as raylib's lighting example does: `locs[SHADER_LOC_VECTOR_VIEW]` is `viewPos`, set to the camera's position each frame; `GetShaderLocation(shader, "ambient")` finds the ambient color; lights come from rlights' `CreateLight`. A model posed by `UpdateModelAnimation` under it is skinned on the GPU. A program's own shader lights the same way by including `<helix/raylib/shaders/lights.glsl>`.

  ```haxe
  var shader = LoadLightingShader();
  SetShaderValue(shader, GetShaderLocation(shader, "ambient"), [0.1, 0.1, 0.1, 1.0], SHADER_UNIFORM_VEC4);
  model.materials[0].shader = shader;
  var light = CreateLight(LIGHT_POINT, new Vector3(-2, 1, -2), Vector3Zero(), YELLOW, shader);
  ```
- `LoadPbrShader`: Returns helix-raylib's PBR shader, built in: a glTF's materials drawn as authored, metallic-roughness under the same lights as `LoadLightingShader`, which shines every material alike.
  - returns: The shader, the program's until `UnloadShader`.

  Set up as that one: `locs[SHADER_LOC_VECTOR_VIEW]` is `viewPos`, set to the camera's position each frame; `GetShaderLocation(shader, "ambient")` finds the ambient color; lights come from rlights' `CreateLight`, a light's color what a white surface facing it shows. A model posed by `UpdateModelAnimation` under it is skinned on the GPU. A material marked `unlit` (glTF's `KHR_materials_unlit`) draws its base color and no light.

  Each light also has a range and an intensity, set with `SetShaderValue` at `GetShaderLocation(shader, "lights[0].range")` and `"lights[0].intensity"` (and the next light's at `lights[1]`). A point light with a range dims with distance, fading to nothing at the range, and 0, the default, is no falloff. Intensity is a multiple of the light's color, 1 until set. Light brighter than white rolls off toward white instead of clipping, and colors in the usual range come out as authored.

  Each draw reads the material's maps `MATERIAL_MAP_ALBEDO`, `MATERIAL_MAP_METALNESS`, `MATERIAL_MAP_ROUGHNESS`, `MATERIAL_MAP_NORMAL`, `MATERIAL_MAP_OCCLUSION` and `MATERIAL_MAP_EMISSION`. Their samplers are `albedoMap`, `metalnessMap`, `roughnessMap`, `normalMap`, `occlusionMap` and `emissiveMap`, found at `locs[SHADER_LOC_MAP_ALBEDO]` and the five after it. A missing map reads white, and a missing normal map reads a flat normal.

  Each draw also reads the material's values. `maps[MATERIAL_MAP_ALBEDO].color` times the tint is `colDiffuse`. `maps[MATERIAL_MAP_METALNESS].value` is `metallicValue`, `maps[MATERIAL_MAP_ROUGHNESS].value` is `roughnessValue`, and `maps[MATERIAL_MAP_EMISSION].color` is `emissiveColor`. Colors are taken as linear, as a glTF's factors are. An image's texels are decoded from sRGB. A material from `LoadMaterialDefault` is a smooth non-metal, both values 0, until set.

  A mesh without tangents under a normal map gets them with its first draw (`GenMeshTangents`). A program's own shader draws the same way by including `<helix/raylib/shaders/pbr.glsl>`.

  ```haxe
  var pbr = LoadPbrShader();
  SetShaderValue(pbr, GetShaderLocation(pbr, "ambient"), [0.2, 0.2, 0.2, 1.0], SHADER_UNIFORM_VEC4);
  CreateLight(LIGHT_DIRECTIONAL, new Vector3(2, 4, 2), Vector3Zero(), WHITE, pbr);
  for (m in model.materials)
  m.shader = pbr;
  // each frame
  SetShaderValue(pbr, pbr.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z],
  SHADER_UNIFORM_VEC3);
  ```

## Models

*class* in [`engines/raylib/src/helix/raylib/extras/Models.hx`](../src/helix/raylib/extras/Models.hx), `import helix.raylib.extras.Models;`

Provides what raylib has no call for on models: a model's bounds as posed, which raylib's `GetModelBoundingBox` leaves at the bind pose (`GetModelBoundingBoxPosed`), and models merged into one (`LoadModelFromModels`). Imported apart: `import helix.raylib.extras.Models.*;`.

### models: a skinned model's bounds as posed

```haxe
static function GetModelBoundingBoxPosed(model:Model):BoundingBox
```

- `GetModelBoundingBoxPosed`: Returns a model's bounds as its last `UpdateModelAnimation` (or `UpdateModelAnimationEx`) posed it: `GetModelBoundingBox`'s box, each skinned mesh bounded by its vertices where its bones put them rather than where the skin was bound. A mesh never posed, or without bones, counts as it is, and so does a vertex no bone weights. It is exact whatever shader draws the mesh, as it works the positions out from the pose itself, allocating nothing; that is each skinned vertex moved by its bones, on the CPU, each call. As `GetModelBoundingBox`, its least and most corners are then moved by the model's transform (a turned model's box is not its bounds).
  - `model`: The model.
  - returns: The box.

### models: models merged into one

```haxe
static function LoadModelFromModels(models:Array<Model>, ?skeleton:Model):Null<Model>
```

- `LoadModelFromModels`: Returns a new model with the provided models' meshes merged where possible. The provided models are unchanged. For example, a character's head, body, legs and feet models, whose materials differ only in color, are merged into one character model with one mesh.
  - `models`: The models.
  - `skeleton`: Optional. The model whose bones, bind pose and transform the new model takes. Usually one of the provided models.
  - returns: The new model, or null when refused.

  Meshes whose materials differ only in diffuse color are merged into one mesh. Each material's diffuse color is multiplied into the vertex colors, and the merged mesh has one material, the same material with a white diffuse color. Meshes whose materials differ in anything else (the shader, a texture, `unlit`, or another map's color or value) stay separate meshes.

  A shader that ignores the vertex color draws a merged mesh without the materials' colors.

  A mesh lacking normals, texture coordinates or colors that another merged mesh has gets normals (0, 0, 1), texture coordinates (0, 0) and white colors. Tangents are kept when every merged mesh has them. `texcoords2` is dropped.

  With `skeleton`, the new model has the bones, bind pose and transform of `skeleton`, and an animation that poses `skeleton` poses the new model. Each provided model's bones are matched to the bones of `skeleton` by name. A vertex following a bone that `skeleton` lacks follows the nearest ancestor of that bone that `skeleton` has. A vertex with no such ancestor stays where it is when the new model is posed. A provided model bound in another bind pose is rebound to the bind pose of `skeleton`. A vertex following several bones whose bind poses differ by different amounts is rebound approximately. A provided model without bones is placed where its transform put it.

  Without `skeleton`, the new model has no bones and the identity transform. Each provided model's transform is multiplied into the model's vertices, and a provided model with bones is merged at its bind pose.

  The merged meshes are uploaded. Refused, with the reason logged, for an empty list, for a provided model with bones whose transform differs from the transform of `skeleton`, and for a `skeleton` of more than 256 bones.

## VirtualGamepad

*class* in [`engines/raylib/src/helix/raylib/extras/VirtualGamepad.hx`](../src/helix/raylib/extras/VirtualGamepad.hx), `import helix.raylib.extras.VirtualGamepad;`

Provides on-screen gamepads for phones: sticks and buttons a finger works, read through raylib's gamepad functions. Imported apart, with its constants: `import helix.raylib.extras.VirtualGamepad.*;`.

The first touch anywhere on the screen plugs an enabled virtual gamepad in. A mouse click leaves the virtual gamepad unplugged. Once the virtual gamepad is plugged in, `IsGamepadAvailable` is true for its slot, and its sticks read through `GetGamepadAxisMovement` and its buttons through `IsGamepadButtonDown`, `IsGamepadButtonPressed` and `IsGamepadButtonReleased`. `IsGamepadVirtual` tells a virtual gamepad from a physical one.

A physical gamepad plugged into the virtual gamepad's slot replaces the virtual gamepad. The first physical gamepad plugged in takes slot 0. The next touch after the physical gamepad is unplugged plugs the virtual gamepad in again.

A free finger is a finger that is not currently captured. A stick captures a finger landing in its touch zone, and the buttons a finger landing on one of them. A free finger counts as the mouse, and as a touch point, as every finger does without a virtual gamepad. A captured finger is neither: the touch functions list the free fingers.

The virtual gamepad is drawn at `EndDrawing`, over everything the frame drew. On a device with touch, its buttons and fixed sticks are drawn from the moment it's enabled, and every other stick while it has captured a finger. A program drawing its own controls sets their `visible` to false and draws from `IsVirtualGamepadVisible`, `IsVirtualStickHeld`, `GetVirtualStickBase` and `GetVirtualStickKnob`. The virtual gamepad is hidden while a physical gamepad is in its slot.

```haxe
InitWindow(800, 450, "twin stick");
EnableVirtualGamepad(0);
while (!WindowShouldClose()) {
var moveX = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
var aimX = GetGamepadAxisMovement(0, GAMEPAD_AXIS_RIGHT_X);
// ...
}
```

```haxe
static inline var VIRTUAL_STICK_BASE_FLOATING:Int
static inline var VIRTUAL_STICK_BASE_FOLLOWING:Int
static inline var VIRTUAL_STICK_BASE_FIXED:Int
static inline var VIRTUAL_STICK_LEFT:Int
static inline var VIRTUAL_STICK_RIGHT:Int
```

- `VIRTUAL_STICK_BASE_FLOATING`: A stick whose base is where the finger lands. The base stays there while the stick is held.
- `VIRTUAL_STICK_BASE_FOLLOWING`: A stick whose base is where the finger lands. The base is pulled along when the finger moves past the radius.
- `VIRTUAL_STICK_BASE_FIXED`: A stick whose base stays at the fixed base position. A finger landing anywhere in the stick's touch zone pushes the stick from the base toward the finger. While no finger holds the stick, the stick is drawn at the base, the knob at rest.
- `VIRTUAL_STICK_LEFT`: The left stick, read as `GAMEPAD_AXIS_LEFT_X` and `GAMEPAD_AXIS_LEFT_Y`.
- `VIRTUAL_STICK_RIGHT`: The right stick, read as `GAMEPAD_AXIS_RIGHT_X` and `GAMEPAD_AXIS_RIGHT_Y`.

### virtual gamepad: on-screen sticks read as a gamepad's

```haxe
static function EnableVirtualGamepad(gamepad:Int, ?options:VirtualGamepadOptions):Void
static function DisableVirtualGamepad(gamepad:Int):Void
static function IsGamepadVirtual(gamepad:Int):Bool
static function IsVirtualGamepadVisible(gamepad:Int):Bool
static function IsVirtualStickHeld(gamepad:Int, stick:Int):Bool
static function GetVirtualStickBase(gamepad:Int, stick:Int):Vector2
static function GetVirtualStickKnob(gamepad:Int, stick:Int):Vector2
```

- `EnableVirtualGamepad`: Enables a virtual gamepad in a slot. The first touch after enabling plugs the virtual gamepad in. Enabling it again applies the new options. Its held sticks and buttons, and whether it's plugged in, stay as they were.
  - `gamepad`: The slot, 0 to 3.
  - `options`: Optional. Its sticks, its buttons and their look. Two floating sticks, on the screen's left and right halves, when omitted.

  ```haxe
  EnableVirtualGamepad(0, {
  right: {enabled: false},
  buttons: [{button: GAMEPAD_BUTTON_RIGHT_FACE_DOWN}, {button: GAMEPAD_BUTTON_RIGHT_FACE_RIGHT}]
  });
  ```
- `DisableVirtualGamepad`: Disables the virtual gamepad in a slot, unplugging it. A physical gamepad in that slot is unaffected.
  - `gamepad`: The slot, 0 to 3.
- `IsGamepadVirtual`: Returns whether the gamepad in a slot is a virtual one (`EnableVirtualGamepad`).
  - `gamepad`: The slot, 0 to 3.
  - returns: True while a virtual gamepad is plugged in there. False for a physical one or an empty slot.
- `IsVirtualGamepadVisible`: Returns whether the virtual gamepad in a slot is drawn: enabled, on a device with touch, with no physical gamepad in its slot. A program drawing its own sticks (`visible: false`) draws them while this is true.
  - `gamepad`: The slot, 0 to 3.
  - returns: True while drawn.
- `IsVirtualStickHeld`: Returns whether a finger holds a stick of the virtual gamepad in a slot.
  - `gamepad`: The slot, 0 to 3.
  - `stick`: `VIRTUAL_STICK_LEFT` or `VIRTUAL_STICK_RIGHT`.
  - returns: True while held.
- `GetVirtualStickBase`: Returns where a stick's base is, in the screen's pixels. While the stick isn't held, the base is at the stick's home: the fixed base position, or one and a half radii in from the touch zone's bottom outer corner.
  - `gamepad`: The slot, 0 to 3.
  - `stick`: `VIRTUAL_STICK_LEFT` or `VIRTUAL_STICK_RIGHT`.
  - returns: The base's center. (0, 0) without a virtual gamepad in the slot.
- `GetVirtualStickKnob`: Returns where a stick's knob is, in the screen's pixels: under the finger, held within the radius of the base. While the stick isn't held, the knob is at the base.
  - `gamepad`: The slot, 0 to 3.
  - `stick`: `VIRTUAL_STICK_LEFT` or `VIRTUAL_STICK_RIGHT`.
  - returns: The knob's center. (0, 0) without a virtual gamepad in the slot.
