@vs sprite2d_vs
// The adapter's: clip space's x and y scales (y is -1 in a pass drawn flipped, into a render target on GL).
layout(binding=0) uniform sprite2d_params {
    vec4 clip;
};
layout(location=0) in vec2 position;
layout(location=1) in vec2 uv;
layout(location=2) in vec4 color;
out vec2 texcoord;
out vec4 tint;
void main(){gl_Position=vec4(position*clip.xy,0.0,1.0);texcoord=uv;tint=color;}
@end
@fs sprite2d_fs
layout(binding=0) uniform texture2D atlas;
layout(binding=0) uniform sampler atlasSampler;
in vec2 texcoord;
in vec4 tint;
out vec4 fragColor;
void main(){
    vec4 texel=texture(sampler2D(atlas,atlasSampler),texcoord);
    if(tint.a>1.5){
        // Distance-field text (Batch2D.quad's distanceField): alpha 0.5 is the outline; the edge is smoothed over about a pixel at any scale.
        // Four samples across the pixel's footprint, averaged, keep thin strokes from dropping out when the field is drawn smaller than it was baked.
        float w=max(fwidth(texel.a)*0.75,1e-4);
        vec2 dx=dFdx(texcoord)*0.25,dy=dFdy(texcoord)*0.25;
        float coverage=smoothstep(0.5-w,0.5+w,texture(sampler2D(atlas,atlasSampler),texcoord+dx+dy).a)
            +smoothstep(0.5-w,0.5+w,texture(sampler2D(atlas,atlasSampler),texcoord+dx-dy).a)
            +smoothstep(0.5-w,0.5+w,texture(sampler2D(atlas,atlasSampler),texcoord-dx+dy).a)
            +smoothstep(0.5-w,0.5+w,texture(sampler2D(atlas,atlasSampler),texcoord-dx-dy).a);
        fragColor=vec4(tint.rgb,coverage*0.25*(tint.a-2.0));
    }else{
        fragColor=texel*tint;
    }
}
@end
@program sprite2d sprite2d_vs sprite2d_fs
