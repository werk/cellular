package cellular.mini

object Compiler {

    def compile(definitions : List[Definition]) : String = {
        val context : TypeContext = TypeContext.fromDefinitions(definitions)

        blocks(
            head,
            makeValueStruct(context),
            lines(getMaterialOffsets(cellTypeDeclarations, 0)),
            lines(getTraitSizes(traitSizes, materialTraitNames)),
            getEncodeFunction(materialTraitNames),
            getDecodeFunction(materialTraitNames, allTraitNames),
            lookupMaterialFunction,
            swapFunction,
            blocks(ruleFunctions),
            makeMain(blocks(ruleUsages))
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
