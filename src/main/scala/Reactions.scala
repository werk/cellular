import Language._

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
                    case EEquals(EVariable(name), right) => Some(name) -> free(right)
                    case _ => None -> free(e)
                }
                val newDepth = (0 :: freeVariables.map(variableDepths).toList).max + 1
                for(x <- variableNameOption) variableDepths += x -> Math.min(variableDepths(x), newDepth)
                newDepth -> e
            }
        } while(expressionDepths != oldExpressionDepths)
        expressionDepths
    }.sortBy {
        case (depth, EEquals(EVariable(_), _)) => depth -> true // Prefer variable definitions after asserts.
        case (depth, _) => depth -> false
    }

    def free(expression : Expression) : Set[String] = expression match {
        case EBool(value) => Set()
        case ENumber(value) => Set()
        case EPeek(x, y) => Set()
        case EVariable(name) => Set(name)
        case EPlus(left, right) => free(left) ++ free(right)
        case EEquals(left, right) => free(left) ++ free(right)
        case ENot(condition) => free(condition)
        case EIf(condition, thenBody, elseBody) => free(condition) ++ free(thenBody) ++ free(elseBody)
        case EApply(name, arguments) => arguments.map(free).fold(Set[String]())(_ ++ _)
        case EDid(name) => Set()
        case EIs(left, right) => free(left) ++ freeInCellType(right)
    }

    def freeInCellType(cellType : CellType) : Set[String] = cellType match {
        case CTrait(name, argument) => argument.map(free).getOrElse(Set())
        case COr(left, right) => freeInCellType(left) ++ freeInCellType(right)
        case CAnd(left, right) => freeInCellType(left) ++ freeInCellType(right)
        case CWithout(left, right) => freeInCellType(left) ++ freeInCellType(right)
    }


    def main(args: Array[String]): Unit = {
        val r1 = Reaction("foo", List(), List(), List(
            EEquals(EVariable("x"), EPlus(EVariable("x"), EVariable("x"))),
            EEquals(EVariable("x"), EPlus(EVariable("y"), EVariable("z"))),
            EEquals(EPlus(EVariable("x"), EVariable("y")), EPlus(EVariable("y"), EVariable("z"))),
            EEquals(EPlus(EVariable("y"), EVariable("y")), EPlus(EVariable("y"), EVariable("y"))),
            EEquals(EVariable("y"), EPlus(ENumber(2), ENumber(3))),
            EEquals(EVariable("z"), EPlus(EVariable("y"), EPeek(0, 1))),
            EEquals(EPlus(EVariable("q"), ENumber(1)), EPlus(EVariable("p"), ENumber(1))),
        ))
        for((depth, e) <- sortByDependencies(r1.constraints)) println(depth + " " + e)

        println()
        val peekArguments = r1.constraints.map(Peeks.peeks).fold(Set()) { _ ++ _ }.toList.sorted.
            map((Peeks.peekArgument _).tupled).mkString(", ")
        println("bool rule_" + r1.name + "(" + peekArguments + ") {")
        var lets = Set[String]()
        for((depth, e) <- sortByDependencies(r1.constraints)) {
            e match {
                case _ if depth >= infinity =>
                    println("    error " + Expressions.translate(e, false) + ";")
                case EEquals(EVariable(x), e1) if !lets(x) =>
                    lets += x
                    println("    uint " + Expressions.escape(x) + " = " + Expressions.translate(e1, false) + ";")
                case _ =>
                    println("    if(!" + Expressions.translate(e, true) + ") return false;")
            }
        }
        println("    return true;")
        println("}")
    }

}
