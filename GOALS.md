# Goals

What HeliX is for, and why it's built the way it is. When a choice is unclear, these decide it.

## What HeliX is for

1. **The smallest web delivery,** balanced against features, performance, and clarity and ease of use. Size is weighed on every feature;
   none of the three is traded away for it.
2. **The same codebase built for a native target, ahead of time:** for performance, and for platforms that require native code.
   Consoles, for example, prohibit Electron, Tauri and the like.
3. **Rapid iteration during development,** without paying for it in a release build: the development loop's machinery is absent from
   what ships.
4. **Existing libraries through the C ABI:** compiled to WebAssembly in the browser, linked as `.a`/`.so` natively. Compute-heavy work is
   offloaded to them, and libraries too costly to port are used as they are.
5. **A clear, consistent API.** The easier and cleaner it is, the easier it is for a person and for an agent to build an application
   on it.

## Why Haxe

Each language was tried against those goals:

- **Lua:** great flexibility and rapid iteration, but too slow on the web (a WebAssembly VM, no JIT).
- **C:** great performance and interop, and excellent tooling, but poor for rapid iteration. Swapping a DLL is the fallback, and it's
  awkward: changed scoped variables, statics and the like don't survive the swap.
- **Nim:** near C's performance, but the same DLL-swapping problems for iteration (its own hot reload is reportedly unmaintained).
  Easier to use, but its JavaScript output was only fair, it has no incremental compiler (which slows iteration considerably), and its
  tooling (IDE, LSP) was frustrating.
- **Haxe:** fairly easy to understand. Its hxcpp native target is reasonably fast. Its WebAssembly is too large, carrying the
  infrastructure Haxe brings (garbage collector, reflection, objects), but its JavaScript target is excellent, and with the compilation
  server it has arguably the fastest compile and export of any of them. Native iteration leans on cppia, whose size, memory and
  performance costs made the browser the primary development environment, where debugging JavaScript with source maps gives top-notch
  tools. Native tooling was frustrating at first (pull requests were submitted upstream).

So HeliX develops in the browser with hot reload, ships JavaScript to the web, compiles natively through hxcpp, and reaches C libraries
for what Haxe shouldn't do itself.

## Why a framework at all

Why build one, if you can tell an agent "make my game, more like GTA, CS or Diablo"?

- **Partly the challenge:** some not-invented-here, some "can I do it?".
- **Agents still get things wrong.** The majority of HeliX was built with AI, and it's better than ever, but it still needs a person to
  point and say "no, not like that". A clean, consistent API with its checks built in makes that easier for both of them.
- **Some places prohibit AI.** A game jam may ban generative AI, but there's nothing wrong with using tools that were built with its
  help. A framework is such a tool: a person writes the game on it by hand.

## Why not an existing Haxe framework

- **OpenFL with Lime** carries Flash's API, which people and agents know well, and Lime builds natively through hxcpp. Measured
  (2026-10-22, OpenFL 9.5.2, Lime 8.3.2, Haxe 4.3.7, an HTML5 release build with `-dce full`, gzip -9): an empty program is 232 KB of
  JavaScript, 181 KB after Terser, and a rectangle and a line of text add almost nothing to it (its runtime starts whole). HeliX's same
  three programs are 25, 71 and 74 KB (19.5, 62 and 65 KB after Terser), and a lit 3D scene 91 KB. Its text used the browser's fonts,
  where HeliX's carries its own. It has no hot reload (its model is listeners on display objects, which a reload strands), no path to
  C libraries as WebAssembly, and no 3D beyond Stage3D, Flash's low-level GPU API with AGAL shaders. Flash's model is worth borrowing
  (a stage that draws itself, display objects, drawing on a node); its runtime isn't.
- **Heaps** is Haxe, 2D and 3D, and has shipped console games. It builds natively through HashLink, not hxcpp, has no hot reload of its
  own, and has its own shader language. Not measured here.
