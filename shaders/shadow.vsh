#version 430 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec2 mc_Entity;

out VertexData {
    vec2 texcoord;
    vec3 localPos;
    vec4 color;
    flat uint blockId;
} vOut;

uniform mat4 shadowModelViewInverse;

#ifdef SHADOW_FRUSTUM_FIT
    #ifndef IRIS_FEATURE_SSBO
        uniform mat4 gbufferModelViewInverse;
        uniform mat4 gbufferProjection;
        uniform mat4 shadowModelView;
        uniform float dhFarPlane;
        uniform float near;
    #endif
#else
    uniform mat4 shadowProjection;
#endif

#ifdef SHADOW_FRUSTUM_FIT
    #ifdef IRIS_FEATURE_SSBO
        #include "/lib/shadow_ssbo.glsl"
    #else
        #include "/lib/shadow_matrix.glsl"
    #endif
#endif

#include "/lib/shadow_distortion.glsl"


void main() {
    vOut.texcoord  = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vOut.blockId = uint(mc_Entity.x);
    vOut.color = gl_Color;

    vec3 shadowViewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
    vOut.localPos = mul3(shadowModelViewInverse, shadowViewPos);

    #ifdef SHADOW_FRUSTUM_FIT
        #ifndef IRIS_FEATURE_SSBO
            vec3 boundsMin, boundsMax;
            GetFrustumShadowBounds(boundsMin, boundsMax);
            mat4 shadowProjectionFit = BuildOrthoProjectionMatrix(boundsMin, boundsMax);
        #endif

        gl_Position.xyz = mul3(shadowProjectionFit, shadowViewPos);
    #else
        gl_Position.xyz = mul3(shadowProjection, shadowViewPos);
    #endif

    gl_Position.w = 1.0;
    
    #if SHADOW_DISTORTION > 0
        #ifndef IRIS_FEATURE_SSBO
            vec3 shadowCameraOffset = vec3(0.0);

            #ifdef SHADOW_FRUSTUM_FIT
                shadowCameraOffset = shadowProjectionFit[3].xyz;
            #endif
        #endif

        distort(gl_Position.xyz, shadowCameraOffset.xy);
    #endif
}
