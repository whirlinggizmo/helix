# Refusal check: build-time gate

Haxe 4.3.7 (patched), this machine, under the build lock. Synthetic helix-ray program from `gen.py` (beside this file): N modules
of game-like code (generic pool, enum with args, entity class with loops/switch/closures/filter/map, draw methods calling
Raylib and Raymath; one module in four pure logic without helix.ray imports), Main constructing and updating all of them inside
raylib's loop. `-dce full`. Median of 5 runs, wall seconds. Hook in `hook/Refuse.hx`, script `time.py`, raw output `times.txt`.

| program | mode | (a) no hook | (b) walk, all non-std/non-helix classes | (c1) walk, cf.get() only for FStatic on Raylib/Rlgl | (c2) @:deprecated + onGenerate upgrade |
|---|---|---|---|---|---|
| 48,318 lines, 200 modules | `-js` | 2.310 | 4.187 (+81%) | 4.097 (+77%) | 2.314 (+0.2%) |
| 48,318 lines | `--no-output` | 2.186 | 4.022 (+84%) | 4.034 (+85%) | 2.218 (+1.5%) |
| 193,218 lines, 800 modules | `-js` | 6.069 | 13.678 (+125%) | 12.942 (+113%) | 6.098 (+0.5%) |
| 193,218 lines | `--no-output` | 5.771 | 13.052 (+126%) | 12.705 (+120%) | 5.851 (+1.4%) |

Where the walk's time goes (48k program, timed inside the hook): encoding the ClassTypes and field lists alone 20 ms; calling
`f.expr()` on every field (encoding the typed AST into macro values) 1,717 ms; walking it 1,923 ms total. The cost is the macro
API's encoding of typed expressions, so any walk through `onAfterTyping` pays it per module it looks at.

Other variants:
- Skipping modules that can't reference helix.ray from typed info: the macro API gives no module dependencies
  (Context has registerModuleDependency, nothing to read them), and a class's field signatures don't show calls in bodies; the
  only typed evidence is the expressions, whose encoding is the cost. Not possible without paying it.
- Stopping early: every refusal must be reported, so the walk can't stop before the end.
- Caching per module across `--wait` builds (keyed by module and file mtime, in a macro static): the statics were reset on every
  server build (walked 601, skipped 0 each time), so nothing was kept; and the first build would pay full price anyway.
- (c2): each refused function also carries `@:deprecated("<its message>")`; the compiler's own deprecation check (run on every
  build already, in OCaml) warns at every naming; an `onGenerate` hook filters those warnings out (`Context.filterMessages`) and
  reports each as an error with the same message and position. Cost: within noise.

## Compilation server (`haxe --wait` / `--connect`), 48k program

| build | (a)/(c2) | (b) walk |
|---|---|---|
| first | 2.30 s | 4.47 s |
| unchanged, again | 0.21 s | 2.08 s |
| unchanged, again | 0.21 s | 1.95 s |
| one module edited | 0.23 s | ~1.9 s |

- onAfterTyping runs on every server build and is handed every module, cached or not, so the walk re-encodes everything each
  time: cached builds go from 0.2 s to 2 s.
- (c2) with a refusal in a cached module: reported on every build (0.16 s each), including after editing a different module.
- Display: `--display File.hx@0@diagnostics`: (b) gives an error diagnostic (severity 1) with the message; (c2) gives a
  deprecation diagnostic (severity 2, kind 5: a warning, editors strike the name through) with the exact message. onGenerate doesn't
  run in display mode, so (c2) shows a warning in the editor, an error when built.

## Gaps of (c2)

- No report where deprecation warnings are off: `-D no-deprecation-warnings`, `-w -WDeprecated` (both checked for at install:
  refused with an error), or `@:haxe.warning("-WDeprecated")` on a user's class or field, and inside a user's own `@:deprecated`
  field or class. There the program compiles and the refused function throws its message when called.
- An inline function naming one is reported at its body and again at each call site.

Gate: (c2) adds 0.2-1.5% (under 3%), so the conversion goes ahead with (c2).

## The three trial games, page build (`-js`, `-dce full`), median of 5, after the conversion

| game | before (macros) | after (deprecation + onGenerate) | app.js |
|---|---|---|---|
| agent-1 | 1.012 s | 0.974 s | 356,204 bytes, identical |
| agent-2 | 0.987 s | 0.988 s | 356,072 bytes, identical |
| agent-3 | 0.996 s | 0.966 s | 350,233 bytes, identical |
