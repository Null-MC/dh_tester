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

    outFinal *= vIn.color;

    #if DEBUG_VIEW == DEBUG_VIEW_WORLD_NORMAL
        vec3 worldNormal = mat3(gbufferModelViewInverse) * _viewNormal;
        outFinal.rgb = normalize(worldNormal) * 0.5 + 0.5;
        outFinal.rgb = linear_to_srgb(outFinal.rgb);
    #elif DEBUG_VIEW == DEBUG_VIEW_LIGHT_COORD
        outFinal.rgb = vec3(vIn.lmcoord, 0.0);
        outFinal.rgb = linear_to_srgb(outFinal.rgb);
    #else
        vec3 sunDir = GetSunVector();
        vec3 lightDir = sunDir * sign(sunDir.y);
        vec3 lightViewDir = mat3(gbufferModelView) * lightDir;

        vec2 _lm = clamp((vIn.lmcoord - (0.5/16.0)) / (15.0/16.0), 0.0, 1.0);
        float NdotL = max(dot(_viewNormal, lightViewDir), 0.0);
        float lit = pow(NdotL, 0.5);

        #ifdef SHADOWS_ENABLED
            lit *= texture(shadowtex0, vIn.shadowPos);
        #endif

        _lm.y *= lit * 0.5 + 0.5;

        vec2 lmFinal = _lm * (15.0/16.0) + (0.5/16.0);
        vec3 blockSkyLight = textureLod(lightmap, lmFinal, 0).rgb;
        outFinal.rgb *= blockSkyLight;

        // float viewDist = length(viewPos.xyz);
        float fogF = smoothstep(0.0, 0.5 * dhFarPlane, viewDist);
        outFinal.rgb = mix(outFinal.rgb, fogColor, fogF);
    #endif
}
