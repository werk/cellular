package cellular.mini

object Expander {

    def expand(groupScheme: Scheme, rule: Rule): List[Rule] = {
        val scheme = Scheme(
            wrapper = rule.scheme.wrapper.orElse(groupScheme.wrapper),
            unless = (rule.scheme.unless ++ groupScheme.unless).distinct,
            modifiers = (rule.scheme.modifiers ++ groupScheme.modifiers).distinct
        )
        val wrappedRule = scheme.wrapper.map { wrapper =>
            rule.copy(
                patterns = rule.patterns.zipWithIndex.map { case (xs, y) =>
                    xs.zipWithIndex.map { case (p, x) =>
                        PProperty(PVariable(Some("p_" + x + "_" + y)), wrapper, Some(p))
                    }
                },
                expression = wrapMatrices(wrapper, rule.expression)
            )
        }.getOrElse(rule)
        val extraRules = scheme.modifiers.map { modifier =>
            val patterns = modify(modifier, wrappedRule.patterns)
            val expression = modifyMatrices(modifier, wrappedRule.expression)
            wrappedRule.copy(
                name = wrappedRule.name + "_" + modifier,
                scheme = scheme,
                patterns = patterns,
                expression = expression
            )
        }
        wrappedRule :: extraRules
    }

    def wrapMatrices[T](wrapper: String, expression: Expression): Expression = expression match {
        case e: EVariable => e
        case e: EMatch => e.copy(matchCases = e.matchCases.map(c => c.copy(body = wrapMatrices(wrapper, c.body))))
        case e: ECall => e
        case e: EProperty => e
        case e: EMaterial => e
        case e: EMatrix =>
            e.copy(expressions = e.expressions.zipWithIndex.map { case (xs, y) =>
                xs.zipWithIndex.map { case (e, x) =>
                    EProperty(EVariable("p_" + x + "_" + y), wrapper, e)
                }
            })
    }

    def modifyMatrices[T](modifier: String, expression: Expression): Expression = expression match {
        case e: EVariable => e
        case e: EMatch => e.copy(matchCases = e.matchCases.map(c => c.copy(body = modifyMatrices(modifier, c.body))))
        case e: ECall => e
        case e: EProperty => e
        case e: EMaterial => e
        case e: EMatrix => e.copy(expressions = modify(modifier, e.expressions))
    }

    def modify[T](modifier: String, matrix: List[List[T]]): List[List[T]] = {
        modifier match {
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
                throw new RuntimeException("Unknown modifier: " + modifier)
        }
    }

}
