#define DEBUG_VIEW_NONE 0
#define DEBUG_VIEW_WORLD_NORMAL 1
#define DEBUG_VIEW_VIEW_POS 2
#define DEBUG_VIEW_DEPTH_LINEAR 3
#define DEBUG_VIEW_BLOCK_ID 4
#define DEBUG_VIEW_SHADOWS 5

#define BLOCK_WATER 10u

#define DH_MATERIAL_LEAVES 1u
#define DH_MATERIAL_STONE 2u
#define DH_MATERIAL_WOOD 3u
#define DH_MATERIAL_METAL 4u
#define DH_MATERIAL_DIRT 5u
#define DH_MATERIAL_LAVA 6u
#define DH_MATERIAL_DEEPSLATE 7u
#define DH_MATERIAL_SNOW 8u
#define DH_MATERIAL_SAND 9u
#define DH_MATERIAL_TERRACOTTA 10u
#define DH_MATERIAL_NETHER_STONE 11u
#define DH_MATERIAL_EMISSIVE 15u


#define linear_to_srgb(x) (pow(x, vec3(1.0/2.2)))

float maxOf(const in vec2 vec) {return max(vec[0], vec[1]);}

vec3 unproject(const in vec4 pos) {return pos.xyz / pos.w;}

float linearizeDepth(const in float d, const in float zNear, const in float zFar) {
    float z_n = 2.0 * d - 1.0;
    return 2.0 * zNear * zFar / (zFar + zNear - z_n * (zFar - zNear));
}

#ifdef SHADOWS_ENABLED
#endif
