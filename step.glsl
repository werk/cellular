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

// There are 88 different tiles

const uint Rock = 0u;
const uint Cave = 1u;
const uint Building = 2u;
const uint Empty = 3u;
const uint Left = 4u;
const uint Right = 5u;
const uint Up = 6u;
const uint Down = 7u;
const uint RockOre = 8u;
const uint IronOre = 9u;
const uint CoalOre = 10u;
const uint Scaffold = 11u;
const uint Imp = 12u;
const uint Chest = 13u;

struct value {
    uint material;
    uint Tile;
    uint Light;
    uint Vein;
    uint Dig;
    uint Foreground;
    uint Background;
    uint BuildingVariant;
    uint DirectionH;
    uint DirectionHV;
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
,   NOT_FOUND
);

uint Background_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Empty:
            n *= 2u;
            n += 0u;
            break;
        case Scaffold:
            n *= 4u;
            n += v.DirectionHV;
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
            n *= 4u;
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
            n *= 4u;
            n += 0u;
            break;
        case Empty:
            n *= 4u;
            n += 1u;
            break;
        case IronOre:
            n *= 4u;
            n += 2u;
            break;
        case RockOre:
            n *= 4u;
            n += 3u;
            break;
    }
    return n;
}

uint DirectionH_e(value v) {
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

uint DirectionHV_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Down:
            n *= 4u;
            n += 0u;
            break;
        case Left:
            n *= 4u;
            n += 1u;
            break;
        case Right:
            n *= 4u;
            n += 2u;
            break;
        case Up:
            n *= 4u;
            n += 3u;
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
            n *= 4u;
            n += v.Content;
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
            n *= 44u;
            n += v.BuildingVariant;
            n *= 3u;
            n += 0u;
            break;
        case Cave:
            n *= 8u;
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

value Background_d(uint n) {
    value v = ALL_NOT_FOUND;
    uint m = n % 2u;
    n /= 2u;
    switch(m) {
        case 0u:
            v.material = Empty;
            break;
        case 1u:
            v.material = Scaffold;
            v.DirectionHV = n % 4u;
            n /= 4u;
            break;
    }
    return v;
}

value BuildingVariant_d(uint n) {
    value v = ALL_NOT_FOUND;
    uint m = n % 1u;
    n /= 1u;
    switch(m) {
        case 0u:
            v.material = Chest;
            v.SmallContentCount = n % 11u;
            n /= 11u;
            v.Content = n % 4u;
            n /= 4u;
            break;
    }
    return v;
}

value Content_d(uint n) {
    value v = ALL_NOT_FOUND;
    uint m = n % 4u;
    n /= 4u;
    switch(m) {
        case 0u:
            v.material = CoalOre;
            break;
        case 1u:
            v.material = Empty;
            break;
        case 2u:
            v.material = IronOre;
            break;
        case 3u:
            v.material = RockOre;
            break;
    }
    return v;
}

value DirectionH_d(uint n) {
    value v = ALL_NOT_FOUND;
    uint m = n % 2u;
    n /= 2u;
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

value DirectionHV_d(uint n) {
    value v = ALL_NOT_FOUND;
    uint m = n % 4u;
    n /= 4u;
    switch(m) {
        case 0u:
            v.material = Down;
            break;
        case 1u:
            v.material = Left;
            break;
        case 2u:
            v.material = Right;
            break;
        case 3u:
            v.material = Up;
            break;
    }
    return v;
}

value Foreground_d(uint n) {
    value v = ALL_NOT_FOUND;
    uint m = n % 5u;
    n /= 5u;
    switch(m) {
        case 0u:
            v.material = CoalOre;
            break;
        case 1u:
            v.material = Empty;
            break;
        case 2u:
            v.material = Imp;
            v.Content = n % 4u;
            n /= 4u;
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
    n /= 3u;
    switch(m) {
        case 0u:
            v.material = Building;
            v.BuildingVariant = n % 44u;
            n /= 44u;
            break;
        case 1u:
            v.material = Cave;
            v.Foreground = n % 8u;
            n /= 8u;
            break;
        case 2u:
            v.material = Rock;
            v.Vein = n % 3u;
            n /= 3u;
            v.Light = n % 6u;
            n /= 6u;
            v.Dig = n % 2u;
            n /= 2u;
            break;
    }
    return v;
}

value Vein_d(uint n) {
    value v = ALL_NOT_FOUND;
    uint m = n % 3u;
    n /= 3u;
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

value lookupTile(ivec2 offset) {
    uint n = texelFetch(state, offset, 0).r;
    return Tile_d(n);
}



bool generateImp1_r(inout uint seed, uint transform, inout value a1) {
    value v_1 = a1;
    
    value a1t;
    
    a1t = ALL_NOT_FOUND;
    a1t.material = Cave;
    value v_2;
    v_2 = ALL_NOT_FOUND;
    v_2.material = Imp;
    value v_3;
    v_3 = ALL_NOT_FOUND;
    v_3.material = IronOre;
    v_2.Content = Content_e(v_3);
    a1t.Foreground = Foreground_e(v_2);
    
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
    bool generateImp1_d = false;
    if(true) {
        if(true) {
            seed ^= 108567334u;
            generateImp1_d = generateImp1_r(seed, 0u, a1) || generateImp1_d;
            seed ^= 1869972635u;
            generateImp1_d = generateImp1_r(seed, 0u, a2) || generateImp1_d;
            seed ^= 871070164u;
            generateImp1_d = generateImp1_r(seed, 0u, b1) || generateImp1_d;
            seed ^= 223888653u;
            generateImp1_d = generateImp1_r(seed, 0u, b2) || generateImp1_d;
            generateGroup_d = generateGroup_d || generateImp1_d;
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