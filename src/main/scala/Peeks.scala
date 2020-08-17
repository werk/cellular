import Language.Expression

object Peeks {

    def peek(x : Int, y : Int) : String = {
        def sign(value : Int) = if(value < 0) "m" else "p"
        sign(x) + sign(y) + "_" + Math.abs(x) + "_" + Math.abs(y)
    }

    def peekArgument(x : Int, y : Int) : String = {
        val prefix = if((x == 0 || x == 1) && (y == 0 || y == 1)) "inout int " else "int "
        prefix + peek(x, y)
    }

    def peeks(expression : Expression) : Set[(Int, Int)] = expression match {
        case Language.EBool(value) => Set()
        case Language.ENumber(value) => Set()
        case Language.EVariable(name) => Set()
        case Language.EPlus(left, right) => peeks(left) ++ peeks(right)
        case Language.EEquals(left, right) => peeks(left) ++ peeks(right)
        case Language.ENot(condition) => peeks(condition)
        case Language.EIf(condition, thenBody, elseBody) => peeks(condition) ++ peeks(thenBody) ++ peeks(elseBody)
        case Language.EApply(name, arguments) => arguments.map(peeks).fold(Set()) { _ ++ _ }
        case Language.EDid(name) => Set()
        case Language.EIs(left, right) => Set() // TODO
        case Language.EPeek(x, y) => Set(x -> y)
    }

}
