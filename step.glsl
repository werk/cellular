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

// There are 808 different tiles

const uint Rock = 0u;
const uint Shaft = 1u;
const uint Cave = 2u;
const uint Building = 3u;
const uint ShaftImp = 4u;
const uint None = 5u;
const uint Left = 6u;
const uint Right = 7u;
const uint Up = 8u;
const uint Down = 9u;
const uint RockOre = 10u;
const uint IronOre = 11u;
const uint CoalOre = 12u;
const uint Imp = 13u;
const uint SmallChest = 14u;
const uint BigChest = 15u;
const uint Ladder = 16u;
const uint Sign = 17u;

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
    uint DirectionV;
    uint DirectionHV;
    uint ImpClimb;
    uint ImpStep;
    uint Content;
    uint SmallContentCount;
    uint BigContentCount;
    uint ShaftForeground;
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
,   NOT_FOUND
,   NOT_FOUND
,   NOT_FOUND
,   NOT_FOUND
,   NOT_FOUND
);

uint Background_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Ladder:
            break;
        case None:
            n += 1u;
            break;
        case Sign:
            n *= 2u;
            n += v.DirectionV;
            n += 1u + 1u;
            break;
    }
    return n;
}

uint BuildingVariant_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case BigChest:
            n *= 101u;
            n += v.BigContentCount;
            n *= 4u;
            n += v.Content;
            break;
        case SmallChest:
            n *= 4u;
            n += v.Content;
            n *= 11u;
            n += v.SmallContentCount;
            n += 404u;
            break;
    }
    return n;
}

uint Content_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case CoalOre:
            break;
        case IronOre:
            n += 1u;
            break;
        case None:
            n += 1u + 1u;
            break;
        case RockOre:
            n += 1u + 1u + 1u;
            break;
    }
    return n;
}

uint DirectionH_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Left:
            break;
        case Right:
            n += 1u;
            break;
    }
    return n;
}

uint DirectionHV_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Down:
            break;
        case Left:
            n += 1u;
            break;
        case Right:
            n += 1u + 1u;
            break;
        case Up:
            n += 1u + 1u + 1u;
            break;
    }
    return n;
}

uint DirectionV_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Down:
            break;
        case Up:
            n += 1u;
            break;
    }
    return n;
}

uint Foreground_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case CoalOre:
            break;
        case Imp:
            n *= 4u;
            n += v.Content;
            n *= 2u;
            n += v.DirectionH;
            n *= 3u;
            n += v.ImpClimb;
            n *= 3u;
            n += v.ImpStep;
            n += 1u;
            break;
        case IronOre:
            n += 1u + 72u;
            break;
        case None:
            n += 1u + 72u + 1u;
            break;
        case RockOre:
            n += 1u + 72u + 1u + 1u;
            break;
    }
    return n;
}

uint ImpClimb_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Down:
            break;
        case None:
            n += 1u;
            break;
        case Up:
            n += 1u + 1u;
            break;
    }
    return n;
}

uint ShaftForeground_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case None:
            break;
        case ShaftImp:
            n *= 4u;
            n += v.Content;
            n += 1u;
            break;
    }
    return n;
}

uint Tile_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Building:
            n *= 448u;
            n += v.BuildingVariant;
            break;
        case Cave:
            n *= 4u;
            n += v.Background;
            n *= 76u;
            n += v.Foreground;
            n += 448u;
            break;
        case Rock:
            n *= 2u;
            n += v.Dig;
            n *= 6u;
            n += v.Light;
            n *= 3u;
            n += v.Vein;
            n += 448u + 304u;
            break;
        case Shaft:
            n *= 4u;
            n += v.DirectionHV;
            n *= 5u;
            n += v.ShaftForeground;
            n += 448u + 304u + 36u;
            break;
    }
    return n;
}

uint Vein_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case CoalOre:
            break;
        case IronOre:
            n += 1u;
            break;
        case RockOre:
            n += 1u + 1u;
            break;
    }
    return n;
}

value Background_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 1u) {
        v.material = Ladder;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = None;
        return v;
    }
    n -= 1u;
    if(n < 2u) {
        v.material = Sign;
        v.DirectionV = n % 2u;
        n /= 2u;
        return v;
    }
    n -= 2u;
    return v;
}

value BuildingVariant_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 404u) {
        v.material = BigChest;
        v.Content = n % 4u;
        n /= 4u;
        v.BigContentCount = n % 101u;
        n /= 101u;
        return v;
    }
    n -= 404u;
    if(n < 44u) {
        v.material = SmallChest;
        v.SmallContentCount = n % 11u;
        n /= 11u;
        v.Content = n % 4u;
        n /= 4u;
        return v;
    }
    n -= 44u;
    return v;
}

value Content_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 1u) {
        v.material = CoalOre;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = IronOre;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = None;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = RockOre;
        return v;
    }
    n -= 1u;
    return v;
}

value DirectionH_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 1u) {
        v.material = Left;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Right;
        return v;
    }
    n -= 1u;
    return v;
}

value DirectionHV_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 1u) {
        v.material = Down;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Left;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Right;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Up;
        return v;
    }
    n -= 1u;
    return v;
}

value DirectionV_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 1u) {
        v.material = Down;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Up;
        return v;
    }
    n -= 1u;
    return v;
}

value Foreground_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 1u) {
        v.material = CoalOre;
        return v;
    }
    n -= 1u;
    if(n < 72u) {
        v.material = Imp;
        v.ImpStep = n % 3u;
        n /= 3u;
        v.ImpClimb = n % 3u;
        n /= 3u;
        v.DirectionH = n % 2u;
        n /= 2u;
        v.Content = n % 4u;
        n /= 4u;
        return v;
    }
    n -= 72u;
    if(n < 1u) {
        v.material = IronOre;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = None;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = RockOre;
        return v;
    }
    n -= 1u;
    return v;
}

value ImpClimb_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 1u) {
        v.material = Down;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = None;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Up;
        return v;
    }
    n -= 1u;
    return v;
}

value ShaftForeground_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 1u) {
        v.material = None;
        return v;
    }
    n -= 1u;
    if(n < 4u) {
        v.material = ShaftImp;
        v.Content = n % 4u;
        n /= 4u;
        return v;
    }
    n -= 4u;
    return v;
}

value Tile_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 448u) {
        v.material = Building;
        v.BuildingVariant = n % 448u;
        n /= 448u;
        return v;
    }
    n -= 448u;
    if(n < 304u) {
        v.material = Cave;
        v.Foreground = n % 76u;
        n /= 76u;
        v.Background = n % 4u;
        n /= 4u;
        return v;
    }
    n -= 304u;
    if(n < 36u) {
        v.material = Rock;
        v.Vein = n % 3u;
        n /= 3u;
        v.Light = n % 6u;
        n /= 6u;
        v.Dig = n % 2u;
        n /= 2u;
        return v;
    }
    n -= 36u;
    if(n < 20u) {
        v.material = Shaft;
        v.ShaftForeground = n % 5u;
        n /= 5u;
        v.DirectionHV = n % 4u;
        n /= 4u;
        return v;
    }
    n -= 20u;
    return v;
}

value Vein_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 1u) {
        v.material = CoalOre;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = IronOre;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = RockOre;
        return v;
    }
    n -= 1u;
    return v;
}

// END COMMON

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

bool walkable_f(inout uint seed, uint transform, value tile_, out bool result) {
    uint v_1;
    value v_2;
    v_2 = tile_;
    int m_3 = 0;
    switch(m_3) { case 0:
        value v_4 = v_2;
        if(v_4.material != Rock) break;
        v_1 = 1u;
        m_3 = 1;
    default: break; }
    switch(m_3) { case 0:
        value v_5 = v_2;
        if(v_5.Background == NOT_FOUND) break;
        value v_6 = Background_d(v_5.Background);
        if(v_6.material != Ladder) break;
        v_1 = 1u;
        m_3 = 1;
    default: break; }
    switch(m_3) { case 0:
        value v_7 = v_2;
        v_1 = 0u;
        m_3 = 1;
    default: break; }
    if(m_3 == 0) return false;
    result = (v_1 == 1u);
    return true;
}

bool generateCave_r(inout uint seed, uint transform, inout value a1) {
    value v_1 = a1;
    
    value a1t;
    
    bool v_2;
    uint v_3;
    v_3 = uint(step);
    v_2 = (v_3 == 0u);
    bool v_4 = v_2;
    if(!v_4) return false;
    bool v_5;
    bool v_6;
    bool v_8;
    bool v_10;
    uint v_12;
    v_12 = uint(gl_FragCoord.x - 0.5);
    v_10 = (v_12 > 5u);
    bool v_11;
    uint v_13;
    v_13 = uint(gl_FragCoord.x - 0.5);
    v_11 = (v_13 < 15u);
    v_8 = (v_10 && v_11);
    bool v_9;
    uint v_14;
    v_14 = uint(gl_FragCoord.y - 0.5);
    v_9 = (v_14 > 5u);
    v_6 = (v_8 && v_9);
    bool v_7;
    uint v_15;
    v_15 = uint(gl_FragCoord.y - 0.5);
    v_7 = (v_15 < 15u);
    v_5 = (v_6 && v_7);
    if(v_5) {
    a1t = ALL_NOT_FOUND;
    a1t.material = Cave;
    value v_16;
    v_16 = ALL_NOT_FOUND;
    v_16.material = None;
    a1t.Foreground = Foreground_e(v_16);
    value v_17;
    v_17 = ALL_NOT_FOUND;
    v_17.material = None;
    a1t.Background = Background_e(v_17);
    } else {
    a1t = ALL_NOT_FOUND;
    a1t.material = Rock;
    uint v_18;
    v_18 = 0u;
    if(v_18 >= 6u) return false;
    a1t.Light = v_18;
    value v_19;
    v_19 = ALL_NOT_FOUND;
    v_19.material = RockOre;
    a1t.Vein = Vein_e(v_19);
    uint v_20;
    v_20 = 0u;
    if(v_20 >= 2u) return false;
    a1t.Dig = v_20;
    }
    
    a1 = a1t;
    return true;
}

bool generateDig_r(inout uint seed, uint transform, inout value a1) {
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
    v_10 = (v_12 >= 15u);
    v_7 = (v_9 && v_10);
    bool v_8;
    uint v_13;
    v_13 = uint(gl_FragCoord.x - 0.5);
    v_8 = (v_13 < 25u);
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
    a1t.material = Rock;
    uint v_17;
    v_17 = 0u;
    if(v_17 >= 6u) return false;
    a1t.Light = v_17;
    value v_18;
    v_18 = ALL_NOT_FOUND;
    v_18.material = RockOre;
    a1t.Vein = Vein_e(v_18);
    uint v_19;
    v_19 = 1u;
    if(v_19 >= 2u) return false;
    a1t.Dig = v_19;
    
    a1 = a1t;
    return true;
}

bool generateChest_r(inout uint seed, uint transform, inout value a1) {
    value v_1 = a1;
    
    value a1t;
    
    bool v_2;
    bool v_3;
    bool v_5;
    uint v_7;
    v_7 = uint(step);
    v_5 = (v_7 == 0u);
    bool v_6;
    uint v_8;
    v_8 = uint(gl_FragCoord.x - 0.5);
    v_6 = (v_8 == 6u);
    v_3 = (v_5 && v_6);
    bool v_4;
    uint v_9;
    v_9 = uint(gl_FragCoord.y - 0.5);
    v_4 = (v_9 == 7u);
    v_2 = (v_3 && v_4);
    bool v_10 = v_2;
    if(!v_10) return false;
    a1t = ALL_NOT_FOUND;
    a1t.material = Building;
    value v_11;
    v_11 = ALL_NOT_FOUND;
    v_11.material = BigChest;
    value v_12;
    v_12 = ALL_NOT_FOUND;
    v_12.material = RockOre;
    v_11.Content = Content_e(v_12);
    uint v_13;
    v_13 = 0u;
    if(v_13 >= 101u) return false;
    v_11.BigContentCount = v_13;
    a1t.BuildingVariant = BuildingVariant_e(v_11);
    
    a1 = a1t;
    return true;
}

