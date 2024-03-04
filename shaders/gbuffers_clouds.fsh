#version 330 compatibility

varying vec4 pos;
varying vec4 gcolor;
varying vec2 lmcoord;

uniform sampler2D lightmap;
uniform sampler2D dhDepthTex;

uniform mat4 gbufferModelView;
uniform float dhNearPlane;
uniform float dhFarPlane;
uniform int worldTime;
uniform vec3 fogColor;

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/sun.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    float depthDh = texelFetch(dhDepthTex, ivec2(gl_FragCoord.xy), 0).r;
    float depthDhL = linearizeDepth(depthDh, dhNearPlane, dhFarPlane);
    
    if (depthDhL < -pos.z) {
        discard;
        return;
    }

    outFinal = gcolor;

    vec3 sunDir = GetSunVector();
    vec3 lightDir = sunDir * sign(sunDir.y);
    vec3 lightViewDir = mat3(gbufferModelView) * lightDir;

    vec2 _lm = clamp((lmcoord - (0.5/16.0)) / (15.0/16.0), 0.0, 1.0);
    vec3 viewNormal = normalize(cross(dFdx(pos.xyz), dFdy(pos.xyz)));
    float NdotL = max(dot(viewNormal, lightViewDir), 0.0);
    _lm.y *= pow(NdotL, 0.5) * 0.5 + 0.5;

    vec2 lmFinal = _lm * (15.0/16.0) + (0.5/16.0);
    vec3 blockSkyLight = textureLod(lightmap, lmFinal, 0).rgb;
    outFinal.rgb *= blockSkyLight;

    float viewDist = length(pos.xyz);
    float fogF = smoothstep(0.0, 0.5 * dhFarPlane, viewDist);
    outFinal.rgb = mix(outFinal.rgb, fogColor, fogF);
}
