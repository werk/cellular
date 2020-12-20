package cellular.mini

import cellular.mini.Emitter.AbstractEmitter

class Emitter extends AbstractEmitter {

    def emitExpression(context: TypeContext, destination: String, expression: Expression): String = {
        expression match {

            case EVariable(_, _, name) =>
                destination + " = " + escapeVariable(name) + ";\n"

            case ECall(_, _, function, arguments) =>
                val destinations = arguments.map(e => generateValueVariable() -> e)
                val argumentsCode = destinations.map { case (variable, e) =>
                    emitExpression(context, e.kind + " " + variable, e)
                }.mkString
                val callCode = destinations match {
                    case List((x, _)) if !function.head.isLetter =>
                        "(" + function + x + ")"
                    case List((x1, _), (x2, _)) if !function.head.isLetter =>
                        val operator = function match {
                            case "!==" => "!="
                            case "===" => "=="
                            case "<>" => "^^"
                            case _ => function
                        }
                        "(" + x1 + " " + operator + " " + x2 + ")"
                    case _ =>
                        val variablesCode = destinations.map(_._1).mkString(", ")
                        function + "(" + variablesCode + ")"
                }
                argumentsCode + destination + " = " + callCode + ";\n"

            case EMatrix(line, _, expressions) =>
                destination.split(":") match {
                    case Array(first, _) =>
                        val firstX = first.head
                        val firstY = first.drop(1).toInt
                        expressions.zipWithIndex.flatMap { case (row, y) =>
                            row.zipWithIndex.map { case (e, x) =>
                                val cell = (firstX + x).toChar + (firstY + y).toString
                                emitExpression(context, cell, e)
                            }
                        }.mkString
                    case _ =>
                        fail(line, "Can't write a matrix to the destination: " + destination)
                }

            case EMaterial(_, _, material) if material.head.isDigit =>
                destination + " = " + material + "u;\n"

            case EMaterial(line, _, material) =>
                val materialIndex = context.materialIndexes.getOrElse(material, {
                    fail(line, "Unknown material: " + material)
                })
                destination + " = ALL_NOT_FOUND;\n" +
                destination + ".material = " + materialIndex + "u;\n"

            case EProperty(_, _, expression, property, value) =>
                val expressionCode = emitExpression(context, destination, expression)
                val propertyCode = emitNumber(context, destination + "." + property, property, value)
                expressionCode + propertyCode

            case EMatch(_, _, expression, matchCases) =>
                val variable = generateValueVariable()
                val variableCode = expression.kind + " " + variable + ";\n"
                val expressionCode = emitExpression(context, variable, expression)
                val matchCode = emitMatch(context, destination, matchCases, variable)
                variableCode + expressionCode + matchCode

        }
    }

    def emitMatch(context: TypeContext, destination: String, matchCases: List[MatchCase], variable: String): String = {
        if(matchCases.size != 1) fail(matchCases(1).line, "Multiple match cases not implemented: " + matchCases)
        matchCases.map { c => emitMatchCase(context, destination, c, variable) }.mkString
    }

    def emitMatchCase(context: TypeContext, destination: String, matchCase: MatchCase, variable: String): String = {
        val patternCode = emitPattern(context, matchCase.pattern, variable, None)
        val bodyCode = emitExpression(context, destination, matchCase.body)
        patternCode + bodyCode
    }

    def emitPattern(context: TypeContext, pattern: Pattern, input: String, decodeProperty: Option[String]): String = {
        val variableName = pattern.name.map(escapeVariable).getOrElse(generateValueVariable())
        val variableCode = decodeProperty.filter(_ => pattern.kind == KValue).map {
            emitDecode(context, "Value " + variableName, _, input)
        }.getOrElse(pattern.kind + " " + variableName + " = " + input + ";\n")
        val checks = pattern.symbols.map { s =>
            if(pattern.kind == KBool && s.symbol == "0") variableName
            else if(pattern.kind == KBool) "!" + variableName
            else if(pattern.kind == KNat) variableName + " != " + s.symbol + "u"
            else if(context.materialIndexes.contains(s.symbol)) variableName + ".material != " + s.symbol
            else variableName + "." + s.symbol + " == NOT_FOUND"
        }
        val checkCode = if(checks.isEmpty) "" else "if(" + checks.mkString(" || ") + ") return false;\n"
        val subPatterns = pattern.symbols.collect { case SymbolPattern(_, property, Some(p)) =>
            emitPattern(context, p, variableName + "." + property, Some(property))
        }
        val subPatternCode = subPatterns.mkString
        variableCode + checkCode + subPatternCode
    }

    def emitNumber(context: TypeContext, destination: String, property: String, value: Expression): String = {
        val variable = generateValueVariable()
        val variableCode = value.kind + " " + variable + ";\n"
        val valueCode = emitExpression(context, variable, value)
        val encodeCode =
            if(value.kind == KNat) destination + " = " + variable + ";\n"
            else emitEncode(context, destination, property, variable)
        variableCode + valueCode + encodeCode
    }

    def emitEncode(context: TypeContext, destination: String, property: String, input: String): String = {
        destination + " = encode(" + input + ", FIXED_" + property + ");\n"
    }

    def emitDecode(context: TypeContext, destination: String, property: String, input: String): String = {
        destination + " = decode(" + input + ", FIXED_" + property + ");\n"
    }

}

object Emitter {

    abstract class AbstractEmitter {

        private var nextValueVariable = 0;

        def generateValueVariable(): String = {
            nextValueVariable += 1
            "v_" + nextValueVariable
        }

        def escapeVariable(value: String): String = {
            value + "_"
        }

        protected def fail(line: Int, message: String) = {
            throw new RuntimeException(message + " at line " + line)
        }

    }

    def main(args : Array[String]) : Unit = {
        val code = "q : x Foo(y Bar(z)) Baz(w) Quux => e"
        val parsed = new Parser(code).parseExpression()
        val context = TypeContext(Map(), Map(), Map(), Map())
        println(new Emitter().emitExpression(context, "result", parsed))
    }

}
