# Lanternholm (3D, a floating island under a turning sky)

A small 3D toy: a floating island to look at from every side, its sky turning from dawn through noon and dusk into a moonlit night,
trees to plant and little creatures to poke. Everything is made in code: its shapes, its textures and its sound. Its one asset file
is the title's font, `assets/serif.ttf`. It names no engine and no function. `reference/` holds screenshots of it at 1280 x 720: at
dawn, noon, dusk and night, and close up at noon.

Distances are in meters, the island about 4.3 across. Colors are RGB, 0 to 1, or hex.

## Window and camera
- **Window:** 1280 x 720, resizable, the background behind the sky near black (#05040a). On a resize the view keeps the island framed,
  and in a window taller than wide the view widens so the island stays whole.
- **Camera:** starts at (2.45, 1.4, 10.7), looking at (0, 0.2, 0), with a vertical field of view of 36 degrees.
- **Orbiting:** dragging turns the camera around (0, 0.2, 0), easing to a stop when let go. The wheel zooms, from 5 to 20 meters away.
  It turns from 0.55 to 2.05 radians from straight up, so it can look up at the island from a little below. It never pans. The left
  button orbits when the press starts off the island or the Time tool is chosen. The right button orbits anywhere, and its context
  menu never opens.
- **Touch:** on a touch screen, one finger dragging orbits as the left button does, and a tap uses the chosen tool as a click does. Two
  fingers pinching zoom, within the same 5 to 20 meters, and dragging together orbit. A second finger landing cancels the first's tap.
- **The island floats:** it bobs up and down by 4.5 centimeters and tilts by about 0.7 degrees, slowly, never still.

## The island
- **Outline:** roughly round, 2.15 across from the middle to the rim, its edge irregular. The same island every run.
- **Top:** a grassy surface about 0.3 above the rim, gently uneven, rising to one hill at (-0.7, -0.6), 1 high, with a rocky crest.
  It falls away toward the rim over its outer fifth. The grass varies from dark to light green with straw-colored patches, bare
  earth where a path runs, and gray rock where the ground is steep or high.
- **Underside:** a rocky cone hanging below, about 1.9 deep with spikes to 2.3, dark gray stone with strata, cracks and moss. Teal
  veins run through it, glowing faintly by day and brightly at night.
- **Crystals:** about 110 teal and cyan crystals, a quarter of them violet, set into the underside pointing down, 3.5 to 10
  centimeters long, some nearly twice that. They glow, faintly by day and strongly at night, pulsing slowly.
- **Pond:** an oval pond centered at (0.6, 0.3), 1.3 by 0.9 across, its shore irregular, its water surface at 0.2. Its water is clear
  green at the shore and deep blue-green in the middle, more reflective at a glancing view, with a bright glint of the sun.
- **Stream and waterfall:** a stream runs from the pond to the rim, about 1.3 long, widening and quickening as it goes, cut into the
  ground. It pours over the rim as a waterfall, falling 2.7 below the island, spreading as it falls and fading out, with white mist
  rising where it leaves the rim.
- **Path:** a bare-earth path from the hut to the dock.
- **Hut:** a small log cabin at (-1.05, 0.72), turned 0.7 radians, about 0.33 wide and 0.24 deep: logs with pale chinking on a stone
  footing, a shingled roof with a little moss, a blue door with a brass knob, a front window and a side window with shutters, a flower
  box under the front window, a stone chimney, and a woodpile at the back.
- **Chimney smoke:** soft gray puffs rise from the chimney, about three a second, each drifting up and sideways with the breeze,
  growing and fading out over 3 to 5 seconds.
- **Dock and boat:** a short plank dock from the path's end out into the pond, on posts, a coil of rope on it, and a small green and
  red rowboat moored alongside on a sagging rope, bobbing and rocking gently.
- **Boulders:** about 40 small gray-brown rocks, faceted, gathered on steep and high ground.

## Sky and time of day
- **Time of day:** 0 to 1: 0 midnight, 0.25 sunrise, 0.5 noon, 0.75 sunset. It starts at 0.4. It doesn't pass by itself: the Time
  tool's slider sets it, and the sky eases toward the slider's value over about a second, the short way round the clock.
- **Sun and moon:** the sun rises in the east, climbs high but not straight overhead, and sets in the west. The moon is roughly
  opposite it, up at night.
- **Sky:**
  - **Day:** blue, pale near the horizon and deep overhead.
  - **Dawn and dusk:** an orange to violet band along the horizon, strongest toward the sun.
  - **Night:** near black, a faint haze drifting, and twinkling stars.
  - The sun is a bright disc with a glow, orange when low and white when high. The moon is a pale disc with darker patches and a blue
    halo.
- **Light:** the sun lights the island by day, orange when low, warm white at noon, dimming to nothing as it sets. The moon lights it
  at night, cool blue and dim. Whichever is up casts shadows: the trees, the hut, the dock, the boulders and the island's own hill
  shadow the ground. A soft fill from the sky lights everything, blue-white by day and deep blue at night, warm brown from below.
- **Glow:** bright things glow at night, their light bleeding softly into the dark around them: the crystals, the veins, the hut's
  windows, the mushrooms and the fireflies.

## Life
- **Grass:** thousands of tapered blades over the grassy ground, light and dark greens, darker at their base, swaying in a breeze.
- **Flowers:** a few hundred small five-petal flowers in pink, yellow, red, lilac and cream, swaying gently. They close at night.
- **Mushrooms:** clumps of 4 to 7 small mushrooms, dusty teal caps on pale stems, in short grass. Their caps glow teal at night.
- **Trees:** 11 trees at the start, kept apart and away from the hut and dock: conifers on the hill, willows near the pond, the rest
  birch and puffwood. Their leaves sway in the breeze, more toward the top. Each kind:
  - **Puffwood:** a branching trunk with round clumps of green leaves, red fruit on many branch tips that glows orange at night.
  - **Needlewood:** a conifer of drooping dark green tiers.
  - **Birch:** a slim pale trunk with small yellow-green clumps on its upper half.
  - **Willow:** a short trunk forking into arching limbs with long hanging strands.
  - **Blossom:** a low wide crown of pink blossom with some green leaves.
  - **Palm:** a curved ringed trunk with drooping fronds.
- **Dust:** about 180 motes floating slowly around and below the island, catching the sun or moon's color, brighter by day.
- **Fireflies:** a few dozen yellow lights blinking just above the ground, only at night.
- **Nubbins:** 6 round mossy pebble creatures, gray with a moss cap, a sprout on top and two black eyes, 7.5 centimeters across.
  Each waits a moment, then hops toward a spot nearby, squashing as it lands and stretching as it leaps, again and again. At night
  they sleep, still, their eyes nearly shut.
- **The hut at night:** its windows glow warm orange, and a small warm light by the door lights the ground in front of it.

## Tools
- **Controls:** a title "Lanternholm" at the top left, in the serif face of `assets/serif.ttf`. At the bottom middle, a toolbar of
  three tools, Time, Plant and Poke, each with an icon and its name, the chosen one highlighted. Above it a panel for the chosen
  tool, and above that a hint. Panels are dark and translucent, the highlight amber (#f1b768). Keys 1, 2 and 3 choose the tools. H
  hides and shows all the controls, fading.
- **A tap** is a press and release moving no more than 6 pixels. A drag orbits, as above.
- **Time:** a slider for the time of day, and beside it what it is: Night, Dawn, Sunrise, Morning, Noon, Afternoon, Sunset or Dusk.
  Hint: "Use the slider to move the sun".
- **Plant:** a stepper, ‹ Puffwood ›, cycling through the six kinds of tree. Tapping the ground plants one there. It grows from nothing
  over about 4 seconds, overshooting a little before it settles. A tap on water, the rim, a steep slope, the path, by the dock, next to
  another tree or on a nubbin plants nothing, with a dull thud. At most 22 trees stand at once: past that the oldest shrinks away.
  Hint: "Tap the ground to plant a tree".
- **Poke:** a Strength slider, Gentle, Firm or Hard. Tapping a nubbin makes it chirp and hop, as high as the strength says. Hint: "Tap a
  nubbin to make it hop".
- **Hints:** each fades out for good once its tool has been used.
- **Sound button:** a speaker beside the panel, muting and unmuting all sound.
- **Cursor:** a pointing hand over the island with Plant or Poke chosen.

## Sound
- All made in code. It starts with the first press or key.
- **Ambience:** a soft airy hiss, as of wind and water, over a low rumble, looping.
- **Chirp:** a nubbin poked, two quick rising notes.
- **Plant:** a tree planted, two soft rising tones.
- **Thud:** a planting refused, a short low falling tone.

## Running it
- **Options** for looking at it: `--hour=0.5` starts at a time of day; `--cam=x,y,z` and `--look=x,y,z` place and aim the camera;
  `--frames=N` closes it after N frames, saving `shot.png` on the last; `--shots=a,b` saves `shot-<frame>.png` on those frames.
- **Frame rate:** 60 frames a second, smoothly.
