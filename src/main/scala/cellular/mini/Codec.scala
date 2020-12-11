package cellular.mini

object Codec {

    def sizeOf(context: TypeContext, fixed: FixedType): Int = {
        val materialNames = materialsOf(context, fixed.valueType).toList
        materialNames.map(materialSizeOf(context, _, fixed.fixed)).sum
    }

    def materialSizeOf(context: TypeContext, materialName: String, fixed: List[PropertyValue] = List()): Int = {
        context.materials(materialName).map {
            case MaterialProperty(_, Some(_)) => 1
            case MaterialProperty(propertyName, None) if fixed.exists(_.property == propertyName) => 1
            case MaterialProperty(propertyName, None) => propertySizeOf(context, propertyName)
        }.product
    }

    def propertySizeOf(context: TypeContext, propertyName: String): Int = {
        context.properties(propertyName) match {
            case None => 1
            case Some(fixedType1) => sizeOf(context, fixedType1)
        }
    }

    def materialsOf(context: TypeContext, type0: Type): Set[String] = type0 match {
        case TIntersection(type1, type2) =>
            materialsOf(context, type1) intersect materialsOf(context, type2)
        case TUnion(type1, type2) =>
            materialsOf(context, type1) union materialsOf(context, type2)
        case TProperty(property) =>
            context.propertyMaterials(property)
    }

    def encodeValue(context: TypeContext, fixedType: FixedType, value: Value): Int = {
        var result = 0
        for(PropertyValue(property, value) <- value.properties) {
            val constant = context.materials(value.material).exists(p => p.property == property && p.value.nonEmpty)
            if(!constant && !fixedType.fixed.exists(_.property == property)) {
                context.properties(property).map { propertyFixedType =>
                    result *= propertySizeOf(context, property)
                    result += encodeValue(context, propertyFixedType, value)
                }
            }
        }
        val materials = materialsOf(context, fixedType.valueType).toList.sorted
        val material = materials.indexOf(value.material)
        result *= materials.size
        result += material
        result
    }

    def decodeValue(context: TypeContext, fixedType: FixedType, number: Int): Value = {
        val materials = materialsOf(context, fixedType.valueType).toList.sorted
        val material = materials(number % materials.size)
        var remaining = number / materials.size
        val properties = context.materials(material)
        val values = for(property <- properties) yield property.property -> property.value.orElse {
            fixedType.fixed.find(_.property == property.property).map(_.value).orElse {
                context.properties(property.property).map { propertyFixedType =>
                    val size = propertySizeOf(context, property.property)
                    val propertyNumber = remaining % size
                    remaining = remaining / size
                    decodeValue(context, propertyFixedType, propertyNumber)
                }
            }
        }
        val propertyValues = values.collect { case (k, Some(v)) => PropertyValue(k, v) }
        Value(material, propertyValues)
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

        /*
        context.properties.foreach(println)
        println()
        context.materials.foreach(println)
        println()
        context.propertyMaterials.foreach(println)
        println()
        println(sizeOf(
            context,
            FixedType(TProperty("Tile"), List())
        ))
        */

        val fixedType = FixedType(TProperty("Tile"), List())
        val value = Value("Chest", List(PropertyValue("ChestContent", Value("Sand", List()))))
        val encoded = encodeValue(context, fixedType, value)
        val decoded = decodeValue(context, fixedType, encoded)
        println(value)
        println(encoded)
        println(decoded)

    }

}
