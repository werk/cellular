package cellular.language

import java.math.BigInteger

object Compiler {

    def compile(definitions : List[Definition]) : List[String] = {
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

        val sheet = Sheet.autoSize(groups.flatMap(_.rules).map(_.patterns) : _*)

        val commonAndShared = blocks(
            head,
            "// BEGIN COMMON",
            makeTileSizeComment(context),
            makeMaterialIds(context),
            makeValueStruct(propertyNames),
            makeAllNotFound(propertyNames),
            blocks(propertyEncodeFunctions),
            blocks(propertyDecodeFunctions),
            "// END COMMON",
            lookupTile,
            blocks(functions.map(makeFunction(context, _))),
        )

        groups.map { group =>
            val rules = List(group).flatMap(_.rules).map(Inference.inferRule(inferenceContext, _))
            blocks(
                commonAndShared,
                blocks(rules.map(makeRuleFunction(context, _))),
                blocks(makeGroupFunctions(sheet, List(group))),
                makeMain(sheet, List(group))
            )
        }
    }

    def updateViewGlsl(stepGlsl : String, oldViewGlsl : String) : String = {
        val common = stepGlsl.linesIterator.dropWhile(_ != "// BEGIN COMMON").takeWhile(_ != "// END COMMON")
        val commonCode = common.mkString("\n") + "\n// END COMMON"
        val beforeCommonCode = oldViewGlsl.linesIterator.takeWhile(_ != "// BEGIN COMMON").mkString("\n")
        val afterCommonCode = oldViewGlsl.linesIterator.toList.reverse.takeWhile(_ != "// END COMMON").reverse.mkString("\n")
        beforeCommonCode + "\n" + commonCode + "\n" + afterCommonCode
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
        "uint random(inout uint seed, uint entropy, uint range) {",
        "    seed ^= entropy;",
        "    seed += (seed << 10u);",
        "    seed ^= (seed >> 6u);",
        "    seed += (seed << 3u);",
        "    seed ^= (seed >> 11u);",
        "    seed += (seed << 15u);",
        "    return seed % range;",
        "}",
    )

