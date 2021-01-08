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

// There are 624 different tiles

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
const uint SmallChest = 13u;
const uint BigChest = 14u;

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
    uint ImpStep;
    uint Content;
    uint SmallContentCount;
    uint BigContentCount;
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
);

uint Background_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Empty:
            break;
        case Scaffold:
            n *= 4u;
            n += v.DirectionHV;
            n += 1u;
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
        case Empty:
            n += 1u;
            break;
        case IronOre:
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

uint Foreground_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case CoalOre:
            break;
        case Empty:
            n += 1u;
            break;
        case Imp:
            n *= 4u;
            n += v.Content;
            n *= 2u;
            n += v.DirectionH;
            n *= 3u;
            n += v.ImpStep;
            n += 1u + 1u;
            break;
        case IronOre:
            n += 1u + 1u + 24u;
            break;
        case RockOre:
            n += 1u + 1u + 24u + 1u;
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
            n *= 5u;
            n += v.Background;
            n *= 28u;
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
            n += 448u + 140u;
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
        v.material = Empty;
        return v;
    }
    n -= 1u;
    if(n < 4u) {
        v.material = Scaffold;
        v.DirectionHV = n % 4u;
        n /= 4u;
        return v;
    }
    n -= 4u;
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
        v.material = Empty;
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

value Foreground_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 1u) {
        v.material = CoalOre;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Empty;
        return v;
    }
    n -= 1u;
    if(n < 24u) {
        v.material = Imp;
        v.ImpStep = n % 3u;
        n /= 3u;
        v.DirectionH = n % 2u;
        n /= 2u;
        v.Content = n % 4u;
        n /= 4u;
        return v;
    }
    n -= 24u;
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

value Tile_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 448u) {
        v.material = Building;
        v.BuildingVariant = n % 448u;
        n /= 448u;
        return v;
    }
    n -= 448u;
    if(n < 140u) {
        v.material = Cave;
        v.Foreground = n % 28u;
        n /= 28u;
        v.Background = n % 5u;
        n /= 5u;
        return v;
    }
    n -= 140u;
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
    v_16.material = Empty;
    a1t.Foreground = Foreground_e(v_16);
    value v_17;
    v_17 = ALL_NOT_FOUND;
    v_17.material = Empty;
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

bool generateImp1_r(inout uint seed, uint transform, inout value a1) {
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
    v_6 = (v_8 == 9u);
    v_3 = (v_5 && v_6);
    bool v_4;
    uint v_9;
    v_9 = uint(gl_FragCoord.y - 0.5);
    v_4 = (v_9 == 7u);
    v_2 = (v_3 && v_4);
    bool v_10 = v_2;
    if(!v_10) return false;
    a1t = ALL_NOT_FOUND;
    a1t.material = Imp;
    value v_11;
    v_11 = ALL_NOT_FOUND;
    v_11.material = Left;
    a1t.DirectionH = DirectionH_e(v_11);
    uint v_12;
    v_12 = 0u;
    if(v_12 >= 3u) return false;
    a1t.ImpStep = v_12;
    value v_13;
    v_13 = ALL_NOT_FOUND;
    v_13.material = Empty;
    a1t.Content = Content_e(v_13);
    
    a1 = a1t;
    return true;
}

