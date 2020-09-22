package language

import language.Language._

object Compile {

    def main(args : Array[String]) : Unit = {
        println(compile(experiments.SandAndWater.declarations))
    }

    def compile(declarations : List[Declaration]) : String = {
        val cellTypeDeclarations = declarations.collect{case t : DCellType => t}
        val traitDeclarations = declarations.collect{case t : DTrait => t}

        val (ruleFunctions, ruleUsages) = declarations.collect{case g : DGroup => compileGroup(g)}.unzip

        blocks(
            head,
            getStruct(traitDeclarations),
            lines(getMaterialOffsets(cellTypeDeclarations, 0)),
            intToVec4,
            vec4ToInt,
            getEncodeFunction(cellTypeDeclarations.map(_.name), traitDeclarations.map(_.name)),
            getDecodeFunction(cellTypeDeclarations.map(_.name), traitDeclarations.map(_.name)),
            lookupMaterialFunction,
            blocks(ruleFunctions),
            makeMain(blocks(ruleUsages))
        )
    }

    val head : String = lines(
        s"precision mediump float;",
        s"uniform sampler2D state;",
        s"uniform vec2 scale;",
        s"uniform float seedling;",
        s"uniform int step;",
        "",
        "const uint NOT_FOUND = 4294967295;",
    )

    val intToVec4 : String = lines(
        "vec4 intToVec4(uint integer) {",
        "    uint o4 = 256 * 256 * 256;",
        "    uint x4 = integer / o4;",
        "    uint r4 = integer - (x4 * o4);",
        "    uint o3 = 256 * 256;",
        "    uint x3 = r4 / o3;",
        "    uint r3 = r4 - (x3 * o3);",
        "    uint o2 = 256;",
        "    uint x2 = r3 / o2;",
        "    uint r2 = r3 - (x2 * o2);",
        "    uint x1 = r2;",
        "    return vec4(float(x1), float(x2), float(x3), float(x4));",
        "}",
    )

    val vec4ToInt : String = lines(
        "uint vec4ToInt(vec4 pixel) {",
        "    return uint(pixel.x) + 256 * (uint(pixel.y) + 256 * (uint(pixel.z) + 256 * uint(pixel.w)));",
        "}",
    )

    val lookupMaterialFunction : String = lines(
        "Material lookupMaterial(vec2 offset) {",
        "    vec4 color = texture2D(state, offset / scale);",
        "    return decode(color);",
        "}",
    )

    def getMaterialOffsets(list : List[DCellType], lastOffset : Int) : List[String] = list match {
        case List() => List()
        case head :: tail => s"const uint ${head.name} = $lastOffset;" :: getMaterialOffsets(tail, lastOffset + getMaterialSize(head))
    }

    def getMaterialSize(t : DCellType) : Int = {
        t.traits.flatMap { case (t, None) =>
            t.argument.collect { case ENumber(n) => n }
        }.product
    }

    def getStruct(list : List[DTrait]) : String = lines(
        "struct Material {",
        "    uint material;",
        lines(list.map(t => s"    uint ${t.name};")),
        "};",
    )

    def getEncodeFunction(materials : List[String], traits : List[String]) : String = {
        val cases = materials.map { m =>
            val dimensions = traits.map(t => s"${m}_${t}_SIZE")
            val indices = traits.map(t => s"material.$t")
            val address = getAddressExpression(dimensions.zip(indices))
            lines(
                s"        case $m:",
                s"            uint traits = $address;",
                s"            return intToVec4($m + traits);",
            )
        }

        lines(
            "vec4 encode(Material material) {",
            s"    switch(material.material) {",
            lines(cases),
            s"        default:",
            s"            return null;",
            s"    }",
            s"}",
        )
    }

    def getAddressExpression(dimensionsAndIndices : List[(String, String)]) : String = dimensionsAndIndices match {
        case (_, index) :: List() => s"$index"
        case (bound, index) :: rest=> s"$index + $bound * (${getAddressExpression(rest)})"
    }

