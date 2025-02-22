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

// There are 2150 different tiles

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
const uint Wood = 13u;
const uint Sand = 14u;
const uint Water = 15u;
const uint Imp = 16u;
const uint SmallChest = 17u;
const uint BigChest = 18u;
const uint Campfire = 19u;
const uint FactorySide = 20u;
const uint FactoryTop = 21u;
const uint FactoryBottom = 22u;
const uint Platform = 23u;
const uint Ladder = 24u;
const uint Sign = 25u;

struct value {
    uint material;
    uint Tile;
    uint Weight;
    uint Rolling;
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
    uint CampfireFuel;
    uint ShaftForeground;
    uint FactorySideCount;
    uint FactoryFedLeft;
    uint FactoryFedRight;
    uint FactoryCountdown;
    uint FactoryProduced;
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
        case Platform:
            n += 1u + 1u;
            break;
        case Sign:
            n *= 2u;
            n += v.DirectionV;
            n += 1u + 1u + 1u;
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
            n *= 7u;
            n += v.Content;
            break;
        case Campfire:
            n *= 101u;
            n += v.CampfireFuel;
            n += 707u;
            break;
        case FactoryBottom:
            n *= 7u;
            n += v.Content;
            n *= 2u;
            n += v.FactoryFedLeft;
            n *= 2u;
            n += v.FactoryFedRight;
            n *= 11u;
            n += v.FactoryProduced;
            n += 707u + 101u;
            break;
        case FactorySide:
            n *= 7u;
            n += v.Content;
            n *= 2u;
            n += v.DirectionH;
            n *= 2u;
            n += v.DirectionV;
            n *= 6u;
            n += v.FactorySideCount;
            n += 707u + 101u + 308u;
            break;
        case FactoryTop:
            n *= 11u;
            n += v.FactoryCountdown;
            n *= 2u;
            n += v.FactoryFedLeft;
            n *= 2u;
            n += v.FactoryFedRight;
            n += 707u + 101u + 308u + 168u;
            break;
        case SmallChest:
            n *= 7u;
            n += v.Content;
            n *= 11u;
            n += v.SmallContentCount;
            n += 707u + 101u + 308u + 168u + 44u;
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
        case Sand:
            n += 1u + 1u + 1u + 1u;
            break;
        case Water:
            n += 1u + 1u + 1u + 1u + 1u;
            break;
        case Wood:
            n += 1u + 1u + 1u + 1u + 1u + 1u;
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
            n *= 7u;
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
            n += 1u + 126u;
            break;
        case None:
            n += 1u + 126u + 1u;
            break;
        case RockOre:
            n += 1u + 126u + 1u + 1u;
            break;
        case Sand:
            n += 1u + 126u + 1u + 1u + 1u;
            break;
        case Water:
            n += 1u + 126u + 1u + 1u + 1u + 1u;
            break;
        case Wood:
            n += 1u + 126u + 1u + 1u + 1u + 1u + 1u;
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
            n *= 7u;
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
            n *= 1405u;
            n += v.BuildingVariant;
            break;
        case Cave:
            n *= 5u;
            n += v.Background;
            n *= 133u;
            n += v.Foreground;
            n += 1405u;
            break;
        case Rock:
            n *= 2u;
            n += v.Dig;
            n *= 6u;
            n += v.Light;
            n *= 4u;
            n += v.Vein;
            n += 1405u + 665u;
            break;
        case Shaft:
            n *= 4u;
            n += v.DirectionHV;
            n *= 8u;
            n += v.ShaftForeground;
            n += 1405u + 665u + 48u;
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
        case Wood:
            n += 1u + 1u + 1u;
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
        v.Weight = 0u;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Platform;
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
    if(n < 707u) {
        v.material = BigChest;
        v.Content = n % 7u;
        n /= 7u;
        v.BigContentCount = n % 101u;
        n /= 101u;
        return v;
    }
    n -= 707u;
    if(n < 101u) {
        v.material = Campfire;
        v.CampfireFuel = n % 101u;
        n /= 101u;
        return v;
    }
    n -= 101u;
    if(n < 308u) {
        v.material = FactoryBottom;
        v.FactoryProduced = n % 11u;
        n /= 11u;
        v.FactoryFedRight = n % 2u;
        n /= 2u;
        v.FactoryFedLeft = n % 2u;
        n /= 2u;
        v.Content = n % 7u;
        n /= 7u;
        return v;
    }
    n -= 308u;
    if(n < 168u) {
        v.material = FactorySide;
        v.FactorySideCount = n % 6u;
        n /= 6u;
        v.DirectionV = n % 2u;
        n /= 2u;
        v.DirectionH = n % 2u;
        n /= 2u;
        v.Content = n % 7u;
        n /= 7u;
        return v;
    }
    n -= 168u;
    if(n < 44u) {
        v.material = FactoryTop;
        v.FactoryFedRight = n % 2u;
        n /= 2u;
        v.FactoryFedLeft = n % 2u;
        n /= 2u;
        v.FactoryCountdown = n % 11u;
        n /= 11u;
        return v;
    }
    n -= 44u;
    if(n < 77u) {
        v.material = SmallChest;
        v.SmallContentCount = n % 11u;
        n /= 11u;
        v.Content = n % 7u;
        n /= 7u;
        return v;
    }
    n -= 77u;
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
        v.Weight = 0u;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = RockOre;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Sand;
        v.Rolling = 0u;
        v.Weight = 3u;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Water;
        v.Rolling = 0u;
        v.Weight = 2u;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Wood;
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
    if(n < 126u) {
        v.material = Imp;
        v.Weight = 1u;
        v.ImpStep = n % 3u;
        n /= 3u;
        v.ImpClimb = n % 3u;
        n /= 3u;
        v.DirectionH = n % 2u;
        n /= 2u;
        v.Content = n % 7u;
        n /= 7u;
        return v;
    }
    n -= 126u;
    if(n < 1u) {
        v.material = IronOre;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = None;
        v.Weight = 0u;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = RockOre;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Sand;
        v.Rolling = 0u;
        v.Weight = 3u;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Water;
        v.Rolling = 0u;
        v.Weight = 2u;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = Wood;
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
        v.Weight = 0u;
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
        v.Weight = 0u;
        return v;
    }
    n -= 1u;
    if(n < 7u) {
        v.material = ShaftImp;
        v.Content = n % 7u;
        n /= 7u;
        return v;
    }
    n -= 7u;
    return v;
}

