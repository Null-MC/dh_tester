#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec2 texcoord;
varying vec4 gcolor;

uniform sampler2D gtexture;


void main() {
    gl_FragColor = texture(gtexture, texcoord) * gcolor;
}
