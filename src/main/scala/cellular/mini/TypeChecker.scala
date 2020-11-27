package cellular.mini

object TypeChecker {

    def size(context: TypeContext, fixed: FixedType): Int = {
        val materialNames = materials(context, fixed.valueType).toList
        materialNames.map(materialSize(context, _, fixed.fixed)).sum
    }

    def materialSize(context: TypeContext, materialName: String, fixed: List[PropertyValue] = List()): Int = {
        context.materials(materialName).map {
            case MaterialProperty(_, Some(_)) => 1
            case MaterialProperty(propertyName, None) if fixed.exists(_.property == propertyName) => 1
            case MaterialProperty(propertyName, None) =>
                context.properties(propertyName) match {
                    case Some(fixedType1) => size(context, fixedType1)
                    case None => 1
                }
        }.product
    }

    def materials(context: TypeContext, type0: Type): Set[String] = type0 match {
        case TIntersection(type1, type2) =>
            materials(context, type1) intersect materials(context, type2)
        case TUnion(type1, type2) =>
            materials(context, type1) union materials(context, type2)
        case TProperty(property) =>
            context.propertyMaterials(property)
    }

    def convert(context: TypeContext, fixed1: FixedType, fixed2: FixedType): Int => Int = {
        ???
    }

    def main(args : Array[String]) : Unit = {

        val definitions = List(
            DProperty("Tile", None),
            DProperty("Resource", None),
            DProperty("ChestContent", Some(FixedType(
                valueType = TUnion(TProperty("Nothing"), TUnion(TProperty("Resource"), TProperty("Chest"))),
                fixed = List(PropertyValue("ChestContent", Value("Nothing", List())))
            ))),
            DMaterial("Chest", List(MaterialProperty("ChestContent", None), MaterialProperty("Tile", None))),
            DMaterial("Sand", List(MaterialProperty("Resource", None), MaterialProperty("Tile", None))),
            DMaterial("Water", List(MaterialProperty("Resource", None), MaterialProperty("Tile", None))),
            DMaterial("Nothing", List())
        )

        val context = TypeContext.fromDefinitions(definitions)

        context.properties.foreach(println)
        println()
        context.materials.foreach(println)
        println()
        context.propertyMaterials.foreach(println)
        println()
        println(size(
            context,
            FixedType(TProperty("Tile"), List())
        ))

    }

}
