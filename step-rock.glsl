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

// BEGIN COMMON

// There are 1 different tiles

const uint Rock = 0u;

struct value {
    uint material;
    uint Tile;
};

const value ALL_NOT_FOUND = value(
    NOT_FOUND
,   NOT_FOUND
);

uint Tile_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Rock:
            break;
    }
    return n;
}

value Tile_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 1u) {
        v.material = Rock;
        return v;
    }
    n -= 1u;
    return v;
}

// END COMMON

value lookupTile(ivec2 offset) {
    ivec2 stateSize = ivec2(100, 100);
    if(offset.x < 0) offset.x += stateSize.x;
    if(offset.y < 0) offset.y += stateSize.y;
    if(offset.x >= stateSize.x) offset.x -= stateSize.x;
    if(offset.y >= stateSize.y) offset.y -= stateSize.y;
    uint n = texelFetch(state, offset, 0).r;
    return Tile_d(n);
}



bool generateRock_r(inout uint seed, uint transform, inout value a1) {
    value v_1 = a1;
    
    value a1t;
    
    a1t = ALL_NOT_FOUND;
    a1t.material = Rock;
    
    a1 = a1t;
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
    random(seed, 712387635u, 1u);
    seed ^= uint(position.x);
    random(seed, 611757929u, 1u);
    seed ^= uint(position.y);
    random(seed, 999260970u, 1u);

    // generateGroup
    bool generateGroup_d = false;
    bool generateRock_d = false;
    if(true) {
        if(true) {
            seed ^= 108567334u;
            generateRock_d = generateRock_r(seed, 0u, a1) || generateRock_d;
            seed ^= 1869972635u;
            generateRock_d = generateRock_r(seed, 0u, b1) || generateRock_d;
            seed ^= 871070164u;
            generateRock_d = generateRock_r(seed, 0u, a2) || generateRock_d;
            seed ^= 223888653u;
            generateRock_d = generateRock_r(seed, 0u, b2) || generateRock_d;
            generateGroup_d = generateGroup_d || generateRock_d;
        }
    }

    // Write and encode own value
    ivec2 quadrant = position - bottomLeft;
    value target = a2;
    if(quadrant == ivec2(0, 1)) target = a1;
    else if(quadrant == ivec2(1, 0)) target = b2;
    else if(quadrant == ivec2(1, 1)) target = b1;
    outputValue = Tile_e(target);

}