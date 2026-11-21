# Library trial: the Particles extra (2026-11-16)

What its entrants were given is in `docs/trials/2026-11-16-particles/` at commit `7b0b153`, the paths below under it.

Whether agents can make a camp at night's effects with the Particles extra, learning it from its page alone: a campfire's flames, embers
and smoke leaning in a breeze, dust lit by the fire, wandering fireflies, a spell burst of streaks, and a 2D coin count that sparkles,
each described by how it looks. Three fresh Sonnet agents, each a `claude -p` in a directory of its own outside any repository, in the
blind trials' sandbox (`run_entrant.py --trial`), were given the brief (`module/brief.md`), the task (`task.md`), the Particles and
Lighting extras' pages and the types page (`module/docs/api`), and Wardens' camp props and font, building natively
against helix at `cff00e4`.

| entrant | cost | time | turns | compile errors | warnings | every effect in its shot |
|---|---|---|---|---|---|---|
| 1 | $0.32 | 2.8 min | 14 | 0 | 0 | yes |
| 2 | $0.50 | 3.6 min | 19 | 0 (1 in its own debug line) | 0 | yes |
| 3 | $0.63 | 4.9 min | 28 | 0 | 0 | yes |

Each shot shows the fire, its smoke leaning, the firelight on the props with the camp's edges dark, lit dust, fireflies, the spell's
streaks and the count. The coin sparkles are faint in all three: the last coin before the shot came 1.25 seconds before it, the task's
timing rather than the extra.

## What it found

| finding | to do |
|---|---|
| Fireflies at the camp's edges: no shape is born on an outline, so each built 4 to 8 box emitters around the rim (3 of 3) | `spawnShell`, born on the shape's surface; `Sphere` and `Circle` become `Ellipsoid` and `Ellipse`, sized by `spawnHalfSize` as `Box` and `Rectangle` are, so a flattened ellipsoid's shell is a ring on the ground; `spawnRadius` goes |
| A firefly's pulse faked with colour or size keys, every particle in step (3 of 3) | `pulseRate` and `pulseDepth`, each particle on a phase of its own |
| Whether `velocity`'s length is the speed when `spread` is 180 (2 of 3) | `direction` and `speed` apart |
| Whether `colorKeys` replace `startColor` and `endColor` between them (2 of 3) | the keys include the ends: `startColor`, `endColor`, `startSize`, `endSize` go |
| How a prewarm treats `rate = 0`; the draw order of additive and alpha emitters (1 each) | open |
