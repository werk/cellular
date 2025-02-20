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
    bool v_4;
    value v_6;
    v_6 = ALL_NOT_FOUND;
    v_6.material = Ladder;
    v_4 = (l_ != v_6);
    bool v_5;
    value v_7;
    v_7 = ALL_NOT_FOUND;
    v_7.material = Platform;
    v_5 = (l_ != v_7);
    v_3 = (v_4 && v_5);
    bool v_8 = v_3;
    if(!v_8) return false;
    a1t = a_;
    value v_9;
    v_9 = ALL_NOT_FOUND;
    v_9.material = None;
    a1t.Foreground = Foreground_e(v_9);
    a2t = b_;
    value v_10;
    v_10 = i_;
    a2t.Foreground = Foreground_e(v_10);
    
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
    if(i_.Content == NOT_FOUND || i_.ImpClimb == NOT_FOUND || i_.DirectionH == NOT_FOUND || i_.ImpStep == NOT_FOUND || i_.material != Imp) return false;
    value c_ = Content_d(i_.Content);
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
        if(v_18.material != Shaft) break;
        bool v_19;
        value v_20;
        v_20 = ALL_NOT_FOUND;
        v_20.material = None;
        v_19 = (c_ != v_20);
        if(v_19) {
        v_13 = 1u;
        } else {
        v_13 = 0u;
        }
        m_15 = 1;
    default: break; }
    switch(m_15) { case 0:
        value v_21 = v_14;
        v_13 = 0u;
        m_15 = 1;
    default: break; }
    if(m_15 == 0) return false;
    v_11 = (v_13 == 1u);
    bool v_12;
    bool v_22;
    if(!walkable_f(seed, transform, g_, v_22)) return false;
    v_12 = (!v_22);
    v_10 = (v_11 || v_12);
    bool v_23 = v_10;
    if(!v_23) return false;
    b2t = a_;
    value v_24;
    v_24 = i_;
    uint v_25;
    v_25 = 0u;
    if(v_25 >= 3u) return false;
    v_24.ImpStep = v_25;
    value v_26;
    value v_27;
    v_27 = ALL_NOT_FOUND;
    v_27.material = Left;
    if(!rotate_f(seed, transform, v_27, v_26)) return false;
    v_24.DirectionH = DirectionH_e(v_26);
    b2t.Foreground = Foreground_e(v_24);
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

bool factoryInputSide_r(inout uint seed, uint transform, inout value a1, inout value b1) {
    value x_ = a1;
    if(x_.Foreground == NOT_FOUND) return false;
    value i_ = Foreground_d(x_.Foreground);
    if(i_.Content == NOT_FOUND || i_.DirectionH == NOT_FOUND || i_.ImpClimb == NOT_FOUND || i_.ImpStep == NOT_FOUND || i_.material != Imp) return false;
    value c_ = Content_d(i_.Content);
    value d_ = DirectionH_d(i_.DirectionH);
    value v_1 = ImpClimb_d(i_.ImpClimb);
    if(v_1.material != None) return false;
    uint s_ = i_.ImpStep;

    value b_ = b1;
    if(b_.BuildingVariant == NOT_FOUND) return false;
    value f_ = BuildingVariant_d(b_.BuildingVariant);
    if(f_.Content == NOT_FOUND || f_.DirectionV == NOT_FOUND || f_.FactorySideCount == NOT_FOUND) return false;
    value p_1_ = Content_d(f_.Content);
    value v_2 = DirectionV_d(f_.DirectionV);
    if(v_2.material != Down) return false;
    uint v_3 = f_.FactorySideCount;
    if(v_3 != 0u) return false;
    
    value a1t;
    value b1t;
    
    bool v_4;
    v_4 = (p_1_ == c_);
    bool v_5 = v_4;
    if(!v_5) return false;
    bool v_6;
    bool v_7;
    value v_9;
    value v_10;
    v_10 = ALL_NOT_FOUND;
    v_10.material = Right;
    if(!rotate_f(seed, transform, v_10, v_9)) return false;
    v_7 = (d_ == v_9);
    bool v_8;
    bool v_11;
    v_11 = (s_ == 1u);
    bool v_12;
    v_12 = (s_ == 2u);
    v_8 = (v_11 || v_12);
    v_6 = (v_7 && v_8);
    bool v_13 = v_6;
    if(!v_13) return false;
    a1t = x_;
    value v_14;
    v_14 = i_;
    value v_15;
    v_15 = ALL_NOT_FOUND;
    v_15.material = None;
    v_14.Content = Content_e(v_15);
    a1t.Foreground = Foreground_e(v_14);
    b1t = b_;
    value v_16;
    v_16 = f_;
    uint v_17;
    v_17 = 1u;
    if(v_17 >= 6u) return false;
    v_16.FactorySideCount = v_17;
    b1t.BuildingVariant = BuildingVariant_e(v_16);
    
    a1 = a1t;
    b1 = b1t;
    return true;
}

