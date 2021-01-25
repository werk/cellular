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

// There are 3 different tiles

const uint Rock = 0u;
const uint Sand = 1u;
const uint Water = 2u;

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
        case Sand:
            n += 1u;
            break;
        case Water:
            n += 1u + 1u;
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
    if(n < 1u) {
        v.material = Sand;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Water;
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
    
    bool v_2;
    uint v_3;
    v_3 = uint(step);
    v_2 = (v_3 == 0u);
    bool v_4 = v_2;
    if(!v_4) return false;
    a1t = ALL_NOT_FOUND;
    a1t.material = Rock;
    
    a1 = a1t;
    return true;
}

bool generateSand_r(inout uint seed, uint transform, inout value a1) {
    value v_1 = a1;
    
    value a1t;
    
    bool v_2;
    bool v_3;
    bool v_5;
    bool v_7;
    bool v_9;
    uint v_11;
    v_11 = uint(step);
    v_9 = (v_11 == 0u);
    bool v_10;
    uint v_12;
    v_12 = uint(gl_FragCoord.x - 0.5);
    v_10 = (v_12 > 5u);
    v_7 = (v_9 && v_10);
    bool v_8;
    uint v_13;
    v_13 = uint(gl_FragCoord.x - 0.5);
    v_8 = (v_13 < 15u);
    v_5 = (v_7 && v_8);
    bool v_6;
    uint v_14;
    v_14 = uint(gl_FragCoord.y - 0.5);
    v_6 = (v_14 > 5u);
    v_3 = (v_5 && v_6);
    bool v_4;
    uint v_15;
    v_15 = uint(gl_FragCoord.y - 0.5);
    v_4 = (v_15 < 15u);
    v_2 = (v_3 && v_4);
    bool v_16 = v_2;
    if(!v_16) return false;
    a1t = ALL_NOT_FOUND;
    a1t.material = Sand;
    
    a1 = a1t;
    return true;
}

bool generateWater_r(inout uint seed, uint transform, inout value a1) {
    value v_1 = a1;
    
    value a1t;
    
    bool v_2;
    bool v_3;
    uint v_5;
    v_5 = uint(step);
    v_3 = (v_5 == 0u);
    bool v_4;
    uint v_6;
    v_6 = uint(gl_FragCoord.y - 0.5);
    v_4 = (v_6 < 3u);
    v_2 = (v_3 && v_4);
    bool v_7 = v_2;
    if(!v_7) return false;
    a1t = ALL_NOT_FOUND;
    a1t.material = Water;
    
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
    bool generateSand_d = false;
    bool generateWater_d = false;
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
        if(true) {
            seed ^= 108567334u;
            generateSand_d = generateSand_r(seed, 0u, a1) || generateSand_d;
            seed ^= 1869972635u;
            generateSand_d = generateSand_r(seed, 0u, b1) || generateSand_d;
            seed ^= 871070164u;
            generateSand_d = generateSand_r(seed, 0u, a2) || generateSand_d;
            seed ^= 223888653u;
            generateSand_d = generateSand_r(seed, 0u, b2) || generateSand_d;
            generateGroup_d = generateGroup_d || generateSand_d;
        }
        if(true) {
            seed ^= 108567334u;
            generateWater_d = generateWater_r(seed, 0u, a1) || generateWater_d;
            seed ^= 1869972635u;
            generateWater_d = generateWater_r(seed, 0u, b1) || generateWater_d;
            seed ^= 871070164u;
            generateWater_d = generateWater_r(seed, 0u, a2) || generateWater_d;
            seed ^= 223888653u;
            generateWater_d = generateWater_r(seed, 0u, b2) || generateWater_d;
            generateGroup_d = generateGroup_d || generateWater_d;
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