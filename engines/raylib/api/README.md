# helix.raylib

Generated from the doc comments by `tools/gen_apidoc.py`.

## Packages

- [`helix.raylib`](types.md)
  - [AudioStream](types.md#audiostream)
  - [AutomationEvent](types.md#automationevent)
  - [AutomationEventList](types.md#automationeventlist)
  - [BoneInfo](types.md#boneinfo)
  - [BoundingBox](types.md#boundingbox)
  - [Camera](types.md#camera)
  - [Camera2D](types.md#camera2d)
  - [Camera3D](types.md#camera3d)
  - [Color](types.md#color)
  - [FilePathList](types.md#filepathlist)
  - [Font](types.md#font)
  - [GlyphInfo](types.md#glyphinfo)
  - [GuiStyleProp](types.md#guistyleprop)
  - [Image](types.md#image)
  - [Light](types.md#light)
  - [Material](types.md#material)
  - [MaterialMap](types.md#materialmap)
  - [Matrix](types.md#matrix)
  - [Mesh](types.md#mesh)
  - [Model](types.md#model)
  - [ModelAnimation](types.md#modelanimation)
  - [ModelMaterials](types.md#modelmaterials)
  - [ModelMeshes](types.md#modelmeshes)
  - [Music](types.md#music)
  - [NPatchInfo](types.md#npatchinfo)
  - [Quaternion](types.md#quaternion)
  - [Ray](types.md#ray)
  - [RayCollision](types.md#raycollision)
  - [Raygui](types.md#raygui)
  - [Raylib](types.md#raylib)
  - [Raylib6](types.md#raylib6)
  - [Raymath](types.md#raymath)
  - [Rectangle](types.md#rectangle)
  - [RenderTexture](types.md#rendertexture)
  - [RenderTexture2D](types.md#rendertexture2d)
  - [Rlgl](types.md#rlgl)
  - [Rlights](types.md#rlights)
  - [Shader](types.md#shader)
  - [Sound](types.md#sound)
  - [Texture](types.md#texture)
  - [Texture2D](types.md#texture2d)
  - [TextureCubemap](types.md#texturecubemap)
  - [Transform](types.md#transform)
  - [Vector2](types.md#vector2)
  - [Vector3](types.md#vector3)
  - [Vector4](types.md#vector4)
  - [VrDeviceInfo](types.md#vrdeviceinfo)
  - [VrStereoConfig](types.md#vrstereoconfig)
  - [Wave](types.md#wave)
- `helix.raylib.extras`
  - [Assets](extras-assets.md): Provides where the program's files come from, and ensures them ahead of raylib's loads, so `LoadTexture`, `LoadSound`, `LoadModel` and the rest answer at once, as in raylib.
  - [Debug](extras-debug.md): Provides drawing for looking at what a program does: a model's skeleton as posed, its posed bounds, and the frame's cost.
    - [FrameStats](extras-debug.md#framestats)
    - [FrameStatsStyle](extras-debug.md#framestatsstyle)
  - [Device](extras-device.md): Provides what a game needs from the device that raylib 5.5 has no call for, helix-raylib's own: the safe area around a notch, what the device is, whether the window can close or go fullscreen, the screen's orientation, and the device's tilt.
  - [GuiSkins](extras-guiskins.md): Provides skins for raygui's controls, helix-raylib's own: a part of a control drawn from a texture, a nine-patch whose corners keep their shape, in place of its style's flat colors.
    - [GuiSkin](extras-guiskins.md#guiskin)
  - [Lighting](extras-lighting.md): Provides the scene's lights, their shadows, and lit shaders, built in: `LoadLightingShader`, raylib's lighting examples' `lighting.vs` and `lighting.fs`, which shine every material alike, and `LoadPbrShader`, which draws a glTF's materials as authored, metallic-roughness.
  - [Materials](extras-materials.md): Provides what a material gives off, where it is cut out, and whether light and shadows fall on it, read by every draw with it: `DrawModel`'s, `DrawMesh`'s and `DrawMeshInstanced`'s, through helix-raylib's default shader and the Lighting extra's lit shaders.
  - [Models](extras-models.md): Provides what raylib has no call for on models: a model's bounds as posed, which raylib's `GetModelBoundingBox` leaves at the bind pose (`GetModelBoundingBoxPosed`), models merged into one (`LoadModelFromModels`), and two animations blended bone by bone (`UpdateModelAnimationMasked`, `GetModelBoneMask`).
  - [Particles](extras-particles.md): Provides particle emitters, in 3D and in 2D.
    - [Emitter2D](extras-particles.md#emitter2d)
    - [Emitter3D](extras-particles.md#emitter3d)
    - [EmitterShape2D](extras-particles.md#emittershape2d)
    - [EmitterShape3D](extras-particles.md#emittershape3d)
    - [Emitter](extras-particles.md#emitter)
    - [EmitterColorKey](extras-particles.md#emittercolorkey)
    - [EmitterSizeKey](extras-particles.md#emittersizekey)
  - [ShadowOptions](extras-shadowoptions.md): Represents how a light's shadows are made (a light's `shadows`): the shadow map's size and reach, its bias against a surface shadowing itself, and how soft and dark its shadows are.
  - [Shadowmaps](extras-shadowmaps.md): Provides raylib's shadowmap example's render texture: a depth buffer a shader can sample, which `BeginTextureMode` draws into.
  - [Sprites](extras-sprites.md): Provides helix-raylib's instanced texture draw, `DrawTextureInstanced`: many copies of one part of a texture, each placed by a matrix, in one call, as three.js's InstancedMesh, Godot's MultiMesh and Unity's instancing draw many of one thing (docs/DECISIONS.md 47).
  - [Textures](extras-textures.md): Provides texture draws beyond raylib's, helix-raylib's own: fills (a bar, a beaker, a mana ball or a cooldown shown up to an amount), tiled draws, nine-patches whose edges repeat, textured polygons, atlases read from a packer's file, and a render texture fitted to the window.
    - [TextureAtlas](extras-textures.md#textureatlas)
  - [VirtualGamepad](extras-virtualgamepad.md): Provides on-screen gamepads for phones: sticks and buttons a finger works, read through raylib's gamepad functions.
    - [VirtualGamepadOptions](extras-virtualgamepad.md#virtualgamepadoptions)
    - [VirtualStickOptions](extras-virtualgamepad.md#virtualstickoptions)
    - [VirtualButtonOptions](extras-virtualgamepad.md#virtualbuttonoptions)

## Shader includes

[shaders.md](shaders.md): `<helix/raylib/shaders/skinning.glsl>`, `<helix/raylib/shaders/lights.glsl>`, `<helix/raylib/shaders/pbr.glsl>`

## Defines

[defines.md](defines.md): the defines a build's hxml sets.
