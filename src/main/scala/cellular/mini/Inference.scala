package cellular.mini

object Inference {

    case class InferenceContext(
        typeAliases: Map[String, Type],
        variables: Map[String, Kind],
        propertiesOrTypeAliases: Map[String, Kind],
        functions: Map[String, (List[Kind], Kind, Boolean)],
    )

    def typeIsNat(typeAliases: Map[String, Type], t: Type): Boolean = t match {
        case TIntersection(line, type1, type2) => typeIsNat(typeAliases, type1) || typeIsNat(typeAliases, type2)
        case TUnion(line, type1, type2) => typeIsNat(typeAliases, type1) || typeIsNat(typeAliases, type2)
        case TSymbol(line, name) => typeAliases.get(name).map(typeIsNat(typeAliases, _)).getOrElse(name.head.isDigit)
    }

    def createContext(definitions: List[Definition]) = {
        val typeAliases = definitions.collect { case definition : DType =>
            definition.name -> definition.expandedType
        }.toMap
        val typeAliasKinds = typeAliases.map { case (name, t) =>
            val kind = if(typeIsNat(typeAliases, t)) KNat else KValue
            name -> kind
        }
        val properties = definitions.collect { case property : DProperty =>
            val kind = if(typeIsNat(typeAliases, property.propertyType.valueType)) KNat else KValue
            property.name -> kind
        }
        val userFunctions = definitions.collect { case function : DFunction =>
            function.name -> ((function.parameters.map(_.kind), function.returnKind, false))
        }
        InferenceContext(
            typeAliases = typeAliases,
            variables = Map(),
            propertiesOrTypeAliases = properties.toMap ++ typeAliasKinds,
            functions = defaultFunctions ++ userFunctions,
        )
    }

    val defaultFunctions = Map(
        "!==" -> (List(KValue, KValue), KBool, true),
        "===" -> (List(KValue, KValue), KBool, true),
        "!=" -> (List(KNat, KNat), KBool, true),
        "==" -> (List(KNat, KNat), KBool, true),
        "<=" -> (List(KNat, KNat), KBool, true),
        ">=" -> (List(KNat, KNat), KBool, true),
        "<" -> (List(KNat, KNat), KBool, true),
        ">" -> (List(KNat, KNat), KBool, true),
        "&&" -> (List(KBool, KBool), KBool, true),
        "||" -> (List(KBool, KBool), KBool, true),
        "<>" -> (List(KBool, KBool), KBool, true),
        "!" -> (List(KBool), KBool, true),
        "+" -> (List(KNat, KNat), KNat, true),
        "-" -> (List(KNat, KNat), KNat, true),
        "*" -> (List(KNat, KNat), KNat, true),
        "/" -> (List(KNat, KNat), KNat, true),
        "%" -> (List(KNat, KNat), KNat, true),
        "random" -> (List(), KNat, true),
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
                e.copy(kind = context.variables.getOrElse(name,
                    fail(line, "No such varible: " + name)
                ))
            case e@EMatch(line, _, expression, matchCases) =>
                val newExpression = inferExpression(context, expression)
                val newMatchCases = matchCases.map(inferMatchCase(context, newExpression.kind, _))
                val headKind :: tailKinds = newMatchCases.map(_.body.kind)
                tailKinds.find(_ != headKind).foreach(matchType =>
                    fail(line, "Kind mismatch: " + matchType + " vs. " + headKind)
                )
                e.copy(kind = headKind, expression = newExpression, matchCases = newMatchCases)
            case e@ECall(line, _, function, arguments) =>
                val (argumentKinds, returnKind, _) = context.functions.getOrElse(function,
                    fail(line, "No such function: " + function)
                )
                val newArguments = arguments.map(inferExpression(context, _))
                if(argumentKinds != newArguments.map(_.kind)) {
                    fail(line,
                        "Argument kind mismatch: " + newArguments.map(_.kind).mkString(", ") +
                        " vs. " + argumentKinds.mkString(", ")
                    )
                }
                e.copy(kind = returnKind, arguments = newArguments)
            case e@EProperty(line, _, expression, property, value) =>
                val resultKind = context.propertiesOrTypeAliases.getOrElse(property,
                    fail(line, "Unknown property or type alias: " + property)
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

    def inferPattern(context: InferenceContext, matchKind : Kind, pattern: Pattern): (Pattern, InferenceContext) = {
        var newContext = pattern.name.map(name =>
            context.copy(variables = context.variables.updated(name, matchKind))
        ).getOrElse(context)
        val newSymbols = pattern.symbols.map { symbolPattern =>
            val newSubpattern = symbolPattern.pattern.map { p =>
                val symbolKind = newContext.propertiesOrTypeAliases(symbolPattern.symbol)
                val (newPattern1, newContext1) = inferPattern(newContext, symbolKind, p)
                newContext = newContext1
                newPattern1
            }
            symbolPattern.copy(pattern = newSubpattern)
        }
        val newPattern = pattern.copy(kind = matchKind, symbols = newSymbols)
        (newPattern, newContext)
    }

    protected def fail(line: Int, message: String) = {
        throw new RuntimeException(message + " at line " + line)
    }

}

