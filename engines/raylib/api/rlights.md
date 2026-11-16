# Rlights

[Back to the library](README.md)

```haxe
static inline var MAX_LIGHTS:Int
static inline var LIGHT_DIRECTIONAL:Int
static inline var LIGHT_POINT:Int
```

- `MAX_LIGHTS`: The lights raylib's lighting examples make room for, rlights' `MAX_LIGHTS`. A program makes as many as it needs (`CreateLight`).
- `LIGHT_DIRECTIONAL`: A light shining one way from far off, from its position toward its target, rlights' `LIGHT_DIRECTIONAL`.
- `LIGHT_POINT`: A light shining every way from its position, rlights' `LIGHT_POINT`.


```haxe
static function CreateLight(type:Int, position:Vector3, target:Vector3, color:Color, shader:Shader):Light
static function UpdateLightValues(shader:Shader, light:Light):Void
```

- `CreateLight`: Makes a light of the scene, as rlights' `CreateLight` makes one of a shader. The light shines on every lit draw, whichever shader it was made with: the Lighting extra's `LoadLightingShader` and `LoadPbrShader`, and a shader declaring rlights' `lights`, such as raylib's examples' `lighting.fs` or one including `<helix/raylib/shaders/lights.glsl>`. A program makes as many lights as it needs.
  - `type`: `LIGHT_DIRECTIONAL` or `LIGHT_POINT`.
  - `position`: Where it is.
  - `target`: Where it points, for a directional light.
  - `color`: Its color.
  - `shader`: The shader it is made with, as rlights takes one.
  - returns: The light.

  Each draw is lit by the lights reaching it most, as many as its shader's `lights` holds, 8 at most. The light's fields are read at each draw, so the light moves or changes by setting them. The Lighting extra sets its intensity, range and cone, and `UnloadLight` takes it out of the scene.
- `UpdateLightValues`: Kept as rlights' `UpdateLightValues`, for a program written for rlights. A light's fields are read at each draw, so the draws after a change show it with or without this call.
  - `shader`: The shader.
  - `light`: The light.
