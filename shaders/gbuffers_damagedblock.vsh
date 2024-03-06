#version 430 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

out VertexData {
    vec2 texcoord;
} vOut;


void main() {
    gl_Position = ftransform();
    vOut.texcoord  = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