value Tile_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 1405u) {
        v.material = Building;
        v.BuildingVariant = n % 1405u;
        n /= 1405u;
        return v;
    }
    n -= 1405u;
    if(n < 665u) {
        v.material = Cave;
        v.Foreground = n % 133u;
        n /= 133u;
        v.Background = n % 5u;
        n /= 5u;
        return v;
    }
    n -= 665u;
    if(n < 48u) {
        v.material = Rock;
        v.Vein = n % 4u;
        n /= 4u;
        v.Light = n % 6u;
        n /= 6u;
        v.Dig = n % 2u;
        n /= 2u;
        return v;
    }
    n -= 48u;
    if(n < 32u) {
        v.material = Shaft;
        v.ShaftForeground = n % 8u;
        n /= 8u;
        v.DirectionHV = n % 4u;
        n /= 4u;
        return v;
    }
    n -= 32u;
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
    if(n < 1u) {
        v.material = Wood;
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
        if(v_6.material != Platform) break;
        v_1 = 1u;
        m_3 = 1;
    default: break; }
    switch(m_3) { case 0:
        value v_7 = v_2;
        if(v_7.Background == NOT_FOUND) break;
        value v_8 = Background_d(v_7.Background);
        if(v_8.material != Ladder) break;
        v_1 = 1u;
        m_3 = 1;
    default: break; }
    switch(m_3) { case 0:
        value v_9 = v_2;
        if(v_9.material != Building) break;
        v_1 = 1u;
        m_3 = 1;
    default: break; }
    switch(m_3) { case 0:
        value v_10 = v_2;
        if(v_10.material != Shaft) break;
        v_1 = 1u;
        m_3 = 1;
    default: break; }
    switch(m_3) { case 0:
        value v_11 = v_2;
        v_1 = 0u;
        m_3 = 1;
    default: break; }
    if(m_3 == 0) return false;
    result = (v_1 == 1u);
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

