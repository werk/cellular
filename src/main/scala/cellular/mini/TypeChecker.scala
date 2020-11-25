package cellular.mini

object TypeChecker {

    def materials(context: TypeContext, type0: Type) : Set[String] = type0 match {
        case TIntersection(type1, type2) =>
            materials(context, type1) intersect materials(context, type2)
        case TUnion(type1, type2) =>
            materials(context, type1) union materials(context, type2)
        case TProperty(property) =>
            context.materials.filter(_._2.contains(property)).keySet
        case TForget(_, _) =>
            context.materials.keySet
    }

    def forgotten(context: TypeContext, type0: Type) : Map[String, Map[String, Value]] = type0 match {
        case TIntersection(type1, type2) =>
            val materials1 = forgotten(context, type1)
            val materials2 = forgotten(context, type2)
            combineForgotten(materials1, materials2, materials1.keySet intersect materials2.keySet)
        case TUnion(type1, type2) =>
            val materials1 = forgotten(context, type1)
            val materials2 = forgotten(context, type2)
            combineForgotten(materials1, materials2, materials1.keySet union materials2.keySet)
        case TProperty(property) =>
            val materialNames = context.materials.filter(_._2.contains(property)).keys
            materialNames.map(_ -> Map[String, Value]()).toMap
        case TForget(property, value) =>
            val forgetMap = Map(property -> value)
            val emptyMap = Map[String, Value]()
            context.materials.map { case (name, properties) =>
                if(properties.contains(property)) name -> forgetMap
                else name -> emptyMap
            }
    }

    private def combineForgotten(
        materials1: Map[String, Map[String, Value]],
        materials2: Map[String, Map[String, Value]],
        keys: Set[String]
    ): Map[String, Map[String, Value]] = {
        keys.map { key =>
            val forgotten1 = materials1(key)
            val forgotten2 = materials2(key)
            val forgottenIntersection = forgotten1.keySet intersect forgotten2.keySet
            forgottenIntersection foreach { k =>
                if(forgotten1(k) != forgotten2(k)) {
                    throw new RuntimeException(
                        "Forgotten value mismatch: " + forgotten1(k) + " vs. " + forgotten2(k)
                    )
                }
            }
            key -> (forgotten1 ++ forgotten2)
        }.toMap
    }

}