    def getDecodeFunction(materials : List[String], traits : List[String]) : String = {
        val pairs = materials.zip(materials.tail.map(Some(_)) ++ List(None)).zipWithIndex

        val cases = pairs.map { case ((name, nextName), i) =>
            val setTraits = getIndicesExpression(name, traits, "trait")
            val body = indent(indent(lines(
                s"material.material = $name;",
                s"uint trait = integer - $name;",
                lines(setTraits)
            )))

            (nextName, i) match {
                case (None, 0) => body
                case (None, i) => lines(
                    " else {",
                    body,
                    "    }",
                )
                case (Some(next), 0) => lines(
                    s"    if(integer < $next) {",
                    body,
                    s"    }",
                )
                case (Some(next), _) => lines(
                    s" else if(integer < $next) {",
                    body,
                    s"    }",
                )
            }
        }

        val notFounds = traits.map { t =>
            s"    material.$t = NOT_FOUND;"
        }


        lines(
            "Material decode(vec4 pixel) {",
            s"    uint integer = vec4ToInt(pixel);",
            s"    Material material;",
            lines(notFounds),
            cases.mkString,
            s"    return material;",
            s"}",
        )
    }

    def getIndicesExpression(material : String, traits : List[String], address : String) : List[String] = traits match {
        case List() => List()
        case List(t) =>
            val x = "material." + t
            List(s"$x = $address;")
        case t :: tail =>
            val offset = t + "_offset"
            val x = "material." + t
            val remainder = t + "_remainder"
            val offsetValue = tail.map(t => s"${material}_${t}_SIZE").mkString(" * ")
            s"$offset = $offsetValue;" ::
            s"$x = $address / $offset;" ::
            s"$remainder = $address - ($x * $offset);" ::
            getIndicesExpression(material, tail, remainder)
    }


    def compileGroup(g : DGroup) : (String, String) = {
        val ruleFunctions = blocks(g.reactions.map(Reactions.compile))

        val comment = s"// ${g.name}"
        val didGroup = s"bool did_${g.name} = false;"
        val didReactions = g.reactions.map(r =>
            s"bool did_${r.name} = false;"
        )
        val groupCondition = Expressions.translate(g.condition, parenthesis = false)
        val ruleCalls = g.reactions.flatMap{r =>
            val peekParameters = r.constraints.map(Usages.peeks).fold(Set()) { _ ++ _ }.toList.sorted.
                map((Usages.peek _).tupled).mkString(", ")

            List(
                s"if($groupCondition) {",
                s"    did_${r.name} = did_${r.name} || rule_${r.name}($peekParameters);",
                s"    did_${g.name} = did_${g.name} || did_${r.name};",
                s"}"
            )
        }

        (ruleFunctions, lines(comment :: didGroup :: didReactions ++ ruleCalls))
    }

    def makeMain(ruleUsages : String) : String = lines(
        "void main() {",
        "    vec2 position = gl_FragCoord.xy - 0.5;",
        "    vec2 offset = mod(float(step), 2.0) == 0.0 ? vec2(-1.0, -1.0) : vec2( 0.0,  0.0);",
        "    vec2 bottomLeft = floor((position + offset) * 0.5) * 2.0 - offset;",
        "",
        "    // Read and parse relevant pixels",
        "    Material pp_0_0 = lookupMaterial(bottomLeft + vec2(0.0, 0.0));",
        "    Material pp_0_1 = lookupMaterial(bottomLeft + vec2(0.0, 1.0));",
        "    Material pp_1_0 = lookupMaterial(bottomLeft + vec2(0.1, 0.0));",
        "    Material pp_1_1 = lookupMaterial(bottomLeft + vec2(0.1, 1.0));",
        "    Material pm_0_1 = lookupMaterial(bottomLeft + vec2(0.0, -1.0));",
        "    Material pm_1_1 = lookupMaterial(bottomLeft + vec2(0.1, -1.0));",
        "",
        indent(ruleUsages),
        "",
        "    // Write and encode own material",
        "    Material target = null;",
        "    vec2 quadrant = position - bottomLeft;",
        "    if(quadrant == vec2(0.0, 0.0)) target = pp_0_0;",
        "    else if(quadrant == vec2(0.0, 0.1)) target = pp_0_1;",
        "    else if(quadrant == vec2(1.0, 0.0)) target = pp_1_0;",
        "    else if(quadrant == vec2(1.0, 0.1)) target = pp_1_1;",
        "    gl_FragColor = encode(target);",
        "}",
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
