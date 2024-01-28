#version 430 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec4 localPos;
varying vec4 gcolor;
varying vec2 lmcoord;
varying vec3 viewNormal;

#ifdef SHADOWS_ENABLED
    varying vec3 shadowPos;
#endif

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 dhProjection;
uniform vec3 cameraPosition;

#ifdef SHADOWS_ENABLED
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;

    #ifndef IRIS_FEATURE_SSBO
        uniform mat4 gbufferProjection;
        uniform float dhFarPlane;
        uniform float near;
    #endif
#endif

#ifdef SHADOWS_ENABLED
    #ifdef IRIS_FEATURE_SSBO
        #include "/lib/shadow_ssbo.glsl"
    #else
        #include "/lib/shadow_matrix.glsl"
    #endif

    #include "/lib/shadow_distortion.glsl"
#endif


#if DEBUG_VIEW == DEBUG_VIEW_BLOCK_ID
    vec3 HsvToRgb(const in vec3 c) {
        const vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
        return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }
#endif

void main() {
    viewNormal = mat3(gbufferModelView) * gl_Normal;
    gcolor = gl_Color;

    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    // lmcoord  = gl_MultiTexCoord1.xy;
    
    vec4 vPos = gl_Vertex;

    vec3 cameraOffset = fract(cameraPosition);
    vPos.xyz = floor(vPos.xyz + cameraOffset + 0.5) - cameraOffset;

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    localPos = gbufferModelViewInverse * viewPos;
    gl_Position = dhProjection * viewPos;

    #ifdef SHADOWS_ENABLED
        float viewDist = length(viewPos.xyz);
        float shadowBias = SHADOW_NORMAL_BIAS * (viewDist + 8.0);
        vec3 offsetViewPos = viewPos.xyz + viewNormal * shadowBias;
        vec4 localPos = gbufferModelViewInverse * vec4(offsetViewPos, 1.0);

        #ifdef SHADOW_FRUSTUM_FIT
            #ifndef IRIS_FEATURE_SSBO
                vec3 boundsMin, boundsMax;
                GetFrustumShadowBounds(boundsMin, boundsMax);
                mat4 shadowProjectionFit = BuildOrthoProjectionMatrix(boundsMin, boundsMax);
            #endif

            shadowPos = (shadowProjectionFit * (shadowModelView * localPos)).xyz;
        #else
            shadowPos = (shadowProjection * (shadowModelView * localPos)).xyz;
        #endif

        #if SHADOW_DISTORTION > 0
            #ifndef IRIS_FEATURE_SSBO
                vec3 shadowCameraOffset = vec3(0.0);

                #ifdef SHADOW_FRUSTUM_FIT
                    shadowCameraOffset = (shadowProjectionFit * vec4(vec3(0.0), 1.0)).xyz;
                #endif
            #endif

            distort(shadowPos, shadowCameraOffset.xy);
        #endif

        shadowPos = shadowPos * 0.5 + 0.5;
    #endif

    #if DEBUG_VIEW == DEBUG_VIEW_BLOCK_ID
        uint matId = uint(dhMaterialId);

        vec3 hsv = vec3(1.0);
        hsv.x = matId / 15.0;

        vec3 color = HsvToRgb(hsv);
        color = pow(color, vec3(1.0/2.2));

        gcolor = vec4(color, 1.0);
    #endif
}
