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
    gl_FragColor = gcolor;

    // Distane-clip DH terrain  when it is closer than threshold
    float viewDist = length(localPos.xyz);
    if (viewDist < dh_clipDistF * far) {discard; return;}

    vec3 _viewNormal = normalize(viewNormal);
    
    #if DEBUG_VIEW == DEBUG_VIEW_WORLD_NORMAL
        vec3 localNormal = mat3(gbufferModelViewInverse) * _viewNormal;
        gl_FragColor.rgb = normalize(localNormal) * 0.5 + 0.5;
        gl_FragColor.rgb = linear_to_srgb(gl_FragColor.rgb);
    #elif DEBUG_VIEW == DEBUG_VIEW_LIGHT_COORD
        gl_FragColor.rgb = vec3(lmcoord, 0.0);
        gl_FragColor.rgb = linear_to_srgb(gl_FragColor.rgb);
    // #elif DEBUG_VIEW != DEBUG_VIEW_BLOCK_ID
    #else
        // Fake Texture Noise
        vec3 worldPos = localPos.xyz + cameraPosition;
        applyNoise(gl_FragColor, worldPos, viewDist);

        // Directional Sky Lighting
        vec3 sunDir = GetSunVector();
        vec3 lightDir = sunDir * sign(sunDir.y);
        vec3 lightViewDir = mat3(gbufferModelView) * lightDir;

        vec2 _lm = (lmcoord - (0.5/16.0)) / (15.0/16.0);
        float NdotL = max(dot(_viewNormal, lightViewDir), 0.0);
        float lit = pow(NdotL, 0.5);

        #ifdef SHADOWS_ENABLED
            if (clamp(shadowPos, vec3(0.0), vec3(1.0)) == shadowPos)
                lit *= texture(shadowtex0, shadowPos);
        #endif

        // Keep 50% of sk-light as ambient lighting
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
