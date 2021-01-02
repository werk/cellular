package cellular.mini

import java.math.BigInteger
import java.security.MessageDigest

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
            makeTileSizeComment(context),
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
        val cases = materials.toList.filterNot(_.head.isDigit).sorted.zipWithIndex.map { case (m, i) =>
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
                    "n /= " + Codec.propertySizeOf(context, p) + "u;",
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
            s"    n /= " + materials.size + "u;",
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

    def computeCells[T](matrix: List[List[T]], maxWidth : Int, maxHeight : Int): List[List[(String, T, Boolean)]] = {
        val baseX = (maxWidth - matrix.head.size) / 2
        val baseY = (maxHeight - matrix.size) / 2

        val writeMinX = (matrix.head.size - 1) / 2
        val writeMinY = (matrix.size - 1) / 2
        val writeMaxX = matrix.head.size / 2
        val writeMaxY = matrix.size / 2

        matrix.zipWithIndex.map { case (ps, y) =>
            val row = (y + 1 + baseY).toString
            ps.zipWithIndex.map { case (p, x) =>
                val cell = ('a' + x + baseX).toChar + row
                val writeX = x >= writeMinX && x <= writeMaxX
                val writeY = y >= writeMinY && y <= writeMaxY
                (cell, p, writeX && writeY)
            }
        }
    }

    def computeBoundingCells(rules : List[Rule], outerMaxWidth : Option[Int], outerMaxHeight : Option[Int]) = {
        def adjust(size : Int) = ((Math.max(2, size) + 1) / 2) * 2
        val maxWidth = adjust(
            rules.map(_.patterns.head.size).maxOption.getOrElse(0)
        )
        val maxHeight = adjust(
            rules.map(_.patterns.size).maxOption.getOrElse(0)
        )
        (maxWidth, maxHeight, computeCells(
            (0 until maxHeight).toList.map(y =>
            (0 until maxWidth).toList.map(x => (x, y))),
            outerMaxWidth.getOrElse(maxWidth),
            outerMaxHeight.getOrElse(maxHeight),
        ).flatten)
    }

    def makeRuleFunction(context : TypeContext, rule : Rule) : String = {

        val arguments = computeCells(rule.patterns, rule.patterns.head.size, rule.patterns.size).flatten

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

    def makeRuleCalls(hashOffset : Int, g : DGroup, outerMaxWidth : Int, outerMaxHeight : Int) : String = {
        val comment = s"// ${g.name}"
        val didGroup = s"bool ${g.name}_d = false;"
        val didReactions = g.rules.map(r =>
            s"bool ${r.name}_d = false;"
        )
        val groupCondition = condition(g.scheme.unless)
        val ruleCalls = g.rules.map { r =>

            val ruleCondition = condition(
                if(g.scheme.unless.contains(g.name)) g.name :: r.scheme.unless
                else r.scheme.unless
            )

            def modify[T](modifier: String, matrix: List[List[T]]): List[List[T]] = {
                modifier match {
                    case "" =>
                        matrix
                    case "h" =>
                        matrix.map(_.reverse)
                    case "v" =>
                        matrix.reverse
                    case "90" =>
                        matrix.map(_.reverse).transpose
                    case "180" =>
                        matrix.map(_.reverse).transpose.map(_.reverse).transpose
                    case "270" =>
                        matrix.map(_.reverse).transpose.map(_.reverse).transpose.map(_.reverse).transpose
                    case _ =>
                        fail(r.line, "Unknown modifier: " + modifier)
                }
            }

            def offset(x : Int, y : Int)(cell : String) = {
                val cellX = cell.head + x
                val cellY = cell.drop(1).toInt + y
                cellX.toChar + cellY.toString
            }

            def offsetParameters(patterns : List[List[Pattern]], cells : List[String]) : List[List[String]] = {
                (patterns.head.size % 2, patterns.size % 2) match {
                    case (0, 1) => List(
                        cells.map(offset(0, 0)),
                        cells.map(offset(0, 1))
                    )
                    case (1, 0) => List(
                        cells.map(offset(0, 0)),
                        cells.map(offset(1, 0))
                    )
                    case (1, 1) => List(
                        cells.map(offset(0, 0)),
                        cells.map(offset(0, 1)),
                        cells.map(offset(1, 0)),
                        cells.map(offset(1, 1))
                    )
                    case _ => List(
                        cells.map(offset(0, 0))
                    )
                }
            }

            def computeParameters(modifier : String) = {
                val patterns = modify(modifier, r.patterns)
                val cells = computeCells(patterns, outerMaxWidth, outerMaxHeight).map(_.map(_._1))
                val suffix = if(r.scheme.wrapper.nonEmpty) "r" else if(g.scheme.wrapper.nonEmpty) "g" else ""
                val offset = offsetParameters(patterns, cells.flatten)
                val mirrored = if(List("h", "v", "180", "270").contains(modifier)) offset.map(_.reverse) else offset
                val transform = (modifier match {
                    case "" => 0
                    case "h" => 1
                    case "v" => 2
                    case rotation => rotation.toInt
                }) + "u"
                mirrored.map("seed" :: transform :: _.map(_ + suffix)).map(_.mkString(", "))
            }
            val modifiers = "" :: (g.scheme.modifiers ++ r.scheme.modifiers).distinct
            val callsParameters = modifiers.flatMap(computeParameters)

            val unless = (g.scheme.unless ++ r.scheme.unless).toSet

            val calls = callsParameters.zipWithIndex.map { case (parameters, index) =>
                val digest = MessageDigest.getInstance("MD5");
                val hash = digest.digest((hashOffset + index).toString.getBytes("UTF-8"))
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
                    rules = List(r),
                    body = bodyLines,
                    outerMaxWidth = outerMaxWidth,
                    outerMaxHeight = outerMaxHeight
                )
            }.getOrElse(lines(bodyLines))

            lines(
                s"if($ruleCondition) {",
                indent(ruleBody),
                s"}"
            )
        }

        val groupBody = g.scheme.wrapper.map { property =>
            wrap(property, groupLevel = true, wrapped = false, g.rules, ruleCalls, outerMaxWidth, outerMaxHeight)
        }.getOrElse(lines(ruleCalls))

        val group = lines(
            s"if($groupCondition) {",
            indent(groupBody),
            s"}"
        )

        lines(comment :: didGroup :: didReactions ++ List(group))
    }

    def wrap(
        property : String,
        groupLevel : Boolean,
        wrapped : Boolean,
        rules : List[Rule],
        body : List[String],
        outerMaxWidth : Int,
        outerMaxHeight : Int
    ) : String = {
        val (_, _, cells) = computeBoundingCells(rules, Some(outerMaxWidth), Some(outerMaxHeight))
        val before = cells.map { case (cell, _, write) =>
            val outer = if(wrapped) "g" else ""
            val inner = if(groupLevel) "g" else "r"
            s"value ${cell}$inner = ${property}_d($cell$outer.$property);"
        }
        val after = cells.collect { case (cell, _, true) =>
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

    def makeMain(context : TypeContext, groups : List[DGroup]) : String = {

        val (maxWidth, maxHeight, cells) = computeBoundingCells(groups.flatMap(_.rules), None, None)

        val lookupLines = cells.map { case (cell, (x, y), _) =>
            val newX = 1 + x - maxWidth / 2
            val newY = maxHeight - y - maxHeight / 2
            "value " + cell + " = lookupTile(bottomLeft + ivec2(" + newX + ", " + newY + "));"
        }

        var hashOffset = 0
        val groupCalls = groups.map { group =>
            val result = makeRuleCalls(hashOffset, group, maxWidth, maxHeight)
            hashOffset += (group.rules.size * 100)
            result
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
                "    random(seed, 712387635u, 1u);",
                "    seed ^= uint(position.x);",
                "    random(seed, 611757929u, 1u);",
                "    seed ^= uint(position.y);",
                "    random(seed, 999260970u, 1u);",
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
