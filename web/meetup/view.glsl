#version 300 es
precision mediump float;
precision highp int;

uniform highp usampler2D state;
uniform sampler2D materials;
uniform vec2 resolution;
uniform float t;
uniform vec2 offset;
uniform float zoom;
uniform ivec4 selection;
out vec4 outputColor;

const float tileSize = 12.0;
const vec2 tileMapSize = vec2(4096.0, 256.0);

const uint NOT_FOUND = 4294967295u;
uint random(inout uint seed, uint entropy, uint range) {
    seed ^= entropy;
    seed += (seed << 10u);
    seed ^= (seed >> 6u);
    seed += (seed << 3u);
    seed ^= (seed >> 11u);
    seed += (seed << 15u);
    return seed % range;
}

// BEGIN COMMON

// There are 4 different tiles

const uint Air = 0u;
const uint Water = 1u;
const uint Sand = 2u;
const uint Rock = 3u;

struct value {
    uint material;
    uint Tile;
    uint Weight;
};

const value ALL_NOT_FOUND = value(
    NOT_FOUND
,   NOT_FOUND
,   NOT_FOUND
);

uint Tile_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Air:
            break;
        case Rock:
            n += 1u;
            break;
        case Sand:
            n += 1u + 1u;
            break;
        case Water:
            n += 1u + 1u + 1u;
            break;
    }
    return n;
}

value Tile_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 1u) {
        v.material = Air;
        v.Weight = 1u;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Rock;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Sand;
        v.Weight = 3u;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Water;
        v.Weight = 2u;
        return v;
    }
    n -= 1u;
    return v;
}

// END COMMON

void materialOffset(value v, out uint front) {
    front = NOT_FOUND;
    switch(v.material) {
        case Air:
            break;
        case Rock:
            front = 1u;
            break;
        case Sand:
            front = 2u;
            break;
        case Water:
            front = 8u;
            break;
        default:
            front = 255u;
            break;
    }
}

vec4 tileColor(vec2 xy, uint offset) {
    vec2 spriteOffset = mod(xy, 1.0) * tileSize;
    vec2 tileMapOffset = vec2(float(offset) * tileSize, tileSize) + spriteOffset * vec2(1, -1);
    return texture(materials, tileMapOffset / tileMapSize);
}

vec4 blend(vec4 below, vec4 above) {
    return above * above.a + below * (1.0 - above.a);
}

vec4 backgroundPattern(vec2 xy) {
    vec2 offset = vec2(tileMapSize.x - 27.0, 120) + vec2(mod(xy.x * tileSize, 27.0), mod(xy.y * tileSize, 23.0)) * vec2(1, -1);
    return texture(materials, offset / tileMapSize);
}

vec4 shroudPattern(vec2 xy) {
    vec2 offset = vec2(tileMapSize.x - 67.0, 120 - 23) + vec2(mod(xy.x * tileSize, 67.0), mod(xy.y * tileSize, 47.0)) * vec2(1, -1);
    return texture(materials, offset / tileMapSize);
}

void main() {
    vec2 stateSize = vec2(1000, 1000);
    float screenToMapRatio = zoom / resolution.x;
    vec2 xy = gl_FragCoord.xy * screenToMapRatio + offset;

    if(int(xy.x) < 0 || int(xy.x) >= int(stateSize.x) || int(xy.y) < 0 || int(xy.y) >= int(stateSize.y)) {
        outputColor = shroudPattern(xy);
        return;
    }

    uint n = texelFetch(state, ivec2(xy), 0).r;
    value v = Tile_d(n);
    uint f;
    materialOffset(v, f);
    vec2 spriteUnitOffset = mod(xy, 1.0);
    vec4 front = f == NOT_FOUND ? vec4(0) : tileColor(spriteUnitOffset, f);

    outputColor = backgroundPattern(xy);
    outputColor = blend(outputColor, front);

    if(int(xy.x) >= selection.x && int(xy.y) >= selection.y && int(xy.x) < selection.z && int(xy.y) < selection.w) {
        float pattern = cos((-spriteUnitOffset.x + spriteUnitOffset.y + t * 0.03) * 3.1415 * 6.0);
        outputColor = blend(outputColor, vec4(0.1, 0.5, 1.0, min(max(pattern * 0.1, 0.0) + 0.07, 0.1)));
    }
}