#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"


void main() {
    gl_Position = ftransform();
}
