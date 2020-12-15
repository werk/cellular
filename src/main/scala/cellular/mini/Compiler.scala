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

    def makeMaterialIds(context : TypeContext) : String = "TODO"

    def makePropertySizes(context : TypeContext): String = "TODO"

    def makeValueStruct(context : TypeContext): String = "TODO"

    def makeEncodeFunction(context : TypeContext): String = {
        val cases = context.materials.map { case (m, properties) =>
            val nonConstantProperties = properties.filter(p =>
                    p.property != m &&
                    p.value.isEmpty
                    // Codec.propertySizeOf(context, p.property) > 1 // TODO StackOverflow
            )
            val propertyEncoding = nonConstantProperties.map { p =>
                lines(
                    s"            if(fixed.${p.property} == NOT_FOUND) {",
                    s"                result *= SIZE_${p.property};",
                    s"                result += value.${p.property};",
                    s"            }"
                )
            }
            lines(
                s"        case $m:",
                lines(propertyEncoding),
                s"            break;",
            )
        }

        lines(
            "uint encode(Value value, Value fixed) {",
            s"    uint result = 0u;",
            s"    switch(value.material) {",
            lines(cases.toList),
            s"        default:",
            s"    }",
            s"    result *= SIZE_material;",
            s"    result += value.material;",
            s"    return result;",
            s"}",
        )
    }

    def makeDecodeFunction(context : TypeContext) : String = "TODO"

    def makeRuleFunctions(context : TypeContext) : String = "TODO"

    def makeRules(context : TypeContext) : List[String] = List("TODO")

    def makeMain(rules : List[String]) : String = "TODO"

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
