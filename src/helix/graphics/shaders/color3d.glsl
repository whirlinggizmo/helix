@vs color3d_vs
layout(binding=0) uniform color3d_params {
    mat4 viewProjection;
};
layout(location=0) in vec3 position;
layout(location=1) in vec4 color;
out vec4 tint;
void main(){gl_Position=viewProjection*vec4(position,1.0);tint=color;}
@end
@fs color3d_fs
in vec4 tint;
out vec4 fragColor;
void main(){fragColor=tint;}
@end
@program color3d color3d_vs color3d_fs
