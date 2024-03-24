#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 texcoord;
    vec3 localPos;

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
    if (isWater && viewDist > dh_clipDistF * far) {discard; return;}

    vec4 color = texture(gtexture, vIn.texcoord);
    
    #if defined DISTANT_HORIZONS && defined DH_LOD_FADE
        float transitionF = smoothstep(0.5 * far, far, viewDist);

        float ditherOut = GetScreenBayerValue();

        color.a /= alphaTestRef;
        color.a *= mix(1.0, ditherOut, transitionF) * pow2(1.0 - transitionF);
        color.a *= alphaTestRef;
    #endif

    if (color.a < alphaTestRef) {discard; return;}

    outFinal = color * vIn.color;
}
