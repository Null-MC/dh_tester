float GetFogFactor(const in float viewDist) {
    float start = fogStart;
    float end = fogEnd;

    #ifdef DISTANT_HORIZONS
        if (isEyeInWater == 0) start = 0.25 * dhFarPlane;
        if (isEyeInWater == 0)   end = 0.50 * dhFarPlane;
    #endif

    return smoothstep(start, end, viewDist);
}
