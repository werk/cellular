package experiments

import language.Language._

object SandAndWater {

    /*
    : WEIGHT(10)
    : HEAT(5)

    AIR : WEIGHT(1) HEAT(5)
    WATER : WEIGHT(5) HEAT(5)
    SAND : WEIGHT(7) HEAT(5)

    [Fall]:
    a : WEIGHT(n)
    b : WEIGHT(m)
    n > m
    -------> [FallDown]
    b
    a

    [Wave]:
    a : AIR    w : WATER
    --------------------> [WaveLeft]
    w          a
     */
    val declarations = List(
        DTrait("WEIGHT", TNumber(10)),
        DTrait("HEAT", TNumber(5)),

        DCellType("AIR", List(
            CTrait("WEIGHT", Some(ENumber(1))) -> None,
            CTrait("HEAT", Some(ENumber(5))) -> None,
        )),
        DCellType("WATER", List(
            CTrait("WEIGHT", Some(ENumber(5))) -> None,
            CTrait("HEAT", Some(ENumber(5))) -> None,
        )),
        DCellType("SAND", List(
            CTrait("WEIGHT", Some(ENumber(7))) -> None,
            CTrait("HEAT", Some(ENumber(5))) -> None,
        )),

        DGroup("Fall", EBool(true), List(
            Reaction("FallDown", List(),
                List(
                    List(CellPattern(Some("b"), None)),
                    List(CellPattern(Some("a"), None))
                ), List(
                    EBinary("=", EVariable("a"), EPeek(0, 0)),
                    EBinary("=", EVariable("b"), EPeek(0, 1)),
                    EIs(EVariable("a"), "WEIGHT"),
                    EIs(EVariable("b"), "WEIGHT"),
                    EBinary("=", EVariable("n"), EField(EVariable("a"), "WEIGHT")),
                    EBinary("=", EVariable("m"), EField(EVariable("b"), "WEIGHT")),
                    EBinary(">", EVariable("n"), EVariable("m")),
                    //EBinary("=", EPeek(0, 0),  EVariable("b")),
                    //EBinary("=", EPeek(0, 1), EVariable("a")),
                )
            )
        )),

        DGroup("Wave", EUnary("!", EVariable("did_Fall")), List(
            Reaction("WaveLeft", List(),
                List(
                    List(CellPattern(Some("w"), None), CellPattern(Some("a"), None)),
                ), List(
                    EBinary("=", EVariable("a"), EPeek(0, 0)),
                    EBinary("=", EVariable("w"), EPeek(1, 0)),
                    EIs(EVariable("a"), "AIR"),
                    EIs(EVariable("w"), "WATER"),
                )
            )
        )),
    )
}
