package cellular.mini

sealed trait Type { val line: Int; override def toString = Type.show(this) }
case class TIntersection(line: Int, type1: Type, type2: Type) extends Type
case class TUnion(line: Int, type1: Type, type2: Type) extends Type
case class TSymbol(line: Int, name: String) extends Type

case class Pattern(line: Int, name: Option[String], properties: List[PropertyPattern])
case class PropertyPattern(line: Int, property: String, pattern: Option[Pattern])

sealed trait Expression { val line: Int }
case class EVariable(line: Int, name: String) extends Expression
case class EMatch(line: Int, expression: Expression, matchCases: List[MatchCase]) extends Expression
case class ECall(line: Int, function: String, arguments: List[Expression]) extends Expression
case class EProperty(line: Int, expression: Expression, property: String, value: Expression) extends Expression
case class EMaterial(line: Int, material: String) extends Expression
case class EMatrix(line: Int, expressions: List[List[Expression]]) extends Expression

sealed trait Definition { val line: Int }
case class DProperty(line: Int, name: String, propertyType: Option[FixedType]) extends Definition
case class DMaterial(line: Int, name: String, properties: List[MaterialProperty]) extends Definition
case class DGroup(line: Int, name: String, scheme: Scheme, rules: List[Rule]) extends Definition

case class Value(line: Int, material: String, properties: List[PropertyValue]) {
    override def toString = Value.show(this)
}

case class PropertyValue(line: Int, property: String, value: Value)
case class MatchCase(line: Int, pattern: Pattern, body: Expression)
case class FixedType(line: Int, valueType: Type, fixed: List[PropertyValue])
case class MaterialProperty(line: Int, property: String, value: Option[Value])

case class Rule(line: Int, name: String, scheme: Scheme, patterns: List[List[Pattern]], expression: Expression)
case class Scheme(line: Int, wrapper: Option[String], unless: List[String], modifiers: List[String])

case class TypeContext(
    properties: Map[String, Option[FixedType]],
    materials: Map[String, List[MaterialProperty]],
    materialIndexes: Map[String, Int],
    propertyMaterials: Map[String, Set[String]]
)

object TypeContext {
    def fromDefinitions(definitions: List[Definition]) = {
        val materials = definitions.collect { case material : DMaterial => material }
        val properties = definitions.collect { case property : DProperty => property }
        val allProperties = properties.map(p => p.name -> p.propertyType).toMap
        val allMaterials = materials.map(m => m.name -> m.properties).toMap
        val materialIndexes = materials.map(_.name).zipWithIndex.toMap
        TypeContext(
            properties = allProperties,
            materials = allMaterials,
            materialIndexes = materialIndexes,
            propertyMaterials = allProperties.map { case (propertyName, _) =>
                propertyName -> allMaterials.filter(_._2.exists(_.property == propertyName)).keySet
            }
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
        case TIntersection(_, type1, type2) => showAtom(type1) + " " + showAtom(type2)
        case TUnion(_, type1, type2) => type1 + " | " + type2
        case TSymbol(_, name) => name
    }

    def showAtom(type0: Type): String = type0 match {
        case _ : TUnion => "(" + type0 + ")"
        case _ => show(type0)
    }
}
