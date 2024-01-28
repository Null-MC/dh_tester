#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec4 localPos;
varying vec4 gcolor;
varying vec2 lmcoord;
varying vec3 viewNormal;

#ifdef SHADOWS_ENABLED
    varying vec3 shadowPos;
#endif

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

#include "/lib/tex_noise.glsl"
#include "/lib/sun.glsl"


void main() {
    float viewDist = length(localPos.xyz);
    if (viewDist < dh_clipDistF * far) {discard; return;}

    vec3 _viewNormal = normalize(viewNormal);
    
    #if DEBUG_VIEW == DEBUG_VIEW_WORLD_NORMAL
        vec3 localNormal = mat3(gbufferModelViewInverse) * _viewNormal;
        gl_FragColor = vec4(normalize(localNormal) * 0.5 + 0.5, 1.0);
        gl_FragColor.rgb = linear_to_srgb(gl_FragColor.rgb);
    #else
        gl_FragColor = gcolor;

        // Fake Texture Noise
        // float viewDist = length(localPos.xyz);
        vec3 worldPos = localPos.xyz + cameraPosition;
        applyNoise(gl_FragColor, worldPos, viewDist);

        // Directional Sky Lighting
        vec3 sunDir = GetSunVector();
        vec3 lightDir = sunDir * sign(sunDir.y);
        vec3 lightViewDir = mat3(gbufferModelView) * lightDir;

        vec2 _lm = (lmcoord - (0.5/16.0)) / (15.0/16.0);
        // vec3 viewNormal = mat3(gbufferModelView) * normal;
        float NdotL = max(dot(_viewNormal, lightViewDir), 0.0);
        float lit = pow(NdotL, 0.5);

        #ifdef SHADOWS_ENABLED
            if (clamp(shadowPos, vec3(0.0), vec3(1.0)) == shadowPos)
                lit *= texture(shadowtex0, shadowPos);
        #endif

        _lm.y *= lit * 0.5 + 0.5;

        // LightMap Lighting
        vec2 lmFinal = _lm * (15.0/16.0) + (0.5/16.0);
        vec3 blockSkyLight = textureLod(lightmap, lmFinal, 0).rgb;
        gl_FragColor.rgb *= blockSkyLight;

        // Fog
        float fogF = smoothstep(0.0, 0.5 * dhFarPlane, viewDist);
        gl_FragColor.rgb = mix(gl_FragColor.rgb, fogColor, fogF);
    #endif
}
