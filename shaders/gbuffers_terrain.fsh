#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec4 viewPos;
varying vec4 gcolor;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 viewNormal;

#ifdef SHADOWS_ENABLED
    varying vec3 shadowPos;
#endif

uniform sampler2D gtexture;
uniform sampler2D lightmap;

#ifdef SHADOWS_ENABLED
    uniform sampler2DShadow shadowtex0;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float dhFarPlane;
uniform int worldTime;
uniform vec3 fogColor;
uniform float far;

#include "/lib/sun.glsl"


void main() {
    float viewDist = length(viewPos.xyz);
    // if (viewDist > dh_clipDistF * far) {discard; return;}

    vec3 _viewNormal = normalize(viewNormal);

    gl_FragColor = texture(gtexture, texcoord) * gcolor;

    #if DEBUG_VIEW == DEBUG_VIEW_WORLD_NORMAL
        vec3 worldNormal = mat3(gbufferModelViewInverse) * _viewNormal;
        gl_FragColor.rgb = normalize(worldNormal) * 0.5 + 0.5;
        gl_FragColor.rgb = linear_to_srgb(gl_FragColor.rgb);
    #elif DEBUG_VIEW == DEBUG_VIEW_LIGHT_COORD
        gl_FragColor.rgb = vec3(lmcoord, 0.0);
        gl_FragColor.rgb = linear_to_srgb(gl_FragColor.rgb);
    #else
        vec3 sunDir = GetSunVector();
        vec3 lightDir = sunDir * sign(sunDir.y);
        vec3 lightViewDir = mat3(gbufferModelView) * lightDir;

        vec2 _lm = clamp((lmcoord - (0.5/16.0)) / (15.0/16.0), 0.0, 1.0);
        float NdotL = max(dot(_viewNormal, lightViewDir), 0.0);
        float lit = pow(NdotL, 0.5);

        #ifdef SHADOWS_ENABLED
            lit *= texture(shadowtex0, shadowPos);
        #endif

        _lm.y *= lit * 0.5 + 0.5;

        vec2 lmFinal = _lm * (15.0/16.0) + (0.5/16.0);
        vec3 blockSkyLight = textureLod(lightmap, lmFinal, 0).rgb;
        gl_FragColor.rgb *= blockSkyLight;

        // float viewDist = length(viewPos.xyz);
        float fogF = smoothstep(0.0, 0.5 * dhFarPlane, viewDist);
        gl_FragColor.rgb = mix(gl_FragColor.rgb, fogColor, fogF);
    #endif
}
