package cellular.language

import cellular.language.Language._

object Compile {

    def compile(declarations : List[Declaration]) : String = {
        val cellTypeDeclarations = declarations.collect{case t : DCellType => t}
        val traitDeclarations = declarations.collect{case t : DTrait => t}
        val materialNames = cellTypeDeclarations.map(_.name)
        val allTraitNames = traitDeclarations.map(_.name)
        val materialTraitNames = cellTypeDeclarations.map { cell =>
            cell.name -> cell.traits.map(_._1.name)
        }
        val traitSizes = getMaterialTraitSizeMap(cellTypeDeclarations)

        val (ruleFunctions, ruleUsages) = declarations.collect{case g : DGroup => compileGroup(g)}.unzip

        blocks(
            head,
            getStruct(traitDeclarations),
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

    val lookupMaterialFunction : String = lines(
        "Material lookupMaterial(ivec2 offset) {",
        "    uint integer = texture(state, (vec2(offset) + 0.5) / 100.0/* / scale*/).r;",
        "    return decode(integer);",
        "}",
    )

    val swapFunction : String = lines(
        "void swap(inout Material v1, inout Material v2) {",
        "    Material temp = v1;",
        "    v1 = v2;",
        "    v2 = temp;",
        "}",
    )

    def getMaterialOffsets(list : List[DCellType], lastOffset : Int) : List[String] = list match {
        case List() => List()
        case head :: tail => s"const uint ${head.name} = ${lastOffset}u;" ::
            getMaterialOffsets(tail, lastOffset + getMaterialSize(head))
    }

    def getMaterialSize(t : DCellType) : Int = {
        t.traits.flatMap { case (t, None) =>
            t.argument.collect { case ENumber(n) => n }
        }.product
    }

    def getMaterialTraitSizeMap(cells : List[DCellType]) : Map[(String, String), Int] = {
        cells.flatMap { cell =>
            cell.traits.flatMap { case (t, _) =>
                t.argument.collect { case ENumber(n) => (cell.name, t.name) -> n }
            }
        }.toMap
    }

    def getTraitSizes(traitSizes : Map[(String, String), Int], materialTraitNames : List[(String, List[String])]) = {
        materialTraitNames.flatMap {case (m, ts) =>
            val declarations = ts.map{t =>
                val size = traitSizes.getOrElse((m, t), 1)
                s"const uint ${m}_${t}_SIZE = ${size}u;"
            }
            declarations
        }
    }

    def getStruct(list : List[DTrait]) : String = lines(
        "struct Material {",
        "    uint material;",
        lines(list.map(t => s"    uint ${t.name};")),
        "};",
    )

    def getEncodeFunction(materialTraits : List[(String, List[String])]) : String = {
        val cases = materialTraits.map { case (m, traits) =>
            val dimensions = traits.map(t => s"${m}_${t}_SIZE")
            val indices = traits.map(t => s"material.$t")
            val address = getAddressExpression(dimensions.zip(indices))
            lines(
                s"        case $m:",
                s"            traits = $address;",
                s"            break;",
            )
        }

        lines(
            "uint encode(Material material) {",
            s"    uint traits;",
            s"    switch(material.material) {",
            lines(cases),
            s"        default:",
            s"            traits = - material.material;",
            s"    }",
            s"    return material.material + traits;",
            s"}",
        )
    }

    def getAddressExpression(dimensionsAndIndices : List[(String, String)]) : String = dimensionsAndIndices match {
        case (_, index) :: List() => s"$index"
        case (bound, index) :: rest=> s"$index + $bound * (${getAddressExpression(rest)})"
    }

    def getDecodeFunction(
        materialTraits : List[(String, List[String])],
        allTraits : List[String],
    ) : String = {
        val materials = materialTraits.map(_._1)
        val pairs = materialTraits.zip(materials.tail.map(Some(_)) ++ List(None)).zipWithIndex

        val cases = pairs.map { case (((name, traits), nextName), i) =>
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

        val notFounds = allTraits.map { t =>
            s"    material.$t = NOT_FOUND;"
        }


        lines(
            "Material decode(uint integer) {",
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
            s"uint $offset = $offsetValue;" ::
            s"$x = $address / $offset;" ::
            s"uint $remainder = $address - ($x * $offset);" ::
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
        val ruleCalls = g.reactions.map{r =>
            val peekParameters = r.constraints.map(Usages.peeks).fold(Set()) { _ ++ _ }.toList.sorted.
                map((Usages.peek _).tupled).mkString(", ")

            val peekParametersPair = peekParameters match {
                case "pp_0_0, pp_1_0" => List("pp_0_0, pp_1_0", "pp_0_1, pp_1_1")
                case "pp_0_0, pp_0_1" => List("pp_0_0, pp_0_1", "pp_1_0, pp_1_1")
                case _ => List(peekParameters)
            }

            val calls = peekParametersPair.map(parameters =>
                s"    did_${r.name} = did_${r.name} || rule_${r.name}($parameters);"
            )

            lines(
                s"if($groupCondition) {",
                lines(calls),
                s"    did_${g.name} = did_${g.name} || did_${r.name};",
                s"}"
            )
        }

        (ruleFunctions, lines(comment :: didGroup :: didReactions ++ ruleCalls))
    }

    def makeMain(ruleUsages : String) : String = lines(
        "void main() {",
        "    ivec2 position = ivec2(gl_FragCoord.xy - 0.5);",
        "    ivec2 offset = (step % 2 == 0) ? ivec2(1, 1) : ivec2(0, 0);",
        "    ivec2 bottomLeft = (position + offset) / 2 * 2 - offset;",
        "",
        "    // Read and parse relevant pixels",
        "    Material pp_0_0 = lookupMaterial(bottomLeft + ivec2(0, 0));",
        "    Material pp_0_1 = lookupMaterial(bottomLeft + ivec2(0, 1));",
        "    Material pp_1_0 = lookupMaterial(bottomLeft + ivec2(1, 0));",
        "    Material pp_1_1 = lookupMaterial(bottomLeft + ivec2(1, 1));",
        "",
        indent(ruleUsages),
        "",
        "    // Write and encode own material",
        "    ivec2 quadrant = position - bottomLeft;",
        "    Material target = pp_0_0;",
        "    if(quadrant == ivec2(0, 1)) target = pp_0_1;",
        "    else if(quadrant == ivec2(1, 0)) target = pp_1_0;",
        "    else if(quadrant == ivec2(1, 1)) target = pp_1_1;",
        "    outputValue = encode(target);",
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
