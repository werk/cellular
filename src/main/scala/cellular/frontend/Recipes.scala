package cellular.frontend

import cellular.language.{PropertyValue, Value}

object Recipes {

    case class Recipe(tiles : List[List[Value]], ingredients : Map[Value, Int])

    val imp = Recipe(
        tiles = List(List(M.imp(P.directionHRight))),
        ingredients = Map()
    )

    val platform = Recipe(
        tiles = List(List(M.platform)),
        ingredients = Map(M.rockOre -> 1)
    )

    val ladder = Recipe(
        tiles = List(List(M.ladder)),
        ingredients = Map(M.rockOre -> 1)
    )

    val signUp = Recipe(
        tiles = List(List(M.sign(P.directionVUp))),
        ingredients = Map(M.rockOre -> 1)
    )

    val signDown = Recipe(
        tiles = List(List(M.sign(P.directionVDown))),
        ingredients = Map(M.rockOre -> 1)
    )

    val bigChest = Recipe(
        tiles = List(List(M.bigChest(M.rockOre))),
        ingredients = Map(M.rockOre -> 1)
    )

    val factory = Recipe(
        tiles = List(
            List(
                M.factorySide(P.directionHLeft, P.directionVUp),
                M.factoryTop,
                M.factorySide(P.directionHRight, P.directionVUp)
            ),
            List(
                M.factorySide(P.directionHLeft, P.directionVDown),
                M.factoryBottom(M.coalOre),
                M.factorySide(P.directionHRight, P.directionVDown)
            )
        ).reverse, // TODO
        ingredients = Map(M.rockOre -> 10)
    )

}

private object M {
    val none = Value(0, "None", List())
    val rockOre = Value(0, "RockOre", List())
    val ironOre = Value(0, "IronOre", List())
    val coalOre = Value(0, "CoalOre", List())

    def imp(directionH : PropertyValue) = cave(
        Value(0, "Imp", List(
            P.number("ImpStep", 0),
            PropertyValue(0, "ImpClimb", M.none),
            directionH,
            P.content(none)
        )),
        none
    )

    val platform = cave(none, Value(0, "Platform", List()))
    val ladder = cave(none, Value(0, "Ladder", List()))

    def sign(directionV : PropertyValue) = cave(none, Value(0, "Sign", List(directionV)))

    def bigChest(resourceType : Value) = building(Value(0, "BigChest", List(
        P.content(resourceType), P.number("BigContentCount", 0)
    )))

    def factorySide(directionH : PropertyValue, directionV : PropertyValue) = {
        building(Value(0, "FactorySide", List(
            P.content(M.none),
            P.number("FactorySideCount", 0),
            directionH,
            directionV,
        )))
    }

    val factoryTop = building(Value(0, "FactoryTop", List(
        P.number("FactoryFedLeft", 0),
        P.number("FactoryFedRight", 0),
        P.number("FactoryCountdown", 10),
    )))

    def factoryBottom(resourceType : Value) = building(Value(0, "FactoryBottom", List(
        P.number("FactoryFedLeft", 0),
        P.number("FactoryFedRight", 0),
        P.number("FactoryProduced", 10),
        P.content(resourceType)
    )))

    def cave(foreground : Value, background : Value) = Value(0, "Cave", List(
        PropertyValue(0, "Foreground", foreground),
        PropertyValue(0, "Background", background),
    ))

    def building(variant : Value) = Value(0, "Building", List(
        PropertyValue(0, "BuildingVariant", variant)
    ))
}

private object P {
    def number(name : String, n : Int) = PropertyValue(0, name, Value(0, n.toString, List()))
    def content(resourceType : Value) = PropertyValue(0, "Content", resourceType)
    val directionHLeft = PropertyValue(0, "DirectionH", Value(0, "Left", List()))
    val directionHRight = PropertyValue(0, "DirectionH", Value(0, "Right", List()))
    val directionVUp = PropertyValue(0, "DirectionV", Value(0, "Up", List()))
    val directionVDown = PropertyValue(0, "DirectionV", Value(0, "Down", List()))
}
