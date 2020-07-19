#version 450

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

void main( void ) {
    vec2 p_pixel = (2 * gl_FragCoord.xy - resolution.xy) / min(resolution.x, resolution.y);
    vec2 p_mouse = (2 * mouse.xy - resolution.xy) / min(resolution.x, resolution.y);
    gl_FragColor = vec4(abs(p_pixel.x), abs(p_mouse.x), sin(time), 1.0);
}