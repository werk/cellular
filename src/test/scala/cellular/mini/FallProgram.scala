package cellular.mini

object FallProgram {
    val code = """
        [properties]
        Tile(Resource)
        Weight(0..3)
        Foreground(Resource)

        [materials]
        Air { Weight(0) }
        Water { Weight(1) }
        Stone { Weight(2) }

        [types]
        Resource = Air | Water | Stone.

        [group fallGroup]

        [rule fall]

        a Weight(x).
        b Weight(y).
        -- x > y ->
        b.
        a.
    """

    def main(args : Array[String]) : Unit = {
        val definitions = new Parser(code).parseDefinitions()
        val glsl = Compiler.compile(definitions)
        println(glsl)
    }

}