bool generateImps_r(inout uint seed, uint transform, inout value a1) {
    value v_1 = a1;
    
    value a1t;
    
    bool v_2;
    uint v_3;
    v_3 = uint(step);
    v_2 = (v_3 == 0u);
    bool v_4 = v_2;
    if(!v_4) return false;
    bool v_5;
    bool v_6;
    bool v_8;
    bool v_10;
    bool v_12;
    bool v_14;
    uint v_16;
    v_16 = uint(gl_FragCoord.x - 0.5);
    v_14 = (v_16 == 8u);
    bool v_15;
    uint v_17;
    v_17 = uint(gl_FragCoord.y - 0.5);
    v_15 = (v_17 == 6u);
    v_12 = (v_14 && v_15);
    bool v_13;
    bool v_18;
    uint v_20;
    v_20 = uint(gl_FragCoord.x - 0.5);
    v_18 = (v_20 == 9u);
    bool v_19;
    uint v_21;
    v_21 = uint(gl_FragCoord.y - 0.5);
    v_19 = (v_21 == 7u);
    v_13 = (v_18 && v_19);
    v_10 = (v_12 || v_13);
    bool v_11;
    bool v_22;
    uint v_24;
    v_24 = uint(gl_FragCoord.x - 0.5);
    v_22 = (v_24 == 10u);
    bool v_23;
    uint v_25;
    v_25 = uint(gl_FragCoord.y - 0.5);
    v_23 = (v_25 == 9u);
    v_11 = (v_22 && v_23);
    v_8 = (v_10 || v_11);
    bool v_9;
    bool v_26;
    uint v_28;
    v_28 = uint(gl_FragCoord.x - 0.5);
    v_26 = (v_28 == 11u);
    bool v_27;
    uint v_29;
    v_29 = uint(gl_FragCoord.y - 0.5);
    v_27 = (v_29 == 6u);
    v_9 = (v_26 && v_27);
    v_6 = (v_8 || v_9);
    bool v_7;
    bool v_30;
    uint v_32;
    v_32 = uint(gl_FragCoord.x - 0.5);
    v_30 = (v_32 == 12u);
    bool v_31;
    uint v_33;
    v_33 = uint(gl_FragCoord.y - 0.5);
    v_31 = (v_33 == 7u);
    v_7 = (v_30 && v_31);
    v_5 = (v_6 || v_7);
    bool v_34 = v_5;
    if(!v_34) return false;
    a1t = ALL_NOT_FOUND;
    a1t.material = Imp;
    value v_35;
    v_35 = ALL_NOT_FOUND;
    v_35.material = Left;
    a1t.DirectionH = DirectionH_e(v_35);
    value v_36;
    v_36 = ALL_NOT_FOUND;
    v_36.material = None;
    a1t.ImpClimb = ImpClimb_e(v_36);
    uint v_37;
    v_37 = 0u;
    if(v_37 >= 3u) return false;
    a1t.ImpStep = v_37;
    value v_38;
    v_38 = ALL_NOT_FOUND;
    v_38.material = None;
    a1t.Content = Content_e(v_38);
    
    a1 = a1t;
    return true;
}

bool generateCave2_r(inout uint seed, uint transform, inout value a1) {
    value v_1 = a1;
    
    value a1t;
    
    bool v_2;
    uint v_3;
    v_3 = uint(step);
    v_2 = (v_3 == 0u);
    bool v_4 = v_2;
    if(!v_4) return false;
    bool v_5;
    bool v_6;
    bool v_8;
    bool v_10;
    uint v_12;
    v_12 = uint(gl_FragCoord.x - 0.5);
    v_10 = (v_12 > 5u);
    bool v_11;
    uint v_13;
    v_13 = uint(gl_FragCoord.x - 0.5);
    v_11 = (v_13 < 15u);
    v_8 = (v_10 && v_11);
    bool v_9;
    uint v_14;
    v_14 = uint(gl_FragCoord.y - 0.5);
    v_9 = (v_14 > 20u);
    v_6 = (v_8 && v_9);
    bool v_7;
    uint v_15;
    v_15 = uint(gl_FragCoord.y - 0.5);
    v_7 = (v_15 < 30u);
    v_5 = (v_6 && v_7);
    bool v_16 = v_5;
    if(!v_16) return false;
    a1t = ALL_NOT_FOUND;
    a1t.material = Cave;
    value v_17;
    v_17 = ALL_NOT_FOUND;
    v_17.material = None;
    a1t.Foreground = Foreground_e(v_17);
    value v_18;
    v_18 = ALL_NOT_FOUND;
    v_18.material = None;
    a1t.Background = Background_e(v_18);
    
    a1 = a1t;
    return true;
}

bool generateLadder2_r(inout uint seed, uint transform, inout value a1) {
    value c_ = a1;
    if(c_.material != Cave) return false;
    
    value a1t;
    
    bool v_1;
    uint v_2;
    v_2 = uint(step);
    v_1 = (v_2 == 0u);
    bool v_3 = v_1;
    if(!v_3) return false;
    bool v_4;
    bool v_5;
    bool v_7;
    uint v_9;
    v_9 = uint(gl_FragCoord.x - 0.5);
    v_7 = (v_9 == 10u);
    bool v_8;
    uint v_10;
    v_10 = uint(gl_FragCoord.y - 0.5);
    v_8 = (v_10 > 20u);
    v_5 = (v_7 && v_8);
    bool v_6;
    uint v_11;
    v_11 = uint(gl_FragCoord.y - 0.5);
    v_6 = (v_11 <= 25u);
    v_4 = (v_5 && v_6);
    bool v_12 = v_4;
    if(!v_12) return false;
    a1t = c_;
    value v_13;
    v_13 = ALL_NOT_FOUND;
    v_13.material = Ladder;
    a1t.Background = Background_e(v_13);
    
    a1 = a1t;
    return true;
}

bool generateImp2_r(inout uint seed, uint transform, inout value a1) {
    value c_ = a1;
    if(c_.material != Cave) return false;
    
    value a1t;
    
    bool v_1;
    uint v_2;
    v_2 = uint(step);
    v_1 = (v_2 == 0u);
    bool v_3 = v_1;
    if(!v_3) return false;
    bool v_4;
    bool v_5;
    bool v_7;
    bool v_9;
    bool v_11;
    uint v_13;
    v_13 = uint(gl_FragCoord.x - 0.5);
    v_11 = (v_13 == 6u);
    bool v_12;
    uint v_14;
    v_14 = uint(gl_FragCoord.x - 0.5);
    v_12 = (v_14 == 7u);
    v_9 = (v_11 || v_12);
    bool v_10;
    uint v_15;
    v_15 = uint(gl_FragCoord.x - 0.5);
    v_10 = (v_15 == 12u);
    v_7 = (v_9 || v_10);
    bool v_8;
    uint v_16;
    v_16 = uint(gl_FragCoord.x - 0.5);
    v_8 = (v_16 == 14u);
    v_5 = (v_7 || v_8);
    bool v_6;
    uint v_17;
    v_17 = uint(gl_FragCoord.y - 0.5);
    v_6 = (v_17 == 21u);
    v_4 = (v_5 && v_6);
    bool v_18 = v_4;
    if(!v_18) return false;
    a1t = c_;
    value v_19;
    v_19 = ALL_NOT_FOUND;
    v_19.material = Imp;
    value v_20;
    v_20 = ALL_NOT_FOUND;
    v_20.material = Left;
    v_19.DirectionH = DirectionH_e(v_20);
    value v_21;
    v_21 = ALL_NOT_FOUND;
    v_21.material = None;
    v_19.ImpClimb = ImpClimb_e(v_21);
    uint v_22;
    v_22 = 0u;
    if(v_22 >= 3u) return false;
    v_19.ImpStep = v_22;
    value v_23;
    v_23 = ALL_NOT_FOUND;
    v_23.material = None;
    v_19.Content = Content_e(v_23);
    a1t.Foreground = Foreground_e(v_19);
    
    a1 = a1t;
    return true;
}

bool generateSign2a_r(inout uint seed, uint transform, inout value a1) {
    value c_ = a1;
    if(c_.material != Cave) return false;
    
    value a1t;
    
    bool v_1;
    uint v_2;
    v_2 = uint(step);
    v_1 = (v_2 == 0u);
    bool v_3 = v_1;
    if(!v_3) return false;
    bool v_4;
    bool v_5;
    bool v_7;
    uint v_9;
    v_9 = uint(gl_FragCoord.x - 0.5);
    v_7 = (v_9 == 9u);
    bool v_8;
    uint v_10;
    v_10 = uint(gl_FragCoord.x - 0.5);
    v_8 = (v_10 == 11u);
    v_5 = (v_7 || v_8);
    bool v_6;
    uint v_11;
    v_11 = uint(gl_FragCoord.y - 0.5);
    v_6 = (v_11 == 21u);
    v_4 = (v_5 && v_6);
    bool v_12 = v_4;
    if(!v_12) return false;
    a1t = c_;
    value v_13;
    v_13 = ALL_NOT_FOUND;
    v_13.material = Sign;
    value v_14;
    v_14 = ALL_NOT_FOUND;
    v_14.material = Up;
    v_13.DirectionV = DirectionV_e(v_14);
    a1t.Background = Background_e(v_13);
    
    a1 = a1t;
    return true;
}

bool generateSign2b_r(inout uint seed, uint transform, inout value a1) {
    value c_ = a1;
    if(c_.material != Cave) return false;
    
    value a1t;
    
    bool v_1;
    uint v_2;
    v_2 = uint(step);
    v_1 = (v_2 == 0u);
    bool v_3 = v_1;
    if(!v_3) return false;
    bool v_4;
    bool v_5;
    bool v_7;
    uint v_9;
    v_9 = uint(gl_FragCoord.x - 0.5);
    v_7 = (v_9 == 9u);
    bool v_8;
    uint v_10;
    v_10 = uint(gl_FragCoord.x - 0.5);
    v_8 = (v_10 == 11u);
    v_5 = (v_7 || v_8);
    bool v_6;
    uint v_11;
    v_11 = uint(gl_FragCoord.y - 0.5);
    v_6 = (v_11 == 25u);
    v_4 = (v_5 && v_6);
    bool v_12 = v_4;
    if(!v_12) return false;
    a1t = c_;
    value v_13;
    v_13 = ALL_NOT_FOUND;
    v_13.material = Sign;
    value v_14;
    v_14 = ALL_NOT_FOUND;
    v_14.material = Down;
    v_13.DirectionV = DirectionV_e(v_14);
    a1t.Background = Background_e(v_13);
    
    a1 = a1t;
    return true;
}

