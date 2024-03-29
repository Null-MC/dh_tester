vec3 GetSkyLightViewDir() {
    vec3 sunDir = GetSunVector();
    vec3 lightDir = sunDir * sign(sunDir.y);
    return mat3(gbufferModelView) * lightDir;
}

vec3 GetDiffuseLighting(in vec2 lmcoord, const in float shadowF, const in float NoLm) {
    lmcoord = clamp((lmcoord - (0.5/16.0)) / (15.0/16.0), 0.0, 1.0);
    
    float lit = pow(NoLm, 0.5) * shadowF;
    lmcoord.y *= lit * 0.5 + 0.5;

    lmcoord = lmcoord * (15.0/16.0) + (0.5/16.0);
    return textureLod(lightmap, lmcoord, 0).rgb;
}

float GetSpecularF(const in vec3 viewDir, const in vec3 viewNormal, const in vec3 lightViewDir) {
    vec3 reflectDir = reflect(viewDir, viewNormal);
    return pow(max(dot(reflectDir, lightViewDir), 0.0), 32.0);
}
