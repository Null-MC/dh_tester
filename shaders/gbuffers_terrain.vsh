#version 430 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec3 mc_Entity;

out VertexData {
    vec4 color;
    vec2 lmcoord;
    vec2 texcoord;
    vec3 localPos;
    vec3 viewNormal;
    flat uint blockId;

    #ifdef SHADOWS_ENABLED
        varying vec3 shadowPos;
    #endif
} vOut;

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
    vOut.color = gl_Color;
    
    vec3 viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
    vOut.viewNormal = gl_NormalMatrix * gl_Normal;
    vOut.texcoord  = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);

    vOut.blockId = uint(mc_Entity.x + 0.5);

    if (vOut.blockId == BLOCK_PLANT) {
        // TODO: extract from matrix
        vOut.viewNormal = mat3(gbufferModelView) * vec3(0.0, 1.0, 0.0);
    }

    #ifdef SHADOWS_ENABLED
        vec3 offsetViewPos = viewPos + vOut.viewNormal * SHADOW_NORMAL_BIAS;

        vOut.shadowPos = mul3(gbufferModelViewInverse, offsetViewPos);
        vOut.shadowPos = mul3(shadowModelView, vOut.shadowPos);

        vOut.shadowPos.z += SHADOW_OFFSET_BIAS;

        #ifdef SHADOW_FRUSTUM_FIT
            #ifndef IRIS_FEATURE_SSBO
                vec3 boundsMin, boundsMax;
                GetFrustumShadowBounds(boundsMin, boundsMax);
                mat4 shadowProjectionFit = BuildOrthoProjectionMatrix(boundsMin, boundsMax);
            #endif

            vOut.shadowPos = mul3(shadowProjectionFit, vOut.shadowPos);
        #else
            vOut.shadowPos = mul3(shadowProjection, vOut.shadowPos);
        #endif

        #if SHADOW_DISTORTION > 0
            #ifndef IRIS_FEATURE_SSBO
                vec3 shadowCameraOffset = vec3(0.0);

                #ifdef SHADOW_FRUSTUM_FIT
                    // shadowCameraOffset = (shadowProjectionFit * vec4(vec3(0.0), 1.0)).xyz;
                    shadowCameraOffset = shadowProjectionFit[3].xyz;
                #endif
            #endif

            distort(vOut.shadowPos, shadowCameraOffset.xy);
        #endif

        vOut.shadowPos = vOut.shadowPos * 0.5 + 0.5;
    #endif

    #if DEBUG_VIEW == DEBUG_VIEW_BLOCK_ID
        vOut.color = vec4(vec3(0.0), 1.0);
    #endif
}
