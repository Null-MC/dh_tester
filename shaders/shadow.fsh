#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec2 texcoord;
    vec3 localPos;
    vec4 color;
    flat uint blockId;
} vIn;

uniform sampler2D gtexture;

uniform float far;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    bool isWater = (vIn.blockId == BLOCK_WATER);

    float viewDist = length(vIn.localPos);
    if (isWater && viewDist > dh_clipDistF * far) {discard;}

    vec4 color = texture(gtexture, vIn.texcoord);
    if (color.a < 0.1) {discard; return;}

    outFinal = color * vIn.color;
}
