void distort(inout vec3 shadowPos, const in vec2 cameraOffset) {
    const float distortionF = 1.0 - SHADOW_DISTORTION * 0.01;

    #ifdef SHADOW_FRUSTUM_FIT
        shadowPos.xy -= cameraOffset;

    #endif

    float factor = length(shadowPos.xy) + distortionF;
    // float factor = maxOf(abs(shadowPos.xy)) + distortionF;

    shadowPos.xy = (shadowPos.xy / factor) * (1.0 + distortionF);

    #ifdef SHADOW_FRUSTUM_FIT
        shadowPos.xy *= 1.0 + abs(0.5*cameraOffset);

        shadowPos.xy += cameraOffset;
    #endif
}