bool generateImp2_r(inout uint seed, uint transform, inout value a1) {
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
    v_6 = (v_8 == 11u);
    v_3 = (v_5 && v_6);
    bool v_4;
    uint v_9;
    v_9 = uint(gl_FragCoord.y - 0.5);
    v_4 = (v_9 == 6u);
    v_2 = (v_3 && v_4);
    bool v_10 = v_2;
    if(!v_10) return false;
    a1t = ALL_NOT_FOUND;
    a1t.material = Imp;
    value v_11;
    v_11 = ALL_NOT_FOUND;
    v_11.material = Right;
    a1t.DirectionH = DirectionH_e(v_11);
    uint v_12;
    v_12 = 0u;
    if(v_12 >= 3u) return false;
    a1t.ImpStep = v_12;
    value v_13;
    v_13 = ALL_NOT_FOUND;
    v_13.material = Empty;
    a1t.Content = Content_e(v_13);
    
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

bool impDig_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Dig == NOT_FOUND || a_.Vein == NOT_FOUND || a_.material != Rock) return false;
    uint v_1 = a_.Dig;
    if(v_1 != 1u) return false;
    value ore_ = Vein_d(a_.Vein);

    value b_ = a2;
    if(b_.Foreground == NOT_FOUND) return false;
    value i_ = Foreground_d(b_.Foreground);
    if(i_.Content == NOT_FOUND || i_.ImpStep == NOT_FOUND || i_.material != Imp) return false;
    value v_2 = Content_d(i_.Content);
    if(v_2.material != Empty) return false;
    uint v_3 = i_.ImpStep;
    if(v_3 != 2u) return false;
    
    value a1t;
    value a2t;
    
    a1t = ALL_NOT_FOUND;
    a1t.material = Cave;
    value v_4;
    v_4 = i_;
    uint v_5;
    v_5 = 0u;
    if(v_5 >= 3u) return false;
    v_4.ImpStep = v_5;
    value v_6;
    v_6 = ore_;
    v_4.Content = Content_e(v_6);
    a1t.Foreground = Foreground_e(v_4);
    value v_7;
    v_7 = ALL_NOT_FOUND;
    v_7.material = Scaffold;
    value v_8;
    value v_9;
    v_9 = ALL_NOT_FOUND;
    v_9.material = Up;
    if(!rotate_f(seed, transform, v_9, v_8)) return false;
    v_7.DirectionHV = DirectionHV_e(v_8);
    a1t.Background = Background_e(v_7);
    a2t = b_;
    value v_10;
    v_10 = ALL_NOT_FOUND;
    v_10.material = Empty;
    a2t.Foreground = Foreground_e(v_10);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool impAscendScaffold_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Background == NOT_FOUND || a_.Foreground == NOT_FOUND) return false;
    value v_1 = Background_d(a_.Background);
    if(v_1.DirectionHV == NOT_FOUND || v_1.material != Scaffold) return false;
    value d_ = DirectionHV_d(v_1.DirectionHV);
    value v_2 = Foreground_d(a_.Foreground);
    if(v_2.material != Empty) return false;

    value b_ = a2;
    if(b_.Foreground == NOT_FOUND) return false;
    value i_ = Foreground_d(b_.Foreground);
    if(i_.Content == NOT_FOUND || i_.material != Imp) return false;
    value v_3 = Content_d(i_.Content);
    if(v_3.material != Empty) return false;
    
    value a1t;
    value a2t;
    
    bool v_4;
    value v_5;
    value v_6;
    v_6 = ALL_NOT_FOUND;
    v_6.material = Up;
    if(!rotate_f(seed, transform, v_6, v_5)) return false;
    v_4 = (d_ == v_5);
    bool v_7 = v_4;
    if(!v_7) return false;
    a1t = a_;
    value v_8;
    v_8 = i_;
    a1t.Foreground = Foreground_e(v_8);
    a2t = b_;
    value v_9;
    v_9 = ALL_NOT_FOUND;
    v_9.material = Empty;
    a2t.Foreground = Foreground_e(v_9);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool impDescendScaffold_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Background == NOT_FOUND || a_.Foreground == NOT_FOUND) return false;
    value v_1 = Background_d(a_.Background);
    if(v_1.DirectionHV == NOT_FOUND || v_1.material != Scaffold) return false;
    value d_ = DirectionHV_d(v_1.DirectionHV);
    value i_ = Foreground_d(a_.Foreground);
    if(i_.Content == NOT_FOUND || i_.material != Imp) return false;
    value c_ = Content_d(i_.Content);

    value b_ = a2;
    if(b_.Foreground == NOT_FOUND) return false;
    value v_2 = Foreground_d(b_.Foreground);
    if(v_2.material != Empty) return false;
    
    value a1t;
    value a2t;
    
    bool v_3;
    bool v_4;
    value v_6;
    value v_7;
    v_7 = ALL_NOT_FOUND;
    v_7.material = Up;
    if(!rotate_f(seed, transform, v_7, v_6)) return false;
    v_4 = (d_ == v_6);
    bool v_5;
    value v_8;
    v_8 = ALL_NOT_FOUND;
    v_8.material = Empty;
    v_5 = (c_ != v_8);
    v_3 = (v_4 && v_5);
    bool v_9 = v_3;
    if(!v_9) return false;
    a1t = a_;
    value v_10;
    v_10 = ALL_NOT_FOUND;
    v_10.material = Empty;
    a1t.Foreground = Foreground_e(v_10);
    a2t = b_;
    value v_11;
    v_11 = i_;
    a2t.Foreground = Foreground_e(v_11);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool impRemoveScaffold_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Background == NOT_FOUND || a_.Foreground == NOT_FOUND) return false;
    value v_1 = Background_d(a_.Background);
    if(v_1.DirectionHV == NOT_FOUND || v_1.material != Scaffold) return false;
    value d_ = DirectionHV_d(v_1.DirectionHV);
    value i_ = Foreground_d(a_.Foreground);
    if(i_.Content == NOT_FOUND || i_.material != Imp) return false;
    value v_2 = Content_d(i_.Content);
    if(v_2.material != Empty) return false;

    value b_ = a2;
    if(b_.Foreground == NOT_FOUND) return false;
    value v_3 = Foreground_d(b_.Foreground);
    if(v_3.material != Empty) return false;
    
    value a1t;
    value a2t;
    
    bool v_4;
    value v_5;
    value v_6;
    v_6 = ALL_NOT_FOUND;
    v_6.material = Up;
    if(!rotate_f(seed, transform, v_6, v_5)) return false;
    v_4 = (d_ == v_5);
    bool v_7 = v_4;
    if(!v_7) return false;
    a1t = a_;
    value v_8;
    v_8 = ALL_NOT_FOUND;
    v_8.material = Empty;
    a1t.Foreground = Foreground_e(v_8);
    value v_9;
    v_9 = ALL_NOT_FOUND;
    v_9.material = Empty;
    a1t.Background = Background_e(v_9);
    a2t = b_;
    value v_10;
    v_10 = i_;
    a2t.Foreground = Foreground_e(v_10);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool impSwapScaffold_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Background == NOT_FOUND || a_.Foreground == NOT_FOUND) return false;
    value v_1 = Background_d(a_.Background);
    if(v_1.DirectionHV == NOT_FOUND || v_1.material != Scaffold) return false;
    value d_ = DirectionHV_d(v_1.DirectionHV);
    value i1_ = Foreground_d(a_.Foreground);
    if(i1_.Content == NOT_FOUND || i1_.material != Imp) return false;
    value c_ = Content_d(i1_.Content);

    value b_ = a2;
    if(b_.Foreground == NOT_FOUND) return false;
    value i2_ = Foreground_d(b_.Foreground);
    if(i2_.Content == NOT_FOUND || i2_.material != Imp) return false;
    value v_2 = Content_d(i2_.Content);
    if(v_2.material != Empty) return false;
    
    value a1t;
    value a2t;
    
    bool v_3;
    bool v_4;
    value v_6;
    value v_7;
    v_7 = ALL_NOT_FOUND;
    v_7.material = Up;
    if(!rotate_f(seed, transform, v_7, v_6)) return false;
    v_4 = (d_ == v_6);
    bool v_5;
    value v_8;
    v_8 = ALL_NOT_FOUND;
    v_8.material = Empty;
    v_5 = (c_ != v_8);
    v_3 = (v_4 && v_5);
    bool v_9 = v_3;
    if(!v_9) return false;
    a1t = a_;
    value v_10;
    v_10 = i2_;
    a1t.Foreground = Foreground_e(v_10);
    a2t = b_;
    value v_11;
    v_11 = i1_;
    a2t.Foreground = Foreground_e(v_11);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool impScaffold_r(inout uint seed, uint transform, inout value a1) {
    value a_ = a1;
    if(a_.Background == NOT_FOUND) return false;
    value v_1 = Background_d(a_.Background);
    if(v_1.material != Scaffold) return false;
    
    value a1t;
    
    a1t = a_;
    
    a1 = a1t;
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

    value v_2 = b3;
    if(v_2.material != Rock) return false;
    
    value b2t;
    
    bool v_3;
    value v_4;
    value v_5;
    v_5 = ALL_NOT_FOUND;
    v_5.material = Right;
    if(!rotate_f(seed, transform, v_5, v_4)) return false;
    v_3 = (d_ == v_4);
    bool v_6 = v_3;
    if(!v_6) return false;
    b2t = a_;
    value v_7;
    v_7 = i_;
    uint v_8;
    v_8 = (s_ + 1u);
    if(v_8 >= 3u) return false;
    v_7.ImpStep = v_8;
    b2t.Foreground = Foreground_e(v_7);
    
    b2 = b2t;
    return true;
}

