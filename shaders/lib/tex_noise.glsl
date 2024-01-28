// https://gitlab.com/jeseibel/distant-horizons-core/-/blob/main/core/src/main/resources/shaders/flat_shaded.frag?ref_type=heads
// Property of Distant Horizons [mod]

const int noiseSteps = 4;
const float noiseIntensity = 5.0;
const int noiseDropoff = 1024;


float rand(float co) { return fract(sin(co*(91.3458)) * 47453.5453); }
float rand(vec2 co) { return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453); }
float rand(vec3 co) { return rand(co.xy + rand(co.z)); }

vec3 quantize(const in vec3 val, const in int stepSize) {
    return floor(val * stepSize) / stepSize;
}

void applyNoise(inout vec4 fragColor, const in vec3 viewPos, const in float viewDist) {
    // vec3 vertexNormal = normalize(cross(dFdy(vPos.xyz), dFdx(vPos.xyz)));
    // // This bit of code is required to fix the vertex position problem cus of floats in the verted world position varuable
    // vec3 fixedVPos = vPos.xyz + vertexNormal * 0.001;

    float noiseAmplification = noiseIntensity * 0.01;
    float lum = (fragColor.r + fragColor.g + fragColor.b) / 3.0;
    noiseAmplification = (1.0 - pow(lum * 2.0 - 1.0, 2.0)) * noiseAmplification; // Lessen the effect on depending on how dark the object is, equasion for this is -(2x-1)^{2}+1
    noiseAmplification *= fragColor.a; // The effect would lessen on transparent objects

    // Random value for each position
    float randomValue = rand(quantize(viewPos, noiseSteps))
    * 2.0 * noiseAmplification - noiseAmplification;

    // Modifies the color
    // A value of 0 on the randomValue will result in the original color, while a value of 1 will result in a fully bright color
    vec3 newCol = fragColor.rgb + (1.0 - fragColor.rgb) * randomValue;
    newCol = clamp(newCol, 0.0, 1.0);

    if (noiseDropoff != 0) {
        float distF = min(viewDist / noiseDropoff, 1.0);
        newCol = mix(newCol, fragColor.rgb, distF); // The further away it gets, the less noise gets applied
    }

    fragColor.rgb = newCol;
}
