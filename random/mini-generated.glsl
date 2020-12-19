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

const uint SIZE_Weight = 4u;
const uint SIZE_Resource = 1u;
const uint SIZE_Temperature = 4u;
const uint SIZE_Content = 4u;
const uint SIZE_ChestCount = 4u;
const uint SIZE_Foreground = 30u;
const uint SIZE_Background = 2u;

struct Value {
    uint material;
    uint Weight;
    uint Resource;
    uint Temperature;
    uint Content;
    uint ChestCount;
    uint Foreground;
    uint Background;
};

uint encode(Value value, Value fix) {
    uint result = 0u;
    switch(value.material) {
        case Imp:
            if(fix.Content == NOT_FOUND) {
                result *= SIZE_Content;
                result += value.Content;
            }
            break;
        case Tile:
            if(fix.Background == NOT_FOUND) {
                result *= SIZE_Background;
                result += value.Background;
            }
            if(fix.Foreground == NOT_FOUND) {
                result *= SIZE_Foreground;
                result += value.Foreground;
            }
            break;
        case IronOre:
            if(fix.Temperature == NOT_FOUND) {
                result *= SIZE_Temperature;
                result += value.Temperature;
            }
            break;
        case Chest:
            if(fix.ChestCount == NOT_FOUND) {
                result *= SIZE_ChestCount;
                result += value.ChestCount;
            }
            if(fix.Content == NOT_FOUND) {
                result *= SIZE_Content;
                result += value.Content;
            }
            break;
        case Water:
            if(fix.Temperature == NOT_FOUND) {
                result *= SIZE_Temperature;
                result += value.Temperature;
            }
            break;
        default:
    }
    result *= SIZE_material;
    result += value.material;
    return result;
}

Value decode(uint number, Value fix) {
    Value value = ALL_NOT_FOUND;
    value.material = number % SIZE_material;
    uint remaining = number / SIZE_material;
    switch(value.material) {
        case Air:
            value.Weight = 0u;
            break;
        case Imp:
            if(fix.Content == NOT_FOUND) {
                value.Content = remaining % SIZE_Content;
                remaining /= SIZE_Content;
            } else {
                value.Content = fix.Content;
            }
            break;
        case Tile:
            if(fix.Background == NOT_FOUND) {
                value.Background = remaining % SIZE_Background;
                remaining /= SIZE_Background;
            } else {
                value.Background = fix.Background;
            }
            if(fix.Foreground == NOT_FOUND) {
                value.Foreground = remaining % SIZE_Foreground;
                remaining /= SIZE_Foreground;
            } else {
                value.Foreground = fix.Foreground;
            }
            break;
        case IronOre:
            if(fix.Temperature == NOT_FOUND) {
                value.Temperature = remaining % SIZE_Temperature;
                remaining /= SIZE_Temperature;
            } else {
                value.Temperature = fix.Temperature;
            }
            break;
        case Stone:
            value.Weight = 2u;
            break;
        case Chest:
            if(fix.ChestCount == NOT_FOUND) {
                value.ChestCount = remaining % SIZE_ChestCount;
                remaining /= SIZE_ChestCount;
            } else {
                value.ChestCount = fix.ChestCount;
            }
            if(fix.Content == NOT_FOUND) {
                value.Content = remaining % SIZE_Content;
                remaining /= SIZE_Content;
            } else {
                value.Content = fix.Content;
            }
            break;
        case Water:
            if(fix.Temperature == NOT_FOUND) {
                value.Temperature = remaining % SIZE_Temperature;
                remaining /= SIZE_Temperature;
            } else {
                value.Temperature = fix.Temperature;
            }
            value.Weight = 1u;
            break;
        default:
    }
    return value;
}

bool fall(Value a1, Value a2) {
    Value a_ = a1;
    if(a_.Weight == NOT_FOUND) return false;
    uint x_ = a_.Weight;

    Value b_ = a2;
    if(b_.Weight == NOT_FOUND) return false;
    uint y_ = b_.Weight;

    bool v_1;
    uint v_2 = x_;
    uint v_3 = y_;
    v_1 = (v_2 > v_3);
    bool v_4 = v_1;
    if(!v_4) return false;
    a1 = b_;
    a2 = a_;
    return true;
}

bool fillChest(Value a1, Value a2) {
    Value a_ = a1;
    if(a_.Resource == NOT_FOUND) return false;

    Value b_ = a2;
    if(b_.ChestCount == NOT_FOUND || b_.Content == NOT_FOUND || b_.material != Chest) return false;
    uint c_ = b_.ChestCount;
    Value a_ = decode(b_.Content, FIXED_Content);

    bool v_1;
    uint v_2 = c_;
    uint v_3 = 3u;
    v_1 = (v_2 < v_3);
    bool v_4 = v_1;
    if(!v_4) return false;
    a1 = ALL_NOT_FOUND;
    a1.material = 5u;
    a2 = b_;
    uint v_5;
    uint v_6 = c_;
    uint v_7 = 1u;
    v_5 = (v_6 + v_7);
    a2.ChestCount = v_5;
    return true;
}

