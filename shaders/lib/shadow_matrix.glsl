const float ShadowFrustumPadding = 3.0;


void GetFrustumMinMax(const in mat4 matProjection, out vec3 boundsMin, out vec3 boundsMax) {
    for (int i = 0; i < 8; i++) {
        vec3 corner = vec3(ivec3(i, i / 2, i / 4) % 2) * 2.0 - 1.0;
        vec3 shadowPos = unproject(matProjection * vec4(corner, 1.0));

        if (i == 0) {
            boundsMin = shadowPos;
            boundsMax = shadowPos;
        }
        else {
            boundsMin = min(boundsMin, shadowPos);
            boundsMax = max(boundsMax, shadowPos);
        }
    }
}

mat4 BuildOrthoProjectionMatrix(const in vec3 boundsMin, const in vec3 boundsMax) {
    vec3 size = boundsMax - boundsMin;
    vec3 translate = (boundsMin + boundsMax) / size;
    vec3 scale = 2.0 / size;

    return mat4(
        scale.x, 0.0, 0.0, 0.0,
        0.0, scale.y, 0.0, 0.0,
        0.0, 0.0, -scale.z, 0.0,
        -translate, 1.0);
}

void GetFrustumShadowBounds(out vec3 boundsMin, out vec3 boundsMax) {
    float shadowNear = near;
    float shadowFar = min(shadowDistance, dhFarPlane);

    mat4 matSceneProjectionRanged = gbufferProjection;
    matSceneProjectionRanged[2][2] = -(shadowFar + shadowNear) / (shadowFar - shadowNear);
    matSceneProjectionRanged[3][2] = -(2.0 * shadowFar * shadowNear) / (shadowFar - shadowNear);

    mat4 matProjectionToShadowView = gbufferModelViewInverse * inverse(matSceneProjectionRanged);
    matProjectionToShadowView = shadowModelView * matProjectionToShadowView;
    GetFrustumMinMax(matProjectionToShadowView, boundsMin, boundsMax);

    boundsMin -= ShadowFrustumPadding;
    boundsMax += ShadowFrustumPadding;

    boundsMin.z = -shadowDistance;
    boundsMax.z =  shadowDistance;

    boundsMin = floor(boundsMin / shadowIntervalSize) * shadowIntervalSize;
    boundsMax = ceil(boundsMax / shadowIntervalSize) * shadowIntervalSize;
}
