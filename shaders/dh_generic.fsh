#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec3 localPos;
    vec3 viewNormal;

    #ifdef SHADOWS_ENABLED
        vec3 shadowPos;
    #endif
} vIn;

uniform sampler2D lightmap;

#ifdef SHADOWS_ENABLED
    uniform sampler2DShadow shadowtex0;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float dhFarPlane;
uniform int worldTime;
uniform float viewWidth;
uniform float far;

uniform int isEyeInWater;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;

#include "/lib/fog.glsl"
#include "/lib/sun.glsl"
#include "/lib/lighting.glsl"

#ifdef DH_TEX_NOISE
    #include "/lib/tex_noise.glsl"
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    outFinal = vIn.color;

    // Distane-clip DH terrain  when it is closer than threshold
    // float viewDist = length(vIn.localPos);
    // if (viewDist < 0.5 * far) {discard; return;}

    vec3 _viewNormal = normalize(vIn.viewNormal);
    
    #if DEBUG_VIEW == DEBUG_VIEW_WORLD_NORMAL
        vec3 localNormal = mat3(gbufferModelViewInverse) * _viewNormal;
        outFinal.rgb = normalize(localNormal) * 0.5 + 0.5;
        outFinal.rgb = linear_to_srgb(outFinal.rgb);
    #elif DEBUG_VIEW == DEBUG_VIEW_LIGHT_COORD
        outFinal.rgb = vec3(vIn.lmcoord, 0.0);
        outFinal.rgb = linear_to_srgb(outFinal.rgb);
    // #elif DEBUG_VIEW != DEBUG_VIEW_BLOCK_ID
    #else
        // #ifdef DH_TEX_NOISE
        //     // Fake Texture Noise
        //     vec3 worldPos = vIn.localPos + cameraPosition;
        //     applyNoise(outFinal, worldPos, viewDist);
        // #endif

        float shadowF = 1.0;
        #ifdef SHADOWS_ENABLED
            if (saturate(vIn.shadowPos) == vIn.shadowPos)
                shadowF = texture(shadowtex0, vIn.shadowPos);
        #endif

        // vec3 lightViewDir = GetSkyLightViewDir();

        // float NoLm = max(dot(_viewNormal, lightViewDir), 0.0);
        // outFinal.rgb *= GetDiffuseLighting(vIn.lmcoord, shadowF, NoLm);

        #ifndef SSAO_ENABLED
            float fogF = GetFogFactor(viewDist);
            outFinal.rgb = mix(outFinal.rgb, fogColor, fogF);
        #endif
    #endif
}
