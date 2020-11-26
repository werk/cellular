package cellular.mini

object TypeChecker {

    def size(context: TypeContext, propertyType: PropertyType) : Int = {
        val materialNames = materials(context, propertyType.valueType).toList
        materialNames.map { material =>
            context.materials(material).map {
                case MaterialProperty(_, Some(_)) => 1
                case MaterialProperty(propertyName, None) if propertyType.forget.exists(_.property == propertyName) => 1
                case MaterialProperty(propertyName, None) =>
                    context.properties(propertyName) match {
                        case Some(propertyType1) => size(context, propertyType1)
                        case None => 1
                    }
            }.product
        }.sum
    }

    def materials(context: TypeContext, type0: Type) : Set[String] = type0 match {
        case TIntersection(type1, type2) =>
            materials(context, type1) intersect materials(context, type2)
        case TUnion(type1, type2) =>
            materials(context, type1) union materials(context, type2)
        case TProperty(property) =>
            context.materials.filter(_._2.exists(_.property == property)).keySet
    }

    def main(args : Array[String]) : Unit = {

        val definitions = List(
            DProperty("Tile", None),
            DProperty("Resource", None),
            DProperty("ChestContent", Some(PropertyType(
                valueType = TUnion(TProperty("Nothing"), TUnion(TProperty("Resource"), TProperty("Chest"))),
                forget = List(PropertyValue("ChestContent", Value("Nothing", List())))
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
        println(size(
            context,
            PropertyType(TProperty("Tile"), List())
        ))

    }

}
