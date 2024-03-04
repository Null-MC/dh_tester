#version 330 compatibility
#extension GL_EXT_gpu_shader4_1 : enable

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 viewPos;
    vec3 viewNormal;

    flat uint blockId;

    #ifdef SHADOWS_ENABLED
        vec3 shadowPos;
    #endif
} vIn;

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

#if DEBUG_VIEW == DEBUG_VIEW_WORLD_NORMAL
    uniform mat4 gbufferModelViewInverse;
#endif

#include "/lib/sun.glsl"


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    bool isWater = (vIn.blockId == BLOCK_WATER);

    float viewDist = length(vIn.viewPos);
    vec3 viewDir = vIn.viewPos.xyz / viewDist;

    #if defined DISTANT_HORIZONS && defined DH_LOD_FADE
        float farTrans = dh_clipDistF * far;
        if (viewDist > dh_clipDistF * far) {discard; return;}

        float lodGrad = textureQueryLod(gtexture, vIn.texcoord).x;
        float lodMinF = smoothstep(0.5 * farTrans, farTrans, viewDist);
        float lodFinal = max(lodGrad, 4.0 * lodMinF);

        outFinal.rgb = textureLod(gtexture, vIn.texcoord, lodFinal).rgb;
        outFinal.a   = textureLod(gtexture, vIn.texcoord, lodGrad).a;
    #else
        outFinal = texture(gtexture, vIn.texcoord);
    #endif

    outFinal *= vIn.color;

    vec3 _viewNormal = normalize(vIn.viewNormal);

    #if DEBUG_VIEW == DEBUG_VIEW_WORLD_NORMAL
        vec3 worldNormal = mat3(gbufferModelViewInverse) * _viewNormal;
        outFinal.rgb = normalize(worldNormal) * 0.5 + 0.5;
        outFinal.rgb = linear_to_srgb(outFinal.rgb);
    #elif DEBUG_VIEW == DEBUG_VIEW_LIGHT_COORD
        outFinal.rgb = vec3(vIn.lmcoord, 0.0);
        outFinal.rgb = linear_to_srgb(outFinal.rgb);
    #else
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

        vec3 reflectDir = reflect(viewDir, _viewNormal);
        float specularF = pow(max(dot(reflectDir, lightViewDir), 0.0), 32);
        outFinal.rgb += vIn.color.a * specularF * shadowF;

        float fogF = smoothstep(0.0, 0.5 * dhFarPlane, viewDist);
        outFinal.rgb = mix(outFinal.rgb, fogColor, fogF);
    #endif
}
