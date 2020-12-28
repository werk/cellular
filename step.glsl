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

value lookupTile(ivec2 offset) {
    uint n = texelFetch(state, offset, 0).r;
    return Tile_d(n);
}



bool rockLightBoundary_r(inout uint seed, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.material != Rock) return false;

    value b_ = a2;
    
    value a1t;
    value a2t;
    
    uint v_1;
    value v_2;
    v_2 = b_;
    int m_3 = 0;
    switch(m_3) { case 0:
        value v_4 = v_2;
        if(v_4.material != Rock) break;
        v_1 = 0u;
        m_3 = 1;
    default: break; }
    switch(m_3) { case 0:
        value v_5 = v_2;
        v_1 = 1u;
        m_3 = 1;
    default: break; }
    if(m_3 == 0) return false;
    uint v_6 = v_1;
    if(v_6 != 1u) return false;
    a1t = a_;
    uint v_7;
    v_7 = 5u;
    if(v_7 >= 6u) return false;
    a1t.Light = v_7;
    a2t = b_;
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool rockLight_r(inout uint seed, inout value a1, inout value b1) {
    value a_ = a1;
    if(a_.Light == NOT_FOUND || a_.material != Rock) return false;
    uint x_ = a_.Light;

    value b_ = b1;
    if(b_.Light == NOT_FOUND || b_.material != Rock) return false;
    uint y_ = b_.Light;
    
    value a1t;
    value b1t;
    
    bool v_1;
    uint v_2 = (x_ + 1u);
    v_1 = (v_2 < y_);
    bool v_3 = v_1;
    if(!v_3) return false;
    a1t = a_;
    uint v_4;
    v_4 = (x_ + 1u);
    if(v_4 >= 6u) return false;
    a1t.Light = v_4;
    b1t = b_;
    
    a1 = a1t;
    b1 = b1t;
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

    // rockLightGroup
    bool rockLightGroup_d = false;
    bool rockLightBoundary_d = false;
    bool rockLight_d = false;
    if(true) {
        if(true) {
            seed ^= 108567334u;
            rockLightBoundary_d = rockLightBoundary_r(seed, a1, a2) || rockLightBoundary_d;
            seed ^= 1869972635u;
            rockLightBoundary_d = rockLightBoundary_r(seed, b1, b2) || rockLightBoundary_d;
            seed ^= 871070164u;
            rockLightBoundary_d = rockLightBoundary_r(seed, a1, b1) || rockLightBoundary_d;
            seed ^= 223888653u;
            rockLightBoundary_d = rockLightBoundary_r(seed, a2, b2) || rockLightBoundary_d;
            seed ^= 1967264300u;
            rockLightBoundary_d = rockLightBoundary_r(seed, a1, a2) || rockLightBoundary_d;
            seed ^= 1956845781u;
            rockLightBoundary_d = rockLightBoundary_r(seed, b1, b2) || rockLightBoundary_d;
            seed ^= 2125574876u;
            rockLightBoundary_d = rockLightBoundary_r(seed, a1, b1) || rockLightBoundary_d;
            seed ^= 1273636163u;
            rockLightBoundary_d = rockLightBoundary_r(seed, a2, b2) || rockLightBoundary_d;
            rockLightGroup_d = rockLightGroup_d || rockLightBoundary_d;
        }
        if(true) {
            seed ^= 108567334u;
            rockLight_d = rockLight_r(seed, a1, b1) || rockLight_d;
            seed ^= 1869972635u;
            rockLight_d = rockLight_r(seed, a2, b2) || rockLight_d;
            seed ^= 871070164u;
            rockLight_d = rockLight_r(seed, a1, a2) || rockLight_d;
            seed ^= 223888653u;
            rockLight_d = rockLight_r(seed, b1, b2) || rockLight_d;
            seed ^= 1967264300u;
            rockLight_d = rockLight_r(seed, a1, b1) || rockLight_d;
            seed ^= 1956845781u;
            rockLight_d = rockLight_r(seed, a2, b2) || rockLight_d;
            seed ^= 2125574876u;
            rockLight_d = rockLight_r(seed, a1, a2) || rockLight_d;
            seed ^= 1273636163u;
            rockLight_d = rockLight_r(seed, b1, b2) || rockLight_d;
            rockLightGroup_d = rockLightGroup_d || rockLight_d;
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
        value rock = ALL_NOT_FOUND;
        rock.material = Rock;
        rock.Light = rock.Vein = rock.Dig = 0u;

        value cave = ALL_NOT_FOUND;
        cave.material = Cave;
        cave.Foreground = cave.Background = 0u;

        if(position.x > 5 && position.x < 15 && position.y > 5 && position.y < 15) outputValue = Tile_e(cave);
        else outputValue = Tile_e(rock);
    }

}