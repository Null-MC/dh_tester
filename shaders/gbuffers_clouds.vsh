#version 330 compatibility

varying vec4 pos;
varying vec4 gcolor;
varying vec2 lmcoord;

#include "/lib/settings.glsl"
#include "/lib/common.glsl"


void main() {
    gl_Position = ftransform();
    gcolor = gl_Color;
    
    pos = gl_ModelViewMatrix * gl_Vertex;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
}
