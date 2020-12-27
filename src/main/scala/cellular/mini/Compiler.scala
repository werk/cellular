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
            case (p, fixedType) if !Inference.typeIsNat(context.typeAliases, fixedType.valueType) =>
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
        "uniform int seedling;",
        "uniform int step;",
        "out uint outputValue;",
        "",
        "const uint NOT_FOUND = 4294967295u;",
        "", // https://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
        "uint random(inout uint seed, uint range) {",
        "    seed ^= range;",
        "    seed += (seed << 10u);",
        "    seed ^= (seed >> 6u);",
        "    seed += (seed << 3u);",
        "    seed ^= (seed >> 11u);",
        "    seed += (seed << 15u);",
        "    return seed % range;",
        "}",
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
        val fixedType = context.properties(property)
        val fixedProperties = fixedType.fixed.map(_.property).toSet
        val materials = Codec.materialsOf(context, fixedType.valueType)
        val cases = materials.toList.filterNot(_.head.isDigit).sorted.zipWithIndex.map { case (m, i) =>
            val properties = context.materials(m).
                filter(_.value.isEmpty).map(_.property).
                filterNot(fixedProperties)
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
        val fixedType = context.properties(property)
        val fixedValues = fixedType.fixed.map(f => f.property -> f.value).toMap
        val materials = Codec.materialsOf(context, fixedType.valueType)
        val cases = materials.toList.filterNot(_.head.isDigit).sorted.zipWithIndex.map { case (m, i) =>
            val valueProperties =
                context.materials(m).sortBy(_.property)
            val (properties, constantProperties) =
                valueProperties.partition(p => p.value.isEmpty && !fixedValues.contains(p.property))
            val constantPropertyCode = constantProperties.map { p =>
                val fixedType1 = context.properties(p.property)
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
        "    uint n = texelFetch(state, offset, 0).r;",
        "    return Tile_d(n);",
        "}",
    )

    def makeFunction(context : TypeContext, function : DFunction) : String = {
        val parametersCode = ("inout uint seed" +: function.parameters.map { case Parameter(_, name, kind) =>
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

    def computeCells[T](matrix: List[List[T]]): List[(String, T, Boolean)] = {
        val writeMinX = (matrix.head.size - 1) / 2
        val writeMinY = (matrix.size - 1) / 2
        val writeMaxX = matrix.head.size / 2
        val writeMaxY = matrix.size / 2

        matrix.zipWithIndex.flatMap { case (ps, y) =>
            val row = (y + 1).toString
            ps.zipWithIndex.map { case (p, x) =>
                val cell = ('a' + x).toChar + row
                val writeX = x >= writeMinX && x <= writeMaxX
                val writeY = y >= writeMinY && y <= writeMaxY
                (cell, p, writeX && writeY)
            }
        }
    }

    def makeRuleFunction(context : TypeContext, rule : Rule) : String = {

        val arguments = computeCells(rule.patterns)

        val emitter = new Emitter()
        val patterns = arguments.map { case (name, pattern, _) =>
            emitter.emitPattern(context, pattern, name, None, multiMatch = false)
        }

        val writableArguments = arguments.collect { case (name, _, true) => name }
        val writableArgumentRange = writableArguments.head + ":" + writableArguments.last
        val body = emitter.emitExpression(context, writableArgumentRange, rule.expression)

        val declare = arguments.collect { case (cell, _, true) =>
            "value " + cell + "t;"
        }

        val copy = arguments.collect { case (cell, _, true) =>
            cell + " = " + cell + "t;"
        }

        val argumentsCode = "inout uint seed" +: arguments.map { case (cell, _, write) =>
            (if(write) "inout " else "") + "value " + cell
        }

        lines(
            s"bool ${rule.name}_r(${argumentsCode.mkString(", ")}) {",
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
            val cells = computeCells(r.patterns).map(_._1)
            def offset(x : Int, y : Int)(cell : String) = {
                val cellX = cell.head + x
                val cellY = cell.drop(1).toInt + y
                cellX.toChar + cellY.toString
            }
            val callsParameters = ((r.patterns.head.size % 2, r.patterns.size % 2) match {
                case (0, 1) => List(cells, cells.map(offset(0, 1)))
                case (1, 0) => List(cells, cells.map(offset(1, 0)))
                case (1, 1) => List(cells, cells.map(offset(0, 1)), cells.map(offset(1, 0)), cells.map(offset(1, 1)))
                case _ => List(cells)
            }).map(_.mkString(", ")).map("seed, " + _)

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

        def adjust(size : Int) = ((Math.max(2, size) + 1) / 2) * 2
        val maxWidth = adjust(
            groups.map(_.rules.map(_.patterns.head.size).maxOption.getOrElse(0)).maxOption.getOrElse(0)
        )
        val maxHeight = adjust(
            groups.map(_.rules.map(_.patterns.size).maxOption.getOrElse(0)).maxOption.getOrElse(0)
        )

        val cells = computeCells((0 until maxHeight).toList.map(y => (0 until maxWidth).toList.map(x => (x, y))))
        val lookupLines = cells.map { case (cell, (x, y), write) =>
            val reverseY = maxHeight - 1 - y
            (if(write) "" else "const ") +
            "value " + cell + " = lookupTile(bottomLeft + ivec2(" + x + ", " + reverseY + "));"
        }

        val List(a1, b1, a2, b2) = cells.collect { case (cell, _, true) => cell }

        blocks(
            lines(
                "void main() {",
                "    ivec2 position = ivec2(gl_FragCoord.xy - 0.5);",
                "    ivec2 offset = (step % 2 == 0) ? ivec2(1, 1) : ivec2(0, 0);",
                "    ivec2 bottomLeft = (position + offset) / 2 * 2 - offset;",
            ),
            indent(lines(lookupLines)),
            lines(
                "    uint seed = uint(seedling) ^ Tile_e(a1);",
                "    random(seed, 1u);",
                "    seed = seed ^ uint(position.x);",
                "    random(seed, 1u);",
                "    seed = seed ^ uint(position.y);",
            ),
            indent(blocks(groupCalls)),
            lines(
                "    // Write and encode own value",
                "    ivec2 quadrant = position - bottomLeft;",
                "    value target = " + a2 + ";",
                "    if(quadrant == ivec2(0, 1)) target = " + a1 + ";",
                "    else if(quadrant == ivec2(1, 0)) target = " + b2 + ";",
                "    else if(quadrant == ivec2(1, 1)) target = " + b1 + ";",
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
