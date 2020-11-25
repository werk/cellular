package cellular.mini

sealed trait Type
case class TIntersection(type1: Type, type2: Type) extends Type
case class TUnion(type1: Type, type2: Type) extends Type
case class TProperty(property: String) extends Type

trait Pattern
case class PVariable(name: Option[String]) extends Pattern
case class PProperty(pattern: Pattern, property: String, value: Option[Value]) extends Pattern

trait Expression
case class EVariable(name: String) extends Expression
case class EMatch(expression: Expression, matchCases: List[MatchCase]) extends Expression
case class EProperty(expression: Expression, value: Expression) extends Expression
case class EMaterial(material: String) extends Expression

case class Value(material: String, properties: List[PropertyValue])
case class PropertyValue(property: String, value: Value)
case class MatchCase(pattern: Pattern, body: Expression)
case class PropertyType(valueType: Type, forget: List[PropertyValue])

trait Definition
case class DProperty(name: String, propertyType: PropertyType) extends Definition
case class DMaterial(name: String, properties: List[String]) extends Definition

case class TypeContext(
    properties: Map[String, PropertyType],
    materials: Map[String, List[String]],
    variables: Map[String, Type]
)
