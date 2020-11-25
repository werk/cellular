#version 300 es
precision mediump float;
precision highp int;

uniform highp usampler2D state;
uniform sampler2D materials;
uniform vec2 resolution;
uniform float t;
out vec4 outputColor;

const float tileSize = 12.0;
const vec2 tileMapSize = vec2(4096.0, 256.0);

const uint NOT_FOUND = 4294967295u;

struct Material {
    uint material;
    uint WEIGHT;
    uint HEAT;
};

const uint AIR = 0u;
const uint WATER = 5u;
const uint SAND = 30u;
const uint LAVA = 65u;

const uint AIR_WEIGHT_SIZE = 1u;
const uint AIR_HEAT_SIZE = 5u;
const uint WATER_WEIGHT_SIZE = 5u;
const uint WATER_HEAT_SIZE = 5u;
const uint SAND_WEIGHT_SIZE = 7u;
const uint SAND_HEAT_SIZE = 5u;
const uint LAVA_HEAT_SIZE = 5u;


uint encode(Material material) {
    uint traits = 0u;
    switch(material.material) {
        case AIR:
            traits = material.WEIGHT + AIR_WEIGHT_SIZE * (material.HEAT);
            break;
        case WATER:
            traits = material.WEIGHT + WATER_WEIGHT_SIZE * (material.HEAT);
            break;
        case SAND:
            traits = material.WEIGHT + SAND_WEIGHT_SIZE * (material.HEAT);
            break;
        case LAVA:
            traits = material.HEAT;
            break;
        default:
            traits = - material.material;
    }
    return material.material + traits;
}

Material decode(uint integer) {
    Material material;
    material.WEIGHT = NOT_FOUND;
    material.HEAT = NOT_FOUND;
    if(integer < WATER) {
        material.material = AIR;
        uint trait = integer - AIR;
        uint WEIGHT_offset = AIR_HEAT_SIZE;
        material.WEIGHT = trait / WEIGHT_offset;
        uint WEIGHT_remainder = trait - (material.WEIGHT * WEIGHT_offset);
        material.HEAT = WEIGHT_remainder;
    } else if(integer < SAND) {
        material.material = WATER;
        uint trait = integer - WATER;
        uint WEIGHT_offset = WATER_HEAT_SIZE;
        material.WEIGHT = trait / WEIGHT_offset;
        uint WEIGHT_remainder = trait - (material.WEIGHT * WEIGHT_offset);
        material.HEAT = WEIGHT_remainder;
    } else if(integer < LAVA) {
        material.material = SAND;
        uint trait = integer - SAND;
        uint WEIGHT_offset = SAND_HEAT_SIZE;
        material.WEIGHT = trait / WEIGHT_offset;
        uint WEIGHT_remainder = trait - (material.WEIGHT * WEIGHT_offset);
        material.HEAT = WEIGHT_remainder;
    } else {
        material.material = LAVA;
        uint trait = integer - LAVA;
        material.HEAT = trait;
    }
    return material;
}

uint materialOffset(Material material) {
    switch(material.material) {
        case AIR: return 0u;
        case WATER: return 10u;
        case SAND: return 2u;
        case LAVA: return 15u;
        default: return 255u;
    }
}

void main() {
    vec2 stateSize = vec2(100, 100);

    vec2 offset = vec2(0, 0);
    float zoom = 40.0;
    float screenToMapRatio = zoom / resolution.x;
    vec2 xy = gl_FragCoord.xy * screenToMapRatio + offset;
    vec2 tile = floor(xy + 0.5);
    vec2 spriteOffset = mod(xy + 0.5, 1.0) * tileSize;

    uint integer = texture(state, tile / stateSize).r;
    Material material = decode(integer);
    uint o = materialOffset(material);

    vec2 tileMapOffset = vec2(float(o) * tileSize, tileSize) + spriteOffset * vec2(1, -1);
    vec4 color = texture(materials, tileMapOffset / tileMapSize);

    outputColor = color;
}