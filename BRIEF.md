# Experiment 05 — Shared Haxe renderer, browser WebGL, native Sokol

Test whether one Haxe game/framework/renderer can use a small graphics contract with direct browser WebGL2 and native Sokol, without target conditionals in shared code. Build an independently implemented playable Asteroids slice: title, thrust/rotation/fire, splitting rocks, toroidal collision/wrap, score/lives, particles, text, sounds, game over and restart.

Keep adapters below scene traversal and batching. Expose a narrow subset of actual Sokol operations: texture and transient vertex-buffer creation, pipeline creation, buffer update, pass begin, bindings/draw, pass end, destruction. Use an explicit fixed vertex format and one shader program for this first slice; do not claim a complete GPU abstraction. One authored shader produces browser/native variants with sokol-shdc.

Browser: Haxe → JS → WebGL2, no graphics Wasm. Native: the same shared Haxe → hxcpp → thin C/Sokol HAL. Start with the established Linux/OpenGL backend, then list modern-backend and further-target work explicitly. Common Haxe owns game simulation, geometry, batching and sound sample generation; platform adapters own events, presentation and audio delivery.

Measure identical seeded replay/snapshots, actual draw/upload counts, images, real input/resize, startup and repeated CPU/cadence, and same-compressor delivery sizes. Compare to libwgf only as context until behavior, features, workload and measurement boundaries match. Do not claim native compilation itself improves performance.

All changes, tools, results and findings stay in this experiment. No libwgf implementation copied or edited. Keep builds/caches ignored. Use Python, Node, Haxe and CMake for orchestration.

## Authorized extension after the first slice

Extract independent input/audio contracts from the host, add a minimal async asset service for external sound files, and bring main Asteroids gameplay/menu/controller/audio coverage closer to the reference while preserving one shared game and renderer. Measure the service-extraction stage independently from added game features. Add a structured input-driven autopilot and one high-level build/test/serve/measure CLI, and assess a Haxe library boundary. Keep package publication, full reference equivalence, compressed-audio delivery and modern backend execution as explicit future gates. Current external WAV generation is offline Python tooling; shared Haxe validates/decodes packaged assets and owns playback policy.

Subsequent authorized work adds independent fetch/storage mechanisms, shared callback/cache policy, explicit audio clip/stream resources and playback lifetimes, and local-first streaming with ensure required for persistence. Use Sokol native services as the executed baseline and retain SDL3 as an alternative for graphics/window/input/gamepads/audio. Keep large-download scheduling, native remote streaming/codecs, production cache policy and a matched SDL3 comparison as explicitly unexecuted gates.

The later authorized Ogg milestone supersedes the compressed/native-codec deferrals: Vorbis and Opus clips and stored streams now run beneath the audio adapter, using browser Web Audio and native libsndfile/Sokol. Original source WAVs are generated offline and eight Vorbis files are deployed; no decoder goes into browser Wasm. Native remote network audio and sustained service frame-time bounds remain separate gates. Add a read-only reference capability/declaration inventory and gap/probe matrix to guide tests that challenge the interfaces and browser performance; do not claim full 1:1 parity or implement new physics in this milestone.
