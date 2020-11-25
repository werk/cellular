package cellular.mini

object TypeChecker {

    def cardinality(context: TypeContext, type0: Type) : Int = {
        val materials = inhabitants(context, type0)
        materials.map { case (material, forgotten) =>
            context.materials(material).map { property =>
                if(forgotten.forgot.contains(property)) 1
                else context.properties(property).map(cardinality(context, _)).getOrElse(1)
            }.product
        }.sum
    }

    def inhabitants(context: TypeContext, type0: Type) : Map[String, Forgotten] = type0 match {
        case TIntersection(type1, type2) =>
            val materials1 = inhabitants(context, type1)
            val materials2 = inhabitants(context, type2)
            combineForgotten(materials1, materials2, materials1.keySet intersect materials2.keySet)
        case TUnion(type1, type2) =>
            val materials1 = inhabitants(context, type1)
            val materials2 = inhabitants(context, type2)
            combineForgotten(materials1, materials2, materials1.keySet union materials2.keySet)
        case TProperty(property) =>
            val materialNames = context.materials.filter(_._2.contains(property)).keys
            materialNames.map(_ -> Forgotten(Map[String, Value]())).toMap
        case TForget(property, value) =>
            val singleton = Forgotten(Map(property -> value))
            val empty = Forgotten(Map[String, Value]())
            context.materials.view.mapValues { properties =>
                if(properties.contains(property)) singleton else empty
            }.toMap
    }

    private def combineForgotten(
        materials1: Map[String, Forgotten],
        materials2: Map[String, Forgotten],
        keys: Set[String]
    ): Map[String, Forgotten] = {
        keys.map { key =>
            val forgotten1 = materials1(key)
            val forgotten2 = materials2(key)
            val forgottenIntersection = forgotten1.forgot.keySet intersect forgotten2.forgot.keySet
            forgottenIntersection foreach { k =>
                if(forgotten1.forgot(k) != forgotten2.forgot(k)) {
                    throw new RuntimeException(
                        "Forgotten value mismatch: " + forgotten1.forgot(k) + " vs. " + forgotten2.forgot(k)
                    )
                }
            }
            key -> Forgotten(forgotten1.forgot ++ forgotten2.forgot)
        }.toMap
    }

}
