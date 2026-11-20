#version 450
// Red is the row, gl_FragCoord.y's sixteenths; green is whether dFdy of a value growing up the image is positive.
layout(location = 0) in vec4 v_color;
layout(location = 0) out vec4 result;
void main() { result = vec4(fract(gl_FragCoord.y / 16.0), dFdy(v_color.g) > 0.0 ? 1.0 : 0.0, 0.0, 1.0); }
