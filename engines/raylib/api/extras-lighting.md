# Lighting

[Back to the library](README.md)

## Lighting

*class* in [`engines/raylib/src/helix/raylib/extras/Lighting.hx`](../src/helix/raylib/extras/Lighting.hx), `import helix.raylib.extras.Lighting;`

Provides the scene's lights, their shadows, and lit shaders, built in: `LoadLightingShader`, raylib's lighting examples' `lighting.vs` and `lighting.fs`, which shine every material alike, and `LoadPbrShader`, which draws a glTF's materials as authored, metallic-roughness. Imported apart: `import helix.raylib.extras.Lighting.*;`.

The example `engines/raylib/examples/extras/lighting` uses it.

```haxe
var pbr = LoadPbrShader();
SetShaderValue(pbr, GetShaderLocation(pbr, "ambient"), [0.1, 0.1, 0.1, 1.0], SHADER_UNIFORM_VEC4);
for (m in model.materials)
m.shader = pbr;
var sun = CreateLight(LIGHT_DIRECTIONAL, new Vector3(4, 10, 2), Vector3Zero(), WHITE, pbr);
var lamp = CreateLight(LIGHT_POINT, new Vector3(-2, 1, -2), Vector3Zero(), YELLOW, pbr);
SetLightRange(lamp, 6);
// each frame
SetShaderValue(pbr, pbr.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z],
SHADER_UNIFORM_VEC3);
```

**Lights.** rlights' `CreateLight` (`helix.raylib.Rlights`) makes a light of the scene, as many as the program makes. A light shines on every lit draw, whichever shader it was made with: `LoadPbrShader`'s, `LoadLightingShader`'s, and a program's own that includes `<helix/raylib/shaders/lights.glsl>` or `<helix/raylib/shaders/pbr.glsl>`. Its fields (`enabled`, `position`, `target`, `color`) are read at each draw, so a light moves by setting them, with no other call. `UnloadLight` takes it out of the scene.

**Which lights reach a draw.** Each draw is lit by the 8 lights that reach it most, scored against its bounds: a light's brightness (its color times its intensity), times its falloff at the bounds' nearest point (none past its range), times a spot light's cone. A directional light reaches everything. A point or spot light without a range reaches everything too, so a scene of many lamps gives each one a range. `DrawMeshInstanced` scores its lights against the bounds of all its instances.

**A program's own shader.** Including `<helix/raylib/shaders/lights.glsl>` gives `lights[MAX_LIGHTS]`, the draw's own lights (8), `ambient` and `viewPos`, and `vec4 helixLight(vec4 texelColor, vec4 tint, vec3 fragPosition, vec3 fragNormal)`, called as `helixLight(texture(texture0, fragTexCoord), colDiffuse*fragColor, fragPosition, fragNormal)`. Including `<helix/raylib/shaders/pbr.glsl>` gives `vec4 helixPbr(vec4 baseColor, float metallic, float roughness, float occlusion, vec3 emissive, vec3 fragPosition, vec3 normal)`, and the material's `emissiveColor` and `alphaCutoff` (the Materials extra). Both take the world position and normal as raylib's `lighting.vs` passes them: `fragPosition` is `vec3(matModel*vec4(vertexPosition, 1.0))` and `fragNormal` is `normalize(vec3(matNormal*vec4(vertexNormal, 1.0)))`. A model posed by `UpdateModelAnimation` under a lit shader is skinned on the GPU. A program that calls none of this links none of it.

**Shadows.**

```haxe
SetLightShadows(sun, {mapSize: 2048, distance: 30, cascades: 2});
SetLightShadows(lamp);
// each frame, before BeginDrawing or after it and before BeginMode3D
BeginShadowMode(camera);
DrawModel(island, Vector3Zero(), 1, WHITE);
DrawModel(hut, hutPosition, 1, WHITE);
EndShadowMode();
BeginDrawing();
BeginMode3D(camera);
DrawModel(island, Vector3Zero(), 1, WHITE);
DrawModel(hut, hutPosition, 1, WHITE);
EndMode3D();
EndDrawing();
```

A light casts shadows once `SetLightShadows` turns them on, 4 lights at most. One shadow pass a frame, between `BeginShadowMode` and `EndShadowMode`, makes the shadows of every such light: its casters are drawn once there and cast for each light. A frame without the pass keeps the shadows of the last one. Every lit draw receives them, and a program's own shader through `<helix/raylib/shaders/shadows.glsl>`: `float helixShadow(int light, vec3 fragPosition, vec3 fragNormal)`, its light an index of `lights`, 0 in full shadow to 1 in full light. A directional light's shadows follow the camera, and a point light's fall every way from it.