bool generatePlatform2_r(inout uint seed, uint transform, inout value a1) {
    value c_ = a1;
    
    value a1t;
    
    bool v_1;
    uint v_2;
    v_2 = uint(step);
    v_1 = (v_2 == 0u);
    bool v_3 = v_1;
    if(!v_3) return false;
    bool v_4;
    bool v_5;
    bool v_7;
    uint v_9;
    v_9 = uint(gl_FragCoord.x - 0.5);
    v_7 = (v_9 > 7u);
    bool v_8;
    uint v_10;
    v_10 = uint(gl_FragCoord.x - 0.5);
    v_8 = (v_10 < 13u);
    v_5 = (v_7 && v_8);
    bool v_6;
    uint v_11;
    v_11 = uint(gl_FragCoord.y - 0.5);
    v_6 = (v_11 == 24u);
    v_4 = (v_5 && v_6);
    bool v_12 = v_4;
    if(!v_12) return false;
    a1t = c_;
    value v_13;
    v_13 = ALL_NOT_FOUND;
    v_13.material = Ladder;
    a1t.Background = Background_e(v_13);
    
    a1 = a1t;
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
    uint v_2;
    v_2 = (x_ + 1u);
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

bool shaftEnter_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.DirectionHV == NOT_FOUND || a_.ShaftForeground == NOT_FOUND) return false;
    value d_ = DirectionHV_d(a_.DirectionHV);
    value v_1 = ShaftForeground_d(a_.ShaftForeground);
    if(v_1.material != None) return false;

    value b_ = a2;
    if(b_.Foreground == NOT_FOUND) return false;
    value i_ = Foreground_d(b_.Foreground);
    if(i_.Content == NOT_FOUND || i_.ImpClimb == NOT_FOUND || i_.ImpStep == NOT_FOUND || i_.material != Imp) return false;
    value v_2 = Content_d(i_.Content);
    if(v_2.material != None) return false;
    value v_3 = ImpClimb_d(i_.ImpClimb);
    if(v_3.material != None) return false;
    uint v_4 = i_.ImpStep;
    if(v_4 != 2u) return false;
    
    value a1t;
    value a2t;
    
    bool v_5;
    value v_6;
    value v_7;
    v_7 = ALL_NOT_FOUND;
    v_7.material = Up;
    if(!rotate_f(seed, transform, v_7, v_6)) return false;
    v_5 = (d_ == v_6);
    bool v_8 = v_5;
    if(!v_8) return false;
    a1t = a_;
    value v_9;
    v_9 = ALL_NOT_FOUND;
    v_9.material = ShaftImp;
    value v_10;
    v_10 = ALL_NOT_FOUND;
    v_10.material = None;
    v_9.Content = Content_e(v_10);
    a1t.ShaftForeground = ShaftForeground_e(v_9);
    a2t = b_;
    value v_11;
    v_11 = ALL_NOT_FOUND;
    v_11.material = None;
    a2t.Foreground = Foreground_e(v_11);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool shaftExit_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.DirectionHV == NOT_FOUND || a_.ShaftForeground == NOT_FOUND) return false;
    value d_ = DirectionHV_d(a_.DirectionHV);
    value v_1 = ShaftForeground_d(a_.ShaftForeground);
    if(v_1.Content == NOT_FOUND || v_1.material != ShaftImp) return false;
    value c_ = Content_d(v_1.Content);

    value b_ = a2;
    if(b_.Foreground == NOT_FOUND) return false;
    value v_2 = Foreground_d(b_.Foreground);
    if(v_2.material != None) return false;
    
    value a1t;
    value a2t;
    
    bool v_3;
    value v_4;
    value v_5;
    v_5 = ALL_NOT_FOUND;
    v_5.material = Up;
    if(!rotate_f(seed, transform, v_5, v_4)) return false;
    v_3 = (d_ == v_4);
    bool v_6 = v_3;
    if(!v_6) return false;
    value v_7;
    value v_8;
    v_8 = d_;
    int m_9 = 0;
    switch(m_9) { case 0:
        value v_10 = v_8;
        if(v_10.material != Right) break;
        v_7 = ALL_NOT_FOUND;
        v_7.material = Left;
        m_9 = 1;
    default: break; }
    switch(m_9) { case 0:
        value v_11 = v_8;
        v_7 = ALL_NOT_FOUND;
        v_7.material = Right;
        m_9 = 1;
    default: break; }
    if(m_9 == 0) return false;
    value d2_ = v_7;
    a1t = a_;
    value v_12;
    v_12 = ALL_NOT_FOUND;
    v_12.material = None;
    a1t.ShaftForeground = ShaftForeground_e(v_12);
    a2t = b_;
    value v_13;
    v_13 = ALL_NOT_FOUND;
    v_13.material = Imp;
    value v_14;
    v_14 = d2_;
    v_13.DirectionH = DirectionH_e(v_14);
    value v_15;
    v_15 = ALL_NOT_FOUND;
    v_15.material = None;
    v_13.ImpClimb = ImpClimb_e(v_15);
    uint v_16;
    v_16 = 0u;
    if(v_16 >= 3u) return false;
    v_13.ImpStep = v_16;
    value v_17;
    v_17 = c_;
    v_13.Content = Content_e(v_17);
    a2t.Foreground = Foreground_e(v_13);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool shaftSwapEnter_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.DirectionHV == NOT_FOUND || a_.ShaftForeground == NOT_FOUND) return false;
    value d_ = DirectionHV_d(a_.DirectionHV);
    value v_1 = ShaftForeground_d(a_.ShaftForeground);
    if(v_1.Content == NOT_FOUND || v_1.material != ShaftImp) return false;
    value c_ = Content_d(v_1.Content);

    value b_ = a2;
    if(b_.Foreground == NOT_FOUND) return false;
    value v_2 = Foreground_d(b_.Foreground);
    if(v_2.Content == NOT_FOUND || v_2.ImpClimb == NOT_FOUND || v_2.ImpStep == NOT_FOUND || v_2.material != Imp) return false;
    value v_3 = Content_d(v_2.Content);
    if(v_3.material != None) return false;
    value v_4 = ImpClimb_d(v_2.ImpClimb);
    if(v_4.material != None) return false;
    uint v_5 = v_2.ImpStep;
    if(v_5 != 2u) return false;
    
    value a1t;
    value a2t;
    
    bool v_6;
    value v_7;
    value v_8;
    v_8 = ALL_NOT_FOUND;
    v_8.material = Up;
    if(!rotate_f(seed, transform, v_8, v_7)) return false;
    v_6 = (d_ == v_7);
    bool v_9 = v_6;
    if(!v_9) return false;
    value v_10;
    value v_11;
    v_11 = d_;
    int m_12 = 0;
    switch(m_12) { case 0:
        value v_13 = v_11;
        if(v_13.material != Right) break;
        v_10 = ALL_NOT_FOUND;
        v_10.material = Left;
        m_12 = 1;
    default: break; }
    switch(m_12) { case 0:
        value v_14 = v_11;
        v_10 = ALL_NOT_FOUND;
        v_10.material = Right;
        m_12 = 1;
    default: break; }
    if(m_12 == 0) return false;
    value d2_ = v_10;
    a1t = a_;
    value v_15;
    v_15 = ALL_NOT_FOUND;
    v_15.material = ShaftImp;
    value v_16;
    v_16 = ALL_NOT_FOUND;
    v_16.material = None;
    v_15.Content = Content_e(v_16);
    a1t.ShaftForeground = ShaftForeground_e(v_15);
    a2t = b_;
    value v_17;
    v_17 = ALL_NOT_FOUND;
    v_17.material = Imp;
    value v_18;
    v_18 = d2_;
    v_17.DirectionH = DirectionH_e(v_18);
    value v_19;
    v_19 = ALL_NOT_FOUND;
    v_19.material = None;
    v_17.ImpClimb = ImpClimb_e(v_19);
    uint v_20;
    v_20 = 0u;
    if(v_20 >= 3u) return false;
    v_17.ImpStep = v_20;
    value v_21;
    v_21 = c_;
    v_17.Content = Content_e(v_21);
    a2t.Foreground = Foreground_e(v_17);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool shaftDigEnter_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Dig == NOT_FOUND || a_.Vein == NOT_FOUND || a_.material != Rock) return false;
    uint v_1 = a_.Dig;
    if(v_1 != 1u) return false;
    value ore_ = Vein_d(a_.Vein);

    value b_ = a2;
    if(b_.Foreground == NOT_FOUND) return false;
    value i_ = Foreground_d(b_.Foreground);
    if(i_.Content == NOT_FOUND || i_.ImpClimb == NOT_FOUND || i_.ImpStep == NOT_FOUND || i_.material != Imp) return false;
    value v_2 = Content_d(i_.Content);
    if(v_2.material != None) return false;
    value v_3 = ImpClimb_d(i_.ImpClimb);
    if(v_3.material != None) return false;
    uint v_4 = i_.ImpStep;
    if(v_4 != 2u) return false;
    
    value a1t;
    value a2t;
    
    a1t = ALL_NOT_FOUND;
    a1t.material = Shaft;
    value v_5;
    v_5 = ALL_NOT_FOUND;
    v_5.material = ShaftImp;
    value v_6;
    v_6 = ore_;
    v_5.Content = Content_e(v_6);
    a1t.ShaftForeground = ShaftForeground_e(v_5);
    value v_7;
    value v_8;
    v_8 = ALL_NOT_FOUND;
    v_8.material = Up;
    if(!rotate_f(seed, transform, v_8, v_7)) return false;
    a1t.DirectionHV = DirectionHV_e(v_7);
    a2t = b_;
    value v_9;
    v_9 = ALL_NOT_FOUND;
    v_9.material = None;
    a2t.Foreground = Foreground_e(v_9);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool shaftDig_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Dig == NOT_FOUND || a_.Vein == NOT_FOUND || a_.material != Rock) return false;
    uint v_1 = a_.Dig;
    if(v_1 != 1u) return false;
    value ore_ = Vein_d(a_.Vein);

    value b_ = a2;
    if(b_.ShaftForeground == NOT_FOUND || b_.material != Shaft) return false;
    value v_2 = ShaftForeground_d(b_.ShaftForeground);
    if(v_2.Content == NOT_FOUND || v_2.material != ShaftImp) return false;
    value v_3 = Content_d(v_2.Content);
    if(v_3.material != None) return false;
    
    value a1t;
    value a2t;
    
    a1t = ALL_NOT_FOUND;
    a1t.material = Shaft;
    value v_4;
    v_4 = ALL_NOT_FOUND;
    v_4.material = ShaftImp;
    value v_5;
    v_5 = ore_;
    v_4.Content = Content_e(v_5);
    a1t.ShaftForeground = ShaftForeground_e(v_4);
    value v_6;
    value v_7;
    v_7 = ALL_NOT_FOUND;
    v_7.material = Up;
    if(!rotate_f(seed, transform, v_7, v_6)) return false;
    a1t.DirectionHV = DirectionHV_e(v_6);
    a2t = b_;
    value v_8;
    v_8 = ALL_NOT_FOUND;
    v_8.material = None;
    a2t.ShaftForeground = ShaftForeground_e(v_8);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool shaftAscend_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.DirectionHV == NOT_FOUND || a_.ShaftForeground == NOT_FOUND) return false;
    value d_ = DirectionHV_d(a_.DirectionHV);
    value v_1 = ShaftForeground_d(a_.ShaftForeground);
    if(v_1.material != None) return false;

    value b_ = a2;
    if(b_.ShaftForeground == NOT_FOUND) return false;
    value i_ = ShaftForeground_d(b_.ShaftForeground);
    if(i_.Content == NOT_FOUND || i_.material != ShaftImp) return false;
    value v_2 = Content_d(i_.Content);
    if(v_2.material != None) return false;
    
    value a1t;
    value a2t;
    
    bool v_3;
    value v_4;
    value v_5;
    v_5 = ALL_NOT_FOUND;
    v_5.material = Up;
    if(!rotate_f(seed, transform, v_5, v_4)) return false;
    v_3 = (d_ == v_4);
    bool v_6 = v_3;
    if(!v_6) return false;
    a1t = a_;
    value v_7;
    v_7 = i_;
    a1t.ShaftForeground = ShaftForeground_e(v_7);
    a2t = b_;
    value v_8;
    v_8 = ALL_NOT_FOUND;
    v_8.material = None;
    a2t.ShaftForeground = ShaftForeground_e(v_8);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool shaftDescend_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.DirectionHV == NOT_FOUND || a_.ShaftForeground == NOT_FOUND) return false;
    value d_ = DirectionHV_d(a_.DirectionHV);
    value i_ = ShaftForeground_d(a_.ShaftForeground);
    if(i_.Content == NOT_FOUND || i_.material != ShaftImp) return false;
    value c_ = Content_d(i_.Content);

    value b_ = a2;
    if(b_.ShaftForeground == NOT_FOUND) return false;
    value v_1 = ShaftForeground_d(b_.ShaftForeground);
    if(v_1.material != None) return false;
    
    value a1t;
    value a2t;
    
    bool v_2;
    bool v_3;
    value v_5;
    value v_6;
    v_6 = ALL_NOT_FOUND;
    v_6.material = Up;
    if(!rotate_f(seed, transform, v_6, v_5)) return false;
    v_3 = (d_ == v_5);
    bool v_4;
    value v_7;
    v_7 = ALL_NOT_FOUND;
    v_7.material = None;
    v_4 = (c_ != v_7);
    v_2 = (v_3 && v_4);
    bool v_8 = v_2;
    if(!v_8) return false;
    a1t = a_;
    value v_9;
    v_9 = ALL_NOT_FOUND;
    v_9.material = None;
    a1t.ShaftForeground = ShaftForeground_e(v_9);
    a2t = b_;
    value v_10;
    v_10 = i_;
    a2t.ShaftForeground = ShaftForeground_e(v_10);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool shaftSwap_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.DirectionHV == NOT_FOUND || a_.ShaftForeground == NOT_FOUND) return false;
    value d_ = DirectionHV_d(a_.DirectionHV);
    value i1_ = ShaftForeground_d(a_.ShaftForeground);
    if(i1_.Content == NOT_FOUND || i1_.material != ShaftImp) return false;
    value c_ = Content_d(i1_.Content);

    value b_ = a2;
    if(b_.ShaftForeground == NOT_FOUND) return false;
    value i2_ = ShaftForeground_d(b_.ShaftForeground);
    if(i2_.Content == NOT_FOUND || i2_.material != ShaftImp) return false;
    value v_1 = Content_d(i2_.Content);
    if(v_1.material != None) return false;
    
    value a1t;
    value a2t;
    
    bool v_2;
    bool v_3;
    value v_5;
    value v_6;
    v_6 = ALL_NOT_FOUND;
    v_6.material = Up;
    if(!rotate_f(seed, transform, v_6, v_5)) return false;
    v_3 = (d_ == v_5);
    bool v_4;
    value v_7;
    v_7 = ALL_NOT_FOUND;
    v_7.material = None;
    v_4 = (c_ != v_7);
    v_2 = (v_3 && v_4);
    bool v_8 = v_2;
    if(!v_8) return false;
    a1t = a_;
    value v_9;
    v_9 = i2_;
    a1t.ShaftForeground = ShaftForeground_e(v_9);
    a2t = b_;
    value v_10;
    v_10 = i1_;
    a2t.ShaftForeground = ShaftForeground_e(v_10);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool shaftRemove_r(inout uint seed, uint transform, value a1, value b1, value c1, value a2, inout value b2, value c2, value a3, value b3, value c3) {
    value v_1 = a1;

    value u_ = b1;

    value v_2 = c1;

    value l_ = a2;

    value c_ = b2;
    if(c_.DirectionHV == NOT_FOUND) return false;
    value d_ = DirectionHV_d(c_.DirectionHV);

    value r_ = c2;

    value v_3 = a3;

    value v_4 = b3;

    value v_5 = c3;
    
    value b2t;
    
    bool v_6;
    value v_7;
    value v_8;
    v_8 = ALL_NOT_FOUND;
    v_8.material = Up;
    if(!rotate_f(seed, transform, v_8, v_7)) return false;
    v_6 = (d_ == v_7);
    bool v_9 = v_6;
    if(!v_9) return false;
    uint v_10;
    value v_11;
    v_11 = l_;
    int m_12 = 0;
    switch(m_12) { case 0:
        value v_13 = v_11;
        if(v_13.DirectionHV == NOT_FOUND || v_13.material != Shaft) break;
        value xd_ = DirectionHV_d(v_13.DirectionHV);
        bool v_14;
        value v_15;
        value v_16;
        v_16 = ALL_NOT_FOUND;
        v_16.material = Left;
        if(!rotate_f(seed, transform, v_16, v_15)) return false;
        v_14 = (xd_ == v_15);
        if(v_14) {
        v_10 = 1u;
        } else {
        v_10 = 0u;
        }
        m_12 = 1;
    default: break; }
    switch(m_12) { case 0:
        value v_17 = v_11;
        if(v_17.Dig == NOT_FOUND) break;
        uint v_18 = v_17.Dig;
        if(v_18 != 1u) break;
        v_10 = 1u;
        m_12 = 1;
    default: break; }
    switch(m_12) { case 0:
        value v_19 = v_11;
        v_10 = 0u;
        m_12 = 1;
    default: break; }
    if(m_12 == 0) return false;
    uint x_ = v_10;
    uint v_20;
    value v_21;
    v_21 = r_;
    int m_22 = 0;
    switch(m_22) { case 0:
        value v_23 = v_21;
        if(v_23.DirectionHV == NOT_FOUND || v_23.material != Shaft) break;
        value yd_ = DirectionHV_d(v_23.DirectionHV);
        bool v_24;
        value v_25;
        value v_26;
        v_26 = ALL_NOT_FOUND;
        v_26.material = Right;
        if(!rotate_f(seed, transform, v_26, v_25)) return false;
        v_24 = (yd_ == v_25);
        if(v_24) {
        v_20 = 1u;
        } else {
        v_20 = 0u;
        }
        m_22 = 1;
    default: break; }
    switch(m_22) { case 0:
        value v_27 = v_21;
        if(v_27.Dig == NOT_FOUND) break;
        uint v_28 = v_27.Dig;
        if(v_28 != 1u) break;
        v_20 = 1u;
        m_22 = 1;
    default: break; }
    switch(m_22) { case 0:
        value v_29 = v_21;
        v_20 = 0u;
        m_22 = 1;
    default: break; }
    if(m_22 == 0) return false;
    uint y_ = v_20;
    uint v_30;
    value v_31;
    v_31 = u_;
    int m_32 = 0;
    switch(m_32) { case 0:
        value v_33 = v_31;
        if(v_33.DirectionHV == NOT_FOUND || v_33.material != Shaft) break;
        value zd_ = DirectionHV_d(v_33.DirectionHV);
        bool v_34;
        value v_35;
        value v_36;
        v_36 = ALL_NOT_FOUND;
        v_36.material = Up;
        if(!rotate_f(seed, transform, v_36, v_35)) return false;
        v_34 = (zd_ == v_35);
        if(v_34) {
        v_30 = 1u;
        } else {
        v_30 = 0u;
        }
        m_32 = 1;
    default: break; }
    switch(m_32) { case 0:
        value v_37 = v_31;
        if(v_37.Dig == NOT_FOUND) break;
        uint v_38 = v_37.Dig;
        if(v_38 != 1u) break;
        v_30 = 1u;
        m_32 = 1;
    default: break; }
    switch(m_32) { case 0:
        value v_39 = v_31;
        v_30 = 0u;
        m_32 = 1;
    default: break; }
    if(m_32 == 0) return false;
    uint z_ = v_30;
    bool v_40;
    bool v_41;
    bool v_43;
    v_43 = (x_ == 0u);
    bool v_44;
    v_44 = (y_ == 0u);
    v_41 = (v_43 && v_44);
    bool v_42;
    v_42 = (z_ == 0u);
    v_40 = (v_41 && v_42);
    bool v_45 = v_40;
    if(!v_45) return false;
    value v_46;
    v_46 = c_;
    int m_47 = 0;
    switch(m_47) { case 0:
        value v_48 = v_46;
        if(v_48.ShaftForeground == NOT_FOUND) break;
        value v_49 = ShaftForeground_d(v_48.ShaftForeground);
        if(v_49.material != None) break;
        b2t = ALL_NOT_FOUND;
        b2t.material = Cave;
        value v_50;
        v_50 = ALL_NOT_FOUND;
        v_50.material = None;
        b2t.Foreground = Foreground_e(v_50);
        value v_51;
        v_51 = ALL_NOT_FOUND;
        v_51.material = None;
        b2t.Background = Background_e(v_51);
        m_47 = 1;
    default: break; }
    switch(m_47) { case 0:
        value v_52 = v_46;
        if(v_52.ShaftForeground == NOT_FOUND) break;
        value i_ = ShaftForeground_d(v_52.ShaftForeground);
        if(i_.Content == NOT_FOUND || i_.material != ShaftImp) break;
        value v_53 = Content_d(i_.Content);
        if(v_53.material != None) break;
        b2t = c_;
        value v_54;
        v_54 = i_;
        value v_55;
        v_55 = ALL_NOT_FOUND;
        v_55.material = RockOre;
        v_54.Content = Content_e(v_55);
        b2t.ShaftForeground = ShaftForeground_e(v_54);
        m_47 = 1;
    default: break; }
    if(m_47 == 0) return false;
    
    b2 = b2t;
    return true;
}

