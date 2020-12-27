#version 300 es
precision mediump float;
precision highp int;
uniform highp usampler2D state;
//uniform float seedling;
uniform uint step;
out uint outputValue;
const uint NOT_FOUND = 4294967295u;
uint random(inout uint seed) {
    seed += (seed << 10u);
    seed ^= (seed >>  6u);
    seed += (seed <<  3u);
    seed ^= (seed >> 11u);
    seed += (seed << 15u);
    return seed;
}

const uint Chest = 0u;
const uint Imp = 1u;
const uint Stone = 2u;
const uint IronOre = 3u;
const uint Water = 4u;
const uint Air = 5u;
const uint Cell = 6u;
const uint Black = 7u;
const uint White = 8u;

struct value {
    uint material;
    uint Tile;
    uint Weight;
    uint Temperature;
    uint Content;
    uint ChestCount;
    uint Foreground;
    uint Background;
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
);

uint Background_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Black:
            n *= 2u;
            n += 0u;
            break;
        case White:
            n *= 2u;
            n += 1u;
            break;
    }
    return n;
}

uint Content_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case IronOre:
            n *= 3u;
            n += 0u;
            break;
        case Stone:
            n *= 3u;
            n += 1u;
            break;
        case Water:
            n *= 3u;
            n += 2u;
            break;
    }
    return n;
}

uint Foreground_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Air:
            n *= 5u;
            n += 0u;
            break;
        case Imp:
            n *= 3u;
            n += v.Content;
            n *= 5u;
            n += 1u;
            break;
        case IronOre:
            n *= 4u;
            n += v.Temperature;
            n *= 5u;
            n += 2u;
            break;
        case Stone:
            n *= 5u;
            n += 3u;
            break;
        case Water:
            n *= 4u;
            n += v.Temperature;
            n *= 5u;
            n += 4u;
            break;
    }
    return n;
}

uint Tile_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Cell:
            n *= 2u;
            n += v.Background;
            n *= 13u;
            n += v.Foreground;
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
            v.material = Black;
            break;
        case 1u:
            v.material = White;
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
            v.material = IronOre;
            v.Temperature = 0u;
            break;
        case 1u:
            v.material = Stone;
            v.Weight = 2u;
            break;
        case 2u:
            v.material = Water;
            v.Temperature = 0u;
            v.Weight = 1u;
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
            v.material = Air;
            v.Weight = 0u;
            break;
        case 1u:
            v.material = Imp;
            v.Content = n % 3u;
            n = n / 3u;
            break;
        case 2u:
            v.material = IronOre;
            v.Temperature = n % 4u;
            n = n / 4u;
            break;
        case 3u:
            v.material = Stone;
            v.Weight = 2u;
            break;
        case 4u:
            v.material = Water;
            v.Weight = 1u;
            v.Temperature = n % 4u;
            n = n / 4u;
            break;
    }
    return v;
}

value Tile_d(uint n) {
    value v = ALL_NOT_FOUND;
    uint m = n % 1u;
    n = n / 1u;
    switch(m) {
        case 0u:
            v.material = Cell;
            v.Foreground = n % 13u;
            n = n / 13u;
            v.Background = n % 2u;
            n = n / 2u;
            break;
    }
    return v;
}

value lookupTile(ivec2 offset) {
    uint n = texelFetch(state, offset, 0).r;
    return Tile_d(n);
}

bool max_f(inout uint seed, uint x, uint y, out uint result) {
    bool v_1;
    v_1 = (x_ > y_);
    if(v_1) {
    result = x_;
    } else {
    result = y_;
    }
    return true;
}

bool fall_r(inout uint seed, inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Weight == NOT_FOUND) return false;
    uint x_ = a_.Weight;

    value b_ = a2;
    if(b_.Weight == NOT_FOUND) return false;
    uint y_ = b_.Weight;

    value a1t;
    value a2t;

    bool v_1;
    v_1 = (x_ > y_);
    bool v_2 = v_1;
    if(!v_2) return false;
    a1t = b_;
    a2t = a_;

    a1 = a1t;
    a2 = a2t;
    return true;
}

