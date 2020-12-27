#version 300 es
precision mediump float;
precision highp int;
uniform highp usampler2D state;
uniform int seedling;
uniform int step;
out uint outputValue;
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

const uint Air = 0u;
const uint Water = 1u;
const uint Stone = 2u;

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

value lookupTile(ivec2 offset) {
    uint n = texelFetch(state, offset, 0).r;
    return Tile_d(n);
}



bool fall_r(inout uint seed, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Weight == NOT_FOUND) return false;
    uint x_ = a_.Weight;

    value b_ = a2;
    if(b_.Weight == NOT_FOUND) return false;
    uint y_ = b_.Weight;

    value a1t;
    value a2t;

    bool v_1;
    v_1 = (x_ > y_);
    bool v_2 = v_1;
    if(!v_2) return false;
    a1t = b_;
    a2t = a_;

    a1 = a1t;
    a2 = a2t;
    return true;
}

void main() {
    ivec2 position = ivec2(gl_FragCoord.xy - 0.5);
    ivec2 offset = (step % 2 == 0) ? ivec2(1, 1) : ivec2(0, 0);
    ivec2 bottomLeft = (position + offset) / 2 * 2 - offset;

    value a1 = lookupTile(bottomLeft + ivec2(0, 1));
    value b1 = lookupTile(bottomLeft + ivec2(1, 1));
    value a2 = lookupTile(bottomLeft + ivec2(0, 0));
    value b2 = lookupTile(bottomLeft + ivec2(1, 0));

    uint seed = uint(seedling) ^ Tile_e(a1);
    random(seed, 612787635u, 1u);
    seed ^= uint(position.x);
    random(seed, 611757929u, 1u);
    seed ^= uint(position.y);
    random(seed, 999260970u, 1u);

    // fallGroup
    bool fallGroup_d = false;
    bool fall_d = false;
    if(true) {
        if(true) {
            fall_d = fall_r(seed, a1, a2) || fall_d;
            fall_d = fall_r(seed, b1, b2) || fall_d;
            fallGroup_d = fallGroup_d || fall_d;
        }
    }

    // Write and encode own value
    ivec2 quadrant = position - bottomLeft;
    value target = a2;
    if(quadrant == ivec2(0, 1)) target = a1;
    else if(quadrant == ivec2(1, 0)) target = b2;
    else if(quadrant == ivec2(1, 1)) target = b1;
    outputValue = Tile_e(target);

    if(step == 0) {
        value stone = ALL_NOT_FOUND;
        stone.material = Stone;

        value air = ALL_NOT_FOUND;
        air.material = Air;

        if(int(position.x + position.y) % 4 == 0) outputValue = Tile_e(stone);
        else outputValue = Tile_e(air);
    }

}