bool impStep_r(inout uint seed, uint transform, value b1, inout value b2, value b3) {
    value v_1 = b1;

    value a_ = b2;
    if(a_.Foreground == NOT_FOUND) return false;
    value i_ = Foreground_d(a_.Foreground);
    if(i_.DirectionH == NOT_FOUND || i_.ImpStep == NOT_FOUND || i_.material != Imp) return false;
    value d_ = DirectionH_d(i_.DirectionH);
    uint s_ = i_.ImpStep;

    value g_ = b3;
    
    value b2t;
    
    bool v_2;
    bool v_3;
    value v_5;
    value v_6;
    v_6 = ALL_NOT_FOUND;
    v_6.material = Right;
    if(!rotate_f(seed, transform, v_6, v_5)) return false;
    v_3 = (d_ == v_5);
    bool v_4;
    if(!walkable_f(seed, transform, g_, v_4)) return false;
    v_2 = (v_3 && v_4);
    bool v_7 = v_2;
    if(!v_7) return false;
    b2t = a_;
    value v_8;
    v_8 = i_;
    uint v_9;
    v_9 = (s_ + 1u);
    if(v_9 >= 3u) return false;
    v_8.ImpStep = v_9;
    b2t.Foreground = Foreground_e(v_8);
    
    b2 = b2t;
    return true;
}

bool impWalk_r(inout uint seed, uint transform, value b1, value c1, inout value b2, inout value c2, value b3, value c3) {
    value v_1 = b1;

    value v_2 = c1;

    value a_ = b2;
    if(a_.Foreground == NOT_FOUND) return false;
    value i_ = Foreground_d(a_.Foreground);
    if(i_.ImpClimb == NOT_FOUND || i_.DirectionH == NOT_FOUND || i_.ImpStep == NOT_FOUND || i_.material != Imp) return false;
    value v_3 = ImpClimb_d(i_.ImpClimb);
    if(v_3.material != None) return false;
    value d_ = DirectionH_d(i_.DirectionH);
    uint v_4 = i_.ImpStep;
    if(v_4 != 2u) return false;

    value b_ = c2;
    if(b_.Foreground == NOT_FOUND) return false;
    value v_5 = Foreground_d(b_.Foreground);
    if(v_5.material != None) return false;

    value g1_ = b3;

    value g2_ = c3;
    
    value b2t;
    value c2t;
    
    bool v_6;
    bool v_7;
    bool v_9;
    value v_11;
    value v_12;
    v_12 = ALL_NOT_FOUND;
    v_12.material = Right;
    if(!rotate_f(seed, transform, v_12, v_11)) return false;
    v_9 = (d_ == v_11);
    bool v_10;
    if(!walkable_f(seed, transform, g1_, v_10)) return false;
    v_7 = (v_9 && v_10);
    bool v_8;
    if(!walkable_f(seed, transform, g2_, v_8)) return false;
    v_6 = (v_7 && v_8);
    bool v_13 = v_6;
    if(!v_13) return false;
    b2t = a_;
    value v_14;
    v_14 = ALL_NOT_FOUND;
    v_14.material = None;
    b2t.Foreground = Foreground_e(v_14);
    c2t = b_;
    value v_15;
    v_15 = i_;
    uint v_16;
    v_16 = 0u;
    if(v_16 >= 3u) return false;
    v_15.ImpStep = v_16;
    c2t.Foreground = Foreground_e(v_15);
    
    b2 = b2t;
    c2 = c2t;
    return true;
}

