import Language._

object Reactions {

    def translate(reaction : DReaction) : Unit = {
        val constraints = reaction.constraints.map {
            case EEquals(EVariable(x), right) =>
                (Some(x) -> right) -> free(right)
            case e =>
                (None -> e) -> free(e)
        }
        var sorted = constraints.sortBy { case ((x, e), f) => (x.isEmpty, f.size) }
        while(sorted.exists(_._1._1.nonEmpty)) {
            val index = sorted.indexWhere { case ((x, e), f) => x.nonEmpty && f.isEmpty }
            if(index == -1) {
                println("Cycle detected: " + sorted.find(_._1._1.nonEmpty).get)
                return
            }
            val ((Some(x0), e0), f0) = sorted(index)
            println("let " + x0 + " = " + e0)
            sorted = sorted.take(index) ++ sorted.drop(index + 1)
            sorted = sorted.map { case ((x, e), f) => ((x, e), f - x0) }
        }
        for(((None, e0), f0) <- sorted) {
            if(f0.nonEmpty) {
                println("Ambiguous variable: " + f0.head + " in " + e0)
            }
            println("assert " + e0)
        }
    }

    def free(expression : Expression) : Set[String] = expression match {
        case ENumber(value) => Set()
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
        val r1 = DReaction("Foo", List(), List(), List(), List(
            EEquals(EVariable("x"), EPlus(EVariable("y"), EVariable("z"))),
            EEquals(EPlus(EVariable("x"), EVariable("y")), EPlus(EVariable("y"), EVariable("z"))),
            EEquals(EVariable("y"), EPlus(ENumber(2), ENumber(3))),
            EEquals(EVariable("z"), EPlus(EVariable("y"), ENumber(1))),
        ))
        translate(r1)
    }

}
