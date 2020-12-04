package cellular.mini

sealed trait Type { override def toString = Type.show(this) }
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

case class Value(material: String, properties: List[PropertyValue]) { override def toString = Value.show(this) }
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
    propertyMaterials: Map[String, Set[String]],
    variables: Map[String, Type]
)

object TypeContext {
    def fromDefinitions(definitions: List[Definition]) = {
        val materials = definitions.collect { case material : DMaterial => material }
        val properties = definitions.collect { case property : DProperty => property }
        val materialProperties = materials.map(m => m.name -> None).toMap
        val allProperties = materialProperties ++ properties.map(p => p.name -> p.propertyType)
        val allMaterials = materials.map(m => m.name -> (MaterialProperty(m.name, None) :: m.properties)).toMap
        TypeContext(
            properties = allProperties,
            materials = allMaterials,
            propertyMaterials = allProperties.map { case (propertyName, _) =>
                propertyName -> allMaterials.filter(_._2.exists(_.property == propertyName)).keySet
            },
            variables = Map()
        )
    }
}

object Value {
    def show(value: Value) = {
        value.material + value.properties.map(p => " " + p.property + "(" + p.value + ")").mkString
    }
}

object Type {
    def show(type0: Type): String = type0 match {
        case TIntersection(type1, type2) => showAtom(type1) + " " + showAtom(type2)
        case TUnion(type1, type2) => type1 + " | " + type2
        case TProperty(property) => property
    }

    def showAtom(type0: Type): String = type0 match {
        case _ : TUnion => "(" + type0 + ")"
        case _ => show(type0)
    }
}
