#version 430 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D dhDepthTex;

uniform mat4 gbufferProjectionInverse;
uniform mat4 dhProjectionInverse;
uniform float dhNearPlane;
uniform float dhFarPlane;
// uniform float viewWidth;
// uniform float viewHeight;
uniform float near;
uniform float farPlane;
uniform vec3 fogColor;


/* RENDERTARGETS: 0 */
void main() {
    ivec2 uv = ivec2(gl_FragCoord.xy);

    float depth = texelFetch(depthtex0, uv, 0).r;
    float depthL = linearizeDepth(depth, near, farPlane);
    
    float dhDepth = texelFetch(dhDepthTex, uv, 0).r;
    float dhDepthL = linearizeDepth(dhDepth, dhNearPlane, dhFarPlane);

    mat4 projectionInv = gbufferProjectionInverse;
    if (depth >= 1.0 || (dhDepthL < depthL && dhDepth > 0.0)) {
        depth = dhDepth;
        depthL = dhDepthL;
        projectionInv = dhProjectionInverse;
    }

    gl_FragColor = vec4(fogColor, 0.0);
    
    if (depth < 1.0) {
        vec3 ndcPos = vec3(texcoord, depth) * 2.0 - 1.0;
        vec3 viewPos = unproject(projectionInv * vec4(ndcPos, 1.0));
        float viewDist = length(viewPos);

        gl_FragColor.a = smoothstep(0.0, 0.5 * dhFarPlane, viewDist);
    }
}
