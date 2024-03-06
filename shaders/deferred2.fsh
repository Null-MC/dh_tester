#version 430 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D depthtex0;
uniform sampler2D dhDepthTex;
uniform sampler2D colortex1;

uniform float dhNearPlane;
uniform float dhFarPlane;
uniform float viewWidth;
uniform float viewHeight;
uniform float aspect;
uniform float near;
uniform float farPlane;


float BilateralGaussianBlur(const in vec2 texcoord, const in float linearDepth) {
    vec3 g_sigma = vec3(1.6 * aspect, 1.6, 0.01 * linearDepth);
    
    vec2 viewSize = vec2(viewWidth, viewHeight);
    vec2 pixelSize = 1.0 / viewSize;

    float accum = 0.0;
    float total = 0.0;
    for (int iy = -SSAO_BLUR_RADIUS; iy <= SSAO_BLUR_RADIUS; iy++) {
        float fy = gaussian(g_sigma.y, iy);

        for (int ix = -SSAO_BLUR_RADIUS; ix <= SSAO_BLUR_RADIUS; ix++) {
            float fx = gaussian(g_sigma.x, ix);

            vec2 sampleTex = texcoord + ivec2(ix, iy) * pixelSize;
            float sampleValue = textureLod(colortex1, sampleTex, 0).r;

            float depth = textureLod(depthtex0, sampleTex, 0).r;
            float depthL = linearizeDepth(depth, near, farPlane);
            
            float dhDepth = textureLod(dhDepthTex, sampleTex, 0).r;
            float dhDepthL = linearizeDepth(dhDepth, dhNearPlane, dhFarPlane);

            if (depth >= 1.0 || (dhDepthL < depthL && dhDepth > 0.0)) {
                depth = dhDepth;
                depthL = dhDepthL;
            }

            float depthDiff = abs(depthL - linearDepth);
            float fv = gaussian(g_sigma.z, depthDiff);

            float weight = fx*fy*fv;
            accum += weight * sampleValue;
            total += weight;
        }
    }

    if (total <= 1.e-4) return 0.0;
    return accum / total;
}


/* RENDERTARGETS: 0 */
void main() {
    float depth = textureLod(depthtex0, texcoord, 0).r;
    float depthL = linearizeDepth(depth, near, farPlane);
    
    float dhDepth = textureLod(dhDepthTex, texcoord, 0).r;
    float dhDepthL = linearizeDepth(dhDepth, dhNearPlane, dhFarPlane);

    if (depth >= 1.0 || (dhDepthL < depthL && dhDepth > 0.0)) {
        depth = dhDepth;
        depthL = dhDepthL;
    }

    gl_FragColor = vec4(0.0);
    
    if (depth < 1.0) {
        #if SSAO_BLUR_RADIUS > 0
            gl_FragColor.a = BilateralGaussianBlur(texcoord, depthL);
        #else
            gl_FragColor.a = textureLod(colortex1, texcoord, 0).r;
        #endif
    }
}
