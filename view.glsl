#version 300 es
precision mediump float;
precision highp int;

uniform highp usampler2D state;
uniform sampler2D materials;
uniform vec2 resolution;
uniform float t;
uniform vec2 offset;
uniform float zoom;
out vec4 outputColor;

const float tileSize = 12.0;
const vec2 tileMapSize = vec2(4096.0, 256.0);

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

// There are 532 different tiles

const uint Rock = 0u;
const uint Shaft = 1u;
const uint Cave = 2u;
const uint Building = 3u;
const uint ShaftImp = 4u;
const uint Empty = 5u;
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
);

uint Background_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Empty:
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

uint ShaftForeground_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Empty:
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
            n *= 1u;
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
            n += 448u + 28u;
            break;
        case Shaft:
            n *= 4u;
            n += v.DirectionHV;
            n *= 5u;
            n += v.ShaftForeground;
            n += 448u + 28u + 36u;
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

value ShaftForeground_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 1u) {
        v.material = Empty;
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
    if(n < 28u) {
        v.material = Cave;
        v.Foreground = n % 28u;
        n /= 28u;
        v.Background = n % 1u;
        n /= 1u;
        return v;
    }
    n -= 28u;
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

void materialOffset(value v, out uint front, out uint back) {
    front = NOT_FOUND;
    back = NOT_FOUND;
    switch(v.material) {
        case Cave:
            back = 0u;
            value foreground = Foreground_d(v.Foreground);
            switch(foreground.material) {
                case Imp:
                    value direction = DirectionH_d(foreground.DirectionH);
                    switch(direction.material) {
                        case Left:
                            front = 68u + foreground.ImpStep;
                            break;
                        case Right:
                            front = 71u + foreground.ImpStep;
                            break;
                        default:
                            front = 255u;
                            break;
                    }
                    break;
                case RockOre:
                    front = 9u; // Ice
                    break;
                case IronOre:
                    front = 20u;
                    break;
                case CoalOre:
                    front = 24u;
                    break;
                case Empty:
                    break;
                default:
                    front = 255u;
                    break;
            }
            break;
        case Shaft:
            value direction = DirectionHV_d(v.DirectionHV);
            switch(direction.material) {
                case Left:
                    back = 26u;
                    break;
                case Right:
                    back = 27u;
                    break;
                case Up:
                    back = 28u;
                    break;
                case Down:
                    back = 29u;
                    break;
            }
            value shaftForeground = ShaftForeground_d(v.ShaftForeground);
            switch(shaftForeground.material) {
                case ShaftImp:
                    front = 72u;
                    break;
            }
            break;
        case Rock:
            front = 6u;
            break;
        case Building:
            value buildingVariant = BuildingVariant_d(v.BuildingVariant);
            front = 128u + (buildingVariant.BigContentCount != NOT_FOUND ? buildingVariant.BigContentCount : 0u);
            break;
        default:
            front = 255u;
            break;
    }
}

bool testEncodeDecode(ivec2 tile) {
    uint n = uint(tile.x + tile.y * 10);
    value v = Tile_d(n);
    uint n2 = Tile_e(v);
    return n == n2;
}

vec4 tileColor(vec2 xy, uint offset) {
    vec2 spriteOffset = mod(xy, 1.0) * tileSize;
    vec2 tileMapOffset = vec2(float(offset) * tileSize, tileSize) + spriteOffset * vec2(1, -1);
    return texture(materials, tileMapOffset / tileMapSize);
}

vec4 blend(vec4 below, vec4 above) {
    return above * above.a + below * (1.0 - above.a);
}

void main() {
    vec2 stateSize = vec2(100, 100);

    float screenToMapRatio = zoom / resolution.x;
    vec2 xy = gl_FragCoord.xy * screenToMapRatio + offset;

    uint n = texelFetch(state, ivec2(xy), 0).r;
    value v = Tile_d(n);

    uint f;
    uint b;
    materialOffset(v, f, b);

    vec4 front = f == NOT_FOUND ? vec4(0) : tileColor(xy, f);
    vec4 back = b == NOT_FOUND ? vec4(0) : tileColor(xy, b);

    outputColor = vec4(0, 0, 0, 1);
    outputColor = blend(outputColor, back);
    outputColor = blend(outputColor, front);

    if(v.Light != NOT_FOUND) {
        outputColor = vec4((outputColor * float(v.Light) * (1.0/5.0)).rgb, 1.0);
    }

    if(v.Dig == 1u) {
        outputColor = blend(outputColor, vec4(1.0, 0.9, 0.0, 0.1));
    }

}