#version 330 compatibility
#extension GL_EXT_gpu_shader4_1 : enable

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
    vec3 viewNormal;
    flat uint blockId;

    #ifdef SHADOWS_ENABLED
        vec3 shadowPos;
    #endif
} vIn;

uniform sampler2D gtexture;
uniform sampler2D lightmap;

#ifdef SHADOWS_ENABLED
    uniform sampler2DShadow shadowtex0;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float dhFarPlane;
uniform int worldTime;
uniform vec3 fogColor;
uniform float far;

#include "/lib/sun.glsl"
#include "/lib/lighting.glsl"

#if defined DISTANT_HORIZONS && defined DH_TEX_NOISE
    #include "/lib/tex_noise.glsl"
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    float viewDist = length(vIn.localPos);
    vec3 _viewNormal = normalize(vIn.viewNormal);

    #if defined DISTANT_HORIZONS && defined DH_LOD_FADE
        float lodGrad = textureQueryLod(gtexture, vIn.texcoord).x;
        float lodMinF = smoothstep(0.7 * far, far, viewDist);
        float lodFinal = max(lodGrad, 4.0 * lodMinF);

        outFinal = textureLod(gtexture, vIn.texcoord, lodFinal);

        if (vIn.blockId == BLOCK_PLANT)
            outFinal.a = textureLod(gtexture, vIn.texcoord, lodGrad).a;

        #if defined DISTANT_HORIZONS && defined DH_TEX_NOISE
            vec3 worldPos = vIn.localPos + cameraPosition;
            applyNoise(outFinal, worldPos, viewDist);
        #endif
    #else
        outFinal = texture(gtexture, vIn.texcoord);
    #endif

    if (outFinal.a < 0.1) {discard; return;}

    outFinal *= vIn.color;

    #if DEBUG_VIEW == DEBUG_VIEW_WORLD_NORMAL
        vec3 worldNormal = mat3(gbufferModelViewInverse) * _viewNormal;
        outFinal.rgb = normalize(worldNormal) * 0.5 + 0.5;
        outFinal.rgb = linear_to_srgb(outFinal.rgb);
    #elif DEBUG_VIEW == DEBUG_VIEW_LIGHT_COORD
        outFinal.rgb = vec3(vIn.lmcoord, 0.0);
        outFinal.rgb = linear_to_srgb(outFinal.rgb);
    #else
        float shadowF = 1.0;
        #ifdef SHADOWS_ENABLED
            if (saturate(vIn.shadowPos) == vIn.shadowPos)
                shadowF = texture(shadowtex0, vIn.shadowPos);
        #endif

        vec3 lightViewDir = GetSkyLightViewDir();

        float NoLm = max(dot(_viewNormal, lightViewDir), 0.0);
        outFinal.rgb *= GetLighting(vIn.lmcoord, shadowF, NoLm);

        float fogF = smoothstep(0.0, 0.5 * dhFarPlane, viewDist);
        outFinal.rgb = mix(outFinal.rgb, fogColor, fogF);
    #endif
}
