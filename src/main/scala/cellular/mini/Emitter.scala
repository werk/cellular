package cellular.mini

import cellular.mini.Emitter.AbstractEmitter

class Emitter extends AbstractEmitter {

    def emitExpression(context: TypeContext, destination: String, expression: Expression): String = {
        expression match {

            case EVariable(name) =>
                destination + " = " + escapeVariable(name) + ";\n"

            case ECall(function, arguments) =>
                val destinations = arguments.map(e => generateValueVariable() -> e)
                val argumentsCode = destinations.map { case (variable, e) =>
                    emitExpression(context, variable, e)
                }.mkString
                val variablesCode = destinations.map(_._1).mkString(",\n")
                argumentsCode + destination + " = " + escapeVariable(function) + "(\n" + variablesCode + "\n);\n"

            case EMatrix(expressions) =>
                expressions.zipWithIndex.flatMap { case (row, y) =>
                    row.zipWithIndex.map { case (e, x) =>
                        val property = "x" + x + "y" + y
                        emitNumber(context, destination + "." + property, property, e)
                    }
                }.mkString

            case EMaterial(material) =>
                val materialIndex = context.materialIndexes(material)
                destination + ".material = " + materialIndex + ";\n"

            case EProperty(expression, property, value) =>
                val expressionCode = emitExpression(context, destination, expression)
                val propertyCode = emitNumber(context, destination + "." + property, property, value)
                expressionCode + propertyCode

            case EMatch(expression, matchCases) =>
                val variable = generateValueVariable()
                val variableCode = "Value " + escapeVariable(variable) + ";\n"
                val expressionCode = emitExpression(context, variable, expression)
                val matchCode = emitMatch(context, destination, matchCases, variable)
                variableCode + expressionCode + matchCode

        }
    }

    def emitMatch(context: TypeContext, destination: String, matchCases: List[MatchCase], variable: String): String = {
        if(matchCases.size != 1) throw new RuntimeException("Not implemented: Multiple match cases: " + matchCases)
        matchCases.map { c => emitMatchCase(context, destination, c, variable) }.mkString
    }

    def emitMatchCase(context: TypeContext, destination: String, matchCase: MatchCase, variable: String): String = {
        val patternCode = emitPattern(context, matchCase.pattern, escapeVariable(variable), None)
        val bodyCode = emitExpression(context, destination, matchCase.body)
        patternCode + bodyCode
    }

    def emitPattern(context: TypeContext, pattern: Pattern, input: String, decodeProperty: Option[String]): String = {
        val variableName = pattern.name.getOrElse(generateValueVariable())
        val variableCode = decodeProperty.map {
            emitDecode(context, variableName, _, input)
        }.getOrElse(escapeVariable(variableName) + " = " + input + ";\n")
        val checks = pattern.properties.map { p =>
            escapeVariable(variableName) + "." + p.property + " == NOT_FOUND"
        }
        val checkCode = if(checks.isEmpty) "" else "if(" + checks.mkString(" || ") + ") return false;\n"
        val subPatterns = pattern.properties.collect { case PropertyPattern(property, Some(p)) =>
            emitPattern(context, p, escapeVariable(variableName) + "." + property, Some(property))
        }
        val subPatternCode = subPatterns.mkString
        variableCode + checkCode + subPatternCode
    }

    def emitNumber(context: TypeContext, destination: String, property: String, value: Expression): String = {
        val variable = generateValueVariable()
        val variableCode = "Value " + escapeVariable(variable) + ";\n"
        val valueCode = emitExpression(context, variable, value)
        val encodeCode = emitEncode(context, destination + "." + property, property, variable)
        variableCode + valueCode + encodeCode
    }

    def emitEncode(context: TypeContext, destination: String, property: String, input: String): String = {
        "Value " + escapeVariable(destination) + " = encode(" + input + ", FIXED_" + property + ")\n"
    }

    def emitDecode(context: TypeContext, destination: String, property: String, input: String): String = {
        "Value " + escapeVariable(destination) + " = decode(" + input + ", FIXED_" + property + ")\n"
    }

}

object Emitter {

    abstract class AbstractEmitter {

        private var nextValueVariable = 0;
        private var nextNumberVariable = 0;

        def generateValueVariable(): String = {
            nextValueVariable += 1
            "v_" + nextValueVariable
        }

        def generateNumberVariable(): String = {
            nextNumberVariable += 1
            "v_" + nextNumberVariable
        }

        def escapeVariable(value: String): String = {
            value + "_"
        }

    }

    def main(args : Array[String]) : Unit = {
        val code = "q : x Foo(y Bar(z)) Baz(w) Quux => e"
        val parsed = new Parser(code).parseExpression()
        val context = TypeContext(Map(), Map(), Map(), Map())
        println(new Emitter().emitExpression(context, "result", parsed))
    }

}
