#version 430 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec4 mc_Entity;

varying vec4 viewPos;
varying vec4 gcolor;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 viewNormal;

flat varying uint blockId;

#ifdef SHADOWS_ENABLED
    varying vec3 shadowPos;

    uniform mat4 gbufferModelViewInverse;
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
    
    viewPos = gl_ModelViewMatrix * gl_Vertex;
    viewNormal = gl_NormalMatrix * gl_Normal;
    texcoord  = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    blockId = int(mc_Entity.x + 0.5);
    
    #ifdef SHADOWS_ENABLED
        //float viewDist = length(viewPos.xyz);
        vec3 offsetViewPos = viewPos.xyz + viewNormal * SHADOW_NORMAL_BIAS;
        vec3 localPos = mul3(gbufferModelViewInverse, offsetViewPos);

        shadowPos = mul3(shadowModelView, localPos);

        shadowPos.z += SHADOW_OFFSET_BIAS;

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
                    shadowCameraOffset = (shadowProjectionFit * vec4(vec3(0.0), 1.0)).xyz;
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