A shader compiled by `CompileShaderFile` carries its shadow variant: its own vertex stage, with a fragment stage writing depth alone and cutting at the material's alpha cutoff (the Materials extra). The shadow pass draws through it.

```haxe
static inline var LIGHT_SPOT:Int
```

- `LIGHT_SPOT`: A light shining in a cone from its position toward its target, made by `SetLightCone`. Its `type` is this.

### lighting: the lit and PBR shaders, a light's intensity, range and cone, and its shadows

```haxe
static function LoadLightingShader():Shader
static function LoadPbrShader():Shader
static function SetLightIntensity(light:Light, intensity:Float):Void
static function SetLightRange(light:Light, range:Float):Void
static function SetLightCone(light:Light, innerAngle:Float, outerAngle:Float):Void
static function UnloadLight(light:Light):Void
static function SetLightShadows(light:Light, ?options:ShadowOptions):Void
static function GetLightShadows(light:Light, ?out:ShadowOptions):Null<ShadowOptions>
static function BeginShadowMode(camera:Camera3D):Void
static function EndShadowMode():Void
```

- `LoadLightingShader`: Returns raylib's examples' lighting shader (`lighting.vs` and `lighting.fs`), built in. It shines every material alike, one Phong highlight whatever the material says. See `LoadPbrShader` for drawing a glTF's materials as authored.
  - returns: The shader, the program's until `UnloadShader`.

  Set up as raylib's lighting example does: `locs[SHADER_LOC_VECTOR_VIEW]` is `viewPos`, set to the camera's position each frame; `GetShaderLocation(shader, "ambient")` finds the ambient color. The scene's lights light it (see the class).

  ```haxe
  var shader = LoadLightingShader();
  SetShaderValue(shader, GetShaderLocation(shader, "ambient"), [0.1, 0.1, 0.1, 1.0], SHADER_UNIFORM_VEC4);
  model.materials[0].shader = shader;
  var light = CreateLight(LIGHT_POINT, new Vector3(-2, 1, -2), Vector3Zero(), YELLOW, shader);
  ```
