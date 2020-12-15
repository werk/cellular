package cellular.mini

object ImpProgram {
    val code = """
        [properties]

        Weight(0..3)
        Resource
        Temperature(0..3)
        Content(Resource) { Temperature?(0) ChestCount?(0) }
        ChestCount(0..3)
        Foreground(Resource | Imp | Air)
        Background(Black | White)

        [materials]

        Chest { Content ChestCount Resource }
        Imp { Content }
        Stone { Resource Weight(2) }
        IronOre { Resource Temperature }
        Water { Resource Temperature Weight(1) }
        Air { Weight(0) }
        Tile { Foreground Background }

        [group fallGroup]

        [rule fall Foreground @h @v @90 @270 @180]

        a Weight(x).
        b Weight(y)
        -- x > y ->
        b.
        a

        [group chestGroup !fallGroup]

        [rule fillChest Foreground]

        a Resource.
        b Chest Content(a) ChestCount(c)
        -- c < 3 ->
        Air.
        b Count(c + 1)

        [rule fillChestMinimal Foreground]

        a.
        b Content(a) ChestCount(c)
        --
        Air.
        b Count(c + 1)

        [rule fillChest2]

        x Foreground(a Resource) Background(White).
        y Foreground(b Chest Content(a) ChestCount(c))
        --
        x Foreground(Air).
        y Foreground(b Count(c + 1))

        [rule fillChest3]

        a Resource.
        b Chest Content(a) ChestCount(c)
        -- c < 3 ->
        Air.
        b Count(c + 1)
    """

}