bool impWalk_r(inout uint seed, uint transform, value b1, value c1, inout value b2, inout value c2, value b3, value c3) {
    value v_1 = b1;

    value v_2 = c1;

    value a_ = b2;
    if(a_.Foreground == NOT_FOUND) return false;
    value i_ = Foreground_d(a_.Foreground);
    if(i_.DirectionH == NOT_FOUND || i_.ImpStep == NOT_FOUND || i_.material != Imp) return false;
    value d_ = DirectionH_d(i_.DirectionH);
    uint v_3 = i_.ImpStep;
    if(v_3 != 2u) return false;

    value b_ = c2;
    if(b_.Foreground == NOT_FOUND) return false;
    value v_4 = Foreground_d(b_.Foreground);
    if(v_4.material != Empty) return false;

    value v_5 = b3;
    if(v_5.material != Rock) return false;

    value v_6 = c3;
    if(v_6.material != Rock) return false;
    
    value b2t;
    value c2t;
    
    bool v_7;
    value v_8;
    value v_9;
    v_9 = ALL_NOT_FOUND;
    v_9.material = Right;
    if(!rotate_f(seed, transform, v_9, v_8)) return false;
    v_7 = (d_ == v_8);
    bool v_10 = v_7;
    if(!v_10) return false;
    b2t = a_;
    value v_11;
    v_11 = ALL_NOT_FOUND;
    v_11.material = Empty;
    b2t.Foreground = Foreground_e(v_11);
    c2t = b_;
    value v_12;
    v_12 = i_;
    uint v_13;
    v_13 = 0u;
    if(v_13 >= 3u) return false;
    v_12.ImpStep = v_13;
    c2t.Foreground = Foreground_e(v_12);
    
    b2 = b2t;
    c2 = c2t;
    return true;
}

