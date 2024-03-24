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

#include "/lib/bayer.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    bool isWater = (vIn.blockId == BLOCK_WATER);

    float viewDist = length(vIn.localPos);
    if (isWater && viewDist > dh_clipDistF * far) {discard;}

    vec4 color = texture(gtexture, vIn.texcoord);
    float alpha = color.a;
    
    #if defined DISTANT_HORIZONS && defined DH_LOD_FADE
        float transitionF = smoothstep(0.7 * far, far, viewDist);

        float ditherOut = GetScreenBayerValue();
        alpha *= mix(1.0, ditherOut, transitionF) * pow2(1.0 - transitionF);
    #endif

    if (alpha < 0.1) {discard; return;}

    outFinal = color * vIn.color;
}
