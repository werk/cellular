package language

import language.Language.Expression

object Usages {

    def peek(x : Int, y : Int) : String = {
        def sign(value : Int) = if(value < 0) "m" else "p"
        sign(x) + sign(y) + "_" + Math.abs(x) + "_" + Math.abs(y)
    }

    def peekArgument(x : Int, y : Int) : String = {
        val prefix = if((x == 0 || x == 1) && (y == 0 || y == 1)) "inout uint " else "uint "
        prefix + peek(x, y)
    }

    def didArgument(name : String) : String = {
        "bool did_" + name
    }

    def peeks(expression : Expression) : Set[(Int, Int)] = expression match {
        case Language.EBool(value) => Set()
        case Language.ENumber(value) => Set()
        case Language.EVariable(name) => Set()
        case Language.EBinary(_, left, right) => peeks(left) ++ peeks(right)
        case Language.EUnary(_, right) => peeks(right)
        case Language.EIf(condition, thenBody, elseBody) => peeks(condition) ++ peeks(thenBody) ++ peeks(elseBody)
        case Language.EApply(name, arguments) => arguments.map(peeks).fold(Set()) { _ ++ _ }
        case Language.EDid(name) => Set()
        case Language.EIs(left, kind) => peeks(left)
        case Language.EField(left, kind) => peeks(left)
        case Language.EPeek(x, y) => Set(x -> y)
    }

    def dids(expression : Expression) : Set[String] = expression match {
        case Language.EBool(value) => Set()
        case Language.ENumber(value) => Set()
        case Language.EVariable(name) => Set()
        case Language.EBinary(_, left, right) => dids(left) ++ dids(right)
        case Language.EUnary(_, right) => dids(right)
        case Language.EIf(condition, thenBody, elseBody) => dids(condition) ++ dids(thenBody) ++ dids(elseBody)
        case Language.EApply(name, arguments) => arguments.map(dids).fold(Set()) { _ ++ _ }
        case Language.EDid(name) => Set(name)
        case Language.EIs(left, kind) => dids(left)
        case Language.EField(left, kind) => dids(left)
        case Language.EPeek(x, y) => Set()
    }

}