bool impFall_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Foreground == NOT_FOUND) return false;
    value i_ = Foreground_d(a_.Foreground);
    if(i_.material != Imp) return false;

    value b_ = a2;
    if(b_.Foreground == NOT_FOUND) return false;
    value v_1 = Foreground_d(b_.Foreground);
    if(v_1.material != Empty) return false;
    
    value a1t;
    value a2t;
    
    a1t = a_;
    value v_2;
    v_2 = ALL_NOT_FOUND;
    v_2.material = Empty;
    a1t.Foreground = Foreground_e(v_2);
    a2t = b_;
    value v_3;
    v_3 = i_;
    a2t.Foreground = Foreground_e(v_3);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool impSwap_r(inout uint seed, uint transform, inout value a1, inout value b1) {
    value a_ = a1;
    if(a_.Foreground == NOT_FOUND) return false;
    value i1_ = Foreground_d(a_.Foreground);
    if(i1_.DirectionH == NOT_FOUND || i1_.ImpStep == NOT_FOUND || i1_.material != Imp) return false;
    value v_1 = DirectionH_d(i1_.DirectionH);
    if(v_1.material != Right) return false;
    uint v_2 = i1_.ImpStep;
    if(v_2 != 2u) return false;

    value b_ = b1;
    if(b_.Foreground == NOT_FOUND) return false;
    value i2_ = Foreground_d(b_.Foreground);
    if(i2_.DirectionH == NOT_FOUND || i2_.ImpStep == NOT_FOUND || i2_.material != Imp) return false;
    value v_3 = DirectionH_d(i2_.DirectionH);
    if(v_3.material != Left) return false;
    uint v_4 = i2_.ImpStep;
    if(v_4 != 2u) return false;
    
    value a1t;
    value b1t;
    
    a1t = a_;
    value v_5;
    v_5 = i2_;
    uint v_6;
    v_6 = 0u;
    if(v_6 >= 3u) return false;
    v_5.ImpStep = v_6;
    a1t.Foreground = Foreground_e(v_5);
    b1t = b_;
    value v_7;
    v_7 = i1_;
    uint v_8;
    v_8 = 0u;
    if(v_8 >= 3u) return false;
    v_7.ImpStep = v_8;
    b1t.Foreground = Foreground_e(v_7);
    
    a1 = a1t;
    b1 = b1t;
    return true;
}

