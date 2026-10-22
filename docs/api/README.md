# HeliX API reference

Generated from the code's doc comments by `tools/gen_apidoc.py` (the same source as the HTML at https://whirlinggizmo.github.io/helix/api/); `python3 tools/gen_apidoc.py --check` fails when it's stale. A file a package, each type with its public members.

- [`helix.adapters and helix.profiles`](adapters.md): 52 adapters and profiles, the platform code
- [`helix.app`](app.md): AppOptions, IApp, Springboard
- [`helix.assets`](assets.md): AssetCacheMode, AssetManifest, AssetPath, AssetProgress, AssetService, Assets, AudioLocation, CacheRecord, CacheRecords, EnsureOptions, ExportResult, Failure, Fetch, FetchPart, FetchProgress, FetchRequest, FetchResponse, FetchResult, FetchService, GrowingSource, IAssets, IExport, IHttp, IReloadable, IRequest, IStore, Lease, Request, SaveService, Saves, Storage, StorageResult, StorageService, StorageSourceResult, StorageWriteResult
- [`helix.audio`](audio.md): Audio, AudioClip, AudioDecodeResult, AudioDecoding, AudioPlayback, AudioResource, AudioResources, AudioStream, Bus, Fade, FadeCurve, IAudio, IAudioDecoder, Pcm, PlayState, StreamOpenResult, Wav
- [`helix.behavior`](behavior.md): Behavior, BehaviorEntry, BehaviorPass, BehaviorProp, BehaviorPropType, BehaviorRegistry, BehaviorSchema, Behaviors, Phase
- [`helix.collision`](collision.md): Body2D, Collide2D, Hit2D, Move2D, SpatialHash2D
- [`helix.core`](core.md): Job, JobRequest, Jobs, WorkQueue
- [`helix.debug`](debug.md): Autopilot, FpsOverlay, ITestHarness, TestHarness
- [`helix.graphics`](graphics.md): BlendMode, ClipFlip, Color, CullFace, DepthTest, Graphics, GraphicsUnavailable, IGraphics, IImageDecoder, ImageDecodeResult, ImageDecoding, Mipmaps, PipelineDesc, Pipelines, Png, PostProcess, Primitive, ReadPixelsResult, Sampling, ScreenEffect, ScreenFrame, ScreenshotResult, ScreenshotService, Screenshots, SdlGpuStages, Shader, ShaderBlock, ShaderParameter, ShaderParameters, ShaderSource, ShaderStages, ShaderTexture, Shaders, SpriteEffect, TextureFormat, VertexAttribute, VertexBuffer, Wrap
- [`helix`](helix.md): App
- [`helix.host`](host.md): Adapters, Config, FrameClock, Host, IHost, IWindow, Identity, Part, Presentation, PresentationMode, Runner, Screen, ScreenShape, Window, WindowOptions
- [`helix.input`](input.md): Actions, Anchor, Binding, Gamepad, IInput, IInputEvents, IInputSource, IInputWatcher, Input, InputRouter, InputState, Key, MouseButton, PadAxis, PadButton, PointerGestures, Touch
- [`helix.macro`](macro.md): AppBuild, Haxelib
- [`helix.math`](math.md): Curve, CurveKind, Interpolate, Random, Trig
- [`helix.particles`](particles.md): Emitter
- [`helix.render2d`](render2d.md): Align2D, AnimationDirection, BakedFont, BakedGlyph, Batch2D, Camera2D, CameraFollow2D, ChainCalls, Drawing2D, Font2D, FontBaker, FontCache, Fonts, Glyph2D, GlyphOutline, Ktx, Node2D, Particles2D, Polygon2D, Renderer2D, Shape2D, ShapeForm, ShapeShading, Sprite2D, SpriteAnimation, SpriteAnimator, SpriteFrame, SpriteSheet, Stage, StageService, Text2D, Texture2D, TextureCache, Textures, TrueType, View, View2D, ViewFrame
- [`helix.render3d`](render3d.md): AnimationClip, Animator, Attachment, Batch3D, Camera3D, Cube, DirectionalLight, Drawing3D, Environment, Environment3D, EnvironmentBake, EnvironmentCache, Environments, Gltf, Hdr, ImageSource, JointPalette, Light, Mat4, Material, Mesh, MeshShape, Model, ModelCache, ModelFile, ModelPass, Models, Node3D, Orbit, Part, Particles3D, PickHit, PointLight, Projection, Ray, Renderer3D, Skin, SpotLight, Sprite3D, SpriteAlpha, SpriteFacing, SpriteKind, Sprites3D, Text3D, Tonemap, Track, TrackInterpolation, TrackPath, View3D
- [`helix.scene`](scene.md): ArgumentSchema, Fade, Flow, KindSchema, Loader, Loading, Node, NodeOrigin, NodeRecord, NodeSnapshot, Pointer, PropertySchema, PropertyType, SceneBehavior, SceneEnvironment3D, SceneFile3D, SceneFileCache3D, SceneFiles3D, SceneInstance3D, SceneKinds3D, SceneMaterial, SceneMesh, SceneNode3D, SceneSchema, SceneValue, ShapeSchema, Splash, Transition
- [`helix.shaders`](shaders.md): Bloom, Blur, ChromaticAberration, ColorLut, Crt, Dissolve, Fxaa, HitFlash, LibraryScreenEffect, LibrarySurface, Outline, PaletteSwap, Pixelate, Rim, ShaderLibrary, Silhouette, SpriteDissolve, SpriteFlash, SpriteOutline, Tonemap, Toon, Unlit, Vignette, Water
- [`helix.time`](time.md): Clock, Ticker, Time, Timer, Timers
- [`helix.tools`](tools.md): Build, Watchers, WebServer
- [`helix.tween`](tween.md): Ease, Tween, Tweens
- [`helix.ui`](ui.md): Alignment, Button, Chevron, ColorFormat, ColorPicker, Dropdown, Handle, Label, Layout2D, Layout2DDirection, ListView, Panel, Popup, ProgressBar, ScrollArea, Scrollbar, ScrollbarVisibility, Separator, Sizing, Slider, TextField, Theme, Tile, Toggle, Ui, Widget, WidgetState
