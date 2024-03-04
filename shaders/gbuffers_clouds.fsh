#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec3 viewPos;
    vec3 viewNormal;
} vIn;

uniform sampler2D lightmap;
uniform sampler2D dhDepthTex;

uniform mat4 gbufferModelView;
uniform float dhNearPlane;
uniform float dhFarPlane;
uniform int worldTime;

uniform int isEyeInWater;
uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;

#include "/lib/fog.glsl"
#include "/lib/sun.glsl"
#include "/lib/lighting.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    float dhDepth = texelFetch(dhDepthTex, ivec2(gl_FragCoord.xy), 0).r;
    float dhDepthL = linearizeDepth(dhDepth, dhNearPlane, dhFarPlane);
    
    if (dhDepth > 0.0 && dhDepthL < -vIn.viewPos.z) {
        discard;
        return;
    }

    float viewDist = length(vIn.viewPos);
    vec3 _viewNormal = normalize(vIn.viewNormal);
    
    outFinal = vIn.color;

    float shadowF = 1.0;
    // #ifdef SHADOWS_ENABLED
    //     if (saturate(vIn.shadowPos) == vIn.shadowPos)
    //         shadowF = texture(shadowtex0, vIn.shadowPos);
    // #endif

    vec3 lightViewDir = GetSkyLightViewDir();

    float NoLm = max(dot(_viewNormal, lightViewDir), 0.0);
    outFinal.rgb *= GetDiffuseLighting(vIn.lmcoord, shadowF, NoLm);

    float fogF = GetFogFactor(viewDist);
    outFinal.rgb = mix(outFinal.rgb, fogColor, fogF);
}
