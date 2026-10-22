# HeliX API reference

Generated from the code's doc comments by `tools/gen_apidoc.py` (the same source as the HTML at https://whirlinggizmo.github.io/helix/api/); `python3 tools/gen_apidoc.py --check` fails when it's stale. A file a package, each type with its public members.

- [`helix.adapter and helix.profile`](adapters.md): 52 adapters and profiles, the platform code
- [`helix.app`](app.md): AppOptions, IApp, Springboard
- [`helix.asset`](asset.md): AssetCacheMode, AssetManifest, AssetPath, AssetProgress, AssetService, Assets, AudioLocation, CacheRecord, CacheRecords, EnsureOptions, ExportResult, Failure, Fetch, FetchPart, FetchProgress, FetchRequest, FetchResponse, FetchResult, FetchService, GrowingSource, IAssets, IExport, IHttp, IReloadable, IRequest, IStore, Lease, Request, SaveService, Saves, Storage, StorageResult, StorageService, StorageSourceResult, StorageWriteResult
- [`helix.audio`](audio.md): Audio, AudioClip, AudioDecodeResult, AudioDecoding, AudioPlayback, AudioResource, AudioResources, AudioStream, Bus, Fade, FadeCurve, IAudio, IAudioDecoder, Pcm, PlayState, StreamOpenResult, Wav
- [`helix.behavior`](behavior.md): Behavior, BehaviorEntry, BehaviorPass, BehaviorProp, BehaviorPropType, BehaviorRegistry, BehaviorSchema, Behaviors, Phase
- [`helix.collision`](collision.md): Body2D, Collide2D, Hit2D, Move2D, SpatialHash2D
- [`helix.core`](core.md): Job, JobRequest, Jobs, WorkQueue
- [`helix.debug`](debug.md): Autopilot, FpsOverlay, ITestHarness, TestHarness
- [`helix.font`](font.md): BakedFont, BakedGlyph, Font, FontBaker, FontCache, Fonts, Glyph, GlyphOutline, TrueType
- [`helix.graphics`](graphics.md): AlphaMode, BlendMode, ClipFlip, Color, CullFace, DepthTest, Graphics, GraphicsUnavailable, IGraphics, IImageDecoder, ImageDecodeResult, ImageDecoding, PipelineDesc, Pipelines, Png, PostProcess, Primitive, ReadPixelsResult, ScreenEffect, ScreenFrame, ScreenshotResult, ScreenshotService, Screenshots, SdlGpuStages, Shader, ShaderBlock, ShaderParameter, ShaderParameters, ShaderSource, ShaderStages, ShaderTexture, Shaders, SpriteEffect, VertexAttribute, VertexBuffer
- [`helix`](helix.md): App
- [`helix.host`](host.md): Adapters, Config, FrameClock, Host, IHost, IWindow, Identity, Part, Presentation, PresentationMode, Runner, Screen, ScreenShape, Window, WindowOptions
- [`helix.input`](input.md): Actions, Anchor, Binding, Gamepad, IInput, IInputEvents, IInputSource, IInputWatcher, Input, InputRouter, InputState, Key, MouseButton, PadAxis, PadButton, PointerGestures, Touch
- [`helix.macro`](macro.md): AppBuild, Haxelib
- [`helix.math`](math.md): Bounds2D, Bounds3D, Curve, CurveKind, Interpolate, Point2D, Point3D, Random, Trig
- [`helix.particle`](particle.md): Emitter, ParticlePreset
- [`helix.render2d`](render2d.md): Align2D, AnimationDirection2D, Batch2D, Camera2D, CameraFollow2D, ChainCalls, Drawing2D, Node2D, Particles2D, Polygon2D, Renderer2D, Shape2D, ShapeForm2D, ShapeShading2D, Sprite2D, SpriteAnimation2D, SpriteAnimator2D, SpriteFrame2D, SpriteSheet2D, Stage, StageService, Text2D, View, View2D, ViewFrame
- [`helix.render3d`](render3d.md): AnimationClip3D, Animator3D, Attachment3D, Batch3D, Camera3D, CubeMap3D, DirectionalLight3D, Drawing3D, Environment3D, EnvironmentBake3D, EnvironmentCache3D, EnvironmentMap3D, Environments3D, Gltf, Hdr, ImageSource3D, JointPalette3D, Light3D, Mat4, Material3D, Mesh3D, MeshShape3D, Model3D, ModelCache3D, ModelFile3D, ModelPass3D, Models3D, Node3D, Orbit3D, Part3D, Particles3D, PickHit3D, PointLight3D, Projection3D, Ray3D, Renderer3D, Skin3D, SpotLight3D, Sprite3D, SpriteFacing3D, SpriteKind3D, Sprites3D, Text3D, Tonemap, Track3D, TrackInterpolation3D, TrackPath3D, View3D
- [`helix.scene`](scene.md): ArgumentSchema3D, Collect2D, Fade, Flow, KindSchema, Loader, Loading, Node, NodeOrigin3D, NodeRecord3D, NodeSnapshot3D, Pointer, PropertySchema, PropertyType, SceneBehavior, SceneEnvironment3D, SceneFile3D, SceneFileCache3D, SceneFiles3D, SceneInstance3D, SceneKinds3D, SceneMaterial3D, SceneMesh3D, SceneNode3D, SceneSchema3D, SceneValue, ShapeSchema3D, Splash, Transition
- [`helix.shader`](shader.md): Bloom, Blur, ChromaticAberration, ColorLut, Crt, Dissolve, Fxaa, HitFlash, LibraryScreenEffect, LibrarySurface, Outline, PaletteSwap, Pixelate, Rim, ShaderLibrary, Silhouette, SpriteDissolve, SpriteFlash, SpriteOutline, SpriteRing, Tonemap, Toon, Unlit, Vignette, Water
- [`helix.texture`](texture.md): Ktx, Mipmaps, Sampling, Texture2D, TextureCache, TextureFormat, Textures, Wrap
- [`helix.time`](time.md): Clock, Ticker, Time, Timer, Timers
- [`helix.tool`](tool.md): Build, Watchers, WebServer
- [`helix.tween`](tween.md): Ease, Tween, Tweens
- [`helix.ui`](ui.md): Alignment2D, Button, Chevron, ColorFormat, ColorPicker, Dropdown, Handle, Label, Layout2D, LayoutDirection2D, ListView, Panel, Popup, ProgressBar, ScrollArea, Scrollbar, ScrollbarVisibility, Separator, Sizing2D, Slider, TextField, Theme, Tile, Toggle, Ui, Widget, WidgetState
