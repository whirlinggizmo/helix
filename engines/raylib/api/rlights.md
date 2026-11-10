# Rlights

[Back to the library](README.md)

```haxe
static inline var MAX_LIGHTS:Int
static inline var LIGHT_DIRECTIONAL:Int
static inline var LIGHT_POINT:Int
```

- `MAX_LIGHTS`: The most lights a shader holds, rlights' `MAX_LIGHTS`.
- `LIGHT_DIRECTIONAL`: A light shining one way from far off, from its position toward its target, rlights' `LIGHT_DIRECTIONAL`.
- `LIGHT_POINT`: A light shining every way from its position, rlights' `LIGHT_POINT`.


```haxe
static function CreateLight(type:Int, position:Vector3, target:Vector3, color:Color, shader:Shader):Light
static function UpdateLightValues(shader:Shader, light:Light):Void
```

- `CreateLight`: Makes a light and sets it in a shader, as rlights' `CreateLight`: the next of the shader's `lights`, its locations found by name (`lights[0].enabled` and the rest). Past `MAX_LIGHTS` lights it makes a light that is off and sets nothing. The count is the program's, as rlights' is, not the shader's.
  - `type`: `LIGHT_DIRECTIONAL` or `LIGHT_POINT`.
  - `position`: Where it is.
  - `target`: Where it points, for a directional light.
  - `color`: Its color.
  - `shader`: The shader.
  - returns: The light.
- `UpdateLightValues`: Sets a light's values in a shader, as rlights' `UpdateLightValues`: whether it is on, its type, position, target and color, for the draws after it.
  - `shader`: The shader.
  - `light`: The light.
