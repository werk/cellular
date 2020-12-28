package cellular.mini

import java.math.BigInteger
import java.security.MessageDigest

import cellular.mini.Compiler.indent
import cellular.mini.Emitter.AbstractEmitter

class Emitter extends AbstractEmitter {

    def emitExpression(context: TypeContext, destination: String, expression: Expression): String = {
        expression match {

            case EVariable(_, _, name) =>
                destination + " = " + escapeVariable(name) + ";\n"

            case ECall(line, _, function, arguments) =>
                val destinations = arguments.map {
                    case EVariable(_, _, name) => escapeVariable(name) -> None
                    case EMaterial(_, _, name) if name.head.isDigit => name + "u" -> None
                    case e => generateVariable() -> Some(e)
                }
                val argumentsCode = destinations.collect {
                    case (variable, Some(e)) => emitExpression(context, e.kind + " " + variable, e)
                }.mkString
                val (_, _, builtIn) = context.functions.getOrElse(function,
                    fail(line, "No such function: " + function)
                )
                if(builtIn) {
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
                        case List((x, _)) if function == "random" =>
                            val digest = MessageDigest.getInstance("MD5");
                            val hash = digest.digest((line + x).getBytes("UTF-8"))
                            val entropy = new BigInteger(hash).intValue().toLong.abs
                            "random(seed, " + entropy + "u, " + x + ")"
                        case _ =>
                            val variablesCode = destinations.map(_._1).mkString(", ")
                            function + "(" + variablesCode + ")"
                    }
                    argumentsCode + destination + " = " + callCode + ";\n"
                } else {
                    val variablesCode = ("seed" +: destinations.map(_._1) :+ destination).mkString(", ")
                    val callCode = "if(!" + function + "_f(" + variablesCode + ")) return false;\n"
                    argumentsCode + callCode
                }

            case EMatrix(line, _, expressions) =>
                destination.split(":") match {
                    case Array(first, _) =>
                        val firstX = first.head
                        val firstY = first.drop(1).toInt
                        expressions.zipWithIndex.flatMap { case (row, y) =>
                            row.zipWithIndex.map { case (e, x) =>
                                val cell = (firstX + x).toChar + (firstY + y).toString + "t"
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
                destination + ".material = " + material + ";\n"

            case EProperty(_, _, expression, property, value) =>
                val expressionCode = emitExpression(context, destination, expression)
                val propertyCode = emitNumber(context, destination + "." + property, property, value)
                expressionCode + propertyCode

            case EMatch(_, _, expression, matchCases) =>
                val variable = generateVariable()
                val variableCode = expression.kind + " " + variable + ";\n"
                val expressionCode = emitExpression(context, variable, expression)
                val matchCode = emitMatch(context, destination, matchCases, variable)
                variableCode + expressionCode + matchCode

        }
    }

    def emitMatch(context: TypeContext, destination: String, matchCases: List[MatchCase], variable: String): String = {
        matchCases match {
            case List(case1) =>
                emitMatchCase(context, destination, case1, variable, multiMatch = false)
            case List(
                MatchCase(_, Pattern(_, KBool, None, List(SymbolPattern(_, "1", None))), e1),
                MatchCase(_, Pattern(_, KBool, None, List(SymbolPattern(_, "0", None))), e2)
            ) =>
                val thenBody = emitExpression(context, destination, e1)
                val elseBody = emitExpression(context, destination, e2)
                "if(" + variable + ") {\n" + thenBody + "} else {\n" + elseBody + "}\n"
            case _ =>
                val done = generateVariable("m_")
                val doneCode = "int " + done + " = 0;\n"
                val casesCode = matchCases.map { c =>
                    val caseCode = emitMatchCase(context, destination, c, variable, multiMatch = true)
                    val commitCode = done + " = 1;\n"
                    "switch(" + done + ") { case 0:\n" + indent(caseCode + commitCode) + "\ndefault: break; }\n"
                }.mkString
                val nonExhaustiveCode = "if(" + done + " == 0) return false;\n"
                doneCode + casesCode + nonExhaustiveCode
        }
    }

    def emitMatchCase(
        context: TypeContext,
        destination: String,
        matchCase: MatchCase,
        variable: String,
        multiMatch: Boolean
    ): String = {
        val patternCode = emitPattern(context, matchCase.pattern, variable, None, multiMatch)
        val bodyCode = emitExpression(context, destination, matchCase.body)
        patternCode + bodyCode
    }

    def emitPattern(
        context: TypeContext,
        pattern: Pattern,
        input: String,
        decodeProperty: Option[String],
        multiMatch: Boolean
    ): String = {
        val variableName = pattern.name.map(escapeVariable).getOrElse(generateVariable())
        val variableCode = decodeProperty.filter(_ => pattern.kind == KValue).map {
            emitDecode(context, "value " + variableName, _, input)
        }.getOrElse(pattern.kind + " " + variableName + " = " + input + ";\n")
        val checks = pattern.symbols.map { s =>
            emitCheck(context, variableName, pattern.kind, TSymbol(s.line, s.symbol))
        }
        val abortCode = if(multiMatch) "break;\n" else "return false;\n"
        val checkCode = if(checks.isEmpty) "" else "if(" + checks.mkString(" || ") + ") " + abortCode
        val subPatterns = pattern.symbols.collect { case SymbolPattern(_, property, Some(p)) =>
            emitPattern(context, p, variableName + "." + property, Some(property), multiMatch)
        }
        val subPatternCode = subPatterns.mkString
        variableCode + checkCode + subPatternCode
    }

    def emitCheck(context: TypeContext, variableName: String, kind: Kind, type0: Type): String = type0 match {
        case TUnion(_, t1, t2) =>
            "(" + emitCheck(context, variableName, kind, t1) +
            " && " + emitCheck(context, variableName, kind, t2) + ")"
        case TIntersection(_, t1, t2) =>
            "(" + emitCheck(context, variableName, kind, t1) +
            " || " + emitCheck(context, variableName, kind, t2) + ")"
        case TSymbol(_, symbol) =>
            context.typeAliases.get(symbol).map(emitCheck(context, variableName, kind, _)).getOrElse {
                if(kind == KBool && symbol == "0") variableName
                else if(kind == KBool) "!" + variableName
                else if(kind == KNat) variableName + " != " + symbol + "u"
                else if(context.materialIndexes.contains(symbol)) variableName + ".material != " + symbol
                else variableName + "." + symbol + " == NOT_FOUND"
            }
    }

    def emitNumber(context: TypeContext, destination: String, property: String, value: Expression): String = {
        val variable = generateVariable()
        val variableCode = value.kind + " " + variable + ";\n"
        val valueCode = emitExpression(context, variable, value)
        val encodeCode = if(value.kind == KNat) {
            val size = Codec.propertySizeOf(context, property)
            "if(" + variable + " >= " + size + "u) return false;\n" +
            destination + " = " + variable + ";\n"
        } else emitEncode(context, destination, property, variable)
        variableCode + valueCode + encodeCode
    }

    def emitEncode(context: TypeContext, destination: String, property: String, input: String): String = {
        destination + " = " + property + "_e(" + input + ");\n"
    }

    def emitDecode(context: TypeContext, destination: String, property: String, input: String): String = {
        destination + " = " + property + "_d(" + input + ");\n"
    }

}

object Emitter {

    abstract class AbstractEmitter {

        private var nextValueVariable = 0;

        def generateVariable(prefix: String = "v_"): String = {
            nextValueVariable += 1
            prefix + nextValueVariable
        }

        def escapeVariable(value: String): String = {
            value + "_"
        }

        protected def fail(line: Int, message: String) = {
            throw new RuntimeException(message + " at line " + line)
        }

    }

}
