package cellular.mini

object TypeChecker {

    def size(context: TypeContext, propertyType: PropertyType) : Int = {
        val materials = materialInhabitants(context, propertyType.valueType)
        materials.map { material =>
            context.materials(material).map { property =>
                if(propertyType.forget.contains(property)) 1 else {
                    size(context, context.properties(property))
                }
            }.product
        }.sum
    }

    def materialInhabitants(context: TypeContext, type0: Type) : Set[String] = type0 match {
        case TIntersection(type1, type2) =>
            materialInhabitants(context, type1) intersect materialInhabitants(context, type2)
        case TUnion(type1, type2) =>
            materialInhabitants(context, type1) union materialInhabitants(context, type2)
        case TProperty(property) =>
            context.materials.filter(_._2.contains(property)).keySet
    }

}
