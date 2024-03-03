#version 430 compatibility
#extension GL_ARB_derivative_control : enable

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D dhDepthTex;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 dhProjectionInverse;
uniform float dhNearPlane;
uniform float dhFarPlane;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
// uniform float far;
uniform float farPlane;



uniform float gRadius = 2.0;
uniform float gStrength = 0.2;
uniform float gMinLight = 0.25;
uniform float gBias = 0.02;

const vec3 MAGIC = vec3(0.06711056, 0.00583715, 52.9829189);
const float GOLDEN_ANGLE = 2.39996323;


float InterleavedGradientNoise(const in vec2 pixel) {
    float x = dot(pixel, MAGIC.xy);
    return fract(MAGIC.z * fract(x));
}

float GetSpiralOcclusion(const in vec3 viewPos, const in vec3 viewNormal) {
    float dither = InterleavedGradientNoise(gl_FragCoord.xy);
    float rotatePhase = dither * TAU;
    float rStep = gRadius / SSAO_SAMPLE_COUNT;

    vec2 viewSize = vec2(viewWidth, viewHeight);

    float occlusion = 0.0;
    int sampleCount = 0;
    float radius = rStep;
    for (int i = 0; i < SSAO_SAMPLE_COUNT; i++) {
        vec2 offset = vec2(
            sin(rotatePhase),
            cos(rotatePhase)
        ) * radius;
        
        radius += rStep;
        rotatePhase += GOLDEN_ANGLE;

        vec3 sampleViewPos = viewPos + vec3(offset, -0.1);
        vec3 sampleClipPos = unproject(gbufferProjection * vec4(sampleViewPos, 1.0)) * 0.5 + 0.5;
        sampleClipPos = saturate(sampleClipPos);


        ivec2 uv = ivec2(sampleClipPos.xy * viewSize);

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


        if (depth >= 1.0 - EPSILON) continue;

        sampleClipPos.z = depth;
        sampleViewPos = unproject(projectionInv * vec4(sampleClipPos * 2.0 - 1.0, 1.0));

        vec3 diff = sampleViewPos - viewPos;
        float sampleDist = length(diff);
        vec3 sampleNormal = diff / sampleDist;

        float sampleNoLm = max(dot(viewNormal, sampleNormal) - gBias, 0.0);
        float aoF = 1.0 - saturate(sampleDist / gRadius);
        occlusion += sampleNoLm * aoF;
        sampleCount++;
    }

    occlusion /= max(sampleCount, 1);
    occlusion = smoothstep(0.0, gStrength, occlusion);

    return occlusion * (1.0 - gMinLight);
}


/* RENDERTARGETS: 1 */
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

    float occlusion = 0.0;
    
    if (depth < 1.0) {
        vec3 ndcPos = vec3(texcoord, depth) * 2.0 - 1.0;
        vec3 viewPos = unproject(projectionInv * vec4(ndcPos, 1.0));
        
        #ifdef GL_ARB_derivative_control
            // Get higher precision derivatives when available
            vec3 viewNormal = cross(dFdxFine(viewPos), dFdyFine(viewPos));
        #else
            vec3 viewNormal = cross(dFdx(viewPos), dFdy(viewPos));
        #endif

        viewNormal = normalize(viewNormal);

        occlusion = GetSpiralOcclusion(viewPos, viewNormal);
    }
    
    gl_FragColor = vec4(vec3(occlusion), 1.0);
}
