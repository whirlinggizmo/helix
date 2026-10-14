# Architecture

HeliX is three layers, and code belongs to exactly one of them.

| Layer | Where | What it is |
| --- | --- | --- |
| Engine | `src/helix/` outside `adapters/` and `profiles/` | Everything that is the same on every platform: rendering (`render2d`, `render3d`, the framework's shaders and pipelines), assets, audio resources, input state, particles, math, the host core. Pure Haxe; no platform API, no target conditional. |
| Platform contracts | the interfaces the engine calls: `IGraphics`, `IAudio`, `IInput`, `IFetch`, `IStorage`, `IImages`, `IWindow`, and the platform half of a host (`HostServices`) | What a platform must provide, stated as capabilities, not as engine features. |
| Adapters | `src/helix/adapters/<area>/<api>/` | One platform API behind one contract: a hardware/OS abstraction layer, nothing more. |

A **profile** (`src/helix/profiles/`) picks one adapter per contract for a target and composes them into `HostServices`.

## The adapter rule

An adapter holds only what differs because of its platform or API. Concretely:

- **In an adapter:** calls into the platform API; the API's quirks and limits worked around (GL's bottom-left origin, sokol's one write per image a frame, WebGL2's missing base instance); resource handles and their bookkeeping; threads and callbacks the API needs, delivered back on the host thread; validation that protects the platform (native memory, the GL state).
- **Never in an adapter:** anything another adapter of the same contract would have to repeat. Formats the engine reads (decoding a WAV, a glTF, a .hdr), the framework's programs, layouts and pipelines, policies (queue sizes, caching, retries, lifetimes), state machines over the platform's events (edges, gestures, a frame's order), engine services and their wiring.
- **The test:** if a second adapter for the same contract (WebGPU beside WebGL2, SDL3 beside sokol) would copy a piece of code, that piece belongs in the engine, and the contract hands the adapter data instead.

`tools/adaptercheck.py` enforces what can be checked mechanically (below); review covers the rest.

## Adapters

| Contract | Adapter | Platform | Responsibility |
| --- | --- | --- | --- |
| `IGraphics` | `graphics/webgl2` | browser | WebGL2: textures (2D, cube, data, render targets, depth arrays), buffers, programs built from a `ShaderSource`'s GLSL ES, pipelines made as a `PipelineDesc` says, passes, one draw. |
| `IGraphics` | `graphics/sokol` (+ C) | native | sokol_gfx (GL 4.1 core): the same, from GLSL 410, passed to C as plain data. |

*(The remaining contracts are being audited; this table grows as each is settled.)*

## Graphics

`IGraphics` knows no program, layout or pipeline of HeliX's own. The engine describes them as data:

- **Programs:** each framework shader in `src/helix/graphics/shaders/` is compiled by sokol-shdc at build time into a generated Haxe class (`Lit3DLayout` and its siblings) holding the program in both dialects with its bindings (`source()`), its vertex buffers' layout (`buffers()`) and the constants the engine packs vertices and records with. An app's `.hxshader` is the same `ShaderSource`. `IGraphics.createShader` builds either.
- **Pipelines:** `PipelineDesc` is a program, its buffers' layout, primitive, indexing, blend, depth test and write, culling and winding, depth-only, and the clip flip (what block 0 holds, so an adapter whose render targets are stored upside down can draw them the right way up). `helix.graphics.Pipelines` describes every framework pipeline, makes each once per GPU and keeps it; drawing code asks it at each draw.
- **Drawing:** one `draw`: buffers by the pipeline's buffer index, an index buffer for indexed pipelines, a range, instances, textures, samplings and uniform blocks by slot.

Resource kinds are the adapter's concern (a cube, a depth array read through a comparison sampler, a data texture read texel by texel), and so is how each is bound; which shader expects which is in its `ShaderSource`.