bool fillChest_r(inout uint seed, inout value a1, inout value a2) {
    value a_ = a1;
    if((a_.material != Stone && (a_.material != IronOre && a_.material != Water))) return false;

    value b_ = a2;
    if(b_.ChestCount == NOT_FOUND || b_.Content == NOT_FOUND || b_.material != Chest) return false;
    uint c_ = b_.ChestCount;
    value p_1_ = Content_d(b_.Content);

    value a1t;
    value a2t;

    bool v_1;
    v_1 = (p_1_ == a_);
    bool v_2 = v_1;
    if(!v_2) return false;
    bool v_3;
    v_3 = (c_ < 3u);
    bool v_4 = v_3;
    if(!v_4) return false;
    a1t = ALL_NOT_FOUND;
    a1t.material = Air;
    a2t = b_;
    uint v_5;
    v_5 = (c_ + 1u);
    if(v_5 >= 4u) return false;
    a2t.ChestCount = v_5;

    a1 = a1t;
    a2 = a2t;
    return true;
}

bool fillChestMinimal_r(inout uint seed, inout value a1, inout value a2) {
    value a_ = a1;

    value b_ = a2;
    if(b_.ChestCount == NOT_FOUND || b_.Content == NOT_FOUND) return false;
    uint c_ = b_.ChestCount;
    value p_1_ = Content_d(b_.Content);

    value a1t;
    value a2t;

    bool v_1;
    v_1 = (p_1_ == a_);
    bool v_2 = v_1;
    if(!v_2) return false;
    a1t = ALL_NOT_FOUND;
    a1t.material = Air;
    a2t = b_;
    uint v_3;
    v_3 = (c_ + 1u);
    if(v_3 >= 4u) return false;
    a2t.ChestCount = v_3;

    a1 = a1t;
    a2 = a2t;
    return true;
}

bool fillChest2_r(inout uint seed, inout value a1, inout value a2) {
    value x_ = a1;
    if(x_.Background == NOT_FOUND || x_.Foreground == NOT_FOUND) return false;
    value v_1 = Background_d(x_.Background);
    if(v_1.material != White) return false;
    value a_ = Foreground_d(x_.Foreground);
    if((a_.material != Stone && (a_.material != IronOre && a_.material != Water))) return false;

    value y_ = a2;
    if(y_.Foreground == NOT_FOUND) return false;
    value b_ = Foreground_d(y_.Foreground);
    if(b_.ChestCount == NOT_FOUND || b_.Content == NOT_FOUND || b_.material != Chest) return false;
    uint c_ = b_.ChestCount;
    value p_1_ = Content_d(b_.Content);

    value a1t;
    value a2t;

    bool v_2;
    v_2 = (p_1_ == a_);
    bool v_3 = v_2;
    if(!v_3) return false;
    a1t = x_;
    value v_4;
    v_4 = ALL_NOT_FOUND;
    v_4.material = Air;
    a1t.Foreground = Foreground_e(v_4);
    a2t = y_;
    value v_5;
    v_5 = b_;
    uint v_6;
    v_6 = (c_ + 1u);
    if(v_6 >= 4u) return false;
    v_5.ChestCount = v_6;
    a2t.Foreground = Foreground_e(v_5);

    a1 = a1t;
    a2 = a2t;
    return true;
}

bool fillChest3_r(inout uint seed, inout value a1, inout value a2) {
    value a_ = a1;
    if((a_.material != Stone && (a_.material != IronOre && a_.material != Water))) return false;

    value b_ = a2;
    if(b_.ChestCount == NOT_FOUND || b_.Content == NOT_FOUND || b_.material != Chest) return false;
    uint c_ = b_.ChestCount;
    value p_1_ = Content_d(b_.Content);

    value a1t;
    value a2t;

    bool v_1;
    v_1 = (p_1_ == a_);
    bool v_2 = v_1;
    if(!v_2) return false;
    bool v_3;
    v_3 = (c_ < 3u);
    bool v_4 = v_3;
    if(!v_4) return false;
    a1t = ALL_NOT_FOUND;
    a1t.material = Air;
    a2t = b_;
    uint v_5;
    v_5 = (c_ + 1u);
    if(v_5 >= 4u) return false;
    a2t.ChestCount = v_5;

    a1 = a1t;
    a2 = a2t;
    return true;
}

