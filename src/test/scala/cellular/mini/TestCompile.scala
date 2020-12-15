package cellular.mini

object TestCompile {

    def main(args : Array[String]) : Unit = {
        val definitions = new Parser(ImpProgram.code).parseDefinitions()
        val glsl = Compiler.compile(definitions)
        println(glsl)
    }

}
