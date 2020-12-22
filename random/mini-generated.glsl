#version 300 es
precision mediump float;
precision highp int;
uniform highp usampler2D state;
//uniform float seedling;
uniform int step;
out uint outputValue;
const uint NOT_FOUND = 4294967295u;

const uint Chest = 0u;
const uint Imp = 1u;
const uint Stone = 2u;
const uint IronOre = 3u;
const uint Water = 4u;
const uint Air = 5u;
const uint Tile = 6u;
const uint Black = 7u;
const uint White = 8u;

const uint SIZE_material = 9u;

const uint SIZE_Weight = 4u;
const uint SIZE_Resource = 1u;
const uint SIZE_Temperature = 4u;
const uint SIZE_Content = 4u;
const uint SIZE_ChestCount = 4u;
const uint SIZE_Foreground = 30u;
const uint SIZE_Background = 2u;

struct value {
    uint material;
    uint Weight;
    uint Resource;
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

const value FIXED_Weight = ALL_NOT_FOUND;

const value FIXED_Resource = ALL_NOT_FOUND;

const value FIXED_Temperature = ALL_NOT_FOUND;

const value FIXED_Content = value(
    NOT_FOUND
,   NOT_FOUND
,   NOT_FOUND
,   0u
,   0u
,   0u
,   NOT_FOUND
,   NOT_FOUND
);

const value FIXED_ChestCount = ALL_NOT_FOUND;

const value FIXED_Foreground = ALL_NOT_FOUND;

const value FIXED_Background = ALL_NOT_FOUND;

uint encode(value i, value fix) {
    uint result = 0u;
    switch(i.material) {
        case Imp:
            if(fix.Content == NOT_FOUND) {
                result *= SIZE_Content;
                result += i.Content;
            }
            break;
        case Tile:
            if(fix.Background == NOT_FOUND) {
                result *= SIZE_Background;
                result += i.Background;
            }
            if(fix.Foreground == NOT_FOUND) {
                result *= SIZE_Foreground;
                result += i.Foreground;
            }
            break;
        case IronOre:
            if(fix.Temperature == NOT_FOUND) {
                result *= SIZE_Temperature;
                result += i.Temperature;
            }
            break;
        case Chest:
            if(fix.ChestCount == NOT_FOUND) {
                result *= SIZE_ChestCount;
                result += i.ChestCount;
            }
            if(fix.Content == NOT_FOUND) {
                result *= SIZE_Content;
                result += i.Content;
            }
            break;
        case Water:
            if(fix.Temperature == NOT_FOUND) {
                result *= SIZE_Temperature;
                result += i.Temperature;
            }
            break;
        default:
            break;
    }
    result *= SIZE_material;
    result += i.material;
    return result;
}

value decode(uint number, value fix) {
    value o = ALL_NOT_FOUND;
    o.material = number % SIZE_material;
    uint remaining = number / SIZE_material;
    switch(o.material) {
        case Air:
            o.Weight = 0u;
            break;
        case Imp:
            if(fix.Content == NOT_FOUND) {
                o.Content = remaining % SIZE_Content;
                remaining /= SIZE_Content;
            } else {
                o.Content = fix.Content;
            }
            break;
        case Tile:
            if(fix.Background == NOT_FOUND) {
                o.Background = remaining % SIZE_Background;
                remaining /= SIZE_Background;
            } else {
                o.Background = fix.Background;
            }
            if(fix.Foreground == NOT_FOUND) {
                o.Foreground = remaining % SIZE_Foreground;
                remaining /= SIZE_Foreground;
            } else {
                o.Foreground = fix.Foreground;
            }
            break;
        case IronOre:
            if(fix.Temperature == NOT_FOUND) {
                o.Temperature = remaining % SIZE_Temperature;
                remaining /= SIZE_Temperature;
            } else {
                o.Temperature = fix.Temperature;
            }
            break;
        case Stone:
            o.Weight = 2u;
            break;
        case Chest:
            if(fix.ChestCount == NOT_FOUND) {
                o.ChestCount = remaining % SIZE_ChestCount;
                remaining /= SIZE_ChestCount;
            } else {
                o.ChestCount = fix.ChestCount;
            }
            if(fix.Content == NOT_FOUND) {
                o.Content = remaining % SIZE_Content;
                remaining /= SIZE_Content;
            } else {
                o.Content = fix.Content;
            }
            break;
        case Water:
            if(fix.Temperature == NOT_FOUND) {
                o.Temperature = remaining % SIZE_Temperature;
                remaining /= SIZE_Temperature;
            } else {
                o.Temperature = fix.Temperature;
            }
            o.Weight = 1u;
            break;
        default:
            break;
    }
    return o;
}

value lookupValue(ivec2 offset) {
    uint integer = texture(state, (vec2(offset) + 0.5) / 100.0/* / scale*/).r;
    return decode(integer, ALL_NOT_FOUND);
}

bool max_f(uint x, uint y, out uint result) {
    bool v_1;
    uint v_2 = x_;
    uint v_3 = y_;
    v_1 = (v_2 > v_3);
    if(v_1) {
    result = x_;
    } else {
    result = y_;
    }
    return true;
}

bool fall_r(inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Weight == NOT_FOUND) return false;
    uint x_ = a_.Weight;