bool stoneWaterCycle_r(inout uint seed, inout value a1) {
    value a_ = a1;
    if((a_.material != Stone && (a_.material != IronOre && a_.material != Water))) return false;

    value a1t;

    uint v_1;
    uint v_4 = random(seed);
    uint v_2 = (v_4 % 2u);
    uint v_5 = random(seed);
    uint v_3 = (v_5 % 3u);
    if(!max_f(seed, v_2, v_3, v_1)) return false;
    uint x_ = v_1;
    value v_6;
    v_6 = a_;
    uint m_7 = 0u;
    switch(m_7) { case 0u:
        value v_8 = v_6;
        if(v_8.material != Stone) break;
        a1t = ALL_NOT_FOUND;
        a1t.material = Water;
        uint v_9;
        v_9 = x_;
        if(v_9 >= 4u) return false;
        a1t.Temperature = v_9;
        m_7 = 1;
    }
    switch(m_7) { case 0u:
        value v_10 = v_6;
        if(v_10.material != Water) break;
        a1t = ALL_NOT_FOUND;
        a1t.material = Stone;
        m_7 = 1;
    }
    if(m_7 == 0u) return false;

    a1 = a1t;
    return true;
}

void main() {
    ivec2 position = ivec2(gl_FragCoord.xy - 0.5);
    ivec2 offset = (step % 2 == 0u) ? ivec2(1, 1) : ivec2(0, 0);
    ivec2 bottomLeft = (position + offset) / 2 * 2 - offset;
    uint seed = hash(997u ^ uint(position.x)) ^ hash(hash(step) ^ uint(position.y));

    value a1 = lookupTile(bottomLeft + ivec2(0, 1));
    value b1 = lookupTile(bottomLeft + ivec2(1, 1));
    value a2 = lookupTile(bottomLeft + ivec2(0, 0));
    value b2 = lookupTile(bottomLeft + ivec2(1, 0));

    // fallGroup
    bool fallGroup_d = false;
    bool fall_d = false;
    if(true) {
        if(true) {
            fall_d = fall_r(seed, a1, a2) || fall_d;
            fall_d = fall_r(seed, b1, b2) || fall_d;
            fallGroup_d = fallGroup_d || fall_d;
        }
    }

    // chestGroup
    bool chestGroup_d = false;
    bool fillChest_d = false;
    bool fillChestMinimal_d = false;
    bool fillChest2_d = false;
    bool fillChest3_d = false;
    bool stoneWaterCycle_d = false;
    if(!fallGroup_d) {
        if(true) {
            fillChest_d = fillChest_r(seed, a1, a2) || fillChest_d;
            fillChest_d = fillChest_r(seed, b1, b2) || fillChest_d;
            chestGroup_d = chestGroup_d || fillChest_d;
        }
        if(true) {
            fillChestMinimal_d = fillChestMinimal_r(seed, a1, a2) || fillChestMinimal_d;
            fillChestMinimal_d = fillChestMinimal_r(seed, b1, b2) || fillChestMinimal_d;
            chestGroup_d = chestGroup_d || fillChestMinimal_d;
        }
        if(true) {
            fillChest2_d = fillChest2_r(seed, a1, a2) || fillChest2_d;
            fillChest2_d = fillChest2_r(seed, b1, b2) || fillChest2_d;
            chestGroup_d = chestGroup_d || fillChest2_d;
        }
        if(true) {
            fillChest3_d = fillChest3_r(seed, a1, a2) || fillChest3_d;
            fillChest3_d = fillChest3_r(seed, b1, b2) || fillChest3_d;
            chestGroup_d = chestGroup_d || fillChest3_d;
        }
        if(true) {
            stoneWaterCycle_d = stoneWaterCycle_r(seed, a1) || stoneWaterCycle_d;
            stoneWaterCycle_d = stoneWaterCycle_r(seed, a2) || stoneWaterCycle_d;
            stoneWaterCycle_d = stoneWaterCycle_r(seed, b1) || stoneWaterCycle_d;
            stoneWaterCycle_d = stoneWaterCycle_r(seed, b2) || stoneWaterCycle_d;
            chestGroup_d = chestGroup_d || stoneWaterCycle_d;
        }
    }

    // Write and encode own value
    ivec2 quadrant = position - bottomLeft;
    value target = a2;
    if(quadrant == ivec2(0, 1)) target = a1;
    else if(quadrant == ivec2(1, 0)) target = b2;
    else if(quadrant == ivec2(1, 1)) target = b1;
    outputValue = Tile_e(target);

    if(step == 0u) {
        value stone = ALL_NOT_FOUND;
        stone.material = Stone;

        value air = ALL_NOT_FOUND;
        air.material = Air;

        if(int(position.x + position.y) % 4 == 0) outputValue = Tile_e(stone);
        else outputValue = Tile_e(air);
    }

}