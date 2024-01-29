#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec4 gcolor;
varying vec3 localPos;

uniform float far;


void main() {
    float viewDist = length(localPos);
    if (viewDist < dh_clipDistF * far) {discard;}

    gl_FragColor = gcolor;
}