    value b_ = a2;
    if(b_.Weight == NOT_FOUND) return false;
    uint y_ = b_.Weight;

    value a1t;
    value a2t;

    bool v_1;
    uint v_2 = x_;
    uint v_3 = y_;
    v_1 = (v_2 > v_3);
    bool v_4 = v_1;
    if(!v_4) return false;
    a1t = b_;
    a2t = a_;

    a1 = a1t;
    a2 = a2t;
    return true;
}

bool fillChest_r(inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Resource == NOT_FOUND) return false;

    value b_ = a2;
    if(b_.ChestCount == NOT_FOUND || b_.Content == NOT_FOUND || b_.material != Chest) return false;
    uint c_ = b_.ChestCount;
    value p_1_ = decode(b_.Content, FIXED_Content);

    value a1t;
    value a2t;

    bool v_1;
    value v_2 = p_1_;
    value v_3 = a_;
    v_1 = (v_2 == v_3);
    bool v_4 = v_1;
    if(!v_4) return false;
    bool v_5;
    uint v_6 = c_;
    uint v_7 = 3u;
    v_5 = (v_6 < v_7);
    bool v_8 = v_5;
    if(!v_8) return false;
    a1t = ALL_NOT_FOUND;
    a1t.material = Air;
    a2t = b_;
    uint v_9;
    uint v_10 = c_;
    uint v_11 = 1u;
    v_9 = (v_10 + v_11);
    if(v_9 >= 4u) return false;
    a2t.ChestCount = v_9;

    a1 = a1t;
    a2 = a2t;
    return true;
}

bool fillChestMinimal_r(inout value a1, inout value a2) {
    value a_ = a1;

    value b_ = a2;
    if(b_.ChestCount == NOT_FOUND || b_.Content == NOT_FOUND) return false;
    uint c_ = b_.ChestCount;
    value p_1_ = decode(b_.Content, FIXED_Content);

    value a1t;
    value a2t;

    bool v_1;
    value v_2 = p_1_;
    value v_3 = a_;
    v_1 = (v_2 == v_3);
    bool v_4 = v_1;
    if(!v_4) return false;
    a1t = ALL_NOT_FOUND;
    a1t.material = Air;
    a2t = b_;
    uint v_5;
    uint v_6 = c_;
    uint v_7 = 1u;
    v_5 = (v_6 + v_7);
    if(v_5 >= 4u) return false;
    a2t.ChestCount = v_5;

    a1 = a1t;
    a2 = a2t;
    return true;
}

bool fillChest2_r(inout value a1, inout value a2) {
    value x_ = a1;
    if(x_.Background == NOT_FOUND || x_.Foreground == NOT_FOUND) return false;
    value v_1 = decode(x_.Background, FIXED_Background);
    if(v_1.material != White) return false;
    value a_ = decode(x_.Foreground, FIXED_Foreground);
    if(a_.Resource == NOT_FOUND) return false;

    value y_ = a2;
    if(y_.Foreground == NOT_FOUND) return false;
    value b_ = decode(y_.Foreground, FIXED_Foreground);
    if(b_.ChestCount == NOT_FOUND || b_.Content == NOT_FOUND || b_.material != Chest) return false;
    uint c_ = b_.ChestCount;
    value p_1_ = decode(b_.Content, FIXED_Content);

    value a1t;
    value a2t;

    bool v_2;
    value v_3 = p_1_;
    value v_4 = a_;
    v_2 = (v_3 == v_4);
    bool v_5 = v_2;
    if(!v_5) return false;
    a1t = x_;
    value v_6;
    v_6 = ALL_NOT_FOUND;
    v_6.material = Air;
    a1t.Foreground = encode(v_6, FIXED_Foreground);
    a2t = y_;
    value v_7;
    v_7 = b_;
    uint v_8;
    uint v_9 = c_;
    uint v_10 = 1u;
    v_8 = (v_9 + v_10);
    if(v_8 >= 4u) return false;
    v_7.ChestCount = v_8;
    a2t.Foreground = encode(v_7, FIXED_Foreground);

    a1 = a1t;
    a2 = a2t;
    return true;
}

bool fillChest3_r(inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Resource == NOT_FOUND) return false;

    value b_ = a2;
    if(b_.ChestCount == NOT_FOUND || b_.Content == NOT_FOUND || b_.material != Chest) return false;
    uint c_ = b_.ChestCount;
    value p_1_ = decode(b_.Content, FIXED_Content);

    value a1t;
    value a2t;

    bool v_1;
    value v_2 = p_1_;
    value v_3 = a_;
    v_1 = (v_2 == v_3);
    bool v_4 = v_1;
    if(!v_4) return false;
    bool v_5;
    uint v_6 = c_;
    uint v_7 = 3u;
    v_5 = (v_6 < v_7);
    bool v_8 = v_5;
    if(!v_8) return false;
    a1t = ALL_NOT_FOUND;
    a1t.material = Air;
    a2t = b_;
    uint v_9;
    uint v_10 = c_;
    uint v_11 = 1u;
    v_9 = (v_10 + v_11);
    if(v_9 >= 4u) return false;
    a2t.ChestCount = v_9;

    a1 = a1t;
    a2 = a2t;
    return true;
}

