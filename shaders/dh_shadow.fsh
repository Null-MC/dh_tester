#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec3 localPos;
} vIn;

uniform float far;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    float viewDist = length(vIn.localPos);
    if (viewDist < dh_clipDistF * far) {discard;}

    outFinal = vIn.color;
}
