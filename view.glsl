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

// There are 1124 different tiles

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
const uint Imp = 13u;
const uint SmallChest = 14u;
const uint BigChest = 15u;
const uint FactorySide = 16u;
const uint FactoryTop = 17u;
const uint FactoryBottom = 18u;
const uint Ladder = 19u;
const uint Sign = 20u;

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
    uint DirectionV;
    uint DirectionHV;
    uint ImpClimb;
    uint ImpStep;
    uint Content;
    uint SmallContentCount;
    uint BigContentCount;
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
);

uint Background_e(value v) {
    uint n = 0u;
    switch(v.material) {
        case Ladder:
            break;
        case None:
            n += 1u;
            break;
        case Sign:
            n *= 2u;
            n += v.DirectionV;
            n += 1u + 1u;
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
        case FactoryBottom:
            n *= 4u;
            n += v.Content;
            n *= 2u;
            n += v.FactoryFedLeft;
            n *= 2u;
            n += v.FactoryFedRight;
            n *= 11u;
            n += v.FactoryProduced;
            n += 404u;
            break;
        case FactorySide:
            n *= 4u;
            n += v.Content;
            n *= 2u;
            n += v.DirectionH;
            n *= 2u;
            n += v.DirectionV;
            n *= 6u;
            n += v.FactorySideCount;
            n += 404u + 176u;
            break;
        case FactoryTop:
            n *= 11u;
            n += v.FactoryCountdown;
            n *= 2u;
            n += v.FactoryFedLeft;
            n *= 2u;
            n += v.FactoryFedRight;
            n += 404u + 176u + 96u;
            break;
        case SmallChest:
            n *= 4u;
            n += v.Content;
            n *= 11u;
            n += v.SmallContentCount;
            n += 404u + 176u + 96u + 44u;
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
            n *= 4u;
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
            n += 1u + 72u;
            break;
        case None:
            n += 1u + 72u + 1u;
            break;
        case RockOre:
            n += 1u + 72u + 1u + 1u;
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
            n *= 764u;
            n += v.BuildingVariant;
            break;
        case Cave:
            n *= 4u;
            n += v.Background;
            n *= 76u;
            n += v.Foreground;
            n += 764u;
            break;
        case Rock:
            n *= 2u;
            n += v.Dig;
            n *= 6u;
            n += v.Light;
            n *= 3u;
            n += v.Vein;
            n += 764u + 304u;
            break;
        case Shaft:
            n *= 4u;
            n += v.DirectionHV;
            n *= 5u;
            n += v.ShaftForeground;
            n += 764u + 304u + 36u;
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
        v.material = Ladder;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = None;
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
    if(n < 404u) {
        v.material = BigChest;
        v.Content = n % 4u;
        n /= 4u;
        v.BigContentCount = n % 101u;
        n /= 101u;
        return v;
    }
    n -= 404u;
    if(n < 176u) {
        v.material = FactoryBottom;
        v.FactoryProduced = n % 11u;
        n /= 11u;
        v.FactoryFedRight = n % 2u;
        n /= 2u;
        v.FactoryFedLeft = n % 2u;
        n /= 2u;
        v.Content = n % 4u;
        n /= 4u;
        return v;
    }
    n -= 176u;
    if(n < 96u) {
        v.material = FactorySide;
        v.FactorySideCount = n % 6u;
        n /= 6u;
        v.DirectionV = n % 2u;
        n /= 2u;
        v.DirectionH = n % 2u;
        n /= 2u;
        v.Content = n % 4u;
        n /= 4u;
        return v;
    }
    n -= 96u;
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
        v.material = IronOre;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = None;
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
    if(n < 72u) {
        v.material = Imp;
        v.ImpStep = n % 3u;
        n /= 3u;
        v.ImpClimb = n % 3u;
        n /= 3u;
        v.DirectionH = n % 2u;
        n /= 2u;
        v.Content = n % 4u;
        n /= 4u;
        return v;
    }
    n -= 72u;
    if(n < 1u) {
        v.material = IronOre;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = None;
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

value ImpClimb_d(uint n) {
    value v = ALL_NOT_FOUND;
    if(n < 1u) {
        v.material = Down;
        return v;
    }
    n -= 1u;
    if(n < 1u) {
        v.material = None;
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
    if(n < 764u) {
        v.material = Building;
        v.BuildingVariant = n % 764u;
        n /= 764u;
        return v;
    }
    n -= 764u;
    if(n < 304u) {
        v.material = Cave;
        v.Foreground = n % 76u;
        n /= 76u;
        v.Background = n % 4u;
        n /= 4u;
        return v;
    }
    n -= 304u;
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

void materialOffset(value v, out uint front, out uint back, out uint cargo, out vec2 cargoOffset, out float cargoScale) {
    front = NOT_FOUND;
    back = NOT_FOUND;
    cargo = NOT_FOUND;
    switch(v.material) {
        case Cave:
            value background = Background_d(v.Background);
            switch(background.material) {
                case Ladder:
                    back = 80u;
                    break;
                case Sign:
                    value directionV = DirectionV_d(background.DirectionV);
                    back = 81u + (directionV.material == Up ? 0u : 1u);
                    break;
                case None:
                    break;
                default:
                    back = 255u;
                    break;
            }
            value foreground = Foreground_d(v.Foreground);
            switch(foreground.material) {
                case Imp:
                    value direction = DirectionH_d(foreground.DirectionH);
                    value climb = ImpClimb_d(foreground.ImpClimb);
                    value content = Content_d(foreground.DirectionH);
                    uint impStep = foreground.ImpStep;
                    if(climb.material == Down) impStep = 2u - impStep;
                    if(climb.material != None) impStep += 6u;
                    switch(direction.material) {
                        case Left:
                            front = 68u + impStep;
                            cargoScale = 4.0; // sprite pixels
                            cargoOffset = vec2(12.0 - cargoScale - (2.0 + float(impStep) * 3.0), 4.0);
                            break;
                        case Right:
                            front = 71u + impStep;
                            cargoScale = 4.0;
                            cargoOffset = vec2(2.0 + float(impStep) * 3.0, 4.0);
                            break;
                        default:
                            front = 255u;
                            break;
                    }
                    switch(content.material) {
                        case None:
                            break;
                        case RockOre:
                            cargo = front = 9u; // Ice
                            break;
                        case IronOre:
                            cargo = 20u;
                            break;
                        case CoalOre:
                            cargo = 24u;
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
                case None:
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
            switch(buildingVariant.material) {
                case FactorySide:
                    value factoryDirectionH = DirectionH_d(buildingVariant.DirectionH);
                    value factoryDirectionV = DirectionV_d(buildingVariant.DirectionV);
                    if(factoryDirectionH.material == Left) {
                        front = (factoryDirectionV.material == Up) ? 88u : 90u;
                    } else {
                        front = (factoryDirectionV.material == Up) ? 89u : 91u;
                    }
                    break;
                case FactoryBottom:
                    front = 92u;
                    break;
                case FactoryTop:
                    front = 93u + 5u - (buildingVariant.FactoryCountdown / 2u);
                    break;
                case BigChest:
                    front = 128u + (buildingVariant.BigContentCount != NOT_FOUND ? buildingVariant.BigContentCount : 0u);
                    break;
                default:
                    front = 255u;
                    break;
            }
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

vec4 backgroundPattern(vec2 xy) {
    vec2 offset = vec2(tileMapSize.x - 27.0, 120) + vec2(mod(xy.x * tileSize, 27.0), mod(xy.y * tileSize, 23.0)) * vec2(1, -1);
    return texture(materials, offset / tileMapSize);
}

vec4 shroudPattern(vec2 xy) {
    vec2 offset = vec2(tileMapSize.x - 67.0, 120 - 23) + vec2(mod(xy.x * tileSize, 67.0), mod(xy.y * tileSize, 47.0)) * vec2(1, -1);
    return texture(materials, offset / tileMapSize);
}

void main() {
    vec2 stateSize = vec2(100, 100);

    float screenToMapRatio = zoom / resolution.x;
    vec2 xy = gl_FragCoord.xy * screenToMapRatio + offset;

    if(int(xy.x) < 0 || int(xy.x) >= int(stateSize.x) || int(xy.y) < 0 || int(xy.y) >= int(stateSize.y)) {
        outputColor = shroudPattern(xy);
        return;
    }

    uint n = texelFetch(state, ivec2(xy), 0).r;
    value v = Tile_d(n);

    uint f;
    uint b;
    uint c;
    vec2 cargoOffset;
    float cargoScale;
    materialOffset(v, f, b, c, cargoOffset, cargoScale);
    cargoOffset /= tileSize;
    cargoScale /= tileSize;

    vec2 spriteUnitOffset = mod(xy, 1.0);

    vec4 cargo = vec4(0);
    if(c != NOT_FOUND &&
        spriteUnitOffset.x > cargoOffset.x && spriteUnitOffset.x < cargoOffset.x + cargoScale &&
        spriteUnitOffset.y > cargoOffset.y && spriteUnitOffset.y < cargoOffset.y + cargoScale
    ) {
        vec2 scaledSpriteUnitOffset = (spriteUnitOffset - cargoOffset) / cargoScale;
        cargo = tileColor(scaledSpriteUnitOffset, c);
    }

    vec4 front = f == NOT_FOUND ? vec4(0) : tileColor(spriteUnitOffset, f);
    vec4 back = b == NOT_FOUND ? vec4(0) : tileColor(spriteUnitOffset, b);

    outputColor = backgroundPattern(xy);
    outputColor = blend(outputColor, back);
    outputColor = blend(outputColor, front);
    outputColor = blend(outputColor, cargo);

    if(v.Light != NOT_FOUND) {
        float light = float(v.Light) * (1.0/5.0);
        outputColor = vec4(blend(outputColor * light, vec4(shroudPattern(xy).rgb, 1.0 - light)).rgb, 1.0);
    }

    if(v.Dig == 1u) {
        outputColor = blend(outputColor, vec4(1.0, 0.9, 0.0, 0.1));
    }

}