bool stoneWaterCycle_r(inout value a1) {
    value a_ = a1;
    if(a_.Resource == NOT_FOUND) return false;

    value a1t;

    uint v_1;
    uint v_2 = 1u;
    uint v_3 = 2u;
    if(!max_f(v_2, v_3, v_1)) return false;
    uint x_ = v_1;
    value v_4;
    v_4 = a_;
    uint m_5 = 0u;
    switch(m_5) { case 0u:
        value v_6 = v_4;
        if(v_6.material != Stone) break;
        a1t = ALL_NOT_FOUND;
        a1t.material = Water;
        uint v_7;
        v_7 = x_;
        if(v_7 >= 4u) return false;
        a1t.Temperature = v_7;
        m_5 = 1;
    default: break; }
    switch(m_5) { case 0u:
        value v_8 = v_4;
        if(v_8.material != Water) break;
        a1t = ALL_NOT_FOUND;
        a1t.material = Stone;
        m_5 = 1;
    default: break; }
    if(m_5 == 0u) return false;

    a1 = a1t;
    return true;
}

void main() {
    ivec2 position = ivec2(gl_FragCoord.xy - 0.5);
    ivec2 offset = (step % 2 == 0) ? ivec2(1, 1) : ivec2(0, 0);
    ivec2 bottomLeft = (position + offset) / 2 * 2 - offset;

    // Read and parse relevant pixels
    value pp_0_0 = lookupValue(bottomLeft + ivec2(0, 0));
    value pp_0_1 = lookupValue(bottomLeft + ivec2(0, 1));
    value pp_1_0 = lookupValue(bottomLeft + ivec2(1, 0));
    value pp_1_1 = lookupValue(bottomLeft + ivec2(1, 1));

    // fallGroup
    bool fallGroup_d = false;
    bool fall_d = false;
    if(true) {
        if(true) {
            fall_d = fall_r(pp_0_1, pp_0_0) || fall_d;
            fall_d = fall_r(pp_1_1, pp_1_0) || fall_d;
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
            fillChest_d = fillChest_r(pp_0_1, pp_0_0) || fillChest_d;
            fillChest_d = fillChest_r(pp_1_1, pp_1_0) || fillChest_d;
            chestGroup_d = chestGroup_d || fillChest_d;
        }
        if(true) {
            fillChestMinimal_d = fillChestMinimal_r(pp_0_1, pp_0_0) || fillChestMinimal_d;
            fillChestMinimal_d = fillChestMinimal_r(pp_1_1, pp_1_0) || fillChestMinimal_d;
            chestGroup_d = chestGroup_d || fillChestMinimal_d;
        }
        if(true) {
            fillChest2_d = fillChest2_r(pp_0_1, pp_0_0) || fillChest2_d;
            fillChest2_d = fillChest2_r(pp_1_1, pp_1_0) || fillChest2_d;
            chestGroup_d = chestGroup_d || fillChest2_d;
        }
        if(true) {
            fillChest3_d = fillChest3_r(pp_0_1, pp_0_0) || fillChest3_d;
            fillChest3_d = fillChest3_r(pp_1_1, pp_1_0) || fillChest3_d;
            chestGroup_d = chestGroup_d || fillChest3_d;
        }
        if(true) {
            stoneWaterCycle_d = stoneWaterCycle_r(pp_0_0) || stoneWaterCycle_d;
            stoneWaterCycle_d = stoneWaterCycle_r(pp_0_1) || stoneWaterCycle_d;
            stoneWaterCycle_d = stoneWaterCycle_r(pp_1_0) || stoneWaterCycle_d;
            stoneWaterCycle_d = stoneWaterCycle_r(pp_1_1) || stoneWaterCycle_d;
            chestGroup_d = chestGroup_d || stoneWaterCycle_d;
        }
    }

    // Write and encode own value
    ivec2 quadrant = position - bottomLeft;
    value target = pp_0_0;
    if(quadrant == ivec2(0, 1)) target = pp_0_1;
    else if(quadrant == ivec2(1, 0)) target = pp_1_0;
    else if(quadrant == ivec2(1, 1)) target = pp_1_1;
    outputValue = encode(target, ALL_NOT_FOUND);

    if(step == 0) {
        value stone = ALL_NOT_FOUND;
        stone.material = Stone;
        value tileStone = ALL_NOT_FOUND;
        tileStone.material = Tile;
        tileStone.Foreground = encode(stone, FIXED_Foreground);

        value air = ALL_NOT_FOUND;
        air.material = Air;
        value tileAir = ALL_NOT_FOUND;
        tileAir.material = Tile;
        tileAir.Foreground = encode(air, FIXED_Foreground);

        if(int(position.x + position.y) % 4 == 0) outputValue = encode(tileStone, ALL_NOT_FOUND);
        else outputValue = outputValue = encode(tileAir, ALL_NOT_FOUND);
    }

}
