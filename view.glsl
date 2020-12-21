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
const uint Tile = 3u;

const uint SIZE_material = 4u;

const uint SIZE_Weight = 4u;
const uint SIZE_Resource = 1u;
const uint SIZE_Foreground = 3u;

struct value {
    uint material;
    uint Weight;
    uint Resource;
    uint Foreground;
};

const value ALL_NOT_FOUND = value(
    NOT_FOUND,
    NOT_FOUND,
    NOT_FOUND,
    NOT_FOUND
);

const value FIXED_Foreground = ALL_NOT_FOUND;

uint encode(value i, value fix) {
    uint result = 0u;
    switch(i.material) {
        case Tile:
            if(fix.Foreground == NOT_FOUND) {
                result *= SIZE_Foreground;
                result += i.Foreground;
            }
            break;
        default:
            break;
    }
    result *= SIZE_material;
    result += i.material;
    return result;
}

value decode(uint number, value fix) {
    value o = ALL_NOT_FOUND;
    o.material = number % SIZE_material;
    uint remaining = number / SIZE_material;
    switch(o.material) {
        case Air:
            o.Weight = 0u;
            break;
        case Water:
            o.Weight = 1u;
            break;
        case Stone:
            o.Weight = 2u;
            break;
        case Tile:
            if(fix.Foreground == NOT_FOUND) {
                o.Foreground = remaining % SIZE_Foreground;
                remaining /= SIZE_Foreground;
            } else {
                o.Foreground = fix.Foreground;
            }
            break;
        default:
            break;
    }
    return o;
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
    vec2 tile = floor(xy + 0.5);
    vec2 spriteOffset = mod(xy + 0.5, 1.0) * tileSize;

    uint integer = texture(state, tile / stateSize).r;
    value material = decode(integer, ALL_NOT_FOUND);
    value foreground = decode(material.Foreground, ALL_NOT_FOUND);
    uint o = materialOffset(foreground);

    vec2 tileMapOffset = vec2(float(o) * tileSize, tileSize) + spriteOffset * vec2(1, -1);
    vec4 color = texture(materials, tileMapOffset / tileMapSize);

    outputColor = color;
}