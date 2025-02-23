package cellular.language

object ParseValueTest {

    def main(args : Array[String]) : Unit = {

        val s1 = "Cave Foreground(Imp ImpStep(2) ImpClimb(None) DirectionH(Right) Content(None)) Background(None)"
        val v = new Parser(s1).parseValue()
        val s2 = v.toString
        println(s1)
        println(s2)
        println(s1 == s2)
    }

}
