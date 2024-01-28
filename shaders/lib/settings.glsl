#define DEBUG_VIEW 0 // [0 1 2 3 4 5]
#define DH_CLIP_DIST 80 // [0 10 20 30 40 50 60 70 80 90 100]
#define SHADOWS_ENABLED
#define WATER_CLIP

// #define SHADOW_DEBUG
#define SHADOW_DISTORTION 0 // [0 10 20 30 40 50 60 70 75 80 85 90 95]
#define SHADOW_NORMAL_BIAS 0.02 // [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08]
#define SHADOW_DIST 200 // [50 100 150 200 250 300 400 500 600 800 1000 1500 2000 2500 3000 3500 4000]
#define SHADOW_FRUSTUM_FIT

const float dh_clipDistF = DH_CLIP_DIST * 0.01;
const float dh_waterClipDist = 0.8;

const float sunPathRotation = 0.0;
const float shadowIntervalSize = 2.0;
const float shadowDistance = SHADOW_DIST;
const int shadowMapResolution = 2048; // [1024 2048 4096 8192]
const float shadowDistanceRenderMul = -1.0;
const bool shadowHardwareFiltering = true;