- `LoadPbrShader`: Returns helix-raylib's PBR shader, built in: a glTF's materials drawn as authored, metallic-roughness under the scene's lights, where `LoadLightingShader` shines every material alike.
  - returns: The shader, the program's until `UnloadShader`.

  Set up as that one: `locs[SHADER_LOC_VECTOR_VIEW]` is `viewPos`, set to the camera's position each frame; `GetShaderLocation(shader, "ambient")` finds the ambient color. A light's color is what a white surface facing it shows at intensity 1. Light brighter than white rolls off toward white instead of clipping, and colors in the usual range come out as authored. A material marked `unlit` (glTF's `KHR_materials_unlit`) draws its base color and no light.

  Each draw reads the material's maps `MATERIAL_MAP_ALBEDO`, `MATERIAL_MAP_METALNESS`, `MATERIAL_MAP_ROUGHNESS`, `MATERIAL_MAP_NORMAL`, `MATERIAL_MAP_OCCLUSION` and `MATERIAL_MAP_EMISSION`. Their samplers are `albedoMap`, `metalnessMap`, `roughnessMap`, `normalMap`, `occlusionMap` and `emissiveMap`, found at `locs[SHADER_LOC_MAP_ALBEDO]` and the five after it. A missing map reads white, and a missing normal map reads a flat normal.

  Each draw also reads the material's values. `maps[MATERIAL_MAP_ALBEDO].color` times the tint is `colDiffuse`. `maps[MATERIAL_MAP_METALNESS].value` is `metallicValue`, and `maps[MATERIAL_MAP_ROUGHNESS].value` is `roughnessValue`. Its emission and alpha cutoff are the Materials extra's. Colors are taken as linear, as a glTF's factors are. An image's texels are decoded from sRGB. A material from `LoadMaterialDefault` is a smooth non-metal, both values 0, until set.

  A mesh without tangents under a normal map gets them with its first draw (`GenMeshTangents`).

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
- `SetLightIntensity`: Sets how bright a light is: its color times the intensity. 1 until set; 0 gives no light, as `enabled` false does.
  - `light`: The light, from `CreateLight`.
  - `intensity`: How bright, 0 or more.
- `SetLightRange`: Sets how far a point or spot light reaches: it dims with distance, fading to nothing at the range, and lights no draw whose bounds lie past it. 0, the default, is no falloff and no limit. A directional light has no range.
  - `light`: The light, from `CreateLight`.
  - `range`: How far, in world units, 0 or more.
- `SetLightCone`: Makes a light a spot light (`LIGHT_SPOT`), shining from its position toward its target in a cone: full inside `innerAngle`, fading to nothing at `outerAngle`, each measured from the cone's middle. A spot light dims with distance as a point light does.
  - `light`: The light, from `CreateLight`.
  - `innerAngle`: Where the fade starts, in degrees.
  - `outerAngle`: Where it ends, in degrees, at least `innerAngle` and under 90.
- `UnloadLight`: Takes a light out of the scene. It lights nothing after, and its shadows are freed.
  - `light`: The light, from `CreateLight`.
- `SetLightShadows`: Makes a light cast shadows, made as the options say. Its shadows take a map of `mapSize` squared texels: one for each cascade of a directional light, six for a point light, one for a spot light. 4 lights cast shadows at most: a fifth's are off, with a warning. `UnloadLight` frees a light's shadows.
  - `light`: The light, from `CreateLight`.
  - `options`: Optional. How its shadows are made; the defaults when omitted or null.
- `GetLightShadows`: Returns how a light's shadows are made, as `SetLightShadows` set them, each default filled in; null when it casts none.
  - `light`: The light, from `CreateLight`.
  - `out`: Optional. The options filled; new ones when omitted.
  - returns: out or the new options, or null when the light casts no shadows.
- `BeginShadowMode`: Starts the frame's shadow pass, until `EndShadowMode`: what is drawn casts shadows, from every light that casts them, and is drawn nowhere else. Call it before `BeginDrawing`, or after it and before `BeginMode3D`, not within a 3D or texture mode.
  - `camera`: The camera the frame is drawn from, which a directional light's shadows follow.

  Draw the casters as the frame draws them, models and meshes posed and placed the same. Each draw runs its own shader's vertex stage, so a caster swaying, skinned or instanced there casts its shadow as it is drawn, and writes depth alone. A material with an alpha cutoff (the Materials extra) casts nothing where its albedo's alpha is below the cutoff. Each light's maps take what was drawn once, less the draws whose bounds fall outside a map's view.

  - **What a shadow keeps:** the vertex stage, given the same uniforms as the draw (bone matrices, a sway's time), and the material's alpha cutoff. A fragment stage's own `discard` (a dissolve) isn't in the shadow. - **Cut out:** only where the vertex stage passes on `fragTexCoord`, which the cutoff samples the albedo at. A vertex stage without it casts its whole shape. - **Cost:** every cascade and every face of a point light draws the casters again. A point light's shadows cost about six times a directional light's single map.
- `EndShadowMode`: Ends the shadow pass `BeginShadowMode` began. The lit draws after it receive its shadows.

## ShadowOptions

*class* in [`engines/raylib/src/helix/raylib/extras/ShadowOptions.hx`](../src/helix/raylib/extras/ShadowOptions.hx), `import helix.raylib.extras.ShadowOptions;`

Represents how a light's shadows are made: the shadow map's size and reach, its bias against a surface shadowing itself, and how soft and dark its shadows are. Each field has a default. Sizes and biases are in shadow-map texels, so they hold whatever the map's size and reach.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?mapSize:Int, ?distance:Float, ?bounds:BoundingBox, ?cascades:Int, ?bias:Float, ?slopeBias:Float, ?normalOffset:Float, ?softness:Float, ?strength:Float}
```

```haxe
var mapSize:Null<Int>
var distance:Null<Float>
var bounds:Null<BoundingBox>
var cascades:Null<Int>
var bias:Null<Float>
var slopeBias:Null<Float>
var normalOffset:Null<Float>
var softness:Null<Float>
var strength:Null<Float>
```

- `mapSize`: Gets or sets the map's width and height, in texels: 2048 when not given. A power of two from 256 to 4096; another is rounded down to one.
- `distance`: Gets or sets how far from the camera a directional light's shadows reach, in world units: 50 when not given. A point light's reach is its range, or this when it has none. Shorter is sharper.
- `bounds`: Gets or sets the box a directional light's map covers, in place of what the camera sees out to `distance`: none when not given, so the map follows the camera. A fixed box suits a small scene seen whole.
- `cascades`: Gets or sets a directional light's number of cascades, 1 to 4: 1 when not given. Each covers a farther part of `distance`, near shadows sharp and far ones still there.
- `bias`: Gets or sets the constant bias, in texels: 1 when not given. Too little and a lit surface speckles with its own shadow; too much and shadows lift off their casters' feet.
- `slopeBias`: Gets or sets the bias added where the light grazes the surface, in texels: 4 when not given.
- `normalOffset`: Gets or sets how far the lookup moves off the surface along its normal, in texels: 1 when not given.
- `softness`: Gets or sets how soft a shadow's edge is, in texels: 1 when not given. 0 is hard.
- `strength`: Gets or sets how much of the light a shadow takes away, 0 to 1: 1 when not given.
