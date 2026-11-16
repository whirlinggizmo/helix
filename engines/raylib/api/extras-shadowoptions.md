# ShadowOptions

[Back to the library](README.md)

## ShadowOptions

*class* in [`engines/raylib/src/helix/raylib/extras/ShadowOptions.hx`](../src/helix/raylib/extras/ShadowOptions.hx), `import helix.raylib.extras.ShadowOptions;`

Represents how a light's shadows are made (a light's `shadows`): the shadow map's size and reach, its bias against a surface shadowing itself, and how soft and dark its shadows are. Each field has a default, and each shadow pass reads the fields, held to their ranges there. Biases, the normal offset and softness are in texels of the shadow map the casting lights share, so they hold whatever its size and reach.

```haxe
var mapSize:Int
var distance:Float
var bounds:Null<BoundingBox>
var cascadeCount:Int
var bias:Float
var slopeBias:Float
var normalOffset:Float
var softness:Float
var strength:Float
```

- `mapSize`: Gets or sets the map's width and height, in texels: 2048 by default. A power of two from 256 to 4096; another is rounded down to one, and one under 256 is 256. The lights casting shadows share one map, as large as the largest any of them asks for.
- `distance`: Gets or sets how far from the camera a directional light's shadows reach, in world units: 50 by default. A point or spot light's reach is its range, or this when it has none. Shorter is sharper. Clamped to more than 0.
- `bounds`: Gets or sets the box a directional light's map covers, in place of what the camera sees out to `distance`: null by default, the map following the camera. A fixed box suits a small scene seen whole. The box's corners are read at each shadow pass.
- `cascadeCount`: Gets or sets a directional light's number of cascades: 1 by default. Clamped to 1 to 4. Each covers a farther part of `distance`, near shadows sharp and far ones still there.
- `bias`: Gets or sets the constant bias, in texels: 1 by default. Clamped to 0 or more. Too little and a lit surface speckles with its own shadow; too much and shadows lift off their casters' feet.
- `slopeBias`: Gets or sets the bias added where the light grazes the surface, in texels: 4 by default. Clamped to 0 or more.
- `normalOffset`: Gets or sets how far the lookup moves off the surface along its normal, in texels: 1 by default. Clamped to 0 or more.
- `softness`: Gets or sets how soft a shadow's edge is, in texels: 1 by default. Clamped to 0 to 8. 0 is hard.
- `strength`: Gets or sets how much of the light a shadow takes away: 1 by default. Clamped to 0 to 1.
