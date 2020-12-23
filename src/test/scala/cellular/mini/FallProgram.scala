package cellular.mini

object FallProgram {
    val code = """
        [properties]
        Tile(Resource)
        Weight(0..3)
        Resource
        Foreground(Resource)

        [materials]
        Air { Resource Weight(0) }
        Water { Resource Weight(1) }
        Stone { Resource Weight(2) }

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