bool factoryInputTop_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value x_ = a1;
    if(x_.Foreground == NOT_FOUND) return false;
    value i_ = Foreground_d(x_.Foreground);
    if(i_.Content == NOT_FOUND || i_.DirectionH == NOT_FOUND || i_.ImpClimb == NOT_FOUND || i_.material != Imp) return false;
    value c_ = Content_d(i_.Content);
    value d_ = DirectionH_d(i_.DirectionH);
    value v_1 = ImpClimb_d(i_.ImpClimb);
    if(v_1.material != None) return false;

    value b_ = a2;
    if(b_.BuildingVariant == NOT_FOUND) return false;
    value f_ = BuildingVariant_d(b_.BuildingVariant);
    if(f_.Content == NOT_FOUND || f_.DirectionV == NOT_FOUND || f_.FactorySideCount == NOT_FOUND) return false;
    value p_1_ = Content_d(f_.Content);
    value v_2 = DirectionV_d(f_.DirectionV);
    if(v_2.material != Up) return false;
    uint v_3 = f_.FactorySideCount;
    if(v_3 != 0u) return false;
    
    value a1t;
    value a2t;
    
    bool v_4;
    v_4 = (p_1_ == c_);
    bool v_5 = v_4;
    if(!v_5) return false;
    bool v_6;
    value v_7;
    value v_8;
    v_8 = ALL_NOT_FOUND;
    v_8.material = Right;
    if(!rotate_f(seed, transform, v_8, v_7)) return false;
    v_6 = (d_ == v_7);
    bool v_9 = v_6;
    if(!v_9) return false;
    a1t = x_;
    value v_10;
    v_10 = i_;
    value v_11;
    v_11 = ALL_NOT_FOUND;
    v_11.material = None;
    v_10.Content = Content_e(v_11);
    a1t.Foreground = Foreground_e(v_10);
    a2t = b_;
    value v_12;
    v_12 = f_;
    uint v_13;
    v_13 = 1u;
    if(v_13 >= 6u) return false;
    v_12.FactorySideCount = v_13;
    a2t.BuildingVariant = BuildingVariant_e(v_12);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool factoryFeedLeft_r(inout uint seed, uint transform, inout value a1, inout value b1) {
    value b1_ = a1;
    if(b1_.BuildingVariant == NOT_FOUND) return false;
    value f1_ = BuildingVariant_d(b1_.BuildingVariant);
    if(f1_.FactorySideCount == NOT_FOUND) return false;
    uint v_1 = f1_.FactorySideCount;
    if(v_1 != 1u) return false;

    value b2_ = b1;
    if(b2_.BuildingVariant == NOT_FOUND) return false;
    value f2_ = BuildingVariant_d(b2_.BuildingVariant);
    if(f2_.FactoryFedLeft == NOT_FOUND) return false;
    uint v_2 = f2_.FactoryFedLeft;
    if(v_2 != 0u) return false;
    
    value a1t;
    value b1t;
    
    a1t = b1_;
    value v_3;
    v_3 = f1_;
    uint v_4;
    v_4 = 0u;
    if(v_4 >= 6u) return false;
    v_3.FactorySideCount = v_4;
    a1t.BuildingVariant = BuildingVariant_e(v_3);
    b1t = b2_;
    value v_5;
    v_5 = f2_;
    uint v_6;
    v_6 = 1u;
    if(v_6 >= 2u) return false;
    v_5.FactoryFedLeft = v_6;
    b1t.BuildingVariant = BuildingVariant_e(v_5);
    
    a1 = a1t;
    b1 = b1t;
    return true;
}

bool factoryFeedRight_r(inout uint seed, uint transform, inout value a1, inout value b1) {
    value b1_ = a1;
    if(b1_.BuildingVariant == NOT_FOUND) return false;
    value f2_ = BuildingVariant_d(b1_.BuildingVariant);
    if(f2_.FactoryFedRight == NOT_FOUND) return false;
    uint v_1 = f2_.FactoryFedRight;
    if(v_1 != 0u) return false;

    value b2_ = b1;
    if(b2_.BuildingVariant == NOT_FOUND) return false;
    value f1_ = BuildingVariant_d(b2_.BuildingVariant);
    if(f1_.FactorySideCount == NOT_FOUND) return false;
    uint v_2 = f1_.FactorySideCount;
    if(v_2 != 1u) return false;
    
    value a1t;
    value b1t;
    
    a1t = b1_;
    value v_3;
    v_3 = f2_;
    uint v_4;
    v_4 = 1u;
    if(v_4 >= 2u) return false;
    v_3.FactoryFedRight = v_4;
    a1t.BuildingVariant = BuildingVariant_e(v_3);
    b1t = b2_;
    value v_5;
    v_5 = f1_;
    uint v_6;
    v_6 = 0u;
    if(v_6 >= 6u) return false;
    v_5.FactorySideCount = v_6;
    b1t.BuildingVariant = BuildingVariant_e(v_5);
    
    a1 = a1t;
    b1 = b1t;
    return true;
}

bool factoryCountdown_r(inout uint seed, uint transform, value b1, inout value b2, value b3) {
    value v_1 = b1;

    value b_ = b2;
    if(b_.BuildingVariant == NOT_FOUND) return false;
    value f_ = BuildingVariant_d(b_.BuildingVariant);
    if(f_.FactoryCountdown == NOT_FOUND || f_.FactoryFedRight == NOT_FOUND || f_.FactoryFedLeft == NOT_FOUND || f_.material != FactoryTop) return false;
    uint n_ = f_.FactoryCountdown;
    uint v_2 = f_.FactoryFedRight;
    if(v_2 != 1u) return false;
    uint v_3 = f_.FactoryFedLeft;
    if(v_3 != 1u) return false;

    value v_4 = b3;
    if(v_4.BuildingVariant == NOT_FOUND) return false;
    value v_5 = BuildingVariant_d(v_4.BuildingVariant);
    if(v_5.FactoryFedRight == NOT_FOUND || v_5.FactoryFedLeft == NOT_FOUND || v_5.material != FactoryBottom) return false;
    uint v_6 = v_5.FactoryFedRight;
    if(v_6 != 1u) return false;
    uint v_7 = v_5.FactoryFedLeft;
    if(v_7 != 1u) return false;
    
    value b2t;
    
    b2t = b_;
    value v_8;
    v_8 = f_;
    uint v_9;
    v_9 = 1u;
    if(v_9 >= 2u) return false;
    v_8.FactoryFedLeft = v_9;
    uint v_10;
    v_10 = 1u;
    if(v_10 >= 2u) return false;
    v_8.FactoryFedRight = v_10;
    uint v_11;
    v_11 = (n_ - 1u);
    if(v_11 >= 11u) return false;
    v_8.FactoryCountdown = v_11;
    b2t.BuildingVariant = BuildingVariant_e(v_8);
    
    b2 = b2t;
    return true;
}

