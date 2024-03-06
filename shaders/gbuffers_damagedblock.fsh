#version 330 compatibility
#extension GL_EXT_gpu_shader4_1 : enable

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in VertexData {
    vec2 texcoord;
} vIn;

uniform sampler2D gtexture;
uniform sampler2D depthtex1;

uniform float near;
uniform float farPlane;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outFinal;

void main() {
    float depth = texelFetch(depthtex1, ivec2(gl_FragCoord.xy), 0).r;
    float depthL = linearizeDepth(depth, near, farPlane);

    float thisDepthL = linearizeDepth(gl_FragCoord.z, near, farPlane);
    if (abs(depthL - thisDepthL) > 0.1) {discard; return;}

    outFinal = texture(gtexture, vIn.texcoord);
    if (outFinal.a < 0.1) {discard; return;}
}
