precision mediump float;
uniform sampler2D state;
uniform vec2 scale;
uniform float seedling;
uniform int step;

const uint NOT_FOUND = 4294967295;

struct Material {
    uint material;
    uint WEIGHT;
    uint HEAT;
};

const uint AIR = 0;
const uint WATER = 5;
const uint SAND = 30;

vec4 intToVec4(uint integer) {
    uint o4 = 256 * 256 * 256;
    uint x4 = integer / o4;
    uint r4 = integer - (x4 * o4);
    uint o3 = 256 * 256;
    uint x3 = r4 / o3;
    uint r3 = r4 - (x3 * o3);
    uint o2 = 256;
    uint x2 = r3 / o2;
    uint r2 = r3 - (x2 * o2);
    uint x1 = r2;
    return vec4(float(x1), float(x2), float(x3), float(x4));
}

uint vec4ToInt(vec4 pixel) {
    return uint(pixel.x) + 256 * (uint(pixel.y) + 256 * (uint(pixel.z) + 256 * uint(pixel.w)));
}

vec4 encode(Material material) {
    switch(material.material) {
        case AIR:
            uint traits = material.WEIGHT + AIR_WEIGHT_SIZE * (material.HEAT);
            return intToVec4(AIR + traits);
        case WATER:
            uint traits = material.WEIGHT + WATER_WEIGHT_SIZE * (material.HEAT);
            return intToVec4(WATER + traits);
        case SAND:
            uint traits = material.WEIGHT + SAND_WEIGHT_SIZE * (material.HEAT);
            return intToVec4(SAND + traits);
        default:
            return null;
    }
}

Material decode(vec4 pixel) {
    uint integer = vec4ToInt(pixel);
    Material material;
    if(integer < WATER) {
        material.material = AIR;
        uint trait = integer - AIR;
        WEIGHT_offset = AIR_HEAT_SIZE;
        material.WEIGHT = trait / WEIGHT_offset;
        WEIGHT_remainder = trait - (material.WEIGHT * WEIGHT_offset);
        material.HEAT = WEIGHT_remainder;
    } else if(integer < SAND) {
        material.material = WATER;
        uint trait = integer - WATER;
        WEIGHT_offset = WATER_HEAT_SIZE;
        material.WEIGHT = trait / WEIGHT_offset;
        WEIGHT_remainder = trait - (material.WEIGHT * WEIGHT_offset);
        material.HEAT = WEIGHT_remainder;
    } else {
        material.material = SAND;
        uint trait = integer - SAND;
        WEIGHT_offset = SAND_HEAT_SIZE;
        material.WEIGHT = trait / WEIGHT_offset;
        WEIGHT_remainder = trait - (material.WEIGHT * WEIGHT_offset);
        material.HEAT = WEIGHT_remainder;
    }
    return material;
}

Material lookupMaterial(vec2 offset) {
    vec4 color = texture2D(state, offset / scale);
    return decode(color);
}

bool rule_FallDown(inout Material pp_0_0, inout Material pp_0_1) {
    uint n = pp_0_0.WEIGHT;
    uint m = pp_0_1.WEIGHT;
    if(n == NOT_FOUND) return false;
    if(m == NOT_FOUND) return false;
    if(n <= m) return false;
    return true;
}

bool rule_WaveLeft(inout Material pp_0_0, inout Material pp_1_0) {
    if(pp_0_0.material != AIR) return false;
    if(pp_1_0.material != WATER) return false;
    return true;
}

void main() {
    vec2 position = gl_FragCoord.xy - 0.5;
    vec2 offset = mod(float(step), 2.0) == 0.0 ? vec2(-1.0, -1.0) : vec2( 0.0,  0.0);
    vec2 bottomLeft = floor((position + offset) * 0.5) * 2.0 - offset;

    // Read and parse relevant pixels
    Material pp_0_0 = lookupMaterial(bottomLeft + vec2(0.0, 0.0));
    Material pp_0_1 = lookupMaterial(bottomLeft + vec2(0.0, 1.0));
    Material pp_1_0 = lookupMaterial(bottomLeft + vec2(0.1, 0.0));
    Material pp_1_1 = lookupMaterial(bottomLeft + vec2(0.1, 1.0));
    Material pm_0_1 = lookupMaterial(bottomLeft + vec2(0.0, -1.0));
    Material pm_1_1 = lookupMaterial(bottomLeft + vec2(0.1, -1.0));

    // Rules
    bool did_Fall = false;
    bool did_FallDown = false;
    if(true) {
        did_FallDown = did_FallDown || rule_FallDown(List(pp_0_0, pp_0_1));
        did_Fall = did_Fall || did_FallDown;
    }

    bool did_Wave = false;
    bool did_WaveLeft = false;
    if(!did_Fall) {
        did_WaveLeft = did_WaveLeft || rule_WaveLeft(List(pp_0_0, pp_1_0));
        did_Wave = did_Wave || did_WaveLeft;
    }

   // Write and encode own material
   Material target = null;
   vec2 quadrant = position - bottomLeft;
   if(quadrant == vec2(0.0, 0.0)) target = pp_0_0;
   else if(quadrant == vec2(0.0, 0.1)) target = pp_0_1;
   else if(quadrant == vec2(1.0, 0.0)) target = pp_1_0;
   else if(quadrant == vec2(1.0, 0.1)) target = pp_1_1;
   gl_FragColor = encode(target);
}