bool factoryProduce_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value b1_ = a1;
    if(b1_.BuildingVariant == NOT_FOUND) return false;
    value f1_ = BuildingVariant_d(b1_.BuildingVariant);
    if(f1_.FactoryCountdown == NOT_FOUND || f1_.FactoryFedRight == NOT_FOUND || f1_.FactoryFedLeft == NOT_FOUND || f1_.material != FactoryTop) return false;
    uint v_1 = f1_.FactoryCountdown;
    if(v_1 != 0u) return false;
    uint v_2 = f1_.FactoryFedRight;
    if(v_2 != 1u) return false;
    uint v_3 = f1_.FactoryFedLeft;
    if(v_3 != 1u) return false;

    value b2_ = a2;
    if(b2_.BuildingVariant == NOT_FOUND) return false;
    value f2_ = BuildingVariant_d(b2_.BuildingVariant);
    if(f2_.FactoryProduced == NOT_FOUND || f2_.FactoryFedRight == NOT_FOUND || f2_.FactoryFedLeft == NOT_FOUND || f2_.material != FactoryBottom) return false;
    uint v_4 = f2_.FactoryProduced;
    if(v_4 != 0u) return false;
    uint v_5 = f2_.FactoryFedRight;
    if(v_5 != 1u) return false;
    uint v_6 = f2_.FactoryFedLeft;
    if(v_6 != 1u) return false;
    
    value a1t;
    value a2t;
    
    a1t = b1_;
    value v_7;
    v_7 = f1_;
    uint v_8;
    v_8 = 0u;
    if(v_8 >= 2u) return false;
    v_7.FactoryFedLeft = v_8;
    uint v_9;
    v_9 = 0u;
    if(v_9 >= 2u) return false;
    v_7.FactoryFedRight = v_9;
    uint v_10;
    v_10 = 10u;
    if(v_10 >= 11u) return false;
    v_7.FactoryCountdown = v_10;
    a1t.BuildingVariant = BuildingVariant_e(v_7);
    a2t = b2_;
    value v_11;
    v_11 = f2_;
    uint v_12;
    v_12 = 0u;
    if(v_12 >= 2u) return false;
    v_11.FactoryFedLeft = v_12;
    uint v_13;
    v_13 = 0u;
    if(v_13 >= 2u) return false;
    v_11.FactoryFedRight = v_13;
    uint v_14;
    v_14 = 1u;
    if(v_14 >= 11u) return false;
    v_11.FactoryProduced = v_14;
    a2t.BuildingVariant = BuildingVariant_e(v_11);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool factoryDeliver_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value b_ = a1;
    if(b_.BuildingVariant == NOT_FOUND) return false;
    value f_ = BuildingVariant_d(b_.BuildingVariant);
    if(f_.Content == NOT_FOUND || f_.FactoryProduced == NOT_FOUND || f_.material != FactoryBottom) return false;
    value c_ = Content_d(f_.Content);
    uint n_ = f_.FactoryProduced;

    value x_ = a2;
    if(x_.Foreground == NOT_FOUND || x_.material != Cave) return false;
    value v_1 = Foreground_d(x_.Foreground);
    if(v_1.material != None) return false;
    
    value a1t;
    value a2t;
    
    a1t = b_;
    value v_2;
    v_2 = f_;
    uint v_3;
    v_3 = (n_ - 1u);
    if(v_3 >= 11u) return false;
    v_2.FactoryProduced = v_3;
    a1t.BuildingVariant = BuildingVariant_e(v_2);
    a2t = x_;
    value v_4;
    v_4 = c_;
    a2t.Foreground = Foreground_e(v_4);
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool campfireBurn_r(inout uint seed, uint transform, inout value a1) {
    value x_ = a1;
    if(x_.BuildingVariant == NOT_FOUND) return false;
    value v_1 = BuildingVariant_d(x_.BuildingVariant);
    if(v_1.CampfireFuel == NOT_FOUND || v_1.material != Campfire) return false;
    uint n_ = v_1.CampfireFuel;
    
    value a1t;
    
    bool v_2;
    v_2 = (n_ > 0u);
    bool v_3 = v_2;
    if(!v_3) return false;
    a1t = x_;
    value v_4;
    v_4 = ALL_NOT_FOUND;
    v_4.material = Campfire;
    uint v_5;
    v_5 = (n_ - 1u);
    if(v_5 >= 101u) return false;
    v_4.CampfireFuel = v_5;
    a1t.BuildingVariant = BuildingVariant_e(v_4);
    
    a1 = a1t;
    return true;
}

bool campfirePut_r(inout uint seed, uint transform, inout value a1, inout value b1) {
    value x_ = a1;
    if(x_.BuildingVariant == NOT_FOUND) return false;
    value v_1 = BuildingVariant_d(x_.BuildingVariant);
    if(v_1.CampfireFuel == NOT_FOUND || v_1.material != Campfire) return false;
    uint n_ = v_1.CampfireFuel;

    value y_ = b1;
    if(y_.Foreground == NOT_FOUND) return false;
    value i_ = Foreground_d(y_.Foreground);
    if(i_.Content == NOT_FOUND || i_.ImpClimb == NOT_FOUND || i_.ImpStep == NOT_FOUND || i_.material != Imp) return false;
    value v_2 = Content_d(i_.Content);
    if(v_2.material != Wood) return false;
    value v_3 = ImpClimb_d(i_.ImpClimb);
    if(v_3.material != None) return false;
    uint v_4 = i_.ImpStep;
    if(v_4 != 2u) return false;
    
    value a1t;
    value b1t;
    
    bool v_5;
    v_5 = (n_ <= 90u);
    bool v_6 = v_5;
    if(!v_6) return false;
    a1t = x_;
    value v_7;
    v_7 = ALL_NOT_FOUND;
    v_7.material = Campfire;
    uint v_8;
    v_8 = (n_ + 10u);
    if(v_8 >= 101u) return false;
    v_7.CampfireFuel = v_8;
    a1t.BuildingVariant = BuildingVariant_e(v_7);
    b1t = y_;
    value v_9;
    v_9 = i_;
    value v_10;
    v_10 = ALL_NOT_FOUND;
    v_10.material = None;
    v_9.Content = Content_e(v_10);
    b1t.Foreground = Foreground_e(v_9);
    
    a1 = a1t;
    b1 = b1t;
    return true;
}