bool impFall_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Foreground == NOT_FOUND) return false;
    value i_ = Foreground_d(a_.Foreground);
    if(i_.ImpClimb == NOT_FOUND || i_.material != Imp) return false;
    value v_1 = ImpClimb_d(i_.ImpClimb);
    if(v_1.material != None) return false;

    value b_ = a2;
    if(b_.Background == NOT_FOUND || b_.Foreground == NOT_FOUND) return false;
    value l_ = Background_d(b_.Background);
    value v_2 = Foreground_d(b_.Foreground);
    if(v_2.material != None) return false;
    
    value a1t;
    value a2t;
    
    bool v_3;
    value v_4;
    v_4 = ALL_NOT_FOUND;
    v_4.material = Ladder;
    v_3 = (l_ != v_4);
    bool v_5 = v_3;
    if(!v_5) return false;
    a1t = a_;
    value v_6;
    v_6 = ALL_NOT_FOUND;
    v_6.material = None;
    a1t.Foreground = Foreground_e(v_6);
    a2t = b_;
    value v_7;
    v_7 = i_;
    a2t.Foreground = Foreground_e(v_7);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool impSwap_r(inout uint seed, uint transform, inout value a1, inout value b1) {
    value a_ = a1;
    if(a_.Foreground == NOT_FOUND) return false;
    value i1_ = Foreground_d(a_.Foreground);
    if(i1_.ImpClimb == NOT_FOUND || i1_.DirectionH == NOT_FOUND || i1_.ImpStep == NOT_FOUND || i1_.material != Imp) return false;
    value v_1 = ImpClimb_d(i1_.ImpClimb);
    if(v_1.material != None) return false;
    value v_2 = DirectionH_d(i1_.DirectionH);
    if(v_2.material != Right) return false;
    uint v_3 = i1_.ImpStep;
    if(v_3 != 2u) return false;

    value b_ = b1;
    if(b_.Foreground == NOT_FOUND) return false;
    value i2_ = Foreground_d(b_.Foreground);
    if(i2_.ImpClimb == NOT_FOUND || i2_.DirectionH == NOT_FOUND || i2_.ImpStep == NOT_FOUND || i2_.material != Imp) return false;
    value v_4 = ImpClimb_d(i2_.ImpClimb);
    if(v_4.material != None) return false;
    value v_5 = DirectionH_d(i2_.DirectionH);
    if(v_5.material != Left) return false;
    uint v_6 = i2_.ImpStep;
    if(v_6 != 2u) return false;
    
    value a1t;
    value b1t;
    
    a1t = a_;
    value v_7;
    v_7 = i2_;
    uint v_8;
    v_8 = 0u;
    if(v_8 >= 3u) return false;
    v_7.ImpStep = v_8;
    a1t.Foreground = Foreground_e(v_7);
    b1t = b_;
    value v_9;
    v_9 = i1_;
    uint v_10;
    v_10 = 0u;
    if(v_10 >= 3u) return false;
    v_9.ImpStep = v_10;
    b1t.Foreground = Foreground_e(v_9);
    
    a1 = a1t;
    b1 = b1t;
    return true;
}

bool impTurn_r(inout uint seed, uint transform, value b1, value c1, inout value b2, inout value c2, value b3, value c3) {
    value v_1 = b1;

    value v_2 = c1;

    value a_ = b2;
    if(a_.Foreground == NOT_FOUND) return false;
    value i_ = Foreground_d(a_.Foreground);
    if(i_.ImpClimb == NOT_FOUND || i_.DirectionH == NOT_FOUND || i_.ImpStep == NOT_FOUND || i_.material != Imp) return false;
    value v_3 = ImpClimb_d(i_.ImpClimb);
    if(v_3.material != None) return false;
    value d_ = DirectionH_d(i_.DirectionH);
    uint v_4 = i_.ImpStep;
    if(v_4 != 2u) return false;

    value b_ = c2;

    value v_5 = b3;

    value g_ = c3;
    
    value b2t;
    value c2t;
    
    bool v_6;
    value v_7;
    value v_8;
    v_8 = ALL_NOT_FOUND;
    v_8.material = Right;
    if(!rotate_f(seed, transform, v_8, v_7)) return false;
    v_6 = (d_ == v_7);
    bool v_9 = v_6;
    if(!v_9) return false;
    bool v_10;
    bool v_11;
    uint v_13;
    value v_14;
    v_14 = b_;
    int m_15 = 0;
    switch(m_15) { case 0:
        value v_16 = v_14;
        if(v_16.material != Rock) break;
        v_13 = 1u;
        m_15 = 1;
    default: break; }
    switch(m_15) { case 0:
        value v_17 = v_14;
        if(v_17.material != Building) break;
        v_13 = 1u;
        m_15 = 1;
    default: break; }
    switch(m_15) { case 0:
        value v_18 = v_14;
        v_13 = 0u;
        m_15 = 1;
    default: break; }
    if(m_15 == 0) return false;
    v_11 = (v_13 == 1u);
    bool v_12;
    bool v_19;
    if(!walkable_f(seed, transform, g_, v_19)) return false;
    v_12 = (!v_19);
    v_10 = (v_11 || v_12);
    bool v_20 = v_10;
    if(!v_20) return false;
    b2t = a_;
    value v_21;
    v_21 = i_;
    uint v_22;
    v_22 = 0u;
    if(v_22 >= 3u) return false;
    v_21.ImpStep = v_22;
    value v_23;
    value v_24;
    v_24 = ALL_NOT_FOUND;
    v_24.material = Left;
    if(!rotate_f(seed, transform, v_24, v_23)) return false;
    v_21.DirectionH = DirectionH_e(v_23);
    b2t.Foreground = Foreground_e(v_21);
    c2t = b_;
    
    b2 = b2t;
    c2 = c2t;
    return true;
}

bool ladderEnter_r(inout uint seed, uint transform, value a2, inout value b2, value c2) {
    value a_ = a2;
    if(a_.Background == NOT_FOUND) return false;
    value v_1 = Background_d(a_.Background);
    if(v_1.DirectionV == NOT_FOUND || v_1.material != Sign) return false;
    value v_ = DirectionV_d(v_1.DirectionV);

    value b_ = b2;
    if(b_.Background == NOT_FOUND || b_.Foreground == NOT_FOUND) return false;
    value v_2 = Background_d(b_.Background);
    if(v_2.material != Ladder) return false;
    value i_ = Foreground_d(b_.Foreground);
    if(i_.ImpClimb == NOT_FOUND || i_.ImpStep == NOT_FOUND || i_.DirectionH == NOT_FOUND || i_.material != Imp) return false;
    value v_3 = ImpClimb_d(i_.ImpClimb);
    if(v_3.material != None) return false;
    uint v_4 = i_.ImpStep;
    if(v_4 != 1u) return false;
    value h_ = DirectionH_d(i_.DirectionH);

    value v_5 = c2;
    
    value b2t;
    
    bool v_6;
    value v_7;
    value v_8;
    v_8 = ALL_NOT_FOUND;
    v_8.material = Right;
    if(!rotate_f(seed, transform, v_8, v_7)) return false;
    v_6 = (h_ == v_7);
    bool v_9 = v_6;
    if(!v_9) return false;
    b2t = b_;
    value v_10;
    v_10 = i_;
    value v_11;
    v_11 = v_;
    v_10.ImpClimb = ImpClimb_e(v_11);
    uint v_12;
    v_12 = 1u;
    if(v_12 >= 3u) return false;
    v_10.ImpStep = v_12;
    b2t.Foreground = Foreground_e(v_10);
    
    b2 = b2t;
    return true;
}

bool ladderExit_r(inout uint seed, uint transform, value b1, inout value b2, value b3) {
    value a_ = b1;

    value b_ = b2;
    if(b_.Background == NOT_FOUND || b_.Foreground == NOT_FOUND) return false;
    value v_1 = Background_d(b_.Background);
    if(v_1.material != Ladder) return false;
    value i_ = Foreground_d(b_.Foreground);
    if(i_.ImpStep == NOT_FOUND || i_.ImpClimb == NOT_FOUND || i_.material != Imp) return false;
    uint s_ = i_.ImpStep;
    value d_ = ImpClimb_d(i_.ImpClimb);

    value v_2 = b3;
    
    value b2t;
    
    bool v_3;
    bool v_4;
    value v_6;
    value v_7;
    v_7 = ALL_NOT_FOUND;
    v_7.material = Up;
    if(!rotate_f(seed, transform, v_7, v_6)) return false;
    v_4 = (d_ == v_6);
    bool v_5;
    v_5 = (s_ != 0u);
    v_3 = (v_4 && v_5);
    bool v_8 = v_3;
    if(!v_8) return false;
    bool v_9;
    uint v_10;
    value v_11;
    v_11 = a_;
    int m_12 = 0;
    switch(m_12) { case 0:
        value v_13 = v_11;
        if(v_13.Background == NOT_FOUND) break;
        value v_14 = Background_d(v_13.Background);
        if(v_14.material != Ladder) break;
        v_10 = 1u;
        m_12 = 1;
    default: break; }
    switch(m_12) { case 0:
        value v_15 = v_11;
        v_10 = 0u;
        m_12 = 1;
    default: break; }
    if(m_12 == 0) return false;
    v_9 = (v_10 == 0u);
    bool v_16 = v_9;
    if(!v_16) return false;
    b2t = b_;
    value v_17;
    v_17 = i_;
    value v_18;
    v_18 = ALL_NOT_FOUND;
    v_18.material = None;
    v_17.ImpClimb = ImpClimb_e(v_18);
    uint v_19;
    v_19 = 1u;
    if(v_19 >= 3u) return false;
    v_17.ImpStep = v_19;
    b2t.Foreground = Foreground_e(v_17);
    
    b2 = b2t;
    return true;
}

bool ladderCheck_r(inout uint seed, uint transform, inout value a1) {
    value a_ = a1;
    if(a_.Background == NOT_FOUND || a_.Foreground == NOT_FOUND) return false;
    value b_ = Background_d(a_.Background);
    value i_ = Foreground_d(a_.Foreground);
    if(i_.ImpClimb == NOT_FOUND || i_.material != Imp) return false;
    value c_ = ImpClimb_d(i_.ImpClimb);
    
    value a1t;
    
    bool v_1;
    value v_2;
    v_2 = ALL_NOT_FOUND;
    v_2.material = None;
    v_1 = (c_ != v_2);
    bool v_3 = v_1;
    if(!v_3) return false;
    bool v_4;
    uint v_5;
    value v_6;
    v_6 = b_;
    int m_7 = 0;
    switch(m_7) { case 0:
        value v_8 = v_6;
        if(v_8.material != Ladder) break;
        v_5 = 1u;
        m_7 = 1;
    default: break; }
    switch(m_7) { case 0:
        value v_9 = v_6;
        v_5 = 0u;
        m_7 = 1;
    default: break; }
    if(m_7 == 0) return false;
    v_4 = (v_5 == 0u);
    bool v_10 = v_4;
    if(!v_10) return false;
    a1t = a_;
    value v_11;
    v_11 = i_;
    value v_12;
    v_12 = ALL_NOT_FOUND;
    v_12.material = None;
    v_11.ImpClimb = ImpClimb_e(v_12);
    a1t.Foreground = Foreground_e(v_11);
    
    a1 = a1t;
    return true;
}

