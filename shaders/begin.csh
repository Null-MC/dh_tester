#version 430 compatibility

#define PROGRAM_BEGIN

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

const ivec3 workGroups = ivec3(1, 1, 1);

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

#ifdef IRIS_FEATURE_SSBO
    uniform mat4 gbufferModelViewInverse;
    uniform mat4 gbufferProjection;
    uniform mat4 shadowModelView;
    uniform mat4 shadowProjection;
    uniform mat4 shadowProjectionInverse;
    uniform float dhFarPlane;
    uniform float near;
    uniform float far;

    #include "/lib/shadow_ssbo.glsl"
    #include "/lib/shadow_matrix.glsl"
#endif


void main() {
    #ifdef IRIS_FEATURE_SSBO
        vec3 boundsMin, boundsMax;
        GetFrustumShadowBounds(boundsMin, boundsMax);
        shadowProjectionFit = BuildOrthoProjectionMatrix(boundsMin, boundsMax);
        // shadowProjectionFitInverse = inverse(shadowProjectionFit);

        shadowCameraOffset = (shadowProjectionFit * vec4(vec3(0.0), 1.0)).xyz;

        shadowViewCenter = 0.5 * (boundsMin + boundsMax);
    #endif
}