bool fall_r(inout uint seed, uint transform, inout value a1, inout value a2) {
    value x_ = a1;
    if(x_.Background == NOT_FOUND || x_.Foreground == NOT_FOUND || x_.material != Cave) return false;
    value v_1 = Background_d(x_.Background);
    if(v_1.material != None) return false;
    value v_2 = Foreground_d(x_.Foreground);
    if(v_2.Weight == NOT_FOUND) return false;
    uint n_ = v_2.Weight;

    value y_ = a2;
    if(y_.Background == NOT_FOUND || y_.Foreground == NOT_FOUND || y_.material != Cave) return false;
    value v_3 = Background_d(y_.Background);
    if(v_3.material != None) return false;
    value v_4 = Foreground_d(y_.Foreground);
    if(v_4.Weight == NOT_FOUND) return false;
    uint m_ = v_4.Weight;
    
    value a1t;
    value a2t;
    
    bool v_5;
    v_5 = (n_ > m_);
    bool v_6 = v_5;
    if(!v_6) return false;
    a1t = y_;
    a2t = x_;
    
    a1 = a1t;
    a2 = a2t;
    return true;
}

bool roll_r(inout uint seed, uint transform, inout value a1, inout value b1, inout value a2, inout value b2) {
    value a_ = a1;
    if(a_.Background == NOT_FOUND || a_.Foreground == NOT_FOUND || a_.material != Cave) return false;
    value v_1 = Background_d(a_.Background);
    if(v_1.material != None) return false;
    value v_2 = Foreground_d(a_.Foreground);
    if(v_2.Weight == NOT_FOUND) return false;
    uint n_ = v_2.Weight;

    value b_ = b1;
    if(b_.Background == NOT_FOUND || b_.Foreground == NOT_FOUND || b_.material != Cave) return false;
    value v_3 = Background_d(b_.Background);
    if(v_3.material != None) return false;
    value v_4 = Foreground_d(b_.Foreground);
    if(v_4.material != None) return false;

    value c_ = a2;
    if(c_.Background == NOT_FOUND || c_.Foreground == NOT_FOUND || c_.material != Cave) return false;
    value v_5 = Background_d(c_.Background);
    if(v_5.material != None) return false;
    value v_6 = Foreground_d(c_.Foreground);
    if(v_6.Weight == NOT_FOUND) return false;
    uint m_ = v_6.Weight;

    value d_ = b2;
    if(d_.Background == NOT_FOUND || d_.Foreground == NOT_FOUND || d_.material != Cave) return false;
    value v_7 = Background_d(d_.Background);
    if(v_7.material != None) return false;
    value v_8 = Foreground_d(d_.Foreground);
    if(v_8.material != None) return false;
    
    value a1t;
    value b1t;
    value a2t;
    value b2t;
    
    bool v_9;
    v_9 = (n_ > m_);
    bool v_10 = v_9;
    if(!v_10) return false;
    a1t = b_;
    b1t = a_;
    a2t = c_;
    b2t = d_;
    
    a1 = a1t;
    b1 = b1t;
    a2 = a2t;
    b2 = b2t;
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

    // rockLightGroup
    bool rockLightGroup_d = false;
    bool rockLightBoundary_d = false;
    bool rockLight_d = false;
    if(true) {
        if(true) {
            seed ^= 108567334u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 0u, b2, b3) || rockLightBoundary_d;
            seed ^= 1869972635u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 0u, c2, c3) || rockLightBoundary_d;
            seed ^= 871070164u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 90u, b3, c3) || rockLightBoundary_d;
            seed ^= 223888653u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 90u, b2, c2) || rockLightBoundary_d;
            seed ^= 1967264300u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 180u, c3, c2) || rockLightBoundary_d;
            seed ^= 1956845781u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 180u, b3, b2) || rockLightBoundary_d;
            seed ^= 2125574876u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 270u, c2, b2) || rockLightBoundary_d;
            seed ^= 1273636163u;
            rockLightBoundary_d = rockLightBoundary_r(seed, 270u, c3, b3) || rockLightBoundary_d;
            rockLightGroup_d = rockLightGroup_d || rockLightBoundary_d;
        }
        if(true) {
            seed ^= 108567334u;
            rockLight_d = rockLight_r(seed, 0u, b2, b3) || rockLight_d;
            seed ^= 1869972635u;
            rockLight_d = rockLight_r(seed, 0u, c2, c3) || rockLight_d;
            seed ^= 871070164u;
            rockLight_d = rockLight_r(seed, 90u, b3, c3) || rockLight_d;
            seed ^= 223888653u;
            rockLight_d = rockLight_r(seed, 90u, b2, c2) || rockLight_d;
            seed ^= 1967264300u;
            rockLight_d = rockLight_r(seed, 180u, c3, c2) || rockLight_d;
            seed ^= 1956845781u;
            rockLight_d = rockLight_r(seed, 180u, b3, b2) || rockLight_d;
            seed ^= 2125574876u;
            rockLight_d = rockLight_r(seed, 270u, c2, b2) || rockLight_d;
            seed ^= 1273636163u;
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
            seed ^= 1998101111u;
            shaftEnter_d = shaftEnter_d || shaftEnter_r(seed, 0u, b2, b3);
            seed ^= 1863429485u;
            shaftEnter_d = shaftEnter_d || shaftEnter_r(seed, 0u, c2, c3);
            seed ^= 512539514u;
            shaftEnter_d = shaftEnter_d || shaftEnter_r(seed, 90u, b3, c3);
            seed ^= 909067310u;
            shaftEnter_d = shaftEnter_d || shaftEnter_r(seed, 90u, b2, c2);
            seed ^= 1483200932u;
            shaftEnter_d = shaftEnter_d || shaftEnter_r(seed, 180u, c3, c2);
            seed ^= 768441705u;
            shaftEnter_d = shaftEnter_d || shaftEnter_r(seed, 180u, b3, b2);
            seed ^= 1076533857u;
            shaftEnter_d = shaftEnter_d || shaftEnter_r(seed, 270u, c2, b2);
            seed ^= 1128456650u;
            shaftEnter_d = shaftEnter_d || shaftEnter_r(seed, 270u, c3, b3);
            shaftGroup_d = shaftGroup_d || shaftEnter_d;
        }
        if(!shaftGroup_d) {
            seed ^= 1998101111u;
            shaftExit_d = shaftExit_d || shaftExit_r(seed, 0u, b2, b3);
            seed ^= 1863429485u;
            shaftExit_d = shaftExit_d || shaftExit_r(seed, 0u, c2, c3);
            seed ^= 512539514u;
            shaftExit_d = shaftExit_d || shaftExit_r(seed, 90u, b3, c3);
            seed ^= 909067310u;
            shaftExit_d = shaftExit_d || shaftExit_r(seed, 90u, b2, c2);
            seed ^= 1483200932u;
            shaftExit_d = shaftExit_d || shaftExit_r(seed, 180u, c3, c2);
            seed ^= 768441705u;
            shaftExit_d = shaftExit_d || shaftExit_r(seed, 180u, b3, b2);
            seed ^= 1076533857u;
            shaftExit_d = shaftExit_d || shaftExit_r(seed, 270u, c2, b2);
            seed ^= 1128456650u;
            shaftExit_d = shaftExit_d || shaftExit_r(seed, 270u, c3, b3);
            shaftGroup_d = shaftGroup_d || shaftExit_d;
        }
        if(!shaftGroup_d) {
            seed ^= 1998101111u;
            shaftSwapEnter_d = shaftSwapEnter_d || shaftSwapEnter_r(seed, 0u, b2, b3);
            seed ^= 1863429485u;
            shaftSwapEnter_d = shaftSwapEnter_d || shaftSwapEnter_r(seed, 0u, c2, c3);
            seed ^= 512539514u;
            shaftSwapEnter_d = shaftSwapEnter_d || shaftSwapEnter_r(seed, 90u, b3, c3);
            seed ^= 909067310u;
            shaftSwapEnter_d = shaftSwapEnter_d || shaftSwapEnter_r(seed, 90u, b2, c2);
            seed ^= 1483200932u;
            shaftSwapEnter_d = shaftSwapEnter_d || shaftSwapEnter_r(seed, 180u, c3, c2);
            seed ^= 768441705u;
            shaftSwapEnter_d = shaftSwapEnter_d || shaftSwapEnter_r(seed, 180u, b3, b2);
            seed ^= 1076533857u;
            shaftSwapEnter_d = shaftSwapEnter_d || shaftSwapEnter_r(seed, 270u, c2, b2);
            seed ^= 1128456650u;
            shaftSwapEnter_d = shaftSwapEnter_d || shaftSwapEnter_r(seed, 270u, c3, b3);
            shaftGroup_d = shaftGroup_d || shaftSwapEnter_d;
        }
        if(!shaftGroup_d) {
            seed ^= 1998101111u;
            shaftDigEnter_d = shaftDigEnter_d || shaftDigEnter_r(seed, 0u, b2, b3);
            seed ^= 1863429485u;
            shaftDigEnter_d = shaftDigEnter_d || shaftDigEnter_r(seed, 0u, c2, c3);
            seed ^= 512539514u;
            shaftDigEnter_d = shaftDigEnter_d || shaftDigEnter_r(seed, 90u, b3, c3);
            seed ^= 909067310u;
            shaftDigEnter_d = shaftDigEnter_d || shaftDigEnter_r(seed, 90u, b2, c2);
            seed ^= 1483200932u;
            shaftDigEnter_d = shaftDigEnter_d || shaftDigEnter_r(seed, 180u, c3, c2);
            seed ^= 768441705u;
            shaftDigEnter_d = shaftDigEnter_d || shaftDigEnter_r(seed, 180u, b3, b2);
            seed ^= 1076533857u;
            shaftDigEnter_d = shaftDigEnter_d || shaftDigEnter_r(seed, 270u, c2, b2);
            seed ^= 1128456650u;
            shaftDigEnter_d = shaftDigEnter_d || shaftDigEnter_r(seed, 270u, c3, b3);
            shaftGroup_d = shaftGroup_d || shaftDigEnter_d;
        }
        if(!shaftGroup_d) {
            seed ^= 1998101111u;
            shaftDig_d = shaftDig_d || shaftDig_r(seed, 0u, b2, b3);
            seed ^= 1863429485u;
            shaftDig_d = shaftDig_d || shaftDig_r(seed, 0u, c2, c3);
            seed ^= 512539514u;
            shaftDig_d = shaftDig_d || shaftDig_r(seed, 90u, b3, c3);
            seed ^= 909067310u;
            shaftDig_d = shaftDig_d || shaftDig_r(seed, 90u, b2, c2);
            seed ^= 1483200932u;
            shaftDig_d = shaftDig_d || shaftDig_r(seed, 180u, c3, c2);
            seed ^= 768441705u;
            shaftDig_d = shaftDig_d || shaftDig_r(seed, 180u, b3, b2);
            seed ^= 1076533857u;
            shaftDig_d = shaftDig_d || shaftDig_r(seed, 270u, c2, b2);
            seed ^= 1128456650u;
            shaftDig_d = shaftDig_d || shaftDig_r(seed, 270u, c3, b3);
            shaftGroup_d = shaftGroup_d || shaftDig_d;
        }
        if(!shaftGroup_d) {
            seed ^= 1998101111u;
            shaftAscend_d = shaftAscend_d || shaftAscend_r(seed, 0u, b2, b3);
            seed ^= 1863429485u;
            shaftAscend_d = shaftAscend_d || shaftAscend_r(seed, 0u, c2, c3);
            seed ^= 512539514u;
            shaftAscend_d = shaftAscend_d || shaftAscend_r(seed, 90u, b3, c3);
            seed ^= 909067310u;
            shaftAscend_d = shaftAscend_d || shaftAscend_r(seed, 90u, b2, c2);
            seed ^= 1483200932u;
            shaftAscend_d = shaftAscend_d || shaftAscend_r(seed, 180u, c3, c2);
            seed ^= 768441705u;
            shaftAscend_d = shaftAscend_d || shaftAscend_r(seed, 180u, b3, b2);
            seed ^= 1076533857u;
            shaftAscend_d = shaftAscend_d || shaftAscend_r(seed, 270u, c2, b2);
            seed ^= 1128456650u;
            shaftAscend_d = shaftAscend_d || shaftAscend_r(seed, 270u, c3, b3);
            shaftGroup_d = shaftGroup_d || shaftAscend_d;
        }
        if(!shaftGroup_d) {
            seed ^= 1998101111u;
            shaftDescend_d = shaftDescend_d || shaftDescend_r(seed, 0u, b2, b3);
            seed ^= 1863429485u;
            shaftDescend_d = shaftDescend_d || shaftDescend_r(seed, 0u, c2, c3);
            seed ^= 512539514u;
            shaftDescend_d = shaftDescend_d || shaftDescend_r(seed, 90u, b3, c3);
            seed ^= 909067310u;
            shaftDescend_d = shaftDescend_d || shaftDescend_r(seed, 90u, b2, c2);
            seed ^= 1483200932u;
            shaftDescend_d = shaftDescend_d || shaftDescend_r(seed, 180u, c3, c2);
            seed ^= 768441705u;
            shaftDescend_d = shaftDescend_d || shaftDescend_r(seed, 180u, b3, b2);
            seed ^= 1076533857u;
            shaftDescend_d = shaftDescend_d || shaftDescend_r(seed, 270u, c2, b2);
            seed ^= 1128456650u;
            shaftDescend_d = shaftDescend_d || shaftDescend_r(seed, 270u, c3, b3);
            shaftGroup_d = shaftGroup_d || shaftDescend_d;
        }
        if(!shaftGroup_d) {
            seed ^= 1998101111u;
            shaftSwap_d = shaftSwap_d || shaftSwap_r(seed, 0u, b2, b3);
            seed ^= 1863429485u;
            shaftSwap_d = shaftSwap_d || shaftSwap_r(seed, 0u, c2, c3);
            seed ^= 512539514u;
            shaftSwap_d = shaftSwap_d || shaftSwap_r(seed, 90u, b3, c3);
            seed ^= 909067310u;
            shaftSwap_d = shaftSwap_d || shaftSwap_r(seed, 90u, b2, c2);
            seed ^= 1483200932u;
            shaftSwap_d = shaftSwap_d || shaftSwap_r(seed, 180u, c3, c2);
            seed ^= 768441705u;
            shaftSwap_d = shaftSwap_d || shaftSwap_r(seed, 180u, b3, b2);
            seed ^= 1076533857u;
            shaftSwap_d = shaftSwap_d || shaftSwap_r(seed, 270u, c2, b2);
            seed ^= 1128456650u;
            shaftSwap_d = shaftSwap_d || shaftSwap_r(seed, 270u, c3, b3);
            shaftGroup_d = shaftGroup_d || shaftSwap_d;
        }
        if(!shaftGroup_d) {
            seed ^= 1998101111u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 0u, a1, b1, c1, a2, b2, c2, a3, b3, c3);
            seed ^= 1863429485u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 0u, b1, c1, d1, b2, c2, d2, b3, c3, d3);
            seed ^= 512539514u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 0u, a2, b2, c2, a3, b3, c3, a4, b4, c4);
            seed ^= 909067310u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 0u, b2, c2, d2, b3, c3, d3, b4, c4, d4);
            seed ^= 1483200932u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 90u, a4, a3, a2, b4, b3, b2, c4, c3, c2);
            seed ^= 768441705u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 90u, a3, a2, a1, b3, b2, b1, c3, c2, c1);
            seed ^= 1076533857u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 90u, b4, b3, b2, c4, c3, c2, d4, d3, d2);
            seed ^= 1128456650u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 90u, b3, b2, b1, c3, c2, c1, d3, d2, d1);
            seed ^= 1036304439u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 180u, d4, c4, b4, d3, c3, b3, d2, c2, b2);
            seed ^= 521866146u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 180u, c4, b4, a4, c3, b3, a3, c2, b2, a2);
            seed ^= 1877734743u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 180u, d3, c3, b3, d2, c2, b2, d1, c1, b1);
            seed ^= 442777204u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 180u, c3, b3, a3, c2, b2, a2, c1, b1, a1);
            seed ^= 417852623u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 270u, d1, d2, d3, c1, c2, c3, b1, b2, b3);
            seed ^= 1468553035u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 270u, d2, d3, d4, c2, c3, c4, b2, b3, b4);
            seed ^= 1804696987u;
            shaftRemove_d = shaftRemove_d || shaftRemove_r(seed, 270u, c1, c2, c3, b1, b2, b3, a1, a2, a3);
            seed ^= 1493263451u;
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
            seed ^= 700865161u;
            impStep_d = impStep_r(seed, 0u, b1, b2, b3) || impStep_d;
            seed ^= 208387653u;
            impStep_d = impStep_r(seed, 0u, c1, c2, c3) || impStep_d;
            seed ^= 29006270u;
            impStep_d = impStep_r(seed, 0u, b2, b3, b4) || impStep_d;
            seed ^= 1366790672u;
            impStep_d = impStep_r(seed, 0u, c2, c3, c4) || impStep_d;
            seed ^= 682242356u;
            impStep_d = impStep_r(seed, 1u, c1, c2, c3) || impStep_d;
            seed ^= 1508586557u;
            impStep_d = impStep_r(seed, 1u, b1, b2, b3) || impStep_d;
            seed ^= 389242727u;
            impStep_d = impStep_r(seed, 1u, c2, c3, c4) || impStep_d;
            seed ^= 2099253769u;
            impStep_d = impStep_r(seed, 1u, b2, b3, b4) || impStep_d;
            impMoveGroup_d = impMoveGroup_d || impStep_d;
        }
        if(!impStep_d) {
            seed ^= 700865161u;
            impWalk_d = impWalk_r(seed, 0u, b1, c1, b2, c2, b3, c3) || impWalk_d;
            seed ^= 208387653u;
            impWalk_d = impWalk_r(seed, 0u, b2, c2, b3, c3, b4, c4) || impWalk_d;
            seed ^= 29006270u;
            impWalk_d = impWalk_r(seed, 1u, c1, b1, c2, b2, c3, b3) || impWalk_d;
            seed ^= 1366790672u;
            impWalk_d = impWalk_r(seed, 1u, c2, b2, c3, b3, c4, b4) || impWalk_d;
            impMoveGroup_d = impMoveGroup_d || impWalk_d;
        }
        if(true) {
            seed ^= 700865161u;
            impFall_d = impFall_r(seed, 0u, b2, b3) || impFall_d;
            seed ^= 208387653u;
            impFall_d = impFall_r(seed, 0u, c2, c3) || impFall_d;
            impMoveGroup_d = impMoveGroup_d || impFall_d;
        }
        if(true) {
            seed ^= 700865161u;
            impSwap_d = impSwap_r(seed, 0u, b2, c2) || impSwap_d;
            seed ^= 208387653u;
            impSwap_d = impSwap_r(seed, 0u, b3, c3) || impSwap_d;
            impMoveGroup_d = impMoveGroup_d || impSwap_d;
        }
        if(!impMoveGroup_d) {
            seed ^= 700865161u;
            impTurn_d = impTurn_d || impTurn_r(seed, 0u, b1, c1, b2, c2, b3, c3);
            seed ^= 208387653u;
            impTurn_d = impTurn_d || impTurn_r(seed, 0u, b2, c2, b3, c3, b4, c4);
            seed ^= 29006270u;
            impTurn_d = impTurn_d || impTurn_r(seed, 1u, c1, b1, c2, b2, c3, b3);
            seed ^= 1366790672u;
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
            seed ^= 212927420u;
            ladderEnter_d = ladderEnter_r(seed, 0u, a2, b2, c2) || ladderEnter_d;
            seed ^= 1702896328u;
            ladderEnter_d = ladderEnter_r(seed, 0u, b2, c2, d2) || ladderEnter_d;
            seed ^= 778946782u;
            ladderEnter_d = ladderEnter_r(seed, 0u, a3, b3, c3) || ladderEnter_d;
            seed ^= 1662459786u;
            ladderEnter_d = ladderEnter_r(seed, 0u, b3, c3, d3) || ladderEnter_d;
            seed ^= 236202830u;
            ladderEnter_d = ladderEnter_r(seed, 1u, d2, c2, b2) || ladderEnter_d;
            seed ^= 1503429822u;
            ladderEnter_d = ladderEnter_r(seed, 1u, c2, b2, a2) || ladderEnter_d;
            seed ^= 127879350u;
            ladderEnter_d = ladderEnter_r(seed, 1u, d3, c3, b3) || ladderEnter_d;
            seed ^= 352105046u;
            ladderEnter_d = ladderEnter_r(seed, 1u, c3, b3, a3) || ladderEnter_d;
            ladderGroup_d = ladderGroup_d || ladderEnter_d;
        }
        if(true) {
            seed ^= 212927420u;
            ladderExit_d = ladderExit_r(seed, 0u, b1, b2, b3) || ladderExit_d;
            seed ^= 1702896328u;
            ladderExit_d = ladderExit_r(seed, 0u, c1, c2, c3) || ladderExit_d;
            seed ^= 778946782u;
            ladderExit_d = ladderExit_r(seed, 0u, b2, b3, b4) || ladderExit_d;
            seed ^= 1662459786u;
            ladderExit_d = ladderExit_r(seed, 0u, c2, c3, c4) || ladderExit_d;
            seed ^= 236202830u;
            ladderExit_d = ladderExit_r(seed, 2u, b4, b3, b2) || ladderExit_d;
            seed ^= 1503429822u;
            ladderExit_d = ladderExit_r(seed, 2u, c4, c3, c2) || ladderExit_d;
            seed ^= 127879350u;
            ladderExit_d = ladderExit_r(seed, 2u, b3, b2, b1) || ladderExit_d;
            seed ^= 352105046u;
            ladderExit_d = ladderExit_r(seed, 2u, c3, c2, c1) || ladderExit_d;
            ladderGroup_d = ladderGroup_d || ladderExit_d;
        }
        if(true) {
            seed ^= 212927420u;
            ladderCheck_d = ladderCheck_r(seed, 0u, b2) || ladderCheck_d;
            seed ^= 1702896328u;
            ladderCheck_d = ladderCheck_r(seed, 0u, c2) || ladderCheck_d;
            seed ^= 778946782u;
            ladderCheck_d = ladderCheck_r(seed, 0u, b3) || ladderCheck_d;
            seed ^= 1662459786u;
            ladderCheck_d = ladderCheck_r(seed, 0u, c3) || ladderCheck_d;
            ladderGroup_d = ladderGroup_d || ladderCheck_d;
        }
        if(true) {
            seed ^= 212927420u;
            ladderClimb_d = ladderClimb_r(seed, 0u, b2, b3) || ladderClimb_d;
            seed ^= 1702896328u;
            ladderClimb_d = ladderClimb_r(seed, 0u, c2, c3) || ladderClimb_d;
            seed ^= 778946782u;
            ladderClimb_d = ladderClimb_r(seed, 2u, b3, b2) || ladderClimb_d;
            seed ^= 1662459786u;
            ladderClimb_d = ladderClimb_r(seed, 2u, c3, c2) || ladderClimb_d;
            ladderGroup_d = ladderGroup_d || ladderClimb_d;
        }
        if(true) {
            seed ^= 212927420u;
            ladderSwap_d = ladderSwap_r(seed, 0u, b2, b3) || ladderSwap_d;
            seed ^= 1702896328u;
            ladderSwap_d = ladderSwap_r(seed, 0u, c2, c3) || ladderSwap_d;
            ladderGroup_d = ladderGroup_d || ladderSwap_d;
        }
    }

    // chestGroup
    bool chestGroup_d = false;
    bool chestPut_d = false;
    if(true) {
        if(true) {
            seed ^= 1400158356u;
            chestPut_d = chestPut_r(seed, 0u, b2, b3) || chestPut_d;
            seed ^= 1636801541u;
            chestPut_d = chestPut_r(seed, 0u, c2, c3) || chestPut_d;
            chestGroup_d = chestGroup_d || chestPut_d;
        }
    }

    // factoryGroup
    bool factoryGroup_d = false;
    bool factoryInputSide_d = false;
    bool factoryInputTop_d = false;
    bool factoryFeedLeft_d = false;
    bool factoryFeedRight_d = false;
    bool factoryCountdown_d = false;
    bool factoryProduce_d = false;
    bool factoryDeliver_d = false;
    if(!factoryGroup_d) {
        if(!factoryGroup_d) {
            seed ^= 240170961u;
            factoryInputSide_d = factoryInputSide_d || factoryInputSide_r(seed, 0u, b2, c2);
            seed ^= 932842599u;
            factoryInputSide_d = factoryInputSide_d || factoryInputSide_r(seed, 0u, b3, c3);
            seed ^= 585650934u;
            factoryInputSide_d = factoryInputSide_d || factoryInputSide_r(seed, 1u, c2, b2);
            seed ^= 331850605u;
            factoryInputSide_d = factoryInputSide_d || factoryInputSide_r(seed, 1u, c3, b3);
            factoryGroup_d = factoryGroup_d || factoryInputSide_d;
        }
        if(!factoryGroup_d) {
            seed ^= 240170961u;
            factoryInputTop_d = factoryInputTop_d || factoryInputTop_r(seed, 0u, b2, b3);
            seed ^= 932842599u;
            factoryInputTop_d = factoryInputTop_d || factoryInputTop_r(seed, 0u, c2, c3);
            factoryGroup_d = factoryGroup_d || factoryInputTop_d;
        }
        if(!factoryGroup_d) {
            seed ^= 240170961u;
            factoryFeedLeft_d = factoryFeedLeft_d || factoryFeedLeft_r(seed, 0u, b2, c2);
            seed ^= 932842599u;
            factoryFeedLeft_d = factoryFeedLeft_d || factoryFeedLeft_r(seed, 0u, b3, c3);
            factoryGroup_d = factoryGroup_d || factoryFeedLeft_d;
        }
        if(!factoryGroup_d) {
            seed ^= 240170961u;
            factoryFeedRight_d = factoryFeedRight_d || factoryFeedRight_r(seed, 0u, b2, c2);
            seed ^= 932842599u;
            factoryFeedRight_d = factoryFeedRight_d || factoryFeedRight_r(seed, 0u, b3, c3);
            factoryGroup_d = factoryGroup_d || factoryFeedRight_d;
        }
        if(!factoryGroup_d) {
            seed ^= 240170961u;
            factoryCountdown_d = factoryCountdown_d || factoryCountdown_r(seed, 0u, b1, b2, b3);
            seed ^= 932842599u;
            factoryCountdown_d = factoryCountdown_d || factoryCountdown_r(seed, 0u, c1, c2, c3);
            seed ^= 585650934u;
            factoryCountdown_d = factoryCountdown_d || factoryCountdown_r(seed, 0u, b2, b3, b4);
            seed ^= 331850605u;
            factoryCountdown_d = factoryCountdown_d || factoryCountdown_r(seed, 0u, c2, c3, c4);
            seed ^= 1274606883u;
            factoryCountdown_d = factoryCountdown_d || factoryCountdown_r(seed, 1u, c1, c2, c3);
            seed ^= 1226340073u;
            factoryCountdown_d = factoryCountdown_d || factoryCountdown_r(seed, 1u, b1, b2, b3);
            seed ^= 1244181786u;
            factoryCountdown_d = factoryCountdown_d || factoryCountdown_r(seed, 1u, c2, c3, c4);
            seed ^= 1859894726u;
            factoryCountdown_d = factoryCountdown_d || factoryCountdown_r(seed, 1u, b2, b3, b4);
            factoryGroup_d = factoryGroup_d || factoryCountdown_d;
        }
        if(!factoryGroup_d) {
            seed ^= 240170961u;
            factoryProduce_d = factoryProduce_d || factoryProduce_r(seed, 0u, b2, b3);
            seed ^= 932842599u;
            factoryProduce_d = factoryProduce_d || factoryProduce_r(seed, 0u, c2, c3);
            factoryGroup_d = factoryGroup_d || factoryProduce_d;
        }
        if(!factoryGroup_d) {
            seed ^= 240170961u;
            factoryDeliver_d = factoryDeliver_d || factoryDeliver_r(seed, 0u, b2, b3);
            seed ^= 932842599u;
            factoryDeliver_d = factoryDeliver_d || factoryDeliver_r(seed, 0u, c2, c3);
            factoryGroup_d = factoryGroup_d || factoryDeliver_d;
        }
    }

    // campfireGroup
    bool campfireGroup_d = false;
    bool campfireBurn_d = false;
    bool campfirePut_d = false;
    if(true) {
        if(true) {
            seed ^= 683714645u;
            campfireBurn_d = campfireBurn_r(seed, 0u, b2) || campfireBurn_d;
            seed ^= 191960836u;
            campfireBurn_d = campfireBurn_r(seed, 0u, c2) || campfireBurn_d;
            seed ^= 1031289094u;
            campfireBurn_d = campfireBurn_r(seed, 0u, b3) || campfireBurn_d;
            seed ^= 295164266u;
            campfireBurn_d = campfireBurn_r(seed, 0u, c3) || campfireBurn_d;
            campfireGroup_d = campfireGroup_d || campfireBurn_d;
        }
        if(true) {
            seed ^= 683714645u;
            campfirePut_d = campfirePut_r(seed, 0u, b2, c2) || campfirePut_d;
            seed ^= 191960836u;
            campfirePut_d = campfirePut_r(seed, 0u, b3, c3) || campfirePut_d;
            campfireGroup_d = campfireGroup_d || campfirePut_d;
        }
    }

    // fallGroup
    bool fallGroup_d = false;
    bool fall_d = false;
    bool roll_d = false;
    if(!fallGroup_d) {
        if(!fallGroup_d) {
            seed ^= 719679085u;
            fall_d = fall_d || fall_r(seed, 0u, b2, b3);
            seed ^= 1668133001u;
            fall_d = fall_d || fall_r(seed, 0u, c2, c3);
            fallGroup_d = fallGroup_d || fall_d;
        }
        if(!fallGroup_d) {
            seed ^= 719679085u;
            roll_d = roll_d || roll_r(seed, 0u, b2, c2, b3, c3);
            fallGroup_d = fallGroup_d || roll_d;
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