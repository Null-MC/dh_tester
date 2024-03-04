#version 430 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

out VertexData {
    vec4 color;
    vec2 lmcoord;
    vec3 localPos;
    vec3 viewNormal;

    flat int materialId;

    #ifdef SHADOWS_ENABLED
        vec3 shadowPos;
    #endif
} vOut;

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
    vOut.viewNormal = mat3(gbufferModelView) * gl_Normal;
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.materialId = dhMaterialId;
    vOut.color = gl_Color;
    
    vec3 vPos = gl_Vertex.xyz;

    vec3 cameraOffset = fract(cameraPosition);
    vPos = floor(vPos + cameraOffset + 0.5) - cameraOffset;

    // Move down to match vanilla
    bool isWater = (vOut.materialId == DH_BLOCK_WATER);
    if (isWater) vPos.y -= (1.8/16.0);

    vec3 viewPos = mul3(gl_ModelViewMatrix, vPos);
    vOut.localPos = mul3(gbufferModelViewInverse, viewPos);
    gl_Position = dhProjection * vec4(viewPos, 1.0);

    #ifdef SHADOWS_ENABLED
        // float viewDist = length(viewPos);
        vec3 offsetViewPos = viewPos.xyz + vOut.viewNormal * SHADOW_NORMAL_BIAS;

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
                    shadowCameraOffset = shadowProjectionFit[3].xyz;
                #endif
            #endif

            distort(vOut.shadowPos, shadowCameraOffset.xy);
        #endif

        vOut.shadowPos = vOut.shadowPos * 0.5 + 0.5;
    #endif

    #if DEBUG_VIEW == DEBUG_VIEW_BLOCK_ID
        vec3 hsv = vec3(1.0);
        hsv.x = vOut.materialId / 15.0;

        vec3 color = HsvToRgb(hsv);
        vOut.color.rgb = pow(color, vec3(1.0/2.2));
    #endif
}