bool fillChestMinimal(Value a1, Value a2) {
    Value a_ = a1;

    Value b_ = a2;
    if(b_.ChestCount == NOT_FOUND || b_.Content == NOT_FOUND) return false;
    uint c_ = b_.ChestCount;
    Value a_ = decode(b_.Content, FIXED_Content)

    a1 = ALL_NOT_FOUND;
    a1.material = 5u;
    a2 = b_;
    uint v_1;
    uint v_2 = c_;
    uint v_3 = 1u;
    v_1 = (v_2 + v_3);
    a2.ChestCount = v_1;
    return true;
}

bool fillChest2(Value a1, Value a2) {
    Value x_ = a1;
    if(x_.Background == NOT_FOUND || x_.Foreground == NOT_FOUND) return false;
    Value v_1 = decode(x_.Background, FIXED_Background)
    if(v_1.material != White) return false;
    Value a_ = decode(x_.Foreground, FIXED_Foreground)
    if(a_.Resource == NOT_FOUND) return false;

    Value y_ = a2;
    if(y_.Foreground == NOT_FOUND) return false;
    Value b_ = decode(y_.Foreground, FIXED_Foreground)
    if(b_.ChestCount == NOT_FOUND || b_.Content == NOT_FOUND || b_.material != Chest) return false;
    uint c_ = b_.ChestCount;
    Value a_ = decode(b_.Content, FIXED_Content)

    a1 = x_;
    Value v_1;
    v_1 = ALL_NOT_FOUND;
    v_1.material = 5u;
    a1.Foreground = encode(v_1, FIXED_Foreground)
    a2 = y_;
    Value v_2;
    v_2 = b_;
    uint v_3;
    uint v_4 = c_;
    uint v_5 = 1u;
    v_3 = (v_4 + v_5);
    v_2.ChestCount = v_3;
    a2.Foreground = encode(v_2, FIXED_Foreground);
    return true;
}

bool fillChest3(Value a1, Value a2) {
    Value a_ = a1;
    if(a_.Resource == NOT_FOUND) return false;

    Value b_ = a2;
    if(b_.ChestCount == NOT_FOUND || b_.Content == NOT_FOUND || b_.material != Chest) return false;
    uint c_ = b_.ChestCount;
    Value a_ = decode(b_.Content, FIXED_Content);

    bool v_1;
    uint v_2 = c_;
    uint v_3 = 3u;
    v_1 = (v_2 < v_3);
    bool v_4 = v_1;
    if(!v_4) return false;
    a1 = ALL_NOT_FOUND;
    a1.material = 5u;
    a2 = b_;
    uint v_5;
    uint v_6 = c_;
    uint v_7 = 1u;
    v_5 = (v_6 + v_7);
    a2.ChestCount = v_5;
    return true;
}

void main() {
    ivec2 position = ivec2(gl_FragCoord.xy - 0.5);
    ivec2 offset = (step % 2 == 0) ? ivec2(1, 1) : ivec2(0, 0);
    ivec2 bottomLeft = (position + offset) / 2 * 2 - offset;

    // Read and parse relevant pixels
    Value pp_0_0 = lookupMaterial(bottomLeft + ivec2(0, 0));
    Value pp_0_1 = lookupMaterial(bottomLeft + ivec2(0, 1));
    Value pp_1_0 = lookupMaterial(bottomLeft + ivec2(1, 0));
    Value pp_1_1 = lookupMaterial(bottomLeft + ivec2(1, 1));

    // fallGroup
    bool did_fallGroup = false;
    bool did_fall = false;
    if(true) {
        if(true) {
            did_fall = rule_fall(pp_0_1, pp_0_0) || did_fall;
            did_fall = rule_fall(pp_1_1, pp_1_0) || did_fall;
            did_fallGroup = did_fallGroup || did_fall;
        }
    }

    // chestGroup
    bool did_chestGroup = false;
    bool did_fillChest = false;
    bool did_fillChestMinimal = false;
    bool did_fillChest2 = false;
    bool did_fillChest3 = false;
    if(!did_fallGroup) {
        if(true) {
            did_fillChest = rule_fillChest(pp_0_1, pp_0_0) || did_fillChest;
            did_fillChest = rule_fillChest(pp_1_1, pp_1_0) || did_fillChest;
            did_chestGroup = did_chestGroup || did_fillChest;
        }
        if(true) {
            did_fillChestMinimal = rule_fillChestMinimal(pp_0_1, pp_0_0) || did_fillChestMinimal;
            did_fillChestMinimal = rule_fillChestMinimal(pp_1_1, pp_1_0) || did_fillChestMinimal;
            did_chestGroup = did_chestGroup || did_fillChestMinimal;
        }
        if(true) {
            did_fillChest2 = rule_fillChest2(pp_0_1, pp_0_0) || did_fillChest2;
            did_fillChest2 = rule_fillChest2(pp_1_1, pp_1_0) || did_fillChest2;
            did_chestGroup = did_chestGroup || did_fillChest2;
        }
        if(true) {
            did_fillChest3 = rule_fillChest3(pp_0_1, pp_0_0) || did_fillChest3;
            did_fillChest3 = rule_fillChest3(pp_1_1, pp_1_0) || did_fillChest3;
            did_chestGroup = did_chestGroup || did_fillChest3;
        }
    }

    // Write and encode own value
    ivec2 quadrant = position - bottomLeft;
    Value target = pp_0_0;
    if(quadrant == ivec2(0, 1)) target = pp_0_1;
    else if(quadrant == ivec2(1, 0)) target = pp_1_0;
    else if(quadrant == ivec2(1, 1)) target = pp_1_1;
    outputValue = encode(target);
}