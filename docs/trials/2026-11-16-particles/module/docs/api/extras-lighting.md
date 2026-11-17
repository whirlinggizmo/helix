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
lamp.range = 6;
// each frame
SetShaderValue(pbr, pbr.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z],
SHADER_UNIFORM_VEC3);
```

**Lights.** rlights' `CreateLight` (`helix.raylib.Rlights`) makes a light of the scene, as many as the program makes. A light shines on every lit draw, whichever shader it was made with: `LoadPbrShader`'s, `LoadLightingShader`'s, and a program's own that includes `<helix/raylib/shaders/lights.glsl>` or `<helix/raylib/shaders/pbr.glsl>`. Its fields (`enabled`, `position`, `target`, `color`, and the extra's `intensity`, `range`, `innerAngle` and `outerAngle`) are read at each draw, so a light moves or changes by setting them, with no other call. A spot light is made with `LIGHT_SPOT` and given a cone by its angles. `UnloadLight` takes it out of the scene.

**Which lights reach a draw.** Each draw is lit by the 8 lights that reach it most, scored against its bounds: a light's brightness (its color times its intensity), times its falloff at the bounds' nearest point (none past its range), times a spot light's cone. A directional light reaches everything. A point or spot light without a range reaches everything too, so a scene of many lamps gives each one a range. `DrawMeshInstanced` scores its lights against the bounds of all its instances.

**A program's own shader.** Including `<helix/raylib/shaders/lights.glsl>` gives `lights[MAX_LIGHTS]`, the draw's own lights (8), `ambient` and `viewPos`, and `vec4 helixLight(vec4 texelColor, vec4 tint, vec3 fragPosition, vec3 fragNormal)`, called as `helixLight(texture(texture0, fragTexCoord), colDiffuse*fragColor, fragPosition, fragNormal)`. Including `<helix/raylib/shaders/pbr.glsl>` gives `vec4 helixPbr(vec4 baseColor, float metallic, float roughness, float occlusion, vec3 emissive, vec3 fragPosition, vec3 normal)`, and the material's `emissiveColor` and `alphaCutoff` (the Materials extra). Both take the world position and normal as raylib's `lighting.vs` passes them: `fragPosition` is `vec3(matModel*vec4(vertexPosition, 1.0))` and `fragNormal` is `normalize(vec3(matNormal*vec4(vertexNormal, 1.0)))`. A model posed by `UpdateModelAnimation` under a lit shader is skinned on the GPU. A program that calls none of this links none of it.

**Shadows.**

```haxe
sun.shadows.distance = 30;
sun.shadows.cascadeCount = 2;
EnableLightShadows(sun);
EnableLightShadows(lamp);
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

A light casts shadows once `EnableLightShadows` turns them on, 4 lights at most. The light's `shadows` say how they are made, each field read at each shadow pass. The casting lights share one shadow map, as large as the largest `mapSize` asked for. One shadow pass a frame, between `BeginShadowMode` and `EndShadowMode`, makes the shadows of every such light: its casters are drawn once there and cast for each light. A frame without the pass keeps the shadows of the last one. Every lit draw receives them, and a program's own shader through `<helix/raylib/shaders/shadows.glsl>`: `float helixShadow(int light, vec3 fragPosition, vec3 fragNormal)`, its light an index of `lights`, 0 in full shadow to 1 in full light. A directional light's shadows follow the camera, and a point light's fall every way from it.

A shader compiled by `CompileShaderFile` carries its shadow variant: its own vertex stage, with a fragment stage writing depth alone and cutting at the material's alpha cutoff (the Materials extra). The shadow pass draws through it.

```haxe
static inline var LIGHT_SPOT:Int
```

- `LIGHT_SPOT`: A light shining in a cone from its position toward its target, between a light's `innerAngle` and `outerAngle`: a light's `type`, given to `CreateLight` or set.

### lighting: the lit and PBR shaders and a light's shadows

```haxe
static function LoadLightingShader():Shader
static function LoadPbrShader():Shader
static function UnloadLight(light:Light):Void
static function EnableLightShadows(light:Light):Bool
static function DisableLightShadows(light:Light):Void
static function IsLightCastingShadows(light:Light):Bool
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
- `UnloadLight`: Takes a light out of the scene. It lights nothing after, and its shadows are freed.
  - `light`: The light, from `CreateLight`.
- `EnableLightShadows`: Turns a light's shadows on. A light casts none until then. The light's `shadows` say how its shadows are made.
  - `light`: The light, from `CreateLight`.
  - returns: False when refused, as 4 other lights cast shadows.

  4 lights cast shadows at most. Enabling a fifth's is refused, with a warning, and the fifth casts none. `DisableLightShadows` and `UnloadLight` free a light's place for another.
- `DisableLightShadows`: Turns a light's shadows off, freeing its place among the 4 lights that may cast them. Its `shadows` are kept.
  - `light`: The light, from `CreateLight`.
- `IsLightCastingShadows`: Returns whether a light casts shadows (`EnableLightShadows`).
  - `light`: The light, from `CreateLight`.
  - returns: true when it casts shadows.
- `BeginShadowMode`: Starts the frame's shadow pass, until `EndShadowMode`: what is drawn casts shadows, from every light that casts them, and is drawn nowhere else. Call it before `BeginDrawing`, or after it and before `BeginMode3D`, not within a 3D or texture mode.
  - `camera`: The camera the frame is drawn from, which a directional light's shadows follow.

  Draw the casters as the frame draws them, models and meshes posed and placed the same. Each draw runs its own shader's vertex stage, so a caster swaying, skinned or instanced there casts its shadow as it is drawn, and writes depth alone. A material with an alpha cutoff (the Materials extra) casts nothing where its albedo's alpha is below the cutoff. Each light's maps take what was drawn once, less the draws whose bounds fall outside a map's view.

  - **What a shadow keeps:** the vertex stage, given the same uniforms as the draw (bone matrices, a sway's time), and the material's alpha cutoff. A fragment stage's own `discard` (a dissolve) isn't in the shadow. - **Cut out:** only where the vertex stage passes on `fragTexCoord`, which the cutoff samples the albedo at. A vertex stage without it casts its whole shape. - **Cost:** every cascade and every face of a point light draws the casters again. A point light's shadows cost about six times a directional light's single map.
- `EndShadowMode`: Ends the shadow pass `BeginShadowMode` began. The lit draws after it receive its shadows.
