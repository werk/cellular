package cellular.mini

object Compiler {

    def compile(definitions : List[Definition]) : String = {
        val context : TypeContext = TypeContext.fromDefinitions(definitions)

        blocks(
            head,
            makeMaterialIds(context),
            makePropertySizes(context),
            makeValueStruct(context),
            makeEncodeFunction(context),
            makeDecodeFunction(context),
            blocks(makeRuleFunctions(context)),
            makeMain(makeRules(context))
        )
    }

    val head : String = lines(
        "#version 300 es",
        "precision mediump float;",
        "precision highp int;",
        "",
        "uniform highp usampler2D state;",
        "//uniform float seedling;",
        "uniform int step;",
        "out uint outputValue;",
        "",
        "const uint NOT_FOUND = 4294967295u;",
    )

    def makeMaterialIds(context : TypeContext) : String = ???

    def makePropertySizes(context : TypeContext): String = ???

    def makeValueStruct(context : TypeContext): String = ???

    def makeEncodeFunction(context : TypeContext): String = ???

    def makeDecodeFunction(context : TypeContext) : String = ???

    def makeRuleFunctions(context : TypeContext) : String = ???

    def makeRules(context : TypeContext) : List[String] = ???

    def makeMain(rules : List[String]) : String = ???

    def lines(strings : String*) : String = strings.mkString("\n")
    def lines(strings : List[String]) : String = strings.mkString("\n")

    def blocks(blocks : String*) : String = blocks.mkString("\n\n")
    def blocks(blocks : List[String]) : String = blocks.mkString("\n\n")

    def indent(code : String) : String = {
        code.split('\n').map(line =>
            if(line.nonEmpty) "    " + line
            else line
        ).mkString("\n")
    }

}
