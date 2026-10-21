layout(location=13) in vec4 joints;
layout(location=14) in vec4 weights;
// The stage's joint texture (its palette); the model's first joint is its record's i_normal2.w.
layout(binding=5) uniform texture2D helix_joint_texture;
layout(binding=5) uniform sampler helix_joint_sampler;
@image_sample_type helix_joint_texture unfilterable_float
@sampler_type helix_joint_sampler nonfiltering
vec4 joint_texel(ivec2 at) { return texelFetch(sampler2D(helix_joint_texture, helix_joint_sampler), at, 0); }
@include_block skinning
