package cellular.mini

object TypeChecker {

    def size(context: TypeContext, propertyType: PropertyType) : Int = {
        val materialNames = materials(context, propertyType.valueType)
        materialNames.map { material =>
            context.materials(material).map { property =>
                if(propertyType.forget.contains(property)) 1 else {
                    context.properties(property).map(size(context, _)).getOrElse(1)
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
            context.materials.filter(_._2.contains(property)).keySet
    }

}
