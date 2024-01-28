vec3 GetSunVector() {
    float timeAngle = worldTime / 24000.0;
    const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
    float ang = fract(timeAngle - 0.25);
    ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
    return normalize(vec3(-sin(ang), cos(ang) * sunRotationData));
}
