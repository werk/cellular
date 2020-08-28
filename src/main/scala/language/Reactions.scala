package language

import language.Language._

object Reactions {

    val infinity = 1_000_000_000

    def sortByDependencies(expressions : List[Expression]) : List[(Int, Expression)] = {
        var variableDepths = Map[String, Int]().withDefaultValue(infinity)
        var expressionDepths = expressions.map(infinity -> _)
        var oldExpressionDepths = expressionDepths
        do {
            oldExpressionDepths = expressionDepths
            expressionDepths = expressions.map { e =>
                val (variableNameOption, freeVariables) = e match {
                    case EBinary("=", EVariable(name), right) => Some(name) -> free(right)
                    case _ => None -> free(e)
                }
                val newDepth = (0 :: freeVariables.map(variableDepths).toList).max + 1
                for(x <- variableNameOption) variableDepths += x -> Math.min(variableDepths(x), newDepth)
                newDepth -> e
            }
        } while(expressionDepths != oldExpressionDepths)
        expressionDepths
    }.sortBy {
        case (depth, EBinary("=", EVariable(_), _)) => depth -> true // Prefer variable definitions after asserts.
        case (depth, _) => depth -> false
    }

    def free(expression : Expression) : Set[String] = expression match {
        case EBool(value) => Set()
        case ENumber(value) => Set()
        case EPeek(x, y) => Set()
        case EVariable(name) => Set(name)
        case EBinary(_, left, right) => free(left) ++ free(right)
        case EUnary(_, condition) => free(condition)
        case EIf(condition, thenBody, elseBody) => free(condition) ++ free(thenBody) ++ free(elseBody)
        case EApply(name, arguments) => arguments.map(free).fold(Set[String]())(_ ++ _)
        case EDid(name) => Set()
        case EIs(left, kind) => free(left)
        case EField(left, kind) => free(left)
    }

    def freeInCellType(cellType : CellType) : Set[String] = cellType match {
        case CTrait(name, argument) => argument.map(free).getOrElse(Set())
        case COr(left, right) => freeInCellType(left) ++ freeInCellType(right)
        case CAnd(left, right) => freeInCellType(left) ++ freeInCellType(right)
        case CWithout(left, right) => freeInCellType(left) ++ freeInCellType(right)
    }


    def compile(r1 : Reaction) : String = {
        val peekArguments = r1.constraints.map(Usages.peeks).fold(Set()) { _ ++ _ }.toList.sorted.
            map((Usages.peekArgument _).tupled)
        val didArguments = r1.constraints.map(Usages.dids).fold(Set()) { _ ++ _ }.toList.sorted.
            map(Usages.didArgument)
        val arguments = peekArguments ++ didArguments
        var lets = Set[String]()
        val body = for((depth, e) <- sortByDependencies(r1.constraints)) yield {
            e match {
                case _ if depth >= infinity =>
                    "    error " + Expressions.translate(e, false) + ";"
                case EBinary("=", EVariable(x), e1) if !lets(x) =>
                    lets += x
                    "    uint " + Expressions.escape(x) + " = " + Expressions.translate(e1, false) + ";"
                case _ =>
                    "    if(" + Expressions.translate(Expressions.negate(e), false) + ") return false;"
            }
        }
        List(
            "bool rule_" + r1.name + "(" + arguments.mkString(", ") + ") {",
            body.mkString("\n"),
            "    return true;",
            "}",
        ).mkString("\n")

    }

    def main(args: Array[String]): Unit = {
        val r1 = Reaction("foo", List(), List(), List(
            EBinary("=", EVariable("x"), EBinary("+", EVariable("x"), EVariable("x"))),
            EBinary("=", EVariable("x"), EBinary("+", EField(EVariable("y"), "heat"), EVariable("z"))),
            EBinary("=", EBinary("+", EVariable("x"), EVariable("y")), EBinary("+", EVariable("y"), EVariable("z"))),
            EBinary("=", EBinary("+", EVariable("y"), EVariable("y")), EBinary("+", EVariable("y"), EVariable("y"))),
            EBinary("=", EVariable("y"), EBinary("+", ENumber(2), ENumber(3))),
            EBinary("=", EVariable("z"), EBinary("+", EVariable("y"), EPeek(0, 1))),
            EBinary("&", EDid("fall"), EIs(EVariable("y"), "heat")),
            EBinary("=", EBinary("+", EVariable("q"), ENumber(1)), EBinary("+", EVariable("p"), ENumber(1))),
        ))

        for((depth, e) <- sortByDependencies(r1.constraints)) println(depth + " " + e)

        println()
        println(compile(r1))
    }

}
