#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec4 localPos;
varying vec4 gcolor;
varying vec2 lmcoord;
varying vec3 viewNormal;
flat varying int materialId;

#ifdef SHADOWS_ENABLED
    varying vec3 shadowPos;
#endif

uniform sampler2D depthtex0;
uniform sampler2D lightmap;

#ifdef SHADOWS_ENABLED
    uniform sampler2DShadow shadowtex1;
#endif

uniform mat4 gbufferModelView;
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


void main() {
    float viewDist = length(localPos.xyz);
    if (viewDist < dh_clipDistF * far) {discard; return;}

    float depth = texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).r;
    float depthL = linearizeDepth(depth, near, farPlane);
    float depthDhL = linearizeDepth(gl_FragCoord.z, dhNearPlane, dhFarPlane);
    if (depthL < depthDhL && depth < 1.0) {discard; return;}

    gl_FragColor = gcolor;

    vec3 _viewNormal = normalize(viewNormal);
    if (!gl_FrontFacing) _viewNormal = -_viewNormal;

    #if DEBUG_VIEW == DEBUG_VIEW_WORLD_NORMAL
        vec3 localNormal = mat3(gbufferModelViewInverse) * _viewNormal;
        gl_FragColor = vec4(normalize(localNormal) * 0.5 + 0.5, 1.0);
        gl_FragColor.rgb = linear_to_srgb(gl_FragColor.rgb);
    #else
        bool isWater = (materialId == DH_BLOCK_WATER);

        vec3 sunDir = GetSunVector();
        vec3 lightDir = sunDir * sign(sunDir.y);
        vec3 lightViewDir = mat3(gbufferModelView) * lightDir;
        
        float shadowF = 1.0;
        #ifdef SHADOWS_ENABLED
            if (clamp(shadowPos, vec3(0.0), vec3(1.0)) == shadowPos)
                shadowF = texture(shadowtex1, shadowPos);
        #endif

        vec2 _lm = (lmcoord - (0.5/16.0)) / (15.0/16.0);
        float NdotL = max(dot(_viewNormal, lightViewDir), 0.0);
        float lit = pow(NdotL, 0.5) * shadowF;
        _lm.y *= lit * 0.5 + 0.5;

        vec2 lmFinal = _lm * (15.0/16.0) + (0.5/16.0);
        vec3 blockSkyLight = textureLod(lightmap, lmFinal, 0).rgb;
        gl_FragColor.rgb *= blockSkyLight;

        if (isWater) {
            vec3 _viewDir = normalize(mat3(gbufferModelView) * localPos.xyz);
            vec3 reflectDir = reflect(_viewDir, _viewNormal);
            float specularF = pow(max(dot(reflectDir, lightViewDir), 0.0), 32);
            gl_FragColor.rgb += gcolor.a * specularF * shadowF;
        }

        float fogF = smoothstep(0.0, 0.5 * dhFarPlane, viewDist);
        gl_FragColor.rgb = mix(gl_FragColor.rgb, fogColor, fogF);
        gl_FragColor.a = max(gl_FragColor.a, fogF);
    #endif
}
