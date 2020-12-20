package cellular.mini

object Inference {

    case class InferenceContext(
        variables : Map[String, Kind],
        properties : Map[String, Kind],
        functions : Map[String, (List[Kind], Kind)],
    )

    def createContext(definitions: List[Definition]) = {
        def typeIsNat(t: Type): Boolean = t match {
            case TIntersection(line, type1, type2) => typeIsNat(type1) || typeIsNat(type2)
            case TUnion(line, type1, type2) => typeIsNat(type1) || typeIsNat(type2)
            case TSymbol(line, name) => name.head.isDigit
        }
        val properties = definitions.collect { case property : DProperty =>
            val kind = if(property.propertyType.map(_.valueType).exists(typeIsNat)) KNat else KValue
            property.name -> kind
        }
        InferenceContext(
            variables = Map(),
            properties = properties.toMap,
            functions = defaultFunctions,
        )
    }

    val defaultFunctions = Map(
        "!==" -> (List(KValue, KValue), KBool),
        "===" -> (List(KValue, KValue), KBool),
        "!=" -> (List(KNat, KNat), KBool),
        "==" -> (List(KNat, KNat), KBool),
        "<=" -> (List(KNat, KNat), KBool),
        ">=" -> (List(KNat, KNat), KBool),
        "<" -> (List(KNat, KNat), KBool),
        ">" -> (List(KNat, KNat), KBool),
        "&&" -> (List(KBool, KBool), KBool),
        "||" -> (List(KBool, KBool), KBool),
        "<>" -> (List(KBool, KBool), KBool),
        "!" -> (List(KBool), KBool),
        "+" -> (List(KNat, KNat), KNat),
        "-" -> (List(KNat, KNat), KNat),
        "*" -> (List(KNat, KNat), KNat),
        "/" -> (List(KNat, KNat), KNat),
        "%" -> (List(KNat, KNat), KNat),
    )

    def inferRule(context: InferenceContext, rule: Rule): Rule = {
        var newContext = context
        val newPatterns = rule.patterns.map(_.map { p =>
            val (newPattern1, newContext1) = inferPattern(newContext, KValue, p)
            newContext = newContext1
            newPattern1
        })
        val newExpression = inferExpression(newContext, rule.expression)
        if(newExpression.kind != KMatrix) {
            fail(newExpression.line, "Expected matrix, got: " + newExpression.kind)
        }
        rule.copy(patterns = newPatterns, expression = newExpression)
    }

    def inferExpression(context: InferenceContext, expression: Expression): Expression = {
        expression match {
            case e@EVariable(line, _, name) =>
                e.copy(kind = context.variables(name))
            case e@EMatch(line, _, expression, matchCases) =>
                val newExpression = inferExpression(context, expression)
                val newMatchCases = matchCases.map(inferMatchCase(context, newExpression.kind, _))
                val headKind :: tailKinds = newMatchCases.map(_.body.kind)
                tailKinds.find(_ != headKind).foreach(matchType =>
                    fail(line, "Kind mismatch: " + matchType + " vs. " + headKind)
                )
                e.copy(kind = headKind, expression = newExpression, matchCases = newMatchCases)
            case e@ECall(line, _, function, arguments) =>
                val (argumentKinds, returnKind) = context.functions(function)
                val newArguments = arguments.map(inferExpression(context, _))
                if(argumentKinds != newArguments.map(_.kind)) {
                    fail(line,
                        "Argument kind mismatch: " + newArguments.map(_.kind).mkString(", ") +
                        " vs. " + argumentKinds.mkString(", ")
                    )
                }
                e.copy(kind = returnKind, arguments = newArguments)
            case e@EProperty(line, _, expression, property, value) =>
                val resultKind = context.properties.getOrElse(property,
                    fail(line, "Unknown property: " + property)
                )
                val newExpression = inferExpression(context, expression)
                if(newExpression.kind != KValue) {
                    fail(line, "Kind mismatch: " + newExpression.kind + " vs. " + KValue)
                }
                val newValue = inferExpression(context, value)
                if(resultKind != newValue.kind) {
                    fail(line, "Kind mismatch: " + resultKind + " vs. " + newValue.kind)
                }
                e.copy(kind = newExpression.kind, expression = newExpression, value = newValue)
            case e@EMaterial(line, _, material) if(material.head.isDigit) =>
                e.copy(kind = KNat)
            case e@EMaterial(line, _, material) =>
                e.copy(kind = KValue)
            case e@EMatrix(line, _, expressions) =>
                val newExpressions = expressions.map(_.map(inferExpression(context, _)))
                newExpressions.flatten.map(_.kind).find(_ != KValue).foreach { expressionKind =>
                    fail(line, "Kind mismatch: " + expressionKind + " vs. " + KValue)
                }
                e.copy(kind = KMatrix, expressions = newExpressions)
        }
    }

    def inferMatchCase(context: InferenceContext, matchType : Kind, matchCase: MatchCase): MatchCase = {
        val (newPattern, newContext) = inferPattern(context, matchType, matchCase.pattern)
        val newBody = inferExpression(newContext, matchCase.body)
        matchCase.copy(pattern = newPattern, body = newBody)
    }

    def inferPattern(context: InferenceContext, matchType : Kind, pattern: Pattern): (Pattern, InferenceContext) = {
        var newContext = pattern.name.map(name =>
            context.copy(variables = context.variables.updated(name, matchType))
        ).getOrElse(context)
        val newSymbols = pattern.symbols.map { symbolPattern =>
            val newSubpattern = symbolPattern.pattern.map { p =>
                val symbolType = newContext.properties(symbolPattern.symbol)
                val (newPattern1, newContext1) = inferPattern(newContext, symbolType, p)
                newContext = newContext1
                newPattern1
            }
            symbolPattern.copy(pattern = newSubpattern)
        }
        val newPattern = pattern.copy(kind = matchType, symbols = newSymbols)
        (newPattern, newContext)
    }

    protected def fail(line: Int, message: String) = {
        throw new RuntimeException(message + " at line " + line)
    }

}

