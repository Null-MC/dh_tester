#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec3 localPos;
    vec3 viewNormal;
    flat int materialId;

    #ifdef SHADOWS_ENABLED
        vec3 shadowPos;
    #endif
} vIn;

uniform sampler2D depthtex0;
uniform sampler2D lightmap;

#ifdef SHADOWS_ENABLED
    uniform sampler2DShadow shadowtex1;
#endif

uniform mat4 gbufferModelView;
uniform vec3 cameraPosition;
uniform float dhNearPlane;
uniform float dhFarPlane;
uniform int worldTime;
uniform vec3 fogColor;
uniform float near;
uniform float far;
uniform float farPlane;

#if DEBUG_VIEW == DEBUG_VIEW_WORLD_NORMAL
    uniform mat4 gbufferModelViewInverse;
#endif

#include "/lib/sun.glsl"

#ifdef DH_TEX_NOISE
    #include "/lib/tex_noise.glsl"
#endif


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    float viewDist = length(vIn.localPos);
    if (viewDist < dh_clipDistF * far) {discard; return;}

    float depth = texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).r;
    float depthL = linearizeDepth(depth, near, farPlane);
    float depthDhL = linearizeDepth(gl_FragCoord.z, dhNearPlane, dhFarPlane);
    if (depthL < depthDhL && depth < 1.0) {discard; return;}

    outFinal = vIn.color;

    vec3 _viewNormal = normalize(vIn.viewNormal);
    if (!gl_FrontFacing) _viewNormal = -_viewNormal;

    #if DEBUG_VIEW == DEBUG_VIEW_WORLD_NORMAL
        vec3 localNormal = mat3(gbufferModelViewInverse) * _viewNormal;
        outFinal.rgb = normalize(localNormal) * 0.5 + 0.5;
        outFinal.rgb = linear_to_srgb(outFinal.rgb);
    #elif DEBUG_VIEW == DEBUG_VIEW_LIGHT_COORD
        outFinal.rgb = vec3(vIn.lmcoord, 0.0);
        outFinal.rgb = linear_to_srgb(outFinal.rgb);
    #else
        bool isWater = (vIn.materialId == DH_BLOCK_WATER);

        #ifdef DH_TEX_NOISE
            // Fake Texture Noise
            vec3 worldPos = vIn.localPos + cameraPosition;
            applyNoise(outFinal, worldPos, viewDist);
        #endif

        vec3 sunDir = GetSunVector();
        vec3 lightDir = sunDir * sign(sunDir.y);
        vec3 lightViewDir = mat3(gbufferModelView) * lightDir;
        
        float shadowF = 1.0;
        #ifdef SHADOWS_ENABLED
            if (saturate(vIn.shadowPos) == vIn.shadowPos)
                shadowF = texture(shadowtex1, vIn.shadowPos);
        #endif

        vec2 _lm = (vIn.lmcoord - (0.5/16.0)) / (15.0/16.0);
        float NdotL = max(dot(_viewNormal, lightViewDir), 0.0);
        float lit = pow(NdotL, 0.5) * shadowF;
        _lm.y *= lit * 0.5 + 0.5;

        vec2 lmFinal = _lm * (15.0/16.0) + (0.5/16.0);
        vec3 blockSkyLight = textureLod(lightmap, lmFinal, 0).rgb;
        outFinal.rgb *= blockSkyLight;

        if (isWater) {
            vec3 _viewDir = normalize(mat3(gbufferModelView) * vIn.localPos);
            vec3 reflectDir = reflect(_viewDir, _viewNormal);
            float specularF = pow(max(dot(reflectDir, lightViewDir), 0.0), 32);
            outFinal.rgb += vIn.color.a * specularF * shadowF;
        }

        float fogF = smoothstep(0.0, 0.5 * dhFarPlane, viewDist);
        outFinal.rgb = mix(outFinal.rgb, fogColor, fogF);
        outFinal.a = max(outFinal.a, fogF);
    #endif
}
