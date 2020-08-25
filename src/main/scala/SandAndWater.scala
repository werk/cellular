import Language._

object SandAndWater {

    /*
    : WEIGHT(10)

    AIR : WEIGHT(1)
    WATER : WEIGHT(5)
    SAND : WEIGHT(7)

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

        DCellType("AIR", List(CTrait("WEIGHT", Some(ENumber(1))) -> None)),
        DCellType("WATER", List(CTrait("WEIGHT", Some(ENumber(5))) -> None)),
        DCellType("SAND", List(CTrait("WEIGHT", Some(ENumber(7))) -> None)),

        DGroup("Fall", EBool(true), List(
            Reaction("FallDown", List(), List(), List()) // TODO
        )),

        DGroup("Wave", EBool(true), List(
            Reaction("WaveLeft", List(), List(), List()) // TODO
        )),
    )
}
