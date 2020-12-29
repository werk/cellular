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
const uint Up = 6u;
const uint Down = 7u;
const uint RockVein = 8u;
const uint IronVein = 9u;
const uint CoalVein = 10u;
const uint RockOre = 11u;
const uint IronOre = 12u;
const uint CoalOre = 13u;
const uint Scaffold = 14u;
const uint Imp = 15u;
const uint Chest = 16u;

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
            n *= 3u;
            n += v.Content;
            n *= 2u;
            n += v.DirectionH;
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
            n *= 5u;
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
    n = n / 2u;
    switch(m) {
        case 0u:
            v.material = Empty;
            break;
        case 1u:
            v.material = Scaffold;
            v.DirectionHV = n % 4u;
            n = n / 4u;
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

value DirectionH_d(uint n) {
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

value DirectionHV_d(uint n) {
    value v = ALL_NOT_FOUND;
    uint m = n % 4u;
    n = n / 4u;
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
            v.DirectionH = n % 2u;
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
            v.Background = n % 5u;
            n = n / 5u;
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

bool rotate_f(inout uint seed, uint transform, value direction_, out value result) {
    uint v_1;
    v_1 = transform;
    int m_2 = 0;
    switch(m_2) { case 0:
        uint v_3 = v_1;
        if(v_3 != 1u) break;
        value v_4;
        v_4 = direction_;
        int m_5 = 0;
        switch(m_5) { case 0:
            value v_6 = v_4;
            if(v_6.material != Left) break;
            result = ALL_NOT_FOUND;
            result.material = Right;
            m_5 = 1;
        default: break; }
        switch(m_5) { case 0:
            value v_7 = v_4;
            if(v_7.material != Right) break;
            result = ALL_NOT_FOUND;
            result.material = Left;
            m_5 = 1;
        default: break; }
        switch(m_5) { case 0:
            value v_8 = v_4;
            result = direction_;
            m_5 = 1;
        default: break; }
        if(m_5 == 0) return false;
        m_2 = 1;
    default: break; }
    switch(m_2) { case 0:
        uint v_9 = v_1;
        if(v_9 != 2u) break;
        value v_10;
        v_10 = direction_;
        int m_11 = 0;
        switch(m_11) { case 0:
            value v_12 = v_10;
            if(v_12.material != Up) break;
            result = ALL_NOT_FOUND;
            result.material = Down;
            m_11 = 1;
        default: break; }
        switch(m_11) { case 0:
            value v_13 = v_10;
            if(v_13.material != Down) break;
            result = ALL_NOT_FOUND;
            result.material = Up;
            m_11 = 1;
        default: break; }
        switch(m_11) { case 0:
            value v_14 = v_10;
            result = direction_;
            m_11 = 1;
        default: break; }
        if(m_11 == 0) return false;
        m_2 = 1;
    default: break; }
    switch(m_2) { case 0:
        uint v_15 = v_1;
        if(v_15 != 90u) break;
        value v_16;
        v_16 = direction_;
        int m_17 = 0;
        switch(m_17) { case 0:
            value v_18 = v_16;
            if(v_18.material != Left) break;
            result = ALL_NOT_FOUND;
            result.material = Down;
            m_17 = 1;
        default: break; }
        switch(m_17) { case 0:
            value v_19 = v_16;
            if(v_19.material != Right) break;
            result = ALL_NOT_FOUND;
            result.material = Up;
            m_17 = 1;
        default: break; }
        switch(m_17) { case 0:
            value v_20 = v_16;
            if(v_20.material != Up) break;
            result = ALL_NOT_FOUND;
            result.material = Left;
            m_17 = 1;
        default: break; }
        switch(m_17) { case 0:
            value v_21 = v_16;
            if(v_21.material != Down) break;
            result = ALL_NOT_FOUND;
            result.material = Right;
            m_17 = 1;
        default: break; }
        if(m_17 == 0) return false;
        m_2 = 1;
    default: break; }
    switch(m_2) { case 0:
        uint v_22 = v_1;
        if(v_22 != 180u) break;
        value v_23;
        v_23 = direction_;
        int m_24 = 0;
        switch(m_24) { case 0:
            value v_25 = v_23;
            if(v_25.material != Left) break;
            result = ALL_NOT_FOUND;
            result.material = Right;
            m_24 = 1;
        default: break; }
        switch(m_24) { case 0:
            value v_26 = v_23;
            if(v_26.material != Right) break;
            result = ALL_NOT_FOUND;
            result.material = Left;
            m_24 = 1;
        default: break; }
        switch(m_24) { case 0:
            value v_27 = v_23;
            if(v_27.material != Up) break;
            result = ALL_NOT_FOUND;
            result.material = Down;
            m_24 = 1;
        default: break; }
        switch(m_24) { case 0:
            value v_28 = v_23;
            if(v_28.material != Down) break;
            result = ALL_NOT_FOUND;
            result.material = Up;
            m_24 = 1;
        default: break; }
        if(m_24 == 0) return false;
        m_2 = 1;
    default: break; }
    switch(m_2) { case 0:
        uint v_29 = v_1;
        if(v_29 != 270u) break;
        value v_30;
        v_30 = direction_;
        int m_31 = 0;
        switch(m_31) { case 0:
            value v_32 = v_30;
            if(v_32.material != Left) break;
            result = ALL_NOT_FOUND;
            result.material = Up;
            m_31 = 1;
        default: break; }
        switch(m_31) { case 0:
            value v_33 = v_30;
            if(v_33.material != Right) break;
            result = ALL_NOT_FOUND;
            result.material = Down;
            m_31 = 1;
        default: break; }
        switch(m_31) { case 0:
            value v_34 = v_30;
            if(v_34.material != Up) break;
            result = ALL_NOT_FOUND;
            result.material = Right;
            m_31 = 1;
        default: break; }
        switch(m_31) { case 0:
            value v_35 = v_30;
            if(v_35.material != Down) break;
            result = ALL_NOT_FOUND;
            result.material = Left;
            m_31 = 1;
        default: break; }
        if(m_31 == 0) return false;
        m_2 = 1;
    default: break; }
    switch(m_2) { case 0:
        uint v_36 = v_1;
        result = direction_;
        m_2 = 1;
    default: break; }
    if(m_2 == 0) return false;
    return true;
}

bool rockLightBoundary_r(inout uint seed, uint transform, inout value a1, inout value a2) {
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

bool rockLight_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Light == NOT_FOUND || a_.material != Rock) return false;
    uint x_ = a_.Light;

    value b_ = a2;
    if(b_.Light == NOT_FOUND || b_.material != Rock) return false;
    uint y_ = b_.Light;
    
    value a1t;
    value a2t;
    
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
    a2t = b_;
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool impDig_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Dig == NOT_FOUND || a_.Vein == NOT_FOUND || a_.material != Rock) return false;
    uint v_1 = a_.Dig;
    if(v_1 != 1u) return false;
    value ore_ = Vein_d(a_.Vein);

    value b_ = a2;
    if(b_.Foreground == NOT_FOUND) return false;
    value i_ = Foreground_d(b_.Foreground);
    if(i_.Content == NOT_FOUND || i_.material != Imp) return false;
    value v_2 = Content_d(i_.Content);
    if(v_2.material != Empty) return false;
    
    value a1t;
    value a2t;
    
    a1t = ALL_NOT_FOUND;
    a1t.material = Cave;
    value v_3;
    v_3 = i_;
    value v_4;
    v_4 = ore_;
    v_3.Content = Content_e(v_4);
    a1t.Foreground = Foreground_e(v_3);
    value v_5;
    v_5 = ALL_NOT_FOUND;
    v_5.material = Scaffold;
    value v_6;
    value v_7 = ALL_NOT_FOUND;
    v_7.material = Up;
    if(!rotate_f(seed, transform, v_7, v_6)) return false;
    v_5.DirectionHV = DirectionHV_e(v_6);
    a1t.Background = Background_e(v_5);
    a2t = b_;
    value v_8;
    v_8 = ALL_NOT_FOUND;
    v_8.material = Empty;
    a2t.Foreground = Foreground_e(v_8);
    
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
            rockLightBoundary_d = rockLightBoundary_r(seed, 0u, a1, a2) || rockLightBoundary_d;
            seed ^= 1869972635u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 0u, b1, b2) || rockLightBoundary_d;
            seed ^= 871070164u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 90u, a1, b1) || rockLightBoundary_d;
            seed ^= 223888653u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 90u, a2, b2) || rockLightBoundary_d;
            seed ^= 1967264300u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 180u, a2, a1) || rockLightBoundary_d;
            seed ^= 1956845781u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 180u, b2, b1) || rockLightBoundary_d;
            seed ^= 2125574876u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 270u, b1, a1) || rockLightBoundary_d;
            seed ^= 1273636163u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 270u, b2, a2) || rockLightBoundary_d;
            rockLightGroup_d = rockLightGroup_d || rockLightBoundary_d;
        }
        if(true) {
            seed ^= 108567334u;
            rockLight_d = rockLight_r(seed, 0u, a1, a2) || rockLight_d;
            seed ^= 1869972635u;
            rockLight_d = rockLight_r(seed, 0u, b1, b2) || rockLight_d;
            seed ^= 871070164u;
            rockLight_d = rockLight_r(seed, 90u, a1, b1) || rockLight_d;
            seed ^= 223888653u;
            rockLight_d = rockLight_r(seed, 90u, a2, b2) || rockLight_d;
            seed ^= 1967264300u;
            rockLight_d = rockLight_r(seed, 180u, a2, a1) || rockLight_d;
            seed ^= 1956845781u;
            rockLight_d = rockLight_r(seed, 180u, b2, b1) || rockLight_d;
            seed ^= 2125574876u;
            rockLight_d = rockLight_r(seed, 270u, b1, a1) || rockLight_d;
            seed ^= 1273636163u;
            rockLight_d = rockLight_r(seed, 270u, b2, a2) || rockLight_d;
            rockLightGroup_d = rockLightGroup_d || rockLight_d;
        }
    }

    // impDigGroup
    bool impDigGroup_d = false;
    bool impDig_d = false;
    if(true) {
        if(true) {
            seed ^= 1998101111u;
            impDig_d = impDig_r(seed, 0u, a1, a2) || impDig_d;
            seed ^= 1863429485u;
            impDig_d = impDig_r(seed, 0u, b1, b2) || impDig_d;
            seed ^= 512539514u;
            impDig_d = impDig_r(seed, 90u, a1, b1) || impDig_d;
            seed ^= 909067310u;
            impDig_d = impDig_r(seed, 90u, a2, b2) || impDig_d;
            seed ^= 1483200932u;
            impDig_d = impDig_r(seed, 180u, a2, a1) || impDig_d;
            seed ^= 768441705u;
            impDig_d = impDig_r(seed, 180u, b2, b1) || impDig_d;
            seed ^= 1076533857u;
            impDig_d = impDig_r(seed, 270u, b1, a1) || impDig_d;
            seed ^= 1128456650u;
            impDig_d = impDig_r(seed, 270u, b2, a2) || impDig_d;
            impDigGroup_d = impDigGroup_d || impDig_d;
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