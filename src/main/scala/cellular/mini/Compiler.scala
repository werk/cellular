package cellular.mini

object Compiler {

    def compile(definitions : List[Definition]) : String = {
        val context : TypeContext = TypeContext.fromDefinitions(definitions)
        val checkerContext = Checker.createContext(definitions)
        val inferenceContext = Inference.createContext(definitions)
        val propertyNames = definitions.collect { case p : DProperty => p.name}
        val functions = definitions.collect { case f : DFunction =>
            val variables = f.parameters.map { case Parameter(_, name, kind) => name -> kind }.toMap
            val newInferenceContext = inferenceContext.copy(variables = inferenceContext.variables ++ variables)
            Checker.checkExpression(checkerContext, f.body)
            val newBody = Inference.inferExpression(newInferenceContext, f.body)
            if(newBody.kind != f.returnKind) {
                fail(newBody.line, "Expected " + f.returnKind + ", got: " + newBody.kind)
            }
            f.copy(body = newBody)
        }
        val groups = definitions.collect { case g : DGroup => g }
        groups.flatMap(_.rules).foreach(rule => Checker.checkExpression(checkerContext, rule.expression))
        val rules = groups.flatMap(_.rules).map(Inference.inferRule(inferenceContext, _))

        blocks(
            head,
            makeMaterialIds(context),
            makeMaterialSize(context),
            makePropertySizes(context, propertyNames),
            makeValueStruct(propertyNames),
            makeFixed(context, propertyNames),
            makeEncodeFunction(context),
            makeDecodeFunction(context),
            lookupValue,
            blocks(functions.map(makeFunction(context, _))),
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

    def makeMaterialSize(context : TypeContext) : String = {
        val size = context.materials.size
        lines(
            s"const uint SIZE_material = ${size}u;"
        )
    }

    def makePropertySizes(context : TypeContext, propertyNames : List[String]) : String = {
        val list = propertyNames.map { name =>
            val size = Codec.propertySizeOf(context, name)
            s"const uint SIZE_$name = ${size}u;"
        }
        lines(list)
    }

    def makeValueStruct(propertyNames : List[String]) : String = lines(
        "struct value {",
        "    uint material;",
        lines(propertyNames.map(n => s"    uint $n;")),
        "};",
    )

    def makeFixed(context : TypeContext, propertyNames : List[String]) : String = {
        def go(resultName : String, property : String) = {
            val fixed = context.properties(property).toList.flatMap(_.fixed)
            def fix(name : String) : Option[String] = {
                fixed.find(_.property == name).map { propertyValue =>
                    val fixedType = context.properties(name).get
                    val number = Codec.encodeValue(context, fixedType, propertyValue.value)
                    ",   " + number + "u"
                }
            }
            if(fixed.isEmpty) "const value " + resultName + " = ALL_NOT_FOUND;"
            else lines(
                "const value " + resultName + " = value(",
                "    NOT_FOUND",
                lines(propertyNames.map(n => fix(n).getOrElse(s",   NOT_FOUND"))),
                ");",
            )
        }
        val firstBlock = lines(
            "const value ALL_NOT_FOUND = value(",
            "    NOT_FOUND",
            lines(propertyNames.map(_ => s",   NOT_FOUND")),
            ");",
        )

        blocks(firstBlock :: propertyNames.map(n => go("FIXED_" + n, n)))
    }

    def makeEncodeFunction(context : TypeContext): String = {
        val cases = context.materials.flatMap { case (m, properties) =>
            val nonConstantProperties = properties.filter(p =>
                p.value.isEmpty &&
                Codec.propertySizeOf(context, p.property) > 1
            )
            val propertyEncodings = nonConstantProperties.map { p =>
                lines(
                    s"            if(fix.${p.property} == NOT_FOUND) {",
                    s"                result *= SIZE_${p.property};",
                    s"                result += i.${p.property};",
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
            "uint encode(value i, value fix) {",
            s"    uint result = 0u;",
            s"    switch(i.material) {",
            lines(cases.toList),
            s"        default:",
            s"            break;",
            s"    }",
            s"    result *= SIZE_material;",
            s"    result += i.material;",
            s"    return result;",
            s"}",
        )
    }

    def makeDecodeFunction(context : TypeContext) : String = {
        val cases = context.materials.flatMap { case (m, properties) =>
            val nonConstantProperties = properties.filter(p =>
                p.value.isEmpty &&
                Codec.propertySizeOf(context, p.property) > 1
            )
            val propertyEncoding = nonConstantProperties.map { p =>
                lines(
                    s"            if(fix.${p.property} == NOT_FOUND) {",
                    s"                o.${p.property} = remaining % SIZE_${p.property};",
                    s"                remaining /= SIZE_${p.property};",
                    s"            } else {",
                    s"                o.${p.property} = fix.${p.property};",
                    s"            }",
                )
            }
            val constantProperties = properties.collect { case MaterialProperty(_, property, Some(v)) =>
                property -> v
            }
            val constantPropertyEncoding = constantProperties.map { case (p, v) =>
                val fixedType = context.properties(p).get
                val encoded = Codec.encodeValue(context, fixedType, v)
                lines(
                    s"            o.$p = ${encoded}u;",
                )
            }
            if(nonConstantProperties.isEmpty && constantProperties.isEmpty) None else Some {
                lines(
                    s"        case $m:",
                    lines(propertyEncoding),
                    lines(constantPropertyEncoding),
                    s"            break;",
                )
            }
        }

        lines(
            "value decode(uint number, value fix) {",
            s"    value o = ALL_NOT_FOUND;",
            s"    o.material = number % SIZE_material;",
            s"    uint remaining = number / SIZE_material;",
            s"    switch(o.material) {",
            lines(cases.toList),
            s"        default:",
            s"            break;",
            s"    }",
            s"    return o;",
            s"}",
        )
    }

    val lookupValue : String = lines(
        "value lookupValue(ivec2 offset) {",
        "    uint integer = texture(state, (vec2(offset) + 0.5) / 100.0/* / scale*/).r;",
        "    return decode(integer, ALL_NOT_FOUND);",
        "}",
    )

    def makeFunction(context : TypeContext, function : DFunction) : String = {
        val parametersCode = (function.parameters.map { case Parameter(_, name, kind) =>
            kind + " " + name
        } :+ ("out " + function.returnKind + " result")).mkString(", ")
        val bodyCode = new Emitter().emitExpression(context, "result", function.body)
        lines(
            "bool " + function.name + "_f(" + parametersCode + ") {",
            indent(bodyCode),
            "    return true;",
            "}",
        )
    }

    def makeRuleFunction(context : TypeContext, rule : Rule) : String = {
        val arguments = rule.patterns match {
            case List(List(a1)) => List("a1" -> a1)
            case List(List(a1, b1)) => List("a1" -> a1, "b1" -> b1)
            case List(List(a1), List(a2)) => List("a1" -> a1, "a2" -> a2)
            case List(List(a1), List(b1), List(a2), List(b2)) => List("a1" -> a1, "b1" -> b1, "a2" -> a2, "b2" -> b2)
        }

        val emitter = new Emitter()
        val patterns = arguments.map { case (name, pattern) =>
            emitter.emitPattern(context, pattern, name, None, multiMatch = false)
        }

        val writableArgumentRange = arguments.head._1 + ":" + arguments.last._1
        val body = emitter.emitExpression(context, writableArgumentRange, rule.expression)

        val declare = arguments.map { case (cell, _) =>
            "value " + cell + "t;"
        }

        val copy = arguments.map { case (cell, _) =>
            cell + " = " + cell + "t;"
        }

        lines(
            s"bool ${rule.name}_r(${arguments.map("inout value " + _._1).mkString(", ")}) {",
            indent(patterns.mkString("\n")),
            s"    ",
            indent(lines(declare)),
            s"    ",
            indent(body),
            s"    ",
            indent(lines(copy)),
            s"    return true;",
            s"}",
        )
    }

    def makeRuleCalls(g : DGroup) : String = {
        val comment = s"// ${g.name}"
        val didGroup = s"bool ${g.name}_d = false;"
        val didReactions = g.rules.map(r =>
            s"bool ${r.name}_d = false;"
        )
        val groupCondition = condition(g.scheme.unless)
        val ruleCalls = g.rules.map { r =>
            val ruleCondition = condition(r.scheme.unless)
            val callsParameters = r.patterns match {
                case List(List(_)) => List("pp_0_0", "pp_0_1", "pp_1_0", "pp_1_1")
                case List(List(_, _)) => List("pp_0_0, pp_1_0", "pp_0_1, pp_1_1")
                case List(List(_), List(_)) => List("pp_0_1, pp_0_0", "pp_1_1, pp_1_0")
                case List(List(_), List(_), List(_), List(_)) => List("pp_0_1, pp_1_1, pp_0_0, pp_1_0")
            }

            val calls = callsParameters.map(parameters =>
                s"    ${r.name}_d = ${r.name}_r($parameters) || ${r.name}_d;"
            )

            lines(
                s"if($ruleCondition) {",
                lines(calls),
                s"    ${g.name}_d = ${g.name}_d || ${r.name}_d;",
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
        case _ => unless.map("!" + _ + "_d").mkString(" && ")
    }

    val makeInitialMap = {
        blocks(
            lines(
                "if(step == 0) {",
                "    value stone = ALL_NOT_FOUND;",
                "    stone.material = Stone;",
                "    value tileStone = ALL_NOT_FOUND;",
                "    tileStone.material = Tile;",
                "    tileStone.Foreground = encode(stone, FIXED_Foreground);",
            ),
            lines(
                "    value air = ALL_NOT_FOUND;",
                "    air.material = Air;",
                "    value tileAir = ALL_NOT_FOUND;",
                "    tileAir.material = Tile;",
                "    tileAir.Foreground = encode(air, FIXED_Foreground);",
            ),
            lines(
                "    if(int(position.x + position.y) % 4 == 0) outputValue = encode(tileStone, ALL_NOT_FOUND);",
                "    else outputValue = encode(tileAir, ALL_NOT_FOUND);",
                "}",
            )
        )
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
                "    value pp_0_0 = lookupValue(bottomLeft + ivec2(0, 0));",
                "    value pp_0_1 = lookupValue(bottomLeft + ivec2(0, 1));",
                "    value pp_1_0 = lookupValue(bottomLeft + ivec2(1, 0));",
                "    value pp_1_1 = lookupValue(bottomLeft + ivec2(1, 1));",
            ),
            indent(blocks(groupCalls)),
            lines(
                "    // Write and encode own value",
                "    ivec2 quadrant = position - bottomLeft;",
                "    value target = pp_0_0;",
                "    if(quadrant == ivec2(0, 1)) target = pp_0_1;",
                "    else if(quadrant == ivec2(1, 0)) target = pp_1_0;",
                "    else if(quadrant == ivec2(1, 1)) target = pp_1_1;",
                "    outputValue = encode(target, ALL_NOT_FOUND);",
            ),
            indent(makeInitialMap),
            lines(
                "}",
            ),
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

    protected def fail(line: Int, message: String) = {
        throw new RuntimeException(message + " at line " + line)
    }

}
