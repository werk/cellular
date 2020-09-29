package cellular.experiments

import cellular.language.Compile
import cellular.language.Language._

object SandAndWater {

    def main(args : Array[String]) : Unit = {
        println(Compile.compile(SandAndWater.declarations))
    }


    /*
    : WEIGHT(10)
    : HEAT(5)

    AIR : WEIGHT(1) HEAT(5)
    WATER : WEIGHT(5) HEAT(5)
    SAND : WEIGHT(7) HEAT(5)
    LAVA : HEAT(5)

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
        DCellType("LAVA", List(
            CTrait("HEAT", Some(ENumber(5))) -> None,
        )),

        DGroup("Fall", EBool(true), List(
            Reaction("FallDown", List(),
                List(
                    List(CellPattern(Some("b"), None)),
                    List(CellPattern(Some("a"), None))
                ), {
                    val a = EPeek(0, 0)
                    val b = EPeek(0, 1)
                    List(
                        //EIs(a, "WEIGHT"),
                        //EIs(b, "WEIGHT"),
                        EBinary("=", EVariable("n"), EField(a, "WEIGHT")),
                        EIsDefined(EVariable("n")),
                        EBinary("=", EVariable("m"), EField(b, "WEIGHT")),
                        EIsDefined(EVariable("m")),
                        EBinary(">", EVariable("n"), EVariable("m")),
                    )
                }
            )
        )),

        DGroup("Wave", EUnary("!", EVariable("did_Fall")), List(
            Reaction("WaveLeft", List(),
                List(
                    List(CellPattern(Some("w"), None), CellPattern(Some("a"), None)),
                ), {
                    val a = EPeek(0, 0)
                    val w = EPeek(1, 0)
                    List(
                        EIs(a, "AIR"),
                        EIs(w, "WATER"),
                    )
                }
            )
        )),
    )
}