void ladderGroup_g(inout bool ladderGroup_d, inout uint seed, inout value a1, inout value b1, inout value c1, inout value d1, inout value a2, inout value b2, inout value c2, inout value d2, inout value a3, inout value b3, inout value c3, inout value d3, inout value a4, inout value b4, inout value c4, inout value d4) {
    bool ladderEnter_d = false;
    bool ladderExit_d = false;
    bool ladderCheck_d = false;
    bool ladderClimb_d = false;
    bool ladderSwap_d = false;
    seed ^= 108567334u;
    ladderEnter_d = ladderEnter_r(seed, 0u, a2, b2, c2) || ladderEnter_d;
    seed ^= 1869972635u;
    ladderEnter_d = ladderEnter_r(seed, 0u, b2, c2, d2) || ladderEnter_d;
    seed ^= 871070164u;
    ladderEnter_d = ladderEnter_r(seed, 0u, a3, b3, c3) || ladderEnter_d;
    seed ^= 223888653u;
    ladderEnter_d = ladderEnter_r(seed, 0u, b3, c3, d3) || ladderEnter_d;
    seed ^= 1967264300u;
    ladderEnter_d = ladderEnter_r(seed, 1u, d2, c2, b2) || ladderEnter_d;
    seed ^= 1956845781u;
    ladderEnter_d = ladderEnter_r(seed, 1u, c2, b2, a2) || ladderEnter_d;
    seed ^= 2125574876u;
    ladderEnter_d = ladderEnter_r(seed, 1u, d3, c3, b3) || ladderEnter_d;
    seed ^= 1273636163u;
    ladderEnter_d = ladderEnter_r(seed, 1u, c3, b3, a3) || ladderEnter_d;
    ladderGroup_d = ladderGroup_d || ladderEnter_d;
    seed ^= 108567334u;
    ladderExit_d = ladderExit_r(seed, 0u, b1, b2, b3) || ladderExit_d;
    seed ^= 1869972635u;
    ladderExit_d = ladderExit_r(seed, 0u, c1, c2, c3) || ladderExit_d;
    seed ^= 871070164u;
    ladderExit_d = ladderExit_r(seed, 0u, b2, b3, b4) || ladderExit_d;
    seed ^= 223888653u;
    ladderExit_d = ladderExit_r(seed, 0u, c2, c3, c4) || ladderExit_d;
    seed ^= 1967264300u;
    ladderExit_d = ladderExit_r(seed, 2u, b4, b3, b2) || ladderExit_d;
    seed ^= 1956845781u;
    ladderExit_d = ladderExit_r(seed, 2u, c4, c3, c2) || ladderExit_d;
    seed ^= 2125574876u;
    ladderExit_d = ladderExit_r(seed, 2u, b3, b2, b1) || ladderExit_d;
    seed ^= 1273636163u;
    ladderExit_d = ladderExit_r(seed, 2u, c3, c2, c1) || ladderExit_d;
    ladderGroup_d = ladderGroup_d || ladderExit_d;
    seed ^= 108567334u;
    ladderCheck_d = ladderCheck_r(seed, 0u, b2) || ladderCheck_d;
    seed ^= 1869972635u;
    ladderCheck_d = ladderCheck_r(seed, 0u, c2) || ladderCheck_d;
    seed ^= 871070164u;
    ladderCheck_d = ladderCheck_r(seed, 0u, b3) || ladderCheck_d;
    seed ^= 223888653u;
    ladderCheck_d = ladderCheck_r(seed, 0u, c3) || ladderCheck_d;
    ladderGroup_d = ladderGroup_d || ladderCheck_d;
    seed ^= 108567334u;
    ladderClimb_d = ladderClimb_r(seed, 0u, b2, b3) || ladderClimb_d;
    seed ^= 1869972635u;
    ladderClimb_d = ladderClimb_r(seed, 0u, c2, c3) || ladderClimb_d;
    seed ^= 871070164u;
    ladderClimb_d = ladderClimb_r(seed, 2u, b3, b2) || ladderClimb_d;
    seed ^= 223888653u;
    ladderClimb_d = ladderClimb_r(seed, 2u, c3, c2) || ladderClimb_d;
    ladderGroup_d = ladderGroup_d || ladderClimb_d;
    seed ^= 108567334u;
    ladderSwap_d = ladderSwap_r(seed, 0u, b2, b3) || ladderSwap_d;
    seed ^= 1869972635u;
    ladderSwap_d = ladderSwap_r(seed, 0u, c2, c3) || ladderSwap_d;
    ladderGroup_d = ladderGroup_d || ladderSwap_d;
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

    bool ladderGroup_d = false;

    ladderGroup_g(ladderGroup_d, seed, a1, b1, c1, d1, a2, b2, c2, d2, a3, b3, c3, d3, a4, b4, c4, d4);

    // Write and encode own value
    ivec2 quadrant = position - bottomLeft;
    value target = b3;
    if(quadrant == ivec2(0, 1)) target = b2;
    else if(quadrant == ivec2(1, 0)) target = c3;
    else if(quadrant == ivec2(1, 1)) target = c2;
    outputValue = Tile_e(target);

}