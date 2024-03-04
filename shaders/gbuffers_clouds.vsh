#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

out VertexData {
    vec4 color;
    vec2 lmcoord;
    vec3 viewPos;
    vec3 viewNormal;
} vOut;


void main() {
    gl_Position = ftransform();
    vOut.color = gl_Color;
    
    vOut.lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vOut.viewPos = mul3(gl_ModelViewMatrix, gl_Vertex.xyz);
    vOut.viewNormal = gl_NormalMatrix * gl_Normal;
}
