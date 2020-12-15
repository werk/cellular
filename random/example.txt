const uint NOT_FOUND = 4294967295u;

const uint SIZE_Content = 42;

const uint Chest = 0;
const uint Imp = 1;
const uint Stone = 2;
const uint IronOre = 3;
const uint Water = 4;
const uint Air = 5;
const uint Tile = 6;

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

const Value FIXED_Content = Value {
    material = NOT_FOUND;
    Weight = NOT_FOUND;
    Resource = NOT_FOUND;
    Temperature = 0;
    Content = NOT_FOUND;
    ChestCount = 0;
    Foreground = NOT_FOUND;
    Background = NOT_FOUND;
};

uint encode(Value value, Value fixed) {
    switch(value.material) {
        case Chest:
            uint result = 0;
            if(fixed.Content == NOT_FOUND) {
                result *= SIZE_Content;
                result += value.Content;
            }
            if(fixed.ChestCount == NOT_FOUND) {
                result *= SIZE_ChestCount;
                result += value.ChestCount;
            }
            result *= SIZE_material;
            result += value.material;
            return result;
    }
}

Value decode(uint number, Value fixed) {
    Value value;
    value.material = number % SIZE_material;
    uint remaining = number / SIZE_material;
    switch(value.material) {
        case Chest:
            if(fixed.ChestCount == NOT_FOUND) {
                value.ChestCount = remaining % SIZE_ChestCount;
                remaining /= SIZE_ChestCount;
            } else {
                value.ChestCount = fixed.ChestCount;
            }
            if(fixed.Content == NOT_FOUND) {
                value.Content = remaining % SIZE_Content;
                remaining /= SIZE_Content;
            } else {
                value.Content = fixed.Content;
            }
            return value;
    }
}
