// A block both stages declare alike, of floats, integers, a bool, a struct array, a float array and a mat3: one block at one slot in
// each stage, laid out by std140 on every adapter.
struct Light { vec3 color; int on; };
layout(binding = 1) uniform Shared { vec4 scale; Light lights[3]; int pick; bool bright; uint mask; float weights[3]; mat3 turn; };
