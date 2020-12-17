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

const uint SIZE_Weight = 0u;
const uint SIZE_Resource = 0u;
const uint SIZE_Temperature = 0u;
const uint SIZE_Content = 0u;
const uint SIZE_ChestCount = 0u;
const uint SIZE_Foreground = 0u;
const uint SIZE_Background = 0u;

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
        case Air:
            break;
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
        case Water:
            if(fix.Temperature == NOT_FOUND) {
                result *= SIZE_Temperature;
                result += value.Temperature;
            }
            if(fix.Resource == NOT_FOUND) {
                result *= SIZE_Resource;
                result += value.Resource;
            }
            break;
        case IronOre:
            if(fix.Temperature == NOT_FOUND) {
                result *= SIZE_Temperature;
                result += value.Temperature;
            }
            if(fix.Resource == NOT_FOUND) {
                result *= SIZE_Resource;
                result += value.Resource;
            }
            break;
        case Stone:
            if(fix.Resource == NOT_FOUND) {
                result *= SIZE_Resource;
                result += value.Resource;
            }
            break;
        case Chest:
            if(fix.Resource == NOT_FOUND) {
                result *= SIZE_Resource;
                result += value.Resource;
            }
            if(fix.ChestCount == NOT_FOUND) {
                result *= SIZE_ChestCount;
                result += value.ChestCount;
            }
            if(fix.Content == NOT_FOUND) {
                result *= SIZE_Content;
                result += value.Content;
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
        case Water:
            if(fix.Temperature == NOT_FOUND) {
                value.Temperature = remaining % SIZE_Temperature;
                remaining /= SIZE_Temperature;
            } else {
                value.Temperature = fix.Temperature;
            }
            if(fix.Resource == NOT_FOUND) {
                value.Resource = remaining % SIZE_Resource;
                remaining /= SIZE_Resource;
            } else {
                value.Resource = fix.Resource;
            }
            value.Weight = 1u;
            break;
        case IronOre:
            if(fix.Temperature == NOT_FOUND) {
                value.Temperature = remaining % SIZE_Temperature;
                remaining /= SIZE_Temperature;
            } else {
                value.Temperature = fix.Temperature;
            }
            if(fix.Resource == NOT_FOUND) {
                value.Resource = remaining % SIZE_Resource;
                remaining /= SIZE_Resource;
            } else {
                value.Resource = fix.Resource;
            }
            break;
        case Stone:
            if(fix.Resource == NOT_FOUND) {
                value.Resource = remaining % SIZE_Resource;
                remaining /= SIZE_Resource;
            } else {
                value.Resource = fix.Resource;
            }
            value.Weight = 2u;
            break;
        case Chest:
            if(fix.Resource == NOT_FOUND) {
                value.Resource = remaining % SIZE_Resource;
                remaining /= SIZE_Resource;
            } else {
                value.Resource = fix.Resource;
            }
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
        default:
    }
    return value;
}

bool fall(Value a1, Value a2) {
    return false; // TODO
}

bool fillChest(Value a1, Value a2) {
    return false; // TODO
}

bool fillChestMinimal(Value a1, Value a2) {
    return false; // TODO
}

bool fillChest2(Value a1, Value a2) {
    return false; // TODO
}

bool fillChest3(Value a1, Value a2) {
    return false; // TODO
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
    if(false /* TODO */) {
        did_fall = rule_fall(pp_0_1, pp_0_0) || did_fall;
        did_fall = rule_fall(pp_1_1, pp_1_0) || did_fall;
        did_fallGroup = did_fallGroup || did_fall;
    }

    // chestGroup
    bool did_chestGroup = false;
    bool did_fillChest = false;
    bool did_fillChestMinimal = false;
    bool did_fillChest2 = false;
    bool did_fillChest3 = false;
    if() {
        if(false /* TODO */) {
            did_fillChest = rule_fillChest(pp_0_1, pp_0_0) || did_fillChest;
            did_fillChest = rule_fillChest(pp_1_1, pp_1_0) || did_fillChest;
            did_chestGroup = did_chestGroup || did_fillChest;
        }
        if(false /* TODO */) {
            did_fillChestMinimal = rule_fillChestMinimal(pp_0_1, pp_0_0) || did_fillChestMinimal;
            did_fillChestMinimal = rule_fillChestMinimal(pp_1_1, pp_1_0) || did_fillChestMinimal;
            did_chestGroup = did_chestGroup || did_fillChestMinimal;
        }
        if(false /* TODO */) {
            did_fillChest2 = rule_fillChest2(pp_0_1, pp_0_0) || did_fillChest2;
            did_fillChest2 = rule_fillChest2(pp_1_1, pp_1_0) || did_fillChest2;
            did_chestGroup = did_chestGroup || did_fillChest2;
        }
        if(false /* TODO */) {
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