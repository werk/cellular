package cellular.mini

object ImpProgram {
    val code = """
        [properties]

        Tile(Cell)
        Weight(0..3)
        Temperature(0..3)
        Content(Resource) { Temperature?(0) ChestCount?(0) Content?(0) }
        ChestCount(0..3)
        Foreground(Resource | Imp | Air)
        Background(Black | White)

        [materials]

        Chest { Content ChestCount Resource }
        Imp { Content }
        Stone { Weight(2) }
        IronOre { Temperature }
        Water { Temperature Weight(1) }
        Air { Weight(0) }
        Cell { Foreground Background }
        Black
        White

        [types]

        Resource = Stone | IronOre | Water.

        [function max(x uint, y uint) uint]

        x > y -> x | y

        [group fallGroup]

        [rule fall Foreground @h @v @90 @270 @180]

        a Weight(x).
        b Weight(y).
        -- x > y ->
        b.
        a.

        [group chestGroup !fallGroup]

        [rule fillChest Foreground]

        a Resource.
        b Chest Content(a) ChestCount(c).
        -- c < 3 ->
        Air.
        b ChestCount(c + 1).

        [rule fillChestMinimal Foreground]

        a.
        b Content(a) ChestCount(c).
        --
        Air.
        b ChestCount(c + 1).

        [rule fillChest2]

        x Foreground(a Resource) Background(White).
        y Foreground(b Chest Content(a) ChestCount(c)).
        --
        x Foreground(Air).
        y Foreground(b ChestCount(c + 1)).

        [rule fillChest3]

        a Resource.
        b Chest Content(a) ChestCount(c).
        -- c < 3 ->
        Air.
        b ChestCount(c + 1).

        [rule stoneWaterCycle]

        a Resource.
        --
        x = max(1, 2).
        a : Stone => Water Temperature(x).
          ; Water => Stone.
    """

}
