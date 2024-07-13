#define DEBUG_VIEW_NONE 0
#define DEBUG_VIEW_WORLD_NORMAL 1
#define DEBUG_VIEW_LIGHT_COORD 2
#define DEBUG_VIEW_VIEW_POS 3
#define DEBUG_VIEW_DEPTH_OPAQUE 4
#define DEBUG_VIEW_DEPTH_TRANSLUCENT 5
#define DEBUG_VIEW_BLOCK_ID 6
#define DEBUG_VIEW_SHADOWS 7

#define BLOCK_WATER 10u
#define BLOCK_PLANT 11u

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


const float EPSILON = 1.e-6;
const float PI = 3.1415926538;
const float TAU = PI * 2.0;
const int LOD_Max = 4;
const float alphaTestRef = 0.1;


#define saturate(x) (clamp((x), 0.0, 1.0))

#define linear_to_srgb(x) (pow(x, vec3(1.0/2.2)))

float maxOf(const in vec2 vec) {return max(vec[0], vec[1]);}

float pow2(const in float value) {return value*value;}

vec3 unproject(const in vec4 pos) {return pos.xyz / pos.w;}

float gaussian(const in float sigma, const in float x) {
    return exp(-(x*x) / (2.0 * (sigma*sigma)));
}

float linearizeDepth(const in float d, const in float zNear, const in float zFar) {
    float z_n = 2.0 * d - 1.0;
    return 2.0 * zNear * zFar / (zFar + zNear - z_n * (zFar - zNear));
}

vec3 mul3(const in mat4 matrix, const in vec3 vector) {
    return mat3(matrix) * vector + matrix[3].xyz;
}


#ifdef SHADOWS_ENABLED
#endif

#ifdef DH_LOD_FADE
#endif

#ifdef SSAO_ENABLED
#endif
