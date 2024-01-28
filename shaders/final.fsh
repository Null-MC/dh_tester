#version 430 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

uniform sampler2D depthtex0;
uniform sampler2D dhDepthTex;
uniform sampler2D colortex0;

#if DEBUG_VIEW == DEBUG_VIEW_SHADOWS
    uniform sampler2D shadowcolor0;
#endif

uniform mat4 gbufferProjectionInverse;
uniform mat4 dhProjectionInverse;
uniform float dhNearPlane;
uniform float dhFarPlane;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;

#if defined SHADOW_FRUSTUM_FIT && defined SHADOWS_ENABLED
    uniform float aspectRatio;

    #ifdef IRIS_FEATURE_SSBO
        uniform mat4 shadowProjection;
    #else
        uniform mat4 gbufferModelViewInverse;
        uniform mat4 gbufferProjection;
        uniform mat4 shadowModelView;
    #endif
#endif

#if defined SHADOW_FRUSTUM_FIT && defined SHADOWS_ENABLED
    #ifdef IRIS_FEATURE_SSBO
        #include "/lib/shadow_ssbo.glsl"
    #else
        #include "/lib/shadow_matrix.glsl"
    #endif

    #include "/lib/text.glsl"
#endif


void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);
    vec2 viewSize = vec2(viewWidth, viewHeight);
    vec2 texcoord = gl_FragCoord.xy / viewSize;

    #if DEBUG_VIEW == DEBUG_VIEW_VIEW_POS
        float depth = texelFetch(depthtex0, uv, 0).r;
        vec4 viewPos = vec4(0.0);

        if (depth < 1.0) {
            vec4 ndcPos = vec4(texcoord, depth, 1.0) * 2.0 - 1.0;
            viewPos = gbufferProjectionInverse * ndcPos;
            viewPos.xyz /= viewPos.w;
        }
        else {
            depth = texelFetch(dhDepthTex, ivec2(gl_FragCoord.xy), 0).r;
            
            vec4 ndcPos = vec4(texcoord, depth, 1.0) * 2.0 - 1.0;
            viewPos = dhProjectionInverse * ndcPos;
            viewPos.xyz /= viewPos.w;
        }

        gl_FragColor = vec4(viewPos.xyz * 0.001, 1.0);
        gl_FragColor.rgb = linear_to_srgb(gl_FragColor.rgb);
    #elif DEBUG_VIEW == DEBUG_VIEW_DEPTH_LINEAR
        float depth = texelFetch(depthtex0, uv, 0).r;
        
        mat4 projectionInv = gbufferProjectionInverse;
        float _near = near;
        float _far = far * 4.0;
        if (depth >= 1.0) {
            depth = texelFetch(dhDepthTex, uv, 0).r;
            projectionInv = dhProjectionInverse;
            _near = dhNearPlane;
            _far = dhFarPlane;
        }

        vec4 viewPos = vec4(0.0);
        if (gl_FragCoord.x/viewWidth < 0.5) {
            depth = linearizeDepth(depth, _near, _far);// / (0.5*dhFarPlane);
        }
        else {
            vec4 ndcPos = vec4(texcoord, depth, 1.0) * 2.0 - 1.0;
            viewPos = projectionInv * ndcPos;
            viewPos.xyz /= viewPos.w;

            depth = -viewPos.z;
        }

        depth /= 0.5*dhFarPlane;
        gl_FragColor = vec4(vec3(depth), 1.0);
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
