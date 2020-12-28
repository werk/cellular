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
uint random(inout uint seed, uint entropy, uint range) {
    seed ^= entropy;
    seed += (seed << 10u);
    seed ^= (seed >> 6u);
    seed += (seed << 3u);
    seed ^= (seed >> 11u);
    seed += (seed << 15u);
    return seed % range;
}

const uint Rock = 0u;
const uint Cave = 1u;
const uint Building = 2u;
const uint Empty = 3u;
const uint Left = 4u;
const uint Right = 5u;
const uint RockVein = 6u;
const uint IronVein = 7u;
const uint CoalVein = 8u;
const uint RockOre = 9u;
const uint IronOre = 10u;
const uint CoalOre = 11u;
const uint Ladder = 12u;
const uint Imp = 13u;
const uint Chest = 14u;

struct value {
    uint material;
    uint Tile;
    uint Light;
    uint Vein;
    uint Dig;
    uint Foreground;
    uint Background;
    uint BuildingVariant;
    uint Direction;
    uint Content;
    uint SmallContentCount;
};

const value ALL_NOT_FOUND = value(
    NOT_FOUND
,   NOT_FOUND
,   NOT_FOUND
,   NOT_FOUND
,   NOT_FOUND
,   NOT_FOUND
,   NOT_FOUND
,   NOT_FOUND
,   NOT_FOUND
,   NOT_FOUND
,   NOT_FOUND
);

uint Background_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Empty:
            n *= 2u;
            n += 0u;
            break;
        case Ladder:
            n *= 2u;
            n += 1u;
            break;
    }
    return n;
}

uint BuildingVariant_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Chest:
            n *= 3u;
            n += v.Content;
            n *= 11u;
            n += v.SmallContentCount;
            break;
    }
    return n;
}

uint Content_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case CoalOre:
            n *= 3u;
            n += 0u;
            break;
        case IronOre:
            n *= 3u;
            n += 1u;
            break;
        case RockOre:
            n *= 3u;
            n += 2u;
            break;
    }
    return n;
}

uint Direction_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Left:
            n *= 2u;
            n += 0u;
            break;
        case Right:
            n *= 2u;
            n += 1u;
            break;
    }
    return n;
}

uint Foreground_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case CoalOre:
            n *= 5u;
            n += 0u;
            break;
        case Empty:
            n *= 5u;
            n += 1u;
            break;
        case Imp:
            n *= 3u;
            n += v.Content;
            n *= 2u;
            n += v.Direction;
            n *= 5u;
            n += 2u;
            break;
        case IronOre:
            n *= 5u;
            n += 3u;
            break;
        case RockOre:
            n *= 5u;
            n += 4u;
            break;
    }
    return n;
}

uint Tile_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Building:
            n *= 33u;
            n += v.BuildingVariant;
            n *= 3u;
            n += 0u;
            break;
        case Cave:
            n *= 2u;
            n += v.Background;
            n *= 10u;
            n += v.Foreground;
            n *= 3u;
            n += 1u;
            break;
        case Rock:
            n *= 2u;
            n += v.Dig;
            n *= 6u;
            n += v.Light;
            n *= 3u;
            n += v.Vein;
            n *= 3u;
            n += 2u;
            break;
    }
    return n;
}

uint Vein_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case CoalVein:
            n *= 3u;
            n += 0u;
            break;
        case IronVein:
            n *= 3u;
            n += 1u;
            break;
        case RockVein:
            n *= 3u;
            n += 2u;
            break;
    }
    return n;
}

value Background_d(uint n) {
    value v = ALL_NOT_FOUND;
    uint m = n % 2u;
    n = n / 2u;
    switch(m) {
        case 0u:
            v.material = Empty;
            break;
        case 1u:
            v.material = Ladder;
            break;
    }
    return v;
}

value BuildingVariant_d(uint n) {
    value v = ALL_NOT_FOUND;
    uint m = n % 1u;
    n = n / 1u;
    switch(m) {
        case 0u:
            v.material = Chest;
            v.SmallContentCount = n % 11u;
            n = n / 11u;
            v.Content = n % 3u;
            n = n / 3u;
            break;
    }
    return v;
}

value Content_d(uint n) {
    value v = ALL_NOT_FOUND;
    uint m = n % 3u;
    n = n / 3u;
    switch(m) {
        case 0u:
            v.material = CoalOre;
            break;
        case 1u:
            v.material = IronOre;
            break;
        case 2u:
            v.material = RockOre;
            break;
    }
    return v;
}

value Direction_d(uint n) {
    value v = ALL_NOT_FOUND;
    uint m = n % 2u;
    n = n / 2u;
    switch(m) {
        case 0u:
            v.material = Left;
            break;
        case 1u:
            v.material = Right;
            break;
    }
    return v;
}

value Foreground_d(uint n) {
    value v = ALL_NOT_FOUND;
    uint m = n % 5u;
    n = n / 5u;
    switch(m) {
        case 0u:
            v.material = CoalOre;
            break;
        case 1u:
            v.material = Empty;
            break;
        case 2u:
            v.material = Imp;
            v.Direction = n % 2u;
            n = n / 2u;
            v.Content = n % 3u;
            n = n / 3u;
            break;
        case 3u:
            v.material = IronOre;
            break;
        case 4u:
            v.material = RockOre;
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
            v.material = Building;
            v.BuildingVariant = n % 33u;
            n = n / 33u;
            break;
        case 1u:
            v.material = Cave;
            v.Foreground = n % 10u;
            n = n / 10u;
            v.Background = n % 2u;
            n = n / 2u;
            break;
        case 2u:
            v.material = Rock;
            v.Vein = n % 3u;
            n = n / 3u;
            v.Light = n % 6u;
            n = n / 6u;
            v.Dig = n % 2u;
            n = n / 2u;
            break;
    }
    return v;
}

value Vein_d(uint n) {
    value v = ALL_NOT_FOUND;
    uint m = n % 3u;
    n = n / 3u;
    switch(m) {
        case 0u:
            v.material = CoalVein;
            break;
        case 1u:
            v.material = IronVein;
            break;
        case 2u:
            v.material = RockVein;
            break;
    }
    return v;
}

uint materialOffset(value v) {
    switch(v.material) {
        case Cave: return 0u;
        case Rock: return 6u;
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

    if(v.Light != NOT_FOUND) {
        outputColor = vec4((color * float(v.Light) * (1.0/5.0)).rgb, 1.0);
    } else {
        outputColor = color;
    }
    //outputColor = vec4(spriteOffset.x / stateSize.x, spriteOffset.y / stateSize.y, 1, 1);
}