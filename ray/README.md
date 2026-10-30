# helix-ray

[raylib](https://www.raylib.com) 5.5's API over [helix-services](../services/README.md) and [helix-platform](../platform/README.md): a
program written as raylib is written runs in a page and natively.

| Type | What |
|---|---|
| `helix.ray.Raylib` | raylib's functions, constants and colors, as `raylib.h` names them, with raymath's |
| `helix.ray.Vector2`, `Rectangle`, `Color`, `Texture2D`, `Sound` | raylib's structs, with their fields |

It is raylib's 2D part: the window and frame, the keyboard, mouse, touch and gamepads, shapes, textures, the default font, sounds and
text files. 3D, shaders, fonts from files and images on the CPU aren't here yet.

## Using it

```
-lib helix-ray
```

Until it is published, link it, and the libraries it's built on, from a checkout:

```
haxelib dev helix-ray <checkout>/ray
```

`-D ray-files=<directory>` names where the program's files are as it builds (default `web`), and `-D ray-native-root=<directory>`
where a native program finds them, relative to itself (default `../web`).

## Examples

- `basic`: raylib's basic window, with a circle at the mouse.

## Depends on

helix-services and helix-platform (and helix-math and helix-log under them). raylib's default font is from raylib 5.5, under its zlib
license (`vendor/raylib-LICENSE`).
