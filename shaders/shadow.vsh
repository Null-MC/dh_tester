#version 430 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec2 texcoord;
varying vec4 gcolor;

#if defined SHADOW_FRUSTUM_FIT && !defined IRIS_FEATURE_SSBO
    uniform mat4 gbufferModelViewInverse;
    uniform mat4 gbufferProjection;
    uniform mat4 shadowModelView;
    uniform float dhFarPlane;
    uniform float near;
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
    #ifdef SHADOW_FRUSTUM_FIT
        #ifndef IRIS_FEATURE_SSBO
            vec3 boundsMin, boundsMax;
            GetFrustumShadowBounds(boundsMin, boundsMax);
            mat4 shadowProjectionFit = BuildOrthoProjectionMatrix(boundsMin, boundsMax);
        #endif

        gl_Position = gl_ModelViewMatrix * gl_Vertex;
        gl_Position = shadowProjectionFit * gl_Position;
    #else
        gl_Position = ftransform();
    #endif
    
    #if SHADOW_DISTORTION > 0
        #ifndef IRIS_FEATURE_SSBO
            vec3 shadowCameraOffset = vec3(0.0);

            #ifdef SHADOW_FRUSTUM_FIT
                shadowCameraOffset = (shadowProjectionFit * vec4(vec3(0.0), 1.0)).xyz;
            #endif
        #endif

        distort(gl_Position.xyz, shadowCameraOffset.xy);
    #endif

    texcoord  = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    gcolor = gl_Color;
}
