object Language {

    sealed abstract class Declaration
    case class DTrait(name : String, valueType : Type) extends Declaration
    case class DCellType(name : String, traits : List[(CTrait, Option[Expression])]) extends Declaration
    case class DGroup(name : String, condition : Expression, reactions : List[Reaction]) extends Declaration

    case class Reaction(
        name : String,
        directives : List[String],
        after : List[List[CellPattern]],
        constraints : List[Expression]
    )

    case class CellPattern(variable : Option[String], cellType : Option[CellType])

    sealed abstract class Type
    case class TNumber(lessThan : Int) extends Type
    case class TCell(cellType : CellType) extends Type

    sealed abstract class CellType
    case class CTrait(name : String, argument : Option[Expression]) extends CellType
    case class COr(left : CellType, right : CellType) extends CellType
    case class CAnd(left : CellType, right : CellType) extends CellType
    case class CWithout(left : CellType, right : CellType) extends CellType

    sealed abstract class Expression
    case class EBool(value : Boolean) extends Expression
    case class ENumber(value : Int) extends Expression
    case class EVariable(name : String) extends Expression
    case class EBinary(operator : String, left : Expression, right : Expression) extends Expression
    case class EUnary(operator : String, condition : Expression) extends Expression
    case class EIf(condition : Expression, thenBody : Expression, elseBody : Expression) extends Expression
    case class EApply(name : String, arguments : List[Expression]) extends Expression
    case class EDid(name : String) extends Expression
    case class EIs(left : Expression, kind : String) extends Expression
    case class EField(left : Expression, kind : String) extends Expression
    case class EPeek(x : Int, y : Int) extends Expression

}
