#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

varying vec2 texcoord;
varying vec3 localPos;
varying vec4 gcolor;
flat varying uint blockId;

uniform sampler2D gtexture;

uniform float far;


/* RENDERTARGETS: 0 */
void main() {
    bool isWater = (blockId == BLOCK_WATER);

    float viewDist = length(localPos);
    if (isWater && viewDist > dh_clipDistF * far) {discard;}

    gl_FragColor = texture(gtexture, texcoord) * gcolor;
}
