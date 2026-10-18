# HeliX API reference

Generated from the code's doc comments by `tools/gen_apidoc.py` (the same source as the HTML at https://whirlinggizmo.github.io/helix/api/); `python3 tools/gen_apidoc.py --check` fails when it's stale. A file a package, each type with its public members.

- [`helix.adapters and helix.profiles`](adapters.md): 52 adapters and profiles, the platform code
- [`helix.app`](app.md): BaseApp, IApp
- [`helix.assets`](assets.md): AssetCacheMode, AssetManifest, AssetPath, AssetProgress, AssetService, Assets, AudioLocation, CacheRecord, CacheRecords, EnsureOptions, ExportResult, Failure, Fetch, FetchProgress, FetchRequest, FetchResponse, FetchResult, FetchService, IAssets, IExport, IHttp, IReloadable, IRequest, IStore, Lease, Request, Storage, StorageResult, StorageService, StorageSourceResult, StorageWriteResult
- [`helix.audio`](audio.md): Audio, AudioClip, AudioDecodeResult, AudioDecoding, AudioPlayback, AudioResource, AudioResources, AudioStream, IAudio, IAudioDecoder, Pcm, PlayState, StreamOpenResult, Wav
- [`helix.behavior`](behavior.md): Behavior, BehaviorEntry, BehaviorProp, BehaviorPropType, BehaviorRegistry, BehaviorSchema, Behaviors
- [`helix.collision`](collision.md): Collide2D, Hit2D, Move2D, SpatialHash2D
- [`helix.core`](core.md): Job, JobRequest, Jobs, WorkQueue
- [`helix.debug`](debug.md): Autopilot, FpsOverlay, ITestHarness, TestHarness
- [`helix.graphics`](graphics.md): BlendMode, ClipFlip, Graphics, GraphicsUnavailable, IGraphics, IImageDecoder, ImageDecodeResult, ImageDecoding, Mipmaps, PipelineDesc, Pipelines, Png, PostProcess, Primitive, ReadPixelsResult, Sampling, ScreenEffect, ScreenshotResult, ScreenshotService, Screenshots, SdlGpuStages, Shader, ShaderBlock, ShaderParameter, ShaderParameters, ShaderSource, ShaderStages, ShaderTexture, Shaders, TextureFormat, VertexAttribute, VertexBuffer, Wrap
- [`helix.host`](host.md): Adapters, Config, FrameClock, Host, IHost, IWindow, Identity, Presentation, PresentationMode, Runner, Screen, Window, WindowOptions
- [`helix.input`](input.md): Gamepad, IInput, IInputEvents, IInputSource, Input, InputRouter, InputState, Key, MouseButton, PadAxis, PadButton, PointerGestures, Touch
- [`helix.math`](math.md): Curve, CurveKind, Interpolate, Random, Trig
- [`helix.particles`](particles.md): Emitter
- [`helix.render2d`](render2d.md): Align2D, BakedFont, BakedGlyph, Batch2D, Camera2D, Font2D, FontBaker, Fonts, Glyph2D, GlyphOutline, Ktx, Node2D, Particles2D, Polygon2D, Shape2D, ShapeForm, Sprite2D, Stage2D, Text2D, Texture2D, TextureCache, Textures, TrueType
- [`helix.render3d`](render3d.md): AnimationClip, Animator, Attachment, Batch3D, Camera3D, Cube, DirectionalLight, Environment, EnvironmentBake, EnvironmentCache, Environments, Gltf, Hdr, ImageSource, JointPalette, Light, Mat4, Material, Mesh, Model, ModelCache, ModelFile, Models, Node3D, Part, Particles3D, PickHit, PointLight, Ray, Skin, SpotLight, Sprite3D, SpriteAlpha, SpriteFacing, Sprites3D, Stage3D, Text3D, Tonemap, Track, TrackInterpolation, TrackPath
- [`helix.scene`](scene.md): Fade, KindSchema, Loader, Loading, LoadingScene, Node, Pointer, PropertySchema, PropertyType, Scene, SceneBehavior, SceneFile, SceneMaterial, SceneNode, SceneSchema, SceneStage, SceneValue, Scenes, Splash, Transition
- [`helix.time`](time.md): Clock, Ticker, Time, Timer, Timers
- [`helix.tween`](tween.md): Ease, Tween, Tweens
- [`helix.ui`](ui.md): Alignment, Box, BoxDirection, Button, Label, ListView, Panel, ProgressBar, Sizing, Slider, TextField, Theme, Tile, Toggle, Ui, Widget