bool impTurn_r(inout uint seed, uint transform, inout value a1, inout value b1) {
    value a_ = a1;
    if(a_.Foreground == NOT_FOUND) return false;
    value i_ = Foreground_d(a_.Foreground);
    if(i_.DirectionH == NOT_FOUND || i_.ImpStep == NOT_FOUND || i_.material != Imp) return false;
    value d_ = DirectionH_d(i_.DirectionH);
    uint v_1 = i_.ImpStep;
    if(v_1 != 2u) return false;

    value b_ = b1;
    if(b_.material != Rock) return false;
    
    value a1t;
    value b1t;
    
    bool v_2;
    value v_3;
    value v_4;
    v_4 = ALL_NOT_FOUND;
    v_4.material = Right;
    if(!rotate_f(seed, transform, v_4, v_3)) return false;
    v_2 = (d_ == v_3);
    bool v_5 = v_2;
    if(!v_5) return false;
    a1t = a_;
    value v_6;
    v_6 = i_;
    uint v_7;
    v_7 = 0u;
    if(v_7 >= 3u) return false;
    v_6.ImpStep = v_7;
    value v_8;
    value v_9;
    v_9 = ALL_NOT_FOUND;
    v_9.material = Left;
    if(!rotate_f(seed, transform, v_9, v_8)) return false;
    v_6.DirectionH = DirectionH_e(v_8);
    a1t.Foreground = Foreground_e(v_6);
    b1t = b_;
    
    a1 = a1t;
    b1 = b1t;
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
    if(i_.Content == NOT_FOUND || i_.ImpStep == NOT_FOUND || i_.material != Imp) return false;
    value p_1_ = Content_d(i_.Content);
    uint v_1 = i_.ImpStep;
    if(v_1 != 2u) return false;
    
    value a1t;
    value a2t;
    
    bool v_2;
    v_2 = (p_1_ == c_);
    bool v_3 = v_2;
    if(!v_3) return false;
    bool v_4;
    value v_5;
    v_5 = ALL_NOT_FOUND;
    v_5.material = Empty;
    v_4 = (c_ != v_5);
    bool v_6 = v_4;
    if(!v_6) return false;
    a1t = x_;
    value v_7;
    v_7 = b_;
    uint v_8;
    v_8 = (n_ + 1u);
    if(v_8 >= 101u) return false;
    v_7.BigContentCount = v_8;
    a1t.BuildingVariant = BuildingVariant_e(v_7);
    a2t = y_;
    value v_9;
    v_9 = i_;
    value v_10;
    v_10 = ALL_NOT_FOUND;
    v_10.material = Empty;
    v_9.Content = Content_e(v_10);
    a2t.Foreground = Foreground_e(v_9);
    
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
    bool generateImp1_d = false;
    bool generateImp2_d = false;
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
            generateImp1_d = generateImp1_r(seed, 0u, b2r) || generateImp1_d;
            seed ^= 1869972635u;
            generateImp1_d = generateImp1_r(seed, 0u, c2r) || generateImp1_d;
            seed ^= 871070164u;
            generateImp1_d = generateImp1_r(seed, 0u, b3r) || generateImp1_d;
            seed ^= 223888653u;
            generateImp1_d = generateImp1_r(seed, 0u, c3r) || generateImp1_d;
            generateGroup_d = generateGroup_d || generateImp1_d;
            b2.Foreground = Foreground_e(b2r);
            c2.Foreground = Foreground_e(c2r);
            b3.Foreground = Foreground_e(b3r);
            c3.Foreground = Foreground_e(c3r);
        }
        if(true) {
            value b2r = Foreground_d(b2.Foreground);
            value c2r = Foreground_d(c2.Foreground);
            value b3r = Foreground_d(b3.Foreground);
            value c3r = Foreground_d(c3.Foreground);
            seed ^= 108567334u;
            generateImp2_d = generateImp2_r(seed, 0u, b2r) || generateImp2_d;
            seed ^= 1869972635u;
            generateImp2_d = generateImp2_r(seed, 0u, c2r) || generateImp2_d;
            seed ^= 871070164u;
            generateImp2_d = generateImp2_r(seed, 0u, b3r) || generateImp2_d;
            seed ^= 223888653u;
            generateImp2_d = generateImp2_r(seed, 0u, c3r) || generateImp2_d;
            generateGroup_d = generateGroup_d || generateImp2_d;
            b2.Foreground = Foreground_e(b2r);
            c2.Foreground = Foreground_e(c2r);
            b3.Foreground = Foreground_e(b3r);
            c3.Foreground = Foreground_e(c3r);
        }
    }

    // rockLightGroup
    bool rockLightGroup_d = false;
    bool rockLightBoundary_d = false;
    bool rockLight_d = false;
    if(true) {
        if(true) {
            seed ^= 1965700965u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 0u, b2, b3) || rockLightBoundary_d;
            seed ^= 403662498u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 0u, c2, c3) || rockLightBoundary_d;
            seed ^= 1838484050u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 90u, b3, c3) || rockLightBoundary_d;
            seed ^= 1654912608u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 90u, b2, c2) || rockLightBoundary_d;
            seed ^= 1662033536u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 180u, c3, c2) || rockLightBoundary_d;
            seed ^= 138260616u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 180u, b3, b2) || rockLightBoundary_d;
            seed ^= 1108898331u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 270u, c2, b2) || rockLightBoundary_d;
            seed ^= 814132782u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 270u, c3, b3) || rockLightBoundary_d;
            rockLightGroup_d = rockLightGroup_d || rockLightBoundary_d;
        }
        if(true) {
            seed ^= 1965700965u;
            rockLight_d = rockLight_r(seed, 0u, b2, b3) || rockLight_d;
            seed ^= 403662498u;
            rockLight_d = rockLight_r(seed, 0u, c2, c3) || rockLight_d;
            seed ^= 1838484050u;
            rockLight_d = rockLight_r(seed, 90u, b3, c3) || rockLight_d;
            seed ^= 1654912608u;
            rockLight_d = rockLight_r(seed, 90u, b2, c2) || rockLight_d;
            seed ^= 1662033536u;
            rockLight_d = rockLight_r(seed, 180u, c3, c2) || rockLight_d;
            seed ^= 138260616u;
            rockLight_d = rockLight_r(seed, 180u, b3, b2) || rockLight_d;
            seed ^= 1108898331u;
            rockLight_d = rockLight_r(seed, 270u, c2, b2) || rockLight_d;
            seed ^= 814132782u;
            rockLight_d = rockLight_r(seed, 270u, c3, b3) || rockLight_d;
            rockLightGroup_d = rockLightGroup_d || rockLight_d;
        }
    }

    // impDigGroup
    bool impDigGroup_d = false;
    bool impDig_d = false;
    bool impAscendScaffold_d = false;
    bool impDescendScaffold_d = false;
    bool impRemoveScaffold_d = false;
    bool impSwapScaffold_d = false;
    if(!impDigGroup_d) {
        if(!impDigGroup_d) {
            seed ^= 1025993662u;
            impDig_d = impDig_d || impDig_r(seed, 0u, b2, b3);
            seed ^= 631725343u;
            impDig_d = impDig_d || impDig_r(seed, 0u, c2, c3);
            seed ^= 705055956u;
            impDig_d = impDig_d || impDig_r(seed, 90u, b3, c3);
            seed ^= 1110559074u;
            impDig_d = impDig_d || impDig_r(seed, 90u, b2, c2);
            seed ^= 780986482u;
            impDig_d = impDig_d || impDig_r(seed, 180u, c3, c2);
            seed ^= 522073420u;
            impDig_d = impDig_d || impDig_r(seed, 180u, b3, b2);
            seed ^= 1777778722u;
            impDig_d = impDig_d || impDig_r(seed, 270u, c2, b2);
            seed ^= 1222822196u;
            impDig_d = impDig_d || impDig_r(seed, 270u, c3, b3);
            impDigGroup_d = impDigGroup_d || impDig_d;
        }
        if(!impDigGroup_d) {
            seed ^= 1025993662u;
            impAscendScaffold_d = impAscendScaffold_d || impAscendScaffold_r(seed, 0u, b2, b3);
            seed ^= 631725343u;
            impAscendScaffold_d = impAscendScaffold_d || impAscendScaffold_r(seed, 0u, c2, c3);
            seed ^= 705055956u;
            impAscendScaffold_d = impAscendScaffold_d || impAscendScaffold_r(seed, 90u, b3, c3);
            seed ^= 1110559074u;
            impAscendScaffold_d = impAscendScaffold_d || impAscendScaffold_r(seed, 90u, b2, c2);
            seed ^= 780986482u;
            impAscendScaffold_d = impAscendScaffold_d || impAscendScaffold_r(seed, 180u, c3, c2);
            seed ^= 522073420u;
            impAscendScaffold_d = impAscendScaffold_d || impAscendScaffold_r(seed, 180u, b3, b2);
            seed ^= 1777778722u;
            impAscendScaffold_d = impAscendScaffold_d || impAscendScaffold_r(seed, 270u, c2, b2);
            seed ^= 1222822196u;
            impAscendScaffold_d = impAscendScaffold_d || impAscendScaffold_r(seed, 270u, c3, b3);
            impDigGroup_d = impDigGroup_d || impAscendScaffold_d;
        }
        if(!impDigGroup_d) {
            seed ^= 1025993662u;
            impDescendScaffold_d = impDescendScaffold_d || impDescendScaffold_r(seed, 0u, b2, b3);
            seed ^= 631725343u;
            impDescendScaffold_d = impDescendScaffold_d || impDescendScaffold_r(seed, 0u, c2, c3);
            seed ^= 705055956u;
            impDescendScaffold_d = impDescendScaffold_d || impDescendScaffold_r(seed, 90u, b3, c3);
            seed ^= 1110559074u;
            impDescendScaffold_d = impDescendScaffold_d || impDescendScaffold_r(seed, 90u, b2, c2);
            seed ^= 780986482u;
            impDescendScaffold_d = impDescendScaffold_d || impDescendScaffold_r(seed, 180u, c3, c2);
            seed ^= 522073420u;
            impDescendScaffold_d = impDescendScaffold_d || impDescendScaffold_r(seed, 180u, b3, b2);
            seed ^= 1777778722u;
            impDescendScaffold_d = impDescendScaffold_d || impDescendScaffold_r(seed, 270u, c2, b2);
            seed ^= 1222822196u;
            impDescendScaffold_d = impDescendScaffold_d || impDescendScaffold_r(seed, 270u, c3, b3);
            impDigGroup_d = impDigGroup_d || impDescendScaffold_d;
        }
        if(!impDigGroup_d) {
            seed ^= 1025993662u;
            impRemoveScaffold_d = impRemoveScaffold_d || impRemoveScaffold_r(seed, 0u, b2, b3);
            seed ^= 631725343u;
            impRemoveScaffold_d = impRemoveScaffold_d || impRemoveScaffold_r(seed, 0u, c2, c3);
            seed ^= 705055956u;
            impRemoveScaffold_d = impRemoveScaffold_d || impRemoveScaffold_r(seed, 90u, b3, c3);
            seed ^= 1110559074u;
            impRemoveScaffold_d = impRemoveScaffold_d || impRemoveScaffold_r(seed, 90u, b2, c2);
            seed ^= 780986482u;
            impRemoveScaffold_d = impRemoveScaffold_d || impRemoveScaffold_r(seed, 180u, c3, c2);
            seed ^= 522073420u;
            impRemoveScaffold_d = impRemoveScaffold_d || impRemoveScaffold_r(seed, 180u, b3, b2);
            seed ^= 1777778722u;
            impRemoveScaffold_d = impRemoveScaffold_d || impRemoveScaffold_r(seed, 270u, c2, b2);
            seed ^= 1222822196u;
            impRemoveScaffold_d = impRemoveScaffold_d || impRemoveScaffold_r(seed, 270u, c3, b3);
            impDigGroup_d = impDigGroup_d || impRemoveScaffold_d;
        }
        if(!impDigGroup_d) {
            seed ^= 1025993662u;
            impSwapScaffold_d = impSwapScaffold_d || impSwapScaffold_r(seed, 0u, b2, b3);
            seed ^= 631725343u;
            impSwapScaffold_d = impSwapScaffold_d || impSwapScaffold_r(seed, 0u, c2, c3);
            seed ^= 705055956u;
            impSwapScaffold_d = impSwapScaffold_d || impSwapScaffold_r(seed, 90u, b3, c3);
            seed ^= 1110559074u;
            impSwapScaffold_d = impSwapScaffold_d || impSwapScaffold_r(seed, 90u, b2, c2);
            seed ^= 780986482u;
            impSwapScaffold_d = impSwapScaffold_d || impSwapScaffold_r(seed, 180u, c3, c2);
            seed ^= 522073420u;
            impSwapScaffold_d = impSwapScaffold_d || impSwapScaffold_r(seed, 180u, b3, b2);
            seed ^= 1777778722u;
            impSwapScaffold_d = impSwapScaffold_d || impSwapScaffold_r(seed, 270u, c2, b2);
            seed ^= 1222822196u;
            impSwapScaffold_d = impSwapScaffold_d || impSwapScaffold_r(seed, 270u, c3, b3);
            impDigGroup_d = impDigGroup_d || impSwapScaffold_d;
        }
    }

    // impMoveGroup
    bool impMoveGroup_d = false;
    bool impScaffold_d = false;
    bool impStep_d = false;
    bool impWalk_d = false;
    bool impFall_d = false;
    bool impSwap_d = false;
    bool impTurn_d = false;
    if(true) {
        if(true) {
            seed ^= 1897446844u;
            impScaffold_d = impScaffold_r(seed, 0u, b2) || impScaffold_d;
            seed ^= 678166483u;
            impScaffold_d = impScaffold_r(seed, 0u, c2) || impScaffold_d;
            seed ^= 218212733u;
            impScaffold_d = impScaffold_r(seed, 0u, b3) || impScaffold_d;
            seed ^= 1038273018u;
            impScaffold_d = impScaffold_r(seed, 0u, c3) || impScaffold_d;
            impMoveGroup_d = impMoveGroup_d || impScaffold_d;
        }
        if(!impScaffold_d) {
            seed ^= 1897446844u;
            impStep_d = impStep_r(seed, 0u, b1, b2, b3) || impStep_d;
            seed ^= 678166483u;
            impStep_d = impStep_r(seed, 0u, c1, c2, c3) || impStep_d;
            seed ^= 218212733u;
            impStep_d = impStep_r(seed, 0u, b2, b3, b4) || impStep_d;
            seed ^= 1038273018u;
            impStep_d = impStep_r(seed, 0u, c2, c3, c4) || impStep_d;
            seed ^= 547224797u;
            impStep_d = impStep_r(seed, 1u, c1, c2, c3) || impStep_d;
            seed ^= 1754768770u;
            impStep_d = impStep_r(seed, 1u, b1, b2, b3) || impStep_d;
            seed ^= 1619983794u;
            impStep_d = impStep_r(seed, 1u, c2, c3, c4) || impStep_d;
            seed ^= 2062223264u;
            impStep_d = impStep_r(seed, 1u, b2, b3, b4) || impStep_d;
            impMoveGroup_d = impMoveGroup_d || impStep_d;
        }
        if(!impStep_d && !impScaffold_d) {
            seed ^= 1897446844u;
            impWalk_d = impWalk_r(seed, 0u, b1, c1, b2, c2, b3, c3) || impWalk_d;
            seed ^= 678166483u;
            impWalk_d = impWalk_r(seed, 0u, b2, c2, b3, c3, b4, c4) || impWalk_d;
            seed ^= 218212733u;
            impWalk_d = impWalk_r(seed, 1u, c1, b1, c2, b2, c3, b3) || impWalk_d;
            seed ^= 1038273018u;
            impWalk_d = impWalk_r(seed, 1u, c2, b2, c3, b3, c4, b4) || impWalk_d;
            impMoveGroup_d = impMoveGroup_d || impWalk_d;
        }
        if(!impScaffold_d) {
            seed ^= 1897446844u;
            impFall_d = impFall_r(seed, 0u, b2, b3) || impFall_d;
            seed ^= 678166483u;
            impFall_d = impFall_r(seed, 0u, c2, c3) || impFall_d;
            impMoveGroup_d = impMoveGroup_d || impFall_d;
        }
        if(!impScaffold_d) {
            seed ^= 1897446844u;
            impSwap_d = impSwap_r(seed, 0u, b2, c2) || impSwap_d;
            seed ^= 678166483u;
            impSwap_d = impSwap_r(seed, 0u, b3, c3) || impSwap_d;
            impMoveGroup_d = impMoveGroup_d || impSwap_d;
        }
        if(!impMoveGroup_d) {
            seed ^= 1897446844u;
            impTurn_d = impTurn_d || impTurn_r(seed, 0u, b2, c2);
            seed ^= 678166483u;
            impTurn_d = impTurn_d || impTurn_r(seed, 0u, b3, c3);
            seed ^= 218212733u;
            impTurn_d = impTurn_d || impTurn_r(seed, 1u, c2, b2);
            seed ^= 1038273018u;
            impTurn_d = impTurn_d || impTurn_r(seed, 1u, c3, b3);
            impMoveGroup_d = impMoveGroup_d || impTurn_d;
        }
    }

    // chestGroup
    bool chestGroup_d = false;
    bool chestPut_d = false;
    if(true) {
        if(true) {
            seed ^= 534822373u;
            chestPut_d = chestPut_r(seed, 0u, b2, b3) || chestPut_d;
            seed ^= 550619774u;
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