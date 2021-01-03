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

// There are 140 different tiles

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
            n += 1u + 1u;
            break;
        case IronOre:
            n += 1u + 1u + 8u;
            break;
        case RockOre:
            n += 1u + 1u + 8u + 1u;
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
            break;
        case Cave:
            n *= 5u;
            n += v.Background;
            n *= 12u;
            n += v.Foreground;
            n += 44u;
            break;
        case Rock:
            n *= 2u;
            n += v.Dig;
            n *= 6u;
            n += v.Light;
            n *= 3u;
            n += v.Vein;
            n += 44u + 60u;
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
    if(n < 44u) {
        v.material = Chest;
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
    if(n < 8u) {
        v.material = Imp;
        v.DirectionH = n % 2u;
        n /= 2u;
        v.Content = n % 4u;
        n /= 4u;
        return v;
    }
    n -= 8u;
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
    if(n < 44u) {
        v.material = Building;
        v.BuildingVariant = n % 44u;
        n /= 44u;
        return v;
    }
    n -= 44u;
    if(n < 60u) {
        v.material = Cave;
        v.Foreground = n % 12u;
        n /= 12u;
        v.Background = n % 5u;
        n /= 5u;
        return v;
    }
    n -= 60u;
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
    v_16.material = IronOre;
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
    value v_12;
    v_12 = ALL_NOT_FOUND;
    v_12.material = Empty;
    a1t.Content = Content_e(v_12);
    
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
    value v_12;
    v_12 = ALL_NOT_FOUND;
    v_12.material = Empty;
    a1t.Content = Content_e(v_12);
    
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
    value v_7;
    v_7 = ALL_NOT_FOUND;
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

bool impWalk_r(inout uint seed, uint transform, value a1, value b1, inout value a2, inout value b2, value a3, value b3) {
    value v_1 = a1;

    value v_2 = b1;

    value a_ = a2;
    if(a_.Foreground == NOT_FOUND) return false;
    value i_ = Foreground_d(a_.Foreground);
    if(i_.DirectionH == NOT_FOUND || i_.material != Imp) return false;
    value d_ = DirectionH_d(i_.DirectionH);

    value b_ = b2;
    if(b_.Foreground == NOT_FOUND) return false;
    value v_3 = Foreground_d(b_.Foreground);
    if(v_3.material != Empty) return false;

    value v_4 = a3;
    if(v_4.material != Rock) return false;

    value v_5 = b3;
    if(v_5.material != Rock) return false;
    
    value a2t;
    value b2t;
    
    bool v_6;
    value v_7;
    value v_8;
    v_8 = ALL_NOT_FOUND;
    v_8.material = Right;
    if(!rotate_f(seed, transform, v_8, v_7)) return false;
    v_6 = (d_ == v_7);
    bool v_9 = v_6;
    if(!v_9) return false;
    a2t = a_;
    value v_10;
    v_10 = ALL_NOT_FOUND;
    v_10.material = Empty;
    a2t.Foreground = Foreground_e(v_10);
    b2t = b_;
    value v_11;
    v_11 = i_;
    b2t.Foreground = Foreground_e(v_11);
    
    a2 = a2t;
    b2 = b2t;
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

bool impTurn_r(inout uint seed, uint transform, inout value a1) {
    value i_ = a1;
    if(i_.DirectionH == NOT_FOUND || i_.material != Imp) return false;
    value d_ = DirectionH_d(i_.DirectionH);
    
    value a1t;
    
    bool v_1;
    value v_2;
    value v_3;
    v_3 = ALL_NOT_FOUND;
    v_3.material = Right;
    if(!rotate_f(seed, transform, v_3, v_2)) return false;
    v_1 = (d_ == v_2);
    bool v_4 = v_1;
    if(!v_4) return false;
    a1t = i_;
    value v_5;
    value v_6;
    v_6 = ALL_NOT_FOUND;
    v_6.material = Left;
    if(!rotate_f(seed, transform, v_6, v_5)) return false;
    a1t.DirectionH = DirectionH_e(v_5);
    
    a1 = a1t;
    return true;
}

void main() {
    ivec2 position = ivec2(gl_FragCoord.xy - 0.5);
    ivec2 offset = (step % 2 == 0) ? ivec2(1, 1) : ivec2(0, 0);
    ivec2 bottomLeft = (position + offset) / 2 * 2 - offset;

    value a1 = lookupTile(bottomLeft + ivec2(0, 2));
    value b1 = lookupTile(bottomLeft + ivec2(1, 2));
    value a2 = lookupTile(bottomLeft + ivec2(0, 1));
    value b2 = lookupTile(bottomLeft + ivec2(1, 1));
    value a3 = lookupTile(bottomLeft + ivec2(0, 0));
    value b3 = lookupTile(bottomLeft + ivec2(1, 0));
    value a4 = lookupTile(bottomLeft + ivec2(0, -1));
    value b4 = lookupTile(bottomLeft + ivec2(1, -1));

    uint seed = uint(seedling) ^ Tile_e(a1);
    random(seed, 712387635u, 1u);
    seed ^= uint(position.x);
    random(seed, 611757929u, 1u);
    seed ^= uint(position.y);
    random(seed, 999260970u, 1u);

    // generateGroup
    bool generateGroup_d = false;
    bool generateCave_d = false;
    bool generateImp1_d = false;
    bool generateImp2_d = false;
    if(true) {
        if(true) {
            seed ^= 108567334u;
            generateCave_d = generateCave_r(seed, 0u, a2) || generateCave_d;
            seed ^= 1869972635u;
            generateCave_d = generateCave_r(seed, 0u, a3) || generateCave_d;
            seed ^= 871070164u;
            generateCave_d = generateCave_r(seed, 0u, b2) || generateCave_d;
            seed ^= 223888653u;
            generateCave_d = generateCave_r(seed, 0u, b3) || generateCave_d;
            generateGroup_d = generateGroup_d || generateCave_d;
        }
        if(true) {
            value a2r = Foreground_d(a2.Foreground);
            value b2r = Foreground_d(b2.Foreground);
            value a3r = Foreground_d(a3.Foreground);
            value b3r = Foreground_d(b3.Foreground);
            seed ^= 108567334u;
            generateImp1_d = generateImp1_r(seed, 0u, a2r) || generateImp1_d;
            seed ^= 1869972635u;
            generateImp1_d = generateImp1_r(seed, 0u, a3r) || generateImp1_d;
            seed ^= 871070164u;
            generateImp1_d = generateImp1_r(seed, 0u, b2r) || generateImp1_d;
            seed ^= 223888653u;
            generateImp1_d = generateImp1_r(seed, 0u, b3r) || generateImp1_d;
            generateGroup_d = generateGroup_d || generateImp1_d;
            a2.Foreground = Foreground_e(a2r);
            b2.Foreground = Foreground_e(b2r);
            a3.Foreground = Foreground_e(a3r);
            b3.Foreground = Foreground_e(b3r);
        }
        if(true) {
            value a2r = Foreground_d(a2.Foreground);
            value b2r = Foreground_d(b2.Foreground);
            value a3r = Foreground_d(a3.Foreground);
            value b3r = Foreground_d(b3.Foreground);
            seed ^= 108567334u;
            generateImp2_d = generateImp2_r(seed, 0u, a2r) || generateImp2_d;
            seed ^= 1869972635u;
            generateImp2_d = generateImp2_r(seed, 0u, a3r) || generateImp2_d;
            seed ^= 871070164u;
            generateImp2_d = generateImp2_r(seed, 0u, b2r) || generateImp2_d;
            seed ^= 223888653u;
            generateImp2_d = generateImp2_r(seed, 0u, b3r) || generateImp2_d;
            generateGroup_d = generateGroup_d || generateImp2_d;
            a2.Foreground = Foreground_e(a2r);
            b2.Foreground = Foreground_e(b2r);
            a3.Foreground = Foreground_e(a3r);
            b3.Foreground = Foreground_e(b3r);
        }
    }

    // rockLightGroup
    bool rockLightGroup_d = false;
    bool rockLightBoundary_d = false;
    bool rockLight_d = false;
    if(true) {
        if(true) {
            seed ^= 1182492532u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 0u, a2, a3) || rockLightBoundary_d;
            seed ^= 371095097u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 0u, b2, b3) || rockLightBoundary_d;
            seed ^= 1627330604u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 90u, a2, b2) || rockLightBoundary_d;
            seed ^= 1899154792u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 90u, a3, b3) || rockLightBoundary_d;
            seed ^= 1040173492u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 180u, a3, a2) || rockLightBoundary_d;
            seed ^= 1480988120u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 180u, b3, b2) || rockLightBoundary_d;
            seed ^= 675397029u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 270u, b2, a2) || rockLightBoundary_d;
            seed ^= 935024481u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 270u, b3, a3) || rockLightBoundary_d;
            rockLightGroup_d = rockLightGroup_d || rockLightBoundary_d;
        }
        if(true) {
            seed ^= 1182492532u;
            rockLight_d = rockLight_r(seed, 0u, a2, a3) || rockLight_d;
            seed ^= 371095097u;
            rockLight_d = rockLight_r(seed, 0u, b2, b3) || rockLight_d;
            seed ^= 1627330604u;
            rockLight_d = rockLight_r(seed, 90u, a2, b2) || rockLight_d;
            seed ^= 1899154792u;
            rockLight_d = rockLight_r(seed, 90u, a3, b3) || rockLight_d;
            seed ^= 1040173492u;
            rockLight_d = rockLight_r(seed, 180u, a3, a2) || rockLight_d;
            seed ^= 1480988120u;
            rockLight_d = rockLight_r(seed, 180u, b3, b2) || rockLight_d;
            seed ^= 675397029u;
            rockLight_d = rockLight_r(seed, 270u, b2, a2) || rockLight_d;
            seed ^= 935024481u;
            rockLight_d = rockLight_r(seed, 270u, b3, a3) || rockLight_d;
            rockLightGroup_d = rockLightGroup_d || rockLight_d;
        }
    }

    // impDigGroup
    bool impDigGroup_d = false;
    bool impDig_d = false;
    if(true) {
        if(true) {
            seed ^= 1965700965u;
            impDig_d = impDig_r(seed, 0u, a2, a3) || impDig_d;
            seed ^= 403662498u;
            impDig_d = impDig_r(seed, 0u, b2, b3) || impDig_d;
            seed ^= 1838484050u;
            impDig_d = impDig_r(seed, 90u, a2, b2) || impDig_d;
            seed ^= 1654912608u;
            impDig_d = impDig_r(seed, 90u, a3, b3) || impDig_d;
            seed ^= 1662033536u;
            impDig_d = impDig_r(seed, 180u, a3, a2) || impDig_d;
            seed ^= 138260616u;
            impDig_d = impDig_r(seed, 180u, b3, b2) || impDig_d;
            seed ^= 1108898331u;
            impDig_d = impDig_r(seed, 270u, b2, a2) || impDig_d;
            seed ^= 814132782u;
            impDig_d = impDig_r(seed, 270u, b3, a3) || impDig_d;
            impDigGroup_d = impDigGroup_d || impDig_d;
        }
    }

    // impMoveGroup
    bool impMoveGroup_d = false;
    bool impWalk_d = false;
    bool impFall_d = false;
    bool impTurn_d = false;
    if(true) {
        if(true) {
            seed ^= 57574703u;
            impWalk_d = impWalk_r(seed, 0u, a1, b1, a2, b2, a3, b3) || impWalk_d;
            seed ^= 783035197u;
            impWalk_d = impWalk_r(seed, 0u, a2, b2, a3, b3, a4, b4) || impWalk_d;
            seed ^= 981880051u;
            impWalk_d = impWalk_r(seed, 1u, b3, a3, b2, a2, b1, a1) || impWalk_d;
            seed ^= 582833299u;
            impWalk_d = impWalk_r(seed, 1u, b4, a4, b3, a3, b2, a2) || impWalk_d;
            impMoveGroup_d = impMoveGroup_d || impWalk_d;
        }
        if(true) {
            seed ^= 57574703u;
            impFall_d = impFall_r(seed, 0u, a2, a3) || impFall_d;
            seed ^= 783035197u;
            impFall_d = impFall_r(seed, 0u, b2, b3) || impFall_d;
            impMoveGroup_d = impMoveGroup_d || impFall_d;
        }
        if(!impWalk_d && !impFall_d) {
            value a2r = Foreground_d(a2.Foreground);
            value b2r = Foreground_d(b2.Foreground);
            value a3r = Foreground_d(a3.Foreground);
            value b3r = Foreground_d(b3.Foreground);
            seed ^= 57574703u;
            impTurn_d = impTurn_r(seed, 0u, a2r) || impTurn_d;
            seed ^= 783035197u;
            impTurn_d = impTurn_r(seed, 0u, a3r) || impTurn_d;
            seed ^= 981880051u;
            impTurn_d = impTurn_r(seed, 0u, b2r) || impTurn_d;
            seed ^= 582833299u;
            impTurn_d = impTurn_r(seed, 0u, b3r) || impTurn_d;
            seed ^= 1314288539u;
            impTurn_d = impTurn_r(seed, 1u, a2r) || impTurn_d;
            seed ^= 78912146u;
            impTurn_d = impTurn_r(seed, 1u, a3r) || impTurn_d;
            seed ^= 637777041u;
            impTurn_d = impTurn_r(seed, 1u, b2r) || impTurn_d;
            seed ^= 1840999258u;
            impTurn_d = impTurn_r(seed, 1u, b3r) || impTurn_d;
            impMoveGroup_d = impMoveGroup_d || impTurn_d;
            a2.Foreground = Foreground_e(a2r);
            b2.Foreground = Foreground_e(b2r);
            a3.Foreground = Foreground_e(a3r);
            b3.Foreground = Foreground_e(b3r);
        }
    }

    // Write and encode own value
    ivec2 quadrant = position - bottomLeft;
    value target = a3;
    if(quadrant == ivec2(0, 1)) target = a2;
    else if(quadrant == ivec2(1, 0)) target = b3;
    else if(quadrant == ivec2(1, 1)) target = b2;
    outputValue = Tile_e(target);

}