    def makeTileSizeComment(context : TypeContext) : String = {
        val size = Codec.propertySizeOf(context, "Tile")
        s"// There are $size different tiles"
    }

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
        val realMaterials = materials.toList.filterNot(_.head.isDigit).sorted
        val previousMaterials = realMaterials.inits.toList.reverse
        val cases = realMaterials.zip(previousMaterials).map { case (m, ms) =>
            val properties = context.materials(m).
                filter(_.value.isEmpty).map(_.property).
                filterNot(fixedProperties).
                sorted
            val propertyCode = properties.map { p =>
                lines(
                    "n *= " + Codec.propertySizeOf(context, p) + "u;",
                    "n += v." + p + ";",
                )
            }
            val materialSizes = ms.map(Codec.materialSizeOf(context, _))
            val materialCode = if(materialSizes.isEmpty) "" else {
                lines(
                    "n += " + materialSizes.map(_ + "u").mkString(" + ") + ";",
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
            val materialSize = Codec.materialSizeOf(context, m)
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
                    "n /= " + Codec.propertySizeOf(context, p) + "u;",
                )
            }
            lines(
                "if(n < " + materialSize + "u) {",
                "    v.material = " + m + ";",
                indent(lines(constantPropertyCode)),
                indent(lines(propertyCode)),
                "    return v;",
                "}",
                "n -= " + materialSize + "u;",
            )
        }
        lines(
            "value " + property + "_d(uint n) {",
            s"    value v = ALL_NOT_FOUND;",
            indent(lines(cases)),
            s"    return v;",
            s"}",
        )
    }

    val lookupTile : String = lines(
        "value lookupTile(ivec2 offset) {",
        "    ivec2 stateSize = ivec2(1000, 1000);",
        "    if(offset.x < 0) offset.x += stateSize.x;",
        "    if(offset.y < 0) offset.y += stateSize.y;",
        "    if(offset.x >= stateSize.x) offset.x -= stateSize.x;",
        "    if(offset.y >= stateSize.y) offset.y -= stateSize.y;",
        "    uint n = texelFetch(state, offset, 0).r;",
        "    return Tile_d(n);",
        "}",
    )

    def makeFunction(context : TypeContext, function : DFunction) : String = {
        val extra = List("inout uint seed", "uint transform")
        val parametersCode = (extra ++ function.parameters.map { case Parameter(_, name, kind) =>
            kind + " " + name + "_"
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

        val ruleSheet = Sheet.autoSize(rule.patterns)
        val arguments = ruleSheet.computeCellOffsets(rule.patterns).cells.flatten

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

        val extra = List("inout uint seed", "uint transform")
        val argumentsCode = extra ++ arguments.map { case (cell, _, write) =>
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

    def makeRuleCalls(hashOffset : Int, g : DGroup, sheet : Sheet) : String = {
        val didReactions = g.rules.map(r =>
            s"bool ${r.name}_d = false;"
        )
        val groupCondition = condition(g.scheme.unless)
        val ruleCalls = g.rules.map { r =>

            val ruleCondition = condition(
                if(g.scheme.unless.contains(g.name)) g.name :: r.scheme.unless
                else r.scheme.unless
            )

            def computeParameters(modifiers : List[String]) : List[String] = {
                val suffix = if(r.scheme.wrapper.nonEmpty) "r" else if(g.scheme.wrapper.nonEmpty) "g" else ""
                val cellArguments = sheet.makeCellArguments(r.patterns.head.size, r.patterns.size, modifiers) match {
                    case Right(result) => result
                    case Left(problem) => fail(r.line, problem)
                }
                cellArguments.map { case (transform, arguments) =>
                    val cells = arguments.map(_ + suffix)
                    "seed" :: (transform + "u") :: cells
                }.map(_.mkString(", "))
            }

            val modifiers = (g.scheme.modifiers ++ r.scheme.modifiers).distinct
            val callsParameters = computeParameters(modifiers)

            val unless = (g.scheme.unless ++ r.scheme.unless).toSet

            val calls = callsParameters.zipWithIndex.map { case (parameters, index) =>
                //val digest = MessageDigest.getInstance("MD5");
                //val hash = digest.digest((hashOffset + index).toString.getBytes("UTF-8"))
                val hash = Md5.md5Bytes((hashOffset + index).toString)
                val entropy = new BigInteger(hash).intValue().toLong.abs
                lines(
                    s"seed ^= ${entropy}u;",
                    if(unless.contains(g.name) || unless.contains(r.name)) {
                        s"${r.name}_d = ${r.name}_d || ${r.name}_r($parameters);"
                    } else {
                        s"${r.name}_d = ${r.name}_r($parameters) || ${r.name}_d;"
                    }
                )
            }

            val bodyLines = calls :+ s"${g.name}_d = ${g.name}_d || ${r.name}_d;"
            val ruleBody = r.scheme.wrapper.map { property =>
                wrap(
                    property = property,
                    groupLevel = false,
                    wrapped = g.scheme.wrapper.nonEmpty,
                    groupModifiers = g.scheme.modifiers,
                    rules = List(r),
                    body = bodyLines,
                    sheet = sheet
                )
            }.getOrElse(lines(bodyLines))

            if(ruleCondition == "true") ruleBody else lines(
                s"if($ruleCondition) {",
                indent(ruleBody),
                s"}"
            )
        }

        val groupBody = g.scheme.wrapper.map { property =>
            wrap(property, groupLevel = true, wrapped = false, g.scheme.modifiers, g.rules, ruleCalls, sheet)
        }.getOrElse(lines(ruleCalls))

        val group = if(groupCondition == "true" || groupCondition == s"!${g.name}_d") groupBody else lines(
            s"if($groupCondition) {",
            indent(groupBody),
            s"}"
        )

        lines(didReactions ++ List(group))
    }

    def makeGroupFunctions(sheet : Sheet, groups : List[DGroup]) : List[String] = {
        val cellParameters = sheet.sheetMatrix.cells.flatten.map("inout value " + _).mkString(", ")
        var hashOffset = 0
        groups.map { group =>
            val result = makeRuleCalls(hashOffset, group, sheet)
            hashOffset += (group.rules.size * 100)
            lines(
                s"void ${group.name}_g(inout bool ${group.name}_d, inout uint seed, $cellParameters) {",
                indent(result),
                "}"
            )
        }
    }

    def wrap(
        property : String,
        groupLevel : Boolean,
        wrapped : Boolean,
        groupModifiers : List[String],
        rules : List[Rule],
        body : List[String],
        sheet : Sheet
    ) : String = {
        val cells = rules.flatMap { r =>
            val modifiers = (groupModifiers ++ r.scheme.modifiers).distinct
            val arguments = sheet.makeCellArguments(r.patterns.head.size, r.patterns.size, modifiers)
            arguments.toOption.get.flatMap(_._2) // TODO
        }
        val before = cells.map { cell =>
            val outer = if(wrapped) "g" else ""
            val inner = if(groupLevel) "g" else "r"
            s"value ${cell}$inner = ${property}_d($cell$outer.$property);"
        }
        val center = sheet.computeCenterCells()
        val after = cells.collect { case cell if center.contains(cell) =>
            val outer = if(wrapped) "g" else ""
            val inner = if(groupLevel) "g" else "r"
            s"$cell$outer.$property = ${property}_e(${cell}$inner);"
        }
        lines(before ++ body ++ after)
    }

    def condition(unless : List[String]) = unless match {
        case List() => "true"
        case _ => unless.map("!" + _ + "_d").mkString(" && ")
    }

    def makeMain(sheet : Sheet, groups : List[DGroup]) : String = {

        val lookupLines = sheet.sheetMatrix.cells.zipWithIndex.flatMap { case (row, y) =>
            row.zipWithIndex.map { case (cell, x) =>
                val newX = 1 + x - sheet.size / 2
                val newY = sheet.size - y - sheet.size / 2
                "value " + cell + " = lookupTile(bottomLeft + ivec2(" + newX + ", " + newY + "));"
            }
        }

        val List(a1, b1, a2, b2) = sheet.computeCenterCells()

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
                "    random(seed, 712387635u, 1u);",
                "    seed ^= uint(position.x);",
                "    random(seed, 611757929u, 1u);",
                "    seed ^= uint(position.y);",
                "    random(seed, 999260970u, 1u);",
            ),
            lines(groups.map { group =>
                s"    bool ${group.name}_d = false;"
            }),
            lines(groups.map { group =>
                s"    ${group.name}_g(${group.name}_d, seed, ${sheet.sheetMatrix.cells.flatten.mkString(", ")});"
            }),
            lines(
                "    // Write and encode own value",
                "    ivec2 quadrant = position - bottomLeft;",
                "    value target = " + a2 + ";",
                "    if(quadrant == ivec2(0, 1)) target = " + a1 + ";",
                "    else if(quadrant == ivec2(1, 0)) target = " + b2 + ";",
                "    else if(quadrant == ivec2(1, 1)) target = " + b1 + ";",
                "    outputValue = Tile_e(target);",
            ),
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
