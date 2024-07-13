#version 430 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

uniform sampler2D colortex0;

#if DEBUG_VIEW != DEBUG_VIEW_NONE
    uniform sampler2D depthtex0;
    uniform sampler2D dhDepthTex0;
#endif

#if DEBUG_VIEW == DEBUG_VIEW_DEPTH_OPAQUE
    uniform sampler2D depthtex1;
    uniform sampler2D dhDepthTex1;
#endif

#if DEBUG_VIEW == DEBUG_VIEW_SHADOWS
    uniform sampler2D shadowcolor0;
#endif

#if DEBUG_VIEW != DEBUG_VIEW_NONE
    uniform mat4 gbufferProjectionInverse;
    uniform mat4 dhProjectionInverse;
    uniform float dhNearPlane;
    uniform float dhFarPlane;
    uniform float near;
    uniform float far;
    uniform float farPlane;
    uniform float viewWidth;
    uniform float viewHeight;
#endif

#if defined SHADOW_FRUSTUM_FIT && defined SHADOWS_ENABLED && DEBUG_VIEW == DEBUG_VIEW_SHADOWS
    uniform float aspectRatio;

    #ifdef IRIS_FEATURE_SSBO
        uniform mat4 shadowProjection;
    #else
        uniform mat4 gbufferModelViewInverse;
        uniform mat4 gbufferProjection;
        uniform mat4 shadowModelView;
    #endif
#endif

#if defined SHADOW_FRUSTUM_FIT && defined SHADOWS_ENABLED && DEBUG_VIEW == DEBUG_VIEW_SHADOWS
    #ifdef IRIS_FEATURE_SSBO
        #include "/lib/shadow_ssbo.glsl"
    #else
        #include "/lib/shadow_matrix.glsl"
    #endif

    #if defined SHADOW_DEBUG && defined IRIS_FEATURE_SSBO
        #include "/lib/text.glsl"
    #endif
#endif


/* RENDERTARGETS: 0 */
void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);

    #if DEBUG_VIEW != DEBUG_VIEW_NONE
        vec2 viewSize = vec2(viewWidth, viewHeight);
        vec2 texcoord = gl_FragCoord.xy / viewSize;
    #endif

    #if DEBUG_VIEW == DEBUG_VIEW_VIEW_POS
        float depth = texelFetch(depthtex0, uv, 0).r;
        float depthL = linearizeDepth(depth, near, farPlane);
        vec4 viewPos = vec4(0.0);

        float dhDepth = texelFetch(dhDepthTex0, uv, 0).r;
        float dhDepthL = linearizeDepth(dhDepth, dhNearPlane, dhFarPlane);

        mat4 projectionInv = gbufferProjectionInverse;
        if (depth >= 1.0 || (dhDepthL < depthL && dhDepth > 0.0)) {
            projectionInv = dhProjectionInverse;
            depth = dhDepth;
            // depthL = dhDepthL;
        }

        vec4 ndcPos = vec4(texcoord, depth, 1.0) * 2.0 - 1.0;
        viewPos = projectionInv * ndcPos;
        viewPos /= viewPos.w;
        // viewPos.xyz = abs(viewPos.xyz / viewPos.w);

        gl_FragColor = vec4(viewPos.xyz * 0.001, 1.0);
        gl_FragColor.rgb = linear_to_srgb(gl_FragColor.rgb);
    #elif DEBUG_VIEW == DEBUG_VIEW_DEPTH_OPAQUE
        float depth = texelFetch(depthtex1, uv, 0).r;
        float depthL = linearizeDepth(depth, near, farPlane);
        
        float dhDepth = texelFetch(dhDepthTex1, uv, 0).r;
        float dhDepthL = linearizeDepth(dhDepth, dhNearPlane, dhFarPlane);

        if (depth >= 1.0 || (dhDepthL < depthL && dhDepth > 0.0)) {
            // depth = dhDepth;
            depthL = dhDepthL;
        }

        depthL /= 0.5*dhFarPlane;
        gl_FragColor = vec4(vec3(depthL), 1.0);
        gl_FragColor.rgb = linear_to_srgb(gl_FragColor.rgb);
    #elif DEBUG_VIEW == DEBUG_VIEW_DEPTH_TRANSLUCENT
        float depth = texelFetch(depthtex0, uv, 0).r;
        float depthL = linearizeDepth(depth, near, farPlane);
        
        float dhDepth = texelFetch(dhDepthTex0, uv, 0).r;
        float dhDepthL = linearizeDepth(dhDepth, dhNearPlane, dhFarPlane);

        if (depth >= 1.0 || (dhDepthL < depthL && dhDepth > 0.0)) {
            // depth = dhDepth;
            depthL = dhDepthL;
        }

        depthL /= 0.5*dhFarPlane;
        gl_FragColor = vec4(vec3(depthL), 1.0);
        gl_FragColor.rgb = linear_to_srgb(gl_FragColor.rgb);
    #elif DEBUG_VIEW == DEBUG_VIEW_SHADOWS
        gl_FragColor = texture(shadowcolor0, texcoord);

        #ifdef SHADOW_FRUSTUM_FIT
            #ifndef IRIS_FEATURE_SSBO
                vec3 boundsMin, boundsMax;
                GetFrustumShadowBounds(boundsMin, boundsMax);
                mat4 shadowProjectionFit = BuildOrthoProjectionMatrix(boundsMin, boundsMax);
                //shadowProjectionFitInverse = inverse(shadowProjectionFit);

                vec3 shadowCameraOffset = (shadowProjectionFit * vec4(vec3(0.0), 1.0)).xyz;

                vec3 shadowViewCenter = 0.5 * (boundsMin + boundsMax);
            #endif

            vec3 shadowCenter = (shadowProjectionFit * vec4(shadowViewCenter, 1.0)).xyz * 0.5 + 0.5;
            vec2 centerOffset = texcoord - shadowCenter.xy;
            float centerF = step(length(centerOffset * vec2(aspectRatio, 1.0)), 0.008);
            gl_FragColor.rgb = mix(gl_FragColor.rgb, vec3(0.0, 0.0, 1.0), 0.5*centerF);

            vec2 playerOffset = texcoord - (shadowCameraOffset.xy * 0.5 + 0.5);
            float playerF = step(length(playerOffset * vec2(aspectRatio, 1.0)), 0.008);
            gl_FragColor.rgb = mix(gl_FragColor.rgb, vec3(1.0, 0.0, 0.0), 0.5*playerF);
        #endif
    #else
        gl_FragColor = texelFetch(colortex0, uv, 0);
    #endif

    #if defined SHADOW_FRUSTUM_FIT && defined SHADOWS_ENABLED && defined SHADOW_DEBUG && defined IRIS_FEATURE_SSBO
        beginText(ivec2(gl_FragCoord.xy * 0.5), ivec2(4, viewHeight/2 - 24));

        text.bgCol = vec4(0.0, 0.0, 0.0, 0.6);
        text.fgCol = vec4(1.0, 1.0, 1.0, 1.0);

        printString((_C, _e, _n, _t, _e, _r, _colon, _space));
        printVec3(shadowViewCenter);
        printLine();

        endText(gl_FragColor.rgb);
    #endif
}
