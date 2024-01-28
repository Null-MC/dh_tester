#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec4 gcolor;


void main() {
    gl_FragColor = gcolor;
}
