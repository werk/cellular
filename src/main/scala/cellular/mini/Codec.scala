package cellular.mini

object Codec {

    def sizeOf(context: TypeContext, fixed: FixedType): Int = {
        val materialNames = materialsOf(context, fixed.valueType).toList
        materialNames.map(materialSizeOf(context, _, fixed.fixed)).sum
    }

    def materialSizeOf(context: TypeContext, materialName: String, fixed: List[PropertyValue] = List()): Int = {
        if(materialName.head.isDigit) return 1
        val properties = context.materials.getOrElse(materialName, {
            throw new RuntimeException("No such material: " + materialName)
        })
        properties.filter(_.property != materialName).map {
            case MaterialProperty(_, _, Some(_)) => 1
            case MaterialProperty(_, propertyName, None) if fixed.exists(_.property == propertyName) => 1
            case MaterialProperty(_, propertyName, None) => propertySizeOf(context, propertyName)
        }.product
    }

    def propertySizeOf(context: TypeContext, propertyName: String): Int = {
        if(propertyName.head.isDigit) 1 else
        context.properties.get(propertyName) match {
            case None => throw new RuntimeException("No such property: " + propertyName)
            case Some(None) => 1
            case Some(Some(fixedType1)) => sizeOf(context, fixedType1)
        }
    }

    def materialsOf(context: TypeContext, type0: Type): Set[String] = type0 match {
        case TIntersection(_, type1, type2) =>
            materialsOf(context, type1) intersect materialsOf(context, type2)
        case TUnion(_, type1, type2) =>
            materialsOf(context, type1) union materialsOf(context, type2)
        case TSymbol(_, name) =>
            context.typeAliases.get(name).map(materialsOf(context, _)).getOrElse {
                if(name.head.isDigit || context.materials.contains(name)) Set(name) else
                context.propertyMaterials.get(name) match {
                    case None => throw new RuntimeException("No such property: " + name)
                    case Some(materials) => materials
                }
            }
    }

    def encodeValue(context: TypeContext, fixedType: FixedType, value: Value): Int = {
        if(value.material.head.isDigit) return value.material.toInt
        var result = 0
        for(PropertyValue(_, property, value) <- value.properties) {
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
        val propertyValues = values.collect { case (k, Some(v)) => PropertyValue(0, k, v) }
        Value(0, material, propertyValues)
    }

    def main(args : Array[String]) : Unit = {

        val definitions = List(
            DProperty(0, "Tile", None),
            DProperty(0, "Resource", None),
            DProperty(0, "ChestContent", Some(FixedType(0,
                valueType = TUnion(0,
                    TSymbol(0, "Nothing"),
                    TUnion(0, TSymbol(0, "Resource"), TSymbol(0, "Chest"))
                ),
                fixed = List(PropertyValue(0, "ChestContent", Value(0, "Nothing", List())))
            ))),
            DMaterial(0, "Chest", List(MaterialProperty(0, "ChestContent", None), MaterialProperty(0, "Tile", None))),
            DMaterial(0, "Sand", List(MaterialProperty(0, "Resource", None), MaterialProperty(0, "Tile", None))),
            DMaterial(0, "Water", List(MaterialProperty(0, "Resource", None), MaterialProperty(0, "Tile", None))),
            DMaterial(0, "Nothing", List())
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

        val fixedType = FixedType(0, TSymbol(0, "Tile"), List())
        val value = Value(0, "Chest", List(PropertyValue(0, "ChestContent", Value(0, "Sand", List()))))
        val encoded = encodeValue(context, fixedType, value)
        val decoded = decodeValue(context, fixedType, encoded)
        println(value)
        println(encoded)
        println(decoded)

    }

}
