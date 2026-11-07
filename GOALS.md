# Goals

What helix is for. When a choice is unclear, these decide it.

1. **An API a developer or an agent can build with from the API alone, and can guess.** One they already know beats one they must
   learn; names follow rules, so the next one can be predicted from the last. If something has to be explained in a README or a guide
   before it can be used, the API hasn't met this goal: the fix is in the API, not the explanation. The test is a fresh agent, given
   the API and nothing else, building a working game on the libraries.
2. **The smallest footprint on the web,** balanced against features, performance and clarity. Size is weighed on every feature, and a
   program carries only what it uses. Native size isn't a concern.
3. **The same codebase built for a native target, ahead of time:** for performance, and for platforms that require native code.
4. **Rapid iteration during development,** without paying for it in a release build.
5. **Existing libraries through the C ABI:** compiled to WebAssembly in the browser, linked as `.a`/`.so` natively.
6. **Nothing to install but Haxe to use them:** Haxe for the web, Haxe and hxcpp (with the C++ compiler it drives) natively. What a
   library needs beyond that (its C, its shader compiler, SDL3) comes with it or is fetched by its build. Python, Node and the
   repository's tools are for developing the libraries, never in a user's path.

## The path still open

The libraries are the pieces anything on top needs, platform first. Two ways to build on them are being weighed, and neither is chosen:

- **An API already known,** written over the libraries (OpenFL's is a candidate, not the pick).
- **A known engine forked onto the libraries,** its API kept whole and its substrate replaced.

Either way, the libraries come first, and pass goal 1's test before anything is built on them.
