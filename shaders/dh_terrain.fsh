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
uniform vec3 fogColor;
uniform float viewWidth;
uniform float far;

#include "/lib/sun.glsl"

#ifdef DH_TEX_NOISE
    #include "/lib/tex_noise.glsl"
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    outFinal = vIn.color;

    // Distane-clip DH terrain  when it is closer than threshold
    float viewDist = length(vIn.localPos);
    if (viewDist < dh_clipDistF * far) {discard; return;}

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
        #ifdef DH_TEX_NOISE
            // Fake Texture Noise
            vec3 worldPos = vIn.localPos + cameraPosition;
            applyNoise(outFinal, worldPos, viewDist);
        #endif

        // Directional Sky Lighting
        vec3 sunDir = GetSunVector();
        vec3 lightDir = sunDir * sign(sunDir.y);
        vec3 lightViewDir = mat3(gbufferModelView) * lightDir;

        vec2 _lm = (vIn.lmcoord - (0.5/16.0)) / (15.0/16.0);
        float NdotL = max(dot(_viewNormal, lightViewDir), 0.0);
        float lit = pow(NdotL, 0.5);

        #ifdef SHADOWS_ENABLED
            if (clamp(vIn.shadowPos, vec3(0.0), vec3(1.0)) == vIn.shadowPos)
                lit *= texture(shadowtex0, vIn.shadowPos);
        #endif

        // Keep 50% of sk-light as ambient lighting
        _lm.y *= lit * 0.5 + 0.5;

        // LightMap Lighting
        vec2 lmFinal = _lm * (15.0/16.0) + (0.5/16.0);
        vec3 blockSkyLight = textureLod(lightmap, lmFinal, 0).rgb;
        outFinal.rgb *= blockSkyLight;

        #ifndef SSAO_ENABLED
            // Fog
            float fogF = smoothstep(0.0, 0.5 * dhFarPlane, viewDist);
            outFinal.rgb = mix(outFinal.rgb, fogColor, fogF);
        #endif
    #endif
}
