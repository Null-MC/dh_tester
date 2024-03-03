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

#if DEBUG_VIEW == DEBUG_VIEW_WORLD_NORMAL
    uniform mat4 gbufferModelViewInverse;
#endif

#include "/lib/sun.glsl"


void main() {
    bool isWater = (blockId == BLOCK_WATER);

    float viewDist = length(viewPos.xyz);
    vec3 viewDir = viewPos.xyz / viewDist;

    #ifdef DISTANT_HORIZONS
        float farTrans = dh_clipDistF * far;
        if (viewDist > dh_clipDistF * far) {discard; return;}

        mat2 dFdXY = mat2(dFdx(texcoord), dFdy(texcoord));
        float md = max(dot(dFdXY[0], dFdXY[0]), dot(dFdXY[1], dFdXY[1]));
        float lodGrad = 0.5 * log2(md);

        float lodMinF = smoothstep(0.5 * farTrans, farTrans, viewDist);
        float lodFinal = max(lodGrad, 4.0 * lodMinF);

        gl_FragColor.rgb = textureLod(gtexture, texcoord, lodFinal).rgb;
        gl_FragColor.a   = textureLod(gtexture, texcoord, lodGrad).a;
    #else
        gl_FragColor = texture(gtexture, texcoord);
    #endif

    gl_FragColor *= gcolor;

    vec3 _viewNormal = normalize(viewNormal);

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
    #endif
}
