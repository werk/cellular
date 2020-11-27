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
case class FixedType(valueType: Type, fixed: List[PropertyValue])
case class MaterialProperty(property: String, value: Option[Value])

trait Definition
case class DProperty(name: String, propertyType: Option[FixedType]) extends Definition
case class DMaterial(name: String, properties: List[MaterialProperty]) extends Definition

case class TypeContext(
    properties: Map[String, Option[FixedType]],
    materials: Map[String, List[MaterialProperty]],
    variables: Map[String, Type]
)

object TypeContext {
    def fromDefinitions(definitions: List[Definition]) = {
        val materials = definitions.collect { case material : DMaterial => material }
        val properties = definitions.collect { case property : DProperty => property }
        TypeContext(
            properties = materials.map(m => m.name -> None).toMap ++ properties.map(p => p.name -> p.propertyType),
            materials = materials.map(m => m.name -> (MaterialProperty(m.name, None) :: m.properties)).toMap,
            variables = Map()
        )
    }
}