bool ladderClimb_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Background == NOT_FOUND || a_.Foreground == NOT_FOUND) return false;
    value v_1 = Background_d(a_.Background);
    if(v_1.material != Ladder) return false;
    value v_2 = Foreground_d(a_.Foreground);
    if(v_2.material != None) return false;

    value b_ = a2;
    if(b_.Background == NOT_FOUND || b_.Foreground == NOT_FOUND) return false;
    value v_3 = Background_d(b_.Background);
    if(v_3.material != Ladder) return false;
    value i_ = Foreground_d(b_.Foreground);
    if(i_.ImpStep == NOT_FOUND || i_.ImpClimb == NOT_FOUND || i_.material != Imp) return false;
    uint v_4 = i_.ImpStep;
    if(v_4 != 2u) return false;
    value d_ = ImpClimb_d(i_.ImpClimb);
    
    value a1t;
    value a2t;
    
    bool v_5;
    value v_6;
    value v_7;
    v_7 = ALL_NOT_FOUND;
    v_7.material = Up;
    if(!rotate_f(seed, transform, v_7, v_6)) return false;
    v_5 = (d_ == v_6);
    bool v_8 = v_5;
    if(!v_8) return false;
    a1t = a_;
    value v_9;
    v_9 = i_;
    uint v_10;
    v_10 = 0u;
    if(v_10 >= 3u) return false;
    v_9.ImpStep = v_10;
    a1t.Foreground = Foreground_e(v_9);
    a2t = b_;
    value v_11;
    v_11 = ALL_NOT_FOUND;
    v_11.material = None;
    a2t.Foreground = Foreground_e(v_11);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool ladderSwap_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Background == NOT_FOUND || a_.Foreground == NOT_FOUND) return false;
    value v_1 = Background_d(a_.Background);
    if(v_1.material != Ladder) return false;
    value i1_ = Foreground_d(a_.Foreground);
    if(i1_.ImpStep == NOT_FOUND || i1_.ImpClimb == NOT_FOUND || i1_.material != Imp) return false;
    uint v_2 = i1_.ImpStep;
    if(v_2 != 2u) return false;
    value v_3 = ImpClimb_d(i1_.ImpClimb);
    if(v_3.material != Down) return false;

    value b_ = a2;
    if(b_.Background == NOT_FOUND || b_.Foreground == NOT_FOUND) return false;
    value v_4 = Background_d(b_.Background);
    if(v_4.material != Ladder) return false;
    value i2_ = Foreground_d(b_.Foreground);
    if(i2_.ImpStep == NOT_FOUND || i2_.ImpClimb == NOT_FOUND || i2_.material != Imp) return false;
    uint v_5 = i2_.ImpStep;
    if(v_5 != 2u) return false;
    value v_6 = ImpClimb_d(i2_.ImpClimb);
    if(v_6.material != Up) return false;
    
    value a1t;
    value a2t;
    
    a1t = a_;
    value v_7;
    v_7 = i2_;
    uint v_8;
    v_8 = 0u;
    if(v_8 >= 3u) return false;
    v_7.ImpStep = v_8;
    a1t.Foreground = Foreground_e(v_7);
    a2t = b_;
    value v_9;
    v_9 = i1_;
    uint v_10;
    v_10 = 0u;
    if(v_10 >= 3u) return false;
    v_9.ImpStep = v_10;
    a2t.Foreground = Foreground_e(v_9);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool chestPut_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value x_ = a1;
    if(x_.BuildingVariant == NOT_FOUND) return false;
    value b_ = BuildingVariant_d(x_.BuildingVariant);
    if(b_.BigContentCount == NOT_FOUND || b_.Content == NOT_FOUND || b_.material != BigChest) return false;
    uint n_ = b_.BigContentCount;
    value c_ = Content_d(b_.Content);

    value y_ = a2;
    if(y_.Foreground == NOT_FOUND) return false;
    value i_ = Foreground_d(y_.Foreground);
    if(i_.Content == NOT_FOUND || i_.ImpClimb == NOT_FOUND || i_.ImpStep == NOT_FOUND || i_.material != Imp) return false;
    value p_1_ = Content_d(i_.Content);
    value v_1 = ImpClimb_d(i_.ImpClimb);
    if(v_1.material != None) return false;
    uint v_2 = i_.ImpStep;
    if(v_2 != 2u) return false;
    
    value a1t;
    value a2t;
    
    bool v_3;
    v_3 = (p_1_ == c_);
    bool v_4 = v_3;
    if(!v_4) return false;
    bool v_5;
    value v_6;
    v_6 = ALL_NOT_FOUND;
    v_6.material = None;
    v_5 = (c_ != v_6);
    bool v_7 = v_5;
    if(!v_7) return false;
    a1t = x_;
    value v_8;
    v_8 = b_;
    uint v_9;
    v_9 = (n_ + 1u);
    if(v_9 >= 101u) return false;
    v_8.BigContentCount = v_9;
    a1t.BuildingVariant = BuildingVariant_e(v_8);
    a2t = y_;
    value v_10;
    v_10 = i_;
    value v_11;
    v_11 = ALL_NOT_FOUND;
    v_11.material = None;
    v_10.Content = Content_e(v_11);
    a2t.Foreground = Foreground_e(v_10);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

