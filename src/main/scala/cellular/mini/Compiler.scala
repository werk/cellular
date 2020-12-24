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
        val (propertyEncodeFunctions, propertyDecodeFunctions) = context.properties.toList.sortBy(_._1).collect {
            case (p, Some(fixedType)) if !Inference.typeIsNat(context.typeAliases, fixedType.valueType) =>
                makePropertyEncodeFunction(context, p) -> makePropertyDecodeFunction(context, p)
        }.unzip
        val groups = definitions.collect { case g : DGroup => g }
        groups.flatMap(_.rules).foreach(rule => Checker.checkExpression(checkerContext, rule.expression))
        val rules = groups.flatMap(_.rules).map(Inference.inferRule(inferenceContext, _))

        blocks(
            head,
            makeMaterialIds(context),
            makeValueStruct(propertyNames),
            makeAllNotFound(propertyNames),
            blocks(propertyEncodeFunctions),
            blocks(propertyDecodeFunctions),
            lookupTile,
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

    def makeValueStruct(propertyNames : List[String]) : String = lines(
        "struct value {",
        "    uint material;",
        lines(propertyNames.map(n => s"    uint $n;")),
        "};",
    )

    def makeAllNotFound(propertyNames : List[String]) : String = {
        lines(
            "const value ALL_NOT_FOUND = value(",
            "    NOT_FOUND",
            lines(propertyNames.map(_ => s",   NOT_FOUND")),
            ");",
        )
    }

    def makePropertyEncodeFunction(context : TypeContext, property : String) = {
        val fixedType = context.properties(property).get
        val fixedProperties = fixedType.fixed.map(_.property).toSet
        val materials = Codec.materialsOf(context, fixedType.valueType)
        val cases = materials.toList.filterNot(_.head.isDigit).sorted.zipWithIndex.map { case (m, i) =>
            val properties = context.materials(m).
                filter(_.value.isEmpty).map(_.property).
                filterNot(fixedProperties).
                filter(context.properties(_).nonEmpty)
            val propertyCode = properties.map { p =>
                lines(
                    "n *= " + Codec.propertySizeOf(context, p) + "u;",
                    "n += v." + p + ";",
                )
            }
            val materialCode = if(materials.size == 1) "" else {
                lines(
                    "n *= " + materials.size + "u;",
                    "n += " + i + "u;",
                )
            }
            lines(
                "case " + m + ":",
                indent(lines(propertyCode)),
                indent(materialCode),
                "    break;",
            )
        }
        lines(
            "uint " + property + "_e(value v) {",
            s"    uint n = 0u;",
            s"    switch(v.material) {",
            indent(indent(lines(cases))),
            s"    }",
            s"    return n;",
            s"}",
        )
    }

    def makePropertyDecodeFunction(context : TypeContext, property : String) = {
        val fixedType = context.properties(property).get
        val fixedValues = fixedType.fixed.map(f => f.property -> f.value).toMap
        val materials = Codec.materialsOf(context, fixedType.valueType)
        val cases = materials.toList.filterNot(_.head.isDigit).sorted.zipWithIndex.map { case (m, i) =>
            val valueProperties =
                context.materials(m).filter(p => context.properties(p.property).nonEmpty).sortBy(_.property)
            val (properties, constantProperties) =
                valueProperties.partition(p => p.value.isEmpty && !fixedValues.contains(p.property))
            val constantPropertyCode = constantProperties.map { p =>
                val fixedType1 = context.properties(p.property).get
                val value = fixedValues.getOrElse(p.property, p.value.get)
                val number = Codec.encodeValue(context, fixedType1, value)
                lines(
                    "v." + p.property + " = " + number + "u;",
                )
            }
            val propertyCode = properties.map(_.property).reverse.map { p =>
                lines(
                    "v." + p + " = n % " + Codec.propertySizeOf(context, p) + "u;",
                    "n = n / " + Codec.propertySizeOf(context, p) + "u;",
                )
            }
            lines(
                "case " + i + "u:",
                "    v.material = " + m + ";",
                indent(lines(constantPropertyCode)),
                indent(lines(propertyCode)),
                "    break;",
            )
        }
        lines(
            "value " + property + "_d(uint n) {",
            s"    value v = ALL_NOT_FOUND;",
            s"    uint m = n % " + materials.size + "u;",
            s"    n = n / " + materials.size + "u;",
            s"    switch(m) {",
            indent(indent(lines(cases))),
            s"    }",
            s"    return v;",
            s"}",
        )
    }

    val lookupTile : String = lines(
        "value lookupTile(ivec2 offset) {",
        "    uint n = texture(state, (vec2(offset) + 0.5) / 100.0/* / scale*/).r;",
        "    return Tile_d(n);",
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
                case List(List(_)) => List("a1", "a2", "b1", "b2")
                case List(List(_, _)) => List("a1, b1", "a2, b2")
                case List(List(_), List(_)) => List("a1, a2", "b1, b2")
                case List(List(_), List(_), List(_), List(_)) => List("a1, b1, a2, b2")
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
            ),
            lines(
                "    value air = ALL_NOT_FOUND;",
                "    air.material = Air;",
            ),
            lines(
                "    if(int(position.x + position.y) % 4 == 0) outputValue = Tile_e(stone);",
                "    else outputValue = Tile_e(air);",
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
                "    value a1 = lookupTile(bottomLeft + ivec2(0, 1));",
                "    value a2 = lookupTile(bottomLeft + ivec2(0, 0));",
                "    value b1 = lookupTile(bottomLeft + ivec2(1, 1));",
                "    value b2 = lookupTile(bottomLeft + ivec2(1, 0));",
            ),
            indent(blocks(groupCalls)),
            lines(
                "    // Write and encode own value",
                "    ivec2 quadrant = position - bottomLeft;",
                "    value target = a2;",
                "    if(quadrant == ivec2(0, 1)) target = a1;",
                "    else if(quadrant == ivec2(1, 0)) target = b2;",
                "    else if(quadrant == ivec2(1, 1)) target = b1;",
                "    outputValue = Tile_e(target);",
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
