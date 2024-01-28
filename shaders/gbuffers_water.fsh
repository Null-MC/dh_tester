#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec4 viewPos;
varying vec4 gcolor;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 viewNormal;

flat varying uint blockId;

#ifdef SHADOWS_ENABLED
    varying vec3 shadowPos;
#endif

uniform sampler2D gtexture;
uniform sampler2D lightmap;

#ifdef SHADOWS_ENABLED
    uniform sampler2DShadow shadowtex1;
#endif

uniform mat4 gbufferModelView;
uniform float dhFarPlane;
uniform int worldTime;
uniform vec3 fogColor;
uniform float viewWidth;
uniform float far;

#include "/lib/sun.glsl"


void main() {
    bool isWater = (blockId == BLOCK_WATER);

    float viewDist = length(viewPos.xyz);
    vec3 viewDir = viewPos.xyz / viewDist;

    if (viewDist > dh_clipDistF * far) {discard; return;}

    gl_FragColor = texture(gtexture, texcoord) * gcolor;

    vec3 sunDir = GetSunVector();
    vec3 lightDir = sunDir * sign(sunDir.y);
    vec3 lightViewDir = mat3(gbufferModelView) * lightDir;
    vec3 _viewNormal = normalize(viewNormal);

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

    vec3 reflectDir = reflect(viewDir, _viewNormal);
    float specularF = pow(max(dot(reflectDir, lightViewDir), 0.0), 32);
    gl_FragColor.rgb += gcolor.a * specularF * shadowF;

    float fogF = smoothstep(0.0, 0.5 * dhFarPlane, viewDist);
    gl_FragColor.rgb = mix(gl_FragColor.rgb, fogColor, fogF);
}
