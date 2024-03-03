#version 430 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec3 mc_Entity;

flat out uint blockId;

varying vec3 localPos;
varying vec4 gcolor;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 viewNormal;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

#ifdef SHADOWS_ENABLED
    varying vec3 shadowPos;

    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;

    #ifndef IRIS_FEATURE_SSBO
        uniform mat4 gbufferProjection;
        uniform float dhFarPlane;
        uniform float near;
    #endif

    #ifdef IRIS_FEATURE_SSBO
        #include "/lib/shadow_ssbo.glsl"
    #else
        #include "/lib/shadow_matrix.glsl"
    #endif

    #include "/lib/shadow_distortion.glsl"
#endif


void main() {
    gl_Position = ftransform();
    gcolor = gl_Color;
    
    vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
    viewNormal = gl_NormalMatrix * gl_Normal;
    texcoord  = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    localPos = mul3(gbufferModelViewInverse, viewPos);

    blockId = uint(mc_Entity.x + 0.5);

    if (blockId == BLOCK_PLANT) {
        viewNormal = mat3(gbufferModelView) * vec3(0.0, 1.0, 0.0);
    }

    #ifdef SHADOWS_ENABLED
        float viewDist = length(viewPos);
        float shadowBias = SHADOW_NORMAL_BIAS * (viewDist + 8.0);
        vec3 offsetViewPos = viewPos + viewNormal * shadowBias;
        // vec4 localPos = gbufferModelViewInverse * vec4(offsetViewPos, 1.0);

        shadowPos = mul3(shadowModelView, localPos);

        #ifdef SHADOW_FRUSTUM_FIT
            #ifndef IRIS_FEATURE_SSBO
                vec3 boundsMin, boundsMax;
                GetFrustumShadowBounds(boundsMin, boundsMax);
                mat4 shadowProjectionFit = BuildOrthoProjectionMatrix(boundsMin, boundsMax);
            #endif

            shadowPos = mul3(shadowProjectionFit, shadowPos);
        #else
            shadowPos = mul3(shadowProjection, shadowPos);
        #endif

        #if SHADOW_DISTORTION > 0
            #ifndef IRIS_FEATURE_SSBO
                vec3 shadowCameraOffset = vec3(0.0);

                #ifdef SHADOW_FRUSTUM_FIT
                    // shadowCameraOffset = (shadowProjectionFit * vec4(vec3(0.0), 1.0)).xyz;
                    shadowCameraOffset = shadowProjectionFit[3].xyz;
                #endif
            #endif

            distort(shadowPos, shadowCameraOffset.xy);
        #endif

        shadowPos = shadowPos * 0.5 + 0.5;
    #endif

    #if DEBUG_VIEW == DEBUG_VIEW_BLOCK_ID
        gcolor = vec4(vec3(0.0), 1.0);
    #endif
}
