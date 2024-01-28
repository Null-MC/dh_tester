#ifdef PROGRAM_BEGIN
    layout(binding = 0) buffer shadowData
#else
    layout(binding = 0) readonly buffer shadowData
#endif
{
    mat4 shadowProjectionFit;           // 64
    // mat4 shadowProjectionFitInverse;    // 64
    vec3 shadowCameraOffset;            // 12
    vec3 shadowViewCenter;              // 12
};
