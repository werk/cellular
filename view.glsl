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

const uint Air = 0u;
const uint Water = 1u;
const uint Stone = 2u;

struct value {
    uint material;
    uint Tile;
    uint Weight;
    uint Resource;
    uint Foreground;
};

const value ALL_NOT_FOUND = value(
    NOT_FOUND
,   NOT_FOUND
,   NOT_FOUND
,   NOT_FOUND
,   NOT_FOUND
);

uint Foreground_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Air:
            n *= 3u;
            n += 0u;
            break;
        case Stone:
            n *= 3u;
            n += 1u;
            break;
        case Water:
            n *= 3u;
            n += 2u;
            break;
    }
    return n;
}

uint Tile_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Air:
            n *= 3u;
            n += 0u;
            break;
        case Stone:
            n *= 3u;
            n += 1u;
            break;
        case Water:
            n *= 3u;
            n += 2u;
            break;
    }
    return n;
}

value Foreground_d(uint n) {
    value v = ALL_NOT_FOUND;
    uint m = n % 3u;
    n = n / 3u;
    switch(m) {
        case 0u:
            v.material = Air;
            v.Weight = 0u;
            break;
        case 1u:
            v.material = Stone;
            v.Weight = 2u;
            break;
        case 2u:
            v.material = Water;
            v.Weight = 1u;
            break;
    }
    return v;
}

value Tile_d(uint n) {
    value v = ALL_NOT_FOUND;
    uint m = n % 3u;
    n = n / 3u;
    switch(m) {
        case 0u:
            v.material = Air;
            v.Weight = 0u;
            break;
        case 1u:
            v.material = Stone;
            v.Weight = 2u;
            break;
        case 2u:
            v.material = Water;
            v.Weight = 1u;
            break;
    }
    return v;
}

uint materialOffset(value v) {
    switch(v.material) {
        case Air: return 0u;
        case Water: return 10u;
        case Stone: return 2u;
        default: return 255u;
    }
}

void main() {
    vec2 stateSize = vec2(100, 100);

    vec2 offset = vec2(0, 0);
    float zoom = 40.0;
    float screenToMapRatio = zoom / resolution.x;
    vec2 xy = gl_FragCoord.xy * screenToMapRatio + offset;

    uint n = texelFetch(state, ivec2(xy), 0).r;
    value v = Tile_d(n);
    uint o = materialOffset(v);

    vec2 spriteOffset = mod(xy + 0.5, 1.0) * tileSize;
    vec2 tileMapOffset = vec2(float(o) * tileSize, tileSize) + spriteOffset * vec2(1, -1);
    vec4 color = texture(materials, tileMapOffset / tileMapSize);

    outputColor = color;

    //outputColor = vec4(spriteOffset.x / stateSize.x, spriteOffset.y / stateSize.y, 1, 1);
}