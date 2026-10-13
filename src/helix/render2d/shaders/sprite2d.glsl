@vs vs
layout(location=0) in vec2 position;
layout(location=1) in vec2 uv;
layout(location=2) in vec4 color;
out vec2 texcoord;
out vec4 tint;
void main(){gl_Position=vec4(position,0.0,1.0);texcoord=uv;tint=color;}
@end
@fs fs
layout(binding=0) uniform texture2D atlas;
layout(binding=0) uniform sampler atlasSampler;
in vec2 texcoord;
in vec4 tint;
out vec4 fragColor;
void main(){fragColor=texture(sampler2D(atlas,atlasSampler),texcoord)*tint;}
@end
@program sprite vs fs
