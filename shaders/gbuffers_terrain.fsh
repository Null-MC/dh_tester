#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

flat in uint blockId;

varying vec3 localPos;
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
uniform vec3 cameraPosition;
uniform float dhFarPlane;
uniform int worldTime;
uniform vec3 fogColor;
uniform float far;

#include "/lib/sun.glsl"

#if defined DISTANT_HORIZONS && defined DH_TEX_NOISE
    #include "/lib/tex_noise.glsl"
#endif


void main() {
    float viewDist = length(localPos);
    // if (viewDist > dh_clipDistF * far) {discard; return;}

    vec3 _viewNormal = normalize(viewNormal);

    #if defined DISTANT_HORIZONS && defined DH_LOD_FADE
        mat2 dFdXY = mat2(dFdx(texcoord), dFdy(texcoord));
        float md = max(dot(dFdXY[0], dFdXY[0]), dot(dFdXY[1], dFdXY[1]));
        float lodGrad = 0.5 * log2(md);

        float lodMinF = smoothstep(0.7 * far, far, viewDist);
        float lodFinal = max(lodGrad, 4.0 * lodMinF);

        gl_FragColor = textureLod(gtexture, texcoord, lodFinal);
        // gl_FragColor.rgb = textureLod(gtexture, texcoord, lodFinal).rgb;

        if (blockId == BLOCK_PLANT) {
            gl_FragColor.a = textureLod(gtexture, texcoord, lodGrad).a;
        }

        #if defined DISTANT_HORIZONS && defined DH_TEX_NOISE
            // Fake Texture Noise
            vec3 worldPos = localPos + cameraPosition;
            applyNoise(gl_FragColor, worldPos, viewDist);
        #endif
    #else
        gl_FragColor = texture(gtexture, texcoord);
    #endif

    gl_FragColor *= gcolor;

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
