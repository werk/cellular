package cellular.mini

object Compiler {

    def compile(definitions : List[Definition]) : String = {
        val context : TypeContext = TypeContext.fromDefinitions(definitions)
        val propertyNames = definitions.collect { case p : DProperty => p.name}
        val groups = definitions.collect { case g : DGroup => g}
        val rules = groups.flatMap(_.rules)


        blocks(
            head,
            makeMaterialIds(context),
            makePropertySizes(context, propertyNames),
            makeValueStruct(propertyNames),
            makeEncodeFunction(context),
            makeDecodeFunction(context),
            blocks(rules.map(makeRuleFunction(context, _))),
            makeMain(context, groups)
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

    def makeMaterialIds(context : TypeContext) : String = {
        val list = context.materialIndexes.toList.sortBy(_._2).map { case (name, id) =>
            s"const uint $name = ${id}u;"
        }
        lines(list)
    }

    def makePropertySizes(context : TypeContext, propertyNames : List[String]) : String = {
        val list = propertyNames.map { name =>
            val size = Codec.propertySizeOf(context, name)
            s"const uint SIZE_$name = ${size}u;"
        }
        lines(list)
    }

    def makeValueStruct(propertyNames : List[String]): String = lines(
        "struct Value {",
        "    uint material;",
        lines(propertyNames.map(n => s"    uint $n;")),
        "};",
    )

    def makeEncodeFunction(context : TypeContext): String = {
        val cases = context.materials.flatMap { case (m, properties) =>
            val nonConstantProperties = properties.filter(p =>
                p.property != m &&
                p.value.isEmpty &&
                Codec.propertySizeOf(context, p.property) > 1
            )
            val propertyEncodings = nonConstantProperties.map { p =>
                lines(
                    s"            if(fix.${p.property} == NOT_FOUND) {",
                    s"                result *= SIZE_${p.property};",
                    s"                result += value.${p.property};",
                    s"            }"
                )
            }
            if(nonConstantProperties.isEmpty) None else Some {
                lines(
                    s"        case $m:",
                    lines(propertyEncodings),
                    s"            break;",
                )
            }
        }

        lines(
            "uint encode(Value value, Value fix) {",
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

    def makeDecodeFunction(context : TypeContext) : String = {
        val cases = context.materials.map { case (m, properties) =>
            val nonConstantProperties = properties.filter(p =>
                    p.property != m &&
                    p.value.isEmpty
                    // Codec.propertySizeOf(context, p.property) > 1 // TODO StackOverflow
            )
            val propertyEncoding = nonConstantProperties.map { p =>
                lines(
                    s"            if(fix.${p.property} == NOT_FOUND) {",
                    s"                value.${p.property} = remaining % SIZE_${p.property};",
                    s"                remaining /= SIZE_${p.property};",
                    s"            } else {",
                    s"                value.${p.property} = fix.${p.property};",
                    s"            }",
                )
            }
            val constantProperties = properties.collect { case MaterialProperty(_, property, Some(v)) =>
                property -> v
            }
            val constantPropertyEncoding = constantProperties.map { case (p, v) =>
                val fixedType = context.properties(p).get
                val encoded = v // TODO: Codec.encodeValue(context, fixedType, v)
                lines(
                    s"            value.$p = ${encoded}u;",
                )
            }
            lines(
                s"        case $m:",
                lines(propertyEncoding),
                lines(constantPropertyEncoding),
                s"            break;",
            )
        }

        lines(
            "Value decode(uint number, Value fix) {",
            s"    Value value = ALL_NOT_FOUND;",
            s"    value.material = number % SIZE_material;",
            s"    uint remaining = number / SIZE_material;",
            s"    switch(value.material) {",
            lines(cases.toList),
            s"        default:",
            s"    }",
            s"    return value;",
            s"}",
        )
    }

    def makeRuleFunction(context : TypeContext, rule : Rule) : String = {
        val arguments = rule.patterns match {
            case List(List(a1, b1)) => List("a1" -> a1, "b1" -> b1)
            case List(List(a1), List(a2)) => List("a1" -> a1, "a2" -> a2)
            case List(List(a1), List(b1), List(a2), List(b2)) => List("a1" -> a1, "b1" -> b1, "a2" -> a2, "b2" -> b2)
        }

        val patterns = arguments.map { case (name, pattern) =>
            new Emitter().emitPattern(context, pattern, name, None)
        }

        val writableArgumentRange = arguments.head._1 + ":" + arguments.last._1
        val body = new Emitter().emitExpression(context, writableArgumentRange, rule.expression)

        lines(
            s"bool ${rule.name}(${arguments.map("Value " + _._1).mkString(", ")}) {",
            indent(patterns.mkString("\n")),
            s"    ",
            indent(body),
            s"    return true;",
            s"}",
        )
    }

    def makeRuleCalls(g : DGroup) : String = {
        val comment = s"// ${g.name}"
        val didGroup = s"bool did_${g.name} = false;"
        val didReactions = g.rules.map(r =>
            s"bool did_${r.name} = false;"
        )
        val groupCondition = condition(g.scheme.unless)
        val ruleCalls = g.rules.map { r =>
            val ruleCondition = condition(r.scheme.unless)
            val callsParameters = r.patterns match {
                case List(List(_, _)) => List("pp_0_0, pp_1_0", "pp_0_1, pp_1_1")
                case List(List(_), List(_)) => List("pp_0_1, pp_0_0", "pp_1_1, pp_1_0")
                case List(List(_), List(_), List(_), List(_)) => List("pp_0_1, pp_1_1, pp_0_0, pp_1_0")
            }

            val calls = callsParameters.map(parameters =>
                s"    did_${r.name} = rule_${r.name}($parameters) || did_${r.name};"
            )

            lines(
                s"if($ruleCondition) {",
                lines(calls),
                s"    did_${g.name} = did_${g.name} || did_${r.name};",
                s"}"
            )
        }

        val group = lines(
            s"if($groupCondition) {",
            indent(lines(ruleCalls)),
            s"}"
        )

        lines(comment :: didGroup :: didReactions ++ List(group))
    }

    def condition(unless : List[String]) = unless match {
        case List() => "true"
        case _ => unless.map("!did_" + _).mkString(" && ")
    }

    def makeMain(context : TypeContext, groups : List[DGroup]) : String = {
        val groupCalls = groups.map(makeRuleCalls)

        blocks(
            lines(
                "void main() {",
                "    ivec2 position = ivec2(gl_FragCoord.xy - 0.5);",
                "    ivec2 offset = (step % 2 == 0) ? ivec2(1, 1) : ivec2(0, 0);",
                "    ivec2 bottomLeft = (position + offset) / 2 * 2 - offset;",
            ),
            lines(
                "    // Read and parse relevant pixels",
                "    Value pp_0_0 = lookupMaterial(bottomLeft + ivec2(0, 0));",
                "    Value pp_0_1 = lookupMaterial(bottomLeft + ivec2(0, 1));",
                "    Value pp_1_0 = lookupMaterial(bottomLeft + ivec2(1, 0));",
                "    Value pp_1_1 = lookupMaterial(bottomLeft + ivec2(1, 1));",
            ),
            indent(blocks(groupCalls)),
            lines(
                "    // Write and encode own value",
                "    ivec2 quadrant = position - bottomLeft;",
                "    Value target = pp_0_0;",
                "    if(quadrant == ivec2(0, 1)) target = pp_0_1;",
                "    else if(quadrant == ivec2(1, 0)) target = pp_1_0;",
                "    else if(quadrant == ivec2(1, 1)) target = pp_1_1;",
                "    outputValue = encode(target);",
                "}",
            )
        )
    }

    def lines(strings : String*) : String = strings.filter(_.nonEmpty).mkString("\n")
    def lines(strings : List[String]) : String = lines(strings : _*)

    def blocks(blocks : String*) : String = blocks.mkString("\n\n")
    def blocks(blocks : List[String]) : String = blocks.mkString("\n\n")

    def indent(code : String) : String = {
        code.split('\n').map(line =>
            if(line.nonEmpty) "    " + line
            else line
        ).mkString("\n")
    }



}
