#version 300 es
precision mediump float;
precision highp int;
uniform highp usampler2D state;
//uniform float seedling;
uniform int step;
out uint outputValue;
const uint NOT_FOUND = 4294967295u;

const uint Air = 0u;
const uint Water = 1u;
const uint Stone = 2u;
const uint Tile = 3u;

const uint SIZE_material = 4u;

const uint SIZE_Weight = 4u;
const uint SIZE_Resource = 1u;
const uint SIZE_Foreground = 3u;

struct value {
    uint material;
    uint Weight;
    uint Resource;
    uint Foreground;
};

const value ALL_NOT_FOUND = value(
    NOT_FOUND,
    NOT_FOUND,
    NOT_FOUND,
    NOT_FOUND
);

const value FIXED_Foreground = ALL_NOT_FOUND;

uint encode(value i, value fix) {
    uint result = 0u;
    switch(i.material) {
        case Tile:
            if(fix.Foreground == NOT_FOUND) {
                result *= SIZE_Foreground;
                result += i.Foreground;
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
        case Water:
            o.Weight = 1u;
            break;
        case Stone:
            o.Weight = 2u;
            break;
        case Tile:
            if(fix.Foreground == NOT_FOUND) {
                o.Foreground = remaining % SIZE_Foreground;
                remaining /= SIZE_Foreground;
            } else {
                o.Foreground = fix.Foreground;
            }
            break;
        default:
            break;
    }
    return o;
}

value lookupMaterial(ivec2 offset) {
    uint integer = texture(state, (vec2(offset) + 0.5) / 100.0/* / scale*/).r;
    return decode(integer, ALL_NOT_FOUND);
}

bool fall_r(inout value a1, inout value a2) {
    value a_ = a1;
    if(a_.Foreground == NOT_FOUND) return false;
    value v_1 = decode(a_.Foreground, FIXED_Foreground);
    if(v_1.Weight == NOT_FOUND) return false;
    uint x_ = v_1.Weight;

    value b_ = a2;
    if(b_.Foreground == NOT_FOUND) return false;
    value v_2 = decode(b_.Foreground, FIXED_Foreground);
    if(v_2.Weight == NOT_FOUND) return false;
    uint y_ = v_2.Weight;

    value a1t;
    value a2t;

    bool v_3;
    uint v_4 = x_;
    uint v_5 = y_;
    v_3 = (v_4 > v_5);
    bool v_6 = v_3;
    if(!v_6) return false;
    a1t = b_;
    a2t = a_;

    a1 = a1t;
    a2 = a2t;
    return true;
}

void main() {
    ivec2 position = ivec2(gl_FragCoord.xy - 0.5);
    ivec2 offset = (step % 2 == 0) ? ivec2(1, 1) : ivec2(0, 0);
    ivec2 bottomLeft = (position + offset) / 2 * 2 - offset;

    // Read and parse relevant pixels
    value pp_0_0 = lookupMaterial(bottomLeft + ivec2(0, 0));
    value pp_0_1 = lookupMaterial(bottomLeft + ivec2(0, 1));
    value pp_1_0 = lookupMaterial(bottomLeft + ivec2(1, 0));
    value pp_1_1 = lookupMaterial(bottomLeft + ivec2(1, 1));

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