void main() {
    ivec2 position = ivec2(gl_FragCoord.xy - 0.5);
    ivec2 offset = (step % 2 == 0) ? ivec2(1, 1) : ivec2(0, 0);
    ivec2 bottomLeft = (position + offset) / 2 * 2 - offset;

    value a1 = lookupTile(bottomLeft + ivec2(-1, 2));
    value b1 = lookupTile(bottomLeft + ivec2(0, 2));
    value c1 = lookupTile(bottomLeft + ivec2(1, 2));
    value d1 = lookupTile(bottomLeft + ivec2(2, 2));
    value a2 = lookupTile(bottomLeft + ivec2(-1, 1));
    value b2 = lookupTile(bottomLeft + ivec2(0, 1));
    value c2 = lookupTile(bottomLeft + ivec2(1, 1));
    value d2 = lookupTile(bottomLeft + ivec2(2, 1));
    value a3 = lookupTile(bottomLeft + ivec2(-1, 0));
    value b3 = lookupTile(bottomLeft + ivec2(0, 0));
    value c3 = lookupTile(bottomLeft + ivec2(1, 0));
    value d3 = lookupTile(bottomLeft + ivec2(2, 0));
    value a4 = lookupTile(bottomLeft + ivec2(-1, -1));
    value b4 = lookupTile(bottomLeft + ivec2(0, -1));
    value c4 = lookupTile(bottomLeft + ivec2(1, -1));
    value d4 = lookupTile(bottomLeft + ivec2(2, -1));

    uint seed = uint(seedling) ^ Tile_e(a1);
    random(seed, 712387635u, 1u);
    seed ^= uint(position.x);
    random(seed, 611757929u, 1u);
    seed ^= uint(position.y);
    random(seed, 999260970u, 1u);

    // generateGroup
    bool generateGroup_d = false;
    bool generateCave_d = false;
    bool generateDig_d = false;
    bool generateChest_d = false;
    bool generateImps_d = false;
    if(true) {
        if(true) {
            seed ^= 108567334u;
            generateCave_d = generateCave_r(seed, 0u, b2) || generateCave_d;
            seed ^= 1869972635u;
            generateCave_d = generateCave_r(seed, 0u, c2) || generateCave_d;
            seed ^= 871070164u;
            generateCave_d = generateCave_r(seed, 0u, b3) || generateCave_d;
            seed ^= 223888653u;
            generateCave_d = generateCave_r(seed, 0u, c3) || generateCave_d;
            generateGroup_d = generateGroup_d || generateCave_d;
        }
        if(true) {
            seed ^= 108567334u;
            generateDig_d = generateDig_r(seed, 0u, b2) || generateDig_d;
            seed ^= 1869972635u;
            generateDig_d = generateDig_r(seed, 0u, c2) || generateDig_d;
            seed ^= 871070164u;
            generateDig_d = generateDig_r(seed, 0u, b3) || generateDig_d;
            seed ^= 223888653u;
            generateDig_d = generateDig_r(seed, 0u, c3) || generateDig_d;
            generateGroup_d = generateGroup_d || generateDig_d;
        }
        if(true) {
            seed ^= 108567334u;
            generateChest_d = generateChest_r(seed, 0u, b2) || generateChest_d;
            seed ^= 1869972635u;
            generateChest_d = generateChest_r(seed, 0u, c2) || generateChest_d;
            seed ^= 871070164u;
            generateChest_d = generateChest_r(seed, 0u, b3) || generateChest_d;
            seed ^= 223888653u;
            generateChest_d = generateChest_r(seed, 0u, c3) || generateChest_d;
            generateGroup_d = generateGroup_d || generateChest_d;
        }
        if(true) {
            value b2r = Foreground_d(b2.Foreground);
            value c2r = Foreground_d(c2.Foreground);
            value b3r = Foreground_d(b3.Foreground);
            value c3r = Foreground_d(c3.Foreground);
            seed ^= 108567334u;
            generateImps_d = generateImps_r(seed, 0u, b2r) || generateImps_d;
            seed ^= 1869972635u;
            generateImps_d = generateImps_r(seed, 0u, c2r) || generateImps_d;
            seed ^= 871070164u;
            generateImps_d = generateImps_r(seed, 0u, b3r) || generateImps_d;
            seed ^= 223888653u;
            generateImps_d = generateImps_r(seed, 0u, c3r) || generateImps_d;
            generateGroup_d = generateGroup_d || generateImps_d;
            b2.Foreground = Foreground_e(b2r);
            c2.Foreground = Foreground_e(c2r);
            b3.Foreground = Foreground_e(b3r);
            c3.Foreground = Foreground_e(c3r);
        }
    }

    // generateGroup2
    bool generateGroup2_d = false;
    bool generateCave2_d = false;
    bool generateLadder2_d = false;
    bool generateImp2_d = false;
    bool generateSign2a_d = false;
    bool generateSign2b_d = false;
    bool generatePlatform2_d = false;
    if(true) {
        if(true) {
            seed ^= 553515576u;
            generateCave2_d = generateCave2_r(seed, 0u, b2) || generateCave2_d;
            seed ^= 967788568u;
            generateCave2_d = generateCave2_r(seed, 0u, c2) || generateCave2_d;
            seed ^= 38663404u;
            generateCave2_d = generateCave2_r(seed, 0u, b3) || generateCave2_d;
            seed ^= 1348664957u;
            generateCave2_d = generateCave2_r(seed, 0u, c3) || generateCave2_d;
            generateGroup2_d = generateGroup2_d || generateCave2_d;
        }
        if(true) {
            seed ^= 553515576u;
            generateLadder2_d = generateLadder2_r(seed, 0u, b2) || generateLadder2_d;
            seed ^= 967788568u;
            generateLadder2_d = generateLadder2_r(seed, 0u, c2) || generateLadder2_d;
            seed ^= 38663404u;
            generateLadder2_d = generateLadder2_r(seed, 0u, b3) || generateLadder2_d;
            seed ^= 1348664957u;
            generateLadder2_d = generateLadder2_r(seed, 0u, c3) || generateLadder2_d;
            generateGroup2_d = generateGroup2_d || generateLadder2_d;
        }
        if(true) {
            seed ^= 553515576u;
            generateImp2_d = generateImp2_r(seed, 0u, b2) || generateImp2_d;
            seed ^= 967788568u;
            generateImp2_d = generateImp2_r(seed, 0u, c2) || generateImp2_d;
            seed ^= 38663404u;
            generateImp2_d = generateImp2_r(seed, 0u, b3) || generateImp2_d;
            seed ^= 1348664957u;
            generateImp2_d = generateImp2_r(seed, 0u, c3) || generateImp2_d;
            generateGroup2_d = generateGroup2_d || generateImp2_d;
        }
        if(true) {
            seed ^= 553515576u;
            generateSign2a_d = generateSign2a_r(seed, 0u, b2) || generateSign2a_d;
            seed ^= 967788568u;
            generateSign2a_d = generateSign2a_r(seed, 0u, c2) || generateSign2a_d;
            seed ^= 38663404u;
            generateSign2a_d = generateSign2a_r(seed, 0u, b3) || generateSign2a_d;
            seed ^= 1348664957u;
            generateSign2a_d = generateSign2a_r(seed, 0u, c3) || generateSign2a_d;
            generateGroup2_d = generateGroup2_d || generateSign2a_d;
        }
        if(true) {
            seed ^= 553515576u;
            generateSign2b_d = generateSign2b_r(seed, 0u, b2) || generateSign2b_d;
            seed ^= 967788568u;
            generateSign2b_d = generateSign2b_r(seed, 0u, c2) || generateSign2b_d;
            seed ^= 38663404u;
            generateSign2b_d = generateSign2b_r(seed, 0u, b3) || generateSign2b_d;
            seed ^= 1348664957u;
            generateSign2b_d = generateSign2b_r(seed, 0u, c3) || generateSign2b_d;
            generateGroup2_d = generateGroup2_d || generateSign2b_d;
        }
        if(true) {
            seed ^= 553515576u;
            generatePlatform2_d = generatePlatform2_r(seed, 0u, b2) || generatePlatform2_d;
            seed ^= 967788568u;
            generatePlatform2_d = generatePlatform2_r(seed, 0u, c2) || generatePlatform2_d;
            seed ^= 38663404u;
            generatePlatform2_d = generatePlatform2_r(seed, 0u, b3) || generatePlatform2_d;
            seed ^= 1348664957u;
            generatePlatform2_d = generatePlatform2_r(seed, 0u, c3) || generatePlatform2_d;
            generateGroup2_d = generateGroup2_d || generatePlatform2_d;
        }
    }

    // rockLightGroup
    bool rockLightGroup_d = false;
    bool rockLightBoundary_d = false;
    bool rockLight_d = false;
    if(true) {
        if(true) {
            seed ^= 668027963u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 0u, b2, b3) || rockLightBoundary_d;
            seed ^= 451520550u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 0u, c2, c3) || rockLightBoundary_d;
            seed ^= 573706912u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 90u, b3, c3) || rockLightBoundary_d;
            seed ^= 788956790u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 90u, b2, c2) || rockLightBoundary_d;
            seed ^= 1200244150u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 180u, c3, c2) || rockLightBoundary_d;
            seed ^= 1296423647u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 180u, b3, b2) || rockLightBoundary_d;
            seed ^= 673582934u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 270u, c2, b2) || rockLightBoundary_d;
            seed ^= 938113997u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 270u, c3, b3) || rockLightBoundary_d;
            rockLightGroup_d = rockLightGroup_d || rockLightBoundary_d;
        }
        if(true) {
            seed ^= 668027963u;
            rockLight_d = rockLight_r(seed, 0u, b2, b3) || rockLight_d;
            seed ^= 451520550u;
            rockLight_d = rockLight_r(seed, 0u, c2, c3) || rockLight_d;
            seed ^= 573706912u;
            rockLight_d = rockLight_r(seed, 90u, b3, c3) || rockLight_d;
            seed ^= 788956790u;
            rockLight_d = rockLight_r(seed, 90u, b2, c2) || rockLight_d;
            seed ^= 1200244150u;
            rockLight_d = rockLight_r(seed, 180u, c3, c2) || rockLight_d;
            seed ^= 1296423647u;
            rockLight_d = rockLight_r(seed, 180u, b3, b2) || rockLight_d;
            seed ^= 673582934u;
            rockLight_d = rockLight_r(seed, 270u, c2, b2) || rockLight_d;
            seed ^= 938113997u;
            rockLight_d = rockLight_r(seed, 270u, c3, b3) || rockLight_d;
            rockLightGroup_d = rockLightGroup_d || rockLight_d;
        }
    }

    // shaftGroup
    bool shaftGroup_d = false;
    bool shaftEnter_d = false;
    bool shaftExit_d = false;
    bool shaftSwapEnter_d = false;
    bool shaftDigEnter_d = false;
    bool shaftDig_d = false;
    bool shaftAscend_d = false;
    bool shaftDescend_d = false;
    bool shaftSwap_d = false;
    bool shaftRemove_d = false;
    if(!shaftGroup_d) {
        if(!shaftGroup_d) {
            seed ^= 1897446844u;
            shaftEnter_d = shaftEnter_d || shaftEnter_r(seed, 0u, b2, b3);
            seed ^= 678166483u;
            shaftEnter_d = shaftEnter_d || shaftEnter_r(seed, 0u, c2, c3);
            seed ^= 218212733u;
            shaftEnter_d = shaftEnter_d || shaftEnter_r(seed, 90u, b3, c3);
            seed ^= 1038273018u;
            shaftEnter_d = shaftEnter_d || shaftEnter_r(seed, 90u, b2, c2);
            seed ^= 547224797u;
            shaftEnter_d = shaftEnter_d || shaftEnter_r(seed, 180u, c3, c2);
            seed ^= 1754768770u;
            shaftEnter_d = shaftEnter_d || shaftEnter_r(seed, 180u, b3, b2);
            seed ^= 1619983794u;
            shaftEnter_d = shaftEnter_d || shaftEnter_r(seed, 270u, c2, b2);
            seed ^= 2062223264u;
            shaftEnter_d = shaftEnter_d || shaftEnter_r(seed, 270u, c3, b3);
            shaftGroup_d = shaftGroup_d || shaftEnter_d;
        }
        if(!shaftGroup_d) {
            seed ^= 1897446844u;
            shaftExit_d = shaftExit_d || shaftExit_r(seed, 0u, b2, b3);
            seed ^= 678166483u;
            shaftExit_d = shaftExit_d || shaftExit_r(seed, 0u, c2, c3);
            seed ^= 218212733u;
            shaftExit_d = shaftExit_d || shaftExit_r(seed, 90u, b3, c3);
            seed ^= 1038273018u;
            shaftExit_d = shaftExit_d || shaftExit_r(seed, 90u, b2, c2);
            seed ^= 547224797u;
            shaftExit_d = shaftExit_d || shaftExit_r(seed, 180u, c3, c2);
            seed ^= 1754768770u;
            shaftExit_d = shaftExit_d || shaftExit_r(seed, 180u, b3, b2);
            seed ^= 1619983794u;
            shaftExit_d = shaftExit_d || shaftExit_r(seed, 270u, c2, b2);
            seed ^= 2062223264u;
            shaftExit_d = shaftExit_d || shaftExit_r(seed, 270u, c3, b3);
            shaftGroup_d = shaftGroup_d || shaftExit_d;
        }
        if(!shaftGroup_d) {
            seed ^= 1897446844u;
            shaftSwapEnter_d = shaftSwapEnter_d || shaftSwapEnter_r(seed, 0u, b2, b3);
            seed ^= 678166483u;
            shaftSwapEnter_d = shaftSwapEnter_d || shaftSwapEnter_r(seed, 0u, c2, c3);
            seed ^= 218212733u;
            shaftSwapEnter_d = shaftSwapEnter_d || shaftSwapEnter_r(seed, 90u, b3, c3);
            seed ^= 1038273018u;
            shaftSwapEnter_d = shaftSwapEnter_d || shaftSwapEnter_r(seed, 90u, b2, c2);
            seed ^= 547224797u;
            shaftSwapEnter_d = shaftSwapEnter_d || shaftSwapEnter_r(seed, 180u, c3, c2);
            seed ^= 1754768770u;
            shaftSwapEnter_d = shaftSwapEnter_d || shaftSwapEnter_r(seed, 180u, b3, b2);
            seed ^= 1619983794u;
            shaftSwapEnter_d = shaftSwapEnter_d || shaftSwapEnter_r(seed, 270u, c2, b2);
            seed ^= 2062223264u;
            shaftSwapEnter_d = shaftSwapEnter_d || shaftSwapEnter_r(seed, 270u, c3, b3);
            shaftGroup_d = shaftGroup_d || shaftSwapEnter_d;
        }
        if(!shaftGroup_d) {
            seed ^= 1897446844u;
            shaftDigEnter_d = shaftDigEnter_d || shaftDigEnter_r(seed, 0u, b2, b3);
            seed ^= 678166483u;
            shaftDigEnter_d = shaftDigEnter_d || shaftDigEnter_r(seed, 0u, c2, c3);
            seed ^= 218212733u;
            shaftDigEnter_d = shaftDigEnter_d || shaftDigEnter_r(seed, 90u, b3, c3);
            seed ^= 1038273018u;
            shaftDigEnter_d = shaftDigEnter_d || shaftDigEnter_r(seed, 90u, b2, c2);
            seed ^= 547224797u;
            shaftDigEnter_d = shaftDigEnter_d || shaftDigEnter_r(seed, 180u, c3, c2);
            seed ^= 1754768770u;
            shaftDigEnter_d = shaftDigEnter_d || shaftDigEnter_r(seed, 180u, b3, b2);
            seed ^= 1619983794u;
            shaftDigEnter_d = shaftDigEnter_d || shaftDigEnter_r(seed, 270u, c2, b2);
            seed ^= 2062223264u;
            shaftDigEnter_d = shaftDigEnter_d || shaftDigEnter_r(seed, 270u, c3, b3);
            shaftGroup_d = shaftGroup_d || shaftDigEnter_d;
        }
        if(!shaftGroup_d) {
            seed ^= 1897446844u;
            shaftDig_d = shaftDig_d || shaftDig_r(seed, 0u, b2, b3);
            seed ^= 678166483u;
            shaftDig_d = shaftDig_d || shaftDig_r(seed, 0u, c2, c3);
            seed ^= 218212733u;
            shaftDig_d = shaftDig_d || shaftDig_r(seed, 90u, b3, c3);
            seed ^= 1038273018u;
            shaftDig_d = shaftDig_d || shaftDig_r(seed, 90u, b2, c2);
            seed ^= 547224797u;
            shaftDig_d = shaftDig_d || shaftDig_r(seed, 180u, c3, c2);
            seed ^= 1754768770u;
            shaftDig_d = shaftDig_d || shaftDig_r(seed, 180u, b3, b2);
            seed ^= 1619983794u;
            shaftDig_d = shaftDig_d || shaftDig_r(seed, 270u, c2, b2);
            seed ^= 2062223264u;
            shaftDig_d = shaftDig_d || shaftDig_r(seed, 270u, c3, b3);
            shaftGroup_d = shaftGroup_d || shaftDig_d;
        }
        if(!shaftGroup_d) {
            seed ^= 1897446844u;
            shaftAscend_d = shaftAscend_d || shaftAscend_r(seed, 0u, b2, b3);
            seed ^= 678166483u;
            shaftAscend_d = shaftAscend_d || shaftAscend_r(seed, 0u, c2, c3);
            seed ^= 218212733u;
            shaftAscend_d = shaftAscend_d || shaftAscend_r(seed, 90u, b3, c3);
            seed ^= 1038273018u;
            shaftAscend_d = shaftAscend_d || shaftAscend_r(seed, 90u, b2, c2);
            seed ^= 547224797u;
            shaftAscend_d = shaftAscend_d || shaftAscend_r(seed, 180u, c3, c2);
            seed ^= 1754768770u;
            shaftAscend_d = shaftAscend_d || shaftAscend_r(seed, 180u, b3, b2);
            seed ^= 1619983794u;
            shaftAscend_d = shaftAscend_d || shaftAscend_r(seed, 270u, c2, b2);
            seed ^= 2062223264u;
            shaftAscend_d = shaftAscend_d || shaftAscend_r(seed, 270u, c3, b3);
            shaftGroup_d = shaftGroup_d || shaftAscend_d;
        }
        if(!shaftGroup_d) {
            seed ^= 1897446844u;
            shaftDescend_d = shaftDescend_d || shaftDescend_r(seed, 0u, b2, b3);
            seed ^= 678166483u;
            shaftDescend_d = shaftDescend_d || shaftDescend_r(seed, 0u, c2, c3);
            seed ^= 218212733u;
            shaftDescend_d = shaftDescend_d || shaftDescend_r(seed, 90u, b3, c3);
            seed ^= 1038273018u;
            shaftDescend_d = shaftDescend_d || shaftDescend_r(seed, 90u, b2, c2);
            seed ^= 547224797u;
            shaftDescend_d = shaftDescend_d || shaftDescend_r(seed, 180u, c3, c2);
            seed ^= 1754768770u;
            shaftDescend_d = shaftDescend_d || shaftDescend_r(seed, 180u, b3, b2);
            seed ^= 1619983794u;
            shaftDescend_d = shaftDescend_d || shaftDescend_r(seed, 270u, c2, b2);
            seed ^= 2062223264u;
            shaftDescend_d = shaftDescend_d || shaftDescend_r(seed, 270u, c3, b3);
            shaftGroup_d = shaftGroup_d || shaftDescend_d;
        }
        if(!shaftGroup_d) {
            seed ^= 1897446844u;
            shaftSwap_d = shaftSwap_d || shaftSwap_r(seed, 0u, b2, b3);
            seed ^= 678166483u;
            shaftSwap_d = shaftSwap_d || shaftSwap_r(seed, 0u, c2, c3);
            seed ^= 218212733u;
            shaftSwap_d = shaftSwap_d || shaftSwap_r(seed, 90u, b3, c3);
            seed ^= 1038273018u;
            shaftSwap_d = shaftSwap_d || shaftSwap_r(seed, 90u, b2, c2);
            seed ^= 547224797u;
            shaftSwap_d = shaftSwap_d || shaftSwap_r(seed, 180u, c3, c2);
            seed ^= 1754768770u;
            shaftSwap_d = shaftSwap_d || shaftSwap_r(seed, 180u, b3, b2);
            seed ^= 1619983794u;
            shaftSwap_d = shaftSwap_d || shaftSwap_r(seed, 270u, c2, b2);
            seed ^= 2062223264u;
            shaftSwap_d = shaftSwap_d || shaftSwap_r(seed, 270u, c3, b3);
            shaftGroup_d = shaftGroup_d || shaftSwap_d;
        }
        if(!shaftGroup_d) {
            seed ^= 1897446844u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 0u, a1, b1, c1, a2, b2, c2, a3, b3, c3);
            seed ^= 678166483u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 0u, b1, c1, d1, b2, c2, d2, b3, c3, d3);
            seed ^= 218212733u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 0u, a2, b2, c2, a3, b3, c3, a4, b4, c4);
            seed ^= 1038273018u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 0u, b2, c2, d2, b3, c3, d3, b4, c4, d4);
            seed ^= 547224797u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 90u, a4, a3, a2, b4, b3, b2, c4, c3, c2);
            seed ^= 1754768770u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 90u, a3, a2, a1, b3, b2, b1, c3, c2, c1);
            seed ^= 1619983794u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 90u, b4, b3, b2, c4, c3, c2, d4, d3, d2);
            seed ^= 2062223264u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 90u, b3, b2, b1, c3, c2, c1, d3, d2, d1);
            seed ^= 1296675933u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 180u, d4, c4, b4, d3, c3, b3, d2, c2, b2);
            seed ^= 1405865444u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 180u, c4, b4, a4, c3, b3, a3, c2, b2, a2);
            seed ^= 114736504u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 180u, d3, c3, b3, d2, c2, b2, d1, c1, b1);
            seed ^= 1656983701u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 180u, c3, b3, a3, c2, b2, a2, c1, b1, a1);
            seed ^= 808013191u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 270u, d1, d2, d3, c1, c2, c3, b1, b2, b3);
            seed ^= 1715124762u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 270u, d2, d3, d4, c2, c3, c4, b2, b3, b4);
            seed ^= 954699684u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 270u, c1, c2, c3, b1, b2, b3, a1, a2, a3);
            seed ^= 2139848584u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 270u, c2, c3, c4, b2, b3, b4, a2, a3, a4);
            shaftGroup_d = shaftGroup_d || shaftRemove_d;
        }
    }

    // impMoveGroup
    bool impMoveGroup_d = false;
    bool impStep_d = false;
    bool impWalk_d = false;
    bool impFall_d = false;
    bool impSwap_d = false;
    bool impTurn_d = false;
    if(true) {
        if(true) {
            seed ^= 1400158356u;
            impStep_d = impStep_r(seed, 0u, b1, b2, b3) || impStep_d;
            seed ^= 1636801541u;
            impStep_d = impStep_r(seed, 0u, c1, c2, c3) || impStep_d;
            seed ^= 1662518182u;
            impStep_d = impStep_r(seed, 0u, b2, b3, b4) || impStep_d;
            seed ^= 1554008750u;
            impStep_d = impStep_r(seed, 0u, c2, c3, c4) || impStep_d;
            seed ^= 1683618445u;
            impStep_d = impStep_r(seed, 1u, c1, c2, c3) || impStep_d;
            seed ^= 434267189u;
            impStep_d = impStep_r(seed, 1u, b1, b2, b3) || impStep_d;
            seed ^= 60745904u;
            impStep_d = impStep_r(seed, 1u, c2, c3, c4) || impStep_d;
            seed ^= 1553039437u;
            impStep_d = impStep_r(seed, 1u, b2, b3, b4) || impStep_d;
            impMoveGroup_d = impMoveGroup_d || impStep_d;
        }
        if(!impStep_d) {
            seed ^= 1400158356u;
            impWalk_d = impWalk_r(seed, 0u, b1, c1, b2, c2, b3, c3) || impWalk_d;
            seed ^= 1636801541u;
            impWalk_d = impWalk_r(seed, 0u, b2, c2, b3, c3, b4, c4) || impWalk_d;
            seed ^= 1662518182u;
            impWalk_d = impWalk_r(seed, 1u, c1, b1, c2, b2, c3, b3) || impWalk_d;
            seed ^= 1554008750u;
            impWalk_d = impWalk_r(seed, 1u, c2, b2, c3, b3, c4, b4) || impWalk_d;
            impMoveGroup_d = impMoveGroup_d || impWalk_d;
        }
        if(true) {
            seed ^= 1400158356u;
            impFall_d = impFall_r(seed, 0u, b2, b3) || impFall_d;
            seed ^= 1636801541u;
            impFall_d = impFall_r(seed, 0u, c2, c3) || impFall_d;
            impMoveGroup_d = impMoveGroup_d || impFall_d;
        }
        if(true) {
            seed ^= 1400158356u;
            impSwap_d = impSwap_r(seed, 0u, b2, c2) || impSwap_d;
            seed ^= 1636801541u;
            impSwap_d = impSwap_r(seed, 0u, b3, c3) || impSwap_d;
            impMoveGroup_d = impMoveGroup_d || impSwap_d;
        }
        if(!impMoveGroup_d) {
            seed ^= 1400158356u;
            impTurn_d = impTurn_d || impTurn_r(seed, 0u, b1, c1, b2, c2, b3, c3);
            seed ^= 1636801541u;
            impTurn_d = impTurn_d || impTurn_r(seed, 0u, b2, c2, b3, c3, b4, c4);
            seed ^= 1662518182u;
            impTurn_d = impTurn_d || impTurn_r(seed, 1u, c1, b1, c2, b2, c3, b3);
            seed ^= 1554008750u;
            impTurn_d = impTurn_d || impTurn_r(seed, 1u, c2, b2, c3, b3, c4, b4);
            impMoveGroup_d = impMoveGroup_d || impTurn_d;
        }
    }

    // ladderGroup
    bool ladderGroup_d = false;
    bool ladderEnter_d = false;
    bool ladderExit_d = false;
    bool ladderCheck_d = false;
    bool ladderClimb_d = false;
    bool ladderSwap_d = false;
    if(true) {
        if(true) {
            seed ^= 1378456272u;
            ladderEnter_d = ladderEnter_r(seed, 0u, a2, b2, c2) || ladderEnter_d;
            seed ^= 616040093u;
            ladderEnter_d = ladderEnter_r(seed, 0u, b2, c2, d2) || ladderEnter_d;
            seed ^= 21812182u;
            ladderEnter_d = ladderEnter_r(seed, 0u, a3, b3, c3) || ladderEnter_d;
            seed ^= 1745414753u;
            ladderEnter_d = ladderEnter_r(seed, 0u, b3, c3, d3) || ladderEnter_d;
            seed ^= 954796937u;
            ladderEnter_d = ladderEnter_r(seed, 1u, d2, c2, b2) || ladderEnter_d;
            seed ^= 1189985483u;
            ladderEnter_d = ladderEnter_r(seed, 1u, c2, b2, a2) || ladderEnter_d;
            seed ^= 1819137208u;
            ladderEnter_d = ladderEnter_r(seed, 1u, d3, c3, b3) || ladderEnter_d;
            seed ^= 1500079685u;
            ladderEnter_d = ladderEnter_r(seed, 1u, c3, b3, a3) || ladderEnter_d;
            ladderGroup_d = ladderGroup_d || ladderEnter_d;
        }
        if(true) {
            seed ^= 1378456272u;
            ladderExit_d = ladderExit_r(seed, 0u, b1, b2, b3) || ladderExit_d;
            seed ^= 616040093u;
            ladderExit_d = ladderExit_r(seed, 0u, c1, c2, c3) || ladderExit_d;
            seed ^= 21812182u;
            ladderExit_d = ladderExit_r(seed, 0u, b2, b3, b4) || ladderExit_d;
            seed ^= 1745414753u;
            ladderExit_d = ladderExit_r(seed, 0u, c2, c3, c4) || ladderExit_d;
            seed ^= 954796937u;
            ladderExit_d = ladderExit_r(seed, 2u, b4, b3, b2) || ladderExit_d;
            seed ^= 1189985483u;
            ladderExit_d = ladderExit_r(seed, 2u, c4, c3, c2) || ladderExit_d;
            seed ^= 1819137208u;
            ladderExit_d = ladderExit_r(seed, 2u, b3, b2, b1) || ladderExit_d;
            seed ^= 1500079685u;
            ladderExit_d = ladderExit_r(seed, 2u, c3, c2, c1) || ladderExit_d;
            ladderGroup_d = ladderGroup_d || ladderExit_d;
        }
        if(true) {
            seed ^= 1378456272u;
            ladderCheck_d = ladderCheck_r(seed, 0u, b2) || ladderCheck_d;
            seed ^= 616040093u;
            ladderCheck_d = ladderCheck_r(seed, 0u, c2) || ladderCheck_d;
            seed ^= 21812182u;
            ladderCheck_d = ladderCheck_r(seed, 0u, b3) || ladderCheck_d;
            seed ^= 1745414753u;
            ladderCheck_d = ladderCheck_r(seed, 0u, c3) || ladderCheck_d;
            ladderGroup_d = ladderGroup_d || ladderCheck_d;
        }
        if(true) {
            seed ^= 1378456272u;
            ladderClimb_d = ladderClimb_r(seed, 0u, b2, b3) || ladderClimb_d;
            seed ^= 616040093u;
            ladderClimb_d = ladderClimb_r(seed, 0u, c2, c3) || ladderClimb_d;
            seed ^= 21812182u;
            ladderClimb_d = ladderClimb_r(seed, 2u, b3, b2) || ladderClimb_d;
            seed ^= 1745414753u;
            ladderClimb_d = ladderClimb_r(seed, 2u, c3, c2) || ladderClimb_d;
            ladderGroup_d = ladderGroup_d || ladderClimb_d;
        }
        if(true) {
            seed ^= 1378456272u;
            ladderSwap_d = ladderSwap_r(seed, 0u, b2, b3) || ladderSwap_d;
            seed ^= 616040093u;
            ladderSwap_d = ladderSwap_r(seed, 0u, c2, c3) || ladderSwap_d;
            ladderGroup_d = ladderGroup_d || ladderSwap_d;
        }
    }

    // chestGroup
    bool chestGroup_d = false;
    bool chestPut_d = false;
    if(true) {
        if(true) {
            seed ^= 719679085u;
            chestPut_d = chestPut_r(seed, 0u, b2, b3) || chestPut_d;
            seed ^= 1668133001u;
            chestPut_d = chestPut_r(seed, 0u, c2, c3) || chestPut_d;
            chestGroup_d = chestGroup_d || chestPut_d;
        }
    }

    // Write and encode own value
    ivec2 quadrant = position - bottomLeft;
    value target = b3;
    if(quadrant == ivec2(0, 1)) target = b2;
    else if(quadrant == ivec2(1, 0)) target = c3;
    else if(quadrant == ivec2(1, 1)) target = c2;
    outputValue = Tile_e(target);

}