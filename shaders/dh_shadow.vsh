#version 430 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec4 gcolor;
varying vec3 localPos;

uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;

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

// #include "/lib/hsv.glsl"


void main() {
    gcolor = gl_Color;

    vec4 shadowViewPos = gl_ModelViewMatrix * gl_Vertex;
    localPos = (shadowModelViewInverse * shadowViewPos).xyz;

    #ifdef SHADOW_FRUSTUM_FIT
        #ifndef IRIS_FEATURE_SSBO
            vec3 boundsMin, boundsMax;
            GetFrustumShadowBounds(boundsMin, boundsMax);
            mat4 shadowProjectionFit = BuildOrthoProjectionMatrix(boundsMin, boundsMax);
        #endif

        gl_Position = shadowProjectionFit * shadowViewPos;
    #else
        // gl_Position = ftransform();
        gl_Position = shadowProjection * shadowViewPos;
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

    // vec3 hsv = vec3(1.0);
    // hsv.x = dhMaterialId / 15.0;

    // vec3 color = HsvToRgb(hsv);
    // gcolor.rgb = linear_to_srgb(color);
}
