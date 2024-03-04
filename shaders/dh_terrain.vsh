#version 430 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec3 localPos;
varying vec3 viewNormal;
varying vec4 gcolor;
varying vec2 lmcoord;

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
    #include "/lib/hsv.glsl"
#endif


void main() {
    viewNormal = mat3(gl_ModelViewMatrix) * gl_Normal;
    gcolor = gl_Color;

    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    // lmcoord  = gl_MultiTexCoord1.xy;
    
    vec3 vPos = gl_Vertex.xyz;

    vec3 cameraOffset = fract(cameraPosition);
    vPos = floor(vPos + cameraOffset + 0.5) - cameraOffset;

    vec3 viewPos = mul3(gl_ModelViewMatrix, vPos);
    localPos = mul3(gbufferModelViewInverse, viewPos);
    gl_Position = dhProjection * vec4(viewPos, 1.0);

    #ifdef SHADOWS_ENABLED
        //float viewDist = length(viewPos);
        vec3 offsetViewPos = viewPos + viewNormal * SHADOW_NORMAL_BIAS;

        shadowPos = mul3(gbufferModelViewInverse, offsetViewPos);
        shadowPos = mul3(shadowModelView, shadowPos);

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
                    shadowCameraOffset = shadowProjectionFit[3].xyz;
                #endif
            #endif

            distort(shadowPos, shadowCameraOffset.xy);
        #endif

        shadowPos = shadowPos * 0.5 + 0.5;
    #endif

    #if DEBUG_VIEW == DEBUG_VIEW_BLOCK_ID
        vec3 hsv = vec3(1.0);
        hsv.x = dhMaterialId / 15.0;

        vec3 color = HsvToRgb(hsv);
        gcolor.rgb = linear_to_srgb(color);
    #endif
}
